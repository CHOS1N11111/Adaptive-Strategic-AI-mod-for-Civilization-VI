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
    MustHaveUnits = 6
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
SET MinNumber = 1,
    MaxNumber = 3
WHERE TeamName = 'City Attack Force'
  AND AiType = 'UNITTYPE_SIEGE';

UPDATE OpTeamRequirements
SET MinNumber = 1,
    MaxNumber = 4
WHERE TeamName = 'City Attack Force'
  AND AiType = 'UNITTYPE_SIEGE_ALL';

UPDATE OpTeamRequirements
SET MinNumber = 2,
    MaxNumber = 5
WHERE TeamName = 'City Attack Force'
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
