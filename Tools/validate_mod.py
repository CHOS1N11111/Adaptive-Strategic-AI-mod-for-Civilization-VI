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
    if "GetNumOutgoingRoutes" in source:
        errors.append("GetNumOutgoingRoutes is unavailable in gameplay-script context")
    if "GetMilitaryStrengthWithoutTreasury" in source or ":GetMilitaryStrength()" in source:
        errors.append("player military-strength methods are unavailable in gameplay-script context")
    if "tonumber(player:GetProperty(" in source:
        errors.append("player properties must be stored before numeric conversion")
    if "local function EstimateMilitaryStrength(player)" not in source:
        errors.append("gameplay-safe military strength estimator is missing")
    if "PlayerManager.GetAliveIDs()" not in source:
        errors.append("war detection must include alive major and minor players")
    if "for _, otherID in ipairs(PlayerManager.GetAliveMajorIDs()) do" in source:
        errors.append("war detection still ignores wars against city-states")
    if "not otherPlayer:IsBarbarian()" not in source:
        errors.append("war detection must exclude barbarians")
    infrastructure_fragments = (
        'ASAI_INFRA_IMPROVEMENTS_PER_CITY_X100", 200',
        'ASAI_INFRA_IMPROVEMENTS_PER_POP_X100", 65',
        'ASAI_INFRA_OWNED_PLOTS_CAP_X100", 30',
        "math.max(cityFloor, math.min(populationTarget, landCap))",
    )
    for fragment in infrastructure_fragments:
        if fragment not in source:
            errors.append(f"infrastructure target fragment is missing: {fragment}")
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
    parameter_names = (
        "ASAI_RELATIVE_PACING_ENABLED",
        "ASAI_RELATIVE_START_TURN",
        "ASAI_RELATIVE_CHECK_INTERVAL",
        "ASAI_RELATIVE_TRAILING_ENTER_X100",
        "ASAI_RELATIVE_TRAILING_EXIT_X100",
        "ASAI_RELATIVE_LEADING_EXIT_X100",
        "ASAI_RELATIVE_LEADING_ENTER_X100",
        "ASAI_RELATIVE_LEADING_PILLAR_MIN_X100",
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

    threshold_names = (
        "ASAI_RELATIVE_TRAILING_ENTER_X100",
        "ASAI_RELATIVE_TRAILING_EXIT_X100",
        "ASAI_RELATIVE_LEADING_EXIT_X100",
        "ASAI_RELATIVE_LEADING_ENTER_X100",
    )
    if all(name in parameters for name in threshold_names):
        values = [parameters[name] for name in threshold_names]
        if not values[0] < values[1] < 100 < values[2] < values[3]:
            errors.append(f"relative pacing thresholds are not ordered safely: {values}")

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

    leading_pillar_minimum = parameters.get("ASAI_RELATIVE_LEADING_PILLAR_MIN_X100")
    if leading_pillar_minimum is not None and not 0 < leading_pillar_minimum <= 100:
        errors.append(
            f"relative leading pillar minimum is invalid: {leading_pillar_minimum}"
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
    }
    actual_recovery_strategies = {
        row[0]
        for row in connection.execute(
            "SELECT StrategyType FROM Strategies "
            "WHERE StrategyType IN (?, ?, ?)",
            tuple(sorted(expected_recovery_strategies)),
        )
    }
    if actual_recovery_strategies != expected_recovery_strategies:
        errors.append(
            "pillar recovery strategies differ: "
            f"expected {sorted(expected_recovery_strategies)}, "
            f"found {sorted(actual_recovery_strategies)}"
        )

    oversized = list(
        connection.execute(
            """
            SELECT ListType, Item, Value
            FROM AiFavoredItems
            WHERE (ListType LIKE 'ASAI_Relative%'
                   OR ListType LIKE 'ASAI_ScienceRecovery%'
                   OR ListType LIKE 'ASAI_CultureRecovery%'
                   OR ListType LIKE 'ASAI_EmpireRecovery%')
              AND ABS(Value) > 25
            ORDER BY ListType, Item
            """
        )
    )
    errors.extend(
        f"relative adjustment is too large: {list_type}/{item}={value}"
        for list_type, item, value in oversized
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
        ET.parse(modinfo)
    except (OSError, ET.ParseError) as error:
        print(f"modinfo error: {error}")
        return 1

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
                if strategy_count != 10:
                    errors.append(f"expected 10 adaptive strategies, found {strategy_count}")

    if errors:
        print("VALIDATION FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    print("VALIDATION PASSED")
    print(f"- modinfo: {modinfo.name}")
    print(f"- database scripts: {len(database_files(modinfo))}")
    print("- adaptive strategies: 10 (including 3 pillar recovery strategies)")
    print("- game cache was not modified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
