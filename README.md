**English** | [简体中文](README.zh-CN.md)

# Adaptive Strategic AI

A Civilization VI: Gathering Storm AI overhaul built to keep Deity games competitive from the opening to the victory screen.

**Version 0.11.11** | **Gathering Storm required** | **Designed for Deity** | **New game recommended**

Vanilla Deity concentrates much of its challenge in the opening and often loses pressure later. Adaptive Strategic AI replaces part of that early spike with a smoother era-scaled curve, then helps every major AI turn its economy, military, and victory plans into useful results.

> **Player experience:** AI civilizations can lead, recover, defend, attack, and finish victories. Strong AIs keep their advantages; weaker AIs receive bounded help only when they fall substantially behind. The mod does not try to keep every score equal each turn.

## Highlights

- **A competitive full game.** Deity remains dangerous early, while its economic, combat, and experience bonuses grow with the world era to preserve later pressure.
- **Independent adaptive plans.** Every major AI evaluates itself against the human player, the wider field, and its own recent trend. Development, recovery, expansion, defense, pressure, and war plans can change as the situation changes.
- **Stronger expansion and economy.** Research recovery links prerequisite technologies to useful science buildings; stalled trade capacity gets staged infrastructure priorities. Relative expansion becomes selective in the Industrial Era and ends in the Modern Era. Idle Settlers and cities lost to Free Cities trigger bounded expansion pauses.
- **More credible military behavior.** Attrition, actual army size, ranged and siege roles, and units already in production guide reinforcement. War reviews use held captures and pillaging rather than global enemy losses; changing a support focus does not restart the main review. Unproductive offensives can fall back to defense, while confirmed air or Giant Death Robot attacks trigger focused counter-production.
- **Better victory conversion.** Science, culture, domination, religion, and diplomacy receive distinct priorities. Persistent project milestones guide the next space project, the randomized Future Era route, and a capped number of parallel Spaceports. After the exoplanet launch, laser stations receive urgent priority over ordinary city projects; an active defense emergency can suspend the sequence.
- **Bounded recovery, not constant parity.** Targeted decision support handles isolated weaknesses. Reversible yield support is reserved for broad or severe collapse and never penalizes a matched or leading AI.

The mod does **not** spawn units or grant technologies, civics, resources, cities, or stored progress.

## Adaptive Support

Adaptive support affects future AI decisions and yields; it does not rewrite past progress.

| AI state | Mod response on Deity |
| --- | --- |
| One weak science, culture, or empire pillar | Targeted priorities only; no broad yield bonus |
| Confirmed broad deficit | `+20%` Production, `+15%` Science/Culture, `+10%` Food |
| Confirmed severe collapse | Replaces the mild tier with `+40%` Production, `+30%` Science/Culture, `+20%` Food |
| Matched or leading | No adaptive yield bonus and no player-relative penalty |

Support requires repeated confirmation, has exit thresholds and cooldowns, and is removed with an exact inverse modifier after recovery.

## Deity Difficulty Curve

These are the total Deity AI bonuses after the mod replaces the vanilla values:

| World era | Production / Gold | Science / Culture / Faith | Combat | Unit XP |
| --- | ---: | ---: | ---: | ---: |
| Ancient | +50% | +24% | +3 | +30% |
| Classical | +55% | +27% | +3 | +32% |
| Medieval | +65% | +32% | +4 | +34% |
| Renaissance | +75% | +38% | +5 | +36% |
| Industrial | +85% | +45% | +5 | +38% |
| Modern | +95% | +52% | +5 | +40% |
| Atomic | +105% | +60% | +5 | +40% |
| Information / Future | +115% | +60% | +5 | +40% |

An Ancient Era Deity AI starts with 2 Settlers, 3 Warriors, and 1 Builder in total. This is below the vanilla Deity opening and leaves more room for the player to make meaningful early decisions.

## Installation

1. Download or clone this repository into your Civilization VI `Mods` directory.
2. Confirm that `AdaptiveStrategicAI.modinfo` is directly inside the downloaded mod folder.
3. In Civilization VI, open **Additional Content -> Mods** and enable **Adaptive Strategic AI**.
4. Select the **Gathering Storm** ruleset and start a new game.

Default Windows location:

```text
%USERPROFILE%\Documents\My Games\Sid Meier's Civilization VI\Mods
```

Deity difficulty, Standard speed, and an Ancient Era start are the primary tested setup. Timing is normalized against game speed, but other combinations have received less testing. Installing the mod into an existing game cannot reconstruct starting units or earlier difficulty steps.

## Compatibility

Do not combine Adaptive Strategic AI with RHAI, Real Strategy, AI+, Better AI Tweaks, Late Game AI, Smoother Difficulty, or other mods that replace AI strategies or difficulty bonuses.

UI-only mods are generally compatible. Better Balanced Game changes technologies, units, and districts extensively, so compatibility is not guaranteed. Single-player is the primary test target; multiplayer is supported by the mod metadata but has not been tested as extensively.

## Configuration and Troubleshooting

Most players do not need to configure anything. Pacing and diagnostic settings are in [`AI/10_CoreEconomy.sql`](AI/10_CoreEconomy.sql); execution-recovery thresholds are in [`AI/25_ExecutionRecovery.sql`](AI/25_ExecutionRecovery.sql). Metrics are enabled by default. A separate read-only UI context records trade routes, cultural Great Person points, and city production alongside the controller's `Lua.log` entries.

For a bug report, include the mod version, game settings, enabled mod list, and the relevant `Database.log`, `Modding.log`, and `Lua.log` files in a [GitHub issue](https://github.com/CHOS1N11111/Adaptive-Strategic-AI-mod-for-Civilization-VI/issues).

Repository validation:

```powershell
python .\Tools\validate_mod.py
```

Behavioral regression tests require a local Lua 5.3/5.4 runtime: `python .\Tools\run_lua_tests.py --lua lua`.

## License

Adaptive Strategic AI is available under the [MIT License](LICENSE).
