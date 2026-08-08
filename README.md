**English** | [简体中文](README.zh-CN.md)

# Adaptive Strategic AI 0.9.0

Adaptive Strategic AI reshapes Civilization VI: Gathering Storm AI behavior around expansion, economic development, military readiness, and player-relative pacing. Version 0.9.0 preserves a credible Deity opening and increases sustained mid- and late-game pressure, while retaining bounded, reversible support for AI civilizations that fall behind.

## What This Release Does

- An Ancient Era Deity AI starts with 2 Settlers, 3 Warriors, and 1 Builder in total. This is a meaningful opening advantage but remains below the full vanilla Deity start of approximately 3 Settlers, 5 Warriors, and 2 Builders.
- Deity begins at `+50%` Production/Gold, `+24%` Science/Culture/Faith, `+3` combat strength, and `+30%` unit experience, then scales smoothly with the world era to preserve late-game pressure.
- An AI below 4 cities temporarily reduces its wonder preference and increases its Settler preference during the first 70 Standard-speed-equivalent turns. The strategy exits immediately at 4 cities and does not constrain later wonders or victory plans. Existing and currently produced Settlers still count against the civilian budget and suppress duplicate production.
- Settlement operations retain one combat escort but no longer wait for extra formation strength around safe targets. A team is capped at 1 Settler plus 1 escort. Plot evaluation places more value on fresh water, resources, and compact settlement.
- The AI conditionally enables baseline support strategies for insufficient improvements, Traders, trade route capacity, budget deficits, military readiness, wartime mobilization, and military modernization.
- Every surviving major AI independently compares its overall strength with the human player and checks its science, culture, and empire pillars. There is no global competitor quota, and the system does not force every AI into exact parity.
- Catch-up support has two mutually exclusive, bounded result tiers on Deity. Confirmed normal catch-up adds `+20%` Production and `+15%` Science/Culture. Severe support replaces it with `+40%` Production and `+30%` Science/Culture when overall strength collapses, multiple core pillars fail, one pillar falls critically low, or an AI's military collapses during an active major war. Each tier applies an exact inverse after recovery. Only one pillar recovery runs at a time; an ineffective direction exits into its own cooldown so another valid pillar can take over.
- War tracking distinguishes a formal declaration from actual contact. Full wartime mobilization activates only when the AI is near a major-civilization front or has recently participated in attributable combat.
- Military readiness runs independently from the single science, culture, or empire recovery focus. It enters after two evaluations at or below 78% of the player's smoothed military strength, enters immediately when raw strength falls to 60%, or enters from Standard-equivalent turn 50 when combat-unit density is at or below 1.75 per planned city. A planned city is an existing city plus at most one expansion slot when a Settler exists or is currently being produced. While active, it favors a mixed standing army, ranged, siege, anti-cavalry, and air units while increasing the opportunity cost of extra Settlers and wonders. A separate execution strategy remains active below a rounded-up 25%-of-cities combat-production target, rising to 45% during an active major war; defensive-building pressure is kept below field-army pressure.
- Scale recovery also runs independently from the shared pillar focus. From Standard-equivalent turn 50 it enters after two evaluations at or below 75% of the player's smoothed empire scale, or immediately when the raw empire ratio reaches 60%. It remains active across science, culture, and empire focus changes until the smoothed empire ratio reaches 88%. While active, it favors population, production, improvements, trade capacity, Industrial Zones, Commercial Hubs/Harbors, and their foundational buildings while increasing wonder opportunity cost.
- Scale recovery permits one additional Settler pipeline, capped at three total. Active major wars still disable expansion recovery, and military readiness pauses extra expansion while combat-unit density remains below 2.25 per planned city. This prevents economic catch-up from cancelling the defensive floor.
- Infrastructure recovery considers city count, population, and owned territory so populous or coastal civilizations are not permanently misclassified as under-improved.
- Builder, Trader, and Settler budgets include active units and the item each city is currently producing. Once a budget is full, reverse pressure reduces duplicate orders across cities.
- The controller tracks total and per-city production, specialty district capacity, trade capacity, improvement coverage, current construction, and gold reserves. These signals distinguish expansion shortages from cities that are not converting production into useful assets.
- When a science, culture, or empire focus fails to improve, the controller checks actual city production and temporarily strengthens the relevant execution weights. Theater Squares, their buildings, Monuments, and civilization-specific replacements receive the corresponding culture signal. The extra weights are removed after recovery.
- Science, culture, domination, religious, and diplomatic victory plans receive distinct preferences for districts, buildings, units, technologies, civics, and projects.
- City attack operations use shorter assembly distances, practical launch thresholds, and more balanced ranged, siege, and air compositions. Wartime mobilization avoids splitting scarce defensive units across unnecessary assaults.
- A trailing AI reduces wonder preference to preserve production for expansion, improvements, trade, and key districts. Severe support increases that opportunity cost and removes it after recovery. Military weakness and active major-civilization wars apply stronger, temporary opportunity costs.
- The mod does not spawn units or grant technologies, civics, resources, cities, or accumulated progress. Its player-relative result modifiers affect only future Production and Science/Culture rates on Deity; they do not affect Gold, Faith, combat strength, or matched/leading AIs.

## Player-Relative Pacing

- Sampling starts at turn 35 in Standard-speed-equivalent time. Metrics are sampled every turn and evaluated every 4 Standard-speed-equivalent turns. Online, Standard, and Epic speeds are normalized through `GameSpeeds.CostMultiplier`.
- Overall strength weights science at 32% (20% completed technologies and 12% science output), culture at 30% (18% completed civics and 12% culture output), empire at 25% (10% cities and 15% population), and military at 13%. Normal components are clamped to 55%-145%; military contributes at no more than 120%.
- When the player is in the Ancient or Classical Era, overall catch-up enters/exits at 88%/94%. The Medieval and Renaissance thresholds are 90%/96%, and Industrial or later thresholds are 92%/97%. A weakest science, culture, or empire pillar at or below 85% can also enter catch-up; it must reach 95% before catch-up exits. Lead-consolidation boundaries remain 125%/118%, 120%/113%, and 115%/108% respectively.
- Decisions use speed-normalized exponential smoothing. A boundary must be crossed on 2 consecutive evaluations before the state changes. A state remains active for at least 12 Standard-speed-equivalent turns, followed by an 8-turn cooldown after a normal exit.
- Military readiness uses 78%/92% smoothed entry and exit thresholds. A raw ratio at or below 60% bypasses normal confirmation for emergency entry. From Standard-equivalent turn 50, at most one active or currently produced Settler is included in planned city count; density at or below 1.75 combat units per planned city can enter readiness, and density must recover to at least 2.25 before exit. Minimum dwell and cooldown prevent routine oscillation. This state is parallel to pillar recovery, so defense cannot be hidden by science, culture, empire strength, or an early military lead that is too thin for planned expansion.
- Scale recovery starts at Standard-equivalent turn 50 and uses 75%/88% smoothed empire entry and exit thresholds. A raw empire ratio at or below 60% enters immediately. It has its own persistence, confirmation, dwell, and cooldown, so an ineffective empire focus can hand the shared slot to science or culture without discarding the foundational scale response.
- Science at or below 88%, culture at or below 85%, and empire at or below 85% can become recovery candidates, but only the weakest eligible pillar activates. Their exit thresholds are 96%, 95%, and 95%. A focus exits or switches only after recovery or when another pillar becomes materially weaker.
- An active focus is reviewed every 12 Standard-speed-equivalent turns. If the smoothed ratio improves by less than 3 percentage points and the raw ratio by less than 1 point, the controller checks how many cities are producing related assets. No response is classified as `stalled`; a response with a still-growing gap is `executing`. Both activate execution recovery. Three ineffective review windows place that pillar on a 16-turn cooldown, avoiding both premature abandonment and a permanently locked strategy.
- Severe support can activate after two confirmations when the overall ratio is at or below 80%, when the second-weakest science, culture, or empire pillar is at or below 78%, when the weakest pillar is at or below 70%, or when raw military strength is at or below 60% during an active major war. It exits only after overall strength reaches 88%, the second-weakest pillar reaches 86%, the weakest pillar reaches 80%, and the wartime emergency has cleared. On Deity, the active state adds `+40%` Production and `+30%` Science/Culture to every current or future city. Exit attaches `-40%/-30%/-30%`, exactly cancelling the entry ledger; re-entry remains capped at the same net tier.
- General catch-up weights remain deliberately modest. Normal catch-up applies a `-20` wonder pseudo-yield adjustment, while severe support adds `-30`, for a combined `-50` when both are active. A leading AI does not lose science, culture, production, Settler, or wonder preference; it receives only small gold and defense adjustments.
- The mild and severe result layers change future city yield rates rather than awarding stored yields or research/civic progress. `ASAI_MILD_RESULT_YIELDS_ENABLED` and `ASAI_SEVERE_RESULT_YIELDS_ENABLED` can disable them; evaluation timing, entry/exit thresholds, and the seven component weights remain configurable in `AI/10_CoreEconomy.sql`, and the component weights should continue to sum to 100.
- Production, districts, trade, military composition, and conversion diagnostics do not enter the seven-component overall score. Focus response, military readiness, and scale recovery raise bounded native AI execution weights; both result tiers are tracked separately.

The infrastructure improvement target is `max(2 * cities, min(0.65 * population, 0.30 * owned plots))`. Each existing or currently produced Builder offsets two potential improvements; a currently produced Trader similarly offsets the trade-route deficit. When trade capacity is below `ceil(cities / 2)`, the AI favors Commercial Hubs or Harbors and gives their first Market or Lighthouse a `+120` conditional priority so capacity is completed before more competing orders displace it. Baseline expansion recovery allows `max(1, ceil(cities / 5))` existing or currently produced Settlers; scale recovery adds one slot up to a total cap of three. Independent budget strategies reduce further civilian production after the active limit is reached.

## Total Deity Bonus Curve

| World Era | Production / Gold | Science / Culture / Faith | Combat Strength | Unit Experience |
| --- | ---: | ---: | ---: | ---: |
| Ancient | +50% | +24% | +3 | +30% |
| Classical | +55% | +27% | +3 | +32% |
| Medieval | +65% | +32% | +4 | +34% |
| Renaissance | +75% | +38% | +4 | +36% |
| Industrial | +85% | +44% | +4 | +38% |
| Modern | +95% | +50% | +4 | +40% |
| Atomic | +105% | +55% | +4 | +40% |
| Information / Future | +115% | +60% | +4 | +40% |

While confirmed normal catch-up is active on Deity, add `+20` percentage points to Production and `+15` to Science/Culture in the applicable row. Severe support replaces that tier with `+40` and `+30`. Gold, Faith, combat strength, and experience are unchanged. Recovery removes the complete adaptive addition.

## Installation and Use

1. Enable `Adaptive Strategic AI` under **Additional Content -> Mods**.
2. Select the Gathering Storm ruleset. Deity difficulty, Standard speed, and an Ancient Era start are recommended.
3. Start a new game. Existing saves do not fully recalculate starting units or the early-game bonus curve.

Do not combine this mod with RHAI, Real Strategy, AI+, Better AI Tweaks, Late Game AI, Smooth Difficulty, or other mods that change AI strategies or difficulty bonuses. UI-only mods are generally compatible. Better Balanced Game is not an AI mod, but it substantially changes technologies, units, and districts, so compatibility is not guaranteed.

## Diagnostics and Configuration

The repository includes an offline consistency check:

```powershell
python .\Tools\validate_mod.py
```

`ASAI_ENABLE_METRICS` in `AI/10_CoreEconomy.sql` defaults to `1`. Each controller evaluation emits `ASAI_METRIC`, `ASAI_COMPONENTS`, `ASAI_ECONOMY`, `ASAI_CONVERSION`, and `ASAI_MILITARY`. These entries cover relative strength, the weakest core pillar, economic conversion, scale recovery, the active Settler cap, city defenses, unit roles, military density, the current military queue target, and whether execution recovery is active. Focus reviews emit `ASAI_FOCUS`. State changes use `ASAI_PACING`, `ASAI_RECOVERY`, `ASAI_SUPPORT`, `ASAI_RESULT`, `ASAI_SCALE`, and `ASAI_READINESS`, including reason fields where applicable.
