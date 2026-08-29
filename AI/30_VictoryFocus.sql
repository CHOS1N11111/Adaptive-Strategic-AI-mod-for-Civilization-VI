-- Sharpen the existing victory strategies. Leader identity still decides the
-- route; these lists make the selected route coherent from districts to finish.
INSERT OR IGNORE INTO AiListTypes (ListType) VALUES
    ('ASAI_ScienceDistricts'),
    ('ASAI_ScienceBuildings'),
    ('ASAI_ScienceProjects'),
    ('ASAI_ScienceTechs'),
    ('ASAI_ScienceCivics'),
    ('ASAI_ScienceYields'),
    ('ASAI_SciencePseudoYields'),
    ('ASAI_CultureDistricts'),
    ('ASAI_CultureBuildings'),
    ('ASAI_CultureCivics'),
    ('ASAI_CultureUnits'),
    ('ASAI_CultureDiplomacy'),
    ('ASAI_CultureYields'),
    ('ASAI_CulturePseudoYields'),
    ('ASAI_MilitaryTechs'),
    ('ASAI_MilitaryUnitBuilds'),
    ('ASAI_MilitaryYields'),
    ('ASAI_MilitaryPseudoYields'),
    ('ASAI_ReligionDistricts'),
    ('ASAI_ReligionBuildings'),
    ('ASAI_ReligionUnits'),
    ('ASAI_ReligionYields'),
    ('ASAI_ReligionPseudoYields'),
    ('ASAI_DiploDistricts'),
    ('ASAI_DiploWonders'),
    ('ASAI_DiploProjects'),
    ('ASAI_DiploYields'),
    ('ASAI_DiploPseudoYields');

INSERT OR IGNORE INTO AiLists (ListType, System) VALUES
    ('ASAI_ScienceDistricts', 'Districts'),
    ('ASAI_ScienceBuildings', 'Buildings'),
    ('ASAI_ScienceProjects', 'Projects'),
    ('ASAI_ScienceTechs', 'Technologies'),
    ('ASAI_ScienceCivics', 'Civics'),
    ('ASAI_ScienceYields', 'Yields'),
    ('ASAI_SciencePseudoYields', 'PseudoYields'),
    ('ASAI_CultureDistricts', 'Districts'),
    ('ASAI_CultureBuildings', 'Buildings'),
    ('ASAI_CultureCivics', 'Civics'),
    ('ASAI_CultureUnits', 'Units'),
    ('ASAI_CultureDiplomacy', 'DiplomaticActions'),
    ('ASAI_CultureYields', 'Yields'),
    ('ASAI_CulturePseudoYields', 'PseudoYields'),
    ('ASAI_MilitaryTechs', 'Technologies'),
    ('ASAI_MilitaryUnitBuilds', 'UnitPromotionClasses'),
    ('ASAI_MilitaryYields', 'Yields'),
    ('ASAI_MilitaryPseudoYields', 'PseudoYields'),
    ('ASAI_ReligionDistricts', 'Districts'),
    ('ASAI_ReligionBuildings', 'Buildings'),
    ('ASAI_ReligionUnits', 'Units'),
    ('ASAI_ReligionYields', 'Yields'),
    ('ASAI_ReligionPseudoYields', 'PseudoYields'),
    ('ASAI_DiploDistricts', 'Districts'),
    ('ASAI_DiploWonders', 'Buildings'),
    ('ASAI_DiploProjects', 'Projects'),
    ('ASAI_DiploYields', 'Yields'),
    ('ASAI_DiploPseudoYields', 'PseudoYields');

INSERT OR IGNORE INTO Strategy_Priorities (StrategyType, ListType) VALUES
    ('VICTORY_STRATEGY_SCIENCE_VICTORY', 'ASAI_ScienceDistricts'),
    ('VICTORY_STRATEGY_SCIENCE_VICTORY', 'ASAI_ScienceBuildings'),
    ('VICTORY_STRATEGY_SCIENCE_VICTORY', 'ASAI_ScienceProjects'),
    ('VICTORY_STRATEGY_SCIENCE_VICTORY', 'ASAI_ScienceTechs'),
    ('VICTORY_STRATEGY_SCIENCE_VICTORY', 'ASAI_ScienceCivics'),
    ('VICTORY_STRATEGY_SCIENCE_VICTORY', 'ASAI_ScienceYields'),
    ('VICTORY_STRATEGY_SCIENCE_VICTORY', 'ASAI_SciencePseudoYields'),
    ('VICTORY_STRATEGY_CULTURAL_VICTORY', 'ASAI_CultureDistricts'),
    ('VICTORY_STRATEGY_CULTURAL_VICTORY', 'ASAI_CultureBuildings'),
    ('VICTORY_STRATEGY_CULTURAL_VICTORY', 'ASAI_CultureCivics'),
    ('VICTORY_STRATEGY_CULTURAL_VICTORY', 'ASAI_CultureUnits'),
    ('VICTORY_STRATEGY_CULTURAL_VICTORY', 'ASAI_CultureDiplomacy'),
    ('VICTORY_STRATEGY_CULTURAL_VICTORY', 'ASAI_CultureYields'),
    ('VICTORY_STRATEGY_CULTURAL_VICTORY', 'ASAI_CulturePseudoYields'),
    ('VICTORY_STRATEGY_MILITARY_VICTORY', 'ASAI_MilitaryTechs'),
    ('VICTORY_STRATEGY_MILITARY_VICTORY', 'ASAI_MilitaryUnitBuilds'),
    ('VICTORY_STRATEGY_MILITARY_VICTORY', 'ASAI_MilitaryYields'),
    ('VICTORY_STRATEGY_MILITARY_VICTORY', 'ASAI_MilitaryPseudoYields'),
    ('VICTORY_STRATEGY_RELIGIOUS_VICTORY', 'ASAI_ReligionDistricts'),
    ('VICTORY_STRATEGY_RELIGIOUS_VICTORY', 'ASAI_ReligionBuildings'),
    ('VICTORY_STRATEGY_RELIGIOUS_VICTORY', 'ASAI_ReligionUnits'),
    ('VICTORY_STRATEGY_RELIGIOUS_VICTORY', 'ASAI_ReligionYields'),
    ('VICTORY_STRATEGY_RELIGIOUS_VICTORY', 'ASAI_ReligionPseudoYields');

INSERT OR IGNORE INTO Strategy_Priorities (StrategyType, ListType)
SELECT 'VICTORY_STRATEGY_DIPLOMATIC_VICTORY', ListType
FROM AiListTypes
WHERE ListType IN
    ('ASAI_DiploDistricts', 'ASAI_DiploWonders', 'ASAI_DiploProjects',
     'ASAI_DiploYields', 'ASAI_DiploPseudoYields')
  AND EXISTS (
      SELECT 1 FROM Strategies
      WHERE StrategyType = 'VICTORY_STRATEGY_DIPLOMATIC_VICTORY'
  );

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
VALUES
    ('ASAI_ScienceDistricts', 'DISTRICT_CAMPUS', 1, 35),
    ('ASAI_ScienceDistricts', 'DISTRICT_INDUSTRIAL_ZONE', 1, 20),
    ('ASAI_ScienceDistricts', 'DISTRICT_SPACEPORT', 1, 75),
    ('ASAI_ScienceYields', 'YIELD_SCIENCE', 1, 40),
    ('ASAI_ScienceYields', 'YIELD_PRODUCTION', 1, 20),
    ('ASAI_ScienceYields', 'YIELD_GOLD', 1, 10),
    ('ASAI_ScienceYields', 'YIELD_FAITH', 1, -10),
    ('ASAI_SciencePseudoYields', 'PSEUDOYIELD_SPACE_RACE', 1, 125),
    ('ASAI_SciencePseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 35),
    ('ASAI_SciencePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 15),
    ('ASAI_CultureDistricts', 'DISTRICT_THEATER', 1, 45),
    ('ASAI_CultureDistricts', 'DISTRICT_ENTERTAINMENT_COMPLEX', 1, 15),
    ('ASAI_CultureYields', 'YIELD_CULTURE', 1, 45),
    ('ASAI_CultureYields', 'YIELD_PRODUCTION', 1, 15),
    ('ASAI_CultureYields', 'YIELD_FAITH', 1, 15),
    ('ASAI_CulturePseudoYields', 'PSEUDOYIELD_TOURISM', 1, 125),
    ('ASAI_CulturePseudoYields', 'PSEUDOYIELD_GPP_WRITER', 1, 35),
    ('ASAI_CulturePseudoYields', 'PSEUDOYIELD_GPP_ARTIST', 1, 35),
    ('ASAI_CulturePseudoYields', 'PSEUDOYIELD_GPP_MUSICIAN', 1, 35),
    ('ASAI_CulturePseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, 40),
    ('ASAI_CulturePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 15),
    ('ASAI_CultureDiplomacy', 'DIPLOACTION_OPEN_BORDERS', 1, 25),
    ('ASAI_MilitaryYields', 'YIELD_PRODUCTION', 1, 35),
    ('ASAI_MilitaryYields', 'YIELD_GOLD', 1, 15),
    ('ASAI_MilitaryYields', 'YIELD_SCIENCE', 1, 10),
    ('ASAI_MilitaryPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 45),
    ('ASAI_MilitaryPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 45),
    ('ASAI_MilitaryPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 35),
    ('ASAI_MilitaryPseudoYields', 'PSEUDOYIELD_NUCLEAR_WEAPON', 1, 25),
    ('ASAI_MilitaryUnitBuilds', 'PROMOTION_CLASS_MELEE', 1, 15),
    ('ASAI_MilitaryUnitBuilds', 'PROMOTION_CLASS_RANGED', 1, 15),
    ('ASAI_MilitaryUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, 40),
    ('ASAI_MilitaryUnitBuilds', 'PROMOTION_CLASS_AIR_FIGHTER', 1, 30),
    ('ASAI_MilitaryUnitBuilds', 'PROMOTION_CLASS_AIR_BOMBER', 1, 45),
    ('ASAI_ReligionDistricts', 'DISTRICT_HOLY_SITE', 1, 55),
    ('ASAI_ReligionYields', 'YIELD_FAITH', 1, 65),
    ('ASAI_ReligionYields', 'YIELD_PRODUCTION', 1, 15),
    ('ASAI_ReligionYields', 'YIELD_CULTURE', 1, 10),
    ('ASAI_ReligionPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, 85),
    ('ASAI_ReligionPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 30),
    ('ASAI_ReligionPseudoYields', 'PSEUDOYIELD_RELIGIOUS_CONVERT_EMPIRE', 1, 60),
    ('ASAI_DiploDistricts', 'DISTRICT_COMMERCIAL_HUB', 1, 20),
    ('ASAI_DiploDistricts', 'DISTRICT_HARBOR', 1, 20),
    ('ASAI_DiploYields', 'YIELD_GOLD', 1, 30),
    ('ASAI_DiploYields', 'YIELD_PRODUCTION', 1, 15),
    ('ASAI_DiploYields', 'YIELD_CULTURE', 1, 10),
    ('ASAI_DiploPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_FAVOR', 1, 80),
    ('ASAI_DiploPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_VICTORY_POINT', 1, 150),
    ('ASAI_DiploPseudoYields', 'PSEUDOYIELD_INFLUENCE', 1, 35),
    ('ASAI_DiploPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 25);

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ScienceBuildings', BuildingType, 1, 25
FROM Buildings
WHERE BuildingType IN
    ('BUILDING_LIBRARY', 'BUILDING_UNIVERSITY', 'BUILDING_RESEARCH_LAB',
     'BUILDING_WORKSHOP', 'BUILDING_FACTORY', 'BUILDING_POWER_PLANT',
     'BUILDING_COAL_POWER_PLANT', 'BUILDING_FOSSIL_FUEL_POWER_PLANT');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ScienceProjects', ProjectType, 1, 100
FROM Projects
WHERE SpaceRace = 1;

-- The future-era tree randomizes prerequisites and hides part of the route.
-- Weight every frontier technology that can stand between Nanotechnology and
-- the final two project gates, while keeping the direct gates strongest.
INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ScienceTechs', TechnologyType, 1,
    CASE TechnologyType
        WHEN 'TECH_ROCKETRY' THEN 50
        WHEN 'TECH_SATELLITES' THEN 70
        WHEN 'TECH_NANOTECHNOLOGY' THEN 100
        WHEN 'TECH_SMART_MATERIALS' THEN 150
        WHEN 'TECH_OFFWORLD_MISSION' THEN 180
        ELSE 45
    END
FROM Technologies
WHERE TechnologyType IN
    ('TECH_ROCKETRY', 'TECH_SATELLITES', 'TECH_NANOTECHNOLOGY',
     'TECH_SEASTEADS', 'TECH_ADVANCED_AI', 'TECH_ADVANCED_POWER_CELLS',
     'TECH_CYBERNETICS', 'TECH_PREDICTIVE_SYSTEMS',
     'TECH_SMART_MATERIALS', 'TECH_OFFWORLD_MISSION');

-- Reach the two space-project policy cards without turning science victory
-- into a fixed civic route. These are chooser weights, not free civics.
INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ScienceCivics', CivicType, 1,
    CASE CivicType
        WHEN 'CIVIC_COLD_WAR' THEN 45
        WHEN 'CIVIC_SPACE_RACE' THEN 90
        WHEN 'CIVIC_RAPID_DEPLOYMENT' THEN 55
        WHEN 'CIVIC_GLOBALIZATION' THEN 100
        ELSE 35
    END
FROM Civics
WHERE CivicType IN
    ('CIVIC_COLD_WAR', 'CIVIC_SPACE_RACE', 'CIVIC_RAPID_DEPLOYMENT',
     'CIVIC_GLOBALIZATION', 'CIVIC_SOCIAL_MEDIA');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_CultureBuildings', BuildingType, 1, 30
FROM Buildings
WHERE BuildingType IN
    ('BUILDING_AMPHITHEATER', 'BUILDING_MUSEUM_ART',
     'BUILDING_MUSEUM_ARTIFACT', 'BUILDING_BROADCAST_CENTER');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_CultureCivics', CivicType, 1, 35
FROM Civics
WHERE CivicType IN
    ('CIVIC_CONSERVATION', 'CIVIC_CULTURAL_HERITAGE',
     'CIVIC_COLD_WAR', 'CIVIC_ENVIRONMENTALISM', 'CIVIC_SOCIAL_MEDIA');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_CultureUnits', UnitType, 1, 50
FROM Units
WHERE UnitType IN ('UNIT_ARCHAEOLOGIST', 'UNIT_NATURALIST', 'UNIT_ROCK_BAND');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_MilitaryTechs', TechnologyType, 1, 30
FROM Technologies
WHERE TechnologyType IN
    ('TECH_ARCHERY', 'TECH_IRON_WORKING', 'TECH_MILITARY_ENGINEERING',
     'TECH_METAL_CASTING', 'TECH_STEEL', 'TECH_COMBUSTION',
     'TECH_ADVANCED_FLIGHT', 'TECH_GUIDANCE_SYSTEMS', 'TECH_STEALTH_TECHNOLOGY');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ReligionBuildings', BuildingType, 1, 30
FROM Buildings
WHERE PrereqDistrict = 'DISTRICT_HOLY_SITE';

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_ReligionUnits', UnitType, 1, 45
FROM Units
WHERE ReligiousStrength > 0;

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_DiploWonders', BuildingType, 1, 50
FROM Buildings
WHERE BuildingType IN
    ('BUILDING_ORSZAGHAZ', 'BUILDING_POTALA_PALACE',
     'BUILDING_STATUE_LIBERTY');

INSERT OR IGNORE INTO AiFavoredItems
    (ListType, Item, Favored, Value)
SELECT 'ASAI_DiploProjects', ProjectType, 1, 60
FROM Projects
WHERE ProjectType IN ('PROJECT_SEND_AID', 'PROJECT_CARBON_RECAPTURE');
