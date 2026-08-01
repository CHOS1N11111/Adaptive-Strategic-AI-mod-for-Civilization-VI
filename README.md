**English** | [简体中文](README.zh-CN.md)

# Adaptive Strategic AI 0.8.0

Adaptive Strategic AI is not a cheat pack that feeds hidden resources to the AI. It is an auditable, measurable AI engineering baseline for Gathering Storm. Testing should use a new game starting in the Ancient Era. Release 0.8.0 is based on a complete turn 1-75 Online Speed review and fixes focus execution recovery, reduces opening wonder traps and settler escort waste, and improves the conversion of trade infrastructure into actual route capacity.

## What This Release Does

- Deity AI no longer receives a free additional Settler. An Ancient Era start now gives each Deity AI 1 Settler, 2 Warriors, and 1 Builder in total.
- Deity yield, combat, and experience bonuses scale with the world era, reducing early pressure while preserving a stronger late-game threat.
- A one- or two-city AI temporarily reduces its wonder preference and increases its Settler preference during the first 70 Standard-speed-equivalent turns. The strategy exits immediately at 3 cities and does not constrain later wonders or victory plans. Existing and currently produced Settlers still count against the civilian budget and suppress duplicate production.
- Settlement operations retain one combat escort but no longer wait for extra formation strength around safe targets. A team is capped at 1 Settler plus 1 escort. Plot evaluation places more value on fresh water, resources, and compact settlement.
- The AI conditionally enables six baseline support strategies for insufficient improvements, Traders, trade route capacity, budget deficits, wartime mobilization, and military modernization.
- Every surviving major AI independently compares its overall strength with the human player and checks its science, culture, and empire pillars. There is no global competitor quota, and the system does not force every AI into exact parity.
- Catch-up support has a modest tier and a bounded severe tier. Severe support can activate when overall strength collapses or at least two core pillars fail together. Only one pillar recovery runs at a time; an ineffective direction exits into its own cooldown so another valid pillar can take over.
- War tracking distinguishes a formal declaration from actual contact. Full wartime mobilization activates only when the AI is near a major-civilization front or has recently participated in attributable combat.
- Infrastructure recovery considers city count, population, and owned territory so populous or coastal civilizations are not permanently misclassified as under-improved.
- Builder, Trader, and Settler budgets include active units and the item each city is currently producing. A reverse-pressure strategy suppresses duplicate orders once a budget is full. Gameplay scripts cannot see future items that have not started in the UI production queue, so only current production is counted.
- Every controller evaluation diagnoses total and per-city production, population-derived specialty district capacity, trade capacity, improvement coverage, current production categories, and gold reserves. This separates "not enough cities" from "cities are not converting production into useful assets." The gameplay scripting environment exposes no reliable API for strategic-resource stock limits or upgrade feasibility, so the log marks those sensors unsupported instead of emitting false precision.
- When a science, culture, or empire focus fails to improve during a review window, the controller checks the real production response. Stronger execution weights activate both when no city responds and when relevant production exists but the gap still grows. They are removed only after the result improves. Civilization-specific replacements receive the same district and building signals.
- Science, culture, domination, religious, and diplomatic victory plans receive distinct preferences for districts, buildings, units, technologies, civics, and projects.
- City attack operations use shorter assembly distances, lower deadlock-prone launch thresholds, and more practical ranged, siege, and air compositions.
- A trailing AI reduces wonder preference to preserve production for expansion, improvements, trade, and key districts. Severe support increases that opportunity cost and removes it after recovery. Active wars against major civilizations apply a separate wonder opportunity cost.
- The mod does not spawn units or grant free technologies, free resources, or hidden bonuses triggered by player performance.

## Player-Relative Pacing

- Sampling starts at turn 35 in Standard-speed-equivalent time. Metrics are sampled every turn and evaluated every 4 Standard-speed-equivalent turns. Online, Standard, and Epic speeds are normalized through `GameSpeeds.CostMultiplier`.
- Overall strength weights science at 32% (20% completed technologies and 12% science output), culture at 30% (18% completed civics and 12% culture output), empire at 25% (10% cities and 15% population), and military at 13%. Normal components are clamped to 55%-145%; military contributes at no more than 120%.
- When the player is in the Ancient or Classical Era, catch-up enters/exits at 88%/94%. The Medieval and Renaissance thresholds are 90%/96%, and Industrial or later thresholds are 92%/97%. Lead-consolidation boundaries remain 125%/118%, 120%/113%, and 115%/108% respectively.
- Decisions use speed-normalized exponential smoothing. A boundary must be crossed on 2 consecutive evaluations before the state changes. A state remains active for at least 12 Standard-speed-equivalent turns, followed by an 8-turn cooldown after a normal exit.
- Science at or below 88%, culture at or below 85%, and empire at or below 85% can become recovery candidates, but only the weakest eligible pillar activates. Their exit thresholds are 96%, 95%, and 95%. A focus exits or switches only after recovery or when another pillar becomes materially weaker.
- An active focus is reviewed every 12 Standard-speed-equivalent turns. If the smoothed ratio improves by less than 3 percentage points and the raw ratio by less than 1 point, the controller checks how many cities are producing related assets. No response is classified as `stalled`; a response with a still-growing gap is `executing`. Both activate execution recovery. Three ineffective review windows place that pillar on a 16-turn cooldown, avoiding both premature abandonment and a permanently locked strategy.
- Severe support can activate after two confirmations when the overall ratio is at or below 80%, or when the second-weakest science, culture, or empire pillar is at or below 78%. It exits only after overall strength reaches 88% and the second-weakest pillar reaches 86%. Support adds bounded native AI decision weights and never grants direct yields, units, or progress.
- General catch-up weights remain deliberately modest. Normal catch-up applies a `-20` wonder pseudo-yield adjustment, while severe support adds `-30`, for a combined `-50` when both are active. A leading AI does not lose science, culture, production, Settler, or wonder preference; it receives only small gold and defense adjustments.
- This controller never directly adds or removes yields, resources, technology progress, units, or combat strength. Enable flags, evaluation timing, entry/exit thresholds, and the seven component weights are configurable in `AI/10_CoreEconomy.sql`; the component weights should continue to sum to 100.
- In 0.8.0, production, districts, trade, and conversion diagnostics still do not enter the seven-component overall score. Only whether current production responds to the selected focus can temporarily raise native AI execution weights.

The infrastructure improvement target is `max(2 * cities, min(0.65 * population, 0.30 * owned plots))`. Each existing or currently produced Builder offsets two potential improvements; a currently produced Trader similarly offsets the trade-route deficit. When trade capacity is below `ceil(cities / 3)`, the AI favors Commercial Hubs or Harbors and more strongly prioritizes their first Market or Lighthouse capacity building. Expansion recovery allows `max(1, ceil(cities / 5))` existing or currently produced Settlers. Independent budget strategies reduce further civilian production after those limits are reached.

## Total Deity Bonus Curve

| World Era | Production / Gold | Science / Culture / Faith | Combat Strength | Unit Experience |
| --- | ---: | ---: | ---: | ---: |
| Ancient | +20% | +10% | +1 | +10% |
| Classical | +25% | +14% | +1 | +15% |
| Medieval | +35% | +20% | +1 | +20% |
| Renaissance | +45% | +28% | +1 | +25% |
| Industrial | +55% | +36% | +1 | +30% |
| Modern | +65% | +44% | +2 | +35% |
| Atomic | +75% | +52% | +2 | +40% |
| Information / Future | +90% | +60% | +2 | +40% |

## Installation and Use

1. Enable `Adaptive Strategic AI` under **Additional Content -> Mods**.
2. Select the Gathering Storm ruleset. Deity difficulty, Standard speed, and an Ancient Era start are recommended for baseline testing.
3. Start a new game. Existing saves do not fully recalculate starting units or the early-game bonus curve.

Do not combine this mod with RHAI, Real Strategy, AI+, Better AI Tweaks, Late Game AI, Smooth Difficulty, or other mods that change AI strategies or difficulty bonuses. UI-only mods are generally compatible. Better Balanced Game is not an AI mod, but it substantially changes technologies, units, and districts; disable it for formal baseline tests and evaluate compatibility separately afterward.

## Validation and Benchmarking

Run the offline validator with:

```powershell
python .\Tools\validate_mod.py
```

`ASAI_ENABLE_METRICS` in `AI/10_CoreEconomy.sql` defaults to `1` in the current test release. Each controller evaluation emits `ASAI_METRIC`, `ASAI_COMPONENTS`, `ASAI_ECONOMY`, and `ASAI_CONVERSION`. Focus reviews also emit `ASAI_FOCUS`, including queue response and consecutive failure counts. Current production is read through the gameplay-script `CurrentlyBuilding()` API. Diagnostic sensors fail closed independently and do not stop the controller. Overall pacing changes emit `ASAI_PACING`, focus changes emit `ASAI_RECOVERY`, and support-tier changes emit `ASAI_SUPPORT`.

The claim that this mod is better than existing alternatives must be established through multiple controlled games. Relative pacing prevents a match from losing tension too early; long-term planning, player modeling, war lifecycle management, and victory conversion must make that competition feel earned by the AI itself.
