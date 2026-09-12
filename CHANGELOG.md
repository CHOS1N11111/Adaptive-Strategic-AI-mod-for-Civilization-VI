# Changelog

## 0.11.20 — Release candidate

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
This candidate still requires a short in-game check of strategy admission,
exit and the direct-ranged production contract before a stable release.
