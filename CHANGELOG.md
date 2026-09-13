# Changelog

## 1.0.0 — Initial release

- Initial 1.0 release of Adaptive Strategic AI for Civilization VI: Gathering Storm.
- Includes era-scaled Deity bonuses, bounded catch-up, and adaptive development,
  military and victory priorities.
- Carries forward the responsive strategy and runtime compatibility fixes from
  0.11.22, with no additional AI behavior or balance changes.
- Uses the final `v1.0.0` package name. Local testing and packaging utilities
  are excluded from the public repository and player downloads.

## 0.11.22 — Execution callback compatibility fix

- Fixed a runtime error that prevented the responsive execution strategies
  from activating after the gameplay script loaded. Their dispatch now uses
  direct function references instead of looking up callbacks through `_G`.
- Bind all 17 callback families after their definitions and before registering
  the native gate entry points. Initialization remains in a separate,
  one-time function scope for HavokScript compatibility.
- Added full-script regression coverage with `_G` absent or unusable, including
  activation, release, cooldown-safe re-entry, reloads and collector failures.
- Preserved strategy counts, cooldowns, army requirements, era bonuses and
  catch-up rules. Existing saves can be continued after restarting the game.

Local regression and compiler checks do not replace native verification of
strategy activation and actual production orders.

## 0.11.21 — Compiler compatibility fix

Superseded by 0.11.22: compilation was fixed, but native continuation exposed
a separate runtime callback lookup failure.

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
