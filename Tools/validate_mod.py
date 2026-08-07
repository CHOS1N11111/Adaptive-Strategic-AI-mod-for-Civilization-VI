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

EXPECTED_RELEASE = "0.8.6"
EXPECTED_MODINFO_VERSION = "19"


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
    if "pcall(\n        WriteEconomicDiagnostics" not in source:
        errors.append("economic diagnostics logger is not independently fail-closed")
    if "pcall(\n        WriteMilitaryDiagnostics" not in source:
        errors.append("military diagnostics logger is not independently fail-closed")
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
    for marker in (
        "ASAI_SUPPORT",
        "ASAI_RESULT turn=",
        "ASAI_SCALE turn=",
        "ASAI_READINESS",
        "ASAI_RECOVERY",
        "ASAI_METRIC",
        "ASAI_COMPONENTS",
        "ASAI_ECONOMY",
        "ASAI_CONVERSION",
        "ASAI_MILITARY turn=",
        "ASAI_FOCUS",
        "ASAI_DIAGNOSTIC_ERROR",
    ):
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
        "local function ReviewActiveFocus(playerID, state, turn)",
        "ASAI_RELATIVE_FOCUS_REVIEW_STANDARD",
        "ASAI_RELATIVE_FOCUS_STALL_LIMIT",
        "ASAI_RELATIVE_FOCUS_STALL_COOLDOWN_STANDARD",
        '"focus_production_" .. tostring(playerID)',
        "state.FocusExecution = focusExecutionOk == 1 and focusExecution or -1",
        'ASAI_RELATIVE_FOCUS_REVIEW_STANDARD", 12',
        "queue_response=%d",
        "stall_count=%d",
        "local function IsFocusExecutionRecovery(playerID, focus)",
        "state.FocusResult == RELATIVE_FOCUS_RESULT_STALLED",
        "or state.FocusResult == RELATIVE_FOCUS_RESULT_EXECUTING",
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
        "local function GetWeakestCorePillarScore(state)",
        "local function GetDesiredSevereCatchup(state)",
        "ASAI_RELATIVE_SEVERE_ENTER_X100",
        "ASAI_RELATIVE_SEVERE_EXIT_X100",
        "ASAI_RELATIVE_SEVERE_CORE_ENTER_X100",
        "ASAI_RELATIVE_SEVERE_CORE_EXIT_X100",
        "ASAI_RELATIVE_SEVERE_WEAKEST_ENTER_X100",
        "ASAI_RELATIVE_SEVERE_WEAKEST_EXIT_X100",
        "or secondCore <= coreEnter",
        "or secondCore < coreExit",
        "or weakestCore <= weakestEnter",
        "or weakestCore < weakestExit",
        "function ASAI_IsRelativeSevereCatchup(playerID, threshold)",
        "second_core=%.3f",
        "weakest_core=%.3f",
        "support=%s",
    )
    for fragment in support_fragments:
        if fragment not in source:
            errors.append(f"bounded support fragment is missing: {fragment}")
    severe_result_fragments = (
        "SEVERE_RESULT_YIELDS_ACTIVE_PROPERTY",
        'SEVERE_RESULT_YIELDS_ON_MODIFIER = "ASAI_SEVERE_RESULT_YIELDS_ON"',
        'SEVERE_RESULT_YIELDS_OFF_MODIFIER = "ASAI_SEVERE_RESULT_YIELDS_OFF"',
        "SEVERE_RESULT_PRODUCTION_PERCENT = 40",
        "SEVERE_RESULT_SCIENCE_PERCENT = 30",
        "SEVERE_RESULT_CULTURE_PERCENT = 30",
        "SevereResultYieldsActive = 0",
        "local function SyncSevereResultYields(playerID, player, state, turn)",
        "ASAI_SEVERE_RESULT_YIELDS_ENABLED",
        "enabled and state.SevereCatchup == 1",
        "player:AttachModifierByID(modifierID)",
        "state.SevereResultYieldsActive = desiredActive and 1 or 0",
        "state.SevereResultYieldsActive\n    )",
        "player:SetProperty(\n        SEVERE_RESULT_YIELDS_ACTIVE_PROPERTY",
        "SyncSevereResultYields(playerID, player, state, turn)",
        "ASAI_RESULT turn=%d standard_turn=%.1f",
        "result_yields=%d",
    )
    for fragment in severe_result_fragments:
        if fragment not in source:
            errors.append(f"severe result-yield fragment is missing: {fragment}")
    if "DetachModifierByID" in source:
        errors.append("Lua must not rely on the unavailable modifier detach API")
    military_readiness_fragments = (
        "local function GetDesiredMilitaryReadiness(state, densityEnabled)",
        "ASAI_MILITARY_READINESS_ENTER_X100",
        "ASAI_MILITARY_READINESS_EXIT_X100",
        "ASAI_MILITARY_READINESS_EMERGENCY_X100",
        "ASAI_MILITARY_DENSITY_START_STANDARD",
        "ASAI_MILITARY_UNITS_PER_PLANNED_CITY_ENTER_X100",
        "ASAI_MILITARY_UNITS_PER_PLANNED_CITY_EXIT_X100",
        "state.MilitaryPlannedCities = strengthSnapshot.Cities + plannedExpansion",
        "state.MilitaryUnitsPerPlannedCity",
        "local densityEnabled = turn >= densityStartTurn",
        "local militaryDensityGap = densityEnabled",
        "state.RawScores.Military <= emergencyThreshold",
        "if state.MilitaryReadiness == 0\n            and militaryEmergency then",
        "state.MilitaryReadinessCooldownUntil",
        "MILITARY_READINESS_PROPERTY",
        "function ASAI_IsMilitaryReadiness(playerID, threshold)",
        "local function GetMilitaryQueueTarget(snapshot)",
        "ASAI_MILITARY_QUEUE_TARGET_X100",
        "ASAI_WAR_QUEUE_TARGET_X100",
        "local function GetMilitaryExecutionStatus(playerID)",
        "economic.Queue.Combat < target",
        "function ASAI_IsMilitaryExecutionRecovery(playerID, threshold)",
        "ASAI_READINESS turn=%d standard_turn=%.1f",
        'militaryDensityGap and "force_density" or "sustained_gap"',
        "military_readiness=%d",
        "queue_target=%d",
        "military_execution=%d",
    )
    for fragment in military_readiness_fragments:
        if fragment not in source:
            errors.append(f"military readiness fragment is missing: {fragment}")
    scale_recovery_fragments = (
        "local function GetDesiredScaleRecovery(state)",
        "ASAI_SCALE_RECOVERY_START_STANDARD",
        "ASAI_SCALE_RECOVERY_ENTER_X100",
        "ASAI_SCALE_RECOVERY_EXIT_X100",
        "ASAI_SCALE_RECOVERY_EMERGENCY_X100",
        "state.RawScores.Empire <= scaleEmergencyThreshold",
        "state.ScaleRecoveryCooldownUntil",
        "SCALE_RECOVERY_PROPERTY",
        "player:SetProperty(SCALE_RECOVERY_PROPERTY, state.ScaleRecovery)",
        "local function UpdateScaleExpansionAvailability(state, snapshot)",
        "SCALE_EXPANSION_ALLOWED_PROPERTY",
        "state.ScaleExpansionAllowed",
        "SCALE_EXPANSION_ALLOWED_PROPERTY,\n        state.ScaleExpansionAllowed",
        "function ASAI_IsScaleRecovery(playerID, threshold)",
        "ASAI_SCALE turn=%d standard_turn=%.1f",
        "scale_recovery=%d",
        "scale_expansion=%d",
    )
    for fragment in scale_recovery_fragments:
        if fragment not in source:
            errors.append(f"scale recovery fragment is missing: {fragment}")
    diagnostic_fragments = (
        "local function TryDiagnosticSensor(sensorName, collector)",
        "ASAI_DIAGNOSTIC_ERROR sensor=%s fallback=missing",
        "local function CollectProductionDiagnostics(player)",
        'GameInfo.Yields["YIELD_PRODUCTION"]',
        "city:GetYield(productionYield.Index)",
        "local function GetCurrentProductionType(city)",
        "buildQueue:CurrentlyBuilding()",
        "ASAI_QUEUE_API mode=currently_building coverage=current_only",
        "local function CollectQueueDiagnostics(player)",
        "queue_wonders=%d",
        "queue_science=%d",
        "queue_culture=%d",
        "queue_empire=%d",
        "local function CollectDistrictDiagnostics(player)",
        "player:GetDistricts()",
        "districtInfo.RequiresPopulation == true",
        "district:IsComplete()",
        "local function GetEconomicSnapshot(playerID)",
        '"production_queue"',
        '"district_capacity"',
        "RoutePipelineCoverage = snapshot.RouteCapacity > 0",
        "ImprovementPipelineCoverage = infrastructureTarget > 0",
        "ResourceSupported = 0",
        "UpgradeSupported = 0",
        "local function GetHumanEconomicReference()",
        "local function WriteEconomicDiagnostics(playerID, firstTimeThisTurn)",
        "ASAI_ECONOMY turn=%d evaluated_turn=%d",
        "ASAI_CONVERSION turn=%d evaluated_turn=%d",
        "production_ratio=%.3f",
        "district_util=%.3f",
        "route_coverage=%.3f",
        "improvement_coverage=%.3f",
        "queue_units=%d",
        "gold_surplus=%.1f",
        "production_ok=%d",
        "queue_ok=%d",
        "resource_supported=%d",
        "upgrade_supported=%d",
        "local function GetUnitBaseStrength(unitInfo)",
        "local function AddMilitaryRole(profile, unitInfo)",
        "local function CollectDefenseDiagnostics(player)",
        "local function WriteMilitaryDiagnostics(playerID, firstTimeThisTurn)",
        "ASAI_MILITARY turn=%d evaluated_turn=%d",
        "planned_cities=%d",
        "units_per_planned_city=%.2f",
        "queue_combat=%d",
        "defense_coverage=%.3f",
        "defense_supported=%d",
    )
    for fragment in diagnostic_fragments:
        if fragment not in source:
            errors.append(f"economic diagnostic fragment is missing: {fragment}")
    component_block = re.search(
        r"local RELATIVE_COMPONENTS = \{(.*?)\n\};",
        source,
        re.DOTALL,
    )
    if component_block is None:
        errors.append("relative component table could not be parsed")
    elif 'Key = "Production"' in component_block.group(1):
        errors.append("diagnostic production entered the relative component table")
    if "ASAI_RELATIVE_WEIGHT_PRODUCTION" in source:
        errors.append("diagnostic production must not enter the relative score in 0.8.6")
    infrastructure_fragments = (
        "local function IsOpeningExpansion(playerID, threshold)",
        'ASAI_OPENING_EXPANSION_END_STANDARD", 70',
        'ASAI_OPENING_EXPANSION_CITY_TARGET", 4',
        'ASAI_TRADE_CITIES_PER_CAPACITY", 2',
        "snapshot.Cities < cityTarget",
        "function ASAI_IsOpeningExpansion(playerID, threshold)",
        'ASAI_INFRA_START_TURN_STANDARD", 20',
        'ASAI_INFRA_IMPROVEMENTS_PER_CITY_X100", 200',
        'ASAI_INFRA_IMPROVEMENTS_PER_POP_X100", 65',
        'ASAI_INFRA_OWNED_PLOTS_CAP_X100", 30',
        "local function CountInFlightUnits(player)",
        "buildQueue:CurrentlyBuilding()",
        "ASAI_QUEUE_API mode=currently_building coverage=current_only",
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
    for unavailable_method in (
        "GetCurrentProductionTypeHash",
        "GetNumZonedDistrictsRequiringPopulation",
        "GetNumAllowedDistrictsRequiringPopulation",
        "GetResourceStockpileCap",
        "UnitManager.CanStartCommand",
    ):
        if unavailable_method in source:
            errors.append(
                "gameplay script still uses an unavailable runtime method: "
                f"{unavailable_method}"
            )
    civilian_budget_fragments = (
        "local function IsBuilderBudgetReachedSnapshot(snapshot)",
        "local function IsTraderBudgetReachedSnapshot(snapshot)",
        "local function IsSettlerBudgetReachedSnapshot(snapshot, scaleRecovery)",
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
        "ASAI_SCALE_RECOVERY_SETTLER_BONUS",
        "ASAI_SCALE_RECOVERY_SETTLER_CAP",
        "state.ScaleRecovery == 1 and state.ScaleExpansionAllowed ~= 1",
        "state.ScaleExpansionAllowed ~= 1",
        "snapshot.Settlers + snapshot.InFlightSettlers < maximumInFlight",
        "function ASAI_IsExpansionRecovery(playerID, threshold)",
        "settlers_inflight=%d",
        "settler_cap=%d",
    )
    for fragment in expansion_fragments:
        if fragment not in source:
            errors.append(f"expansion budget fragment is missing: {fragment}")
    return errors


def validate_invariants(connection: sqlite3.Connection) -> list[str]:
    errors: list[str] = []
    starting_rows = {
        (
            row[0],
            int(row[1]),
            int(row[2]),
            int(row[3]),
            row[4],
            float(row[5]),
        )
        for row in connection.execute(
            """
            SELECT Unit, Quantity, NotStartTile, OnDistrictCreated,
                   MinDifficulty, DifficultyDelta
            FROM MajorStartingUnits
            WHERE Era = 'ERA_ANCIENT'
              AND AiOnly = 1
              AND Unit IN ('UNIT_SETTLER', 'UNIT_WARRIOR', 'UNIT_BUILDER')
            """
        )
    }
    expected_starting_rows = {
        ("UNIT_SETTLER", 1, 0, 1, "DIFFICULTY_DEITY", 0.0),
        ("UNIT_WARRIOR", 1, 1, 0, "DIFFICULTY_KING", 0.0),
        ("UNIT_WARRIOR", 1, 1, 0, "DIFFICULTY_DEITY", 0.0),
        ("UNIT_BUILDER", 1, 0, 1, "DIFFICULTY_EMPEROR", 0.0),
    }
    if starting_rows != expected_starting_rows:
        errors.append(
            "Ancient AI starting-unit profile differs: "
            f"expected {sorted(expected_starting_rows)}, found {sorted(starting_rows)}"
        )

    yield_adjustments = {
        "OPENING": (-8, -30),
        "CLASSICAL": (3, 5),
        "MEDIEVAL": (5, 7),
        "RENAISSANCE": (6, 6),
        "INDUSTRIAL": (6, 6),
        "MODERN": (6, 6),
        "ATOMIC": (5, 5),
        "INFORMATION": (5, 5),
    }
    expected_curve = {
        "OPENING": (24, 50),
        "CLASSICAL": (27, 55),
        "MEDIEVAL": (32, 62),
        "RENAISSANCE": (38, 68),
        "INDUSTRIAL": (44, 74),
        "MODERN": (50, 80),
        "ATOMIC": (55, 85),
        "INFORMATION": (60, 90),
    }
    actual_science_total = 32
    actual_production_total = 80
    for stage, (science_adjustment, production_adjustment) in yield_adjustments.items():
        actual_stage_adjustments: dict[str, int] = {}
        for yield_name in ("SCIENCE", "CULTURE", "FAITH", "PRODUCTION", "GOLD"):
            modifier_id = f"ASAI_DEITY_{stage}_{yield_name}"
            row = connection.execute(
                "SELECT Value FROM ModifierArguments "
                "WHERE ModifierId = ? AND Name = 'Amount'",
                (modifier_id,),
            ).fetchone()
            if row is None:
                errors.append(f"missing Deity curve amount: {modifier_id}")
                continue
            actual_stage_adjustments[yield_name] = int(row[0])
        for yield_name in ("SCIENCE", "CULTURE", "FAITH"):
            actual = actual_stage_adjustments.get(yield_name)
            if actual != science_adjustment:
                errors.append(
                    f"{stage} {yield_name} adjustment expected "
                    f"{science_adjustment}, found {actual}"
                )
        for yield_name in ("PRODUCTION", "GOLD"):
            actual = actual_stage_adjustments.get(yield_name)
            if actual != production_adjustment:
                errors.append(
                    f"{stage} {yield_name} adjustment expected "
                    f"{production_adjustment}, found {actual}"
                )
        actual_science_total += actual_stage_adjustments.get("SCIENCE", 0)
        actual_production_total += actual_stage_adjustments.get("PRODUCTION", 0)
        if (actual_science_total, actual_production_total) != expected_curve[stage]:
            errors.append(
                f"{stage} cumulative Deity curve expected {expected_curve[stage]}, "
                f"found {(actual_science_total, actual_production_total)}"
            )

    expected_arguments = {
        ("ASAI_DEITY_OPENING_COMBAT", "Amount"): "-1",
        ("ASAI_DEITY_MODERN_COMBAT", "Amount"): "1",
        ("ASAI_DEITY_OPENING_XP", "Amount"): "-10",
        ("ASAI_DEITY_CLASSICAL_XP", "Amount"): "2",
        ("ASAI_DEITY_MEDIEVAL_XP", "Amount"): "2",
        ("ASAI_DEITY_RENAISSANCE_XP", "Amount"): "2",
        ("ASAI_DEITY_INDUSTRIAL_XP", "Amount"): "2",
        ("ASAI_DEITY_MODERN_XP", "Amount"): "2",
        ("ASAI_DEITY_ATOMIC_XP", "Amount"): "0",
    }
    for key, expected in expected_arguments.items():
        row = connection.execute(
            "SELECT Value FROM ModifierArguments WHERE ModifierId = ? AND Name = ?", key
        ).fetchone()
        actual = None if row is None else str(row[0])
        if actual != expected:
            errors.append(f"modifier argument {key} expected {expected}, found {actual}")

    result_enabled = connection.execute(
        "SELECT Value FROM GlobalParameters "
        "WHERE Name = 'ASAI_SEVERE_RESULT_YIELDS_ENABLED'"
    ).fetchone()
    if result_enabled is None or int(result_enabled[0]) != 1:
        errors.append(
            "severe result-yield layer must default enabled, found "
            f"{None if result_enabled is None else result_enabled[0]}"
        )

    expected_result_amounts = {
        "ASAI_SEVERE_RESULT_YIELDS_ON": "40, 30, 30",
        "ASAI_SEVERE_RESULT_YIELDS_OFF": "-40, -30, -30",
    }
    yield_types = "YIELD_PRODUCTION, YIELD_SCIENCE, YIELD_CULTURE"
    parsed_result_amounts: dict[str, list[int]] = {}
    for modifier_id, expected_amount in expected_result_amounts.items():
        definition = connection.execute(
            "SELECT ModifierType, OwnerRequirementSetId, Permanent, RunOnce "
            "FROM Modifiers WHERE ModifierId = ?",
            (modifier_id,),
        ).fetchone()
        expected_definition = (
            "MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER",
            "ASAI_DEITY_AI",
            0,
            0,
        )
        if definition != expected_definition:
            errors.append(
                f"result modifier {modifier_id} expected {expected_definition}, "
                f"found {definition}"
            )
        arguments = dict(
            connection.execute(
                "SELECT Name, Value FROM ModifierArguments WHERE ModifierId = ?",
                (modifier_id,),
            )
        )
        if arguments.get("YieldType") != yield_types:
            errors.append(
                f"result modifier {modifier_id} yield order differs: "
                f"{arguments.get('YieldType')}"
            )
        if str(arguments.get("Amount")) != expected_amount:
            errors.append(
                f"result modifier {modifier_id} amount expected {expected_amount}, "
                f"found {arguments.get('Amount')}"
            )
        try:
            parsed_result_amounts[modifier_id] = [
                int(value.strip())
                for value in str(arguments.get("Amount", "")).split(",")
            ]
        except ValueError:
            errors.append(f"result modifier {modifier_id} has non-integer amounts")

    positive = parsed_result_amounts.get("ASAI_SEVERE_RESULT_YIELDS_ON")
    negative = parsed_result_amounts.get("ASAI_SEVERE_RESULT_YIELDS_OFF")
    if positive is not None and negative is not None:
        if len(positive) != 3 or len(negative) != 3:
            errors.append("severe result-yield ledger must contain exactly three yields")
        elif any(on + off != 0 for on, off in zip(positive, negative)):
            errors.append(
                f"severe result-yield ledger does not cancel exactly: {positive}/{negative}"
            )

    statically_attached_results = connection.execute(
        "SELECT COUNT(*) FROM TraitModifiers "
        "WHERE ModifierId IN "
        "('ASAI_SEVERE_RESULT_YIELDS_ON', 'ASAI_SEVERE_RESULT_YIELDS_OFF')"
    ).fetchone()[0]
    if statically_attached_results:
        errors.append(
            "severe result modifiers must only be attached by the runtime state machine"
        )

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

    expected_settlement_items = {
        ("Nearest Friendly City", None): -8,
        ("Fresh Water", None): 30,
        ("Coastal", None): 15,
        ("New Resources", None): 5,
        ("Resource Class", "RESOURCECLASS_LUXURY"): 4,
        ("Resource Class", "RESOURCECLASS_STRATEGIC"): 5,
    }
    for (item, string_value), expected in expected_settlement_items.items():
        if string_value is None:
            row = connection.execute(
                "SELECT Value FROM AiFavoredItems "
                "WHERE ListType = 'StandardSettlePlot' "
                "AND Item = ? AND StringVal IS NULL",
                (item,),
            ).fetchone()
        else:
            row = connection.execute(
                "SELECT Value FROM AiFavoredItems "
                "WHERE ListType = 'StandardSettlePlot' "
                "AND Item = ? AND StringVal = ?",
                (item, string_value),
            ).fetchone()
        actual = None if row is None else row[0]
        if actual != expected:
            errors.append(
                f"settlement preference {item}/{string_value} expected "
                f"{expected}, found {actual}"
            )

    expected_plot_conditions = {
        "Nearest Friendly City": (-40, -16),
        "New Resources": (0, 6),
        "Inner Ring Yield": (14, 20),
        "Total Yield": (18, 32),
        "Coastal": (-1, 10),
        "Specific Resource": (-1, 4),
    }
    for condition, expected in expected_plot_conditions.items():
        row = connection.execute(
            "SELECT PoorValue, GoodValue FROM PlotEvalConditions "
            "WHERE ConditionType = ?",
            (condition,),
        ).fetchone()
        if row != expected:
            errors.append(
                f"plot evaluation {condition} expected {expected}, found {row}"
            )

    settle_team = connection.execute(
        """
        SELECT InitialStrengthAdvantage, OngoingStrengthAdvantage, MaxUnits
        FROM AiOperationTeams
        WHERE TeamName = 'Settle City Team'
          AND OperationName = 'Settle New City'
        """
    ).fetchone()
    if settle_team != (0.0, 0.0, 2):
        errors.append(
            "settler operation team expected strength/cap (0, 0, 2), "
            f"found {settle_team}"
        )

    settle_requirements = {
        (row[0], row[1], row[2])
        for row in connection.execute(
            """
            SELECT AiType, MinNumber, MaxNumber
            FROM OpTeamRequirements
            WHERE TeamName = 'Settle City Team'
              AND AiType IN ('UNITAI_SETTLE', 'UNITAI_COMBAT')
            """
        )
    }
    if ("UNITAI_SETTLE", 1, 1) not in settle_requirements:
        errors.append("settler operation no longer requires exactly one settler")
    if not any(
        ai_type == "UNITAI_COMBAT" and minimum == 1
        for ai_type, minimum, _maximum in settle_requirements
    ):
        errors.append("settler operation no longer requires one combat escort")
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
        "ASAI_OPENING_EXPANSION_END_STANDARD",
        "ASAI_OPENING_EXPANSION_CITY_TARGET",
        "ASAI_EXPANSION_CITIES_PER_INFLIGHT_SETTLER",
        "ASAI_SCALE_RECOVERY_SETTLER_BONUS",
        "ASAI_SCALE_RECOVERY_SETTLER_CAP",
        "ASAI_TRADE_CAPACITY_START_STANDARD",
        "ASAI_TRADE_CITIES_PER_CAPACITY",
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
        "ASAI_RELATIVE_FOCUS_STALL_LIMIT",
        "ASAI_RELATIVE_FOCUS_STALL_COOLDOWN_STANDARD",
        "ASAI_RELATIVE_SEVERE_ENTER_X100",
        "ASAI_RELATIVE_SEVERE_EXIT_X100",
        "ASAI_RELATIVE_SEVERE_CORE_ENTER_X100",
        "ASAI_RELATIVE_SEVERE_CORE_EXIT_X100",
        "ASAI_RELATIVE_SEVERE_WEAKEST_ENTER_X100",
        "ASAI_RELATIVE_SEVERE_WEAKEST_EXIT_X100",
        "ASAI_SCALE_RECOVERY_START_STANDARD",
        "ASAI_SCALE_RECOVERY_ENTER_X100",
        "ASAI_SCALE_RECOVERY_EXIT_X100",
        "ASAI_SCALE_RECOVERY_EMERGENCY_X100",
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
        "ASAI_MILITARY_READINESS_ENTER_X100",
        "ASAI_MILITARY_READINESS_EXIT_X100",
        "ASAI_MILITARY_READINESS_EMERGENCY_X100",
        "ASAI_MILITARY_DENSITY_START_STANDARD",
        "ASAI_MILITARY_UNITS_PER_PLANNED_CITY_ENTER_X100",
        "ASAI_MILITARY_UNITS_PER_PLANNED_CITY_EXIT_X100",
        "ASAI_MILITARY_QUEUE_TARGET_X100",
        "ASAI_WAR_QUEUE_TARGET_X100",
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

    readiness_enter = parameters.get("ASAI_MILITARY_READINESS_ENTER_X100")
    readiness_exit = parameters.get("ASAI_MILITARY_READINESS_EXIT_X100")
    readiness_emergency = parameters.get("ASAI_MILITARY_READINESS_EMERGENCY_X100")
    if None not in (readiness_enter, readiness_exit, readiness_emergency):
        if not 0 < readiness_emergency < readiness_enter < readiness_exit < 100:
            errors.append(
                "military-readiness thresholds are not ordered safely: "
                f"{(readiness_emergency, readiness_enter, readiness_exit)}"
            )
        if (readiness_enter, readiness_exit, readiness_emergency) != (78, 92, 60):
            errors.append(
                "military-readiness thresholds differ from the turn 1-76 replay: "
                f"{(readiness_enter, readiness_exit, readiness_emergency)}"
            )

    density_start = parameters.get("ASAI_MILITARY_DENSITY_START_STANDARD")
    density_enter = parameters.get(
        "ASAI_MILITARY_UNITS_PER_PLANNED_CITY_ENTER_X100"
    )
    density_exit = parameters.get(
        "ASAI_MILITARY_UNITS_PER_PLANNED_CITY_EXIT_X100"
    )
    if None not in (density_start, density_enter, density_exit):
        if density_start <= 0 or not 0 < density_enter < density_exit:
            errors.append(
                "military-density thresholds are not ordered safely: "
                f"{(density_start, density_enter, density_exit)}"
            )
        if (density_start, density_enter, density_exit) != (50, 175, 225):
            errors.append(
                "military-density thresholds differ from the turn 1-76 replay: "
                f"{(density_start, density_enter, density_exit)}"
            )

    scale_start = parameters.get("ASAI_SCALE_RECOVERY_START_STANDARD")
    scale_enter = parameters.get("ASAI_SCALE_RECOVERY_ENTER_X100")
    scale_exit = parameters.get("ASAI_SCALE_RECOVERY_EXIT_X100")
    scale_emergency = parameters.get("ASAI_SCALE_RECOVERY_EMERGENCY_X100")
    if None not in (scale_start, scale_enter, scale_exit, scale_emergency):
        if scale_start <= 0 or not 0 < scale_emergency < scale_enter < scale_exit < 100:
            errors.append(
                "scale-recovery thresholds are not ordered safely: "
                f"{(scale_start, scale_emergency, scale_enter, scale_exit)}"
            )
        if (scale_start, scale_enter, scale_exit, scale_emergency) != (50, 75, 88, 60):
            errors.append(
                "scale-recovery thresholds differ from the turn 1-76 replay: "
                f"{(scale_start, scale_enter, scale_exit, scale_emergency)}"
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
    opening_end = parameters.get("ASAI_OPENING_EXPANSION_END_STANDARD")
    opening_cities = parameters.get("ASAI_OPENING_EXPANSION_CITY_TARGET")
    if opening_end is not None and opening_end <= 0:
        errors.append(f"opening expansion end turn must be positive: {opening_end}")
    if opening_cities is not None and opening_cities < 2:
        errors.append(f"opening expansion city target is too small: {opening_cities}")
    if opening_cities != 4:
        errors.append(
            "opening expansion city target differs from the competitive opening: "
            f"{opening_cities}"
        )
    expansion_cities = parameters.get("ASAI_EXPANSION_CITIES_PER_INFLIGHT_SETTLER")
    if expansion_cities is not None and expansion_cities <= 0:
        errors.append(
            f"expansion cities per in-flight settler must be positive: {expansion_cities}"
        )
    scale_settler_bonus = parameters.get("ASAI_SCALE_RECOVERY_SETTLER_BONUS")
    scale_settler_cap = parameters.get("ASAI_SCALE_RECOVERY_SETTLER_CAP")
    if scale_settler_bonus is not None and scale_settler_bonus < 0:
        errors.append(f"scale-recovery settler bonus cannot be negative: {scale_settler_bonus}")
    if scale_settler_cap is not None and scale_settler_cap < 1:
        errors.append(f"scale-recovery settler cap must be positive: {scale_settler_cap}")
    trade_capacity_start = parameters.get("ASAI_TRADE_CAPACITY_START_STANDARD")
    trade_cities = parameters.get("ASAI_TRADE_CITIES_PER_CAPACITY")
    if trade_capacity_start is not None and trade_capacity_start < 0:
        errors.append(
            f"trade-capacity start turn cannot be negative: {trade_capacity_start}"
        )
    if trade_cities is not None and trade_cities <= 0:
        errors.append(f"trade cities per capacity must be positive: {trade_cities}")
    if trade_cities != 2:
        errors.append(
            "trade-capacity target differs from the turn 101-115 review: "
            f"{trade_cities} cities per route"
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
    focus_stall_limit = parameters.get("ASAI_RELATIVE_FOCUS_STALL_LIMIT")
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
    if focus_stall_limit is not None and not 1 <= focus_stall_limit <= 5:
        errors.append(f"relative focus stall limit is invalid: {focus_stall_limit}")
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

    severe_weakest_enter = parameters.get(
        "ASAI_RELATIVE_SEVERE_WEAKEST_ENTER_X100"
    )
    severe_weakest_exit = parameters.get(
        "ASAI_RELATIVE_SEVERE_WEAKEST_EXIT_X100"
    )
    if (
        severe_weakest_enter is not None
        and severe_weakest_exit is not None
        and not 0 < severe_weakest_enter < severe_weakest_exit < 100
    ):
        errors.append(
            "relative severe weakest-core thresholds are invalid: "
            f"{(severe_weakest_enter, severe_weakest_exit)}"
        )
    if (severe_weakest_enter, severe_weakest_exit) != (70, 80):
        errors.append(
            "relative severe weakest-core thresholds differ from the turn "
            "101-115 replay: "
            f"{(severe_weakest_enter, severe_weakest_exit)}"
        )

    military_queue_target = parameters.get("ASAI_MILITARY_QUEUE_TARGET_X100")
    war_queue_target = parameters.get("ASAI_WAR_QUEUE_TARGET_X100")
    if None not in (military_queue_target, war_queue_target):
        if not 0 < military_queue_target < war_queue_target <= 100:
            errors.append(
                "military queue targets are not ordered safely: "
                f"{(military_queue_target, war_queue_target)}"
            )
        if (military_queue_target, war_queue_target) != (25, 45):
            errors.append(
                "military queue targets differ from the turn 101-115 replay: "
                f"{(military_queue_target, war_queue_target)}"
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

    opening_strategy = connection.execute(
        "SELECT COUNT(*) FROM Strategies "
        "WHERE StrategyType = 'ASAI_STRATEGY_OPENING_EXPANSION'"
    ).fetchone()[0]
    if opening_strategy != 1:
        errors.append(
            f"expected one opening expansion strategy, found {opening_strategy}"
        )

    expected_opening_values = {
        ("ASAI_OpeningPseudoYields", "PSEUDOYIELD_WONDER"): -35,
        ("ASAI_OpeningPseudoYields", "PSEUDOYIELD_UNIT_SETTLER"): 25,
        ("ASAI_OpeningUnits", "UNIT_SETTLER"): 20,
        ("ASAI_OpeningYields", "YIELD_PRODUCTION"): 8,
    }
    for (list_type, item), expected in expected_opening_values.items():
        row = connection.execute(
            "SELECT Value FROM AiFavoredItems WHERE ListType = ? AND Item = ?",
            (list_type, item),
        ).fetchone()
        actual = None if row is None else row[0]
        if actual != expected:
            errors.append(
                f"opening expansion {list_type}/{item} expected {expected}, "
                f"found {actual}"
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

    expected_execution_strategies = {
        "ASAI_STRATEGY_TRADE_CAPACITY_RECOVERY",
        "ASAI_STRATEGY_SCIENCE_EXECUTION_RECOVERY",
        "ASAI_STRATEGY_CULTURE_EXECUTION_RECOVERY",
        "ASAI_STRATEGY_EMPIRE_EXECUTION_RECOVERY",
    }
    execution_placeholders = ", ".join("?" for _ in expected_execution_strategies)
    actual_execution_strategies = {
        row[0]
        for row in connection.execute(
            "SELECT StrategyType FROM Strategies "
            f"WHERE StrategyType IN ({execution_placeholders})",
            tuple(sorted(expected_execution_strategies)),
        )
    }
    if actual_execution_strategies != expected_execution_strategies:
        errors.append(
            "execution recovery strategies differ: "
            f"expected {sorted(expected_execution_strategies)}, "
            f"found {sorted(actual_execution_strategies)}"
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
        ("ASAI_BuilderBudgetPseudoYields", "PSEUDOYIELD_IMPROVEMENT"): -40,
        ("ASAI_BuilderBudgetUnits", "UNIT_BUILDER"): -70,
        ("ASAI_TraderBudgetPseudoYields", "PSEUDOYIELD_UNIT_TRADE"): -50,
        ("ASAI_TraderBudgetUnits", "UNIT_TRADER"): -70,
        ("ASAI_SettlerBudgetPseudoYields", "PSEUDOYIELD_UNIT_SETTLER"): -65,
        ("ASAI_SettlerBudgetUnits", "UNIT_SETTLER"): -80,
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

    readiness_strategy = connection.execute(
        "SELECT COUNT(*) FROM Strategies "
        "WHERE StrategyType = 'ASAI_STRATEGY_MILITARY_READINESS'"
    ).fetchone()[0]
    if readiness_strategy != 1:
        errors.append(
            f"expected one military-readiness strategy, found {readiness_strategy}"
        )

    scale_strategy = connection.execute(
        "SELECT COUNT(*) FROM Strategies "
        "WHERE StrategyType = 'ASAI_STRATEGY_SCALE_RECOVERY'"
    ).fetchone()[0]
    if scale_strategy != 1:
        errors.append(f"expected one scale-recovery strategy, found {scale_strategy}")

    expected_scale_lists = {
        "ASAI_ScaleRecoveryPseudoYields",
        "ASAI_ScaleRecoveryYields",
        "ASAI_ScaleRecoveryDistricts",
        "ASAI_ScaleRecoveryBuildings",
    }
    actual_scale_lists = {
        row[0]
        for row in connection.execute(
            "SELECT ListType FROM Strategy_Priorities "
            "WHERE StrategyType = 'ASAI_STRATEGY_SCALE_RECOVERY'"
        )
    }
    if actual_scale_lists != expected_scale_lists:
        errors.append(
            "scale-recovery priority lists differ: "
            f"expected {sorted(expected_scale_lists)}, found {sorted(actual_scale_lists)}"
        )

    expected_scale_values = {
        ("ASAI_ScaleRecoveryPseudoYields", "PSEUDOYIELD_IMPROVEMENT"): 25,
        ("ASAI_ScaleRecoveryPseudoYields", "PSEUDOYIELD_UNIT_TRADE"): 20,
        ("ASAI_ScaleRecoveryPseudoYields", "PSEUDOYIELD_WONDER"): -30,
        ("ASAI_ScaleRecoveryYields", "YIELD_FOOD"): 18,
        ("ASAI_ScaleRecoveryYields", "YIELD_PRODUCTION"): 20,
        ("ASAI_ScaleRecoveryDistricts", "DISTRICT_INDUSTRIAL_ZONE"): 30,
        ("ASAI_ScaleRecoveryDistricts", "DISTRICT_COMMERCIAL_HUB"): 20,
        ("ASAI_ScaleRecoveryDistricts", "DISTRICT_HARBOR"): 20,
        ("ASAI_ScaleRecoveryBuildings", "BUILDING_GRANARY"): 55,
        ("ASAI_ScaleRecoveryBuildings", "BUILDING_MONUMENT"): 45,
        ("ASAI_ScaleRecoveryBuildings", "BUILDING_MARKET"): 45,
        ("ASAI_ScaleRecoveryBuildings", "BUILDING_LIGHTHOUSE"): 45,
        ("ASAI_ExpansionRecoveryPseudoYields", "PSEUDOYIELD_UNIT_SETTLER"): 45,
        ("ASAI_ExpansionRecoveryUnits", "UNIT_SETTLER"): 40,
    }
    for (list_type, item), expected in expected_scale_values.items():
        row = connection.execute(
            "SELECT Value FROM AiFavoredItems WHERE ListType = ? AND Item = ?",
            (list_type, item),
        ).fetchone()
        actual = None if row is None else row[0]
        if actual != expected:
            errors.append(
                f"scale recovery {list_type}/{item} expected {expected}, found {actual}"
            )

    missing_scale_building_replacements = [
        row[0]
        for row in connection.execute(
            """
            SELECT replacements.CivUniqueBuildingType
            FROM BuildingReplaces AS replacements
            JOIN Buildings AS base
              ON base.BuildingType = replacements.ReplacesBuildingType
            LEFT JOIN AiFavoredItems AS favored
              ON favored.ListType = 'ASAI_ScaleRecoveryBuildings'
             AND favored.Item = replacements.CivUniqueBuildingType
             AND favored.Value = CASE
                    WHEN base.BuildingType = 'BUILDING_GRANARY' THEN 55
                    WHEN base.BuildingType IN
                        ('BUILDING_MONUMENT', 'BUILDING_WATER_MILL') THEN 45
                    WHEN base.BuildingType = 'BUILDING_SEWER' THEN 35
                    WHEN base.PrereqDistrict = 'DISTRICT_INDUSTRIAL_ZONE' THEN 50
                    WHEN base.BuildingType IN
                        ('BUILDING_MARKET', 'BUILDING_LIGHTHOUSE') THEN 45
                    WHEN base.BuildingType IN
                        ('BUILDING_BANK', 'BUILDING_SHIPYARD') THEN 40
                    ELSE 30
                 END
            WHERE COALESCE(base.IsWonder, 0) = 0
              AND (base.BuildingType IN
                    ('BUILDING_MONUMENT', 'BUILDING_GRANARY',
                     'BUILDING_WATER_MILL', 'BUILDING_SEWER',
                     'BUILDING_MARKET', 'BUILDING_BANK',
                     'BUILDING_STOCK_EXCHANGE', 'BUILDING_LIGHTHOUSE',
                     'BUILDING_SHIPYARD', 'BUILDING_SEAPORT')
                   OR base.PrereqDistrict = 'DISTRICT_INDUSTRIAL_ZONE')
              AND favored.Item IS NULL
            ORDER BY replacements.CivUniqueBuildingType
            """
        )
    ]
    if missing_scale_building_replacements:
        errors.append(
            "scale recovery is missing unique building replacements: "
            f"{missing_scale_building_replacements}"
        )

    expected_severe_values = {
        ("ASAI_RelativeSeverePseudoYields", "PSEUDOYIELD_UNIT_TRADE"): 14,
        ("ASAI_RelativeSeverePseudoYields", "PSEUDOYIELD_IMPROVEMENT"): 20,
        ("ASAI_RelativeSevereYields", "YIELD_PRODUCTION"): 20,
        ("ASAI_RelativeSevereYields", "YIELD_SCIENCE"): 16,
        ("ASAI_RelativeSevereYields", "YIELD_CULTURE"): 16,
        ("ASAI_RelativeSevereDistricts", "DISTRICT_INDUSTRIAL_ZONE"): 20,
        ("ASAI_RelativeSevereDistricts", "DISTRICT_COMMERCIAL_HUB"): 12,
    }
    for (list_type, item), expected in expected_severe_values.items():
        row = connection.execute(
            "SELECT Value FROM AiFavoredItems WHERE ListType = ? AND Item = ?",
            (list_type, item),
        ).fetchone()
        actual = None if row is None else row[0]
        if actual != expected:
            errors.append(
                f"severe support {list_type}/{item} expected {expected}, found {actual}"
            )

    expected_military_values = {
        ("ASAI_MilitaryReadinessPseudoYields", "PSEUDOYIELD_UNIT_COMBAT"): 35,
        ("ASAI_MilitaryReadinessPseudoYields", "PSEUDOYIELD_STANDING_ARMY_NUMBER"): 35,
        ("ASAI_MilitaryReadinessPseudoYields", "PSEUDOYIELD_STANDING_ARMY_VALUE"): 30,
        ("ASAI_MilitaryReadinessPseudoYields", "PSEUDOYIELD_UNIT_SETTLER"): -30,
        ("ASAI_MilitaryReadinessPseudoYields", "PSEUDOYIELD_WONDER"): -45,
        ("ASAI_MilitaryReadinessUnitBuilds", "PROMOTION_CLASS_RANGED"): 55,
        ("ASAI_MilitaryReadinessUnitBuilds", "PROMOTION_CLASS_SIEGE"): 35,
        ("ASAI_MilitaryReadinessUnitBuilds", "PROMOTION_CLASS_ANTI_CAVALRY"): 35,
        ("ASAI_MilitaryReadinessUnitBuilds", "PROMOTION_CLASS_AIR_FIGHTER"): 30,
        ("ASAI_MilitaryReadinessUnitBuilds", "PROMOTION_CLASS_AIR_BOMBER"): 35,
        ("ASAI_MilitaryReadinessYields", "YIELD_PRODUCTION"): 18,
        ("ASAI_MilitaryReadinessDistricts", "DISTRICT_ENCAMPMENT"): 30,
        ("ASAI_MilitaryReadinessBuildings", "BUILDING_WALLS"): 35,
        ("ASAI_MilitaryExecutionPseudoYields", "PSEUDOYIELD_UNIT_COMBAT"): 70,
        ("ASAI_MilitaryExecutionPseudoYields", "PSEUDOYIELD_UNIT_AIR_COMBAT"): 55,
        ("ASAI_MilitaryExecutionPseudoYields", "PSEUDOYIELD_STANDING_ARMY_NUMBER"): 55,
        ("ASAI_MilitaryExecutionPseudoYields", "PSEUDOYIELD_STANDING_ARMY_VALUE"): 45,
        ("ASAI_MilitaryExecutionPseudoYields", "PSEUDOYIELD_UNIT_SETTLER"): -40,
        ("ASAI_MilitaryExecutionUnitBuilds", "PROMOTION_CLASS_MELEE"): 35,
        ("ASAI_MilitaryExecutionUnitBuilds", "PROMOTION_CLASS_RANGED"): 85,
        ("ASAI_MilitaryExecutionUnitBuilds", "PROMOTION_CLASS_SIEGE"): 60,
        ("ASAI_MilitaryExecutionUnitBuilds", "PROMOTION_CLASS_ANTI_CAVALRY"): 45,
        ("ASAI_MilitaryExecutionUnitBuilds", "PROMOTION_CLASS_LIGHT_CAVALRY"): 25,
        ("ASAI_MilitaryExecutionUnitBuilds", "PROMOTION_CLASS_HEAVY_CAVALRY"): 25,
        ("ASAI_MilitaryExecutionUnitBuilds", "PROMOTION_CLASS_AIR_FIGHTER"): 60,
        ("ASAI_MilitaryExecutionUnitBuilds", "PROMOTION_CLASS_AIR_BOMBER"): 70,
        ("ASAI_MilitaryExecutionYields", "YIELD_PRODUCTION"): 25,
        ("ASAI_MilitaryExecutionYields", "YIELD_GOLD"): 12,
        ("ASAI_LateDistricts", "DISTRICT_AERODROME"): 50,
        ("ASAI_WarPseudoYields", "PSEUDOYIELD_UNIT_COMBAT"): 60,
        ("ASAI_WarPseudoYields", "PSEUDOYIELD_STANDING_ARMY_NUMBER"): 30,
        ("ASAI_WarPseudoYields", "PSEUDOYIELD_STANDING_ARMY_VALUE"): 55,
        ("ASAI_WarPseudoYields", "PSEUDOYIELD_UNIT_SETTLER"): -65,
        ("ASAI_WarUnitBuilds", "PROMOTION_CLASS_RANGED"): 50,
        ("ASAI_WarUnitBuilds", "PROMOTION_CLASS_ANTI_CAVALRY"): 40,
        ("ASAI_WarYields", "YIELD_PRODUCTION"): 30,
        ("ASAI_WarDistricts", "DISTRICT_ENCAMPMENT"): 35,
        ("ASAI_WarBuildings", "BUILDING_WALLS"): 90,
    }
    for (list_type, item), expected in expected_military_values.items():
        row = connection.execute(
            "SELECT Value FROM AiFavoredItems WHERE ListType = ? AND Item = ?",
            (list_type, item),
        ).fetchone()
        actual = None if row is None else row[0]
        if actual != expected:
            errors.append(
                f"military readiness {list_type}/{item} expected {expected}, "
                f"found {actual}"
            )

    obsolete_war_operation = connection.execute(
        "SELECT COUNT(*) FROM AiLists WHERE ListType = 'ASAI_WarOperations'"
    ).fetchone()[0] + connection.execute(
        "SELECT COUNT(*) FROM AiFavoredItems "
        "WHERE ListType = 'ASAI_WarOperations' OR "
        "(ListType LIKE 'ASAI_War%' AND Item = 'CITY_ASSAULT')"
    ).fetchone()[0]
    if obsolete_war_operation:
        errors.append(
            "wartime mobilization still adds an extra CITY_ASSAULT operation slot"
        )

    for list_type, expected in (
        ("ASAI_MilitaryReadinessBuildings", 35),
        ("ASAI_WarBuildings", 90),
    ):
        missing_defenses = [
            row[0]
            for row in connection.execute(
                """
                SELECT b.BuildingType
                FROM Buildings AS b
                LEFT JOIN AiFavoredItems AS f
                  ON f.ListType = ?
                 AND f.Item = b.BuildingType
                 AND f.Value = ?
                WHERE (COALESCE(b.OuterDefenseHitPoints, 0) > 0
                       OR b.BuildingType IN (
                            SELECT CivUniqueBuildingType
                            FROM BuildingReplaces
                            WHERE ReplacesBuildingType IN
                                ('BUILDING_WALLS', 'BUILDING_CASTLE', 'BUILDING_STAR_FORT')
                       ))
                  AND f.Item IS NULL
                ORDER BY b.BuildingType
                """,
                (list_type, expected),
            )
        ]
        if missing_defenses:
            errors.append(
                f"{list_type} is missing defensive buildings: {missing_defenses}"
            )

    for list_type, expected in (
        ("ASAI_MilitaryReadinessDistricts", 30),
        ("ASAI_WarDistricts", 35),
    ):
        missing_encampments = [
            row[0]
            for row in connection.execute(
                """
                SELECT r.CivUniqueDistrictType
                FROM DistrictReplaces AS r
                LEFT JOIN AiFavoredItems AS f
                  ON f.ListType = ?
                 AND f.Item = r.CivUniqueDistrictType
                 AND f.Value = ?
                WHERE r.ReplacesDistrictType = 'DISTRICT_ENCAMPMENT'
                  AND f.Item IS NULL
                ORDER BY r.CivUniqueDistrictType
                """,
                (list_type, expected),
            )
        ]
        if missing_encampments:
            errors.append(
                f"{list_type} is missing Encampment replacements: {missing_encampments}"
            )

    expected_execution_values = {
        ("ASAI_TradeCapacityBuildings", "BUILDING_MARKET"): 120,
        ("ASAI_TradeCapacityBuildings", "BUILDING_LIGHTHOUSE"): 120,
        ("ASAI_ScienceExecutionDistricts", "DISTRICT_CAMPUS"): 75,
        ("ASAI_CultureExecutionDistricts", "DISTRICT_THEATER"): 100,
        ("ASAI_CultureExecutionBuildings", "BUILDING_AMPHITHEATER"): 80,
        ("ASAI_CultureExecutionBuildings", "BUILDING_MONUMENT"): 100,
        ("ASAI_EmpireExecutionBuildings", "BUILDING_GRANARY"): 60,
        ("ASAI_EmpireExecutionBuildings", "BUILDING_WATER_MILL"): 40,
    }
    for (list_type, item), expected in expected_execution_values.items():
        row = connection.execute(
            "SELECT Value FROM AiFavoredItems WHERE ListType = ? AND Item = ?",
            (list_type, item),
        ).fetchone()
        actual = None if row is None else row[0]
        if actual != expected:
            errors.append(
                f"execution recovery {list_type}/{item} expected {expected}, "
                f"found {actual}"
            )

    district_replacement_expectations = (
        ("ASAI_TradeCapacityDistricts", "DISTRICT_COMMERCIAL_HUB", 55),
        ("ASAI_TradeCapacityDistricts", "DISTRICT_HARBOR", 55),
        ("ASAI_ScienceRecoveryDistricts", "DISTRICT_CAMPUS", 50),
        ("ASAI_ScienceExecutionDistricts", "DISTRICT_CAMPUS", 75),
        ("ASAI_CultureRecoveryDistricts", "DISTRICT_THEATER", 55),
        ("ASAI_CultureExecutionDistricts", "DISTRICT_THEATER", 100),
        ("ASAI_ScaleRecoveryDistricts", "DISTRICT_INDUSTRIAL_ZONE", 30),
        ("ASAI_ScaleRecoveryDistricts", "DISTRICT_COMMERCIAL_HUB", 20),
        ("ASAI_ScaleRecoveryDistricts", "DISTRICT_HARBOR", 20),
    )
    for list_type, base_district, expected in district_replacement_expectations:
        missing = [
            row[0]
            for row in connection.execute(
                """
                SELECT r.CivUniqueDistrictType
                FROM DistrictReplaces AS r
                LEFT JOIN AiFavoredItems AS f
                  ON f.ListType = ?
                 AND f.Item = r.CivUniqueDistrictType
                 AND f.Value = ?
                WHERE r.ReplacesDistrictType = ?
                  AND f.Item IS NULL
                ORDER BY r.CivUniqueDistrictType
                """,
                (list_type, expected, base_district),
            )
        ]
        if missing:
            errors.append(
                f"{list_type} is missing {base_district} replacements: {missing}"
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
                   OR ListType LIKE 'ASAI_ExpansionRecovery%'
                   OR ListType LIKE 'ASAI_ScaleRecovery%')
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
              AND Item <> 'PSEUDOYIELD_WONDER'
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
              AND Item <> 'PSEUDOYIELD_WONDER'
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

    expected_victory_culture_buildings = {
        "BUILDING_AMPHITHEATER",
        "BUILDING_MUSEUM_ART",
        "BUILDING_MUSEUM_ARTIFACT",
        "BUILDING_BROADCAST_CENTER",
    }
    actual_victory_culture_buildings = {
        row[0]
        for row in connection.execute(
            "SELECT Item FROM AiFavoredItems WHERE ListType = 'ASAI_CultureBuildings'"
        )
    }
    if actual_victory_culture_buildings != expected_victory_culture_buildings:
        errors.append(
            "ASAI_CultureBuildings differs: "
            f"expected {sorted(expected_victory_culture_buildings)}, "
            f"found {sorted(actual_victory_culture_buildings)}"
        )

    required_recovery_culture_buildings = expected_victory_culture_buildings | {
        "BUILDING_MONUMENT"
    }
    for list_type in (
        "ASAI_CultureRecoveryBuildings",
        "ASAI_CultureExecutionBuildings",
    ):
        actual_culture_buildings = {
            row[0]
            for row in connection.execute(
                "SELECT Item FROM AiFavoredItems WHERE ListType = ?",
                (list_type,),
            )
        }
        missing = required_recovery_culture_buildings - actual_culture_buildings
        if missing:
            errors.append(f"{list_type} is missing required buildings: {sorted(missing)}")

    expected_wonder_penalties = {
        ("ASAI_OpeningPseudoYields", "PSEUDOYIELD_WONDER"): -35,
        ("ASAI_RelativeCatchupPseudoYields", "PSEUDOYIELD_WONDER"): -20,
        ("ASAI_RelativeSeverePseudoYields", "PSEUDOYIELD_WONDER"): -30,
        ("ASAI_MilitaryReadinessPseudoYields", "PSEUDOYIELD_WONDER"): -45,
        ("ASAI_ScaleRecoveryPseudoYields", "PSEUDOYIELD_WONDER"): -30,
    }
    for (list_type, item), expected in expected_wonder_penalties.items():
        row = connection.execute(
            "SELECT Value FROM AiFavoredItems WHERE ListType = ? AND Item = ?",
            (list_type, item),
        ).fetchone()
        actual = None if row is None else row[0]
        if actual != expected:
            errors.append(
                f"wonder opportunity-cost guardrail {list_type} expected "
                f"{expected}, found {actual}"
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
    if war_wonder_values != {-60}:
        errors.append(
            f"major-war wonder penalty expected only -60, found {sorted(war_wonder_values)}"
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
                if strategy_count != 23:
                    errors.append(f"expected 23 adaptive strategies, found {strategy_count}")
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
    print(
        "- Deity opening: 2 Settlers, 3 Warriors, 1 Builder; "
        "+50% Production/Gold, +24% Science/Culture/Faith, +3 combat, +30% XP"
    )
    print(
        "- adaptive strategies: 23 "
        "(including military readiness, military execution, and scale recovery)"
    )
    print("- game cache was not modified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
