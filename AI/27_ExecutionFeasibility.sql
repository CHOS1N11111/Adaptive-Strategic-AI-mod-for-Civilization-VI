-- Keep old type IDs for save compatibility but detach ALL their priorities.
-- Fresh R2 identities do not inherit 0.11.17's observed Forbidden state.
-- This is database migration, not a claim about the proprietary save loader:
-- admission/re-entry still needs an in-game test after a full restart.
CREATE TEMP TABLE ASAI_GateMigration (OldType TEXT PRIMARY KEY);
INSERT INTO ASAI_GateMigration VALUES
    ('ASAI_STRATEGY_LAND_RECOVERY'), ('ASAI_STRATEGY_RANGED_REINFORCEMENT'),
    ('ASAI_STRATEGY_WRITING_PREREQUISITE'), ('ASAI_STRATEGY_EDUCATION_PREREQUISITE'),
    ('ASAI_STRATEGY_LABORATORY_PREREQUISITE'), ('ASAI_STRATEGY_SCIENCE_CONSTRUCTION'),
    ('ASAI_STRATEGY_SCIENCE_PRODUCTION_SHARE'), ('ASAI_STRATEGY_SCIENCE_CAPACITY'),
    ('ASAI_STRATEGY_MINOR_FRONT_RECOVERY'), ('ASAI_STRATEGY_CAMPUS_DEMAND'),
    ('ASAI_STRATEGY_ANTICAVALRY_DEMAND');
INSERT INTO Types (Type, Kind)
SELECT OldType || '_R2', 'KIND_VICTORY_STRATEGY' FROM ASAI_GateMigration;
INSERT INTO Strategies (StrategyType, NumConditionsNeeded)
SELECT OldType || '_R2', 1 FROM ASAI_GateMigration;
INSERT INTO StrategyConditions
    (StrategyType, ConditionFunction, StringValue, ThresholdValue, Forbidden, Disqualifier, Exclusive)
SELECT c.StrategyType || '_R2', c.ConditionFunction, c.StringValue,
       c.ThresholdValue, 0, c.Disqualifier, 0
FROM StrategyConditions c JOIN ASAI_GateMigration m ON m.OldType = c.StrategyType;
INSERT INTO Strategy_Priorities (StrategyType, ListType)
SELECT p.StrategyType || '_R2', p.ListType
FROM Strategy_Priorities p JOIN ASAI_GateMigration m ON m.OldType = p.StrategyType;
DELETE FROM Strategy_Priorities WHERE StrategyType IN (SELECT OldType FROM ASAI_GateMigration);
UPDATE StrategyConditions SET StringValue = 'ASAI_IsRetiredStrategy',
    Forbidden = 0, Disqualifier = 0, Exclusive = 0
WHERE ConditionFunction = 'Call Lua Function'
  AND StrategyType IN (SELECT OldType FROM ASAI_GateMigration);
DROP TABLE ASAI_GateMigration;

INSERT INTO Types (Type, Kind) VALUES
    ('ASAI_STRATEGY_URGENT_LAND', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_CAMPUS_SLOT_PRESSURE', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_LASER_ORBITAL', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_LASER_TERRESTRIAL', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_LASER_POWER', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_LASER_PORT_HANDOFF', 'KIND_VICTORY_STRATEGY');
INSERT INTO Strategies (StrategyType, NumConditionsNeeded) VALUES
    ('ASAI_STRATEGY_URGENT_LAND', 1), ('ASAI_STRATEGY_CAMPUS_SLOT_PRESSURE', 1),
    ('ASAI_STRATEGY_LASER_ORBITAL', 1), ('ASAI_STRATEGY_LASER_TERRESTRIAL', 1),
    ('ASAI_STRATEGY_LASER_POWER', 1), ('ASAI_STRATEGY_LASER_PORT_HANDOFF', 1);
INSERT INTO StrategyConditions (StrategyType, ConditionFunction, StringValue, Disqualifier) VALUES
    ('ASAI_STRATEGY_URGENT_LAND', 'Call Lua Function', 'ASAI_IsUrgentLandDemand', 0),
    ('ASAI_STRATEGY_CAMPUS_SLOT_PRESSURE', 'Call Lua Function', 'ASAI_IsCampusSlotPressure', 0),
    ('ASAI_STRATEGY_LASER_ORBITAL', 'Call Lua Function', 'ASAI_IsOrbitalLaserDemand', 0),
    ('ASAI_STRATEGY_LASER_TERRESTRIAL', 'Call Lua Function', 'ASAI_IsTerrestrialLaserDemand', 0),
    ('ASAI_STRATEGY_LASER_POWER', 'Call Lua Function', 'ASAI_IsLaserPowerDemand', 0),
    ('ASAI_STRATEGY_LASER_PORT_HANDOFF', 'Call Lua Function', 'ASAI_IsLaserPortHandoff', 0);
INSERT INTO StrategyConditions (StrategyType, ConditionFunction, Disqualifier)
SELECT StrategyType, 'Is Not Major', 1 FROM Strategies
WHERE StrategyType IN ('ASAI_STRATEGY_URGENT_LAND', 'ASAI_STRATEGY_CAMPUS_SLOT_PRESSURE',
    'ASAI_STRATEGY_LASER_ORBITAL', 'ASAI_STRATEGY_LASER_TERRESTRIAL',
    'ASAI_STRATEGY_LASER_POWER', 'ASAI_STRATEGY_LASER_PORT_HANDOFF');

INSERT INTO AiListTypes (ListType) VALUES
    ('ASAI_UrgentLandCompetition'), ('ASAI_UrgentLandProjects'),
    ('ASAI_UrgentLandBuildings'), ('ASAI_UrgentLandDistricts'),
    ('ASAI_CampusSlotDistricts'), ('ASAI_CampusSlotGrowth'),
    ('ASAI_OrbitalResourceProjects'), ('ASAI_TerrestrialResourceProjects'),
    ('ASAI_LaserPowerBuildings'), ('ASAI_LaserHandoffProjects'),
    ('ASAI_LaserHandoffSpecialization');
INSERT INTO AiLists (ListType, System) VALUES
    ('ASAI_UrgentLandCompetition', 'Units'), ('ASAI_UrgentLandProjects', 'Projects'),
    ('ASAI_UrgentLandBuildings', 'Buildings'), ('ASAI_UrgentLandDistricts', 'Districts'),
    ('ASAI_CampusSlotDistricts', 'Districts'), ('ASAI_CampusSlotGrowth', 'Yields'),
    ('ASAI_OrbitalResourceProjects', 'Projects'), ('ASAI_TerrestrialResourceProjects', 'Projects'),
    ('ASAI_LaserPowerBuildings', 'Buildings'), ('ASAI_LaserHandoffProjects', 'Projects'),
    ('ASAI_LaserHandoffSpecialization', 'AiBuildSpecializations');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
    ('ASAI_STRATEGY_URGENT_LAND', 'ASAI_UrgentLandCompetition'),
    ('ASAI_STRATEGY_URGENT_LAND', 'ASAI_UrgentLandProjects'),
    ('ASAI_STRATEGY_URGENT_LAND', 'ASAI_UrgentLandBuildings'),
    ('ASAI_STRATEGY_URGENT_LAND', 'ASAI_UrgentLandDistricts'),
    ('ASAI_STRATEGY_CAMPUS_SLOT_PRESSURE', 'ASAI_CampusSlotDistricts'),
    ('ASAI_STRATEGY_CAMPUS_SLOT_PRESSURE', 'ASAI_CampusSlotGrowth'),
    ('ASAI_STRATEGY_LASER_ORBITAL', 'ASAI_OrbitalResourceProjects'),
    ('ASAI_STRATEGY_LASER_TERRESTRIAL', 'ASAI_TerrestrialResourceProjects'),
    ('ASAI_STRATEGY_LASER_POWER', 'ASAI_LaserPowerBuildings'),
    ('ASAI_STRATEGY_LASER_PORT_HANDOFF', 'ASAI_LaserHandoffProjects'),
    ('ASAI_STRATEGY_LASER_PORT_HANDOFF', 'ASAI_LaserHandoffSpecialization');

-- Soft, temporary competition adjustments, never bans. Keep walls, ground
-- defenders, AA, power and space launches out of these negative lists.
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_UrgentLandCompetition', UnitType, 0, -80 FROM Units
WHERE Domain IN ('DOMAIN_AIR', 'DOMAIN_SEA') AND COALESCE(Combat, 0) > 0;
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_UrgentLandProjects', ProjectType, 0, -180 FROM Projects
WHERE ProjectType = 'PROJECT_TRAIN_ATHLETES' AND COALESCE(SpaceRace, 0) = 0;
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_UrgentLandBuildings', BuildingType, 0, -65 FROM Buildings
WHERE PrereqDistrict IN ('DISTRICT_AERODROME', 'DISTRICT_ENCAMPMENT')
  AND COALESCE(IsWonder, 0) = 0;
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_UrgentLandDistricts', DistrictType, 0, -70 FROM Districts
WHERE DistrictType IN ('DISTRICT_AERODROME', 'DISTRICT_ENCAMPMENT')
   OR DistrictType IN (SELECT CivUniqueDistrictType FROM DistrictReplaces
       WHERE ReplacesDistrictType IN ('DISTRICT_AERODROME', 'DISTRICT_ENCAMPMENT'));
-- Preserve the last potential campus slot from optional military expansion.
-- Neither this list nor the probe invents population or legal placement.
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_CampusSlotDistricts', Item, 0, -100
FROM AiFavoredItems WHERE ListType = 'ASAI_UrgentLandDistricts';
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
    ('ASAI_CampusSlotGrowth', 'YIELD_FOOD', 1, 20),
    ('ASAI_OrbitalResourceProjects', 'PROJECT_ORBITAL_LASER', 1, 240),
    ('ASAI_TerrestrialResourceProjects', 'PROJECT_TERRESTRIAL_LASER', 1, 240),
    ('ASAI_LaserHandoffProjects', 'PROJECT_ORBITAL_LASER', 1, 180),
    ('ASAI_LaserHandoffProjects', 'PROJECT_TERRESTRIAL_LASER', 1, 180),
    ('ASAI_LaserHandoffSpecialization', 'BUILD_FOR_SCIENCE', 1, -3);
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_LaserPowerBuildings', BuildingType, 1, 100 FROM Buildings
WHERE BuildingType IN ('BUILDING_COAL_POWER_PLANT', 'BUILDING_FOSSIL_FUEL_POWER_PLANT',
    'BUILDING_POWER_PLANT', 'BUILDING_HYDROELECTRIC_DAM');
-- Neutralize retired prerequisite preferences after unlock by legality.
-- Do not add negative generic recruitment offsets: native exit can lag.
