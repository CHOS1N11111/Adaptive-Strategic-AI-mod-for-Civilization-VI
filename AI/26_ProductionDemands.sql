-- Runtime requests must reach the native demand systems, not just the final
-- item score. These remain AI preferences: native legality, placement, costs,
-- contracts and city orders are not bypassed.
INSERT OR REPLACE INTO GlobalParameters (Name, Value) VALUES
    ('ASAI_PRODUCTION_DEMAND_REVIEW_STANDARD', 8),
    ('ASAI_DEFENSE_CAVALRY_MEMORY_STANDARD', 8);

INSERT INTO Types (Type, Kind) VALUES
    ('ASAI_STRATEGY_CAMPUS_DEMAND', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_ANTICAVALRY_DEMAND', 'KIND_VICTORY_STRATEGY');
INSERT INTO Strategies (StrategyType, NumConditionsNeeded) VALUES
    ('ASAI_STRATEGY_CAMPUS_DEMAND', 1),
    ('ASAI_STRATEGY_ANTICAVALRY_DEMAND', 1);
INSERT INTO StrategyConditions
    (StrategyType, ConditionFunction, StringValue, ThresholdValue, Disqualifier) VALUES
    ('ASAI_STRATEGY_CAMPUS_DEMAND', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_CAMPUS_DEMAND', 'Call Lua Function', 'ASAI_IsCampusDemand', 0, 0),
    ('ASAI_STRATEGY_ANTICAVALRY_DEMAND', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_ANTICAVALRY_DEMAND', 'Call Lua Function', 'ASAI_IsAntiCavalryDemand', 0, 0);

INSERT INTO AiListTypes (ListType) VALUES
    ('ASAI_LandRecoverySpecialization'),
    ('ASAI_LandRecoveryCivilianUnits'),
    ('ASAI_CampusDemandDistricts'),
    ('ASAI_CampusDemandYields'),
    ('ASAI_ConstructionDemandProjects'),
    ('ASAI_AntiCavalryDemandUnits');
INSERT INTO AiLists (ListType, System) VALUES
    ('ASAI_LandRecoverySpecialization', 'AiBuildSpecializations'),
    ('ASAI_LandRecoveryCivilianUnits', 'Units'),
    ('ASAI_CampusDemandDistricts', 'Districts'),
    ('ASAI_CampusDemandYields', 'Yields'),
    ('ASAI_ConstructionDemandProjects', 'Projects'),
    ('ASAI_AntiCavalryDemandUnits', 'Units');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
    ('ASAI_STRATEGY_LAND_RECOVERY', 'ASAI_LandRecoverySpecialization'),
    ('ASAI_STRATEGY_LAND_RECOVERY', 'ASAI_LandRecoveryCivilianUnits'),
    ('ASAI_STRATEGY_CAMPUS_DEMAND', 'ASAI_CampusDemandDistricts'),
    ('ASAI_STRATEGY_CAMPUS_DEMAND', 'ASAI_CampusDemandYields'),
    ('ASAI_STRATEGY_SCIENCE_CONSTRUCTION', 'ASAI_ConstructionDemandProjects'),
    ('ASAI_STRATEGY_ANTICAVALRY_DEMAND', 'ASAI_AntiCavalryDemandUnits');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
    -- Default military specialization has offset +1. This is a conditional
    -- priority offset, NOT production, strength or a city-order command.
    ('ASAI_LandRecoverySpecialization', 'BUILD_MILITARY_UNITS', 1, -3),
    ('ASAI_LandRecoveryCivilianUnits', 'UNIT_SETTLER', 0, -100),
    ('ASAI_LandRecoveryCivilianUnits', 'UNIT_BUILDER', 0, -60),
    ('ASAI_LandRecoveryCivilianUnits', 'UNIT_SPY', 0, -100),
    ('ASAI_CampusDemandYields', 'YIELD_SCIENCE', 1, 60);
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_CampusDemandDistricts', DistrictType, 1, 180 FROM Districts
WHERE DistrictType = 'DISTRICT_CAMPUS'
   OR DistrictType IN (SELECT CivUniqueDistrictType FROM DistrictReplaces
       WHERE ReplacesDistrictType = 'DISTRICT_CAMPUS');
-- The health request needs permanent facilities, not repeatable projects.
-- Do not discourage launch/laser projects, emergency projects, or gold work.
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_ConstructionDemandProjects', ProjectType, 0, -120 FROM Projects
WHERE ProjectType IN ('PROJECT_ENHANCE_DISTRICT_CAMPUS',
                      'PROJECT_ENHANCE_DISTRICT_INDUSTRIAL_ZONE')
  AND COALESCE(SpaceRace, 0) = 0;
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_AntiCavalryDemandUnits', UnitType, 1, 220 FROM Units
WHERE Domain = 'DOMAIN_LAND' AND PromotionClass = 'PROMOTION_CLASS_ANTI_CAVALRY'
  AND COALESCE(Combat, 0) > 0;
-- A scout/medic/AA unit is not the intended replacement for a lost line.
DELETE FROM AiFavoredItems WHERE ListType = 'ASAI_LandRecoveryUnits'
AND Item NOT IN (SELECT UnitType FROM Units WHERE PromotionClass IN
    ('PROMOTION_CLASS_MELEE', 'PROMOTION_CLASS_RANGED',
     'PROMOTION_CLASS_ANTI_CAVALRY', 'PROMOTION_CLASS_LIGHT_CAVALRY',
     'PROMOTION_CLASS_HEAVY_CAVALRY'));

-- Do not let a cached science/recovery strategy suppress recruitment after a
-- war starts. Keep science project and construction preferences; neutralize
-- just the generic military penalties in these temporary sharing strategies.
UPDATE AiFavoredItems SET Value = 0
WHERE (ListType IN ('ASAI_ProductionShareSpecialization',
                    'ASAI_ScienceCapacitySpecialization')
       AND Item = 'BUILD_MILITARY_UNITS')
   OR (ListType IN ('ASAI_ScienceCapacityPseudoYields',
                    'ASAI_MinorRecoveryPseudoYields')
       AND Item = 'PSEUDOYIELD_UNIT_COMBAT');

-- A positive condition alone can linger as a native strategy. Use a stable
-- native qualifier plus an explicit dynamic Disqualifier. The latter
-- returns true on inactive/unknown/error, so failure cannot retain a request.
-- No Exclusive flag is used; independent adaptive strategies may coexist.
-- "Handicap at or below" is an existing native condition. Its signed-int
-- ceiling admits every real difficulty without relying on whether Forbidden
-- contributes to NumConditionsNeeded. Is Not Major remains a disqualifier;
-- Lua separately rejects humans. This does not modify difficulty bonuses.
INSERT INTO StrategyConditions (StrategyType, ConditionFunction, ThresholdValue)
SELECT StrategyType, 'Handicap at or below', 2147483647 FROM Strategies
WHERE StrategyType IN
    ('ASAI_STRATEGY_LAND_RECOVERY', 'ASAI_STRATEGY_RANGED_REINFORCEMENT',
     'ASAI_STRATEGY_WRITING_PREREQUISITE', 'ASAI_STRATEGY_EDUCATION_PREREQUISITE',
     'ASAI_STRATEGY_LABORATORY_PREREQUISITE',
     'ASAI_STRATEGY_SCIENCE_CONSTRUCTION', 'ASAI_STRATEGY_SCIENCE_PRODUCTION_SHARE',
     'ASAI_STRATEGY_SCIENCE_CAPACITY', 'ASAI_STRATEGY_MINOR_FRONT_RECOVERY',
     'ASAI_STRATEGY_CAMPUS_DEMAND', 'ASAI_STRATEGY_ANTICAVALRY_DEMAND');
UPDATE StrategyConditions
SET StringValue = CASE StrategyType
    WHEN 'ASAI_STRATEGY_LAND_RECOVERY' THEN 'ASAI_IsLandRecoveryDisqualified'
    WHEN 'ASAI_STRATEGY_RANGED_REINFORCEMENT' THEN 'ASAI_IsRangedReinforcementDisqualified'
    WHEN 'ASAI_STRATEGY_WRITING_PREREQUISITE' THEN 'ASAI_IsWritingDisqualified'
    WHEN 'ASAI_STRATEGY_EDUCATION_PREREQUISITE' THEN 'ASAI_IsEducationDisqualified'
    WHEN 'ASAI_STRATEGY_LABORATORY_PREREQUISITE' THEN 'ASAI_IsLaboratoryDisqualified'
    WHEN 'ASAI_STRATEGY_SCIENCE_CONSTRUCTION' THEN 'ASAI_IsScienceConstructionDisqualified'
    WHEN 'ASAI_STRATEGY_SCIENCE_PRODUCTION_SHARE' THEN 'ASAI_IsScienceShareDisqualified'
    WHEN 'ASAI_STRATEGY_SCIENCE_CAPACITY' THEN 'ASAI_IsScienceCapacityDisqualified'
    WHEN 'ASAI_STRATEGY_MINOR_FRONT_RECOVERY' THEN 'ASAI_IsMinorRecoveryDisqualified'
    WHEN 'ASAI_STRATEGY_CAMPUS_DEMAND' THEN 'ASAI_IsCampusDemandDisqualified'
    WHEN 'ASAI_STRATEGY_ANTICAVALRY_DEMAND' THEN 'ASAI_IsAntiCavalryDemandDisqualified' END,
    Disqualifier = 1, Forbidden = 0, Exclusive = 0
WHERE ConditionFunction = 'Call Lua Function' AND StrategyType IN
    ('ASAI_STRATEGY_LAND_RECOVERY', 'ASAI_STRATEGY_RANGED_REINFORCEMENT',
     'ASAI_STRATEGY_WRITING_PREREQUISITE', 'ASAI_STRATEGY_EDUCATION_PREREQUISITE',
     'ASAI_STRATEGY_LABORATORY_PREREQUISITE',
     'ASAI_STRATEGY_SCIENCE_CONSTRUCTION', 'ASAI_STRATEGY_SCIENCE_PRODUCTION_SHARE',
     'ASAI_STRATEGY_SCIENCE_CAPACITY', 'ASAI_STRATEGY_MINOR_FRONT_RECOVERY',
     'ASAI_STRATEGY_CAMPUS_DEMAND', 'ASAI_STRATEGY_ANTICAVALRY_DEMAND');
