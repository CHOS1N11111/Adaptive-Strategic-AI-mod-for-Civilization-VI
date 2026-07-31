from __future__ import annotations

import argparse
import os
import re
import sqlite3
import sys
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path


ITEM_TABLES = {
    "PseudoYields": ("PseudoYields", "PseudoYieldType"),
    "Yields": ("Yields", "YieldType"),
    "Units": ("Units", "UnitType"),
    "Districts": ("Districts", "DistrictType"),
    "Buildings": ("Buildings", "BuildingType"),
    "Projects": ("Projects", "ProjectType"),
    "Technologies": ("Technologies", "TechnologyType"),
    "Civics": ("Civics", "CivicType"),
    "UnitPromotionClasses": ("UnitPromotionClasses", "PromotionClassType"),
    "AiOperationTypes": ("AiOperationTypes", "OperationType"),
    "DiplomaticActions": ("DiplomaticActions", "DiplomaticActionType"),
}

EXPANSION_ONLY_ITEMS = {
    "PSEUDOYIELD_RELIGIOUS_CONVERT_EMPIRE",
    "PSEUDOYIELD_DIPLOMATIC_FAVOR",
    "PSEUDOYIELD_DIPLOMATIC_VICTORY_POINT",
}

EXPECTED_RELEASE = "0.5.2"
EXPECTED_MODINFO_VERSION = "10"


def default_database() -> Path:
    local_app_data = Path(os.environ.get("LOCALAPPDATA", ""))
    return (
        local_app_data
        / "Firaxis Games"
        / "Sid Meier's Civilization VI"
        / "Cache"
        / "DebugGameplay.sqlite"
    )


def database_files(modinfo: Path) -> list[Path]:
    root = ET.parse(modinfo).getroot()
    files: list[Path] = []
    for action in root.findall("./InGameActions/UpdateDatabase"):
        files.extend(modinfo.parent / node.text for node in action.findall("File") if node.text)
    return files


def declared_files(modinfo: Path) -> list[Path]:
    root = ET.parse(modinfo).getroot()
    result: list[Path] = []
    for node in root.findall("./Files/File"):
        if node.text:
            result.append(modinfo.parent / node.text)
    for node in root.findall("./InGameActions/AddGameplayScripts/File"):
        if node.text:
            result.append(modinfo.parent / node.text)
    return result


def foreign_key_errors(connection: sqlite3.Connection) -> set[tuple[object, ...]]:
    return {tuple(row) for row in connection.execute("PRAGMA foreign_key_check")}


def register_game_sql_functions(connection: sqlite3.Connection) -> None:
    def make_hash(value: object) -> int:
        raw = str(value).encode("utf-8")
        unsigned = zlib.crc32(raw)
        return unsigned if unsigned < 2**31 else unsigned - 2**32

    connection.create_function("Make_Hash", 1, make_hash)


def validate_items(connection: sqlite3.Connection) -> list[str]:
    errors: list[str] = []
    rows = connection.execute(
        """
        SELECT l.ListType, l.System, f.Item
        FROM AiLists AS l
        JOIN AiFavoredItems AS f ON f.ListType = l.ListType
        WHERE l.ListType LIKE 'ASAI_%'
        ORDER BY l.ListType, f.Item
        """
    )
    for list_type, system, item in rows:
        mapping = ITEM_TABLES.get(system)
        if mapping is None or item in EXPANSION_ONLY_ITEMS:
            continue
        table, column = mapping
        found = connection.execute(
            f"SELECT 1 FROM {table} WHERE {column} = ? LIMIT 1", (item,)
        ).fetchone()
        if found is None:
            errors.append(f"{list_type}: {item} is not valid for {system}")
    return errors


def lua_format_counts(source: str, marker: str) -> tuple[int, int] | None:
    marker_position = source.find(f'"{marker}')
    if marker_position < 0:
        return None
    call_position = source.rfind("string.format(", 0, marker_position)
    if call_position < 0:
        return None

    index = call_position + len("string.format(")
    depth = 0
    commas = 0
    quote = ""
    escaped = False
    end_position = -1
    while index < len(source):
        character = source[index]
        if quote:
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == quote:
                quote = ""
        elif character in ('"', "'"):
            quote = character
        elif character in "([{":
            depth += 1
        elif character in ")]}":
            if character == ")" and depth == 0:
                end_position = index
                break
            depth -= 1
        elif character == "," and depth == 0:
            commas += 1
        index += 1
    if end_position < 0:
        return None

    body = source[call_position + len("string.format(") : end_position]
    format_match = re.match(r'\s*"([^"\\]*(?:\\.[^"\\]*)*)"', body, re.DOTALL)
    if format_match is None:
        return None
    placeholders = len(
        re.findall(r"%(?!%)(?:[-+0 #]*\d*(?:\.\d+)?[a-zA-Z])", format_match.group(1))
    )
    # The first top-level comma separates the format string from its first
    # value, so the comma count equals the number of supplied value arguments.
    return placeholders, commas


def validate_lua_functions(connection: sqlite3.Connection, lua_file: Path) -> list[str]:
    source = lua_file.read_text(encoding="utf-8")
    errors: list[str] = []
    safe_functions = set(
        re.findall(
            r"function\s+(ASAI_Is[A-Za-z0-9_]+)\s*\([^)]*\)\s*"
            r"return\s+RunStrategyCondition\(",
            source,
        )
    )
    functions = connection.execute(
        """
        SELECT DISTINCT StringValue
        FROM StrategyConditions
        WHERE StrategyType LIKE 'ASAI_%'
          AND ConditionFunction = 'Call Lua Function'
        """
    )
    for (name,) in functions:
        if f"function {name}(" not in source:
            errors.append(f"Lua function is missing: {name}")
        if f"GameEvents.{name}.Add({name})" not in source:
            errors.append(f"GameEvents registration is missing: {name}")
        if name not in safe_functions:
            errors.append(f"Lua strategy condition is not fail-closed: {name}")

    if "pcall(evaluator, playerID, threshold)" not in source:
        errors.append("Lua strategy condition guard does not use pcall")
    if "pcall(WriteMetrics, playerID, firstTimeThisTurn)" not in source:
        errors.append("Lua metrics logger is not fail-closed")
    if "pcall(EvaluateRelativeState, playerID)" not in source:
        errors.append("Lua per-turn relative evaluator is not fail-closed")
    if "GetNumOutgoingRoutes" in source:
        errors.append("GetNumOutgoingRoutes is unavailable in gameplay-script context")
    if "GetMilitaryStrengthWithoutTreasury" in source or ":GetMilitaryStrength()" in source:
        errors.append("player military-strength methods are unavailable in gameplay-script context")
    if "tonumber(player:GetProperty(" in source:
        errors.append("player properties must be stored before numeric conversion")
    if "local function EstimateMilitaryStrength(player)" not in source:
        errors.append("gameplay-safe military strength estimator is missing")
    for marker in ("ASAI_SUPPORT", "ASAI_RECOVERY", "ASAI_METRIC", "ASAI_COMPONENTS"):
        counts = lua_format_counts(source, marker)
        if counts is None:
            errors.append(f"Lua format call could not be parsed: {marker}")
        elif counts[0] != counts[1]:
            errors.append(
                f"Lua format argument mismatch for {marker}: "
                f"{counts[0]} placeholders, {counts[1]} arguments"
            )
    war_fragments = (
        "local function CountWarsByOpponentType(playerID, player)",
        "PlayerManager.GetAliveIDs()",
        "not otherPlayer:IsBarbarian()",
        "if otherPlayer:IsMajor() then",
        "MajorWars = majorWars",
        "MinorWars = minorWars",
        "local function CountActiveMajorWars(player, majorOpponents, turn)",
        "ASAI_WAR_FRONT_CITY_DISTANCE",
        "ASAI_WAR_RECENT_COMBAT_STANDARD",
        "ASAI_LAST_MAJOR_COMBAT_TURN",
        "and #majorOpponents > 0",
        "pcall(\n        RecordUnitDamage",
        "return GetSnapshot(playerID).ActiveMajorWars > 0",
        "Events.UnitDamageChanged.Add(OnUnitDamageChanged)",
        "active_major_wars=%d",
    )
    for fragment in war_fragments:
        if fragment not in source:
            errors.append(f"major/minor war classification fragment is missing: {fragment}")
    timing_fragments = (
        "local function GetGameSpeedMultiplier()",
        "local function ScaleStandardTurns(standardTurns)",
        'ASAI_RELATIVE_START_TURN_STANDARD", 35',
        'ASAI_RELATIVE_CHECK_INTERVAL_STANDARD", 4',
        "relativeState.EvaluatedThisTurn",
        "evaluated_turn=%d",
        "ASAI_COMPONENTS",
    )
    for fragment in timing_fragments:
        if fragment not in source:
            errors.append(f"relative timing/telemetry fragment is missing: {fragment}")
    focus_fragments = (
        "local function GetDesiredFocus(state, recoveryThresholds, turn)",
        "ASAI_RELATIVE_FOCUS_SWITCH_MARGIN_X100",
        "local function ReviewActiveFocus(state, turn)",
        "ASAI_RELATIVE_FOCUS_REVIEW_STANDARD",
        "ASAI_RELATIVE_FOCUS_STALL_COOLDOWN_STANDARD",
        "RELATIVE_FOCUS_HANDOFF_PROPERTY",
        "FocusHandoffReady = false",
        "state.FocusHandoffReady = true",
        "local canChangeFocus = state.FocusHandoffReady",
        "and turn - state.FocusChangedTurn >= minimumDwell",
        "handoff_ready=%d",
        "state.FocusCooldownUntil[focus]",
        "SyncRecoveryFlags(state)",
    )
    for fragment in focus_fragments:
        if fragment not in source:
            errors.append(f"single-focus recovery fragment is missing: {fragment}")
    support_fragments = (
        "local function GetSecondWeakestCorePillarScore(state)",
        "local function GetDesiredSevereCatchup(state)",
        "ASAI_RELATIVE_SEVERE_ENTER_X100",
        "ASAI_RELATIVE_SEVERE_EXIT_X100",
        "ASAI_RELATIVE_SEVERE_CORE_ENTER_X100",
        "ASAI_RELATIVE_SEVERE_CORE_EXIT_X100",
        "or secondCore <= coreEnter",
        "or secondCore < coreExit",
        "function ASAI_IsRelativeSevereCatchup(playerID, threshold)",
        "second_core=%.3f",
        "support=%s",
    )
    for fragment in support_fragments:
        if fragment not in source:
            errors.append(f"bounded support fragment is missing: {fragment}")
    infrastructure_fragments = (
        'ASAI_INFRA_START_TURN_STANDARD", 20',
        'ASAI_INFRA_IMPROVEMENTS_PER_CITY_X100", 200',
        'ASAI_INFRA_IMPROVEMENTS_PER_POP_X100", 65',
        'ASAI_INFRA_OWNED_PLOTS_CAP_X100", 30',
        "local function CountInFlightUnits(player)",
        "buildQueue:GetCurrentProductionTypeHash()",
        "ASAI_QUEUE_API mode=current_production_hash coverage=current_only",
        "snapshot.InFlightBuilders",
        "snapshot.InFlightTraders",
        "math.max(cityFloor, math.min(populationTarget, landCap))",
        "builder_budget=%d",
        "trader_budget=%d",
        "settler_budget=%d",
    )
    for fragment in infrastructure_fragments:
        if fragment not in source:
            errors.append(f"infrastructure target fragment is missing: {fragment}")
    for unavailable_method in ("buildQueue:GetSize()", "buildQueue:GetAt("):
        if unavailable_method in source:
            errors.append(
                "gameplay script still uses a UI-only build-queue method: "
                f"{unavailable_method}"
            )
    civilian_budget_fragments = (
        "local function IsBuilderBudgetReachedSnapshot(snapshot)",
        "local function IsTraderBudgetReachedSnapshot(snapshot)",
        "local function IsSettlerBudgetReachedSnapshot(snapshot)",
        "function ASAI_IsBuilderBudgetReached(playerID, threshold)",
        "function ASAI_IsTraderBudgetReached(playerID, threshold)",
        "function ASAI_IsSettlerBudgetReached(playerID, threshold)",
        "snapshot.Settlers + snapshot.InFlightSettlers",
    )
    for fragment in civilian_budget_fragments:
        if fragment not in source:
            errors.append(f"civilian budget fragment is missing: {fragment}")
    expansion_fragments = (
        "local function IsExpansionRecovery(playerID, threshold)",
        "ASAI_EXPANSION_CITIES_PER_INFLIGHT_SETTLER",
        "snapshot.Settlers + snapshot.InFlightSettlers < maximumInFlight",
        "function ASAI_IsExpansionRecovery(playerID, threshold)",
        "settlers_inflight=%d",
    )
    for fragment in expansion_fragments:
        if fragment not in source:
            errors.append(f"expansion budget fragment is missing: {fragment}")
    return errors


def validate_invariants(connection: sqlite3.Connection) -> list[str]:
    errors: list[str] = []
    ai_settlers = connection.execute(
        """
        SELECT COUNT(*) FROM MajorStartingUnits
        WHERE Era = 'ERA_ANCIENT' AND AiOnly = 1 AND Unit = 'UNIT_SETTLER'
        """
    ).fetchone()[0]
    if ai_settlers != 0:
        errors.append(f"expected no free Ancient AI settlers, found {ai_settlers}")

    expected_arguments = {
        ("ASAI_DEITY_OPENING_SCIENCE", "Amount"): "-22",
        ("ASAI_DEITY_OPENING_PRODUCTION", "Amount"): "-60",
        ("ASAI_DEITY_INFORMATION_SCIENCE", "Amount"): "8",
        ("ASAI_DEITY_INFORMATION_PRODUCTION", "Amount"): "15",
        ("ASAI_DEITY_OPENING_COMBAT", "Amount"): "-3",
        ("ASAI_DEITY_MODERN_COMBAT", "Amount"): "1",
    }
    for key, expected in expected_arguments.items():
        row = connection.execute(
            "SELECT Value FROM ModifierArguments WHERE ModifierId = ? AND Name = ?", key
        ).fetchone()
        actual = None if row is None else str(row[0])
        if actual != expected:
            errors.append(f"modifier argument {key} expected {expected}, found {actual}")

    unattached = connection.execute(
        """
        SELECT COUNT(*)
        FROM Modifiers AS m
        LEFT JOIN TraitModifiers AS t
          ON t.ModifierId = m.ModifierId
         AND t.TraitType = 'TRAIT_LEADER_MAJOR_CIV'
        WHERE m.ModifierId LIKE 'ASAI_DEITY_%'
          AND t.ModifierId IS NULL
        """
    ).fetchone()[0]
    if unattached:
        errors.append(f"found {unattached} unattached Deity modifiers")

    for pseudo_yield in (
        "PSEUDOYIELD_IMPROVEMENT",
        "PSEUDOYIELD_UNIT_TRADE",
        "PSEUDOYIELD_UNIT_AIR_COMBAT",
    ):
        value = connection.execute(
            "SELECT DefaultValue FROM PseudoYields WHERE PseudoYieldType = ?",
            (pseudo_yield,),
        ).fetchone()[0]
        if value < 4.0:
            errors.append(f"{pseudo_yield} expected at least 4.0, found {value}")

    walled = connection.execute(
        """
        SELECT MustHaveUnits, MaxTargetDistInArea
        FROM AiOperationDefs WHERE OperationName = 'Attack Walled City'
        """
    ).fetchone()
    if walled != (7, 10):
        errors.append(f"walled-city operation expected (7, 10), found {walled}")
    return errors


def validate_relative_pacing(connection: sqlite3.Connection) -> list[str]:
    errors: list[str] = []
    obsolete_parameters = (
        "ASAI_METRICS_INTERVAL",
        "ASAI_INFRA_START_TURN",
        "ASAI_RELATIVE_START_TURN",
        "ASAI_RELATIVE_CHECK_INTERVAL",
        "ASAI_RELATIVE_TRAILING_ENTER_X100",
        "ASAI_RELATIVE_TRAILING_EXIT_X100",
        "ASAI_RELATIVE_LEADING_EXIT_X100",
        "ASAI_RELATIVE_LEADING_ENTER_X100",
        "ASAI_RELATIVE_LEADING_PILLAR_MIN_X100",
    )
    obsolete_placeholders = ", ".join("?" for _ in obsolete_parameters)
    obsolete_found = [
        row[0]
        for row in connection.execute(
            f"SELECT Name FROM GlobalParameters "
            f"WHERE Name IN ({obsolete_placeholders}) ORDER BY Name",
            obsolete_parameters,
        )
    ]
    if obsolete_found:
        errors.append(f"obsolete pacing parameters remain: {obsolete_found}")

    parameter_names = (
        "ASAI_RELATIVE_PACING_ENABLED",
        "ASAI_EXPANSION_CITIES_PER_INFLIGHT_SETTLER",
        "ASAI_WAR_FRONT_CITY_DISTANCE",
        "ASAI_WAR_RECENT_COMBAT_STANDARD",
        "ASAI_WAR_COMBAT_ATTRIBUTION_DISTANCE",
        "ASAI_RELATIVE_START_TURN_STANDARD",
        "ASAI_RELATIVE_CHECK_INTERVAL_STANDARD",
        "ASAI_RELATIVE_MIN_DWELL_STANDARD",
        "ASAI_RELATIVE_COOLDOWN_STANDARD",
        "ASAI_RELATIVE_CONFIRM_SAMPLES",
        "ASAI_RELATIVE_EMA_ALPHA_X100",
        "ASAI_RELATIVE_FOCUS_SWITCH_MARGIN_X100",
        "ASAI_RELATIVE_FOCUS_REVIEW_STANDARD",
        "ASAI_RELATIVE_FOCUS_MIN_GAIN_X100",
        "ASAI_RELATIVE_FOCUS_RAW_MIN_GAIN_X100",
        "ASAI_RELATIVE_FOCUS_STALL_COOLDOWN_STANDARD",
        "ASAI_RELATIVE_SEVERE_ENTER_X100",
        "ASAI_RELATIVE_SEVERE_EXIT_X100",
        "ASAI_RELATIVE_SEVERE_CORE_ENTER_X100",
        "ASAI_RELATIVE_SEVERE_CORE_EXIT_X100",
        "ASAI_RELATIVE_EARLY_TRAILING_ENTER_X100",
        "ASAI_RELATIVE_EARLY_TRAILING_EXIT_X100",
        "ASAI_RELATIVE_EARLY_LEADING_EXIT_X100",
        "ASAI_RELATIVE_EARLY_LEADING_ENTER_X100",
        "ASAI_RELATIVE_EARLY_LEADING_PILLAR_MIN_X100",
        "ASAI_RELATIVE_MID_TRAILING_ENTER_X100",
        "ASAI_RELATIVE_MID_TRAILING_EXIT_X100",
        "ASAI_RELATIVE_MID_LEADING_EXIT_X100",
        "ASAI_RELATIVE_MID_LEADING_ENTER_X100",
        "ASAI_RELATIVE_MID_LEADING_PILLAR_MIN_X100",
        "ASAI_RELATIVE_LATE_TRAILING_ENTER_X100",
        "ASAI_RELATIVE_LATE_TRAILING_EXIT_X100",
        "ASAI_RELATIVE_LATE_LEADING_EXIT_X100",
        "ASAI_RELATIVE_LATE_LEADING_ENTER_X100",
        "ASAI_RELATIVE_LATE_LEADING_PILLAR_MIN_X100",
        "ASAI_RELATIVE_COMPONENT_MIN_X100",
        "ASAI_RELATIVE_COMPONENT_MAX_X100",
        "ASAI_RELATIVE_MILITARY_MAX_X100",
        "ASAI_RELATIVE_SCIENCE_ENTER_X100",
        "ASAI_RELATIVE_SCIENCE_EXIT_X100",
        "ASAI_RELATIVE_CULTURE_ENTER_X100",
        "ASAI_RELATIVE_CULTURE_EXIT_X100",
        "ASAI_RELATIVE_EMPIRE_ENTER_X100",
        "ASAI_RELATIVE_EMPIRE_EXIT_X100",
        "ASAI_RELATIVE_WEIGHT_TECHS",
        "ASAI_RELATIVE_WEIGHT_CIVICS",
        "ASAI_RELATIVE_WEIGHT_SCIENCE",
        "ASAI_RELATIVE_WEIGHT_CULTURE",
        "ASAI_RELATIVE_WEIGHT_CITIES",
        "ASAI_RELATIVE_WEIGHT_POPULATION",
        "ASAI_RELATIVE_WEIGHT_MILITARY",
    )
    parameters: dict[str, int] = {}
    for name in parameter_names:
        row = connection.execute(
            "SELECT Value FROM GlobalParameters WHERE Name = ?", (name,)
        ).fetchone()
        if row is None:
            errors.append(f"missing relative pacing parameter: {name}")
            continue
        try:
            parameters[name] = int(row[0])
        except (TypeError, ValueError):
            errors.append(f"relative pacing parameter is not an integer: {name}={row[0]}")

    for stage in ("EARLY", "MID", "LATE"):
        threshold_names = tuple(
            f"ASAI_RELATIVE_{stage}_{suffix}"
            for suffix in (
                "TRAILING_ENTER_X100",
                "TRAILING_EXIT_X100",
                "LEADING_EXIT_X100",
                "LEADING_ENTER_X100",
            )
        )
        if all(name in parameters for name in threshold_names):
            values = [parameters[name] for name in threshold_names]
            if not values[0] < values[1] < 100 < values[2] < values[3]:
                errors.append(
                    f"relative {stage.lower()} thresholds are not ordered safely: {values}"
                )
        pillar_name = f"ASAI_RELATIVE_{stage}_LEADING_PILLAR_MIN_X100"
        pillar_minimum = parameters.get(pillar_name)
        if pillar_minimum is not None and not 0 < pillar_minimum <= 100:
            errors.append(
                f"relative {stage.lower()} leading pillar minimum is invalid: "
                f"{pillar_minimum}"
            )

    bounds = (
        parameters.get("ASAI_RELATIVE_COMPONENT_MIN_X100"),
        parameters.get("ASAI_RELATIVE_COMPONENT_MAX_X100"),
    )
    if None not in bounds and not 0 < bounds[0] < 100 < bounds[1]:
        errors.append(f"relative component bounds are invalid: {bounds}")

    military_maximum = parameters.get("ASAI_RELATIVE_MILITARY_MAX_X100")
    if None not in bounds and military_maximum is not None:
        if not 100 <= military_maximum <= bounds[1]:
            errors.append(
                "relative military cap must be between 100 and the component maximum: "
                f"{military_maximum}"
            )

    interval = parameters.get("ASAI_RELATIVE_CHECK_INTERVAL_STANDARD")
    minimum_dwell = parameters.get("ASAI_RELATIVE_MIN_DWELL_STANDARD")
    cooldown = parameters.get("ASAI_RELATIVE_COOLDOWN_STANDARD")
    confirm_samples = parameters.get("ASAI_RELATIVE_CONFIRM_SAMPLES")
    if interval is not None and interval <= 0:
        errors.append(f"relative evaluation interval must be positive: {interval}")
    if interval is not None and minimum_dwell is not None:
        if minimum_dwell < interval * 2:
            errors.append(
                "relative minimum dwell must cover at least two evaluation intervals: "
                f"{minimum_dwell} < {interval * 2}"
            )
    if cooldown is not None and cooldown < 0:
        errors.append(f"relative cooldown cannot be negative: {cooldown}")
    if confirm_samples is not None and confirm_samples < 2:
        errors.append(f"relative confirmation requires at least two samples: {confirm_samples}")
    expansion_cities = parameters.get("ASAI_EXPANSION_CITIES_PER_INFLIGHT_SETTLER")
    if expansion_cities is not None and expansion_cities <= 0:
        errors.append(
            f"expansion cities per in-flight settler must be positive: {expansion_cities}"
        )
    for name in (
        "ASAI_WAR_FRONT_CITY_DISTANCE",
        "ASAI_WAR_RECENT_COMBAT_STANDARD",
        "ASAI_WAR_COMBAT_ATTRIBUTION_DISTANCE",
    ):
        value = parameters.get(name)
        if value is not None and value <= 0:
            errors.append(f"active-war parameter must be positive: {name}={value}")
    ema_alpha = parameters.get("ASAI_RELATIVE_EMA_ALPHA_X100")
    if ema_alpha is not None and not 0 < ema_alpha <= 100:
        errors.append(f"relative EMA alpha is invalid: {ema_alpha}")
    focus_margin = parameters.get("ASAI_RELATIVE_FOCUS_SWITCH_MARGIN_X100")
    if focus_margin is not None and not 0 <= focus_margin <= 100:
        errors.append(f"relative focus switch margin is invalid: {focus_margin}")
    focus_review = parameters.get("ASAI_RELATIVE_FOCUS_REVIEW_STANDARD")
    focus_minimum_gain = parameters.get("ASAI_RELATIVE_FOCUS_MIN_GAIN_X100")
    focus_raw_minimum_gain = parameters.get("ASAI_RELATIVE_FOCUS_RAW_MIN_GAIN_X100")
    focus_stall_cooldown = parameters.get(
        "ASAI_RELATIVE_FOCUS_STALL_COOLDOWN_STANDARD"
    )
    if focus_review is not None and focus_review < 8:
        errors.append(f"relative focus review window is too short: {focus_review}")
    for name, value in (
        ("smoothed", focus_minimum_gain),
        ("raw", focus_raw_minimum_gain),
    ):
        if value is not None and not 0 <= value <= 25:
            errors.append(f"relative focus {name} minimum gain is invalid: {value}")
    if focus_stall_cooldown is not None and focus_stall_cooldown < 0:
        errors.append(
            f"relative focus stall cooldown cannot be negative: {focus_stall_cooldown}"
        )
    severe_enter = parameters.get("ASAI_RELATIVE_SEVERE_ENTER_X100")
    severe_exit = parameters.get("ASAI_RELATIVE_SEVERE_EXIT_X100")
    if (
        severe_enter is not None
        and severe_exit is not None
        and not 0 < severe_enter < severe_exit < 100
    ):
        errors.append(
            f"relative severe-support thresholds are invalid: {(severe_enter, severe_exit)}"
        )
    severe_core_enter = parameters.get("ASAI_RELATIVE_SEVERE_CORE_ENTER_X100")
    severe_core_exit = parameters.get("ASAI_RELATIVE_SEVERE_CORE_EXIT_X100")
    if (
        severe_core_enter is not None
        and severe_core_exit is not None
        and not 0 < severe_core_enter < severe_core_exit < 100
    ):
        errors.append(
            "relative severe core-collapse thresholds are invalid: "
            f"{(severe_core_enter, severe_core_exit)}"
        )
    if (severe_core_enter, severe_core_exit) != (78, 86):
        errors.append(
            "relative severe core-collapse thresholds differ from the replayed "
            f"0.5.2 profile: {(severe_core_enter, severe_core_exit)}"
        )

    for pillar in ("SCIENCE", "CULTURE", "EMPIRE"):
        enter = parameters.get(f"ASAI_RELATIVE_{pillar}_ENTER_X100")
        exit_ = parameters.get(f"ASAI_RELATIVE_{pillar}_EXIT_X100")
        if enter is not None and exit_ is not None and not 0 < enter < exit_ < 100:
            errors.append(
                f"relative {pillar.lower()} recovery thresholds are invalid: "
                f"{(enter, exit_)}"
            )

    weight_names = tuple(name for name in parameter_names if "_WEIGHT_" in name)
    if all(name in parameters for name in weight_names):
        weights = [parameters[name] for name in weight_names]
        if any(weight < 0 for weight in weights):
            errors.append(f"relative component weights cannot be negative: {weights}")
        if sum(weights) != 100:
            errors.append(f"relative component weights must total 100, found {sum(weights)}")

    expected_strategies = {
        "ASAI_STRATEGY_RELATIVE_CATCHUP",
        "ASAI_STRATEGY_RELATIVE_SEVERE_CATCHUP",
        "ASAI_STRATEGY_RELATIVE_CONSOLIDATE",
    }
    actual_strategies = {
        row[0]
        for row in connection.execute(
            "SELECT StrategyType FROM Strategies WHERE StrategyType LIKE 'ASAI_STRATEGY_RELATIVE_%'"
        )
    }
    if actual_strategies != expected_strategies:
        errors.append(
            "relative strategies differ: "
            f"expected {sorted(expected_strategies)}, found {sorted(actual_strategies)}"
        )

    expected_recovery_strategies = {
        "ASAI_STRATEGY_SCIENCE_RECOVERY",
        "ASAI_STRATEGY_CULTURE_RECOVERY",
        "ASAI_STRATEGY_EMPIRE_RECOVERY",
        "ASAI_STRATEGY_EXPANSION_RECOVERY",
    }
    recovery_placeholders = ", ".join("?" for _ in expected_recovery_strategies)
    actual_recovery_strategies = {
        row[0]
        for row in connection.execute(
            "SELECT StrategyType FROM Strategies "
            f"WHERE StrategyType IN ({recovery_placeholders})",
            tuple(sorted(expected_recovery_strategies)),
        )
    }
    if actual_recovery_strategies != expected_recovery_strategies:
        errors.append(
            "pillar recovery strategies differ: "
            f"expected {sorted(expected_recovery_strategies)}, "
            f"found {sorted(actual_recovery_strategies)}"
        )

    expected_budget_strategies = {
        "ASAI_STRATEGY_BUILDER_BUDGET",
        "ASAI_STRATEGY_TRADER_BUDGET",
        "ASAI_STRATEGY_SETTLER_BUDGET",
    }
    budget_placeholders = ", ".join("?" for _ in expected_budget_strategies)
    actual_budget_strategies = {
        row[0]
        for row in connection.execute(
            "SELECT StrategyType FROM Strategies "
            f"WHERE StrategyType IN ({budget_placeholders})",
            tuple(sorted(expected_budget_strategies)),
        )
    }
    if actual_budget_strategies != expected_budget_strategies:
        errors.append(
            "civilian budget strategies differ: "
            f"expected {sorted(expected_budget_strategies)}, "
            f"found {sorted(actual_budget_strategies)}"
        )

    expected_budget_values = {
        ("ASAI_BuilderBudgetPseudoYields", "PSEUDOYIELD_IMPROVEMENT"): -25,
        ("ASAI_BuilderBudgetUnits", "UNIT_BUILDER"): -50,
        ("ASAI_TraderBudgetPseudoYields", "PSEUDOYIELD_UNIT_TRADE"): -35,
        ("ASAI_TraderBudgetUnits", "UNIT_TRADER"): -50,
        ("ASAI_SettlerBudgetPseudoYields", "PSEUDOYIELD_UNIT_SETTLER"): -45,
        ("ASAI_SettlerBudgetUnits", "UNIT_SETTLER"): -50,
    }
    for (list_type, item), expected in expected_budget_values.items():
        row = connection.execute(
            "SELECT Value FROM AiFavoredItems WHERE ListType = ? AND Item = ?",
            (list_type, item),
        ).fetchone()
        actual = None if row is None else row[0]
        if actual != expected:
            errors.append(
                f"civilian budget {list_type}/{item} expected {expected}, found {actual}"
            )

    oversized = list(
        connection.execute(
            """
            SELECT ListType, Item, Value
            FROM AiFavoredItems
            WHERE (ListType LIKE 'ASAI_Relative%'
                   OR ListType LIKE 'ASAI_ScienceRecovery%'
                   OR ListType LIKE 'ASAI_CultureRecovery%'
                   OR ListType LIKE 'ASAI_EmpireRecovery%'
                   OR ListType LIKE 'ASAI_ExpansionRecovery%')
              AND ABS(Value) > 60
            ORDER BY ListType, Item
            """
        )
    )
    errors.extend(
        f"targeted recovery adjustment exceeds 60: {list_type}/{item}={value}"
        for list_type, item, value in oversized
    )

    severe_oversized = list(
        connection.execute(
            """
            SELECT ListType, Item, Value
            FROM AiFavoredItems
            WHERE ListType LIKE 'ASAI_RelativeSevere%'
              AND ABS(Value) > 20
            ORDER BY ListType, Item
            """
        )
    )
    errors.extend(
        f"severe catch-up guardrail exceeds 20: {list_type}/{item}={value}"
        for list_type, item, value in severe_oversized
    )

    broad_guardrail_oversized = list(
        connection.execute(
            """
            SELECT ListType, Item, Value
            FROM AiFavoredItems
            WHERE ListType LIKE 'ASAI_RelativeCatchup%'
              AND ABS(Value) > 12
            ORDER BY ListType, Item
            """
        )
    )
    errors.extend(
        f"broad catch-up guardrail exceeds 12: {list_type}/{item}={value}"
        for list_type, item, value in broad_guardrail_oversized
    )
    lead_penalties = list(
        connection.execute(
            """
            SELECT ListType, Item, Value
            FROM AiFavoredItems
            WHERE ListType LIKE 'ASAI_RelativeLead%'
              AND Value < 0
            ORDER BY ListType, Item
            """
        )
    )
    errors.extend(
        f"leading AI still receives a self-sabotaging penalty: "
        f"{list_type}/{item}={value}"
        for list_type, item, value in lead_penalties
    )

    expected_culture_buildings = {
        "BUILDING_AMPHITHEATER",
        "BUILDING_MUSEUM_ART",
        "BUILDING_MUSEUM_ARTIFACT",
        "BUILDING_BROADCAST_CENTER",
    }
    for list_type in ("ASAI_CultureRecoveryBuildings", "ASAI_CultureBuildings"):
        actual_culture_buildings = {
            row[0]
            for row in connection.execute(
                "SELECT Item FROM AiFavoredItems WHERE ListType = ?",
                (list_type,),
            )
        }
        if actual_culture_buildings != expected_culture_buildings:
            errors.append(
                f"{list_type} differs: "
                f"expected {sorted(expected_culture_buildings)}, "
                f"found {sorted(actual_culture_buildings)}"
            )

    forbidden_wonder_lists = (
        "ASAI_GoldWonders",
        "ASAI_RelativeCatchupWonders",
        "ASAI_RelativeLeadWonders",
        "ASAI_ScienceRecoveryWonders",
        "ASAI_CultureRecoveryWonders",
        "ASAI_EmpireRecoveryWonders",
    )
    wonder_placeholders = ", ".join("?" for _ in forbidden_wonder_lists)
    forbidden_wonders = connection.execute(
        f"SELECT COUNT(*) FROM AiFavoredItems WHERE ListType IN ({wonder_placeholders})",
        forbidden_wonder_lists,
    ).fetchone()[0]
    if forbidden_wonders:
        errors.append(
            f"found {forbidden_wonders} stackable non-war wonder penalties"
        )
    war_wonder_values = {
        row[0]
        for row in connection.execute(
            "SELECT DISTINCT Value FROM AiFavoredItems "
            "WHERE ListType = 'ASAI_WarWonders'"
        )
    }
    if war_wonder_values != {-35}:
        errors.append(
            f"major-war wonder penalty expected only -35, found {sorted(war_wonder_values)}"
        )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Adaptive Strategic AI without modifying the game cache.")
    parser.add_argument("--db", type=Path, default=default_database())
    args = parser.parse_args()

    mod_root = Path(__file__).resolve().parents[1]
    modinfo = mod_root / "AdaptiveStrategicAI.modinfo"
    lua_file = mod_root / "Lua" / "AdaptiveStrategicAI.lua"
    errors: list[str] = []

    try:
        modinfo_root = ET.parse(modinfo).getroot()
    except (OSError, ET.ParseError) as error:
        print(f"modinfo error: {error}")
        return 1

    if modinfo_root.get("version") != EXPECTED_MODINFO_VERSION:
        errors.append(
            "modinfo version differs: "
            f"expected {EXPECTED_MODINFO_VERSION}, "
            f"found {modinfo_root.get('version')}"
        )

    for path in declared_files(modinfo):
        if not path.is_file():
            errors.append(f"declared file is missing: {path.relative_to(mod_root)}")

    if not args.db.is_file():
        errors.append(f"reference database is missing: {args.db}")
    else:
        with sqlite3.connect(args.db) as source, sqlite3.connect(":memory:") as target:
            source.backup(target)
            register_game_sql_functions(target)
            baseline_fk = foreign_key_errors(target)
            target.execute("PRAGMA foreign_keys = ON")
            for sql_file in database_files(modinfo):
                try:
                    target.executescript(sql_file.read_text(encoding="utf-8"))
                except (OSError, sqlite3.Error) as error:
                    errors.append(f"{sql_file.name}: {error}")
                    break
            else:
                new_fk = foreign_key_errors(target) - baseline_fk
                errors.extend(f"new foreign-key error: {row}" for row in sorted(new_fk))
                errors.extend(validate_items(target))
                errors.extend(validate_lua_functions(target, lua_file))
                errors.extend(validate_invariants(target))
                errors.extend(validate_relative_pacing(target))
                strategy_count = target.execute(
                    "SELECT COUNT(*) FROM Strategies WHERE StrategyType LIKE 'ASAI_%'"
                ).fetchone()[0]
                if strategy_count != 15:
                    errors.append(f"expected 15 adaptive strategies, found {strategy_count}")
                release = target.execute(
                    "SELECT Value FROM GlobalParameters WHERE Name = 'ASAI_VERSION'"
                ).fetchone()
                if release is None or str(release[0]) != EXPECTED_RELEASE:
                    errors.append(
                        "database release differs: "
                        f"expected {EXPECTED_RELEASE}, "
                        f"found {None if release is None else release[0]}"
                    )

    if errors:
        print("VALIDATION FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    print("VALIDATION PASSED")
    print(f"- release: {EXPECTED_RELEASE} (modinfo {EXPECTED_MODINFO_VERSION})")
    print(f"- modinfo: {modinfo.name}")
    print(f"- database scripts: {len(database_files(modinfo))}")
    print("- adaptive strategies: 15 (including support, recovery, and civilian budgets)")
    print("- game cache was not modified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
