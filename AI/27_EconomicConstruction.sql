-- Conditional native construction requests; no grants or forced city orders.
INSERT OR REPLACE INTO GlobalParameters (Name, Value) VALUES
    ('ASAI_FINANCE_ENTER_STANDARD', 4),
    ('ASAI_FINANCE_EXIT_STANDARD', 6),
    ('ASAI_CULTURE_BUILD_DELAY_STANDARD', 4);

CREATE TEMP TABLE ASAI_EconomicFamilies (StrategyType TEXT, Callback TEXT);
INSERT INTO ASAI_EconomicFamilies VALUES
    ('ASAI_STRATEGY_FINANCE_BUILDING', 'ASAI_IsFinanceBuildingDemand'),
    ('ASAI_STRATEGY_FINANCE_DISTRICT', 'ASAI_IsFinanceDistrictDemand'),
    ('ASAI_STRATEGY_FINANCE_RESTRAINT', 'ASAI_IsFinanceRestraint'),
    ('ASAI_STRATEGY_CULTURE_MONUMENT', 'ASAI_IsCultureMonumentDemand'),
    ('ASAI_STRATEGY_CULTURE_THEATER', 'ASAI_IsCultureTheaterDemand'),
    ('ASAI_STRATEGY_CULTURE_BUILDING', 'ASAI_IsCultureBuildingDemand'),
    ('ASAI_STRATEGY_CULTURE_CIVIC', 'ASAI_IsCultureCivicPrerequisite');
INSERT INTO Types (Type, Kind)
SELECT StrategyType, 'KIND_VICTORY_STRATEGY' FROM ASAI_EconomicFamilies;
INSERT INTO Strategies (StrategyType, NumConditionsNeeded)
SELECT StrategyType, 1 FROM ASAI_EconomicFamilies;
INSERT INTO StrategyConditions
    (StrategyType, ConditionFunction, StringValue, ThresholdValue, Disqualifier)
SELECT StrategyType, 'Call Lua Function', Callback, 0, 0 FROM ASAI_EconomicFamilies;
INSERT INTO StrategyConditions (StrategyType, ConditionFunction, Disqualifier)
SELECT StrategyType, 'Is Not Major', 1 FROM ASAI_EconomicFamilies;
DROP TABLE ASAI_EconomicFamilies;

INSERT INTO AiListTypes (ListType) VALUES
    ('ASAI_FinanceBuildings'), ('ASAI_FinanceDistricts'), ('ASAI_FinanceGold'),
    ('ASAI_FinanceSpecialization'), ('ASAI_FinanceExpensiveUnits'),
    ('ASAI_FinanceMilitarySpecialization'), ('ASAI_CultureMonuments'),
    ('ASAI_CultureTheaters'), ('ASAI_CultureConstructionBuildings'),
    ('ASAI_CultureBuildYield'), ('ASAI_CultureBuildSpecialization'),
    ('ASAI_CulturePrerequisiteCivics');
INSERT INTO AiLists (ListType, System) VALUES
    ('ASAI_FinanceBuildings', 'Buildings'),
    ('ASAI_FinanceDistricts', 'Districts'),
    ('ASAI_FinanceGold', 'Yields'),
    ('ASAI_FinanceSpecialization', 'AiBuildSpecializations'),
    ('ASAI_FinanceExpensiveUnits', 'Units'),
    ('ASAI_FinanceMilitarySpecialization', 'AiBuildSpecializations'),
    ('ASAI_CultureMonuments', 'Buildings'),
    ('ASAI_CultureTheaters', 'Districts'),
    ('ASAI_CultureConstructionBuildings', 'Buildings'),
    ('ASAI_CultureBuildYield', 'Yields'),
    ('ASAI_CultureBuildSpecialization', 'AiBuildSpecializations'),
    ('ASAI_CulturePrerequisiteCivics', 'Civics');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
    ('ASAI_STRATEGY_FINANCE_BUILDING', 'ASAI_FinanceBuildings'),
    ('ASAI_STRATEGY_FINANCE_BUILDING', 'ASAI_FinanceGold'),
    ('ASAI_STRATEGY_FINANCE_BUILDING', 'ASAI_FinanceSpecialization'),
    ('ASAI_STRATEGY_FINANCE_DISTRICT', 'ASAI_FinanceDistricts'),
    ('ASAI_STRATEGY_FINANCE_DISTRICT', 'ASAI_FinanceGold'),
    ('ASAI_STRATEGY_FINANCE_DISTRICT', 'ASAI_FinanceSpecialization'),
    ('ASAI_STRATEGY_FINANCE_RESTRAINT', 'ASAI_FinanceExpensiveUnits'),
    ('ASAI_STRATEGY_FINANCE_RESTRAINT', 'ASAI_FinanceMilitarySpecialization'),
    ('ASAI_STRATEGY_CULTURE_MONUMENT', 'ASAI_CultureMonuments'),
    ('ASAI_STRATEGY_CULTURE_MONUMENT', 'ASAI_CultureBuildYield'),
    ('ASAI_STRATEGY_CULTURE_MONUMENT', 'ASAI_CultureBuildSpecialization'),
    ('ASAI_STRATEGY_CULTURE_THEATER', 'ASAI_CultureTheaters'),
    ('ASAI_STRATEGY_CULTURE_THEATER', 'ASAI_CultureBuildYield'),
    ('ASAI_STRATEGY_CULTURE_THEATER', 'ASAI_CultureBuildSpecialization'),
    ('ASAI_STRATEGY_CULTURE_BUILDING', 'ASAI_CultureConstructionBuildings'),
    ('ASAI_STRATEGY_CULTURE_BUILDING', 'ASAI_CultureBuildYield'),
    ('ASAI_STRATEGY_CULTURE_BUILDING', 'ASAI_CultureBuildSpecialization'),
    ('ASAI_STRATEGY_CULTURE_CIVIC', 'ASAI_CulturePrerequisiteCivics');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_FinanceBuildings', BuildingType, 1, 260 FROM Buildings
WHERE BuildingType IN ('BUILDING_MARKET', 'BUILDING_LIGHTHOUSE', 'BUILDING_BANK', 'BUILDING_STOCK_EXCHANGE')
   OR BuildingType IN (SELECT CivUniqueBuildingType FROM BuildingReplaces
       WHERE ReplacesBuildingType IN ('BUILDING_MARKET', 'BUILDING_LIGHTHOUSE', 'BUILDING_BANK', 'BUILDING_STOCK_EXCHANGE'));
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_FinanceDistricts', DistrictType, 1, 220 FROM Districts
WHERE DistrictType IN ('DISTRICT_COMMERCIAL_HUB', 'DISTRICT_HARBOR')
   OR DistrictType IN (SELECT CivUniqueDistrictType FROM DistrictReplaces
       WHERE ReplacesDistrictType IN ('DISTRICT_COMMERCIAL_HUB', 'DISTRICT_HARBOR'));
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_FinanceExpensiveUnits', UnitType, 0, -60 FROM Units
WHERE COALESCE(Maintenance, 0) >= 2
  AND MAX(COALESCE(Combat, 0), COALESCE(RangedCombat, 0), COALESCE(Bombard, 0)) > 0;
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_CultureMonuments', BuildingType, 1, 240 FROM Buildings
WHERE BuildingType = 'BUILDING_MONUMENT'
   OR BuildingType IN (SELECT CivUniqueBuildingType FROM BuildingReplaces
       WHERE ReplacesBuildingType = 'BUILDING_MONUMENT');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_CultureTheaters', DistrictType, 1, 220 FROM Districts
WHERE DistrictType = 'DISTRICT_THEATER'
   OR DistrictType IN (SELECT CivUniqueDistrictType FROM DistrictReplaces
       WHERE ReplacesDistrictType = 'DISTRICT_THEATER');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ASAI_CultureConstructionBuildings', BuildingType, 1, 220 FROM Buildings
WHERE BuildingType IN ('BUILDING_AMPHITHEATER', 'BUILDING_MUSEUM_ART', 'BUILDING_MUSEUM_ARTIFACT')
   OR BuildingType IN (SELECT CivUniqueBuildingType FROM BuildingReplaces
       WHERE ReplacesBuildingType IN ('BUILDING_AMPHITHEATER', 'BUILDING_MUSEUM_ART', 'BUILDING_MUSEUM_ARTIFACT'));
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
    ('ASAI_FinanceGold', 'YIELD_GOLD', 1, 80),
    ('ASAI_FinanceSpecialization', 'BUILD_FOR_GOLD', 1, -3),
    ('ASAI_FinanceMilitarySpecialization', 'BUILD_MILITARY_UNITS', 0, 3),
    ('ASAI_CultureBuildYield', 'YIELD_CULTURE', 1, 60),
    ('ASAI_CultureBuildSpecialization', 'BUILD_FOR_CULTURE', 1, -2),
    ('ASAI_CulturePrerequisiteCivics', 'CIVIC_DRAMA_POETRY', 1, 180);
