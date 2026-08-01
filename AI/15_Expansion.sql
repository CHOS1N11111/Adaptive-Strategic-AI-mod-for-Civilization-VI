-- Favor compact, productive settlement without turning expansion into a
-- command. These values only change AI plot evaluation and operation sizing.
UPDATE AiFavoredItems SET Value = -8
WHERE ListType = 'StandardSettlePlot'
  AND Item = 'Nearest Friendly City';

UPDATE AiFavoredItems SET Value = 30
WHERE ListType = 'StandardSettlePlot'
  AND Item = 'Fresh Water';

UPDATE AiFavoredItems SET Value = 15
WHERE ListType = 'StandardSettlePlot'
  AND Item = 'Coastal';

UPDATE AiFavoredItems SET Value = 5
WHERE ListType = 'StandardSettlePlot'
  AND Item = 'New Resources';

UPDATE AiFavoredItems SET Value = 4
WHERE ListType = 'StandardSettlePlot'
  AND Item = 'Resource Class'
  AND StringVal = 'RESOURCECLASS_LUXURY';

UPDATE AiFavoredItems SET Value = 5
WHERE ListType = 'StandardSettlePlot'
  AND Item = 'Resource Class'
  AND StringVal = 'RESOURCECLASS_STRATEGIC';

UPDATE PlotEvalConditions SET PoorValue = -40, GoodValue = -16
WHERE ConditionType = 'Nearest Friendly City';

UPDATE PlotEvalConditions SET PoorValue = 0, GoodValue = 6
WHERE ConditionType = 'New Resources';

UPDATE PlotEvalConditions SET PoorValue = 14, GoodValue = 20
WHERE ConditionType = 'Inner Ring Yield';

UPDATE PlotEvalConditions SET PoorValue = 18, GoodValue = 32
WHERE ConditionType = 'Total Yield';

UPDATE PlotEvalConditions SET PoorValue = -1, GoodValue = 10
WHERE ConditionType = 'Coastal';

UPDATE PlotEvalConditions SET PoorValue = -1, GoodValue = 4
WHERE ConditionType = 'Specific Resource';

-- One combat escort remains mandatory through OpTeamRequirements. Prevent the
-- strength-matching layer from holding settlers for extra military units.
UPDATE AiOperationTeams
SET InitialStrengthAdvantage = 0,
    OngoingStrengthAdvantage = 0,
    MaxUnits = 2
WHERE TeamName = 'Settle City Team'
  AND OperationName = 'Settle New City';
