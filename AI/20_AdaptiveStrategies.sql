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
    ('ASAI_STRATEGY_DEVELOPMENT', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_INFRA_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_TRADE_CAPACITY_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_BUILDER_BUDGET', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_TRADER_BUDGET', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_SETTLER_BUDGET', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_MILITARY_READINESS', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_MILITARY_DOMINANCE', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_MILITARY_EXECUTION_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_HIGH_TECH_DEFENSE', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_SCALE_RECOVERY', 'KIND_VICTORY_STRATEGY'),
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
    ('ASAI_STRATEGY_EXPANSION_RECOVERY', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_SCIENCE_MOON_EXECUTION', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_SCIENCE_MARS_EXECUTION', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_SCIENCE_EXOPLANET_EXECUTION', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_SCIENCE_LASER_EXECUTION', 'KIND_VICTORY_STRATEGY'),
    ('ASAI_STRATEGY_SCIENCE_SPACEPORT_SCALE', 'KIND_VICTORY_STRATEGY');

INSERT OR IGNORE INTO Strategies
    (StrategyType, NumConditionsNeeded)
VALUES
    ('ASAI_STRATEGY_OPENING_EXPANSION', 1),
    ('ASAI_STRATEGY_DEVELOPMENT', 1),
    ('ASAI_STRATEGY_INFRA_RECOVERY', 1),
    ('ASAI_STRATEGY_TRADE_RECOVERY', 1),
    ('ASAI_STRATEGY_TRADE_CAPACITY_RECOVERY', 1),
    ('ASAI_STRATEGY_BUILDER_BUDGET', 1),
    ('ASAI_STRATEGY_TRADER_BUDGET', 1),
    ('ASAI_STRATEGY_SETTLER_BUDGET', 1),
    ('ASAI_STRATEGY_GOLD_RECOVERY', 1),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 1),
    ('ASAI_STRATEGY_MILITARY_READINESS', 1),
    ('ASAI_STRATEGY_MILITARY_DOMINANCE', 1),
    ('ASAI_STRATEGY_MILITARY_EXECUTION_RECOVERY', 1),
    ('ASAI_STRATEGY_HIGH_TECH_DEFENSE', 1),
    ('ASAI_STRATEGY_SCALE_RECOVERY', 1),
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
    ('ASAI_STRATEGY_EXPANSION_RECOVERY', 1),
    ('ASAI_STRATEGY_SCIENCE_MOON_EXECUTION', 1),
    ('ASAI_STRATEGY_SCIENCE_MARS_EXECUTION', 1),
    ('ASAI_STRATEGY_SCIENCE_EXOPLANET_EXECUTION', 1),
    ('ASAI_STRATEGY_SCIENCE_LASER_EXECUTION', 1),
    ('ASAI_STRATEGY_SCIENCE_SPACEPORT_SCALE', 1);

INSERT OR IGNORE INTO StrategyConditions
    (StrategyType, ConditionFunction, StringValue, ThresholdValue, Disqualifier)
VALUES
    ('ASAI_STRATEGY_OPENING_EXPANSION', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_OPENING_EXPANSION', 'Call Lua Function', 'ASAI_IsOpeningExpansion', 0, 0),
    ('ASAI_STRATEGY_DEVELOPMENT', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_DEVELOPMENT', 'Call Lua Function', 'ASAI_IsDevelopmentPlan', 0, 0),
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
    ('ASAI_STRATEGY_MILITARY_READINESS', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_MILITARY_READINESS', 'Call Lua Function', 'ASAI_IsMilitaryReadiness', 0, 0),
    ('ASAI_STRATEGY_MILITARY_DOMINANCE', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_MILITARY_DOMINANCE', 'Call Lua Function', 'ASAI_IsMilitaryDominance', 0, 0),
    ('ASAI_STRATEGY_MILITARY_EXECUTION_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_MILITARY_EXECUTION_RECOVERY', 'Call Lua Function', 'ASAI_IsMilitaryExecutionRecovery', 0, 0),
    ('ASAI_STRATEGY_HIGH_TECH_DEFENSE', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_HIGH_TECH_DEFENSE', 'Call Lua Function', 'ASAI_IsHighTechDefense', 0, 0),
    ('ASAI_STRATEGY_SCALE_RECOVERY', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_SCALE_RECOVERY', 'Call Lua Function', 'ASAI_IsScaleRecovery', 0, 0),
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
    ('ASAI_STRATEGY_EXPANSION_RECOVERY', 'Call Lua Function', 'ASAI_IsExpansionRecovery', 0, 0),
    ('ASAI_STRATEGY_SCIENCE_MOON_EXECUTION', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_SCIENCE_MOON_EXECUTION', 'Call Lua Function', 'ASAI_IsScienceMoonExecution', 0, 0),
    ('ASAI_STRATEGY_SCIENCE_MARS_EXECUTION', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_SCIENCE_MARS_EXECUTION', 'Call Lua Function', 'ASAI_IsScienceMarsExecution', 0, 0),
    ('ASAI_STRATEGY_SCIENCE_EXOPLANET_EXECUTION', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_SCIENCE_EXOPLANET_EXECUTION', 'Call Lua Function', 'ASAI_IsScienceExoplanetExecution', 0, 0),
    ('ASAI_STRATEGY_SCIENCE_LASER_EXECUTION', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_SCIENCE_LASER_EXECUTION', 'Call Lua Function', 'ASAI_IsScienceLaserExecution', 0, 0),
    ('ASAI_STRATEGY_SCIENCE_SPACEPORT_SCALE', 'Is Not Major', NULL, 0, 1),
    ('ASAI_STRATEGY_SCIENCE_SPACEPORT_SCALE', 'Call Lua Function', 'ASAI_IsScienceSpaceportScale', 0, 0);

INSERT OR IGNORE INTO AiListTypes (ListType) VALUES
    ('ASAI_OpeningPseudoYields'),
    ('ASAI_OpeningUnits'),
    ('ASAI_OpeningYields'),
    ('ASAI_DevelopmentPseudoYields'),
    ('ASAI_DevelopmentDistricts'),
    ('ASAI_DevelopmentYields'),
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
    ('ASAI_WarDistricts'),
    ('ASAI_WarBuildings'),
    ('ASAI_WarWonders'),
    ('ASAI_MilitaryReadinessPseudoYields'),
    ('ASAI_MilitaryReadinessUnitBuilds'),
    ('ASAI_MilitaryReadinessYields'),
    ('ASAI_MilitaryReadinessDistricts'),
    ('ASAI_MilitaryReadinessBuildings'),
    ('ASAI_MilitaryDominancePseudoYields'),
    ('ASAI_MilitaryDominanceOperations'),
    ('ASAI_MilitaryDominanceDiplomacy'),
    ('ASAI_MilitaryExecutionPseudoYields'),
    ('ASAI_MilitaryExecutionUnitBuilds'),
    ('ASAI_MilitaryExecutionYields'),
    ('ASAI_HighTechDefensePseudoYields'),
    ('ASAI_HighTechDefenseUnitBuilds'),
    ('ASAI_HighTechDefenseUnits'),
    ('ASAI_HighTechDefenseTechs'),
    ('ASAI_HighTechDefenseDistricts'),
    ('ASAI_HighTechDefenseYields'),
    ('ASAI_ScaleRecoveryPseudoYields'),
    ('ASAI_ScaleRecoveryYields'),
    ('ASAI_ScaleRecoveryDistricts'),
    ('ASAI_ScaleRecoveryBuildings'),
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
    ('ASAI_ExpansionRecoveryUnits'),
    ('ASAI_ScienceMoonTechs'),
    ('ASAI_ScienceMoonProjects'),
    ('ASAI_ScienceMoonYields'),
    ('ASAI_ScienceMarsTechs'),
    ('ASAI_ScienceMarsProjects'),
    ('ASAI_ScienceMarsYields'),
    ('ASAI_ScienceExoplanetTechs'),
    ('ASAI_ScienceExoplanetProjects'),
    ('ASAI_ScienceExoplanetYields'),
    ('ASAI_ScienceLaserTechs'),
    ('ASAI_ScienceLaserProjects'),
    ('ASAI_ScienceLaserDistricts'),
    ('ASAI_ScienceLaserBuildings'),
    ('ASAI_ScienceLaserYields'),
    ('ASAI_ScienceLaserPseudoYields'),
    ('ASAI_ScienceLaserSuppressedProjects'),
    ('ASAI_ScienceSpaceportDistricts'),
    ('ASAI_ScienceSpaceportYields'),
    ('ASAI_ScienceSpaceportPseudoYields');

INSERT OR IGNORE INTO AiLists (ListType, System) VALUES
    ('ASAI_OpeningPseudoYields', 'PseudoYields'),
    ('ASAI_OpeningUnits', 'Units'),
    ('ASAI_OpeningYields', 'Yields'),
    ('ASAI_DevelopmentPseudoYields', 'PseudoYields'),
    ('ASAI_DevelopmentDistricts', 'Districts'),
    ('ASAI_DevelopmentYields', 'Yields'),
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
    ('ASAI_WarDistricts', 'Districts'),
    ('ASAI_WarBuildings', 'Buildings'),
    ('ASAI_WarWonders', 'Buildings'),
    ('ASAI_MilitaryReadinessPseudoYields', 'PseudoYields'),
    ('ASAI_MilitaryReadinessUnitBuilds', 'UnitPromotionClasses'),
    ('ASAI_MilitaryReadinessYields', 'Yields'),
    ('ASAI_MilitaryReadinessDistricts', 'Districts'),
    ('ASAI_MilitaryReadinessBuildings', 'Buildings'),
    ('ASAI_MilitaryDominancePseudoYields', 'PseudoYields'),
    ('ASAI_MilitaryDominanceOperations', 'AiOperationTypes'),
    ('ASAI_MilitaryDominanceDiplomacy', 'DiplomaticActions'),
    ('ASAI_MilitaryExecutionPseudoYields', 'PseudoYields'),
    ('ASAI_MilitaryExecutionUnitBuilds', 'UnitPromotionClasses'),
    ('ASAI_MilitaryExecutionYields', 'Yields'),
    ('ASAI_HighTechDefensePseudoYields', 'PseudoYields'),
    ('ASAI_HighTechDefenseUnitBuilds', 'UnitPromotionClasses'),
    ('ASAI_HighTechDefenseUnits', 'Units'),
    ('ASAI_HighTechDefenseTechs', 'Technologies'),
    ('ASAI_HighTechDefenseDistricts', 'Districts'),
    ('ASAI_HighTechDefenseYields', 'Yields'),
    ('ASAI_ScaleRecoveryPseudoYields', 'PseudoYields'),
    ('ASAI_ScaleRecoveryYields', 'Yields'),
    ('ASAI_ScaleRecoveryDistricts', 'Districts'),
    ('ASAI_ScaleRecoveryBuildings', 'Buildings'),
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
    ('ASAI_ExpansionRecoveryUnits', 'Units'),
    ('ASAI_ScienceMoonTechs', 'Technologies'),
    ('ASAI_ScienceMoonProjects', 'Projects'),
    ('ASAI_ScienceMoonYields', 'Yields'),
    ('ASAI_ScienceMarsTechs', 'Technologies'),
    ('ASAI_ScienceMarsProjects', 'Projects'),
    ('ASAI_ScienceMarsYields', 'Yields'),
    ('ASAI_ScienceExoplanetTechs', 'Technologies'),
    ('ASAI_ScienceExoplanetProjects', 'Projects'),
    ('ASAI_ScienceExoplanetYields', 'Yields'),
    ('ASAI_ScienceLaserTechs', 'Technologies'),
    ('ASAI_ScienceLaserProjects', 'Projects'),
    ('ASAI_ScienceLaserDistricts', 'Districts'),
    ('ASAI_ScienceLaserBuildings', 'Buildings'),
    ('ASAI_ScienceLaserYields', 'Yields'),
    ('ASAI_ScienceLaserPseudoYields', 'PseudoYields'),
    ('ASAI_ScienceLaserSuppressedProjects', 'Projects'),
    ('ASAI_ScienceSpaceportDistricts', 'Districts'),
    ('ASAI_ScienceSpaceportYields', 'Yields'),
    ('ASAI_ScienceSpaceportPseudoYields', 'PseudoYields');

INSERT OR IGNORE INTO Strategy_Priorities (StrategyType, ListType) VALUES
    ('ASAI_STRATEGY_OPENING_EXPANSION', 'ASAI_OpeningPseudoYields'),
    ('ASAI_STRATEGY_OPENING_EXPANSION', 'ASAI_OpeningUnits'),
    ('ASAI_STRATEGY_OPENING_EXPANSION', 'ASAI_OpeningYields'),
    ('ASAI_STRATEGY_DEVELOPMENT', 'ASAI_DevelopmentPseudoYields'),
    ('ASAI_STRATEGY_DEVELOPMENT', 'ASAI_DevelopmentDistricts'),
    ('ASAI_STRATEGY_DEVELOPMENT', 'ASAI_DevelopmentYields'),
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
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'ASAI_WarDistricts'),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'ASAI_WarBuildings'),
    ('ASAI_STRATEGY_WAR_MOBILIZATION', 'ASAI_WarWonders'),
    ('ASAI_STRATEGY_MILITARY_READINESS', 'ASAI_MilitaryReadinessPseudoYields'),
    ('ASAI_STRATEGY_MILITARY_READINESS', 'ASAI_MilitaryReadinessUnitBuilds'),
    ('ASAI_STRATEGY_MILITARY_READINESS', 'ASAI_MilitaryReadinessYields'),
    ('ASAI_STRATEGY_MILITARY_READINESS', 'ASAI_MilitaryReadinessDistricts'),
    ('ASAI_STRATEGY_MILITARY_READINESS', 'ASAI_MilitaryReadinessBuildings'),
    ('ASAI_STRATEGY_MILITARY_DOMINANCE', 'ASAI_MilitaryDominancePseudoYields'),
    ('ASAI_STRATEGY_MILITARY_DOMINANCE', 'ASAI_MilitaryDominanceOperations'),
    ('ASAI_STRATEGY_MILITARY_DOMINANCE', 'ASAI_MilitaryDominanceDiplomacy'),
    ('ASAI_STRATEGY_MILITARY_EXECUTION_RECOVERY', 'ASAI_MilitaryExecutionPseudoYields'),
    ('ASAI_STRATEGY_MILITARY_EXECUTION_RECOVERY', 'ASAI_MilitaryExecutionUnitBuilds'),
    ('ASAI_STRATEGY_MILITARY_EXECUTION_RECOVERY', 'ASAI_MilitaryExecutionYields'),
    ('ASAI_STRATEGY_HIGH_TECH_DEFENSE', 'ASAI_HighTechDefensePseudoYields'),
    ('ASAI_STRATEGY_HIGH_TECH_DEFENSE', 'ASAI_HighTechDefenseUnitBuilds'),
    ('ASAI_STRATEGY_HIGH_TECH_DEFENSE', 'ASAI_HighTechDefenseUnits'),
    ('ASAI_STRATEGY_HIGH_TECH_DEFENSE', 'ASAI_HighTechDefenseTechs'),
    ('ASAI_STRATEGY_HIGH_TECH_DEFENSE', 'ASAI_HighTechDefenseDistricts'),
    ('ASAI_STRATEGY_HIGH_TECH_DEFENSE', 'ASAI_HighTechDefenseYields'),
    ('ASAI_STRATEGY_SCALE_RECOVERY', 'ASAI_ScaleRecoveryPseudoYields'),
    ('ASAI_STRATEGY_SCALE_RECOVERY', 'ASAI_ScaleRecoveryYields'),
    ('ASAI_STRATEGY_SCALE_RECOVERY', 'ASAI_ScaleRecoveryDistricts'),
    ('ASAI_STRATEGY_SCALE_RECOVERY', 'ASAI_ScaleRecoveryBuildings'),
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
    ('ASAI_STRATEGY_EXPANSION_RECOVERY', 'ASAI_ExpansionRecoveryUnits'),
    ('ASAI_STRATEGY_SCIENCE_MOON_EXECUTION', 'ASAI_ScienceMoonTechs'),
    ('ASAI_STRATEGY_SCIENCE_MOON_EXECUTION', 'ASAI_ScienceMoonProjects'),
    ('ASAI_STRATEGY_SCIENCE_MOON_EXECUTION', 'ASAI_ScienceMoonYields'),
    ('ASAI_STRATEGY_SCIENCE_MARS_EXECUTION', 'ASAI_ScienceMarsTechs'),
    ('ASAI_STRATEGY_SCIENCE_MARS_EXECUTION', 'ASAI_ScienceMarsProjects'),
    ('ASAI_STRATEGY_SCIENCE_MARS_EXECUTION', 'ASAI_ScienceMarsYields'),
    ('ASAI_STRATEGY_SCIENCE_EXOPLANET_EXECUTION', 'ASAI_ScienceExoplanetTechs'),
    ('ASAI_STRATEGY_SCIENCE_EXOPLANET_EXECUTION', 'ASAI_ScienceExoplanetProjects'),
    ('ASAI_STRATEGY_SCIENCE_EXOPLANET_EXECUTION', 'ASAI_ScienceExoplanetYields'),
    ('ASAI_STRATEGY_SCIENCE_LASER_EXECUTION', 'ASAI_ScienceLaserTechs'),
    ('ASAI_STRATEGY_SCIENCE_LASER_EXECUTION', 'ASAI_ScienceLaserProjects'),
    ('ASAI_STRATEGY_SCIENCE_LASER_EXECUTION', 'ASAI_ScienceLaserDistricts'),
    ('ASAI_STRATEGY_SCIENCE_LASER_EXECUTION', 'ASAI_ScienceLaserBuildings'),
    ('ASAI_STRATEGY_SCIENCE_LASER_EXECUTION', 'ASAI_ScienceLaserYields'),
    ('ASAI_STRATEGY_SCIENCE_LASER_EXECUTION', 'ASAI_ScienceLaserPseudoYields'),
    ('ASAI_STRATEGY_SCIENCE_LASER_EXECUTION', 'ASAI_ScienceLaserSuppressedProjects'),
    ('ASAI_STRATEGY_SCIENCE_SPACEPORT_SCALE', 'ASAI_ScienceSpaceportDistricts'),
    ('ASAI_STRATEGY_SCIENCE_SPACEPORT_SCALE', 'ASAI_ScienceSpaceportYields'),
    ('ASAI_STRATEGY_SCIENCE_SPACEPORT_SCALE', 'ASAI_ScienceSpaceportPseudoYields');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
VALUES
    ('ASAI_OpeningPseudoYields', 'PSEUDOYIELD_WONDER', 1, -35),
    ('ASAI_OpeningPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, 25),
    ('ASAI_OpeningUnits', 'UNIT_SETTLER', 1, 20),
    ('ASAI_OpeningYields', 'YIELD_PRODUCTION', 1, 8),
    ('ASAI_DevelopmentPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 18),
    ('ASAI_DevelopmentPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 18),
    ('ASAI_DevelopmentPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 12),
    ('ASAI_DevelopmentDistricts', 'DISTRICT_INDUSTRIAL_ZONE', 1, 25),
    ('ASAI_DevelopmentDistricts', 'DISTRICT_COMMERCIAL_HUB', 1, 18),
    ('ASAI_DevelopmentDistricts', 'DISTRICT_HARBOR', 1, 18),
    ('ASAI_DevelopmentDistricts', 'DISTRICT_CAMPUS', 1, 10),
    ('ASAI_DevelopmentDistricts', 'DISTRICT_THEATER', 1, 10),
    ('ASAI_DevelopmentYields', 'YIELD_PRODUCTION', 1, 12),
    ('ASAI_DevelopmentYields', 'YIELD_GOLD', 1, 8),
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
    ('ASAI_BuilderBudgetPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -40),
    ('ASAI_BuilderBudgetUnits', 'UNIT_BUILDER', 1, -70),
    ('ASAI_TraderBudgetPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, -50),
    ('ASAI_TraderBudgetUnits', 'UNIT_TRADER', 1, -70),
    ('ASAI_SettlerBudgetPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -100),
    ('ASAI_SettlerBudgetUnits', 'UNIT_SETTLER', 1, -120),
    ('ASAI_GoldPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 60),
    ('ASAI_GoldDistricts', 'DISTRICT_COMMERCIAL_HUB', 1, 30),
    ('ASAI_GoldDistricts', 'DISTRICT_HARBOR', 1, 30),
    ('ASAI_GoldYields', 'YIELD_GOLD', 1, 60),
    ('ASAI_GoldYields', 'YIELD_PRODUCTION', 1, 10),
    ('ASAI_WarPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 60),
    ('ASAI_WarPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 30),
    ('ASAI_WarPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 30),
    ('ASAI_WarPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 55),
    ('ASAI_WarPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -65),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_MELEE', 1, 30),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_RANGED', 1, 50),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, 50),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_ANTI_CAVALRY', 1, 40),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_LIGHT_CAVALRY', 1, 25),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_HEAVY_CAVALRY', 1, 25),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_AIR_FIGHTER', 1, 30),
    ('ASAI_WarUnitBuilds', 'PROMOTION_CLASS_AIR_BOMBER', 1, 40),
    ('ASAI_WarYields', 'YIELD_PRODUCTION', 1, 30),
    ('ASAI_WarYields', 'YIELD_GOLD', 1, 15),
    ('ASAI_WarDistricts', 'DISTRICT_ENCAMPMENT', 1, 35),
    ('ASAI_MilitaryReadinessPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 35),
    ('ASAI_MilitaryReadinessPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 35),
    ('ASAI_MilitaryReadinessPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 30),
    ('ASAI_MilitaryReadinessPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -30),
    ('ASAI_MilitaryReadinessPseudoYields', 'PSEUDOYIELD_WONDER', 1, -45),
    ('ASAI_MilitaryReadinessUnitBuilds', 'PROMOTION_CLASS_MELEE', 1, 25),
    ('ASAI_MilitaryReadinessUnitBuilds', 'PROMOTION_CLASS_RANGED', 1, 55),
    ('ASAI_MilitaryReadinessUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, 35),
    ('ASAI_MilitaryReadinessUnitBuilds', 'PROMOTION_CLASS_ANTI_CAVALRY', 1, 35),
    ('ASAI_MilitaryReadinessUnitBuilds', 'PROMOTION_CLASS_LIGHT_CAVALRY', 1, 15),
    ('ASAI_MilitaryReadinessUnitBuilds', 'PROMOTION_CLASS_HEAVY_CAVALRY', 1, 15),
    ('ASAI_MilitaryReadinessUnitBuilds', 'PROMOTION_CLASS_AIR_FIGHTER', 1, 30),
    ('ASAI_MilitaryReadinessUnitBuilds', 'PROMOTION_CLASS_AIR_BOMBER', 1, 35),
    ('ASAI_MilitaryReadinessYields', 'YIELD_PRODUCTION', 1, 18),
    ('ASAI_MilitaryReadinessYields', 'YIELD_GOLD', 1, 10),
    ('ASAI_MilitaryReadinessDistricts', 'DISTRICT_ENCAMPMENT', 1, 30),
    -- A peaceful army already far stronger than the human is a resource to use,
    -- not a reason to keep every marginal production slot in readiness mode.
    ('ASAI_MilitaryDominancePseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 100),
    ('ASAI_MilitaryDominancePseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, -25),
    ('ASAI_MilitaryDominancePseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -25),
    ('ASAI_MilitaryDominancePseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, -50),
    ('ASAI_MilitaryDominancePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, -30),
    ('ASAI_MilitaryDominancePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, -40),
    ('ASAI_MilitaryDominancePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 25),
    ('ASAI_MilitaryDominancePseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 20),
    ('ASAI_MilitaryDominancePseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 15),
    ('ASAI_MilitaryDominanceOperations', 'CITY_ASSAULT', 1, 1),
    ('ASAI_MilitaryDominanceDiplomacy', 'DIPLOACTION_DENOUNCE', 1, 0),
    ('ASAI_MilitaryDominanceDiplomacy', 'DIPLOACTION_DECLARE_FORMAL_WAR', 1, 0),
    ('ASAI_MilitaryDominanceDiplomacy', 'DIPLOACTION_DECLARE_FRIENDSHIP', 0, 0),
    ('ASAI_MilitaryDominanceDiplomacy', 'DIPLOACTION_RENEW_ALLIANCE', 0, 0),
    ('ASAI_MilitaryDominanceDiplomacy', 'DIPLOACTION_ALLIANCE_CULTURAL', 0, 0),
    ('ASAI_MilitaryDominanceDiplomacy', 'DIPLOACTION_ALLIANCE_ECONOMIC', 0, 0),
    ('ASAI_MilitaryDominanceDiplomacy', 'DIPLOACTION_ALLIANCE_MILITARY', 0, 0),
    ('ASAI_MilitaryDominanceDiplomacy', 'DIPLOACTION_ALLIANCE_RELIGIOUS', 0, 0),
    ('ASAI_MilitaryDominanceDiplomacy', 'DIPLOACTION_ALLIANCE_RESEARCH', 0, 0),
    ('ASAI_MilitaryExecutionPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 70),
    ('ASAI_MilitaryExecutionPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 55),
    ('ASAI_MilitaryExecutionPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 55),
    ('ASAI_MilitaryExecutionPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 45),
    ('ASAI_MilitaryExecutionPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -40),
    ('ASAI_MilitaryExecutionUnitBuilds', 'PROMOTION_CLASS_MELEE', 1, 35),
    ('ASAI_MilitaryExecutionUnitBuilds', 'PROMOTION_CLASS_RANGED', 1, 85),
    ('ASAI_MilitaryExecutionUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, 60),
    ('ASAI_MilitaryExecutionUnitBuilds', 'PROMOTION_CLASS_ANTI_CAVALRY', 1, 45),
    ('ASAI_MilitaryExecutionUnitBuilds', 'PROMOTION_CLASS_LIGHT_CAVALRY', 1, 25),
    ('ASAI_MilitaryExecutionUnitBuilds', 'PROMOTION_CLASS_HEAVY_CAVALRY', 1, 25),
    ('ASAI_MilitaryExecutionUnitBuilds', 'PROMOTION_CLASS_AIR_FIGHTER', 1, 60),
    ('ASAI_MilitaryExecutionUnitBuilds', 'PROMOTION_CLASS_AIR_BOMBER', 1, 70),
    ('ASAI_MilitaryExecutionYields', 'YIELD_PRODUCTION', 1, 25),
    ('ASAI_MilitaryExecutionYields', 'YIELD_GOLD', 1, 12),
    -- This response is dormant until recent damage is attributable to nearby
    -- enemy air power or GDRs and the defender lacks enough counters.
    ('ASAI_HighTechDefensePseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 50),
    ('ASAI_HighTechDefensePseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 150),
    ('ASAI_HighTechDefensePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 40),
    ('ASAI_HighTechDefenseUnitBuilds', 'PROMOTION_CLASS_AIR_FIGHTER', 1, 180),
    ('ASAI_HighTechDefenseUnitBuilds', 'PROMOTION_CLASS_AIR_BOMBER', 1, 90),
    ('ASAI_HighTechDefenseUnits', 'UNIT_ANTIAIR_GUN', 1, 160),
    ('ASAI_HighTechDefenseUnits', 'UNIT_MOBILE_SAM', 1, 220),
    ('ASAI_HighTechDefenseUnits', 'UNIT_GIANT_DEATH_ROBOT', 1, 140),
    ('ASAI_HighTechDefenseTechs', 'TECH_ADVANCED_BALLISTICS', 1, 120),
    ('ASAI_HighTechDefenseTechs', 'TECH_GUIDANCE_SYSTEMS', 1, 180),
    ('ASAI_HighTechDefenseTechs', 'TECH_ADVANCED_FLIGHT', 1, 140),
    ('ASAI_HighTechDefenseTechs', 'TECH_LASERS', 1, 180),
    ('ASAI_HighTechDefenseTechs', 'TECH_ROBOTICS', 1, 160),
    ('ASAI_HighTechDefenseDistricts', 'DISTRICT_AERODROME', 1, 100),
    ('ASAI_HighTechDefenseYields', 'YIELD_PRODUCTION', 1, 40),
    ('ASAI_HighTechDefenseYields', 'YIELD_GOLD', 1, 20),
    ('ASAI_LatePseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 75),
    ('ASAI_LatePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 25),
    ('ASAI_LateDistricts', 'DISTRICT_AERODROME', 1, 50),
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
    ('ASAI_RelativeSeverePseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 14),
    ('ASAI_RelativeSeverePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 20),
    ('ASAI_RelativeSeverePseudoYields', 'PSEUDOYIELD_WONDER', 1, -30),
    ('ASAI_RelativeSeverePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 6),
    ('ASAI_RelativeSevereYields', 'YIELD_PRODUCTION', 1, 20),
    ('ASAI_RelativeSevereYields', 'YIELD_SCIENCE', 1, 16),
    ('ASAI_RelativeSevereYields', 'YIELD_CULTURE', 1, 16),
    ('ASAI_RelativeSevereYields', 'YIELD_GOLD', 1, 10),
    ('ASAI_RelativeSevereDistricts', 'DISTRICT_CAMPUS', 1, 20),
    ('ASAI_RelativeSevereDistricts', 'DISTRICT_THEATER', 1, 20),
    ('ASAI_RelativeSevereDistricts', 'DISTRICT_INDUSTRIAL_ZONE', 1, 20),
    ('ASAI_RelativeSevereDistricts', 'DISTRICT_COMMERCIAL_HUB', 1, 12),
    ('ASAI_RelativeSevereDistricts', 'DISTRICT_HARBOR', 1, 12),
    ('ASAI_ScaleRecoveryPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 25),
    ('ASAI_ScaleRecoveryPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 20),
    ('ASAI_ScaleRecoveryPseudoYields', 'PSEUDOYIELD_WONDER', 1, -30),
    ('ASAI_ScaleRecoveryYields', 'YIELD_FOOD', 1, 18),
    ('ASAI_ScaleRecoveryYields', 'YIELD_PRODUCTION', 1, 20),
    ('ASAI_ScaleRecoveryYields', 'YIELD_GOLD', 1, 10),
    ('ASAI_ScaleRecoveryDistricts', 'DISTRICT_INDUSTRIAL_ZONE', 1, 30),
    ('ASAI_ScaleRecoveryDistricts', 'DISTRICT_COMMERCIAL_HUB', 1, 20),
    ('ASAI_ScaleRecoveryDistricts', 'DISTRICT_HARBOR', 1, 20),
    ('ASAI_ScaleRecoveryDistricts', 'DISTRICT_AQUEDUCT', 1, 35),
    ('ASAI_ScaleRecoveryDistricts', 'DISTRICT_NEIGHBORHOOD', 1, 35),
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
    ('ASAI_CultureExecutionDistricts', 'DISTRICT_THEATER', 1, 100),
    ('ASAI_CultureExecutionYields', 'YIELD_CULTURE', 1, 44),
    ('ASAI_CultureExecutionYields', 'YIELD_PRODUCTION', 1, 15),
    ('ASAI_EmpireExecutionPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 25),
    ('ASAI_EmpireExecutionPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 20),
    ('ASAI_EmpireExecutionUnits', 'UNIT_BUILDER', 1, 25),
    ('ASAI_EmpireExecutionUnits', 'UNIT_TRADER', 1, 20),
    ('ASAI_EmpireExecutionYields', 'YIELD_FOOD', 1, 24),
    ('ASAI_EmpireExecutionYields', 'YIELD_PRODUCTION', 1, 15),
    ('ASAI_ExpansionRecoveryPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, 45),
    ('ASAI_ExpansionRecoveryUnits', 'UNIT_SETTLER', 1, 40),
    ('ASAI_ScienceMoonTechs', 'TECH_SATELLITES', 1, 140),
    ('ASAI_ScienceMoonProjects', 'PROJECT_LAUNCH_MOON_LANDING', 1, 220),
    ('ASAI_ScienceMoonYields', 'YIELD_PRODUCTION', 1, 25),
    ('ASAI_ScienceMarsTechs', 'TECH_NANOTECHNOLOGY', 1, 170),
    ('ASAI_ScienceMarsProjects', 'PROJECT_LAUNCH_MARS_BASE', 1, 240),
    ('ASAI_ScienceMarsYields', 'YIELD_PRODUCTION', 1, 30),
    ('ASAI_ScienceExoplanetTechs', 'TECH_SEASTEADS', 1, 70),
    ('ASAI_ScienceExoplanetTechs', 'TECH_ADVANCED_AI', 1, 70),
    ('ASAI_ScienceExoplanetTechs', 'TECH_ADVANCED_POWER_CELLS', 1, 70),
    ('ASAI_ScienceExoplanetTechs', 'TECH_CYBERNETICS', 1, 70),
    ('ASAI_ScienceExoplanetTechs', 'TECH_PREDICTIVE_SYSTEMS', 1, 70),
    ('ASAI_ScienceExoplanetTechs', 'TECH_SMART_MATERIALS', 1, 220),
    ('ASAI_ScienceExoplanetProjects', 'PROJECT_LAUNCH_EXOPLANET_EXPEDITION', 1, 260),
    ('ASAI_ScienceExoplanetYields', 'YIELD_SCIENCE', 1, 20),
    ('ASAI_ScienceExoplanetYields', 'YIELD_PRODUCTION', 1, 35),
    ('ASAI_ScienceLaserTechs', 'TECH_OFFWORLD_MISSION', 1, 240),
    ('ASAI_ScienceLaserProjects', 'PROJECT_ORBITAL_LASER', 1, 500),
    ('ASAI_ScienceLaserProjects', 'PROJECT_TERRESTRIAL_LASER', 1, 500),
    -- Additional ports belong to the bounded scale strategy, not to every
    -- laser-finishing empire regardless of existing port capacity.
    ('ASAI_ScienceLaserDistricts', 'DISTRICT_INDUSTRIAL_ZONE', 1, 50),
    ('ASAI_ScienceLaserYields', 'YIELD_SCIENCE', 1, 20),
    ('ASAI_ScienceLaserYields', 'YIELD_PRODUCTION', 1, 65),
    ('ASAI_ScienceLaserYields', 'YIELD_GOLD', 1, 10),
    ('ASAI_ScienceLaserPseudoYields', 'PSEUDOYIELD_SPACE_RACE', 1, 350),
    ('ASAI_ScienceSpaceportDistricts', 'DISTRICT_SPACEPORT', 1, 160),
    ('ASAI_ScienceSpaceportDistricts', 'DISTRICT_INDUSTRIAL_ZONE', 1, 45),
    ('ASAI_ScienceSpaceportYields', 'YIELD_PRODUCTION', 1, 35),
    ('ASAI_ScienceSpaceportPseudoYields', 'PSEUDOYIELD_SPACE_RACE', 1, 100),
    ('ASAI_ScienceSpaceportPseudoYields', 'PSEUDOYIELD_WONDER', 1, -40);

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ScienceLaserBuildings', BuildingType, 1, 60
FROM Buildings
WHERE BuildingType IN
    ('BUILDING_FACTORY', 'BUILDING_POWER_PLANT', 'BUILDING_COAL_POWER_PLANT',
     'BUILDING_FOSSIL_FUEL_POWER_PLANT');

-- Once the exoplanet expedition is in flight, keep ordinary district work,
-- competitions, aid, and reactor maintenance from displacing laser stations.
-- Defensive repairs and units remain available.
INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ScienceLaserSuppressedProjects', ProjectType, 1, -160
FROM Projects
WHERE ProjectType LIKE 'PROJECT_ENHANCE_DISTRICT_%'
   OR COALESCE(WMD, 0) = 1
   OR ProjectType IN (
        'PROJECT_SEND_AID',
        'PROJECT_TRAIN_ATHLETES',
        'PROJECT_TRAIN_ASTRONAUTS',
        'PROJECT_CARBON_RECAPTURE',
        'PROJECT_RECOMMISSION_REACTOR',
        'PROJECT_CONVERT_REACTOR_TO_COAL',
        'PROJECT_CONVERT_REACTOR_TO_OIL',
        'PROJECT_CONVERT_REACTOR_TO_URANIUM',
        'PROJECT_DECOMMISSION_COAL_POWER_PLANT',
        'PROJECT_DECOMMISSION_OIL_POWER_PLANT',
        'PROJECT_DECOMMISSION_NUCLEAR_POWER_PLANT'
   );

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
SELECT 'ASAI_DevelopmentDistricts', CivUniqueDistrictType, 1,
    CASE ReplacesDistrictType
        WHEN 'DISTRICT_INDUSTRIAL_ZONE' THEN 25
        WHEN 'DISTRICT_COMMERCIAL_HUB' THEN 18
        WHEN 'DISTRICT_HARBOR' THEN 18
        ELSE 10
    END
FROM DistrictReplaces
WHERE ReplacesDistrictType IN
    ('DISTRICT_INDUSTRIAL_ZONE', 'DISTRICT_COMMERCIAL_HUB', 'DISTRICT_HARBOR',
     'DISTRICT_CAMPUS', 'DISTRICT_THEATER');

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
        WHEN 'DISTRICT_CAMPUS' THEN 20
        WHEN 'DISTRICT_THEATER' THEN 20
        WHEN 'DISTRICT_INDUSTRIAL_ZONE' THEN 20
        ELSE 12
    END
FROM DistrictReplaces
WHERE ReplacesDistrictType IN
    ('DISTRICT_CAMPUS', 'DISTRICT_THEATER', 'DISTRICT_INDUSTRIAL_ZONE',
     'DISTRICT_COMMERCIAL_HUB', 'DISTRICT_HARBOR');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ScaleRecoveryDistricts', CivUniqueDistrictType, 1,
    CASE ReplacesDistrictType
        WHEN 'DISTRICT_INDUSTRIAL_ZONE' THEN 30
        WHEN 'DISTRICT_AQUEDUCT' THEN 35
        WHEN 'DISTRICT_NEIGHBORHOOD' THEN 35
        ELSE 20
    END
FROM DistrictReplaces
WHERE ReplacesDistrictType IN
    ('DISTRICT_INDUSTRIAL_ZONE', 'DISTRICT_COMMERCIAL_HUB', 'DISTRICT_HARBOR',
     'DISTRICT_AQUEDUCT', 'DISTRICT_NEIGHBORHOOD');

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
SELECT 'ASAI_CultureExecutionDistricts', CivUniqueDistrictType, 1, 100
FROM DistrictReplaces
WHERE ReplacesDistrictType = 'DISTRICT_THEATER';

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_TradeCapacityBuildings', BuildingType, 1, 120
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
SELECT 'ASAI_CultureExecutionBuildings', BuildingType, 1, 80
FROM Buildings
WHERE PrereqDistrict = 'DISTRICT_THEATER'
  AND COALESCE(IsWonder, 0) = 0;

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_CultureExecutionBuildings', BuildingType, 1, 100
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
        WHEN BuildingType = 'BUILDING_SEWER' THEN 50
        WHEN BuildingType = 'BUILDING_WATER_MILL' THEN 40
        WHEN BuildingType IN (
            SELECT CivUniqueBuildingType
            FROM BuildingReplaces
            WHERE ReplacesBuildingType = 'BUILDING_GRANARY'
        ) THEN 60
        WHEN BuildingType IN (
            SELECT CivUniqueBuildingType
            FROM BuildingReplaces
            WHERE ReplacesBuildingType = 'BUILDING_SEWER'
        ) THEN 50
        ELSE 40
    END
FROM Buildings
WHERE BuildingType IN ('BUILDING_GRANARY', 'BUILDING_WATER_MILL', 'BUILDING_SEWER')
   OR BuildingType IN (
        SELECT CivUniqueBuildingType
        FROM BuildingReplaces
        WHERE ReplacesBuildingType IN
            ('BUILDING_GRANARY', 'BUILDING_WATER_MILL', 'BUILDING_SEWER')
   );

-- Scale recovery converts existing cities into population, production, and
-- trade capacity. It remains independent from the current victory focus.
INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ScaleRecoveryBuildings', BuildingType, 1,
    CASE
        WHEN BuildingType = 'BUILDING_GRANARY' THEN 55
        WHEN BuildingType IN ('BUILDING_MONUMENT', 'BUILDING_WATER_MILL') THEN 45
        WHEN BuildingType = 'BUILDING_SEWER' THEN 35
        WHEN PrereqDistrict = 'DISTRICT_INDUSTRIAL_ZONE' THEN 50
        WHEN BuildingType IN ('BUILDING_MARKET', 'BUILDING_LIGHTHOUSE') THEN 45
        WHEN BuildingType IN ('BUILDING_BANK', 'BUILDING_SHIPYARD') THEN 40
        ELSE 30
    END
FROM Buildings
WHERE COALESCE(IsWonder, 0) = 0
  AND (BuildingType IN
        ('BUILDING_MONUMENT', 'BUILDING_GRANARY', 'BUILDING_WATER_MILL',
         'BUILDING_SEWER', 'BUILDING_MARKET', 'BUILDING_BANK',
         'BUILDING_STOCK_EXCHANGE', 'BUILDING_LIGHTHOUSE',
         'BUILDING_SHIPYARD', 'BUILDING_SEAPORT')
       OR PrereqDistrict = 'DISTRICT_INDUSTRIAL_ZONE');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ScaleRecoveryBuildings', replacements.CivUniqueBuildingType, 1,
    CASE
        WHEN base.BuildingType = 'BUILDING_GRANARY' THEN 55
        WHEN base.BuildingType IN ('BUILDING_MONUMENT', 'BUILDING_WATER_MILL') THEN 45
        WHEN base.BuildingType = 'BUILDING_SEWER' THEN 35
        WHEN base.PrereqDistrict = 'DISTRICT_INDUSTRIAL_ZONE' THEN 50
        WHEN base.BuildingType IN ('BUILDING_MARKET', 'BUILDING_LIGHTHOUSE') THEN 45
        WHEN base.BuildingType IN ('BUILDING_BANK', 'BUILDING_SHIPYARD') THEN 40
        ELSE 30
    END
FROM BuildingReplaces AS replacements
JOIN Buildings AS base
  ON base.BuildingType = replacements.ReplacesBuildingType
WHERE COALESCE(base.IsWonder, 0) = 0
  AND (base.BuildingType IN
        ('BUILDING_MONUMENT', 'BUILDING_GRANARY', 'BUILDING_WATER_MILL',
         'BUILDING_SEWER', 'BUILDING_MARKET', 'BUILDING_BANK',
         'BUILDING_STOCK_EXCHANGE', 'BUILDING_LIGHTHOUSE',
         'BUILDING_SHIPYARD', 'BUILDING_SEAPORT')
       OR base.PrereqDistrict = 'DISTRICT_INDUSTRIAL_ZONE');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_MilitaryReadinessDistricts', CivUniqueDistrictType, 1, 30
FROM DistrictReplaces
WHERE ReplacesDistrictType = 'DISTRICT_ENCAMPMENT';

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_WarDistricts', CivUniqueDistrictType, 1, 35
FROM DistrictReplaces
WHERE ReplacesDistrictType = 'DISTRICT_ENCAMPMENT';

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_MilitaryReadinessBuildings', BuildingType, 1, 35
FROM Buildings
WHERE COALESCE(OuterDefenseHitPoints, 0) > 0
   OR BuildingType IN (
        SELECT CivUniqueBuildingType
        FROM BuildingReplaces
        WHERE ReplacesBuildingType IN
            ('BUILDING_WALLS', 'BUILDING_CASTLE', 'BUILDING_STAR_FORT')
   );

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_WarBuildings', BuildingType, 1, 90
FROM Buildings
WHERE COALESCE(OuterDefenseHitPoints, 0) > 0
   OR BuildingType IN (
        SELECT CivUniqueBuildingType
        FROM BuildingReplaces
        WHERE ReplacesBuildingType IN
            ('BUILDING_WALLS', 'BUILDING_CASTLE', 'BUILDING_STAR_FORT')
   );

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_WarWonders', BuildingType, 1, -60
FROM Buildings
WHERE IsWonder = 1;
