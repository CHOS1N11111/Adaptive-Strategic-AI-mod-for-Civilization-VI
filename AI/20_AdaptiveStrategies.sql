-- Utility strategies activate from deterministic Lua checks. They supplement
-- the chosen victory strategy instead of replacing leader identity.
INSERT OR IGNORE INTO Types (Type, Kind) VALUES
    ('ASAI_STRATEGY_INFRA_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_LATE_GAME', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_RELATIVE_CONSOLIDATE', 'KIND_VICTORY_STRATEGY');

INSERT OR IGNORE INTO Strategies
    (StrategyType, NumConditionsNeeded)
VALUES
    ('ASAI_STRATEGY_INFRA_RECOVERY', 1),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 1),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 1),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 1),
    ('ASAI_STRATEGY_LATE_GAME', 1),
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 1),
    ('ASAI_STRATEGY_RELATIVE_CONSOLIDATE', 1);

INSERT OR IGNORE INTO StrategyConditions
    (StrategyType, ConditionFunction, StringValue, ThresholdValue, Disqualifier)
VALUES
    ('ASAI_STRATEGY_INFRA_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_INFRA_RECOVERY', 'Call Lua Function', 'ASAI_IsInfrastructureRecovery', 0, 0),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 'Call Lua Function', 'ASAI_IsTradeRecovery', 0, 0),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'Call Lua Function', 'ASAI_IsGoldRecovery', 0, 0),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'Call Lua Function', 'ASAI_IsWarMobilization', 0, 0),
    ('ASAI_STRATEGY_LATE_GAME', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_LATE_GAME', 'Call Lua Function', 'ASAI_IsLateGame', 0, 0),
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 'Call Lua Function', 'ASAI_IsRelativeCatchup', 0, 0),
    ('ASAI_STRATEGY_RELATIVE_CONSOLIDATE', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_RELATIVE_CONSOLIDATE', 'Call Lua Function', 'ASAI_IsRelativeConsolidate', 0, 0);

INSERT OR IGNORE INTO AiListTypes (ListType) VALUES
    ('ASAI_InfraPseudoYields'),
    ('ASAI_InfraUnits'),
    ('ASAI_InfraYields'),
    ('ASAI_TradePseudoYields'),
    ('ASAI_TradeUnits'),
    ('ASAI_TradeYields'),
    ('ASAI_GoldPseudoYields'),
    ('ASAI_GoldDistricts'),
    ('ASAI_GoldBuildings'),
    ('ASAI_GoldYields'),
    ('ASAI_GoldWonders'),
    ('ASAI_WarPseudoYields'),
    ('ASAI_WarUnitBuilds'),
    ('ASAI_WarYields'),
    ('ASAI_WarOperations'),
    ('ASAI_WarWonders'),
    ('ASAI_LatePseudoYields'),
    ('ASAI_LateDistricts'),
    ('ASAI_LateBuildings'),
    ('ASAI_LateUnitBuilds'),
    ('ASAI_LateUnits'),
    ('ASAI_RelativeCatchupPseudoYields'),
    ('ASAI_RelativeCatchupUnits'),
    ('ASAI_RelativeCatchupYields'),
    ('ASAI_RelativeCatchupDistricts'),
    ('ASAI_RelativeCatchupWonders'),
    ('ASAI_RelativeLeadPseudoYields'),
    ('ASAI_RelativeLeadYields'),
    ('ASAI_RelativeLeadWonders');

INSERT OR IGNORE INTO AiLists (ListType, System) VALUES
    ('ASAI_InfraPseudoYields', 'PseudoYields'),
    ('ASAI_InfraUnits', 'Units'),
    ('ASAI_InfraYields', 'Yields'),
    ('ASAI_TradePseudoYields', 'PseudoYields'),
    ('ASAI_TradeUnits', 'Units'),
    ('ASAI_TradeYields', 'Yields'),
    ('ASAI_GoldPseudoYields', 'PseudoYields'),
    ('ASAI_GoldDistricts', 'Districts'),
    ('ASAI_GoldBuildings', 'Buildings'),
    ('ASAI_GoldYields', 'Yields'),
    ('ASAI_GoldWonders', 'Buildings'),
    ('ASAI_WarPseudoYields', 'PseudoYields'),
    ('ASAI_WarUnitBuilds', 'UnitPromotionClasses'),
    ('ASAI_WarYields', 'Yields'),
    ('ASAI_WarOperations', 'AiOperationTypes'),
    ('ASAI_WarWonders', 'Buildings'),
    ('ASAI_LatePseudoYields', 'PseudoYields'),
    ('ASAI_LateDistricts', 'Districts'),
    ('ASAI_LateBuildings', 'Buildings'),
    ('ASAI_LateUnitBuilds', 'UnitPromotionClasses'),
    ('ASAI_LateUnits', 'Units'),
    ('ASAI_RelativeCatchupPseudoYields', 'PseudoYields'),
    ('ASAI_RelativeCatchupUnits', 'Units'),
    ('ASAI_RelativeCatchupYields', 'Yields'),
    ('ASAI_RelativeCatchupDistricts', 'Districts'),
    ('ASAI_RelativeCatchupWonders', 'Buildings'),
    ('ASAI_RelativeLeadPseudoYields', 'PseudoYields'),
    ('ASAI_RelativeLeadYields', 'Yields'),
    ('ASAI_RelativeLeadWonders', 'Buildings');

INSERT OR IGNORE INTO Strategy_Priorities (StrategyType, ListType) VALUES
    ('ASAI_STRATEGY_INFRA_RECOVERY', 'ASAI_InfraPseudoYields'),
    ('ASAI_STRATEGY_INFRA_RECOVERY', 'ASAI_InfraUnits'),
    ('ASAI_STRATEGY_INFRA_RECOVERY', 'ASAI_InfraYields'),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 'ASAI_TradePseudoYields'),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 'ASAI_TradeUnits'),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 'ASAI_TradeYields'),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'ASAI_GoldPseudoYields'),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'ASAI_GoldDistricts'),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'ASAI_GoldBuildings'),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'ASAI_GoldYields'),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'ASAI_GoldWonders'),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'ASAI_WarPseudoYields'),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'ASAI_WarUnitBuilds'),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'ASAI_WarYields'),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'ASAI_WarOperations'),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'ASAI_WarWonders'),
    ('ASAI_STRATEGY_LATE_GAME', 'ASAI_LatePseudoYields'),
    ('ASAI_STRATEGY_LATE_GAME', 'ASAI_LateDistricts'),
    ('ASAI_STRATEGY_LATE_GAME', 'ASAI_LateBuildings'),
    ('ASAI_STRATEGY_LATE_GAME', 'ASAI_LateUnitBuilds'),
    ('ASAI_STRATEGY_LATE_GAME', 'ASAI_LateUnits'),
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 'ASAI_RelativeCatchupPseudoYields'),
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 'ASAI_RelativeCatchupUnits'),
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 'ASAI_RelativeCatchupYields'),
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 'ASAI_RelativeCatchupDistricts'),
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 'ASAI_RelativeCatchupWonders'),
    ('ASAI_STRATEGY_RELATIVE_CONSOLIDATE', 'ASAI_RelativeLeadPseudoYields'),
    ('ASAI_STRATEGY_RELATIVE_CONSOLIDATE', 'ASAI_RelativeLeadYields'),
    ('ASAI_STRATEGY_RELATIVE_CONSOLIDATE', 'ASAI_RelativeLeadWonders');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
VALUES
    ('ASAI_InfraPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 100),
    ('ASAI_InfraUnits', 'UNIT_BUILDER', 1, 60),
    ('ASAI_InfraYields', 'YIELD_PRODUCTION', 1, 15),
    ('ASAI_TradePseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 150),
    ('ASAI_TradeUnits', 'UNIT_TRADER', 1, 80),
    ('ASAI_TradeYields', 'YIELD_GOLD', 1, 20),
    ('ASAI_GoldPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 60),
    ('ASAI_GoldDistricts', 'DISTRICT_COMMERCIAL_HUB', 1, 30),
    ('ASAI_GoldDistricts', 'DISTRICT_HARBOR', 1, 30),
    ('ASAI_GoldYields', 'YIELD_GOLD', 1, 60),
    ('ASAI_GoldYields', 'YIELD_PRODUCTION', 1, 10),
    ('ASAI_WarPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 35),
    ('ASAI_WarPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 25),
    ('ASAI_WarPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 30),
    ('ASAI_WarPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -35),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_MELEE', 1, 10),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_RANGED', 1, 15),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, 35),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_AIR_FIGHTER', 1, 20),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_AIR_BOMBER', 1, 30),
    ('ASAI_WarYields', 'YIELD_PRODUCTION', 1, 25),
    ('ASAI_WarYields', 'YIELD_GOLD', 1, 10),
    ('ASAI_WarOperations', 'CITY_ASSAULT', 1, 1),
    ('ASAI_LatePseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 75),
    ('ASAI_LatePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 25),
    ('ASAI_LateDistricts', 'DISTRICT_AERODROME', 1, 35),
    ('ASAI_LateDistricts', 'DISTRICT_INDUSTRIAL_ZONE', 1, 15),
    ('ASAI_LateUnitBuilds', 'PROMOTION_CLASS_AIR_FIGHTER', 1, 50),
    ('ASAI_LateUnitBuilds', 'PROMOTION_CLASS_AIR_BOMBER', 1, 65),
    ('ASAI_LateUnits', 'UNIT_ANTIAIR_GUN', 1, 20),
    ('ASAI_LateUnits', 'UNIT_MOBILE_SAM', 1, 25),
    ('ASAI_RelativeCatchupPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 20),
    ('ASAI_RelativeCatchupPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 20),
    ('ASAI_RelativeCatchupPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 8),
    ('ASAI_RelativeCatchupUnits', 'UNIT_BUILDER', 1, 15),
    ('ASAI_RelativeCatchupUnits', 'UNIT_TRADER', 1, 20),
    ('ASAI_RelativeCatchupYields', 'YIELD_PRODUCTION', 1, 8),
    ('ASAI_RelativeCatchupYields', 'YIELD_SCIENCE', 1, 10),
    ('ASAI_RelativeCatchupYields', 'YIELD_CULTURE', 1, 9),
    ('ASAI_RelativeCatchupYields', 'YIELD_GOLD', 1, 5),
    ('ASAI_RelativeCatchupDistricts', 'DISTRICT_CAMPUS', 1, 10),
    ('ASAI_RelativeCatchupDistricts', 'DISTRICT_THEATER', 1, 10),
    ('ASAI_RelativeCatchupDistricts', 'DISTRICT_INDUSTRIAL_ZONE', 1, 8),
    ('ASAI_RelativeCatchupDistricts', 'DISTRICT_COMMERCIAL_HUB', 1, 6),
    ('ASAI_RelativeCatchupDistricts', 'DISTRICT_HARBOR', 1, 6),
    ('ASAI_RelativeLeadPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -18),
    ('ASAI_RelativeLeadPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, -5),
    ('ASAI_RelativeLeadYields', 'YIELD_PRODUCTION', 1, -3),
    ('ASAI_RelativeLeadYields', 'YIELD_SCIENCE', 1, -6),
    ('ASAI_RelativeLeadYields', 'YIELD_CULTURE', 1, -5),
    ('ASAI_RelativeLeadYields', 'YIELD_GOLD', 1, 3);

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_GoldBuildings', BuildingType, 1, 25
FROM Buildings
WHERE BuildingType IN
    ('BUILDING_MARKET', 'BUILDING_BANK', 'BUILDING_STOCK_EXCHANGE',
     'BUILDING_LIGHTHOUSE', 'BUILDING_SHIPYARD', 'BUILDING_SEAPORT');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_LateBuildings', BuildingType, 1, 25
FROM Buildings
WHERE BuildingType IN
    ('BUILDING_FACTORY', 'BUILDING_COAL_POWER_PLANT',
     'BUILDING_FOSSIL_FUEL_POWER_PLANT', 'BUILDING_POWER_PLANT',
     'BUILDING_HANGAR', 'BUILDING_AIRPORT');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_GoldWonders', BuildingType, 1, -50
FROM Buildings
WHERE IsWonder = 1;

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_WarWonders', BuildingType, 1, -75
FROM Buildings
WHERE IsWonder = 1;

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_RelativeCatchupWonders', BuildingType, 1, -12
FROM Buildings
WHERE IsWonder = 1;

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_RelativeLeadWonders', BuildingType, 1, -8
FROM Buildings
WHERE IsWonder = 1;
