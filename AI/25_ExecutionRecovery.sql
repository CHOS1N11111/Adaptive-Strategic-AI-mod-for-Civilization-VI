-- Bounded, outcome-driven execution. These change AI valuation only; they
-- neither grant assets nor force a technology, production order or war.
INSERT OR REPLACE INTO GlobalParameters (Name, Value) VALUES
    ('ASAI_SCIENCE_BOTTLENECK_DELAY_STANDARD', 8),
    ('ASAI_TRADE_EXECUTION_DELAY_STANDARD', 12),
    ('ASAI_WAR_ATTRITION_WINDOW_STANDARD', 8),
    ('ASAI_WAR_SURVIVAL_UNITS_PER_CITY_X100', 85),
    ('ASAI_WAR_REINFORCED_UNITS_PER_CITY_X100', 125),
    ('ASAI_WAR_SERIOUS_OWN_LOSS_X100', 25),
    ('ASAI_LOYALTY_STABILIZE_STANDARD', 16);

INSERT OR REPLACE INTO GlobalParameters (Name, Value) VALUES
    ('ASAI_TRADER_EXECUTION_DELAY_STANDARD', 12),
    ('ASAI_SCIENCE_FIRST_PORT_HORIZON_STANDARD', 24);

-- Fixed valuation changes with runtime queue budgets, not yield grants or
-- forced orders. Native strategy refresh may lag the Lua condition.
INSERT INTO Types (Type, Kind) VALUES
    ('ASAI_STRATEGY_LAND_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_TRADER_EXECUTION', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_SCIENCE_SATELLITE_EXECUTION', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_SCIENCE_PREPARATION_BUDGET', 'KIND_VICTORY_STRATEGY');
INSERT INTO Strategies (StrategyType, NumConditionsNeeded) VALUES
    ('ASAI_STRATEGY_LAND_RECOVERY', 1),
    ('ASAI_STRATEGY_TRADER_EXECUTION', 1),
    ('ASAI_STRATEGY_SCIENCE_SATELLITE_EXECUTION', 1),
    ('ASAI_STRATEGY_SCIENCE_PREPARATION_BUDGET', 1);
INSERT INTO StrategyConditions
    (StrategyType, ConditionFunction, StringValue, ThresholdValue, Disqualifier) VALUES
    ('ASAI_STRATEGY_LAND_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_LAND_RECOVERY', 'Call Lua Function', 'ASAI_IsLandRecovery', 0, 0),
    ('ASAI_STRATEGY_TRADER_EXECUTION', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_TRADER_EXECUTION', 'Call Lua Function', 'ASAI_IsTraderExecution', 0, 0),
    ('ASAI_STRATEGY_SCIENCE_SATELLITE_EXECUTION', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_SCIENCE_SATELLITE_EXECUTION', 'Call Lua Function', 'ASAI_IsScienceSatelliteExecution', 0, 0),
    ('ASAI_STRATEGY_SCIENCE_PREPARATION_BUDGET', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_SCIENCE_PREPARATION_BUDGET', 'Call Lua Function', 'ASAI_IsSciencePreparationBudget', 0, 0);
INSERT INTO AiListTypes (ListType) VALUES
    ('ASAI_LandRecoveryUnits'), ('ASAI_LandRecoveryPseudoYields'),
    ('ASAI_TraderExecutionUnits'), ('ASAI_TraderExecutionPseudoYields'),
    ('ASAI_SatelliteExecutionProjects'), ('ASAI_SatelliteExecutionPseudoYields'),
    ('ASAI_PreparationBudgetDistricts');
INSERT INTO AiLists (ListType, System) VALUES
    ('ASAI_LandRecoveryUnits', 'Units'),
    ('ASAI_LandRecoveryPseudoYields', 'PseudoYields'),
    ('ASAI_TraderExecutionUnits', 'Units'),
    ('ASAI_TraderExecutionPseudoYields', 'PseudoYields'),
    ('ASAI_SatelliteExecutionProjects', 'Projects'),
    ('ASAI_SatelliteExecutionPseudoYields', 'PseudoYields'),
    ('ASAI_PreparationBudgetDistricts', 'Districts');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
    ('ASAI_STRATEGY_LAND_RECOVERY', 'ASAI_LandRecoveryUnits'),
    ('ASAI_STRATEGY_LAND_RECOVERY', 'ASAI_LandRecoveryPseudoYields'),
    ('ASAI_STRATEGY_TRADER_EXECUTION', 'ASAI_TraderExecutionUnits'),
    ('ASAI_STRATEGY_TRADER_EXECUTION', 'ASAI_TraderExecutionPseudoYields'),
    ('ASAI_STRATEGY_SCIENCE_SATELLITE_EXECUTION', 'ASAI_SatelliteExecutionProjects'),
    ('ASAI_STRATEGY_SCIENCE_SATELLITE_EXECUTION', 'ASAI_SatelliteExecutionPseudoYields'),
    ('ASAI_STRATEGY_SCIENCE_PREPARATION_BUDGET', 'ASAI_PreparationBudgetDistricts');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_LandRecoveryUnits', UnitType, 1, 180 FROM Units
WHERE Domain = 'DOMAIN_LAND'
  AND MAX(COALESCE(Combat, 0), COALESCE(RangedCombat, 0), COALESCE(AntiAirCombat, 0)) > 0
  AND PromotionClass NOT IN ('PROMOTION_CLASS_SIEGE', 'PROMOTION_CLASS_GIANT_DEATH_ROBOT');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_TraderExecutionUnits', UnitType, 1, 220 FROM Units WHERE MakeTradeRoute = 1;
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
    ('ASAI_LandRecoveryPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 80),
    ('ASAI_LandRecoveryPseudoYields', 'PSEUDOYIELD_WONDER', 0, -45),
    ('ASAI_TraderExecutionPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 160),
    ('ASAI_SatelliteExecutionProjects', 'PROJECT_LAUNCH_EARTH_SATELLITE', 1, 350),
    ('ASAI_SatelliteExecutionPseudoYields', 'PSEUDOYIELD_SPACE_RACE', 1, 125),
    ('ASAI_PreparationBudgetDistricts', 'DISTRICT_SPACEPORT', 0, -400);

INSERT INTO Types (Type, Kind) VALUES
    ('ASAI_STRATEGY_WRITING_PREREQUISITE', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_EDUCATION_PREREQUISITE', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_LABORATORY_PREREQUISITE', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_RANGED_REINFORCEMENT', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_SIEGE_REINFORCEMENT', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_TRADE_DISTRICT_EXECUTION', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_TRADE_BUILDING_EXECUTION', 'KIND_VICTORY_STRATEGY');

INSERT INTO Strategies (StrategyType, NumConditionsNeeded) VALUES
    ('ASAI_STRATEGY_WRITING_PREREQUISITE', 1),
    ('ASAI_STRATEGY_EDUCATION_PREREQUISITE', 1),
    ('ASAI_STRATEGY_LABORATORY_PREREQUISITE', 1),
    ('ASAI_STRATEGY_RANGED_REINFORCEMENT', 1),
    ('ASAI_STRATEGY_SIEGE_REINFORCEMENT', 1),
    ('ASAI_STRATEGY_TRADE_DISTRICT_EXECUTION', 1),
    ('ASAI_STRATEGY_TRADE_BUILDING_EXECUTION', 1);

INSERT INTO StrategyConditions
    (StrategyType, ConditionFunction, StringValue, ThresholdValue, Disqualifier)
VALUES
    ('ASAI_STRATEGY_WRITING_PREREQUISITE', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_WRITING_PREREQUISITE', 'Call Lua Function', 'ASAI_IsWritingPrerequisite', 0, 0),
    ('ASAI_STRATEGY_EDUCATION_PREREQUISITE', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_EDUCATION_PREREQUISITE', 'Call Lua Function', 'ASAI_IsEducationPrerequisite', 0, 0),
    ('ASAI_STRATEGY_LABORATORY_PREREQUISITE', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_LABORATORY_PREREQUISITE', 'Call Lua Function', 'ASAI_IsLaboratoryPrerequisite', 0, 0),
    ('ASAI_STRATEGY_RANGED_REINFORCEMENT', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_RANGED_REINFORCEMENT', 'Call Lua Function', 'ASAI_IsRangedReinforcement', 0, 0),
    ('ASAI_STRATEGY_SIEGE_REINFORCEMENT', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_SIEGE_REINFORCEMENT', 'Call Lua Function', 'ASAI_IsSiegeReinforcement', 0, 0),
    ('ASAI_STRATEGY_TRADE_DISTRICT_EXECUTION', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_TRADE_DISTRICT_EXECUTION', 'Call Lua Function', 'ASAI_IsTradeDistrictExecution', 0, 0),
    ('ASAI_STRATEGY_TRADE_BUILDING_EXECUTION', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_TRADE_BUILDING_EXECUTION', 'Call Lua Function', 'ASAI_IsTradeBuildingExecution', 0, 0);

INSERT INTO AiListTypes (ListType) VALUES
    ('ASAI_WritingPrerequisiteTechs'),
    ('ASAI_EducationPrerequisiteTechs'),
    ('ASAI_LaboratoryPrerequisiteTechs'),
    ('ASAI_WritingInfrastructureDistricts'),
    ('ASAI_WritingInfrastructureBuildings'),
    ('ASAI_EducationInfrastructureBuildings'),
    ('ASAI_LaboratoryInfrastructureBuildings'),
    ('ASAI_RangedReinforcementUnits'),
    ('ASAI_SiegeReinforcementUnits'),
    ('ASAI_TradeExecutionDistricts'),
    ('ASAI_TradeExecutionBuildings'),
    ('ASAI_TradeExecutionTechs'),
    ('ASAI_TradeExecutionYields'),
    ('ASAI_ExecutionOptionalBuildings');

INSERT INTO AiLists (ListType, System) VALUES
    ('ASAI_WritingPrerequisiteTechs', 'Technologies'),
    ('ASAI_EducationPrerequisiteTechs', 'Technologies'),
    ('ASAI_LaboratoryPrerequisiteTechs', 'Technologies'),
    ('ASAI_WritingInfrastructureDistricts', 'Districts'),
    ('ASAI_WritingInfrastructureBuildings', 'Buildings'),
    ('ASAI_EducationInfrastructureBuildings', 'Buildings'),
    ('ASAI_LaboratoryInfrastructureBuildings', 'Buildings'),
    ('ASAI_RangedReinforcementUnits', 'Units'),
    ('ASAI_SiegeReinforcementUnits', 'Units'),
    ('ASAI_TradeExecutionDistricts', 'Districts'),
    ('ASAI_TradeExecutionBuildings', 'Buildings'),
    ('ASAI_TradeExecutionTechs', 'Technologies'),
    ('ASAI_TradeExecutionYields', 'Yields'),
    ('ASAI_ExecutionOptionalBuildings', 'Buildings');

INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
    ('ASAI_STRATEGY_WRITING_PREREQUISITE', 'ASAI_WritingPrerequisiteTechs'),
    ('ASAI_STRATEGY_EDUCATION_PREREQUISITE', 'ASAI_EducationPrerequisiteTechs'),
    ('ASAI_STRATEGY_LABORATORY_PREREQUISITE', 'ASAI_LaboratoryPrerequisiteTechs'),
    ('ASAI_STRATEGY_WRITING_PREREQUISITE', 'ASAI_WritingInfrastructureDistricts'),
    ('ASAI_STRATEGY_WRITING_PREREQUISITE', 'ASAI_WritingInfrastructureBuildings'),
    ('ASAI_STRATEGY_EDUCATION_PREREQUISITE', 'ASAI_EducationInfrastructureBuildings'),
    ('ASAI_STRATEGY_LABORATORY_PREREQUISITE', 'ASAI_LaboratoryInfrastructureBuildings'),
    ('ASAI_STRATEGY_RANGED_REINFORCEMENT', 'ASAI_RangedReinforcementUnits'),
    ('ASAI_STRATEGY_SIEGE_REINFORCEMENT', 'ASAI_SiegeReinforcementUnits'),
    ('ASAI_STRATEGY_TRADE_DISTRICT_EXECUTION', 'ASAI_TradeExecutionDistricts'),
    ('ASAI_STRATEGY_TRADE_DISTRICT_EXECUTION', 'ASAI_TradeExecutionTechs'),
    ('ASAI_STRATEGY_TRADE_DISTRICT_EXECUTION', 'ASAI_TradeExecutionYields'),
    ('ASAI_STRATEGY_TRADE_DISTRICT_EXECUTION', 'ASAI_ExecutionOptionalBuildings'),
    ('ASAI_STRATEGY_TRADE_BUILDING_EXECUTION', 'ASAI_TradeExecutionBuildings'),
    ('ASAI_STRATEGY_TRADE_BUILDING_EXECUTION', 'ASAI_TradeExecutionYields'),
    ('ASAI_STRATEGY_TRADE_BUILDING_EXECUTION', 'ASAI_ExecutionOptionalBuildings'),
    ('ASAI_STRATEGY_SCIENCE_EXECUTION_RECOVERY', 'ASAI_ExecutionOptionalBuildings');

-- Follow the actual database prerequisite graph, including replacements by
-- other mods. Only one science stage can request this bounded preference.
WITH RECURSIVE Prerequisites(ListType, TechnologyType, Depth) AS (
    VALUES
        ('ASAI_WritingPrerequisiteTechs', 'TECH_WRITING', 0),
        ('ASAI_EducationPrerequisiteTechs', 'TECH_EDUCATION', 0),
        ('ASAI_LaboratoryPrerequisiteTechs', 'TECH_CHEMISTRY', 0)
    UNION ALL
    SELECT p.ListType, t.PrereqTech, p.Depth + 1
    FROM Prerequisites AS p
    JOIN TechnologyPrereqs AS t ON t.Technology = p.TechnologyType
    WHERE p.Depth < 2
)
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT p.ListType, p.TechnologyType, 1,
    MAX(CASE WHEN p.Depth = 0 THEN 400 WHEN p.Depth = 1 THEN 120 ELSE 55 END)
FROM Prerequisites AS p
JOIN Technologies AS t ON t.TechnologyType = p.TechnologyType
GROUP BY p.ListType, p.TechnologyType;

-- A stage stays attached to its specific facility after its technology is
-- owned. Generic science priorities alone could still choose more Campuses.
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_WritingInfrastructureDistricts', DistrictType, 1, 90 FROM Districts
WHERE DistrictType = 'DISTRICT_CAMPUS'
   OR DistrictType IN (SELECT CivUniqueDistrictType FROM DistrictReplaces
       WHERE ReplacesDistrictType = 'DISTRICT_CAMPUS');

WITH Facilities(ListType, BuildingType, Weight) AS (
    VALUES ('ASAI_WritingInfrastructureBuildings', 'BUILDING_LIBRARY', 120),
           ('ASAI_EducationInfrastructureBuildings', 'BUILDING_UNIVERSITY', 160),
           ('ASAI_LaboratoryInfrastructureBuildings', 'BUILDING_RESEARCH_LAB', 180)
)
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT f.ListType, b.BuildingType, 1, f.Weight
FROM Facilities f JOIN Buildings b ON b.BuildingType = f.BuildingType
   OR b.BuildingType IN (SELECT CivUniqueBuildingType FROM BuildingReplaces
       WHERE ReplacesBuildingType = f.BuildingType);

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_RangedReinforcementUnits', UnitType, 1, 125 FROM Units
WHERE PromotionClass = 'PROMOTION_CLASS_RANGED'
  AND MAX(COALESCE(Combat, 0), COALESCE(RangedCombat, 0)) > 0;

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_SiegeReinforcementUnits', UnitType, 1, 160 FROM Units
WHERE PromotionClass = 'PROMOTION_CLASS_SIEGE' AND COALESCE(Bombard, 0) > 0;

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_TradeExecutionDistricts', DistrictType, 1, 90 FROM Districts
WHERE DistrictType IN ('DISTRICT_COMMERCIAL_HUB', 'DISTRICT_HARBOR')
   OR DistrictType IN (SELECT CivUniqueDistrictType FROM DistrictReplaces
       WHERE ReplacesDistrictType IN ('DISTRICT_COMMERCIAL_HUB', 'DISTRICT_HARBOR'));

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_TradeExecutionBuildings', BuildingType, 1, 180 FROM Buildings
WHERE BuildingType IN ('BUILDING_MARKET', 'BUILDING_LIGHTHOUSE')
   OR BuildingType IN (SELECT CivUniqueBuildingType FROM BuildingReplaces
       WHERE ReplacesBuildingType IN ('BUILDING_MARKET', 'BUILDING_LIGHTHOUSE'));

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
    ('ASAI_TradeExecutionTechs', 'TECH_CURRENCY', 1, 100),
    ('ASAI_TradeExecutionYields', 'YIELD_PRODUCTION', 1, 15),
    ('ASAI_TradeExecutionYields', 'YIELD_GOLD', 1, 15);

-- Reduce optional military-building competition, not defensive unit access,
-- walls, cultural identity, or space projects. Never change their base costs.
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_ExecutionOptionalBuildings', BuildingType, 0, -45 FROM Buildings
WHERE PrereqDistrict = 'DISTRICT_ENCAMPMENT'
  AND COALESCE(IsWonder, 0) = 0;
