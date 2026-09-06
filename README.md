**English** | [简体中文](README.zh-CN.md)

# Adaptive Strategic AI

A **Civilization VI: Gathering Storm** AI mod designed to keep **Deity** competitive beyond the opening—through development, war, and the race to victory.

## Highlights

- **A smoother challenge.** Less front-loaded opening strength, with bonuses that grow through the eras.
- **AI that adapts.** Every major AI adjusts its economic, military, and victory priorities as the game changes.
- **Better follow-through.** More attention to trade, reinforcements, and turning scientific progress into victory projects.
- **Bounded catch-up.** Sustained, broad setbacks trigger temporary support. Leading AIs keep their advantages.

The mod adjusts AI priorities and bonuses. It does not spawn free units or grant completed research.

<p align="center">
  <img src="assets/cover.jpg" alt="Adaptive Strategic AI cover" width="480">
</p>

## Install

1. Download and extract this repository into your Civilization VI `Mods` directory:

   ```text
   %USERPROFILE%\Documents\My Games\Sid Meier's Civilization VI\Mods
   ```

2. Check that `AdaptiveStrategicAI.modinfo` is directly inside the extracted mod folder. Enable **Adaptive Strategic AI** in **Additional Content → Mods**.
3. Choose **Gathering Storm**, select **Deity**, and start a new game.

## How It Works

**Dynamic priorities.** Every major AI compares its science, culture, empire, and military with the player and the wider field. It adjusts priorities for development, defense, and victory, including trade-route gaps, reinforcements, and science-victory projects. Victory priorities can change with the situation.

**Era-scaled Deity bonuses.** A standard Ancient Era Deity start provides 2 Settlers, 3 Warriors, and 1 Builder per AI. The following bonuses grow with the **world era**. These are the total difficulty bonuses after the mod's adjustments—not extra bonuses on top of vanilla Deity:

| World era | Production / Gold | Science / Culture / Faith | Combat strength |
| --- | ---: | ---: | ---: |
| Ancient | +50% | +24% | +3 |
| Classical | +55% | +27% | +3 |
| Medieval | +65% | +32% | +4 |
| Renaissance | +75% | +38% | +5 |
| Industrial | +85% | +45% | +5 |
| Modern | +95% | +52% | +5 |
| Atomic | +105% | +60% | +5 |
| Information / Future | +115% | +60% | +5 |

**Temporary catch-up on Deity.** Sustained, broad or severe setbacks can activate additional yield support:

- **Mild:** +20% Production, +15% Science and Culture, +10% Food.
- **Strong:** +40% Production, +30% Science and Culture, +20% Food.

The strong tier replaces the mild tier; they do not stack, and support ends after recovery. An isolated weakness receives targeted priorities instead of broad yield bonuses. Leading AIs are not weakened to match the player.

## Compatibility

- **Use one AI/difficulty overhaul at a time.** Do not combine with Real Strategy, AI+, RHAI, or similar mods.
- UI-only mods are generally compatible. **BBG compatibility is not guaranteed; multiplayer testing is limited.**

## Feedback

[Report an issue](https://github.com/CHOS1N11111/Adaptive-Strategic-AI-mod-for-Civilization-VI/issues) with your mod version, game settings, enabled mods, and relevant `Lua.log`, `Database.log`, and `Modding.log` files.

[MIT License](LICENSE)
