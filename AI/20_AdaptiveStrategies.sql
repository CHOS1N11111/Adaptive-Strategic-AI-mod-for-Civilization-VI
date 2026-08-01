-- Utility strategies activate from deterministic Lua checks. They supplement
-- the chosen victory strategy instead of replacing leader identity.
-- Remove this mod's previous strategy rows first so version upgrades cannot
-- retain obsolete weights in a reused gameplay cache.
DELETE FROM Strategy_Priorities
WHERE StrategyType LIKE 'ASAI_%' OR ListType LIKE 'ASAI_%';
DELETE FROM AiFavoredItems WHERE ListType LIKE 'ASAI_%';
DELETE FROM AiLists WHERE ListType LIKE 'ASAI_%';
DELETE FROM AiListTypes WHERE ListType LIKE 'ASAI_%';
DELETE FROM StrategyConditions WHERE StrategyType LIKE 'ASAI_%';
DELETE FROM Strategies WHERE StrategyType LIKE 'ASAI_%';
DELETE FROM Types WHERE Type LIKE 'ASAI_STRATEGY_%';

INSERT OR IGNORE INTO Types (Type, Kind) VALUES
    ('ASAI_STRATEGY_OPENING_EXPANSION', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_INFRA_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_TRADE_CAPACITY_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_BUILDER_BUDGET', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_TRADER_BUDGET', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_SETTLER_BUDGET', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_LATE_GAME', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_RELATIVE_SEVERE_CATCHUP', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_RELATIVE_CONSOLIDATE', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_SCIENCE_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_CULTURE_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_EMPIRE_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_SCIENCE_EXECUTION_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_CULTURE_EXECUTION_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_EMPIRE_EXECUTION_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_EXPANSION_RECOVERY', 'KIND_VICTORY_STRATEGY');

INSERT OR IGNORE INTO Strategies
    (StrategyType, NumConditionsNeeded)
VALUES
    ('ASAI_STRATEGY_OPENING_EXPANSION', 1),
    ('ASAI_STRATEGY_INFRA_RECOVERY', 1),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 1),
    ('ASAI_STRATEGY_TRADE_CAPACITY_RECOVERY', 1),
    ('ASAI_STRATEGY_BUILDER_BUDGET', 1),
    ('ASAI_STRATEGY_TRADER_BUDGET', 1),
    ('ASAI_STRATEGY_SETTLER_BUDGET', 1),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 1),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 1),
    ('ASAI_STRATEGY_LATE_GAME', 1),
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 1),
    ('ASAI_STRATEGY_RELATIVE_SEVERE_CATCHUP', 1),
    ('ASAI_STRATEGY_RELATIVE_CONSOLIDATE', 1),
    ('ASAI_STRATEGY_SCIENCE_RECOVERY', 1),
    ('ASAI_STRATEGY_CULTURE_RECOVERY', 1),
    ('ASAI_STRATEGY_EMPIRE_RECOVERY', 1),
    ('ASAI_STRATEGY_SCIENCE_EXECUTION_RECOVERY', 1),
    ('ASAI_STRATEGY_CULTURE_EXECUTION_RECOVERY', 1),
    ('ASAI_STRATEGY_EMPIRE_EXECUTION_RECOVERY', 1),
    ('ASAI_STRATEGY_EXPANSION_RECOVERY', 1);

INSERT OR IGNORE INTO StrategyConditions
    (StrategyType, ConditionFunction, StringValue, ThresholdValue, Disqualifier)
VALUES
    ('ASAI_STRATEGY_OPENING_EXPANSION', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_OPENING_EXPANSION', 'Call Lua Function', 'ASAI_IsOpeningExpansion', 0, 0),
    ('ASAI_STRATEGY_INFRA_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_INFRA_RECOVERY', 'Call Lua Function', 'ASAI_IsInfrastructureRecovery', 0, 0),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 'Call Lua Function', 'ASAI_IsTradeRecovery', 0, 0),
    ('ASAI_STRATEGY_TRADE_CAPACITY_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_TRADE_CAPACITY_RECOVERY', 'Call Lua Function', 'ASAI_IsTradeCapacityRecovery', 0, 0),
    ('ASAI_STRATEGY_BUILDER_BUDGET', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_BUILDER_BUDGET', 'Call Lua Function', 'ASAI_IsBuilderBudgetReached', 0, 0),
    ('ASAI_STRATEGY_TRADER_BUDGET', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_TRADER_BUDGET', 'Call Lua Function', 'ASAI_IsTraderBudgetReached', 0, 0),
    ('ASAI_STRATEGY_SETTLER_BUDGET', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_SETTLER_BUDGET', 'Call Lua Function', 'ASAI_IsSettlerBudgetReached', 0, 0),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'Call Lua Function', 'ASAI_IsGoldRecovery', 0, 0),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'Call Lua Function', 'ASAI_IsWarMobilization', 0, 0),
    ('ASAI_STRATEGY_LATE_GAME', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_LATE_GAME', 'Call Lua Function', 'ASAI_IsLateGame', 0, 0),
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 'Call Lua Function', 'ASAI_IsRelativeCatchup', 0, 0),
    ('ASAI_STRATEGY_RELATIVE_SEVERE_CATCHUP', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_RELATIVE_SEVERE_CATCHUP', 'Call Lua Function', 'ASAI_IsRelativeSevereCatchup', 0, 0),
    ('ASAI_STRATEGY_RELATIVE_CONSOLIDATE', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_RELATIVE_CONSOLIDATE', 'Call Lua Function', 'ASAI_IsRelativeConsolidate', 0, 0),
    ('ASAI_STRATEGY_SCIENCE_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_SCIENCE_RECOVERY', 'Call Lua Function', 'ASAI_IsScienceRecovery', 0, 0),
    ('ASAI_STRATEGY_CULTURE_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_CULTURE_RECOVERY', 'Call Lua Function', 'ASAI_IsCultureRecovery', 0, 0),
    ('ASAI_STRATEGY_EMPIRE_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_EMPIRE_RECOVERY', 'Call Lua Function', 'ASAI_IsEmpireRecovery', 0, 0),
    ('ASAI_STRATEGY_SCIENCE_EXECUTION_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_SCIENCE_EXECUTION_RECOVERY', 'Call Lua Function', 'ASAI_IsScienceExecutionRecovery', 0, 0),
    ('ASAI_STRATEGY_CULTURE_EXECUTION_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_CULTURE_EXECUTION_RECOVERY', 'Call Lua Function', 'ASAI_IsCultureExecutionRecovery', 0, 0),
    ('ASAI_STRATEGY_EMPIRE_EXECUTION_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_EMPIRE_EXECUTION_RECOVERY', 'Call Lua Function', 'ASAI_IsEmpireExecutionRecovery', 0, 0),
    ('ASAI_STRATEGY_EXPANSION_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_EXPANSION_RECOVERY', 'Call Lua Function', 'ASAI_IsExpansionRecovery', 0, 0);

INSERT OR IGNORE INTO AiListTypes (ListType) VALUES
    ('ASAI_OpeningPseudoYields'),
    ('ASAI_OpeningUnits'),
    ('ASAI_OpeningYields'),
    ('ASAI_InfraPseudoYields'),
    ('ASAI_InfraUnits'),
    ('ASAI_InfraYields'),
    ('ASAI_TradePseudoYields'),
    ('ASAI_TradeUnits'),
    ('ASAI_TradeYields'),
    ('ASAI_TradeCapacityDistricts'),
    ('ASAI_TradeCapacityBuildings'),
    ('ASAI_TradeCapacityYields'),
    ('ASAI_BuilderBudgetPseudoYields'),
    ('ASAI_BuilderBudgetUnits'),
    ('ASAI_TraderBudgetPseudoYields'),
    ('ASAI_TraderBudgetUnits'),
    ('ASAI_SettlerBudgetPseudoYields'),
    ('ASAI_SettlerBudgetUnits'),
    ('ASAI_GoldPseudoYields'),
    ('ASAI_GoldDistricts'),
    ('ASAI_GoldBuildings'),
    ('ASAI_GoldYields'),
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
    ('ASAI_RelativeCatchupYields'),
    ('ASAI_RelativeCatchupDistricts'),
    ('ASAI_RelativeSeverePseudoYields'),
    ('ASAI_RelativeSevereYields'),
    ('ASAI_RelativeSevereDistricts'),
    ('ASAI_RelativeLeadPseudoYields'),
    ('ASAI_RelativeLeadYields'),
    ('ASAI_ScienceRecoveryDistricts'),
    ('ASAI_ScienceRecoveryBuildings'),
    ('ASAI_ScienceRecoveryYields'),
    ('ASAI_CultureRecoveryPseudoYields'),
    ('ASAI_CultureRecoveryDistricts'),
    ('ASAI_CultureRecoveryBuildings'),
    ('ASAI_CultureRecoveryYields'),
    ('ASAI_EmpireRecoveryYields'),
    ('ASAI_ScienceExecutionDistricts'),
    ('ASAI_ScienceExecutionBuildings'),
    ('ASAI_ScienceExecutionYields'),
    ('ASAI_CultureExecutionDistricts'),
    ('ASAI_CultureExecutionBuildings'),
    ('ASAI_CultureExecutionYields'),
    ('ASAI_EmpireExecutionPseudoYields'),
    ('ASAI_EmpireExecutionUnits'),
    ('ASAI_EmpireExecutionBuildings'),
    ('ASAI_EmpireExecutionYields'),
    ('ASAI_ExpansionRecoveryPseudoYields'),
    ('ASAI_ExpansionRecoveryUnits');

INSERT OR IGNORE INTO AiLists (ListType, System) VALUES
    ('ASAI_OpeningPseudoYields', 'PseudoYields'),
    ('ASAI_OpeningUnits', 'Units'),
    ('ASAI_OpeningYields', 'Yields'),
    ('ASAI_InfraPseudoYields', 'PseudoYields'),
    ('ASAI_InfraUnits', 'Units'),
    ('ASAI_InfraYields', 'Yields'),
    ('ASAI_TradePseudoYields', 'PseudoYields'),
    ('ASAI_TradeUnits', 'Units'),
    ('ASAI_TradeYields', 'Yields'),
    ('ASAI_TradeCapacityDistricts', 'Districts'),
    ('ASAI_TradeCapacityBuildings', 'Buildings'),
    ('ASAI_TradeCapacityYields', 'Yields'),
    ('ASAI_BuilderBudgetPseudoYields', 'PseudoYields'),
    ('ASAI_BuilderBudgetUnits', 'Units'),
    ('ASAI_TraderBudgetPseudoYields', 'PseudoYields'),
    ('ASAI_TraderBudgetUnits', 'Units'),
    ('ASAI_SettlerBudgetPseudoYields', 'PseudoYields'),
    ('ASAI_SettlerBudgetUnits', 'Units'),
    ('ASAI_GoldPseudoYields', 'PseudoYields'),
    ('ASAI_GoldDistricts', 'Districts'),
    ('ASAI_GoldBuildings', 'Buildings'),
    ('ASAI_GoldYields', 'Yields'),
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
    ('ASAI_RelativeCatchupYields', 'Yields'),
    ('ASAI_RelativeCatchupDistricts', 'Districts'),
    ('ASAI_RelativeSeverePseudoYields', 'PseudoYields'),
    ('ASAI_RelativeSevereYields', 'Yields'),
    ('ASAI_RelativeSevereDistricts', 'Districts'),
    ('ASAI_RelativeLeadPseudoYields', 'PseudoYields'),
    ('ASAI_RelativeLeadYields', 'Yields'),
    ('ASAI_ScienceRecoveryDistricts', 'Districts'),
    ('ASAI_ScienceRecoveryBuildings', 'Buildings'),
    ('ASAI_ScienceRecoveryYields', 'Yields'),
    ('ASAI_CultureRecoveryPseudoYields', 'PseudoYields'),
    ('ASAI_CultureRecoveryDistricts', 'Districts'),
    ('ASAI_CultureRecoveryBuildings', 'Buildings'),
    ('ASAI_CultureRecoveryYields', 'Yields'),
    ('ASAI_EmpireRecoveryYields', 'Yields'),
    ('ASAI_ScienceExecutionDistricts', 'Districts'),
    ('ASAI_ScienceExecutionBuildings', 'Buildings'),
    ('ASAI_ScienceExecutionYields', 'Yields'),
    ('ASAI_CultureExecutionDistricts', 'Districts'),
    ('ASAI_CultureExecutionBuildings', 'Buildings'),
    ('ASAI_CultureExecutionYields', 'Yields'),
    ('ASAI_EmpireExecutionPseudoYields', 'PseudoYields'),
    ('ASAI_EmpireExecutionUnits', 'Units'),
    ('ASAI_EmpireExecutionBuildings', 'Buildings'),
    ('ASAI_EmpireExecutionYields', 'Yields'),
    ('ASAI_ExpansionRecoveryPseudoYields', 'PseudoYields'),
    ('ASAI_ExpansionRecoveryUnits', 'Units');

INSERT OR IGNORE INTO Strategy_Priorities (StrategyType, ListType) VALUES
    ('ASAI_STRATEGY_OPENING_EXPANSION', 'ASAI_OpeningPseudoYields'),
    ('ASAI_STRATEGY_OPENING_EXPANSION', 'ASAI_OpeningUnits'),
    ('ASAI_STRATEGY_OPENING_EXPANSION', 'ASAI_OpeningYields'),
    ('ASAI_STRATEGY_INFRA_RECOVERY', 'ASAI_InfraPseudoYields'),
    ('ASAI_STRATEGY_INFRA_RECOVERY', 'ASAI_InfraUnits'),
    ('ASAI_STRATEGY_INFRA_RECOVERY', 'ASAI_InfraYields'),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 'ASAI_TradePseudoYields'),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 'ASAI_TradeUnits'),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 'ASAI_TradeYields'),
    ('ASAI_STRATEGY_TRADE_CAPACITY_RECOVERY', 'ASAI_TradeCapacityDistricts'),
    ('ASAI_STRATEGY_TRADE_CAPACITY_RECOVERY', 'ASAI_TradeCapacityBuildings'),
    ('ASAI_STRATEGY_TRADE_CAPACITY_RECOVERY', 'ASAI_TradeCapacityYields'),
    ('ASAI_STRATEGY_BUILDER_BUDGET', 'ASAI_BuilderBudgetPseudoYields'),
    ('ASAI_STRATEGY_BUILDER_BUDGET', 'ASAI_BuilderBudgetUnits'),
    ('ASAI_STRATEGY_TRADER_BUDGET', 'ASAI_TraderBudgetPseudoYields'),
    ('ASAI_STRATEGY_TRADER_BUDGET', 'ASAI_TraderBudgetUnits'),
    ('ASAI_STRATEGY_SETTLER_BUDGET', 'ASAI_SettlerBudgetPseudoYields'),
    ('ASAI_STRATEGY_SETTLER_BUDGET', 'ASAI_SettlerBudgetUnits'),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'ASAI_GoldPseudoYields'),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'ASAI_GoldDistricts'),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'ASAI_GoldBuildings'),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'ASAI_GoldYields'),
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
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 'ASAI_RelativeCatchupYields'),
    ('ASAI_STRATEGY_RELATIVE_CATCHUP', 'ASAI_RelativeCatchupDistricts'),
    ('ASAI_STRATEGY_RELATIVE_SEVERE_CATCHUP', 'ASAI_RelativeSeverePseudoYields'),
    ('ASAI_STRATEGY_RELATIVE_SEVERE_CATCHUP', 'ASAI_RelativeSevereYields'),
    ('ASAI_STRATEGY_RELATIVE_SEVERE_CATCHUP', 'ASAI_RelativeSevereDistricts'),
    ('ASAI_STRATEGY_RELATIVE_CONSOLIDATE', 'ASAI_RelativeLeadPseudoYields'),
    ('ASAI_STRATEGY_RELATIVE_CONSOLIDATE', 'ASAI_RelativeLeadYields'),
    ('ASAI_STRATEGY_SCIENCE_RECOVERY', 'ASAI_ScienceRecoveryDistricts'),
    ('ASAI_STRATEGY_SCIENCE_RECOVERY', 'ASAI_ScienceRecoveryBuildings'),
    ('ASAI_STRATEGY_SCIENCE_RECOVERY', 'ASAI_ScienceRecoveryYields'),
    ('ASAI_STRATEGY_CULTURE_RECOVERY', 'ASAI_CultureRecoveryPseudoYields'),
    ('ASAI_STRATEGY_CULTURE_RECOVERY', 'ASAI_CultureRecoveryDistricts'),
    ('ASAI_STRATEGY_CULTURE_RECOVERY', 'ASAI_CultureRecoveryBuildings'),
    ('ASAI_STRATEGY_CULTURE_RECOVERY', 'ASAI_CultureRecoveryYields'),
    ('ASAI_STRATEGY_EMPIRE_RECOVERY', 'ASAI_EmpireRecoveryYields'),
    ('ASAI_STRATEGY_SCIENCE_EXECUTION_RECOVERY', 'ASAI_ScienceExecutionDistricts'),
    ('ASAI_STRATEGY_SCIENCE_EXECUTION_RECOVERY', 'ASAI_ScienceExecutionBuildings'),
    ('ASAI_STRATEGY_SCIENCE_EXECUTION_RECOVERY', 'ASAI_ScienceExecutionYields'),
    ('ASAI_STRATEGY_CULTURE_EXECUTION_RECOVERY', 'ASAI_CultureExecutionDistricts'),
    ('ASAI_STRATEGY_CULTURE_EXECUTION_RECOVERY', 'ASAI_CultureExecutionBuildings'),
    ('ASAI_STRATEGY_CULTURE_EXECUTION_RECOVERY', 'ASAI_CultureExecutionYields'),
    ('ASAI_STRATEGY_EMPIRE_EXECUTION_RECOVERY', 'ASAI_EmpireExecutionPseudoYields'),
    ('ASAI_STRATEGY_EMPIRE_EXECUTION_RECOVERY', 'ASAI_EmpireExecutionUnits'),
    ('ASAI_STRATEGY_EMPIRE_EXECUTION_RECOVERY', 'ASAI_EmpireExecutionBuildings'),
    ('ASAI_STRATEGY_EMPIRE_EXECUTION_RECOVERY', 'ASAI_EmpireExecutionYields'),
    ('ASAI_STRATEGY_EXPANSION_RECOVERY', 'ASAI_ExpansionRecoveryPseudoYields'),
    ('ASAI_STRATEGY_EXPANSION_RECOVERY', 'ASAI_ExpansionRecoveryUnits');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
VALUES
    ('ASAI_OpeningPseudoYields', 'PSEUDOYIELD_WONDER', 1, -35),
    ('ASAI_OpeningPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, 25),
    ('ASAI_OpeningUnits', 'UNIT_SETTLER', 1, 20),
    ('ASAI_OpeningYields', 'YIELD_PRODUCTION', 1, 8),
    ('ASAI_InfraPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 55),
    ('ASAI_InfraUnits', 'UNIT_BUILDER', 1, 35),
    ('ASAI_InfraYields', 'YIELD_PRODUCTION', 1, 10),
    ('ASAI_TradePseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 100),
    ('ASAI_TradeUnits', 'UNIT_TRADER', 1, 50),
    ('ASAI_TradeYields', 'YIELD_GOLD', 1, 15),
    ('ASAI_TradeCapacityDistricts', 'DISTRICT_COMMERCIAL_HUB', 1, 55),
    ('ASAI_TradeCapacityDistricts', 'DISTRICT_HARBOR', 1, 55),
    ('ASAI_TradeCapacityYields', 'YIELD_PRODUCTION', 1, 12),
    ('ASAI_TradeCapacityYields', 'YIELD_GOLD', 1, 10),
    ('ASAI_BuilderBudgetPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -25),
    ('ASAI_BuilderBudgetUnits', 'UNIT_BUILDER', 1, -50),
    ('ASAI_TraderBudgetPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, -35),
    ('ASAI_TraderBudgetUnits', 'UNIT_TRADER', 1, -50),
    ('ASAI_SettlerBudgetPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -45),
    ('ASAI_SettlerBudgetUnits', 'UNIT_SETTLER', 1, -50),
    ('ASAI_GoldPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 60),
    ('ASAI_GoldDistricts', 'DISTRICT_COMMERCIAL_HUB', 1, 30),
    ('ASAI_GoldDistricts', 'DISTRICT_HARBOR', 1, 30),
    ('ASAI_GoldYields', 'YIELD_GOLD', 1, 60),
    ('ASAI_GoldYields', 'YIELD_PRODUCTION', 1, 10),
    ('ASAI_WarPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 45),
    ('ASAI_WarPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 25),
    ('ASAI_WarPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 40),
    ('ASAI_WarPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -35),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_MELEE', 1, 10),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_RANGED', 1, 25),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, 50),
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
    ('ASAI_RelativeCatchupPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 12),
    ('ASAI_RelativeCatchupPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 12),
    ('ASAI_RelativeCatchupPseudoYields', 'PSEUDOYIELD_WONDER', 1, -20),
    ('ASAI_RelativeCatchupPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 4),
    ('ASAI_RelativeCatchupYields', 'YIELD_PRODUCTION', 1, 8),
    ('ASAI_RelativeCatchupYields', 'YIELD_SCIENCE', 1, 8),
    ('ASAI_RelativeCatchupYields', 'YIELD_CULTURE', 1, 8),
    ('ASAI_RelativeCatchupYields', 'YIELD_GOLD', 1, 4),
    ('ASAI_RelativeCatchupDistricts', 'DISTRICT_CAMPUS', 1, 8),
    ('ASAI_RelativeCatchupDistricts', 'DISTRICT_THEATER', 1, 8),
    ('ASAI_RelativeCatchupDistricts', 'DISTRICT_INDUSTRIAL_ZONE', 1, 7),
    ('ASAI_RelativeCatchupDistricts', 'DISTRICT_COMMERCIAL_HUB', 1, 5),
    ('ASAI_RelativeCatchupDistricts', 'DISTRICT_HARBOR', 1, 5),
    ('ASAI_RelativeSeverePseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 10),
    ('ASAI_RelativeSeverePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 18),
    ('ASAI_RelativeSeverePseudoYields', 'PSEUDOYIELD_WONDER', 1, -30),
    ('ASAI_RelativeSeverePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 6),
    ('ASAI_RelativeSevereYields', 'YIELD_PRODUCTION', 1, 16),
    ('ASAI_RelativeSevereYields', 'YIELD_SCIENCE', 1, 12),
    ('ASAI_RelativeSevereYields', 'YIELD_CULTURE', 1, 12),
    ('ASAI_RelativeSevereYields', 'YIELD_GOLD', 1, 8),
    ('ASAI_RelativeSevereDistricts', 'DISTRICT_CAMPUS', 1, 16),
    ('ASAI_RelativeSevereDistricts', 'DISTRICT_THEATER', 1, 16),
    ('ASAI_RelativeSevereDistricts', 'DISTRICT_INDUSTRIAL_ZONE', 1, 18),
    ('ASAI_RelativeSevereDistricts', 'DISTRICT_COMMERCIAL_HUB', 1, 8),
    ('ASAI_RelativeSevereDistricts', 'DISTRICT_HARBOR', 1, 8),
    ('ASAI_RelativeLeadPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 4),
    ('ASAI_RelativeLeadYields', 'YIELD_GOLD', 1, 3),
    ('ASAI_ScienceRecoveryDistricts', 'DISTRICT_CAMPUS', 1, 50),
    ('ASAI_ScienceRecoveryYields', 'YIELD_SCIENCE', 1, 32),
    ('ASAI_ScienceRecoveryYields', 'YIELD_PRODUCTION', 1, 12),
    ('ASAI_CultureRecoveryPseudoYields', 'PSEUDOYIELD_GPP_WRITER', 1, 15),
    ('ASAI_CultureRecoveryPseudoYields', 'PSEUDOYIELD_GPP_ARTIST', 1, 15),
    ('ASAI_CultureRecoveryPseudoYields', 'PSEUDOYIELD_GPP_MUSICIAN', 1, 15),
    ('ASAI_CultureRecoveryDistricts', 'DISTRICT_THEATER', 1, 55),
    ('ASAI_CultureRecoveryYields', 'YIELD_CULTURE', 1, 34),
    ('ASAI_CultureRecoveryYields', 'YIELD_PRODUCTION', 1, 12),
    ('ASAI_EmpireRecoveryYields', 'YIELD_FOOD', 1, 16),
    ('ASAI_EmpireRecoveryYields', 'YIELD_PRODUCTION', 1, 10),
    ('ASAI_ScienceExecutionDistricts', 'DISTRICT_CAMPUS', 1, 75),
    ('ASAI_ScienceExecutionYields', 'YIELD_SCIENCE', 1, 40),
    ('ASAI_ScienceExecutionYields', 'YIELD_PRODUCTION', 1, 15),
    ('ASAI_CultureExecutionDistricts', 'DISTRICT_THEATER', 1, 80),
    ('ASAI_CultureExecutionYields', 'YIELD_CULTURE', 1, 44),
    ('ASAI_CultureExecutionYields', 'YIELD_PRODUCTION', 1, 15),
    ('ASAI_EmpireExecutionPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, 45),
    ('ASAI_EmpireExecutionPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 25),
    ('ASAI_EmpireExecutionPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 20),
    ('ASAI_EmpireExecutionUnits', 'UNIT_SETTLER', 1, 35),
    ('ASAI_EmpireExecutionUnits', 'UNIT_BUILDER', 1, 25),
    ('ASAI_EmpireExecutionUnits', 'UNIT_TRADER', 1, 20),
    ('ASAI_EmpireExecutionYields', 'YIELD_FOOD', 1, 24),
    ('ASAI_EmpireExecutionYields', 'YIELD_PRODUCTION', 1, 15),
    ('ASAI_ExpansionRecoveryPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, 25),
    ('ASAI_ExpansionRecoveryUnits', 'UNIT_SETTLER', 1, 20);

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

-- Civilization-unique districts must receive the same recovery signal as the
-- base district they replace. Otherwise a leader's unique kit can silently
-- bypass the adaptive controller.
INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_TradeCapacityDistricts', CivUniqueDistrictType, 1, 55
FROM DistrictReplaces
WHERE ReplacesDistrictType IN ('DISTRICT_COMMERCIAL_HUB', 'DISTRICT_HARBOR');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_RelativeCatchupDistricts', CivUniqueDistrictType, 1,
    CASE ReplacesDistrictType
        WHEN 'DISTRICT_CAMPUS' THEN 8
        WHEN 'DISTRICT_THEATER' THEN 8
        WHEN 'DISTRICT_INDUSTRIAL_ZONE' THEN 7
        ELSE 5
    END
FROM DistrictReplaces
WHERE ReplacesDistrictType IN
    ('DISTRICT_CAMPUS', 'DISTRICT_THEATER', 'DISTRICT_INDUSTRIAL_ZONE',
     'DISTRICT_COMMERCIAL_HUB', 'DISTRICT_HARBOR');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_RelativeSevereDistricts', CivUniqueDistrictType, 1,
    CASE ReplacesDistrictType
        WHEN 'DISTRICT_CAMPUS' THEN 16
        WHEN 'DISTRICT_THEATER' THEN 16
        WHEN 'DISTRICT_INDUSTRIAL_ZONE' THEN 18
        ELSE 8
    END
FROM DistrictReplaces
WHERE ReplacesDistrictType IN
    ('DISTRICT_CAMPUS', 'DISTRICT_THEATER', 'DISTRICT_INDUSTRIAL_ZONE',
     'DISTRICT_COMMERCIAL_HUB', 'DISTRICT_HARBOR');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ScienceRecoveryDistricts', CivUniqueDistrictType, 1, 50
FROM DistrictReplaces
WHERE ReplacesDistrictType = 'DISTRICT_CAMPUS';

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ScienceExecutionDistricts', CivUniqueDistrictType, 1, 75
FROM DistrictReplaces
WHERE ReplacesDistrictType = 'DISTRICT_CAMPUS';

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_CultureRecoveryDistricts', CivUniqueDistrictType, 1, 55
FROM DistrictReplaces
WHERE ReplacesDistrictType = 'DISTRICT_THEATER';

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_CultureExecutionDistricts', CivUniqueDistrictType, 1, 80
FROM DistrictReplaces
WHERE ReplacesDistrictType = 'DISTRICT_THEATER';

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_TradeCapacityBuildings', BuildingType, 1, 90
FROM Buildings
WHERE BuildingType IN ('BUILDING_MARKET', 'BUILDING_LIGHTHOUSE')
   OR BuildingType IN (
        SELECT CivUniqueBuildingType
        FROM BuildingReplaces
        WHERE ReplacesBuildingType IN ('BUILDING_MARKET', 'BUILDING_LIGHTHOUSE')
   );

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ScienceRecoveryBuildings', BuildingType, 1, 40
FROM Buildings
WHERE PrereqDistrict = 'DISTRICT_CAMPUS'
  AND COALESCE(IsWonder, 0) = 0;

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ScienceExecutionBuildings', BuildingType, 1, 65
FROM Buildings
WHERE PrereqDistrict = 'DISTRICT_CAMPUS'
  AND COALESCE(IsWonder, 0) = 0;

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_CultureRecoveryBuildings', BuildingType, 1, 40
FROM Buildings
WHERE PrereqDistrict = 'DISTRICT_THEATER'
  AND COALESCE(IsWonder, 0) = 0;

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_CultureRecoveryBuildings', BuildingType, 1, 55
FROM Buildings
WHERE BuildingType = 'BUILDING_MONUMENT'
   OR BuildingType IN (
        SELECT CivUniqueBuildingType
        FROM BuildingReplaces
        WHERE ReplacesBuildingType = 'BUILDING_MONUMENT'
   );

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_CultureExecutionBuildings', BuildingType, 1, 65
FROM Buildings
WHERE PrereqDistrict = 'DISTRICT_THEATER'
  AND COALESCE(IsWonder, 0) = 0;

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_CultureExecutionBuildings', BuildingType, 1, 80
FROM Buildings
WHERE BuildingType = 'BUILDING_MONUMENT'
   OR BuildingType IN (
        SELECT CivUniqueBuildingType
        FROM BuildingReplaces
        WHERE ReplacesBuildingType = 'BUILDING_MONUMENT'
   );

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_EmpireExecutionBuildings', BuildingType, 1,
    CASE
        WHEN BuildingType = 'BUILDING_GRANARY' THEN 60
        WHEN BuildingType = 'BUILDING_WATER_MILL' THEN 40
        WHEN BuildingType IN (
            SELECT CivUniqueBuildingType
            FROM BuildingReplaces
            WHERE ReplacesBuildingType = 'BUILDING_GRANARY'
        ) THEN 60
        ELSE 40
    END
FROM Buildings
WHERE BuildingType IN ('BUILDING_GRANARY', 'BUILDING_WATER_MILL')
   OR BuildingType IN (
        SELECT CivUniqueBuildingType
        FROM BuildingReplaces
        WHERE ReplacesBuildingType IN ('BUILDING_GRANARY', 'BUILDING_WATER_MILL')
   );

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_WarWonders', BuildingType, 1, -35
FROM Buildings
WHERE IsWonder = 1;
