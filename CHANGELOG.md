# Changelog

## 0.11.21 — Compiler compatibility fix

- Fixed a gameplay script loading failure introduced in 0.11.20: the native
  gate callback table exceeded HavokScript's top-level register limit. Its
  initialization now uses a separate, one-time function scope.
- Preserved all execution families, strategy slots, unit requirements, era
  bonuses and catch-up rules.
- Release packaging now requires compile-only validation with the installed
  Windows game's HavokScript runtime, alongside standard Lua behavior and SQL
  tests. It checks both installed and packaged Lua bytes and records their
  hashes; missing or failed compiler validation blocks packaging.

In-game loading, strategy response and production still require native gameplay
acceptance. Compiler success alone does not establish those results.

## 0.11.20 — Withdrawn release candidate

Do not use this candidate: its gameplay Lua fails to compile in the game.
The fix is included in 0.11.21.

- Reworked short-lived execution requests to account for the native strategy
  cooldown. Each request uses one active preference set, with temporary vetoes
  and saved cooldown-safe spare identities for re-entry.
- Land attack teams now request a direct-ranged unit for their existing ranged
  slot. Siege units no longer satisfy that specific slot; standard and unique
  ranged units remain eligible. Existing team-size limits are unchanged.
- Added separate ranged, siege and anti-cavalry production receipts to distinguish
  requests, observed queues, asset changes and time without an order.
- Added delayed-scheduler regression coverage and an allowlisted, reproducible
  release packager.

Era bonuses, catch-up yields and unit costs are unchanged. The mod does not
override city orders, grant units or patch the game executable.

Local Lua, database and package checks are separate from native game testing.
The replacement candidate still requires a short in-game check of strategy
admission, exit and the direct-ranged production contract before a stable release.
