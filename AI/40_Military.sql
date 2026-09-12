-- Keep attack operations local enough to reinforce and small enough to launch.
UPDATE AiOperationDefs
SET MaxTargetDistInRegion = 12,
    MaxTargetDistInArea = 12,
    MaxTargetDistInWorld = 14,
    MinOddsOfSuccess = 0.45,
    MustHaveUnits = 5
WHERE OperationName = 'Attack Enemy City';

UPDATE AiOperationDefs
SET MaxTargetDistInRegion = 12,
    MaxTargetDistInArea = 14,
    MaxTargetDistInWorld = 16,
    MinOddsOfSuccess = 0.30,
    MustHaveUnits = 4
WHERE OperationName = 'Wartime Attack Enemy City';

UPDATE AiOperationDefs
SET MaxTargetDistInRegion = 10,
    MaxTargetDistInArea = 10,
    MaxTargetDistInWorld = 12,
    MinOddsOfSuccess = 0.50,
    MustHaveUnits = 7
WHERE OperationName = 'Attack Walled City';

UPDATE AiOperationDefs
SET MaxTargetDistInRegion = 10,
    MaxTargetDistInArea = 12,
    MaxTargetDistInWorld = 14,
    MinOddsOfSuccess = 0.35,
    -- This is a launch floor, not an exact formation size. Optional team
    -- slots can still recruit a larger army when enough units are available.
    MustHaveUnits = 5
WHERE OperationName = 'Wartime Attack Walled City';

UPDATE AiOperationTeams
SET InitialStrengthAdvantage = 1.0,
    OngoingStrengthAdvantage = 1.8
WHERE TeamName = 'Simple City Attack Force'
  AND OperationName = 'Attack Enemy City';

UPDATE AiOperationTeams
SET InitialStrengthAdvantage = 0.5,
    OngoingStrengthAdvantage = 1.0
WHERE TeamName = 'Simple City Attack Force'
  AND OperationName = 'Wartime Attack Enemy City';

UPDATE AiOperationTeams
SET InitialStrengthAdvantage = 1.2,
    OngoingStrengthAdvantage = 2.2
WHERE TeamName = 'City Attack Force'
  AND OperationName = 'Attack Walled City';

UPDATE AiOperationTeams
SET InitialStrengthAdvantage = 0.7,
    OngoingStrengthAdvantage = 1.4
WHERE TeamName = 'City Attack Force'
  AND OperationName = 'Wartime Attack Walled City';

UPDATE OpTeamRequirements
SET MinNumber = 1,
    MaxNumber = 4
WHERE TeamName = 'Simple City Attack Force'
  AND AiType = 'UNITTYPE_RANGED';

UPDATE OpTeamRequirements
-- UNITTYPE_SIEGE_ALL already keeps one wall-breaking slot mandatory. Requiring
-- a second, strict siege-class slot prevents modern air/GDR-heavy armies from
-- assembling even when they otherwise satisfy the operation.
SET MinNumber = 0,
    MaxNumber = 3
WHERE TeamName = 'City Attack Force'
  AND AiType = 'UNITTYPE_SIEGE';

UPDATE OpTeamRequirements
SET MinNumber = 1,
    MaxNumber = 4
WHERE TeamName = 'City Attack Force'
  AND AiType = 'UNITTYPE_SIEGE_ALL';

UPDATE OpTeamRequirements
-- One ranged unit is the launch floor; MaxNumber keeps 1-5 valid so a richer
-- army may bring more ranged units without blocking a smaller usable force.
SET MinNumber = 1,
    MaxNumber = 5
WHERE TeamName = 'City Attack Force'
  AND AiType = 'UNITTYPE_RANGED';

-- UNITTYPE_RANGED also includes siege/recon/naval units. A bombard can
-- therefore fill the previous "ranged" contract even with zero archers.
-- Give these two LAND attack teams an explicit direct-ranged role. Preserve
-- their existing 1-4 / 1-5 bounds and all other assembly requirements.
-- Original unit roles remain intact for every other operation/tactical AI.
INSERT OR IGNORE INTO UnitAiTypes (AiType) VALUES ('UNITTYPE_ASAI_DIRECT_RANGED');
DELETE FROM UnitAiInfos WHERE AiType = 'UNITTYPE_ASAI_DIRECT_RANGED';
INSERT INTO UnitAiInfos (UnitType, AiType)
SELECT UnitType, 'UNITTYPE_ASAI_DIRECT_RANGED' FROM Units
WHERE Domain = 'DOMAIN_LAND' AND PromotionClass = 'PROMOTION_CLASS_RANGED'
  AND COALESCE(RangedCombat, 0) > 0
  AND EXISTS (SELECT 1 FROM UnitAiInfos a WHERE a.UnitType = Units.UnitType
              AND a.AiType = 'UNITAI_COMBAT');
UPDATE OpTeamRequirements SET AiType = 'UNITTYPE_ASAI_DIRECT_RANGED'
WHERE TeamName IN ('Simple City Attack Force', 'City Attack Force')
  AND AiType = 'UNITTYPE_RANGED';

UPDATE OpTeamRequirements
SET MinNumber = 0,
    MaxNumber = 3
WHERE TeamName = 'City Attack Force'
  AND AiType = 'UNITTYPE_AIR';

UPDATE OpTeamRequirements
SET MinNumber = 0,
    MaxNumber = 2
WHERE TeamName = 'City Attack Force'
  AND AiType = 'UNITTYPE_AIR_SIEGE';

-- Permit two concurrent defensive responses and settlement escorts.
UPDATE AiFavoredItems
SET Value = 2
WHERE ListType = 'BaseOperationsLimits'
  AND Item IN ('OP_DEFENSE', 'OP_SETTLE');
