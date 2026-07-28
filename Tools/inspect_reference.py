from __future__ import annotations

import sqlite3
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: inspect_reference.py DATABASE TABLE [PATTERN]")
        return 2

    database = Path(sys.argv[1])
    table = sys.argv[2]
    pattern = sys.argv[3] if len(sys.argv) > 3 else "%"
    if table == "__tables__":
        with sqlite3.connect(database) as connection:
            for (name,) in connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
            ):
                print(name)
        return 0
    if table == "__schema__":
        if len(sys.argv) < 4:
            print("usage: inspect_reference.py DATABASE __schema__ TABLE")
            return 2
        with sqlite3.connect(database) as connection:
            for row in connection.execute(f"PRAGMA table_info({pattern})"):
                print("\t".join(str(value) for value in row))
        return 0
    if table == "__enabled_mods__":
        with sqlite3.connect(database) as connection:
            rows = connection.execute(
                """
                SELECT m.ModId, COALESCE(p.Value, ''), g.Name
                FROM ModGroups AS g
                JOIN ModGroupItems AS i ON i.ModGroupRowId = g.ModGroupRowId
                JOIN Mods AS m ON m.ModRowId = i.ModRowId
                LEFT JOIN ModProperties AS p
                  ON p.ModRowId = m.ModRowId AND p.Name = 'Name'
                WHERE g.Selected = 1 AND i.Disabled = 0
                ORDER BY p.Value, m.ModId
                """
            )
            for row in rows:
                print("\t".join(str(value) for value in row))
        return 0

    allowed = {
        "GlobalParameters": ("Name", "Value"),
        "PseudoYields": ("PseudoYieldType", "DefaultValue"),
        "AiFavoredItems": ("ListType", "Item", "Favored", "Value", "StringVal"),
        "AiOperationDefs": ("OperationName", "OperationType", "MustHaveUnits", "MinOddsOfSuccess"),
        "Projects": ("ProjectType", "SpaceRace"),
    }
    columns = allowed.get(table)
    if columns is None:
        print(f"unsupported table: {table}")
        return 2

    key = columns[0]
    sql = f"SELECT {', '.join(columns)} FROM {table} WHERE {key} LIKE ? ORDER BY {key}"
    with sqlite3.connect(database) as connection:
        for row in connection.execute(sql, (pattern,)):
            print("\t".join("NULL" if value is None else str(value) for value in row))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
