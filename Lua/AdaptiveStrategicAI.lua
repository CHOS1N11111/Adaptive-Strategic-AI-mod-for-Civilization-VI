print("Adaptive Strategic AI " .. tostring(GlobalParameters.ASAI_VERSION) .. " loaded");

local m_Snapshots = {};
local m_StrengthSnapshots = {};
local m_HumanReference = { Turn = -1, Value = nil };
local m_WorldReference = { Turn = -1, Value = nil };
local m_EconomicSnapshots = {};
local m_HumanEconomicReference = { Turn = -1, Value = nil };
local m_RelativeRuntime = {};
local m_ConditionErrors = {};
local m_ProductionApiLogged = false;
local LAST_MAJOR_COMBAT_TURN_PROPERTY = "ASAI_LAST_MAJOR_COMBAT_TURN";

local RELATIVE_CATCHUP = -1;
local RELATIVE_MATCHED = 0;
local RELATIVE_CONSOLIDATE = 1;
local RELATIVE_BAND_PROPERTY = "ASAI_RELATIVE_BAND";
local RELATIVE_SAMPLE_TURN_PROPERTY = "ASAI_RELATIVE_LAST_SAMPLE_TURN";
local RELATIVE_EVALUATION_TURN_PROPERTY = "ASAI_RELATIVE_LAST_EVAL_TURN";
local RELATIVE_BAND_CANDIDATE_PROPERTY = "ASAI_RELATIVE_BAND_CANDIDATE";
local RELATIVE_BAND_STREAK_PROPERTY = "ASAI_RELATIVE_BAND_STREAK";
local RELATIVE_BAND_CHANGED_TURN_PROPERTY = "ASAI_RELATIVE_BAND_CHANGED_TURN";
local RELATIVE_BAND_COOLDOWN_PROPERTY = "ASAI_RELATIVE_BAND_COOLDOWN_UNTIL";
local RELATIVE_SCORE_PROPERTIES = {
    Overall = "ASAI_RELATIVE_SCORE_X1000",
    Science = "ASAI_RELATIVE_SCIENCE_X1000",
    Culture = "ASAI_RELATIVE_CULTURE_X1000",
    Empire = "ASAI_RELATIVE_EMPIRE_X1000",
    Military = "ASAI_RELATIVE_MILITARY_X1000"
};
local RELATIVE_RAW_SCORE_PROPERTIES = {
    Overall = "ASAI_RELATIVE_RAW_SCORE_X1000",
    Science = "ASAI_RELATIVE_RAW_SCIENCE_X1000",
    Culture = "ASAI_RELATIVE_RAW_CULTURE_X1000",
    Empire = "ASAI_RELATIVE_RAW_EMPIRE_X1000",
    Military = "ASAI_RELATIVE_RAW_MILITARY_X1000"
};
local RELATIVE_RECOVERY_PROPERTIES = {
    Science = "ASAI_RELATIVE_SCIENCE_RECOVERY",
    Culture = "ASAI_RELATIVE_CULTURE_RECOVERY",
    Empire = "ASAI_RELATIVE_EMPIRE_RECOVERY"
};
local RELATIVE_FOCUS_NONE = 0;
local RELATIVE_FOCUS_SCIENCE = 1;
local RELATIVE_FOCUS_CULTURE = 2;
local RELATIVE_FOCUS_EMPIRE = 3;
local RELATIVE_FOCUS_PROPERTY = "ASAI_RELATIVE_FOCUS";
local RELATIVE_FOCUS_CANDIDATE_PROPERTY = "ASAI_RELATIVE_FOCUS_CANDIDATE";
local RELATIVE_FOCUS_STREAK_PROPERTY = "ASAI_RELATIVE_FOCUS_STREAK";
local RELATIVE_FOCUS_CHANGED_TURN_PROPERTY = "ASAI_RELATIVE_FOCUS_CHANGED_TURN";
local RELATIVE_FOCUS_HANDOFF_PROPERTY = "ASAI_RELATIVE_FOCUS_HANDOFF_READY";
local RELATIVE_FOCUS_COOLDOWN_PROPERTY = "ASAI_RELATIVE_FOCUS_COOLDOWN_UNTIL";
local RELATIVE_FOCUS_STARTED_TURN_PROPERTY = "ASAI_RELATIVE_FOCUS_STARTED_TURN";
local RELATIVE_FOCUS_REVIEW_TURN_PROPERTY = "ASAI_RELATIVE_FOCUS_REVIEW_TURN";
local RELATIVE_FOCUS_BASELINE_PROPERTY = "ASAI_RELATIVE_FOCUS_BASELINE_X1000";
local RELATIVE_FOCUS_RAW_BASELINE_PROPERTY = "ASAI_RELATIVE_FOCUS_RAW_BASELINE_X1000";
local RELATIVE_FOCUS_GAIN_PROPERTY = "ASAI_RELATIVE_FOCUS_GAIN_X1000";
local RELATIVE_FOCUS_RAW_GAIN_PROPERTY = "ASAI_RELATIVE_FOCUS_RAW_GAIN_X1000";
local RELATIVE_FOCUS_RESULT_PROPERTY = "ASAI_RELATIVE_FOCUS_RESULT";
local RELATIVE_FOCUS_EXECUTION_PROPERTY = "ASAI_RELATIVE_FOCUS_EXECUTION";
local RELATIVE_FOCUS_STALL_COUNT_PROPERTY = "ASAI_RELATIVE_FOCUS_STALL_COUNT";
local RELATIVE_FOCUS_RESULT_NONE = 0;
local RELATIVE_FOCUS_RESULT_IMPROVING = 1;
local RELATIVE_FOCUS_RESULT_EXECUTING = 2;
local RELATIVE_FOCUS_RESULT_STALLED = 3;
local RELATIVE_FOCUS_COOLDOWN_PROPERTIES = {
    [RELATIVE_FOCUS_SCIENCE] = "ASAI_RELATIVE_SCIENCE_COOLDOWN_UNTIL",
    [RELATIVE_FOCUS_CULTURE] = "ASAI_RELATIVE_CULTURE_COOLDOWN_UNTIL",
    [RELATIVE_FOCUS_EMPIRE] = "ASAI_RELATIVE_EMPIRE_COOLDOWN_UNTIL"
};
local RELATIVE_SEVERE_PROPERTY = "ASAI_RELATIVE_SEVERE_CATCHUP";
local RELATIVE_SEVERE_CANDIDATE_PROPERTY = "ASAI_RELATIVE_SEVERE_CANDIDATE";
local RELATIVE_SEVERE_STREAK_PROPERTY = "ASAI_RELATIVE_SEVERE_STREAK";
local RELATIVE_SEVERE_CHANGED_TURN_PROPERTY = "ASAI_RELATIVE_SEVERE_CHANGED_TURN";
local MILD_RESULT_YIELDS_ACTIVE_PROPERTY = "ASAI_MILD_RESULT_YIELDS_ACTIVE";
local MILD_RESULT_YIELDS_ON_MODIFIER = "ASAI_MILD_RESULT_YIELDS_ON";
local MILD_RESULT_YIELDS_OFF_MODIFIER = "ASAI_MILD_RESULT_YIELDS_OFF";
local MILD_RESULT_PRODUCTION_PERCENT = 20;
local MILD_RESULT_SCIENCE_PERCENT = 15;
local MILD_RESULT_CULTURE_PERCENT = 15;
local MILD_RESULT_FOOD_PERCENT = 10;
local SEVERE_RESULT_YIELDS_ACTIVE_PROPERTY = "ASAI_SEVERE_RESULT_YIELDS_ACTIVE";
local SEVERE_RESULT_YIELDS_ON_MODIFIER = "ASAI_SEVERE_RESULT_YIELDS_ON";
local SEVERE_RESULT_YIELDS_OFF_MODIFIER = "ASAI_SEVERE_RESULT_YIELDS_OFF";
local SEVERE_RESULT_PRODUCTION_PERCENT = 40;
local SEVERE_RESULT_SCIENCE_PERCENT = 30;
local SEVERE_RESULT_CULTURE_PERCENT = 30;
local SEVERE_RESULT_FOOD_PERCENT = 20;
local MILITARY_READINESS_PROPERTY = "ASAI_MILITARY_READINESS";
local MILITARY_READINESS_CANDIDATE_PROPERTY = "ASAI_MILITARY_READINESS_CANDIDATE";
local MILITARY_READINESS_STREAK_PROPERTY = "ASAI_MILITARY_READINESS_STREAK";
local MILITARY_READINESS_CHANGED_TURN_PROPERTY = "ASAI_MILITARY_READINESS_CHANGED_TURN";
local MILITARY_READINESS_COOLDOWN_PROPERTY = "ASAI_MILITARY_READINESS_COOLDOWN_UNTIL";
local MILITARY_DOMINANCE_PROPERTY = "ASAI_MILITARY_DOMINANCE";
local SCALE_RECOVERY_PROPERTY = "ASAI_SCALE_RECOVERY";
local SCALE_RECOVERY_CANDIDATE_PROPERTY = "ASAI_SCALE_RECOVERY_CANDIDATE";
local SCALE_RECOVERY_STREAK_PROPERTY = "ASAI_SCALE_RECOVERY_STREAK";
local SCALE_RECOVERY_CHANGED_TURN_PROPERTY = "ASAI_SCALE_RECOVERY_CHANGED_TURN";
local SCALE_RECOVERY_COOLDOWN_PROPERTY = "ASAI_SCALE_RECOVERY_COOLDOWN_UNTIL";
local SCALE_EXPANSION_ALLOWED_PROPERTY = "ASAI_SCALE_EXPANSION_ALLOWED";

-- Keep coordinator state on one table to stay below Lua's 200-local chunk limit.
local Strategic = {
    DEVELOP = 1,
    RECOVER = 2,
    EXPAND = 3,
    DEFEND = 4,
    PRESSURE = 5,
    WAR = 6,
    PROPERTY = "ASAI_STRATEGIC_PLAN",
    CANDIDATE_PROPERTY = "ASAI_STRATEGIC_PLAN_CANDIDATE",
    STREAK_PROPERTY = "ASAI_STRATEGIC_PLAN_STREAK",
    CHANGED_TURN_PROPERTY = "ASAI_STRATEGIC_PLAN_CHANGED_TURN",
    STARTED_TURN_PROPERTY = "ASAI_STRATEGIC_PLAN_STARTED_TURN",
    REVIEW_TURN_PROPERTY = "ASAI_STRATEGIC_PLAN_REVIEW_TURN",
    BASELINE_PROPERTY = "ASAI_STRATEGIC_PLAN_BASELINE_X1000",
    BASELINE_CITIES_PROPERTY = "ASAI_STRATEGIC_PLAN_BASELINE_CITIES",
    BASELINE_CAPTURED_PROPERTY = "ASAI_STRATEGIC_PLAN_BASELINE_CAPTURED",
    BASELINE_SETTLERS_PROPERTY = "ASAI_STRATEGIC_PLAN_BASELINE_SETTLERS",
    BASELINE_ACTIVE_WARS_PROPERTY =
        "ASAI_STRATEGIC_PLAN_BASELINE_ACTIVE_MAJOR_WARS",
    BASELINE_COMBAT_PROPERTY = "ASAI_STRATEGIC_PLAN_BASELINE_COMBAT",
    BASELINE_OWNED_PROPERTY = "ASAI_STRATEGIC_PLAN_BASELINE_OWNED",
    BASELINE_MILITARY_PROPERTY = "ASAI_STRATEGIC_PLAN_BASELINE_MILITARY",
    BASELINE_ENEMY_MILITARY_PROPERTY =
        "ASAI_STRATEGIC_PLAN_BASELINE_ENEMY_MILITARY",
    BASELINE_MAJOR_WARS_PROPERTY = "ASAI_STRATEGIC_PLAN_BASELINE_MAJOR_WARS",
    BASELINE_COMBAT_EVENTS_PROPERTY =
        "ASAI_STRATEGIC_PLAN_BASELINE_COMBAT_EVENTS",
    BASELINE_CAPTURE_EVENTS_PROPERTY =
        "ASAI_STRATEGIC_PLAN_BASELINE_CAPTURE_EVENTS",
    BASELINE_PILLAGE_EVENTS_PROPERTY =
        "ASAI_STRATEGIC_PLAN_BASELINE_PILLAGE_EVENTS",
    GAIN_PROPERTY = "ASAI_STRATEGIC_PLAN_GAIN_X1000",
    RESULT_PROPERTY = "ASAI_STRATEGIC_PLAN_RESULT",
    EXECUTION_PROPERTY = "ASAI_STRATEGIC_PLAN_EXECUTION",
    STALL_COUNT_PROPERTY = "ASAI_STRATEGIC_PLAN_STALL_COUNT",
    SCORE_PROPERTY = "ASAI_STRATEGIC_PLAN_SCORE_X100",
    SUPPORT_PROPERTY = "ASAI_STRATEGIC_SUPPORT",
    OUTCOME_SCHEMA = 4,
    OUTCOME_SCHEMA_PROPERTY = "ASAI_STRATEGIC_PLAN_OUTCOME_SCHEMA",
    MAJOR_COMBAT_EVENTS_PROPERTY = "ASAI_MAJOR_COMBAT_EVENTS",
    MAJOR_CAPTURE_EVENTS_PROPERTY = "ASAI_MAJOR_CAPTURE_EVENTS",
    MAJOR_PILLAGE_EVENTS_PROPERTY = "ASAI_MAJOR_PILLAGE_EVENTS",
    FOCUS_OWN_YIELD_BASELINE_PROPERTY =
        "ASAI_RELATIVE_FOCUS_OWN_YIELD_BASELINE_X100",
    FOCUS_OWN_PROGRESS_BASELINE_PROPERTY =
        "ASAI_RELATIVE_FOCUS_OWN_PROGRESS_BASELINE",
    FOCUS_OWN_YIELD_GAIN_PROPERTY =
        "ASAI_RELATIVE_FOCUS_OWN_YIELD_GAIN_X1000",
    FOCUS_OWN_PROGRESS_GAIN_PROPERTY =
        "ASAI_RELATIVE_FOCUS_OWN_PROGRESS_GAIN",
    EXPANSION_SETTLER_STALL_PROPERTY = "ASAI_EXPANSION_SETTLER_STALL_COUNT",
    EXPANSION_LAST_SUCCESS_PROPERTY = "ASAI_EXPANSION_LAST_SUCCESS_TURN",
    EXPANSION_BLOCKED_UNTIL_PROPERTY = "ASAI_EXPANSION_BLOCKED_UNTIL",
    EXPANSION_NORMAL = 0,
    EXPANSION_RESTRICTED = 1,
    EXPANSION_CLOSED = 2
};
Strategic.COOLDOWN_PROPERTIES = {
    [Strategic.DEVELOP] = "ASAI_PLAN_DEVELOP_COOLDOWN_UNTIL",
    [Strategic.RECOVER] = "ASAI_PLAN_RECOVER_COOLDOWN_UNTIL",
    [Strategic.EXPAND] = "ASAI_PLAN_EXPAND_COOLDOWN_UNTIL",
    [Strategic.DEFEND] = "ASAI_PLAN_DEFEND_COOLDOWN_UNTIL",
    [Strategic.PRESSURE] = "ASAI_PLAN_PRESSURE_COOLDOWN_UNTIL",
    [Strategic.WAR] = "ASAI_PLAN_WAR_COOLDOWN_UNTIL"
};
local ScienceExecution = {
    NONE = 0,
    SATELLITE = 1,
    MOON = 2,
    MARS = 3,
    EXOPLANET = 4,
    STAGE_PROPERTY = "ASAI_SCIENCE_EXECUTION_STAGE",
    STAGE_TURN_PROPERTY = "ASAI_SCIENCE_EXECUTION_STAGE_TURN",
    LAST_PROGRESS_TURN_PROPERTY = "ASAI_SCIENCE_EXECUTION_LAST_PROGRESS_TURN",
    COUNT_PROPERTY_PREFIX = "ASAI_SCIENCE_PROJECT_COUNT_",
    TRACKING_SCHEMA_PROPERTY = "ASAI_SCIENCE_TRACKING_SCHEMA",
    TRACKING_SCHEMA = 1,
    PROJECTS = {
        Satellite = "PROJECT_LAUNCH_EARTH_SATELLITE",
        Moon = "PROJECT_LAUNCH_MOON_LANDING",
        Mars = "PROJECT_LAUNCH_MARS_BASE",
        Exoplanet = "PROJECT_LAUNCH_EXOPLANET_EXPEDITION",
        OrbitalLaser = "PROJECT_ORBITAL_LASER",
        TerrestrialLaser = "PROJECT_TERRESTRIAL_LASER"
    },
    FRONTIER_TECHS = {
        "TECH_SEASTEADS",
        "TECH_ADVANCED_AI",
        "TECH_ADVANCED_POWER_CELLS",
        "TECH_CYBERNETICS",
        "TECH_PREDICTIVE_SYSTEMS",
        "TECH_SMART_MATERIALS",
        "TECH_OFFWORLD_MISSION"
    },
    Cache = {}
};
ScienceExecution.PROJECT_STAGES = {
    [ScienceExecution.PROJECTS.Satellite] = ScienceExecution.SATELLITE,
    [ScienceExecution.PROJECTS.Moon] = ScienceExecution.MOON,
    [ScienceExecution.PROJECTS.Mars] = ScienceExecution.MARS,
    [ScienceExecution.PROJECTS.Exoplanet] = ScienceExecution.EXOPLANET,
    [ScienceExecution.PROJECTS.OrbitalLaser] = ScienceExecution.EXOPLANET,
    [ScienceExecution.PROJECTS.TerrestrialLaser] = ScienceExecution.EXOPLANET
};
ScienceExecution.STAGE_PROJECTS = {
    [ScienceExecution.SATELLITE] = ScienceExecution.PROJECTS.Satellite,
    [ScienceExecution.MOON] = ScienceExecution.PROJECTS.Moon,
    [ScienceExecution.MARS] = ScienceExecution.PROJECTS.Mars,
    [ScienceExecution.EXOPLANET] = ScienceExecution.PROJECTS.Exoplanet
};
local ThreatResponse = {
    LAST_AIR_TURN_PROPERTY = "ASAI_LAST_AIR_THREAT_TURN",
    LAST_GDR_TURN_PROPERTY = "ASAI_LAST_GDR_THREAT_TURN",
    Cache = {}
};
local Diagnostics = {
    QUEUE_SAMPLE_TURN_PROPERTY = "ASAI_QUEUE_SAMPLE_TURN",
    QUEUE_IDLE_SAMPLE_TURN_PROPERTY = "ASAI_QUEUE_IDLE_SAMPLE_TURN",
    QUEUE_IDLE_STREAK_PROPERTY = "ASAI_QUEUE_IDLE_STREAK",
    QUEUE_IDLE_PLAYER_PROPERTY = "ASAI_QUEUE_IDLE_PLAYER",
    CultureBuildingRoles = nil,
    UnitAiTypes = nil,
    UnavailableSensors = {}
};
local RELATIVE_TREND_PROPERTIES = {
    Overall = "ASAI_RELATIVE_TREND_X1000",
    Science = "ASAI_RELATIVE_SCIENCE_TREND_X1000",
    Culture = "ASAI_RELATIVE_CULTURE_TREND_X1000",
    Empire = "ASAI_RELATIVE_EMPIRE_TREND_X1000",
    Military = "ASAI_RELATIVE_MILITARY_TREND_X1000"
};

local GetRelativeState;

local RELATIVE_COMPONENTS = {
    { Key = "Techs", Parameter = "ASAI_RELATIVE_WEIGHT_TECHS", Weight = 20 },
    { Key = "Civics", Parameter = "ASAI_RELATIVE_WEIGHT_CIVICS", Weight = 18 },
    { Key = "Science", Parameter = "ASAI_RELATIVE_WEIGHT_SCIENCE", Weight = 12 },
    { Key = "Culture", Parameter = "ASAI_RELATIVE_WEIGHT_CULTURE", Weight = 12 },
    { Key = "Cities", Parameter = "ASAI_RELATIVE_WEIGHT_CITIES", Weight = 10 },
    { Key = "Population", Parameter = "ASAI_RELATIVE_WEIGHT_POPULATION", Weight = 15 },
    { Key = "Military", Parameter = "ASAI_RELATIVE_WEIGHT_MILITARY", Weight = 13 }
};

local RELATIVE_PILLARS = {
    Science = { "Techs", "Science" },
    Culture = { "Civics", "Culture" },
    Empire = { "Cities", "Population" },
    Military = { "Military" }
};

local function GetNumberParameter(name, fallback)
    local value = tonumber(GlobalParameters[name]);
    if value == nil then
        return fallback;
    end
    return value;
end

function Strategic.GetRuntimeCounter(player, propertyName)
    local rawValue = player:GetProperty(propertyName);
    local value = tonumber(rawValue);
    return value ~= nil and math.max(0, math.floor(value)) or 0;
end

function Strategic.IncrementRuntimeCounter(player, propertyName)
    player:SetProperty(
        propertyName,
        Strategic.GetRuntimeCounter(player, propertyName) + 1
    );
end

local function GetGameSpeedMultiplier()
    if GameConfiguration == nil or GameConfiguration.GetGameSpeedType == nil then
        return 100;
    end
    local speedType = GameConfiguration.GetGameSpeedType();
    local speedInfo = speedType ~= nil and GameInfo.GameSpeeds[speedType] or nil;
    local multiplier = speedInfo ~= nil and tonumber(speedInfo.CostMultiplier) or nil;
    if multiplier == nil or multiplier <= 0 then
        return 100;
    end
    return multiplier;
end

local function ScaleStandardTurns(standardTurns)
    local scaled = standardTurns * GetGameSpeedMultiplier() / 100;
    return math.max(1, math.floor(scaled + 0.5));
end

local function GetStandardEquivalentTurn(turn)
    return turn * 100 / GetGameSpeedMultiplier();
end

local function RunStrategyCondition(conditionName, evaluator, playerID, threshold)
    local success, result = pcall(evaluator, playerID, threshold);
    if success then
        return result == true;
    end

    if m_ConditionErrors[conditionName] == nil then
        print(string.format(
            "ASAI_ERROR condition=%s player=%s fallback=false error=%s",
            conditionName,
            tostring(playerID),
            tostring(result)
        ));
        m_ConditionErrors[conditionName] = true;
    end
    return false;
end

local function TryDiagnosticSensor(sensorName, collector, rememberUnsupported)
    if rememberUnsupported
        and Diagnostics.UnavailableSensors[sensorName] then
        return nil, 0;
    end
    local success, result = pcall(collector);
    if success and result ~= nil then
        return result, 1;
    end

    local errorKey = "ASAI_Diagnostic_" .. sensorName;
    if m_ConditionErrors[errorKey] == nil then
        print(string.format(
            "ASAI_DIAGNOSTIC_ERROR sensor=%s fallback=missing error=%s",
            sensorName,
            tostring(result)
        ));
        m_ConditionErrors[errorKey] = true;
    end
    if rememberUnsupported then
        Diagnostics.UnavailableSensors[sensorName] = true;
    end
    return nil, 0;
end

local function IsMajorAI(playerID)
    if not PlayerManager.IsAlive(playerID) then
        return false;
    end
    local player = Players[playerID];
    return player ~= nil and player:IsMajor() and not player:IsHuman();
end

local function CountOwnedPlots(playerID)
    local owned = 0;
    local improved = 0;
    for plotIndex = 0, Map.GetPlotCount() - 1 do
        local plot = Map.GetPlotByIndex(plotIndex);
        if plot ~= nil and plot:GetOwner() == playerID then
            owned = owned + 1;
            if plot:GetImprovementType() >= 0 then
                improved = improved + 1;
            end
        end
    end
    return owned, improved;
end

local function CountUnits(player)
    local builders = 0;
    local traders = 0;
    local settlers = 0;
    for _, unit in player:GetUnits():Members() do
        local unitInfo = GameInfo.Units[unit:GetType()];
        if unitInfo ~= nil then
            if unitInfo.UnitType == "UNIT_BUILDER" then
                builders = builders + 1;
            end
            if unitInfo.MakeTradeRoute then
                traders = traders + 1;
            end
            if unitInfo.FoundCity then
                settlers = settlers + 1;
            end
        end
    end
    return builders, traders, settlers;
end

local function GetCurrentProductionType(city)
    local buildQueue = city:GetBuildQueue();
    if buildQueue == nil then
        return nil;
    end
    local productionType = buildQueue:CurrentlyBuilding();
    if not m_ProductionApiLogged then
        print("ASAI_QUEUE_API mode=currently_building coverage=current_only");
        m_ProductionApiLogged = true;
    end
    if productionType == nil
        or productionType == ""
        or productionType == "NONE"
        or productionType == 0
        or productionType == -1 then
        return nil;
    end
    local unitInfo = GameInfo.Units[productionType];
    if unitInfo ~= nil then
        return unitInfo.UnitType;
    end
    local districtInfo = GameInfo.Districts[productionType];
    if districtInfo ~= nil then
        return districtInfo.DistrictType;
    end
    local buildingInfo = GameInfo.Buildings[productionType];
    if buildingInfo ~= nil then
        return buildingInfo.BuildingType;
    end
    local projectInfo = GameInfo.Projects[productionType];
    if projectInfo ~= nil then
        return projectInfo.ProjectType;
    end
    return productionType;
end

local function IsDistrictRole(districtType, baseDistrictType)
    if districtType == baseDistrictType then
        return true;
    end
    for replacement in GameInfo.DistrictReplaces() do
        if replacement.CivUniqueDistrictType == districtType
            and replacement.ReplacesDistrictType == baseDistrictType then
            return true;
        end
    end
    return false;
end

local function IsBuildingRole(buildingType, baseBuildingType)
    if buildingType == baseBuildingType then
        return true;
    end
    for replacement in GameInfo.BuildingReplaces() do
        if replacement.CivUniqueBuildingType == buildingType
            and replacement.ReplacesBuildingType == baseBuildingType then
            return true;
        end
    end
    return false;
end

local function GetUnitBaseStrength(unitInfo)
    if unitInfo == nil then
        return 0;
    end
    return math.max(
        tonumber(unitInfo.Combat) or 0,
        tonumber(unitInfo.RangedCombat) or 0,
        tonumber(unitInfo.Bombard) or 0,
        tonumber(unitInfo.AntiAirCombat) or 0
    );
end

local function AddMilitaryRole(profile, unitInfo)
    if GetUnitBaseStrength(unitInfo) <= 0 then
        return;
    end
    profile.Combat = profile.Combat + 1;
    if unitInfo.Domain == "DOMAIN_LAND" then
        profile.Land = profile.Land + 1;
    elseif unitInfo.Domain == "DOMAIN_SEA" then
        profile.Naval = profile.Naval + 1;
    elseif unitInfo.Domain == "DOMAIN_AIR" then
        profile.Air = profile.Air + 1;
    end

    local promotionClass = unitInfo.PromotionClass;
    if promotionClass == "PROMOTION_CLASS_RANGED" then
        profile.Ranged = profile.Ranged + 1;
    elseif promotionClass == "PROMOTION_CLASS_SIEGE" then
        profile.Siege = profile.Siege + 1;
    elseif promotionClass == "PROMOTION_CLASS_LIGHT_CAVALRY"
        or promotionClass == "PROMOTION_CLASS_HEAVY_CAVALRY" then
        profile.Mobile = profile.Mobile + 1;
    end
end

local function ProductionSupportsFocus(productionType, focus)
    if productionType == nil then
        return false;
    end

    local districtInfo = GameInfo.Districts[productionType];
    local buildingInfo = GameInfo.Buildings[productionType];
    local projectInfo = GameInfo.Projects[productionType];
    local unitInfo = GameInfo.Units[productionType];
    if focus == RELATIVE_FOCUS_SCIENCE then
        return (districtInfo ~= nil
                and IsDistrictRole(productionType, "DISTRICT_CAMPUS"))
            or (buildingInfo ~= nil
                and IsDistrictRole(buildingInfo.PrereqDistrict, "DISTRICT_CAMPUS"))
            or (projectInfo ~= nil
                and IsDistrictRole(projectInfo.PrereqDistrict, "DISTRICT_CAMPUS"));
    end
    if focus == RELATIVE_FOCUS_CULTURE then
        return (districtInfo ~= nil
                and IsDistrictRole(productionType, "DISTRICT_THEATER"))
            or (buildingInfo ~= nil
                and (IsDistrictRole(buildingInfo.PrereqDistrict, "DISTRICT_THEATER")
                    or IsBuildingRole(productionType, "BUILDING_MONUMENT")))
            or (projectInfo ~= nil
                and IsDistrictRole(projectInfo.PrereqDistrict, "DISTRICT_THEATER"));
    end
    if focus == RELATIVE_FOCUS_EMPIRE then
        return (unitInfo ~= nil
                and (unitInfo.FoundCity
                    or unitInfo.MakeTradeRoute
                    or unitInfo.UnitType == "UNIT_BUILDER"))
            or (buildingInfo ~= nil
                and ((tonumber(buildingInfo.Housing) or 0) > 0
                    or IsBuildingRole(productionType, "BUILDING_WATER_MILL")))
            or (districtInfo ~= nil
                and (IsDistrictRole(productionType, "DISTRICT_AQUEDUCT")
                    or IsDistrictRole(productionType, "DISTRICT_NEIGHBORHOOD")));
    end
    return false;
end

local function CountFocusProduction(player, focus)
    local count = 0;
    for _, city in player:GetCities():Members() do
        if ProductionSupportsFocus(GetCurrentProductionType(city), focus) then
            count = count + 1;
        end
    end
    return count;
end

local function CountInFlightUnits(player)
    local builders = 0;
    local traders = 0;
    local settlers = 0;
    for _, city in player:GetCities():Members() do
        local productionType = GetCurrentProductionType(city);
        local unitInfo = productionType ~= nil and GameInfo.Units[productionType] or nil;
        if unitInfo ~= nil then
            if unitInfo.UnitType == "UNIT_BUILDER" then
                builders = builders + 1;
            end
            if unitInfo.MakeTradeRoute then
                traders = traders + 1;
            end
            if unitInfo.FoundCity then
                settlers = settlers + 1;
            end
        end
    end
    return builders, traders, settlers;
end

local function CollectProductionDiagnostics(player)
    local productionYield = GameInfo.Yields["YIELD_PRODUCTION"];
    if productionYield == nil then
        error("YIELD_PRODUCTION is unavailable");
    end

    local production = 0;
    for _, city in player:GetCities():Members() do
        local cityProduction = tonumber(city:GetYield(productionYield.Index));
        if cityProduction == nil then
            error("City:GetYield(PRODUCTION) returned no value");
        end
        production = production + cityProduction;
    end
    return { Production = production };
end

local function CollectQueueDiagnostics(player)
    local result = {
        Units = 0,
        Combat = 0,
        Land = 0,
        Ranged = 0,
        Siege = 0,
        Mobile = 0,
        Naval = 0,
        Air = 0,
        Districts = 0,
        Buildings = 0,
        Projects = 0,
        Idle = 0,
        Unknown = 0,
        Wonders = 0,
        Science = 0,
        Culture = 0,
        Empire = 0,
        IdleCityIDs = {}
    };
    for _, city in player:GetCities():Members() do
        local productionType = GetCurrentProductionType(city);
        if productionType == nil then
            result.Idle = result.Idle + 1;
            table.insert(result.IdleCityIDs, city:GetID());
        elseif GameInfo.Units[productionType] ~= nil then
            result.Units = result.Units + 1;
            AddMilitaryRole(result, GameInfo.Units[productionType]);
        elseif GameInfo.Districts[productionType] ~= nil then
            result.Districts = result.Districts + 1;
        elseif GameInfo.Buildings[productionType] ~= nil then
            result.Buildings = result.Buildings + 1;
            if GameInfo.Buildings[productionType].IsWonder then
                result.Wonders = result.Wonders + 1;
            end
        elseif GameInfo.Projects[productionType] ~= nil then
            result.Projects = result.Projects + 1;
        else
            result.Unknown = result.Unknown + 1;
        end
        if ProductionSupportsFocus(productionType, RELATIVE_FOCUS_SCIENCE) then
            result.Science = result.Science + 1;
        end
        if ProductionSupportsFocus(productionType, RELATIVE_FOCUS_CULTURE) then
            result.Culture = result.Culture + 1;
        end
        if ProductionSupportsFocus(productionType, RELATIVE_FOCUS_EMPIRE) then
            result.Empire = result.Empire + 1;
        end
    end
    return result;
end

local function CollectDistrictDiagnostics(player)
    local used = 0;
    local completed = 0;
    local slots = 0;
    for _, city in player:GetCities():Members() do
        slots = slots + math.floor((math.max(1, city:GetPopulation()) - 1) / 3) + 1;
    end
    local districts = player:GetDistricts();
    if districts == nil then
        error("Player:GetDistricts() is unavailable");
    end
    for _, district in districts:Members() do
        local districtInfo = GameInfo.Districts[district:GetType()];
        if districtInfo ~= nil
            and (districtInfo.RequiresPopulation == true
                or districtInfo.RequiresPopulation == 1) then
            used = used + 1;
            if district:IsComplete() then
                completed = completed + 1;
            end
        end
    end
    return { Used = used, Completed = completed, Slots = slots, OpenCities = -1 };
end

local function CollectDefenseDiagnostics(player)
    local cities = 0;
    local defendedCities = 0;
    for _, city in player:GetCities():Members() do
        cities = cities + 1;
        local cityBuildings = city:GetBuildings();
        if cityBuildings == nil or cityBuildings.HasBuilding == nil then
            error("City:GetBuildings():HasBuilding() is unavailable");
        end
        local defended = false;
        for buildingInfo in GameInfo.Buildings() do
            if (tonumber(buildingInfo.OuterDefenseHitPoints) or 0) > 0
                and cityBuildings:HasBuilding(buildingInfo.Index) then
                defended = true;
                break;
            end
        end
        if defended then
            defendedCities = defendedCities + 1;
        end
    end
    return { Cities = cities, DefendedCities = defendedCities };
end

function Diagnostics.UpdateQueueIdleHistory(player, turn, queue, queueOk)
    local result = {
        PreviousSampleTurn = -1,
        PersistentIdle = -1,
        MaximumIdleStreak = -1
    };
    if queueOk ~= 1 or queue == nil then
        return result;
    end

    local rawPreviousSampleTurn = player:GetProperty(
        Diagnostics.QUEUE_SAMPLE_TURN_PROPERTY
    );
    local previousSampleTurn = tonumber(rawPreviousSampleTurn) or -1;
    local sameSample = previousSampleTurn == turn;
    local idleCities = {};
    for _, cityID in ipairs(queue.IdleCityIDs or {}) do
        idleCities[cityID] = true;
    end

    local persistentIdle = 0;
    local maximumIdleStreak = 0;
    for _, city in player:GetCities():Members() do
        local rawLastSampleTurn = city:GetProperty(
            Diagnostics.QUEUE_IDLE_SAMPLE_TURN_PROPERTY
        );
        local lastSampleTurn = tonumber(rawLastSampleTurn) or -1;
        local rawPreviousStreak = city:GetProperty(
            Diagnostics.QUEUE_IDLE_STREAK_PROPERTY
        );
        local previousStreak = tonumber(rawPreviousStreak) or 0;
        local rawPreviousPlayer = city:GetProperty(
            Diagnostics.QUEUE_IDLE_PLAYER_PROPERTY
        );
        local previousPlayer = tonumber(rawPreviousPlayer) or -1;
        local idleStreak = 0;
        if idleCities[city:GetID()] then
            if sameSample and previousPlayer == player:GetID() then
                idleStreak = previousStreak;
            elseif previousPlayer == player:GetID()
                and lastSampleTurn == previousSampleTurn then
                idleStreak = previousStreak + 1;
            else
                idleStreak = 1;
            end
        end
        if idleStreak >= 2 then
            persistentIdle = persistentIdle + 1;
        end
        maximumIdleStreak = math.max(maximumIdleStreak, idleStreak);
        if not sameSample then
            city:SetProperty(
                Diagnostics.QUEUE_IDLE_SAMPLE_TURN_PROPERTY,
                turn
            );
            city:SetProperty(
                Diagnostics.QUEUE_IDLE_STREAK_PROPERTY,
                idleStreak
            );
            city:SetProperty(
                Diagnostics.QUEUE_IDLE_PLAYER_PROPERTY,
                player:GetID()
            );
        end
    end
    if not sameSample then
        player:SetProperty(Diagnostics.QUEUE_SAMPLE_TURN_PROPERTY, turn);
    end

    result.PreviousSampleTurn = previousSampleTurn;
    result.PersistentIdle = persistentIdle;
    result.MaximumIdleStreak = maximumIdleStreak;
    return result;
end

function Diagnostics.CollectTradeRoutes(player)
    local result = {
        Active = 0,
        Domestic = 0,
        International = 0,
        UnknownDestination = 0,
        IdleTraders = 0,
        TraderLinksOk = 1
    };
    local routedTraderIDs = {};
    for _, city in player:GetCities():Members() do
        local cityTrade = city:GetTrade();
        if cityTrade == nil or cityTrade.GetOutgoingRoutes == nil then
            error("City:GetTrade():GetOutgoingRoutes() is unavailable");
        end
        local routes = cityTrade:GetOutgoingRoutes();
        if routes == nil then
            error("City:GetTrade():GetOutgoingRoutes() returned no routes table");
        end
        for _, route in ipairs(routes) do
            result.Active = result.Active + 1;
            if route.DestinationCityPlayer == player:GetID() then
                result.Domestic = result.Domestic + 1;
            elseif route.DestinationCityPlayer == nil
                or route.DestinationCityPlayer < 0 then
                result.UnknownDestination = result.UnknownDestination + 1;
            else
                result.International = result.International + 1;
            end
            if route.TraderUnitID ~= nil and route.TraderUnitID >= 0 then
                routedTraderIDs[route.TraderUnitID] = true;
            else
                result.TraderLinksOk = 0;
            end
        end
    end
    if result.TraderLinksOk == 1 then
        for _, unit in player:GetUnits():Members() do
            local unitInfo = GameInfo.Units[unit:GetType()];
            if unitInfo ~= nil and unitInfo.MakeTradeRoute
                and not routedTraderIDs[unit:GetID()] then
                result.IdleTraders = result.IdleTraders + 1;
            end
        end
    else
        result.IdleTraders = -1;
    end
    return result;
end

function Diagnostics.GetCultureBuildingRoles()
    if Diagnostics.CultureBuildingRoles ~= nil then
        return Diagnostics.CultureBuildingRoles;
    end
    local roles = {};
    for buildingInfo in GameInfo.Buildings() do
        if buildingInfo.IsWonder ~= true and buildingInfo.IsWonder ~= 1 then
            if IsBuildingRole(
                buildingInfo.BuildingType,
                "BUILDING_MONUMENT"
            ) then
                table.insert(roles, {
                    Index = buildingInfo.Index,
                    Monument = true
                });
            elseif IsDistrictRole(
                buildingInfo.PrereqDistrict,
                "DISTRICT_THEATER"
            ) then
                table.insert(roles, {
                    Index = buildingInfo.Index,
                    Monument = false
                });
            end
        end
    end
    Diagnostics.CultureBuildingRoles = roles;
    return roles;
end

function Diagnostics.CollectCultureInfrastructure(player)
    local result = {
        Theaters = 0,
        Monuments = 0,
        TheaterBuildings = 0
    };
    local districts = player:GetDistricts();
    if districts == nil then
        error("Player:GetDistricts() is unavailable");
    end
    for _, district in districts:Members() do
        local districtInfo = GameInfo.Districts[district:GetType()];
        if districtInfo ~= nil
            and IsDistrictRole(districtInfo.DistrictType, "DISTRICT_THEATER")
            and district:IsComplete() then
            result.Theaters = result.Theaters + 1;
        end
    end

    local buildingRoles = Diagnostics.GetCultureBuildingRoles();
    for _, city in player:GetCities():Members() do
        local cityBuildings = city:GetBuildings();
        if cityBuildings == nil or cityBuildings.HasBuilding == nil then
            error("City:GetBuildings():HasBuilding() is unavailable");
        end
        for _, role in ipairs(buildingRoles) do
            if cityBuildings:HasBuilding(role.Index) then
                if role.Monument then
                    result.Monuments = result.Monuments + 1;
                else
                    result.TheaterBuildings = result.TheaterBuildings + 1;
                end
            end
        end
    end
    return result;
end

function Diagnostics.CollectCultureQueue(player)
    local result = {
        Districts = 0,
        Monuments = 0,
        Buildings = 0,
        Projects = 0,
        Total = 0
    };
    for _, city in player:GetCities():Members() do
        local productionType = GetCurrentProductionType(city);
        local districtInfo = productionType ~= nil
            and GameInfo.Districts[productionType] or nil;
        local buildingInfo = productionType ~= nil
            and GameInfo.Buildings[productionType] or nil;
        local projectInfo = productionType ~= nil
            and GameInfo.Projects[productionType] or nil;
        if districtInfo ~= nil
            and IsDistrictRole(productionType, "DISTRICT_THEATER") then
            result.Districts = result.Districts + 1;
        elseif buildingInfo ~= nil
            and IsBuildingRole(productionType, "BUILDING_MONUMENT") then
            result.Monuments = result.Monuments + 1;
        elseif buildingInfo ~= nil
            and IsDistrictRole(
                buildingInfo.PrereqDistrict,
                "DISTRICT_THEATER"
            ) then
            result.Buildings = result.Buildings + 1;
        elseif projectInfo ~= nil
            and IsDistrictRole(
                projectInfo.PrereqDistrict,
                "DISTRICT_THEATER"
            ) then
            result.Projects = result.Projects + 1;
        end
    end
    result.Total = result.Districts
        + result.Monuments
        + result.Buildings
        + result.Projects;
    return result;
end

function Diagnostics.CollectCulturalGreatPeople(player)
    local greatPeoplePoints = player:GetGreatPeoplePoints();
    if greatPeoplePoints == nil
        or greatPeoplePoints.GetPointsPerTurn == nil
        or greatPeoplePoints.GetPointsTotal == nil then
        error("Player:GetGreatPeoplePoints() diagnostics are unavailable");
    end
    local result = { PerTurn = 0, Balance = 0 };
    for _, classType in ipairs({
        "GREAT_PERSON_CLASS_WRITER",
        "GREAT_PERSON_CLASS_ARTIST",
        "GREAT_PERSON_CLASS_MUSICIAN"
    }) do
        local classInfo = GameInfo.GreatPersonClasses[classType];
        if classInfo ~= nil then
            result.PerTurn = result.PerTurn
                + (tonumber(greatPeoplePoints:GetPointsPerTurn(
                    classInfo.Index
                )) or 0);
            result.Balance = result.Balance
                + (tonumber(greatPeoplePoints:GetPointsTotal(
                    classInfo.Index
                )) or 0);
        end
    end
    return result;
end

function Diagnostics.GetUnitAiTypes()
    if Diagnostics.UnitAiTypes ~= nil then
        return Diagnostics.UnitAiTypes;
    end
    local unitAiTypes = {};
    for row in GameInfo.UnitAiInfos() do
        unitAiTypes[row.UnitType] = unitAiTypes[row.UnitType] or {};
        unitAiTypes[row.UnitType][row.AiType] = true;
    end
    Diagnostics.UnitAiTypes = unitAiTypes;
    return unitAiTypes;
end

function Diagnostics.AddAssaultRoles(result, prefix, unitType)
    local unitAiTypes = Diagnostics.GetUnitAiTypes()[unitType] or {};
    if unitAiTypes.UNITTYPE_RANGED then
        result[prefix .. "Ranged"] = result[prefix .. "Ranged"] + 1;
    end
    if unitAiTypes.UNITTYPE_SIEGE_ALL then
        result[prefix .. "WallBreakers"] =
            result[prefix .. "WallBreakers"] + 1;
    end
    if unitAiTypes.UNITTYPE_AIR_SIEGE then
        result[prefix .. "AirSiege"] = result[prefix .. "AirSiege"] + 1;
    end
end

function Diagnostics.CollectAssaultRoles(player)
    local result = {
        FieldedRanged = 0,
        FieldedWallBreakers = 0,
        FieldedAirSiege = 0,
        QueuedRanged = 0,
        QueuedWallBreakers = 0,
        QueuedAirSiege = 0
    };
    for _, unit in player:GetUnits():Members() do
        local unitInfo = GameInfo.Units[unit:GetType()];
        if unitInfo ~= nil then
            Diagnostics.AddAssaultRoles(
                result,
                "Fielded",
                unitInfo.UnitType
            );
        end
    end
    for _, city in player:GetCities():Members() do
        local productionType = GetCurrentProductionType(city);
        local unitInfo = productionType ~= nil
            and GameInfo.Units[productionType] or nil;
        if unitInfo ~= nil then
            Diagnostics.AddAssaultRoles(
                result,
                "Queued",
                unitInfo.UnitType
            );
        end
    end
    return result;
end

local function CountWarsByOpponentType(playerID, player)
    local majorWars = 0;
    local minorWars = 0;
    local majorOpponents = {};
    local diplomacy = player:GetDiplomacy();
    for _, otherID in ipairs(PlayerManager.GetAliveIDs()) do
        local otherPlayer = Players[otherID];
        if otherID ~= playerID
            and otherPlayer ~= nil
            and not otherPlayer:IsBarbarian()
            and diplomacy:IsAtWarWith(otherID) then
            if otherPlayer:IsMajor() then
                majorWars = majorWars + 1;
                table.insert(majorOpponents, otherID);
            else
                minorWars = minorWars + 1;
            end
        end
    end
    return majorWars, minorWars, majorOpponents;
end

local function HasNearbyEnemyCity(player, opponent, maximumDistance)
    for _, city in player:GetCities():Members() do
        for _, enemyCity in opponent:GetCities():Members() do
            local distance = Map.GetPlotDistance(
                city:GetX(),
                city:GetY(),
                enemyCity:GetX(),
                enemyCity:GetY()
            );
            if distance <= maximumDistance then
                return true;
            end
        end
    end
    return false;
end

local function CountActiveMajorWars(player, majorOpponents, turn)
    local activeWars = 0;
    local frontDistance = math.max(
        1,
        GetNumberParameter("ASAI_WAR_FRONT_CITY_DISTANCE", 12)
    );
    for _, opponentID in ipairs(majorOpponents) do
        local opponent = Players[opponentID];
        if opponent ~= nil and HasNearbyEnemyCity(player, opponent, frontDistance) then
            activeWars = activeWars + 1;
        end
    end

    local rawLastCombatTurn = player:GetProperty(LAST_MAJOR_COMBAT_TURN_PROPERTY);
    local lastCombatTurn = tonumber(rawLastCombatTurn) or -100000;
    local recentWindow = ScaleStandardTurns(
        GetNumberParameter("ASAI_WAR_RECENT_COMBAT_STANDARD", 8)
    );
    if activeWars == 0
        and #majorOpponents > 0
        and turn - lastCombatTurn <= recentWindow then
        activeWars = 1;
    end
    return activeWars, lastCombatTurn;
end

local function GetSnapshot(playerID)
    local turn = Game.GetCurrentGameTurn();
    local cached = m_Snapshots[playerID];
    if cached ~= nil and cached.Turn == turn then
        return cached;
    end

    local player = Players[playerID];
    local cities = 0;
    local capturedCities = 0;
    local population = 0;
    for _, city in player:GetCities():Members() do
        cities = cities + 1;
        if city:GetOriginalOwner() ~= playerID then
            capturedCities = capturedCities + 1;
        end
        population = population + city:GetPopulation();
    end

    local builders, traders, settlers = CountUnits(player);
    local inFlightBuilders = 0;
    local inFlightTraders = 0;
    local inFlightSettlers = 0;
    local queueSuccess, queueBuilders, queueTraders, queueSettlers = pcall(
        CountInFlightUnits,
        player
    );
    if queueSuccess then
        inFlightBuilders = queueBuilders;
        inFlightTraders = queueTraders;
        inFlightSettlers = queueSettlers;
    elseif m_ConditionErrors.ASAI_CountInFlightUnits == nil then
        print(string.format(
            "ASAI_ERROR condition=ASAI_CountInFlightUnits player=%s fallback=zeros error=%s",
            tostring(playerID),
            tostring(queueBuilders)
        ));
        m_ConditionErrors.ASAI_CountInFlightUnits = true;
    end
    local ownedPlots, improvements = CountOwnedPlots(playerID);
    local majorWars, minorWars, majorOpponents = CountWarsByOpponentType(
        playerID,
        player
    );
    local activeMajorWars, lastMajorCombatTurn = CountActiveMajorWars(
        player,
        majorOpponents,
        turn
    );
    local trade = player:GetTrade();
    local treasury = player:GetTreasury();
    local snapshot = {
        Turn = turn,
        Cities = cities,
        CapturedCities = capturedCities,
        Population = population,
        OwnedPlots = ownedPlots,
        Improvements = improvements,
        Builders = builders,
        Traders = traders,
        Settlers = settlers,
        InFlightBuilders = inFlightBuilders,
        InFlightTraders = inFlightTraders,
        InFlightSettlers = inFlightSettlers,
        RouteCapacity = trade:GetOutgoingRouteCapacity(),
        GoldBalance = treasury:GetGoldBalance(),
        NetGold = treasury:GetGoldYield() - treasury:GetTotalMaintenance(),
        Wars = majorWars + minorWars,
        MajorWars = majorWars,
        MajorOpponents = majorOpponents,
        ActiveMajorWars = activeMajorWars,
        LastMajorCombatTurn = lastMajorCombatTurn,
        MajorCombatEvents = Strategic.GetRuntimeCounter(
            player,
            Strategic.MAJOR_COMBAT_EVENTS_PROPERTY
        ),
        MajorCaptureEvents = Strategic.GetRuntimeCounter(
            player,
            Strategic.MAJOR_CAPTURE_EVENTS_PROPERTY
        ),
        MajorPillageEvents = Strategic.GetRuntimeCounter(
            player,
            Strategic.MAJOR_PILLAGE_EVENTS_PROPERTY
        ),
        MinorWars = minorWars,
        Era = player:GetEra()
    };
    m_Snapshots[playerID] = snapshot;
    return snapshot;
end

local function GetInfrastructureTarget(snapshot)
    local perCity = GetNumberParameter("ASAI_INFRA_IMPROVEMENTS_PER_CITY_X100", 200);
    local perPopulation = GetNumberParameter("ASAI_INFRA_IMPROVEMENTS_PER_POP_X100", 65);
    local ownedPlotsCap = GetNumberParameter("ASAI_INFRA_OWNED_PLOTS_CAP_X100", 30);
    local cityFloor = snapshot.Cities * perCity / 100;
    local populationTarget = snapshot.Population * perPopulation / 100;
    local landCap = snapshot.OwnedPlots * ownedPlotsCap / 100;
    return math.ceil(math.max(cityFloor, math.min(populationTarget, landCap)));
end

local function GetBuilderCoverage(snapshot)
    local builderCredit = GetNumberParameter("ASAI_INFRA_BUILDER_CREDIT", 2);
    return snapshot.Improvements
        + (snapshot.Builders + snapshot.InFlightBuilders) * builderCredit;
end

local function GetEconomicSnapshot(playerID)
    local turn = Game.GetCurrentGameTurn();
    local cached = m_EconomicSnapshots[playerID];
    if cached ~= nil and cached.Turn == turn then
        return cached;
    end

    local player = Players[playerID];
    local snapshot = GetSnapshot(playerID);
    local production, productionOk = TryDiagnosticSensor(
        "production",
        function() return CollectProductionDiagnostics(player); end
    );
    local queue, queueOk = TryDiagnosticSensor(
        "production_queue",
        function() return CollectQueueDiagnostics(player); end
    );
    local districts, districtOk = TryDiagnosticSensor(
        "district_capacity",
        function() return CollectDistrictDiagnostics(player); end
    );

    production = production or { Production = -1 };
    queue = queue or {
        Units = -1,
        Combat = -1,
        Land = -1,
        Ranged = -1,
        Siege = -1,
        Mobile = -1,
        Naval = -1,
        Air = -1,
        Districts = -1,
        Buildings = -1,
        Projects = -1,
        Idle = -1,
        Unknown = -1,
        Wonders = -1,
        Science = -1,
        Culture = -1,
        Empire = -1,
        IdleCityIDs = {}
    };
    districts = districts or {
        Used = -1,
        Completed = -1,
        Slots = -1,
        OpenCities = -1
    };

    local infrastructureTarget = GetInfrastructureTarget(snapshot);
    local reserve = snapshot.Cities
        * GetNumberParameter("ASAI_GOLD_RESERVE_PER_CITY", 15);
    local goldSurplus = math.max(0, snapshot.GoldBalance - reserve);
    local result = {
        Turn = turn,
        Production = production.Production,
        ProductionPerCity = productionOk == 1 and snapshot.Cities > 0
            and production.Production / snapshot.Cities or -1,
        ProductionPerPopulation = productionOk == 1 and snapshot.Population > 0
            and production.Production / snapshot.Population or -1,
        Queue = queue,
        Districts = districts,
        DistrictUtilization = districtOk == 1 and districts.Slots > 0
            and districts.Used / districts.Slots or -1,
        RouteCoverage = snapshot.RouteCapacity > 0
            and math.min(snapshot.Traders, snapshot.RouteCapacity)
                / snapshot.RouteCapacity or -1,
        RoutePipelineCoverage = snapshot.RouteCapacity > 0
            and math.min(
                snapshot.Traders + snapshot.InFlightTraders,
                snapshot.RouteCapacity
            ) / snapshot.RouteCapacity or -1,
        ImprovementCoverage = infrastructureTarget > 0
            and snapshot.Improvements / infrastructureTarget or -1,
        ImprovementPipelineCoverage = infrastructureTarget > 0
            and GetBuilderCoverage(snapshot) / infrastructureTarget or -1,
        ImprovedLand = snapshot.OwnedPlots > 0
            and snapshot.Improvements / snapshot.OwnedPlots or -1,
        GoldReserve = reserve,
        GoldSurplus = goldSurplus,
        GoldPerCity = snapshot.Cities > 0
            and snapshot.GoldBalance / snapshot.Cities or -1,
        ProductionOk = productionOk,
        QueueOk = queueOk,
        DistrictOk = districtOk,
        ResourceSupported = -1,
        UpgradeSupported = -1
    };
    m_EconomicSnapshots[playerID] = result;
    return result;
end

local function GetHumanEconomicReference()
    local turn = Game.GetCurrentGameTurn();
    if m_HumanEconomicReference.Turn == turn then
        return m_HumanEconomicReference.Value;
    end

    local production = 0;
    local productionPerCity = 0;
    local humans = 0;
    for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
        local player = Players[playerID];
        if player ~= nil and player:IsHuman() then
            local economic = GetEconomicSnapshot(playerID);
            if economic.ProductionOk == 1 then
                production = production + economic.Production;
                productionPerCity = productionPerCity + economic.ProductionPerCity;
                humans = humans + 1;
            end
        end
    end
    if humans == 0 then
        m_HumanEconomicReference = { Turn = turn, Value = nil };
        return nil;
    end

    local result = {
        Production = production / humans,
        ProductionPerCity = productionPerCity / humans
    };
    m_HumanEconomicReference = { Turn = turn, Value = result };
    return result;
end

local function GetDiagnosticRatio(numerator, denominator)
    if numerator == nil or numerator < 0 or denominator == nil or denominator <= 0 then
        return -1;
    end
    return numerator / denominator;
end

local function GetMaximumSettlersInFlight(snapshot, scaleRecovery)
    local citiesPerSettler = math.max(
        1,
        GetNumberParameter("ASAI_EXPANSION_CITIES_PER_INFLIGHT_SETTLER", 8)
    );
    local baseline = math.max(1, math.ceil(snapshot.Cities / citiesPerSettler));
    if not scaleRecovery then
        return baseline;
    end
    local bonus = math.max(
        0,
        GetNumberParameter("ASAI_SCALE_RECOVERY_SETTLER_BONUS", 1)
    );
    local recoveryCap = math.max(
        1,
        GetNumberParameter("ASAI_SCALE_RECOVERY_SETTLER_CAP", 3)
    );
    return math.max(baseline, math.min(recoveryCap, baseline + bonus));
end

local function GetTradeCapacityTarget(snapshot)
    local citiesPerCapacity = math.max(
        1,
        GetNumberParameter("ASAI_TRADE_CITIES_PER_CAPACITY", 2)
    );
    return snapshot.Cities > 0
        and math.max(1, math.ceil(snapshot.Cities / citiesPerCapacity))
        or 0;
end

local function IsBuilderBudgetReachedSnapshot(snapshot)
    local startTurn = ScaleStandardTurns(
        GetNumberParameter("ASAI_INFRA_START_TURN_STANDARD", 20)
    );
    return snapshot.Turn >= startTurn
        and snapshot.Population > 0
        and GetBuilderCoverage(snapshot) >= GetInfrastructureTarget(snapshot);
end

local function IsTraderBudgetReachedSnapshot(snapshot)
    return snapshot.RouteCapacity <= snapshot.Traders + snapshot.InFlightTraders;
end

local function IsSettlerBudgetReachedSnapshot(snapshot, scaleRecovery)
    return snapshot.Cities > 0
        and snapshot.Settlers + snapshot.InFlightSettlers
            >= GetMaximumSettlersInFlight(snapshot, scaleRecovery);
end

local function IsInfrastructureRecovery(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    local snapshot = GetSnapshot(playerID);
    local startTurn = ScaleStandardTurns(
        GetNumberParameter("ASAI_INFRA_START_TURN_STANDARD", 20)
    );
    if snapshot.Turn < startTurn or snapshot.Population <= 0 then
        return false;
    end
    return GetBuilderCoverage(snapshot) < GetInfrastructureTarget(snapshot);
end
function ASAI_IsInfrastructureRecovery(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsInfrastructureRecovery",
        IsInfrastructureRecovery,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsInfrastructureRecovery.Add(ASAI_IsInfrastructureRecovery);

local function IsOpeningExpansion(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    local snapshot = GetSnapshot(playerID);
    local modern = GameInfo.Eras["ERA_MODERN"];
    if modern ~= nil and snapshot.Era >= modern.Index then
        return false;
    end
    local endTurn = ScaleStandardTurns(
        GetNumberParameter("ASAI_OPENING_EXPANSION_END_STANDARD", 70)
    );
    local cityTarget = math.max(
        2,
        GetNumberParameter("ASAI_OPENING_EXPANSION_CITY_TARGET", 4)
    );
    local coordinatorStart = ScaleStandardTurns(
        GetNumberParameter("ASAI_RELATIVE_START_TURN_STANDARD", 35)
    );
    if snapshot.Turn >= coordinatorStart then
        local state = GetRelativeState(playerID);
        if state.StrategicPlan ~= Strategic.EXPAND then
            return false;
        end
    end
    return snapshot.Turn < endTurn
        and snapshot.ActiveMajorWars <= 0
        and snapshot.Cities > 0
        and snapshot.Cities < cityTarget;
end
function ASAI_IsOpeningExpansion(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsOpeningExpansion",
        IsOpeningExpansion,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsOpeningExpansion.Add(ASAI_IsOpeningExpansion);

local function IsTradeRecovery(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    local snapshot = GetSnapshot(playerID);
    -- Active routes still own trader units; current production covers pending gaps.
    return snapshot.RouteCapacity > snapshot.Traders + snapshot.InFlightTraders;
end
function ASAI_IsTradeRecovery(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsTradeRecovery",
        IsTradeRecovery,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsTradeRecovery.Add(ASAI_IsTradeRecovery);

local function IsTradeCapacityRecovery(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    local snapshot = GetSnapshot(playerID);
    local startTurn = ScaleStandardTurns(
        GetNumberParameter("ASAI_TRADE_CAPACITY_START_STANDARD", 35)
    );
    return snapshot.Turn >= startTurn
        and snapshot.RouteCapacity < GetTradeCapacityTarget(snapshot);
end
function ASAI_IsTradeCapacityRecovery(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsTradeCapacityRecovery",
        IsTradeCapacityRecovery,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsTradeCapacityRecovery.Add(ASAI_IsTradeCapacityRecovery);

local function IsBuilderBudgetReached(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    return IsBuilderBudgetReachedSnapshot(GetSnapshot(playerID));
end
function ASAI_IsBuilderBudgetReached(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsBuilderBudgetReached",
        IsBuilderBudgetReached,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsBuilderBudgetReached.Add(ASAI_IsBuilderBudgetReached);

local function IsTraderBudgetReached(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    return IsTraderBudgetReachedSnapshot(GetSnapshot(playerID));
end
function ASAI_IsTraderBudgetReached(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsTraderBudgetReached",
        IsTraderBudgetReached,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsTraderBudgetReached.Add(ASAI_IsTraderBudgetReached);

local function IsSettlerBudgetReached(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    local player = Players[playerID];
    local rawScaleExpansion = player:GetProperty(SCALE_EXPANSION_ALLOWED_PROPERTY);
    local snapshot = GetSnapshot(playerID);
    local state = GetRelativeState(playerID);
    local expansionUnavailable = state.ExpansionPlanAllowed ~= 1
        and (state.ExpansionPhase == Strategic.EXPANSION_CLOSED
            or snapshot.Turn < state.ExpansionBlockedUntil);
    if expansionUnavailable then
        return true;
    end
    local scaleExpansion = GetNumberParameter(
        "ASAI_RELATIVE_PACING_ENABLED",
        1
    ) == 1
        and tonumber(rawScaleExpansion) == 1
        and snapshot.ActiveMajorWars <= 0;
    return IsSettlerBudgetReachedSnapshot(snapshot, scaleExpansion);
end
function ASAI_IsSettlerBudgetReached(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsSettlerBudgetReached",
        IsSettlerBudgetReached,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsSettlerBudgetReached.Add(ASAI_IsSettlerBudgetReached);

local function IsGoldRecovery(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    local snapshot = GetSnapshot(playerID);
    local reservePerCity = GetNumberParameter("ASAI_GOLD_RESERVE_PER_CITY", 15);
    return snapshot.NetGold < 0 and snapshot.GoldBalance < snapshot.Cities * reservePerCity;
end
function ASAI_IsGoldRecovery(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsGoldRecovery",
        IsGoldRecovery,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsGoldRecovery.Add(ASAI_IsGoldRecovery);

local function IsWarMobilization(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    local snapshot = GetSnapshot(playerID);
    local coordinatorStart = ScaleStandardTurns(
        GetNumberParameter("ASAI_RELATIVE_START_TURN_STANDARD", 35)
    );
    return snapshot.ActiveMajorWars > 0
        and (snapshot.Turn < coordinatorStart
            or GetRelativeState(playerID).StrategicPlan == Strategic.WAR);
end
function ASAI_IsWarMobilization(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsWarMobilization",
        IsWarMobilization,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsWarMobilization.Add(ASAI_IsWarMobilization);

local function IsLateGame(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    local modern = GameInfo.Eras["ERA_MODERN"];
    return modern ~= nil and GetSnapshot(playerID).Era >= modern.Index;
end
function ASAI_IsLateGame(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsLateGame",
        IsLateGame,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsLateGame.Add(ASAI_IsLateGame);

local function CountResearched(player)
    local techs = 0;
    local civics = 0;
    local playerTechs = player:GetTechs();
    local playerCulture = player:GetCulture();
    for tech in GameInfo.Technologies() do
        if playerTechs:HasTech(tech.Index) then
            techs = techs + 1;
        end
    end
    for civic in GameInfo.Civics() do
        if playerCulture:HasCivic(civic.Index) then
            civics = civics + 1;
        end
    end
    return techs, civics;
end

local function EstimateMilitaryStrength(player)
    local strength = 0;
    local profile = {
        Combat = 0,
        Land = 0,
        Ranged = 0,
        Siege = 0,
        Mobile = 0,
        Naval = 0,
        Air = 0
    };
    for _, unit in player:GetUnits():Members() do
        local unitInfo = GameInfo.Units[unit:GetType()];
        if unitInfo ~= nil then
            strength = strength + GetUnitBaseStrength(unitInfo);
            AddMilitaryRole(profile, unitInfo);
        end
    end
    return strength, profile;
end

local function GetStrengthSnapshot(playerID)
    local turn = Game.GetCurrentGameTurn();
    local cached = m_StrengthSnapshots[playerID];
    if cached ~= nil and cached.Turn == turn then
        return cached;
    end

    local player = Players[playerID];
    local cities = 0;
    local population = 0;
    for _, city in player:GetCities():Members() do
        cities = cities + 1;
        population = population + city:GetPopulation();
    end

    local techs, civics = CountResearched(player);
    local military, profile = EstimateMilitaryStrength(player);
    local snapshot = {
        Turn = turn,
        Techs = techs,
        Civics = civics,
        Science = math.max(0, player:GetTechs():GetScienceYield()),
        Culture = math.max(0, player:GetCulture():GetCultureYield()),
        Cities = cities,
        Population = population,
        Military = military,
        CombatUnits = profile.Combat,
        LandCombatUnits = profile.Land,
        RangedUnits = profile.Ranged,
        SiegeUnits = profile.Siege,
        MobileUnits = profile.Mobile,
        NavalUnits = profile.Naval,
        AirUnits = profile.Air
    };
    m_StrengthSnapshots[playerID] = snapshot;
    return snapshot;
end

function Strategic.GetPercentile(values, percentile)
    if #values == 0 then
        return 0;
    end
    table.sort(values);
    local index = math.max(
        1,
        math.min(#values, math.ceil(#values * percentile))
    );
    return values[index];
end

function Strategic.GetWorldReference()
    local turn = Game.GetCurrentGameTurn();
    if m_WorldReference.Turn == turn then
        return m_WorldReference.Value;
    end

    local samples = {};
    for _, component in ipairs(RELATIVE_COMPONENTS) do
        samples[component.Key] = {};
    end
    local eras = {};
    for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
        local player = Players[playerID];
        if player ~= nil then
            local strength = GetStrengthSnapshot(playerID);
            table.insert(eras, player:GetEra());
            for _, component in ipairs(RELATIVE_COMPONENTS) do
                table.insert(samples[component.Key], strength[component.Key]);
            end
        end
    end

    if #eras == 0 then
        m_WorldReference = { Turn = turn, Value = nil };
        return nil;
    end

    local reference = { Median = {}, Upper = {} };
    for _, component in ipairs(RELATIVE_COMPONENTS) do
        local key = component.Key;
        reference.Median[key] = Strategic.GetPercentile(samples[key], 0.50);
        reference.Upper[key] = Strategic.GetPercentile(samples[key], 0.75);
    end
    reference.Median.Era = Strategic.GetPercentile(eras, 0.50);
    reference.Upper.Era = Strategic.GetPercentile(eras, 0.75);
    m_WorldReference = { Turn = turn, Value = reference };
    return reference;
end

function Strategic.GetCompetitiveReference(humanStrength, worldStrength)
    local reference = { Era = humanStrength.Era };
    for _, component in ipairs(RELATIVE_COMPONENTS) do
        local key = component.Key;
        reference[key] = math.max(
            humanStrength[key] or 0,
            worldStrength[key] or 0
        );
    end
    reference.Era = math.max(humanStrength.Era or 0, worldStrength.Era or 0);
    return reference;
end

local function GetHumanReference()
    local turn = Game.GetCurrentGameTurn();
    if m_HumanReference.Turn == turn then
        return m_HumanReference.Value;
    end

    local total = {
        Techs = 0,
        Civics = 0,
        Science = 0,
        Culture = 0,
        Cities = 0,
        Population = 0,
        Military = 0,
        Era = 0
    };
    local humans = 0;
    for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
        local player = Players[playerID];
        if player ~= nil and player:IsHuman() then
            local strength = GetStrengthSnapshot(playerID);
            humans = humans + 1;
            total.Era = total.Era + player:GetEra();
            for _, component in ipairs(RELATIVE_COMPONENTS) do
                total[component.Key] = total[component.Key] + strength[component.Key];
            end
        end
    end

    if humans == 0 then
        m_HumanReference = { Turn = turn, Value = nil };
        return nil;
    end

    for _, component in ipairs(RELATIVE_COMPONENTS) do
        total[component.Key] = total[component.Key] / humans;
    end
    total.Era = total.Era / humans;
    m_HumanReference = { Turn = turn, Value = total };
    return total;
end

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value));
end

local function GetWeightedScore(ratios, weights, componentKeys)
    local weightedScore = 0;
    local totalWeight = 0;
    for _, key in ipairs(componentKeys) do
        local weight = weights[key] or 0;
        weightedScore = weightedScore + (ratios[key] or 1) * weight;
        totalWeight = totalWeight + weight;
    end
    if totalWeight <= 0 then
        return 1;
    end
    return weightedScore / totalWeight;
end

local function GetRelativeMeasurements(aiStrength, humanStrength)
    local minimum = GetNumberParameter("ASAI_RELATIVE_COMPONENT_MIN_X100", 55) / 100;
    local maximum = GetNumberParameter("ASAI_RELATIVE_COMPONENT_MAX_X100", 145) / 100;
    local militaryMaximum = GetNumberParameter("ASAI_RELATIVE_MILITARY_MAX_X100", 120) / 100;
    militaryMaximum = Clamp(militaryMaximum, minimum, maximum);
    local rawRatios = {};
    local controlledRatios = {};
    local weights = {};
    local allKeys = {};

    for _, component in ipairs(RELATIVE_COMPONENTS) do
        local humanValue = humanStrength[component.Key];
        local ratio = 1;
        local weight = math.max(0, GetNumberParameter(component.Parameter, component.Weight));
        if humanValue > 0 then
            ratio = aiStrength[component.Key] / humanValue;
        end
        local componentMaximum = maximum;
        if component.Key == "Military" then
            componentMaximum = militaryMaximum;
        end
        rawRatios[component.Key] = ratio;
        controlledRatios[component.Key] = Clamp(ratio, minimum, componentMaximum);
        weights[component.Key] = weight;
        table.insert(allKeys, component.Key);
    end

    return {
        Raw = {
            Overall = GetWeightedScore(rawRatios, weights, allKeys),
            Science = GetWeightedScore(rawRatios, weights, RELATIVE_PILLARS.Science),
            Culture = GetWeightedScore(rawRatios, weights, RELATIVE_PILLARS.Culture),
            Empire = GetWeightedScore(rawRatios, weights, RELATIVE_PILLARS.Empire),
            Military = GetWeightedScore(rawRatios, weights, RELATIVE_PILLARS.Military)
        },
        Controlled = {
            Overall = GetWeightedScore(controlledRatios, weights, allKeys),
            Science = GetWeightedScore(controlledRatios, weights, RELATIVE_PILLARS.Science),
            Culture = GetWeightedScore(controlledRatios, weights, RELATIVE_PILLARS.Culture),
            Empire = GetWeightedScore(controlledRatios, weights, RELATIVE_PILLARS.Empire),
            Military = GetWeightedScore(controlledRatios, weights, RELATIVE_PILLARS.Military)
        },
        RawRatios = rawRatios,
        ControlledRatios = controlledRatios
    };
end

local function GetStoredNumber(player, propertyName, fallback)
    local rawValue = player:GetProperty(propertyName);
    local value = tonumber(rawValue);
    if value == nil then
        return fallback;
    end
    return value;
end

function ScienceExecution.GetStageName(stage)
    if stage == ScienceExecution.SATELLITE then
        return "satellite";
    end
    if stage == ScienceExecution.MOON then
        return "moon";
    end
    if stage == ScienceExecution.MARS then
        return "mars";
    end
    if stage == ScienceExecution.EXOPLANET then
        return "exoplanet";
    end
    return "none";
end

function ScienceExecution.GetProjectCount(player, projectType)
    local rawCount = player:GetProperty(
        ScienceExecution.COUNT_PROPERTY_PREFIX .. projectType
    );
    local count = tonumber(rawCount);
    return count ~= nil and math.max(0, math.floor(count)) or 0;
end

function ScienceExecution.SetProjectCountAtLeast(player, projectType, minimum)
    local propertyName = ScienceExecution.COUNT_PROPERTY_PREFIX .. projectType;
    local current = ScienceExecution.GetProjectCount(player, projectType);
    if current < minimum then
        player:SetProperty(propertyName, minimum);
    end
end

function ScienceExecution.SeedCountsThroughStage(player, stage)
    local maximum = math.min(stage, ScienceExecution.EXOPLANET);
    for completedStage = ScienceExecution.SATELLITE, maximum do
        local projectType = ScienceExecution.STAGE_PROJECTS[completedStage];
        if projectType ~= nil then
            ScienceExecution.SetProjectCountAtLeast(player, projectType, 1);
        end
    end
end

function ScienceExecution.GetCompletedSpaceports(player)
    local districts = player:GetDistricts();
    if districts == nil then
        error("Player:GetDistricts() is unavailable");
    end
    local completed = 0;
    for _, district in districts:Members() do
        local districtInfo = GameInfo.Districts[district:GetType()];
        if districtInfo ~= nil
            and districtInfo.DistrictType == "DISTRICT_SPACEPORT"
            and district:IsComplete() then
            completed = completed + 1;
        end
    end
    return completed;
end

function ScienceExecution.GetQueueState(player)
    local activeProjects = 0;
    local inFlightSpaceports = 0;
    local currentProject = "none";
    local inferredStage = ScienceExecution.NONE;
    for _, city in player:GetCities():Members() do
        local productionType = GetCurrentProductionType(city);
        local projectInfo = productionType ~= nil
            and GameInfo.Projects[productionType] or nil;
        if projectInfo ~= nil
            and (projectInfo.SpaceRace == true or projectInfo.SpaceRace == 1) then
            activeProjects = activeProjects + 1;
            if currentProject == "none" then
                currentProject = projectInfo.ProjectType;
            end
            local projectStage = ScienceExecution.PROJECT_STAGES[
                projectInfo.ProjectType
            ];
            if projectStage ~= nil then
                local prerequisiteStage = projectInfo.ProjectType
                        == ScienceExecution.PROJECTS.OrbitalLaser
                    or projectInfo.ProjectType
                        == ScienceExecution.PROJECTS.TerrestrialLaser;
                prerequisiteStage = prerequisiteStage
                    and ScienceExecution.EXOPLANET
                    or math.max(ScienceExecution.NONE, projectStage - 1);
                inferredStage = math.max(inferredStage, prerequisiteStage);
            end
        elseif productionType == "DISTRICT_SPACEPORT" then
            inFlightSpaceports = inFlightSpaceports + 1;
        end
    end
    return activeProjects, currentProject, inFlightSpaceports, inferredStage;
end

function ScienceExecution.GetLegacyAvailableStage(player)
    local candidates = {
        {
            Project = ScienceExecution.PROJECTS.OrbitalLaser,
            Stage = ScienceExecution.EXOPLANET
        },
        {
            Project = ScienceExecution.PROJECTS.TerrestrialLaser,
            Stage = ScienceExecution.EXOPLANET
        },
        {
            Project = ScienceExecution.PROJECTS.Exoplanet,
            Stage = ScienceExecution.MARS
        },
        {
            Project = ScienceExecution.PROJECTS.Mars,
            Stage = ScienceExecution.MOON
        },
        {
            Project = ScienceExecution.PROJECTS.Moon,
            Stage = ScienceExecution.SATELLITE
        }
    };
    for _, city in player:GetCities():Members() do
        local buildQueue = city:GetBuildQueue();
        if buildQueue ~= nil and buildQueue.CanProduce ~= nil then
            for _, candidate in ipairs(candidates) do
                local projectInfo = GameInfo.Projects[candidate.Project];
                if projectInfo ~= nil and projectInfo.Hash ~= nil then
                    local success, canProduce = pcall(
                        buildQueue.CanProduce,
                        buildQueue,
                        projectInfo.Hash,
                        true
                    );
                    if not success then
                        return ScienceExecution.NONE, 0;
                    end
                    if canProduce then
                        return candidate.Stage, 1;
                    end
                end
            end
        end
    end
    return ScienceExecution.NONE, 1;
end

function ScienceExecution.CountFrontierTechs(player)
    local technologies = player:GetTechs();
    local completed = 0;
    for _, technologyType in ipairs(ScienceExecution.FRONTIER_TECHS) do
        local technologyInfo = GameInfo.Technologies[technologyType];
        if technologyInfo ~= nil and technologies:HasTech(technologyInfo.Index) then
            completed = completed + 1;
        end
    end
    return completed;
end

function ScienceExecution.HasCivic(culture, civicType)
    local civicInfo = GameInfo.Civics[civicType];
    return civicInfo ~= nil and culture:HasCivic(civicInfo.Index);
end

function ScienceExecution.GetPolicyStatus(culture)
    local integratedInfo = GameInfo.Policies["POLICY_INTEGRATED_SPACE_CELL"];
    local agencyInfo = GameInfo.Policies["POLICY_INTERNATIONAL_SPACE_AGENCY"];
    local integrated = 0;
    local agency = 0;
    for slot = 0, culture:GetNumPolicySlots() - 1 do
        local policyIndex = culture:GetSlotPolicy(slot);
        if integratedInfo ~= nil and policyIndex == integratedInfo.Index then
            integrated = 1;
        end
        if agencyInfo ~= nil and policyIndex == agencyInfo.Index then
            agency = 1;
        end
    end
    return integrated, agency;
end

function ScienceExecution.GetSpaceportTarget(stage, cities)
    if stage <= ScienceExecution.NONE then
        return 0;
    end
    local midThreshold = math.max(1, GetNumberParameter(
        "ASAI_SCIENCE_SPACEPORT_MID_CITY_THRESHOLD",
        8
    ));
    if stage <= ScienceExecution.MOON then
        return cities >= midThreshold and 2 or 1;
    end
    if stage == ScienceExecution.MARS then
        local cap = math.max(2, math.floor(GetNumberParameter(
            "ASAI_SCIENCE_SPACEPORT_MARS_CAP",
            3
        )));
        return math.min(cities, cap, math.max(2, math.floor(cities / 5)));
    end
    local cap = math.max(2, math.floor(GetNumberParameter(
        "ASAI_SCIENCE_SPACEPORT_LASER_CAP",
        4
    )));
    return math.min(cities, cap, math.max(2, math.floor(cities / 4)));
end

function ScienceExecution.Collect(playerID)
    if not IsMajorAI(playerID) then
        return {
            Turn = Game.GetCurrentGameTurn(),
            Plan = Strategic.DEVELOP,
            Stage = ScienceExecution.NONE,
            Active = false,
            Suspended = false,
            LastProgressTurn = -1,
            ProgressAge = 0,
            Satellite = 0,
            Moon = 0,
            Mars = 0,
            Exoplanet = 0,
            Lasers = 0,
            Spaceports = 0,
            SpaceportsInFlight = 0,
            SpaceportTarget = 0,
            ActiveProjects = 0,
            CurrentProject = "none",
            FrontierTechs = 0,
            SpaceRaceCivic = false,
            GlobalizationCivic = false,
            IntegratedSpaceCell = 0,
            InternationalSpaceAgency = 0,
            MigrationStage = ScienceExecution.NONE,
            MigrationSensorOk = -1
        };
    end
    local turn = Game.GetCurrentGameTurn();
    local player = Players[playerID];
    local plan = GetStoredNumber(player, Strategic.PROPERTY, Strategic.DEVELOP);
    local cached = ScienceExecution.Cache[playerID];
    if cached ~= nil and cached.Turn == turn and cached.Plan == plan then
        return cached;
    end

    local snapshot = GetSnapshot(playerID);
    local activeProjects, currentProject, inFlightSpaceports, queueStage =
        ScienceExecution.GetQueueState(player);
    local rawStoredStageProperty = player:GetProperty(ScienceExecution.STAGE_PROPERTY);
    local rawStoredStage = tonumber(rawStoredStageProperty);
    local storedStage = rawStoredStage or ScienceExecution.NONE;
    local rawTrackingSchema = player:GetProperty(
        ScienceExecution.TRACKING_SCHEMA_PROPERTY
    );
    local trackingSchema = tonumber(rawTrackingSchema) or 0;
    local availableStage = ScienceExecution.NONE;
    local migrationSensorOk = -1;
    if trackingSchema < ScienceExecution.TRACKING_SCHEMA then
        availableStage, migrationSensorOk =
            ScienceExecution.GetLegacyAvailableStage(player);
        local migrationStage = math.max(
            storedStage,
            queueStage,
            availableStage
        );
        ScienceExecution.SeedCountsThroughStage(player, migrationStage);
        player:SetProperty(
            ScienceExecution.TRACKING_SCHEMA_PROPERTY,
            ScienceExecution.TRACKING_SCHEMA
        );
        print(string.format(
            "ASAI_SCIENCE_MIGRATION turn=%d player=%d stored_stage=%s queue_stage=%s available_stage=%s sensor_ok=%d",
            turn,
            playerID,
            ScienceExecution.GetStageName(storedStage),
            ScienceExecution.GetStageName(queueStage),
            ScienceExecution.GetStageName(availableStage),
            migrationSensorOk
        ));
    end

    local satellite = ScienceExecution.GetProjectCount(
        player,
        ScienceExecution.PROJECTS.Satellite
    );
    local moon = ScienceExecution.GetProjectCount(player, ScienceExecution.PROJECTS.Moon);
    local mars = ScienceExecution.GetProjectCount(player, ScienceExecution.PROJECTS.Mars);
    local exoplanet = ScienceExecution.GetProjectCount(
        player,
        ScienceExecution.PROJECTS.Exoplanet
    );
    local orbitalLasers = ScienceExecution.GetProjectCount(
        player,
        ScienceExecution.PROJECTS.OrbitalLaser
    );
    local terrestrialLasers = ScienceExecution.GetProjectCount(
        player,
        ScienceExecution.PROJECTS.TerrestrialLaser
    );
    local computedStage = ScienceExecution.NONE;
    if satellite > 0 then
        computedStage = ScienceExecution.SATELLITE;
    end
    if moon > 0 then
        computedStage = ScienceExecution.MOON;
    end
    if mars > 0 then
        computedStage = ScienceExecution.MARS;
    end
    if exoplanet > 0 then
        computedStage = ScienceExecution.EXOPLANET;
    end

    local migrationStage = math.max(queueStage, availableStage);
    local stage = math.max(computedStage, storedStage, migrationStage);
    local rawProgressTurnProperty = player:GetProperty(
        ScienceExecution.LAST_PROGRESS_TURN_PROPERTY
    );
    local rawProgressTurn = tonumber(rawProgressTurnProperty);
    local lastProgressTurn = rawProgressTurn or turn;
    if rawStoredStage == nil then
        player:SetProperty(ScienceExecution.STAGE_PROPERTY, stage);
        player:SetProperty(ScienceExecution.STAGE_TURN_PROPERTY, turn);
        player:SetProperty(ScienceExecution.LAST_PROGRESS_TURN_PROPERTY, turn);
        lastProgressTurn = turn;
    elseif stage > storedStage then
        player:SetProperty(ScienceExecution.STAGE_PROPERTY, stage);
        player:SetProperty(ScienceExecution.STAGE_TURN_PROPERTY, turn);
        player:SetProperty(ScienceExecution.LAST_PROGRESS_TURN_PROPERTY, turn);
        lastProgressTurn = turn;
        print(string.format(
            "ASAI_SCIENCE_STAGE turn=%d player=%d from=%s to=%s",
            turn,
            playerID,
            ScienceExecution.GetStageName(storedStage),
            ScienceExecution.GetStageName(stage)
        ));
    elseif rawProgressTurn == nil then
        player:SetProperty(ScienceExecution.LAST_PROGRESS_TURN_PROPERTY, turn);
        lastProgressTurn = turn;
    end

    local spaceports = ScienceExecution.GetCompletedSpaceports(player);
    local spaceportTarget = ScienceExecution.GetSpaceportTarget(stage, snapshot.Cities);
    local defenseWindow = ScaleStandardTurns(GetNumberParameter(
        "ASAI_SCIENCE_DEFENSE_COMBAT_STANDARD",
        8
    ));
    local suspended = plan == Strategic.DEFEND
        and snapshot.ActiveMajorWars > 0
        and turn - snapshot.LastMajorCombatTurn <= defenseWindow;
    local timeoutStandard = stage == ScienceExecution.MARS
        and GetNumberParameter("ASAI_SCIENCE_MARS_TIMEOUT_STANDARD", 20)
        or GetNumberParameter("ASAI_SCIENCE_STAGE_TIMEOUT_STANDARD", 16);
    local recentProgress = turn - lastProgressTurn <= ScaleStandardTurns(timeoutStandard);
    local active = stage > ScienceExecution.NONE
        and not suspended
        and (stage == ScienceExecution.EXOPLANET
            or activeProjects > 0
            or recentProgress);

    local culture = player:GetCulture();
    local policySuccess, integrated, agency = pcall(
        ScienceExecution.GetPolicyStatus,
        culture
    );
    if not policySuccess then
        local policyError = integrated;
        integrated = -1;
        agency = -1;
        if m_ConditionErrors.ASAI_SciencePolicyStatus == nil then
            print(string.format(
                "ASAI_DIAGNOSTIC_ERROR sensor=science_policies fallback=missing error=%s",
                tostring(policyError)
            ));
            m_ConditionErrors.ASAI_SciencePolicyStatus = true;
        end
    end
    local result = {
        Turn = turn,
        Plan = plan,
        Stage = stage,
        Active = active,
        Suspended = suspended,
        LastProgressTurn = lastProgressTurn,
        ProgressAge = GetStandardEquivalentTurn(turn - lastProgressTurn),
        Satellite = satellite,
        Moon = moon,
        Mars = mars,
        Exoplanet = exoplanet,
        Lasers = orbitalLasers + terrestrialLasers,
        Spaceports = spaceports,
        SpaceportsInFlight = inFlightSpaceports,
        SpaceportTarget = spaceportTarget,
        ActiveProjects = activeProjects,
        CurrentProject = currentProject,
        FrontierTechs = ScienceExecution.CountFrontierTechs(player),
        SpaceRaceCivic = ScienceExecution.HasCivic(culture, "CIVIC_SPACE_RACE"),
        GlobalizationCivic = ScienceExecution.HasCivic(culture, "CIVIC_GLOBALIZATION"),
        IntegratedSpaceCell = integrated,
        InternationalSpaceAgency = agency,
        MigrationStage = migrationStage,
        MigrationSensorOk = migrationSensorOk
    };
    ScienceExecution.Cache[playerID] = result;
    return result;
end

function ScienceExecution.RecordProjectCompletion(
    playerID,
    cityID,
    projectID,
    bCanceled
)
    if bCanceled == true or bCanceled == 1 or not IsMajorAI(playerID) then
        return;
    end
    local projectInfo = GameInfo.Projects[projectID];
    if projectInfo == nil then
        return;
    end
    local projectType = projectInfo.ProjectType;
    local completedStage = ScienceExecution.PROJECT_STAGES[projectType];
    if completedStage == nil then
        return;
    end

    local player = Players[playerID];
    local propertyName = ScienceExecution.COUNT_PROPERTY_PREFIX .. projectType;
    local projectCount = ScienceExecution.GetProjectCount(player, projectType) + 1;
    local turn = Game.GetCurrentGameTurn();
    local previousStage = GetStoredNumber(
        player,
        ScienceExecution.STAGE_PROPERTY,
        ScienceExecution.NONE
    );
    local stage = math.max(previousStage, completedStage);
    player:SetProperty(propertyName, projectCount);
    player:SetProperty(
        ScienceExecution.TRACKING_SCHEMA_PROPERTY,
        ScienceExecution.TRACKING_SCHEMA
    );
    player:SetProperty(ScienceExecution.STAGE_PROPERTY, stage);
    player:SetProperty(ScienceExecution.LAST_PROGRESS_TURN_PROPERTY, turn);
    if stage > previousStage then
        player:SetProperty(ScienceExecution.STAGE_TURN_PROPERTY, turn);
        print(string.format(
            "ASAI_SCIENCE_STAGE turn=%d player=%d from=%s to=%s",
            turn,
            playerID,
            ScienceExecution.GetStageName(previousStage),
            ScienceExecution.GetStageName(stage)
        ));
    end
    print(string.format(
        "ASAI_SCIENCE_PROJECT turn=%d player=%d city=%d project=%s count=%d stage=%s",
        turn,
        playerID,
        cityID,
        projectType,
        projectCount,
        ScienceExecution.GetStageName(stage)
    ));
    ScienceExecution.Cache[playerID] = nil;
end

function ScienceExecution.OnCityProjectCompleted(
    playerID,
    cityID,
    projectID,
    buildingID,
    x,
    y,
    bCanceled
)
    local success, projectError = pcall(
        ScienceExecution.RecordProjectCompletion,
        playerID,
        cityID,
        projectID,
        bCanceled
    );
    if not success and m_ConditionErrors.ASAI_RecordScienceProject == nil then
        print(string.format(
            "ASAI_ERROR condition=ASAI_RecordScienceProject player=%s fallback=skip error=%s",
            tostring(playerID),
            tostring(projectError)
        ));
        m_ConditionErrors.ASAI_RecordScienceProject = true;
    end
end

local function GetBandName(band)
    if band == RELATIVE_CATCHUP then
        return "catchup";
    end
    if band == RELATIVE_CONSOLIDATE then
        return "consolidate";
    end
    return "matched";
end

local function GetFocusName(focus)
    if focus == RELATIVE_FOCUS_SCIENCE then
        return "science";
    end
    if focus == RELATIVE_FOCUS_CULTURE then
        return "culture";
    end
    if focus == RELATIVE_FOCUS_EMPIRE then
        return "empire";
    end
    return "none";
end

local function GetFocusResultName(result)
    if result == RELATIVE_FOCUS_RESULT_IMPROVING then
        return "improving";
    end
    if result == RELATIVE_FOCUS_RESULT_EXECUTING then
        return "executing";
    end
    if result == RELATIVE_FOCUS_RESULT_STALLED then
        return "stalled";
    end
    return "none";
end

local function GetSupportName(state)
    if state.SevereCatchup == 1 then
        return "strong";
    end
    if state.Band == RELATIVE_CATCHUP then
        return "mild";
    end
    return "none";
end

function Strategic.GetPlanName(plan)
    if plan == Strategic.RECOVER then
        return "recover";
    end
    if plan == Strategic.EXPAND then
        return "expand";
    end
    if plan == Strategic.DEFEND then
        return "defend";
    end
    if plan == Strategic.PRESSURE then
        return "pressure";
    end
    if plan == Strategic.WAR then
        return "war";
    end
    return "develop";
end

function Strategic.GetSupportName(support)
    return GetFocusName(support);
end

local function GetResultTierName(state)
    if state.SevereResultYieldsActive == 1 then
        return "strong";
    end
    if state.MildResultYieldsActive == 1 then
        return "mild";
    end
    return "none";
end

local function SyncRecoveryFlags(state)
    state.Recovery.Science = state.StrategicSupport == RELATIVE_FOCUS_SCIENCE;
    state.Recovery.Culture = state.StrategicSupport == RELATIVE_FOCUS_CULTURE;
    state.Recovery.Empire = state.StrategicSupport == RELATIVE_FOCUS_EMPIRE;
end

local function GetNeutralRelativeState()
    return {
        Band = RELATIVE_MATCHED,
        Scores = { Overall = 1, Science = 1, Culture = 1, Empire = 1, Military = 1 },
        RawScores = { Overall = 1, Science = 1, Culture = 1, Empire = 1, Military = 1 },
        CompetitiveScores = { Overall = 1, Science = 1, Culture = 1, Empire = 1, Military = 1 },
        WorldUpperScores = { Overall = 1, Science = 1, Culture = 1, Empire = 1, Military = 1 },
        Trends = { Overall = 0, Science = 0, Culture = 0, Empire = 0, Military = 0 },
        RawRatios = {},
        ControlledRatios = {},
        Focus = RELATIVE_FOCUS_NONE,
        Recovery = { Science = false, Culture = false, Empire = false },
        BandCandidate = RELATIVE_MATCHED,
        BandStreak = 0,
        BandChangedTurn = -100000,
        BandCooldownUntil = -1,
        FocusCandidate = RELATIVE_FOCUS_NONE,
        FocusStreak = 0,
        FocusChangedTurn = -100000,
        FocusHandoffReady = false,
        FocusCooldownUntil = {
            [RELATIVE_FOCUS_SCIENCE] = -1,
            [RELATIVE_FOCUS_CULTURE] = -1,
            [RELATIVE_FOCUS_EMPIRE] = -1
        },
        FocusStartedTurn = -1,
        FocusReviewTurn = -1,
        FocusBaseline = 1,
        FocusRawBaseline = 1,
        FocusGain = 0,
        FocusRawGain = 0,
        FocusOwnYieldBaseline = -1,
        FocusOwnProgressBaseline = -1,
        FocusOwnYieldGain = 0,
        FocusOwnProgressGain = 0,
        FocusResult = RELATIVE_FOCUS_RESULT_NONE,
        FocusExecution = 0,
        FocusStallCount = 0,
        SevereCatchup = 0,
        SevereCandidate = 0,
        SevereStreak = 0,
        SevereChangedTurn = -100000,
        MildResultYieldsActive = 0,
        SevereResultYieldsActive = 0,
        MilitaryReadiness = 0,
        MilitaryReadinessCandidate = 0,
        MilitaryReadinessStreak = 0,
        MilitaryReadinessChangedTurn = -100000,
        MilitaryReadinessCooldownUntil = -1,
        MilitaryDominance = 0,
        MilitaryPlannedCities = 0,
        MilitaryUnitsPerPlannedCity = 0,
        ScaleRecovery = 0,
        ScaleRecoveryCandidate = 0,
        ScaleRecoveryStreak = 0,
        ScaleRecoveryChangedTurn = -100000,
        ScaleRecoveryCooldownUntil = -1,
        ScaleExpansionAllowed = 0,
        StrategicPlan = Strategic.DEVELOP,
        StrategicPlanCandidate = Strategic.DEVELOP,
        StrategicPlanStreak = 0,
        StrategicPlanChangedTurn = -100000,
        StrategicPlanStartedTurn = -1,
        StrategicPlanReviewTurn = -1,
        StrategicPlanBaseline = 1,
        StrategicPlanBaselineCities = 0,
        StrategicPlanBaselineCaptured = 0,
        StrategicPlanBaselineSettlers = 0,
        StrategicPlanBaselineActiveWars = 0,
        StrategicPlanBaselineCombat = 0,
        StrategicPlanBaselineOwned = 0,
        StrategicPlanBaselineMilitary = 0,
        StrategicPlanBaselineEnemyMilitary = 0,
        StrategicPlanBaselineMajorWars = 0,
        StrategicPlanBaselineCombatEvents = 0,
        StrategicPlanBaselineCaptureEvents = 0,
        StrategicPlanBaselinePillageEvents = 0,
        StrategicPlanGain = 0,
        StrategicPlanResult = RELATIVE_FOCUS_RESULT_NONE,
        StrategicPlanExecution = 0,
        StrategicPlanStallCount = 0,
        StrategicPlanScore = 0,
        StrategicPlanOutcomeSchema = Strategic.OUTCOME_SCHEMA,
        StrategicPlanScores = {},
        StrategicPlanCooldownUntil = {
            [Strategic.DEVELOP] = -1,
            [Strategic.RECOVER] = -1,
            [Strategic.EXPAND] = -1,
            [Strategic.DEFEND] = -1,
            [Strategic.PRESSURE] = -1,
            [Strategic.WAR] = -1
        },
        ExpansionPhase = Strategic.EXPANSION_NORMAL,
        ExpansionPlanAllowed = 1,
        ExpansionSettlerStallCount = 0,
        ExpansionLastSuccessTurn = -1,
        ExpansionBlockedUntil = -1,
        StrategicSupport = RELATIVE_FOCUS_NONE,
        LastSampleTurn = -1,
        LastEvaluationTurn = -1,
        EvaluatedThisTurn = false,
        Stage = "early"
    };
end

local function ReadRelativeState(player)
    local state = GetNeutralRelativeState();
    state.Band = GetStoredNumber(player, RELATIVE_BAND_PROPERTY, RELATIVE_MATCHED);
    if state.Band ~= RELATIVE_CATCHUP and state.Band ~= RELATIVE_CONSOLIDATE then
        state.Band = RELATIVE_MATCHED;
    end
    for pillar, propertyName in pairs(RELATIVE_SCORE_PROPERTIES) do
        state.Scores[pillar] = GetStoredNumber(player, propertyName, 1000) / 1000;
    end
    for pillar, propertyName in pairs(RELATIVE_RAW_SCORE_PROPERTIES) do
        state.RawScores[pillar] = GetStoredNumber(
            player,
            propertyName,
            math.floor(state.Scores[pillar] * 1000 + 0.5)
        ) / 1000;
    end
    for pillar, propertyName in pairs(RELATIVE_TREND_PROPERTIES) do
        state.Trends[pillar] = GetStoredNumber(player, propertyName, 0) / 1000;
    end
    state.Focus = GetStoredNumber(player, RELATIVE_FOCUS_PROPERTY, RELATIVE_FOCUS_NONE);
    if state.Focus < RELATIVE_FOCUS_NONE or state.Focus > RELATIVE_FOCUS_EMPIRE then
        state.Focus = RELATIVE_FOCUS_NONE;
    end
    state.BandCandidate = GetStoredNumber(
        player,
        RELATIVE_BAND_CANDIDATE_PROPERTY,
        state.Band
    );
    state.BandStreak = GetStoredNumber(player, RELATIVE_BAND_STREAK_PROPERTY, 0);
    state.BandChangedTurn = GetStoredNumber(
        player,
        RELATIVE_BAND_CHANGED_TURN_PROPERTY,
        -100000
    );
    state.BandCooldownUntil = GetStoredNumber(
        player,
        RELATIVE_BAND_COOLDOWN_PROPERTY,
        -1
    );
    state.FocusCandidate = GetStoredNumber(
        player,
        RELATIVE_FOCUS_CANDIDATE_PROPERTY,
        state.Focus
    );
    state.FocusStreak = GetStoredNumber(player, RELATIVE_FOCUS_STREAK_PROPERTY, 0);
    state.FocusChangedTurn = GetStoredNumber(
        player,
        RELATIVE_FOCUS_CHANGED_TURN_PROPERTY,
        -100000
    );
    state.FocusHandoffReady = GetStoredNumber(
        player,
        RELATIVE_FOCUS_HANDOFF_PROPERTY,
        0
    ) == 1;
    local legacyFocusCooldown = GetStoredNumber(
        player,
        RELATIVE_FOCUS_COOLDOWN_PROPERTY,
        -1
    );
    for focus, propertyName in pairs(RELATIVE_FOCUS_COOLDOWN_PROPERTIES) do
        state.FocusCooldownUntil[focus] = math.max(
            legacyFocusCooldown,
            GetStoredNumber(player, propertyName, -1)
        );
    end
    state.FocusStartedTurn = GetStoredNumber(
        player,
        RELATIVE_FOCUS_STARTED_TURN_PROPERTY,
        -1
    );
    state.FocusReviewTurn = GetStoredNumber(
        player,
        RELATIVE_FOCUS_REVIEW_TURN_PROPERTY,
        state.FocusStartedTurn
    );
    state.FocusBaseline = GetStoredNumber(
        player,
        RELATIVE_FOCUS_BASELINE_PROPERTY,
        1000
    ) / 1000;
    state.FocusRawBaseline = GetStoredNumber(
        player,
        RELATIVE_FOCUS_RAW_BASELINE_PROPERTY,
        1000
    ) / 1000;
    state.FocusGain = GetStoredNumber(player, RELATIVE_FOCUS_GAIN_PROPERTY, 0) / 1000;
    state.FocusRawGain = GetStoredNumber(
        player,
        RELATIVE_FOCUS_RAW_GAIN_PROPERTY,
        0
    ) / 1000;
    state.FocusOwnYieldBaseline = GetStoredNumber(
        player,
        Strategic.FOCUS_OWN_YIELD_BASELINE_PROPERTY,
        -100
    ) / 100;
    state.FocusOwnProgressBaseline = GetStoredNumber(
        player,
        Strategic.FOCUS_OWN_PROGRESS_BASELINE_PROPERTY,
        -1
    );
    state.FocusOwnYieldGain = GetStoredNumber(
        player,
        Strategic.FOCUS_OWN_YIELD_GAIN_PROPERTY,
        0
    ) / 1000;
    state.FocusOwnProgressGain = GetStoredNumber(
        player,
        Strategic.FOCUS_OWN_PROGRESS_GAIN_PROPERTY,
        0
    );
    state.FocusResult = GetStoredNumber(
        player,
        RELATIVE_FOCUS_RESULT_PROPERTY,
        RELATIVE_FOCUS_RESULT_NONE
    );
    if state.FocusResult < RELATIVE_FOCUS_RESULT_NONE
        or state.FocusResult > RELATIVE_FOCUS_RESULT_STALLED then
        state.FocusResult = RELATIVE_FOCUS_RESULT_NONE;
    end
    state.FocusExecution = GetStoredNumber(
        player,
        RELATIVE_FOCUS_EXECUTION_PROPERTY,
        0
    );
    state.FocusStallCount = GetStoredNumber(
        player,
        RELATIVE_FOCUS_STALL_COUNT_PROPERTY,
        0
    );
    state.SevereCatchup = GetStoredNumber(player, RELATIVE_SEVERE_PROPERTY, 0) == 1 and 1 or 0;
    state.SevereCandidate = GetStoredNumber(
        player,
        RELATIVE_SEVERE_CANDIDATE_PROPERTY,
        state.SevereCatchup
    ) == 1 and 1 or 0;
    state.SevereStreak = GetStoredNumber(player, RELATIVE_SEVERE_STREAK_PROPERTY, 0);
    state.SevereChangedTurn = GetStoredNumber(
        player,
        RELATIVE_SEVERE_CHANGED_TURN_PROPERTY,
        -100000
    );
    state.MildResultYieldsActive = GetStoredNumber(
        player,
        MILD_RESULT_YIELDS_ACTIVE_PROPERTY,
        0
    ) == 1 and 1 or 0;
    state.SevereResultYieldsActive = GetStoredNumber(
        player,
        SEVERE_RESULT_YIELDS_ACTIVE_PROPERTY,
        0
    ) == 1 and 1 or 0;
    state.MilitaryReadiness = GetStoredNumber(
        player,
        MILITARY_READINESS_PROPERTY,
        0
    ) == 1 and 1 or 0;
    state.MilitaryReadinessCandidate = GetStoredNumber(
        player,
        MILITARY_READINESS_CANDIDATE_PROPERTY,
        state.MilitaryReadiness
    ) == 1 and 1 or 0;
    state.MilitaryReadinessStreak = GetStoredNumber(
        player,
        MILITARY_READINESS_STREAK_PROPERTY,
        0
    );
    state.MilitaryReadinessChangedTurn = GetStoredNumber(
        player,
        MILITARY_READINESS_CHANGED_TURN_PROPERTY,
        -100000
    );
    state.MilitaryReadinessCooldownUntil = GetStoredNumber(
        player,
        MILITARY_READINESS_COOLDOWN_PROPERTY,
        -1
    );
    state.MilitaryDominance = GetStoredNumber(
        player,
        MILITARY_DOMINANCE_PROPERTY,
        0
    ) == 1 and 1 or 0;
    state.ScaleRecovery = GetStoredNumber(
        player,
        SCALE_RECOVERY_PROPERTY,
        0
    ) == 1 and 1 or 0;
    state.ScaleRecoveryCandidate = GetStoredNumber(
        player,
        SCALE_RECOVERY_CANDIDATE_PROPERTY,
        state.ScaleRecovery
    ) == 1 and 1 or 0;
    state.ScaleRecoveryStreak = GetStoredNumber(
        player,
        SCALE_RECOVERY_STREAK_PROPERTY,
        0
    );
    state.ScaleRecoveryChangedTurn = GetStoredNumber(
        player,
        SCALE_RECOVERY_CHANGED_TURN_PROPERTY,
        -100000
    );
    state.ScaleRecoveryCooldownUntil = GetStoredNumber(
        player,
        SCALE_RECOVERY_COOLDOWN_PROPERTY,
        -1
    );
    state.ScaleExpansionAllowed = GetStoredNumber(
        player,
        SCALE_EXPANSION_ALLOWED_PROPERTY,
        0
    ) == 1 and 1 or 0;
    state.StrategicPlan = GetStoredNumber(
        player,
        Strategic.PROPERTY,
        Strategic.DEVELOP
    );
    if state.StrategicPlan < Strategic.DEVELOP
        or state.StrategicPlan > Strategic.WAR then
        state.StrategicPlan = Strategic.DEVELOP;
    end
    state.StrategicPlanCandidate = GetStoredNumber(
        player,
        Strategic.CANDIDATE_PROPERTY,
        state.StrategicPlan
    );
    state.StrategicPlanStreak = GetStoredNumber(
        player,
        Strategic.STREAK_PROPERTY,
        0
    );
    state.StrategicPlanChangedTurn = GetStoredNumber(
        player,
        Strategic.CHANGED_TURN_PROPERTY,
        -100000
    );
    state.StrategicPlanStartedTurn = GetStoredNumber(
        player,
        Strategic.STARTED_TURN_PROPERTY,
        -1
    );
    local rawOutcomeSchema = player:GetProperty(
        Strategic.OUTCOME_SCHEMA_PROPERTY
    );
    local storedOutcomeSchema = tonumber(rawOutcomeSchema);
    if storedOutcomeSchema ~= nil then
        state.StrategicPlanOutcomeSchema = math.floor(storedOutcomeSchema);
    elseif player:GetProperty(Strategic.STARTED_TURN_PROPERTY) ~= nil then
        state.StrategicPlanOutcomeSchema = 0;
    end
    state.StrategicPlanReviewTurn = GetStoredNumber(
        player,
        Strategic.REVIEW_TURN_PROPERTY,
        state.StrategicPlanStartedTurn
    );
    state.StrategicPlanBaseline = GetStoredNumber(
        player,
        Strategic.BASELINE_PROPERTY,
        1000
    ) / 1000;
    state.StrategicPlanBaselineCities = GetStoredNumber(
        player,
        Strategic.BASELINE_CITIES_PROPERTY,
        0
    );
    state.StrategicPlanBaselineCaptured = GetStoredNumber(
        player,
        Strategic.BASELINE_CAPTURED_PROPERTY,
        0
    );
    state.StrategicPlanBaselineSettlers = GetStoredNumber(
        player,
        Strategic.BASELINE_SETTLERS_PROPERTY,
        0
    );
    state.StrategicPlanBaselineActiveWars = GetStoredNumber(
        player,
        Strategic.BASELINE_ACTIVE_WARS_PROPERTY,
        0
    );
    state.StrategicPlanBaselineCombat = GetStoredNumber(
        player,
        Strategic.BASELINE_COMBAT_PROPERTY,
        0
    );
    state.StrategicPlanBaselineOwned = GetStoredNumber(
        player,
        Strategic.BASELINE_OWNED_PROPERTY,
        0
    );
    state.StrategicPlanBaselineMilitary = GetStoredNumber(
        player,
        Strategic.BASELINE_MILITARY_PROPERTY,
        0
    );
    state.StrategicPlanBaselineEnemyMilitary = GetStoredNumber(
        player,
        Strategic.BASELINE_ENEMY_MILITARY_PROPERTY,
        0
    );
    state.StrategicPlanBaselineMajorWars = GetStoredNumber(
        player,
        Strategic.BASELINE_MAJOR_WARS_PROPERTY,
        0
    );
    state.StrategicPlanBaselineCombatEvents = GetStoredNumber(
        player,
        Strategic.BASELINE_COMBAT_EVENTS_PROPERTY,
        0
    );
    state.StrategicPlanBaselineCaptureEvents = GetStoredNumber(
        player,
        Strategic.BASELINE_CAPTURE_EVENTS_PROPERTY,
        0
    );
    state.StrategicPlanBaselinePillageEvents = GetStoredNumber(
        player,
        Strategic.BASELINE_PILLAGE_EVENTS_PROPERTY,
        0
    );
    state.StrategicPlanGain = GetStoredNumber(
        player,
        Strategic.GAIN_PROPERTY,
        0
    ) / 1000;
    state.StrategicPlanResult = GetStoredNumber(
        player,
        Strategic.RESULT_PROPERTY,
        RELATIVE_FOCUS_RESULT_NONE
    );
    if state.StrategicPlanResult < RELATIVE_FOCUS_RESULT_NONE
        or state.StrategicPlanResult > RELATIVE_FOCUS_RESULT_STALLED then
        state.StrategicPlanResult = RELATIVE_FOCUS_RESULT_NONE;
    end
    state.StrategicPlanExecution = GetStoredNumber(
        player,
        Strategic.EXECUTION_PROPERTY,
        0
    );
    state.StrategicPlanStallCount = GetStoredNumber(
        player,
        Strategic.STALL_COUNT_PROPERTY,
        0
    );
    state.StrategicPlanScore = GetStoredNumber(
        player,
        Strategic.SCORE_PROPERTY,
        0
    ) / 100;
    for plan, propertyName in pairs(Strategic.COOLDOWN_PROPERTIES) do
        state.StrategicPlanCooldownUntil[plan] = GetStoredNumber(
            player,
            propertyName,
            -1
        );
    end
    state.ExpansionSettlerStallCount = GetStoredNumber(
        player,
        Strategic.EXPANSION_SETTLER_STALL_PROPERTY,
        0
    );
    state.ExpansionLastSuccessTurn = GetStoredNumber(
        player,
        Strategic.EXPANSION_LAST_SUCCESS_PROPERTY,
        -1
    );
    state.ExpansionBlockedUntil = GetStoredNumber(
        player,
        Strategic.EXPANSION_BLOCKED_UNTIL_PROPERTY,
        -1
    );
    state.StrategicSupport = GetStoredNumber(
        player,
        Strategic.SUPPORT_PROPERTY,
        RELATIVE_FOCUS_NONE
    );
    if state.StrategicSupport < RELATIVE_FOCUS_NONE
        or state.StrategicSupport > RELATIVE_FOCUS_EMPIRE then
        state.StrategicSupport = RELATIVE_FOCUS_NONE;
    end
    state.LastSampleTurn = GetStoredNumber(player, RELATIVE_SAMPLE_TURN_PROPERTY, -1);
    state.LastEvaluationTurn = GetStoredNumber(
        player,
        RELATIVE_EVALUATION_TURN_PROPERTY,
        -1
    );
    SyncRecoveryFlags(state);
    return state;
end

local function StoreRelativeState(player, state)
    player:SetProperty(RELATIVE_BAND_PROPERTY, state.Band);
    for pillar, propertyName in pairs(RELATIVE_SCORE_PROPERTIES) do
        player:SetProperty(propertyName, math.floor(state.Scores[pillar] * 1000 + 0.5));
    end
    for pillar, propertyName in pairs(RELATIVE_RAW_SCORE_PROPERTIES) do
        player:SetProperty(propertyName, math.floor(state.RawScores[pillar] * 1000 + 0.5));
    end
    for pillar, propertyName in pairs(RELATIVE_TREND_PROPERTIES) do
        player:SetProperty(propertyName, math.floor(state.Trends[pillar] * 1000 + 0.5));
    end
    for pillar, propertyName in pairs(RELATIVE_RECOVERY_PROPERTIES) do
        player:SetProperty(propertyName, state.Recovery[pillar] and 1 or 0);
    end
    player:SetProperty(RELATIVE_FOCUS_PROPERTY, state.Focus);
    player:SetProperty(RELATIVE_BAND_CANDIDATE_PROPERTY, state.BandCandidate);
    player:SetProperty(RELATIVE_BAND_STREAK_PROPERTY, state.BandStreak);
    player:SetProperty(RELATIVE_BAND_CHANGED_TURN_PROPERTY, state.BandChangedTurn);
    player:SetProperty(RELATIVE_BAND_COOLDOWN_PROPERTY, state.BandCooldownUntil);
    player:SetProperty(RELATIVE_FOCUS_CANDIDATE_PROPERTY, state.FocusCandidate);
    player:SetProperty(RELATIVE_FOCUS_STREAK_PROPERTY, state.FocusStreak);
    player:SetProperty(RELATIVE_FOCUS_CHANGED_TURN_PROPERTY, state.FocusChangedTurn);
    player:SetProperty(
        RELATIVE_FOCUS_HANDOFF_PROPERTY,
        state.FocusHandoffReady and 1 or 0
    );
    -- Clear the pre-0.5 global cooldown after migrating it into pillar cooldowns.
    player:SetProperty(RELATIVE_FOCUS_COOLDOWN_PROPERTY, -1);
    for focus, propertyName in pairs(RELATIVE_FOCUS_COOLDOWN_PROPERTIES) do
        player:SetProperty(propertyName, state.FocusCooldownUntil[focus]);
    end
    player:SetProperty(RELATIVE_FOCUS_STARTED_TURN_PROPERTY, state.FocusStartedTurn);
    player:SetProperty(RELATIVE_FOCUS_REVIEW_TURN_PROPERTY, state.FocusReviewTurn);
    player:SetProperty(
        RELATIVE_FOCUS_BASELINE_PROPERTY,
        math.floor(state.FocusBaseline * 1000 + 0.5)
    );
    player:SetProperty(
        RELATIVE_FOCUS_RAW_BASELINE_PROPERTY,
        math.floor(state.FocusRawBaseline * 1000 + 0.5)
    );
    player:SetProperty(
        RELATIVE_FOCUS_GAIN_PROPERTY,
        math.floor(state.FocusGain * 1000 + 0.5)
    );
    player:SetProperty(
        RELATIVE_FOCUS_RAW_GAIN_PROPERTY,
        math.floor(state.FocusRawGain * 1000 + 0.5)
    );
    player:SetProperty(
        Strategic.FOCUS_OWN_YIELD_BASELINE_PROPERTY,
        math.floor(state.FocusOwnYieldBaseline * 100 + 0.5)
    );
    player:SetProperty(
        Strategic.FOCUS_OWN_PROGRESS_BASELINE_PROPERTY,
        state.FocusOwnProgressBaseline
    );
    player:SetProperty(
        Strategic.FOCUS_OWN_YIELD_GAIN_PROPERTY,
        math.floor(state.FocusOwnYieldGain * 1000 + 0.5)
    );
    player:SetProperty(
        Strategic.FOCUS_OWN_PROGRESS_GAIN_PROPERTY,
        state.FocusOwnProgressGain
    );
    player:SetProperty(RELATIVE_FOCUS_RESULT_PROPERTY, state.FocusResult);
    player:SetProperty(RELATIVE_FOCUS_EXECUTION_PROPERTY, state.FocusExecution);
    player:SetProperty(RELATIVE_FOCUS_STALL_COUNT_PROPERTY, state.FocusStallCount);
    player:SetProperty(RELATIVE_SEVERE_PROPERTY, state.SevereCatchup);
    player:SetProperty(RELATIVE_SEVERE_CANDIDATE_PROPERTY, state.SevereCandidate);
    player:SetProperty(RELATIVE_SEVERE_STREAK_PROPERTY, state.SevereStreak);
    player:SetProperty(RELATIVE_SEVERE_CHANGED_TURN_PROPERTY, state.SevereChangedTurn);
    player:SetProperty(
        MILD_RESULT_YIELDS_ACTIVE_PROPERTY,
        state.MildResultYieldsActive
    );
    player:SetProperty(
        SEVERE_RESULT_YIELDS_ACTIVE_PROPERTY,
        state.SevereResultYieldsActive
    );
    player:SetProperty(MILITARY_READINESS_PROPERTY, state.MilitaryReadiness);
    player:SetProperty(
        MILITARY_READINESS_CANDIDATE_PROPERTY,
        state.MilitaryReadinessCandidate
    );
    player:SetProperty(
        MILITARY_READINESS_STREAK_PROPERTY,
        state.MilitaryReadinessStreak
    );
    player:SetProperty(
        MILITARY_READINESS_CHANGED_TURN_PROPERTY,
        state.MilitaryReadinessChangedTurn
    );
    player:SetProperty(
        MILITARY_READINESS_COOLDOWN_PROPERTY,
        state.MilitaryReadinessCooldownUntil
    );
    player:SetProperty(MILITARY_DOMINANCE_PROPERTY, state.MilitaryDominance);
    player:SetProperty(SCALE_RECOVERY_PROPERTY, state.ScaleRecovery);
    player:SetProperty(
        SCALE_RECOVERY_CANDIDATE_PROPERTY,
        state.ScaleRecoveryCandidate
    );
    player:SetProperty(SCALE_RECOVERY_STREAK_PROPERTY, state.ScaleRecoveryStreak);
    player:SetProperty(
        SCALE_RECOVERY_CHANGED_TURN_PROPERTY,
        state.ScaleRecoveryChangedTurn
    );
    player:SetProperty(
        SCALE_RECOVERY_COOLDOWN_PROPERTY,
        state.ScaleRecoveryCooldownUntil
    );
    player:SetProperty(
        SCALE_EXPANSION_ALLOWED_PROPERTY,
        state.ScaleExpansionAllowed
    );
    player:SetProperty(Strategic.PROPERTY, state.StrategicPlan);
    player:SetProperty(
        Strategic.CANDIDATE_PROPERTY,
        state.StrategicPlanCandidate
    );
    player:SetProperty(Strategic.STREAK_PROPERTY, state.StrategicPlanStreak);
    player:SetProperty(
        Strategic.CHANGED_TURN_PROPERTY,
        state.StrategicPlanChangedTurn
    );
    player:SetProperty(
        Strategic.STARTED_TURN_PROPERTY,
        state.StrategicPlanStartedTurn
    );
    player:SetProperty(
        Strategic.REVIEW_TURN_PROPERTY,
        state.StrategicPlanReviewTurn
    );
    player:SetProperty(
        Strategic.BASELINE_PROPERTY,
        math.floor(state.StrategicPlanBaseline * 1000 + 0.5)
    );
    player:SetProperty(
        Strategic.BASELINE_CITIES_PROPERTY,
        state.StrategicPlanBaselineCities
    );
    player:SetProperty(
        Strategic.BASELINE_CAPTURED_PROPERTY,
        state.StrategicPlanBaselineCaptured
    );
    player:SetProperty(
        Strategic.BASELINE_SETTLERS_PROPERTY,
        state.StrategicPlanBaselineSettlers
    );
    player:SetProperty(
        Strategic.BASELINE_ACTIVE_WARS_PROPERTY,
        state.StrategicPlanBaselineActiveWars
    );
    player:SetProperty(
        Strategic.BASELINE_COMBAT_PROPERTY,
        state.StrategicPlanBaselineCombat
    );
    player:SetProperty(
        Strategic.BASELINE_OWNED_PROPERTY,
        state.StrategicPlanBaselineOwned
    );
    player:SetProperty(
        Strategic.BASELINE_MILITARY_PROPERTY,
        state.StrategicPlanBaselineMilitary
    );
    player:SetProperty(
        Strategic.BASELINE_ENEMY_MILITARY_PROPERTY,
        state.StrategicPlanBaselineEnemyMilitary
    );
    player:SetProperty(
        Strategic.BASELINE_MAJOR_WARS_PROPERTY,
        state.StrategicPlanBaselineMajorWars
    );
    player:SetProperty(
        Strategic.BASELINE_COMBAT_EVENTS_PROPERTY,
        state.StrategicPlanBaselineCombatEvents
    );
    player:SetProperty(
        Strategic.BASELINE_CAPTURE_EVENTS_PROPERTY,
        state.StrategicPlanBaselineCaptureEvents
    );
    player:SetProperty(
        Strategic.BASELINE_PILLAGE_EVENTS_PROPERTY,
        state.StrategicPlanBaselinePillageEvents
    );
    player:SetProperty(
        Strategic.GAIN_PROPERTY,
        math.floor(state.StrategicPlanGain * 1000 + 0.5)
    );
    player:SetProperty(Strategic.RESULT_PROPERTY, state.StrategicPlanResult);
    player:SetProperty(
        Strategic.EXECUTION_PROPERTY,
        state.StrategicPlanExecution
    );
    player:SetProperty(
        Strategic.STALL_COUNT_PROPERTY,
        state.StrategicPlanStallCount
    );
    player:SetProperty(
        Strategic.SCORE_PROPERTY,
        math.floor(state.StrategicPlanScore * 100 + 0.5)
    );
    player:SetProperty(
        Strategic.OUTCOME_SCHEMA_PROPERTY,
        state.StrategicPlanOutcomeSchema
    );
    for plan, propertyName in pairs(Strategic.COOLDOWN_PROPERTIES) do
        player:SetProperty(propertyName, state.StrategicPlanCooldownUntil[plan]);
    end
    player:SetProperty(
        Strategic.EXPANSION_SETTLER_STALL_PROPERTY,
        state.ExpansionSettlerStallCount
    );
    player:SetProperty(
        Strategic.EXPANSION_LAST_SUCCESS_PROPERTY,
        state.ExpansionLastSuccessTurn
    );
    player:SetProperty(
        Strategic.EXPANSION_BLOCKED_UNTIL_PROPERTY,
        state.ExpansionBlockedUntil
    );
    player:SetProperty(Strategic.SUPPORT_PROPERTY, state.StrategicSupport);
    player:SetProperty(RELATIVE_SAMPLE_TURN_PROPERTY, state.LastSampleTurn);
    player:SetProperty(RELATIVE_EVALUATION_TURN_PROPERTY, state.LastEvaluationTurn);
end

local function GetCompetitionThresholds(era)
    local classical = GameInfo.Eras["ERA_CLASSICAL"];
    local renaissance = GameInfo.Eras["ERA_RENAISSANCE"];
    local stage = "late";
    local prefix = "ASAI_RELATIVE_LATE_";
    local defaults = { 92, 97, 108, 115, 90 };
    if classical ~= nil and era <= classical.Index then
        stage = "early";
        prefix = "ASAI_RELATIVE_EARLY_";
        defaults = { 88, 94, 118, 125, 80 };
    elseif renaissance ~= nil and era <= renaissance.Index then
        stage = "mid";
        prefix = "ASAI_RELATIVE_MID_";
        defaults = { 90, 96, 113, 120, 85 };
    end
    return {
        Stage = stage,
        TrailingEnter = GetNumberParameter(prefix .. "TRAILING_ENTER_X100", defaults[1]) / 100,
        TrailingExit = GetNumberParameter(prefix .. "TRAILING_EXIT_X100", defaults[2]) / 100,
        LeadingExit = GetNumberParameter(prefix .. "LEADING_EXIT_X100", defaults[3]) / 100,
        LeadingEnter = GetNumberParameter(prefix .. "LEADING_ENTER_X100", defaults[4]) / 100,
        LeadingPillarMinimum = GetNumberParameter(
            prefix .. "LEADING_PILLAR_MIN_X100",
            defaults[5]
        ) / 100
    };
end

local function GetRecoveryThresholds()
    return {
        [RELATIVE_FOCUS_SCIENCE] = {
            Key = "Science",
            Enter = GetNumberParameter("ASAI_RELATIVE_SCIENCE_ENTER_X100", 88) / 100,
            Exit = GetNumberParameter("ASAI_RELATIVE_SCIENCE_EXIT_X100", 96) / 100
        },
        [RELATIVE_FOCUS_CULTURE] = {
            Key = "Culture",
            Enter = GetNumberParameter("ASAI_RELATIVE_CULTURE_ENTER_X100", 85) / 100,
            Exit = GetNumberParameter("ASAI_RELATIVE_CULTURE_EXIT_X100", 95) / 100
        },
        [RELATIVE_FOCUS_EMPIRE] = {
            Key = "Empire",
            Enter = GetNumberParameter("ASAI_RELATIVE_EMPIRE_ENTER_X100", 85) / 100,
            Exit = GetNumberParameter("ASAI_RELATIVE_EMPIRE_EXIT_X100", 95) / 100
        }
    };
end

local function GetSmoothingAlpha()
    local baseAlpha = Clamp(
        GetNumberParameter("ASAI_RELATIVE_EMA_ALPHA_X100", 35) / 100,
        0.01,
        1
    );
    local standardTurnsPerRawTurn = 100 / GetGameSpeedMultiplier();
    return 1 - ((1 - baseAlpha) ^ standardTurnsPerRawTurn);
end

local function SmoothScores(previous, current, alpha, initialized)
    local smoothed = {};
    for _, key in ipairs({ "Overall", "Science", "Culture", "Empire", "Military" }) do
        if initialized then
            smoothed[key] = previous[key] + alpha * (current[key] - previous[key]);
        else
            smoothed[key] = current[key];
        end
    end
    return smoothed;
end

local function GetDesiredBand(state, thresholds)
    local weakestCorePillar = math.min(
        state.Scores.Science,
        state.Scores.Culture,
        state.Scores.Empire
    );
    local weakestEnter = GetNumberParameter(
        "ASAI_RELATIVE_CATCHUP_WEAKEST_ENTER_X100",
        85
    ) / 100;
    local weakestExit = GetNumberParameter(
        "ASAI_RELATIVE_CATCHUP_WEAKEST_EXIT_X100",
        95
    ) / 100;
    if state.Band == RELATIVE_CATCHUP then
        if state.Scores.Overall >= thresholds.TrailingExit
            and weakestCorePillar >= weakestExit then
            return RELATIVE_MATCHED;
        end
        return RELATIVE_CATCHUP;
    end
    if state.Band == RELATIVE_CONSOLIDATE then
        if state.Scores.Overall <= thresholds.TrailingEnter
            or weakestCorePillar <= weakestEnter then
            return RELATIVE_CATCHUP;
        end
        if state.Scores.Overall <= thresholds.LeadingExit
            or weakestCorePillar < thresholds.LeadingPillarMinimum then
            return RELATIVE_MATCHED;
        end
        return RELATIVE_CONSOLIDATE;
    end
    if state.Scores.Overall <= thresholds.TrailingEnter
        or weakestCorePillar <= weakestEnter then
        return RELATIVE_CATCHUP;
    end
    if state.Scores.Overall >= thresholds.LeadingEnter
        and weakestCorePillar >= thresholds.LeadingPillarMinimum then
        return RELATIVE_CONSOLIDATE;
    end
    return RELATIVE_MATCHED;
end

local function GetSecondWeakestCorePillarScore(state)
    local science = state.Scores.Science;
    local culture = state.Scores.Culture;
    local empire = state.Scores.Empire;
    return science + culture + empire
        - math.min(science, culture, empire)
        - math.max(science, culture, empire);
end

local function GetWeakestCorePillarScore(state)
    return math.min(
        state.Scores.Science,
        state.Scores.Culture,
        state.Scores.Empire
    );
end

local function GetDesiredSevereCatchup(state, snapshot)
    local enter = GetNumberParameter("ASAI_RELATIVE_SEVERE_ENTER_X100", 80) / 100;
    local exit = GetNumberParameter("ASAI_RELATIVE_SEVERE_EXIT_X100", 88) / 100;
    local coreEnter = GetNumberParameter(
        "ASAI_RELATIVE_SEVERE_CORE_ENTER_X100",
        78
    ) / 100;
    local coreExit = GetNumberParameter(
        "ASAI_RELATIVE_SEVERE_CORE_EXIT_X100",
        86
    ) / 100;
    local weakestEnter = GetNumberParameter(
        "ASAI_RELATIVE_SEVERE_WEAKEST_ENTER_X100",
        70
    ) / 100;
    local weakestExit = GetNumberParameter(
        "ASAI_RELATIVE_SEVERE_WEAKEST_EXIT_X100",
        80
    ) / 100;
    local secondCore = GetSecondWeakestCorePillarScore(state);
    local weakestCore = GetWeakestCorePillarScore(state);
    local warMilitaryEnter = GetNumberParameter(
        "ASAI_RELATIVE_WAR_EMERGENCY_MILITARY_X100",
        60
    ) / 100;
    local warEmergency = snapshot ~= nil
        and snapshot.ActiveMajorWars > 0
        and state.RawScores.Military <= warMilitaryEnter;
    if state.SevereCatchup == 1 then
        return (state.Scores.Overall < exit
            or secondCore < coreExit
            or weakestCore < weakestExit
            or warEmergency) and 1 or 0;
    end
    return (state.Scores.Overall <= enter
        or secondCore <= coreEnter
        or weakestCore <= weakestEnter
        or warEmergency) and 1 or 0;
end

local function GetDesiredScaleRecovery(state)
    local enter = GetNumberParameter("ASAI_SCALE_RECOVERY_ENTER_X100", 75) / 100;
    local exit = GetNumberParameter("ASAI_SCALE_RECOVERY_EXIT_X100", 88) / 100;
    local empireScore = math.min(
        state.Scores.Empire,
        state.CompetitiveScores.Empire or state.Scores.Empire
    );
    if state.ScaleRecovery == 1 then
        return empireScore < exit and 1 or 0;
    end
    return empireScore <= enter and 1 or 0;
end

local function HasBroadMildResultGap(state, currentlyActive)
    local overallEnter = GetNumberParameter(
        "ASAI_MILD_RESULT_OVERALL_ENTER_X100",
        92
    ) / 100;
    local overallExit = GetNumberParameter(
        "ASAI_MILD_RESULT_OVERALL_EXIT_X100",
        100
    ) / 100;
    local coreEnter = GetNumberParameter(
        "ASAI_MILD_RESULT_CORE_ENTER_X100",
        90
    ) / 100;
    local coreExit = GetNumberParameter(
        "ASAI_MILD_RESULT_CORE_EXIT_X100",
        98
    ) / 100;
    local secondCore = GetSecondWeakestCorePillarScore(state);
    if currentlyActive then
        return state.Scores.Overall < overallExit or secondCore < coreExit;
    end
    return state.Scores.Overall <= overallEnter or secondCore <= coreEnter;
end

local function SyncMildResultYields(playerID, player, state, turn)
    local enabled = GetNumberParameter(
        "ASAI_MILD_RESULT_YIELDS_ENABLED",
        1
    ) == 1;
    local currentlyActive = state.MildResultYieldsActive == 1;
    local broadEligible = HasBroadMildResultGap(state, currentlyActive);
    local desiredActive = enabled
        and state.Band == RELATIVE_CATCHUP
        and state.SevereCatchup ~= 1
        and broadEligible;
    if desiredActive == currentlyActive then
        return;
    end

    local modifierID = desiredActive and MILD_RESULT_YIELDS_ON_MODIFIER
        or MILD_RESULT_YIELDS_OFF_MODIFIER;
    local success, attachError = pcall(
        function() player:AttachModifierByID(modifierID); end
    );
    if not success then
        local errorKey = "ASAI_MildResultYields_" .. tostring(playerID)
            .. "_" .. modifierID;
        if m_ConditionErrors[errorKey] == nil then
            print(string.format(
                "ASAI_ERROR condition=ASAI_MildResultYields player=%d modifier=%s fallback=retry error=%s",
                playerID,
                modifierID,
                tostring(attachError)
            ));
            m_ConditionErrors[errorKey] = true;
        end
        return;
    end

    state.MildResultYieldsActive = desiredActive and 1 or 0;
    player:SetProperty(
        MILD_RESULT_YIELDS_ACTIVE_PROPERTY,
        state.MildResultYieldsActive
    );
    local direction = desiredActive and 1 or -1;
    print(string.format(
        "ASAI_RESULT turn=%d standard_turn=%.1f player=%d tier=mild active=%d action=%s production=%d science=%d culture=%d food=%d relative=%.3f second_core=%.3f weakest_core=%.3f broad_gap=%d",
        turn,
        GetStandardEquivalentTurn(turn),
        playerID,
        state.MildResultYieldsActive,
        desiredActive and "activate" or "deactivate",
        direction * MILD_RESULT_PRODUCTION_PERCENT,
        direction * MILD_RESULT_SCIENCE_PERCENT,
        direction * MILD_RESULT_CULTURE_PERCENT,
        direction * MILD_RESULT_FOOD_PERCENT,
        state.Scores.Overall,
        GetSecondWeakestCorePillarScore(state),
        GetWeakestCorePillarScore(state),
        broadEligible and 1 or 0
    ));
end

local function SyncSevereResultYields(playerID, player, state, turn)
    local enabled = GetNumberParameter(
        "ASAI_SEVERE_RESULT_YIELDS_ENABLED",
        1
    ) == 1;
    local desiredActive = enabled and state.SevereCatchup == 1;
    local currentlyActive = state.SevereResultYieldsActive == 1;
    if desiredActive == currentlyActive then
        return;
    end

    local modifierID = desiredActive and SEVERE_RESULT_YIELDS_ON_MODIFIER
        or SEVERE_RESULT_YIELDS_OFF_MODIFIER;
    local success, attachError = pcall(
        function() player:AttachModifierByID(modifierID); end
    );
    if not success then
        local errorKey = "ASAI_SevereResultYields_" .. tostring(playerID)
            .. "_" .. modifierID;
        if m_ConditionErrors[errorKey] == nil then
            print(string.format(
                "ASAI_ERROR condition=ASAI_SevereResultYields player=%d modifier=%s fallback=retry error=%s",
                playerID,
                modifierID,
                tostring(attachError)
            ));
            m_ConditionErrors[errorKey] = true;
        end
        return;
    end

    state.SevereResultYieldsActive = desiredActive and 1 or 0;
    player:SetProperty(
        SEVERE_RESULT_YIELDS_ACTIVE_PROPERTY,
        state.SevereResultYieldsActive
    );
    local direction = desiredActive and 1 or -1;
    print(string.format(
        "ASAI_RESULT turn=%d standard_turn=%.1f player=%d tier=strong active=%d action=%s production=%d science=%d culture=%d food=%d relative=%.3f second_core=%.3f weakest_core=%.3f",
        turn,
        GetStandardEquivalentTurn(turn),
        playerID,
        state.SevereResultYieldsActive,
        desiredActive and "activate" or "deactivate",
        direction * SEVERE_RESULT_PRODUCTION_PERCENT,
        direction * SEVERE_RESULT_SCIENCE_PERCENT,
        direction * SEVERE_RESULT_CULTURE_PERCENT,
        direction * SEVERE_RESULT_FOOD_PERCENT,
        state.Scores.Overall,
        GetSecondWeakestCorePillarScore(state),
        GetWeakestCorePillarScore(state)
    ));
end

local function SyncResultYields(playerID, player, state, turn)
    if state.SevereCatchup == 1 then
        SyncMildResultYields(playerID, player, state, turn);
        if state.MildResultYieldsActive == 0 then
            SyncSevereResultYields(playerID, player, state, turn);
        end
        return;
    end

    SyncSevereResultYields(playerID, player, state, turn);
    if state.SevereResultYieldsActive == 0 then
        SyncMildResultYields(playerID, player, state, turn);
    end
end

function Strategic.GetExpansionPhase(era)
    local modern = GameInfo.Eras["ERA_MODERN"];
    if modern ~= nil and era >= modern.Index then
        return Strategic.EXPANSION_CLOSED;
    end
    local industrial = GameInfo.Eras["ERA_INDUSTRIAL"];
    if industrial ~= nil and era >= industrial.Index then
        return Strategic.EXPANSION_RESTRICTED;
    end
    return Strategic.EXPANSION_NORMAL;
end

function Strategic.GetExpansionPhaseName(phase)
    if phase == Strategic.EXPANSION_RESTRICTED then
        return "restricted";
    end
    if phase == Strategic.EXPANSION_CLOSED then
        return "closed";
    end
    return "normal";
end

function Strategic.UpdateExpansionState(state, snapshot, turn)
    state.ExpansionPhase = Strategic.GetExpansionPhase(snapshot.Era);
    local stallLimit = math.max(
        1,
        GetNumberParameter("ASAI_EXPANSION_SETTLER_STALL_LIMIT", 2)
    );
    if state.ExpansionBlockedUntil >= 0
        and turn >= state.ExpansionBlockedUntil
        and state.ExpansionPhase ~= Strategic.EXPANSION_CLOSED
        and state.ExpansionSettlerStallCount >= stallLimit then
        state.ExpansionSettlerStallCount = 0;
    end

    local blocked = turn < state.ExpansionBlockedUntil;
    if blocked
        or state.ExpansionPhase == Strategic.EXPANSION_CLOSED
        or snapshot.ActiveMajorWars > 0 then
        state.ExpansionPlanAllowed = 0;
        return;
    end
    if state.ExpansionPhase == Strategic.EXPANSION_NORMAL then
        state.ExpansionPlanAllowed = 1;
        return;
    end

    local recentWindows = math.max(
        1,
        GetNumberParameter("ASAI_EXPANSION_RECENT_SUCCESS_WINDOWS", 2)
    );
    local recentWindow = ScaleStandardTurns(
        GetNumberParameter("ASAI_PLAN_REVIEW_STANDARD", 12) * recentWindows
    );
    local recentSuccess = state.ExpansionLastSuccessTurn >= 0
        and turn - state.ExpansionLastSuccessTurn <= recentWindow;
    local smallEmpireTarget = math.max(
        2,
        GetNumberParameter("ASAI_EXPANSION_RESTRICTED_CITY_TARGET", 4)
    );
    state.ExpansionPlanAllowed = (snapshot.Cities < smallEmpireTarget
        or recentSuccess
        or snapshot.Settlers > 0) and 1 or 0;
end

local function UpdateScaleExpansionAvailability(state, snapshot)
    local densityExit = GetNumberParameter(
        "ASAI_MILITARY_UNITS_PER_PLANNED_CITY_EXIT_X100",
        225
    ) / 100;
    state.ScaleExpansionAllowed = state.ExpansionPlanAllowed == 1
        and state.StrategicPlan == Strategic.EXPAND
        and state.ScaleRecovery == 1
        and snapshot.ActiveMajorWars <= 0
        and (state.MilitaryDominance == 1
            or state.MilitaryReadiness == 0
            or state.MilitaryUnitsPerPlannedCity >= densityExit)
        and 1 or 0;
end

local function GetDesiredMilitaryDominance(state, snapshot, turn)
    local startTurn = ScaleStandardTurns(
        GetNumberParameter("ASAI_MILITARY_DOMINANCE_START_STANDARD", 70)
    );
    if turn < startTurn or snapshot.ActiveMajorWars > 0 then
        return 0;
    end
    local enter = GetNumberParameter(
        "ASAI_MILITARY_DOMINANCE_ENTER_X100",
        175
    ) / 100;
    local exit = GetNumberParameter(
        "ASAI_MILITARY_DOMINANCE_EXIT_X100",
        140
    ) / 100;
    local competitiveEnter = GetNumberParameter(
        "ASAI_MILITARY_DOMINANCE_COMPETITIVE_ENTER_X100",
        90
    ) / 100;
    local competitiveExit = GetNumberParameter(
        "ASAI_MILITARY_DOMINANCE_COMPETITIVE_EXIT_X100",
        80
    ) / 100;
    local densityEnter = GetNumberParameter(
        "ASAI_MILITARY_DOMINANCE_DENSITY_ENTER_X100",
        175
    ) / 100;
    local densityExit = GetNumberParameter(
        "ASAI_MILITARY_DOMINANCE_DENSITY_EXIT_X100",
        150
    ) / 100;
    local rawMilitary = state.RawScores.Military;
    local competitiveMilitary = state.CompetitiveScores.Military or rawMilitary;
    if state.MilitaryDominance == 1 then
        return (rawMilitary >= exit
            and competitiveMilitary >= competitiveExit
            and state.MilitaryUnitsPerPlannedCity >= densityExit) and 1 or 0;
    end
    return (rawMilitary >= enter
        and competitiveMilitary >= competitiveEnter
        and state.MilitaryUnitsPerPlannedCity >= densityEnter) and 1 or 0;
end

local function GetDesiredMilitaryReadiness(state, densityEnabled)
    if state.MilitaryDominance == 1 then
        return 0;
    end
    local enter = GetNumberParameter(
        "ASAI_MILITARY_READINESS_ENTER_X100",
        78
    ) / 100;
    local exit = GetNumberParameter(
        "ASAI_MILITARY_READINESS_EXIT_X100",
        92
    ) / 100;
    local densityEnter = GetNumberParameter(
        "ASAI_MILITARY_UNITS_PER_PLANNED_CITY_ENTER_X100",
        175
    ) / 100;
    local densityExit = GetNumberParameter(
        "ASAI_MILITARY_UNITS_PER_PLANNED_CITY_EXIT_X100",
        225
    ) / 100;
    local militaryScore = math.min(
        state.Scores.Military,
        state.CompetitiveScores.Military or state.Scores.Military
    );
    if state.MilitaryReadiness == 1 then
        return (militaryScore < exit
            or (densityEnabled and state.MilitaryUnitsPerPlannedCity < densityExit))
            and 1 or 0;
    end
    return (militaryScore <= enter
        or (densityEnabled and state.MilitaryUnitsPerPlannedCity <= densityEnter))
        and 1 or 0;
end

function Strategic.IsFocusCompatible(state, focus)
    if focus == RELATIVE_FOCUS_NONE then
        return false;
    end
    if (state.StrategicPlan == Strategic.WAR
            or state.StrategicPlan == Strategic.DEFEND
            or state.StrategicPlan == Strategic.EXPAND)
        and focus == RELATIVE_FOCUS_EMPIRE then
        return false;
    end
    return true;
end

function Strategic.GetRecoveryDecisionScore(state, key, raw)
    local relativeScores = raw and state.RawScores or state.Scores;
    local competitive = state.CompetitiveScores or relativeScores;
    return math.min(relativeScores[key], competitive[key] or relativeScores[key]);
end

local function GetWorstEligibleFocus(state, recoveryThresholds, turn)
    local selected = RELATIVE_FOCUS_NONE;
    local selectedScore = math.huge;
    for _, focus in ipairs({
        RELATIVE_FOCUS_SCIENCE,
        RELATIVE_FOCUS_CULTURE,
        RELATIVE_FOCUS_EMPIRE
    }) do
        local definition = recoveryThresholds[focus];
        local score = Strategic.GetRecoveryDecisionScore(state, definition.Key, false);
        local cooldownUntil = state.FocusCooldownUntil[focus] or -1;
        if Strategic.IsFocusCompatible(state, focus)
            and turn >= cooldownUntil
            and score <= definition.Enter
            and score < selectedScore then
            selected = focus;
            selectedScore = score;
        end
    end
    return selected, selectedScore;
end

local function GetDesiredFocus(state, recoveryThresholds, turn)
    local worstFocus, worstScore = GetWorstEligibleFocus(
        state,
        recoveryThresholds,
        turn
    );
    if state.Focus == RELATIVE_FOCUS_NONE then
        return worstFocus;
    end
    if not Strategic.IsFocusCompatible(state, state.Focus) then
        return worstFocus;
    end

    local currentDefinition = recoveryThresholds[state.Focus];
    local currentScore = Strategic.GetRecoveryDecisionScore(
        state,
        currentDefinition.Key,
        false
    );
    if currentScore >= currentDefinition.Exit then
        return worstFocus;
    end

    local switchMargin = GetNumberParameter(
        "ASAI_RELATIVE_FOCUS_SWITCH_MARGIN_X100",
        5
    ) / 100;
    if worstFocus ~= RELATIVE_FOCUS_NONE
        and worstFocus ~= state.Focus
        and worstScore + switchMargin < currentScore then
        return worstFocus;
    end
    return state.Focus;
end

local function GetFocusScore(state, focus, raw)
    local definition = GetRecoveryThresholds()[focus];
    if definition == nil then
        return 1;
    end
    return Strategic.GetRecoveryDecisionScore(state, definition.Key, raw);
end

function Strategic.GetFocusOwnMetrics(strength, focus)
    if focus == RELATIVE_FOCUS_SCIENCE then
        return strength.Science, strength.Techs;
    end
    if focus == RELATIVE_FOCUS_CULTURE then
        return strength.Culture, strength.Civics;
    end
    if focus == RELATIVE_FOCUS_EMPIRE then
        return strength.Population, strength.Cities;
    end
    return 0, 0;
end

local function StartFocusReview(state, focus, turn, strength)
    local ownYield, ownProgress = Strategic.GetFocusOwnMetrics(strength, focus);
    state.FocusStartedTurn = turn;
    state.FocusReviewTurn = turn;
    state.FocusBaseline = GetFocusScore(state, focus, false);
    state.FocusRawBaseline = GetFocusScore(state, focus, true);
    state.FocusGain = 0;
    state.FocusRawGain = 0;
    state.FocusOwnYieldBaseline = ownYield;
    state.FocusOwnProgressBaseline = ownProgress;
    state.FocusOwnYieldGain = 0;
    state.FocusOwnProgressGain = 0;
    state.FocusResult = RELATIVE_FOCUS_RESULT_NONE;
    state.FocusExecution = 0;
    state.FocusStallCount = 0;
end

local function ResetFocusReviewBaseline(state, turn, strength)
    local ownYield, ownProgress = Strategic.GetFocusOwnMetrics(
        strength,
        state.Focus
    );
    state.FocusReviewTurn = turn;
    state.FocusBaseline = GetFocusScore(state, state.Focus, false);
    state.FocusRawBaseline = GetFocusScore(state, state.Focus, true);
    state.FocusOwnYieldBaseline = ownYield;
    state.FocusOwnProgressBaseline = ownProgress;
end

local function ReviewActiveFocus(playerID, state, turn)
    if state.Focus == RELATIVE_FOCUS_NONE then
        return false;
    end
    local strength = GetStrengthSnapshot(playerID);
    if not Strategic.IsFocusCompatible(state, state.Focus) then
        ResetFocusReviewBaseline(state, turn, strength);
        state.FocusExecution = 0;
        return false;
    end
    if state.FocusReviewTurn < 0
        or state.FocusOwnYieldBaseline < 0
        or state.FocusOwnProgressBaseline < 0 then
        StartFocusReview(state, state.Focus, turn, strength);
        return false;
    end

    local reviewWindow = ScaleStandardTurns(
        GetNumberParameter("ASAI_RELATIVE_FOCUS_REVIEW_STANDARD", 12)
    );
    if turn - state.FocusReviewTurn < reviewWindow then
        return false;
    end

    state.FocusGain = GetFocusScore(state, state.Focus, false) - state.FocusBaseline;
    state.FocusRawGain = GetFocusScore(state, state.Focus, true)
        - state.FocusRawBaseline;
    local ownYield, ownProgress = Strategic.GetFocusOwnMetrics(
        strength,
        state.Focus
    );
    state.FocusOwnYieldGain = state.FocusOwnYieldBaseline > 0
        and ownYield / state.FocusOwnYieldBaseline - 1
        or (ownYield > state.FocusOwnYieldBaseline and 1 or 0);
    state.FocusOwnProgressGain = ownProgress
        - state.FocusOwnProgressBaseline;
    local focusExecution, focusExecutionOk = TryDiagnosticSensor(
        "focus_production_" .. tostring(playerID),
        function() return CountFocusProduction(Players[playerID], state.Focus); end
    );
    state.FocusExecution = focusExecutionOk == 1 and focusExecution or -1;
    local minimumGain = GetNumberParameter(
        "ASAI_RELATIVE_FOCUS_MIN_GAIN_X100",
        3
    ) / 100;
    local minimumRawGain = GetNumberParameter(
        "ASAI_RELATIVE_FOCUS_RAW_MIN_GAIN_X100",
        1
    ) / 100;
    local minimumOwnYieldGain = GetNumberParameter(
        "ASAI_RELATIVE_FOCUS_OWN_YIELD_MIN_GAIN_X100",
        1
    ) / 100;
    local smoothedClosure = state.FocusGain >= minimumGain;
    local rawClosure = state.FocusRawGain >= minimumRawGain;
    local ownGrowth = state.FocusOwnYieldGain >= minimumOwnYieldGain
        or state.FocusOwnProgressGain > 0;
    if not (smoothedClosure and rawClosure and ownGrowth) then
        state.FocusStallCount = state.FocusStallCount + 1;
        state.FocusResult = state.FocusExecution == 0
            and RELATIVE_FOCUS_RESULT_STALLED
            or RELATIVE_FOCUS_RESULT_EXECUTING;
    else
        state.FocusResult = RELATIVE_FOCUS_RESULT_IMPROVING;
        state.FocusStallCount = 0;
    end

    print(string.format(
        "ASAI_FOCUS turn=%d standard_turn=%.1f player=%d focus=%s result=%s queue_response=%d stall_count=%d smoothed_closure=%.3f raw_closure=%.3f own_yield_gain=%.3f own_progress_gain=%d smoothed_ok=%d raw_ok=%d own_ok=%d",
        turn,
        GetStandardEquivalentTurn(turn),
        playerID,
        GetFocusName(state.Focus),
        GetFocusResultName(state.FocusResult),
        state.FocusExecution,
        state.FocusStallCount,
        state.FocusGain,
        state.FocusRawGain,
        state.FocusOwnYieldGain,
        state.FocusOwnProgressGain,
        smoothedClosure and 1 or 0,
        rawClosure and 1 or 0,
        ownGrowth and 1 or 0
    ));

    local stallLimit = math.max(
        1,
        GetNumberParameter("ASAI_RELATIVE_FOCUS_STALL_LIMIT", 3)
    );
    local retireFocus = state.FocusResult ~= RELATIVE_FOCUS_RESULT_IMPROVING
        and state.FocusStallCount >= stallLimit;
    if not retireFocus then
        ResetFocusReviewBaseline(state, turn, strength);
    end
    return retireFocus;
end

function Strategic.AdvanceConfirmedState(
    current,
    candidate,
    streak,
    desired,
    canChange,
    requiredSamples
)
    if desired == current then
        return current, current, 0, false;
    end
    if candidate == desired then
        streak = streak + 1;
    else
        candidate = desired;
        streak = 1;
    end
    local confirmSamples = math.max(1, requiredSamples or GetNumberParameter(
        "ASAI_RELATIVE_CONFIRM_SAMPLES",
        2
    ));
    if canChange and streak >= confirmSamples then
        return desired, desired, 0, true;
    end
    return current, candidate, streak, false;
end

function Strategic.GetPlanOutcomeScore(state, plan)
    local competitive = state.CompetitiveScores or state.RawScores;
    if plan == Strategic.RECOVER then
        if state.StrategicSupport == RELATIVE_FOCUS_SCIENCE then
            return competitive.Science;
        end
        if state.StrategicSupport == RELATIVE_FOCUS_CULTURE then
            return competitive.Culture;
        end
        return math.min(competitive.Science, competitive.Culture);
    end
    if plan == Strategic.EXPAND then
        return competitive.Empire;
    end
    if plan == Strategic.DEFEND then
        return competitive.Military;
    end
    if plan == Strategic.PRESSURE then
        return competitive.Empire;
    end
    if plan == Strategic.WAR then
        return competitive.Overall;
    end
    return competitive.Overall;
end

function Strategic.GetPlanExecution(playerID, state, snapshot)
    if state.StrategicPlan == Strategic.PRESSURE then
        return snapshot.ActiveMajorWars > 0 and 1 or -1;
    end

    local economic = GetEconomicSnapshot(playerID);
    if economic.QueueOk ~= 1 then
        return -1;
    end
    local queue = economic.Queue;
    if state.StrategicPlan == Strategic.WAR
        or state.StrategicPlan == Strategic.DEFEND then
        return queue.Combat;
    end
    if state.StrategicPlan == Strategic.EXPAND then
        return queue.Empire;
    end
    if state.StrategicPlan == Strategic.RECOVER then
        if state.StrategicSupport == RELATIVE_FOCUS_SCIENCE then
            return queue.Science;
        end
        if state.StrategicSupport == RELATIVE_FOCUS_CULTURE then
            return queue.Culture;
        end
        if state.StrategicSupport == RELATIVE_FOCUS_EMPIRE then
            return queue.Empire;
        end
        return queue.Districts + queue.Buildings + queue.Projects;
    end
    return queue.Districts + queue.Buildings + queue.Projects + queue.Empire;
end

function Strategic.GetWarOpponentMilitary(snapshot)
    local total = 0;
    for _, opponentID in ipairs(snapshot.MajorOpponents or {}) do
        if PlayerManager.IsAlive(opponentID) then
            total = total + GetStrengthSnapshot(opponentID).Military;
        end
    end
    return total;
end

function Strategic.StartPlanReview(state, snapshot, strength, turn)
    state.StrategicPlanStartedTurn = turn;
    state.StrategicPlanReviewTurn = turn;
    state.StrategicPlanBaseline = Strategic.GetPlanOutcomeScore(
        state,
        state.StrategicPlan
    );
    state.StrategicPlanBaselineCities = snapshot.Cities;
    state.StrategicPlanBaselineCaptured = snapshot.CapturedCities;
    state.StrategicPlanBaselineSettlers = snapshot.Settlers;
    state.StrategicPlanBaselineActiveWars = snapshot.ActiveMajorWars;
    state.StrategicPlanBaselineCombat = strength.CombatUnits;
    state.StrategicPlanBaselineOwned = snapshot.OwnedPlots;
    state.StrategicPlanBaselineMilitary = strength.Military;
    state.StrategicPlanBaselineEnemyMilitary =
        Strategic.GetWarOpponentMilitary(snapshot);
    state.StrategicPlanBaselineMajorWars = snapshot.MajorWars;
    state.StrategicPlanBaselineCombatEvents = snapshot.MajorCombatEvents;
    state.StrategicPlanBaselineCaptureEvents = snapshot.MajorCaptureEvents;
    state.StrategicPlanBaselinePillageEvents = snapshot.MajorPillageEvents;
    state.StrategicPlanGain = 0;
    state.StrategicPlanResult = RELATIVE_FOCUS_RESULT_NONE;
    state.StrategicPlanExecution = 0;
    state.StrategicPlanStallCount = 0;
end

function Strategic.ResetPlanReviewBaseline(state, snapshot, strength, turn)
    state.StrategicPlanReviewTurn = turn;
    state.StrategicPlanBaseline = Strategic.GetPlanOutcomeScore(
        state,
        state.StrategicPlan
    );
    state.StrategicPlanBaselineCities = snapshot.Cities;
    state.StrategicPlanBaselineCaptured = snapshot.CapturedCities;
    state.StrategicPlanBaselineSettlers = snapshot.Settlers;
    state.StrategicPlanBaselineActiveWars = snapshot.ActiveMajorWars;
    state.StrategicPlanBaselineCombat = strength.CombatUnits;
    state.StrategicPlanBaselineOwned = snapshot.OwnedPlots;
    state.StrategicPlanBaselineMilitary = strength.Military;
    state.StrategicPlanBaselineEnemyMilitary =
        Strategic.GetWarOpponentMilitary(snapshot);
    state.StrategicPlanBaselineMajorWars = snapshot.MajorWars;
    state.StrategicPlanBaselineCombatEvents = snapshot.MajorCombatEvents;
    state.StrategicPlanBaselineCaptureEvents = snapshot.MajorCaptureEvents;
    state.StrategicPlanBaselinePillageEvents = snapshot.MajorPillageEvents;
end

function Strategic.ReviewPlan(playerID, state, snapshot, strength, turn)
    if state.StrategicPlanStartedTurn < 0 then
        Strategic.StartPlanReview(state, snapshot, strength, turn);
        return false;
    end

    local reviewWindow = ScaleStandardTurns(
        GetNumberParameter("ASAI_PLAN_REVIEW_STANDARD", 12)
    );
    if turn - state.StrategicPlanReviewTurn < reviewWindow then
        return false;
    end

    state.StrategicPlanGain = Strategic.GetPlanOutcomeScore(
        state,
        state.StrategicPlan
    ) - state.StrategicPlanBaseline;
    state.StrategicPlanExecution = Strategic.GetPlanExecution(
        playerID,
        state,
        snapshot
    );
    local cityGain = snapshot.Cities - state.StrategicPlanBaselineCities;
    local capturedGain = snapshot.CapturedCities
        - state.StrategicPlanBaselineCaptured;
    local foundedCityGain = (snapshot.Cities - snapshot.CapturedCities)
        - (state.StrategicPlanBaselineCities
            - state.StrategicPlanBaselineCaptured);
    local combatGain = strength.CombatUnits - state.StrategicPlanBaselineCombat;
    local territoryGain = snapshot.OwnedPlots
        - state.StrategicPlanBaselineOwned;
    local combatEvents = math.max(
        0,
        snapshot.MajorCombatEvents
            - state.StrategicPlanBaselineCombatEvents
    );
    local captureEvents = math.max(
        0,
        snapshot.MajorCaptureEvents
            - state.StrategicPlanBaselineCaptureEvents
    );
    local pillageEvents = math.max(
        0,
        snapshot.MajorPillageEvents
            - state.StrategicPlanBaselinePillageEvents
    );
    local enemyMilitary = Strategic.GetWarOpponentMilitary(snapshot);
    local enemyMilitaryChange = enemyMilitary
        - state.StrategicPlanBaselineEnemyMilitary;
    local ownMilitaryChange = strength.Military
        - state.StrategicPlanBaselineMilitary;
    local enemyLossRatio = state.StrategicPlanBaselineEnemyMilitary > 0
        and math.max(0, -enemyMilitaryChange)
            / state.StrategicPlanBaselineEnemyMilitary
        or 0;
    local ownLossRatio = state.StrategicPlanBaselineMilitary > 0
        and math.max(0, -ownMilitaryChange)
            / state.StrategicPlanBaselineMilitary
        or 0;
    local minimumGain = GetNumberParameter("ASAI_PLAN_MIN_GAIN_X100", 2) / 100;
    local improved = state.StrategicPlanGain >= minimumGain;
    local strategicProgress = false;
    local foundedExpansion = foundedCityGain > 0 and captureEvents <= 0;
    local persistentSettler = state.StrategicPlanBaselineSettlers > 0
        and snapshot.Settlers > 0;
    local peacefulWindow = state.StrategicPlanBaselineActiveWars <= 0
        and snapshot.ActiveMajorWars <= 0
        and combatEvents <= 0
        and captureEvents <= 0;
    local previousSettlerStallCount = state.ExpansionSettlerStallCount;
    if foundedExpansion then
        state.ExpansionSettlerStallCount = 0;
        state.ExpansionLastSuccessTurn = turn;
    elseif not persistentSettler then
        state.ExpansionSettlerStallCount = 0;
    elseif peacefulWindow and turn >= state.ExpansionBlockedUntil then
        state.ExpansionSettlerStallCount =
            state.ExpansionSettlerStallCount + 1;
    end
    local expansionStallLimit = math.max(
        1,
        GetNumberParameter("ASAI_EXPANSION_SETTLER_STALL_LIMIT", 2)
    );
    local expansionSettlerStalled = previousSettlerStallCount
            < expansionStallLimit
        and state.ExpansionSettlerStallCount >= expansionStallLimit;
    if state.StrategicPlan == Strategic.EXPAND then
        improved = improved or foundedExpansion;
    elseif state.StrategicPlan == Strategic.DEFEND then
        improved = improved or combatGain > 0;
    elseif state.StrategicPlan == Strategic.PRESSURE then
        improved = improved or snapshot.ActiveMajorWars > 0 or cityGain > 0;
    elseif state.StrategicPlan == Strategic.WAR then
        local minimumEnemyLoss = GetNumberParameter(
            "ASAI_WAR_ENEMY_MILITARY_LOSS_X100",
            12
        ) / 100;
        local minimumPillages = math.max(
            1,
            GetNumberParameter("ASAI_WAR_PILLAGE_PROGRESS_MIN", 2)
        );
        local stableWarSet = snapshot.MajorWars
            == state.StrategicPlanBaselineMajorWars;
        local favorableExchange = stableWarSet
            and enemyLossRatio >= minimumEnemyLoss
            and enemyLossRatio >= ownLossRatio;
        strategicProgress = captureEvents > 0
            or capturedGain > 0
            or favorableExchange
            or pillageEvents >= minimumPillages;
        -- Generic score growth and combat activity do not prove that an
        -- offensive war is advancing.
        improved = strategicProgress;
    end

    if improved then
        state.StrategicPlanResult = RELATIVE_FOCUS_RESULT_IMPROVING;
        state.StrategicPlanStallCount = 0;
    else
        state.StrategicPlanStallCount = state.StrategicPlanStallCount + 1;
        state.StrategicPlanResult = state.StrategicPlanExecution > 0
            and RELATIVE_FOCUS_RESULT_EXECUTING
            or RELATIVE_FOCUS_RESULT_STALLED;
    end

    print(string.format(
        "ASAI_PLAN_REVIEW turn=%d standard_turn=%.1f player=%d plan=%s result=%s execution=%d stall_count=%d gain=%.3f city_gain=%d founded_city_gain=%d capture_gain=%d settlers_baseline=%d settlers=%d settler_stall_count=%d settler_stalled=%d territory_gain=%d combat_unit_gain=%d combat_events=%d capture_events=%d pillage_events=%d own_military_change=%d enemy_military_change=%d enemy_loss_ratio=%.3f own_loss_ratio=%.3f strategic_progress=%d active_major_wars=%d major_wars=%d",
        turn,
        GetStandardEquivalentTurn(turn),
        playerID,
        Strategic.GetPlanName(state.StrategicPlan),
        GetFocusResultName(state.StrategicPlanResult),
        state.StrategicPlanExecution,
        state.StrategicPlanStallCount,
        state.StrategicPlanGain,
        cityGain,
        foundedCityGain,
        capturedGain,
        state.StrategicPlanBaselineSettlers,
        snapshot.Settlers,
        state.ExpansionSettlerStallCount,
        expansionSettlerStalled and 1 or 0,
        territoryGain,
        combatGain,
        combatEvents,
        captureEvents,
        pillageEvents,
        ownMilitaryChange,
        enemyMilitaryChange,
        enemyLossRatio,
        ownLossRatio,
        strategicProgress and 1 or 0,
        snapshot.ActiveMajorWars,
        snapshot.MajorWars
    ));

    local stallLimit = math.max(
        1,
        GetNumberParameter("ASAI_PLAN_STALL_LIMIT", 2)
    );
    local retirePlan = (state.StrategicPlan == Strategic.EXPAND
            and expansionSettlerStalled)
        or (state.StrategicPlan ~= Strategic.DEVELOP
            and state.StrategicPlanResult ~= RELATIVE_FOCUS_RESULT_IMPROVING
            and state.StrategicPlanStallCount >= stallLimit);
    if not retirePlan then
        Strategic.ResetPlanReviewBaseline(state, snapshot, strength, turn);
    end
    return retirePlan, expansionSettlerStalled;
end

function Strategic.GetPlanScores(state, snapshot, turn)
    Strategic.UpdateExpansionState(state, snapshot, turn);
    local competitive = state.CompetitiveScores or state.RawScores;
    local upper = state.WorldUpperScores or competitive;
    local trends = state.Trends or {};
    local knowledge = math.min(competitive.Science, competitive.Culture);
    local knowledgeTrend = math.min(trends.Science or 0, trends.Culture or 0);
    local overallGap = math.max(0, 1 - competitive.Overall);
    local knowledgeGap = math.max(0, 1 - knowledge);
    local empireGap = math.max(0, 1 - competitive.Empire);
    local militaryGap = math.max(0, 1 - competitive.Military);
    local scores = {};

    scores[Strategic.DEVELOP] = 60
        + math.max(0, competitive.Overall - 1) * 30
        + math.max(0, upper.Overall - 0.9) * 20
        + (state.Band == RELATIVE_CONSOLIDATE and 15 or 0);
    scores[Strategic.RECOVER] = 25
        + knowledgeGap * 180
        + overallGap * 45
        + math.max(0, -knowledgeTrend) * 120
        + (state.SevereCatchup == 1 and 20
            or (state.Band == RELATIVE_CATCHUP and 10 or 0));
    scores[Strategic.EXPAND] = 25
        + empireGap * 180
        + (state.ScaleRecovery == 1 and 25 or 0);

    local openingEnd = ScaleStandardTurns(
        GetNumberParameter("ASAI_OPENING_EXPANSION_END_STANDARD", 70)
    );
    local openingTarget = math.max(
        2,
        GetNumberParameter("ASAI_OPENING_EXPANSION_CITY_TARGET", 4)
    );
    if turn < openingEnd and snapshot.Cities < openingTarget then
        scores[Strategic.EXPAND] = scores[Strategic.EXPAND]
            + 80 + (openingTarget - snapshot.Cities) * 20;
    end
    if snapshot.ActiveMajorWars > 0 then
        scores[Strategic.EXPAND] = 0;
    elseif state.ExpansionPlanAllowed ~= 1 then
        scores[Strategic.EXPAND] = 0;
    elseif state.ExpansionPhase == Strategic.EXPANSION_RESTRICTED then
        local restrictedPercent = math.max(
            0,
            GetNumberParameter("ASAI_EXPANSION_RESTRICTED_SCORE_PERCENT", 50)
        );
        scores[Strategic.EXPAND] = scores[Strategic.EXPAND]
            * restrictedPercent / 100;
    end

    local densityStart = ScaleStandardTurns(
        GetNumberParameter("ASAI_MILITARY_DENSITY_START_STANDARD", 50)
    );
    local densityTarget = GetNumberParameter(
        "ASAI_MILITARY_UNITS_PER_PLANNED_CITY_EXIT_X100",
        225
    ) / 100;
    local densityGap = turn >= densityStart
        and math.max(0, densityTarget - state.MilitaryUnitsPerPlannedCity) or 0;
    scores[Strategic.DEFEND] = 20
        + militaryGap * 180
        + densityGap * 40
        + (state.MilitaryReadiness == 1 and 35 or 0);
    if state.MilitaryDominance == 1 then
        scores[Strategic.DEFEND] = 0;
    end

    scores[Strategic.PRESSURE] = 0;
    local pressureStart = ScaleStandardTurns(
        GetNumberParameter("ASAI_PLAN_PRESSURE_START_STANDARD", 55)
    );
    local pressureReady = turn >= pressureStart
        and snapshot.ActiveMajorWars <= 0
        and competitive.Military >= 1.25
        and upper.Military >= 0.85;
    if state.MilitaryDominance == 1 or pressureReady then
        scores[Strategic.PRESSURE] = 85
            + math.max(0, competitive.Military - 1.2) * 80
            + (state.MilitaryDominance == 1 and 20 or 0)
            - (knowledgeGap + empireGap) * 35;
    end
    local warStopLoss = snapshot.ActiveMajorWars > 0
        and turn < (state.StrategicPlanCooldownUntil[Strategic.WAR] or -1);
    scores[Strategic.WAR] = snapshot.ActiveMajorWars > 0
        and not warStopLoss
        and 1000 + militaryGap * 100 or 0;

    local currentPlan = state.StrategicPlan;
    if currentPlan ~= nil and state.StrategicPlanStallCount > 0 then
        scores[currentPlan] = math.max(
            0,
            (scores[currentPlan] or 0) - state.StrategicPlanStallCount * 15
        );
    end
    for plan, cooldownUntil in pairs(state.StrategicPlanCooldownUntil) do
        if turn < cooldownUntil
            and plan ~= Strategic.DEFEND then
            scores[plan] = 0;
        end
    end
    return scores;
end

function Strategic.SelectPlan(state, snapshot, scores)
    local warStopLoss = snapshot.ActiveMajorWars > 0
        and snapshot.Turn
            < (state.StrategicPlanCooldownUntil[Strategic.WAR] or -1);
    if snapshot.ActiveMajorWars > 0 and not warStopLoss then
        return Strategic.WAR, "active_major_war";
    end
    local emergency = GetNumberParameter(
        "ASAI_MILITARY_READINESS_EMERGENCY_X100",
        60
    ) / 100;
    local militaryScore = math.min(
        state.RawScores.Military,
        state.CompetitiveScores.Military or state.RawScores.Military
    );
    if militaryScore <= emergency then
        return Strategic.DEFEND, warStopLoss
            and "war_stop_loss_military_emergency"
            or "military_emergency";
    end

    local selected = Strategic.DEVELOP;
    local selectedScore = scores[selected] or 0;
    for _, plan in ipairs({
        Strategic.WAR,
        Strategic.DEFEND,
        Strategic.PRESSURE,
        Strategic.EXPAND,
        Strategic.RECOVER,
        Strategic.DEVELOP
    }) do
        local score = scores[plan] or 0;
        if score > selectedScore then
            selected = plan;
            selectedScore = score;
        end
    end

    local currentScore = scores[state.StrategicPlan] or 0;
    local switchMargin = GetNumberParameter("ASAI_PLAN_SWITCH_MARGIN", 15);
    if selected ~= state.StrategicPlan
        and currentScore > 0
        and selectedScore < currentScore + switchMargin then
        return state.StrategicPlan, "switch_cost";
    end
    if state.StrategicPlan == Strategic.EXPAND
        and state.ExpansionPlanAllowed ~= 1 then
        if state.ExpansionPhase == Strategic.EXPANSION_CLOSED then
            return selected, "expansion_era_closed";
        end
        if snapshot.Turn < state.ExpansionBlockedUntil then
            return selected, "expansion_stall_reallocate";
        end
        return selected, "expansion_era_restricted";
    end
    return selected, warStopLoss
        and "war_stop_loss_reallocate"
        or "highest_score";
end

function Strategic.UpdateSupport(state)
    state.StrategicSupport = Strategic.IsFocusCompatible(state, state.Focus)
        and state.Focus or RELATIVE_FOCUS_NONE;
    SyncRecoveryFlags(state);
end

local function EvaluateRelativeState(playerID)
    if not IsMajorAI(playerID) or GetNumberParameter("ASAI_RELATIVE_PACING_ENABLED", 1) ~= 1 then
        return GetNeutralRelativeState();
    end

    local turn = Game.GetCurrentGameTurn();
    local runtime = m_RelativeRuntime[playerID];
    if runtime ~= nil and runtime.RuntimeTurn == turn then
        return runtime;
    end

    local startTurn = ScaleStandardTurns(
        GetNumberParameter("ASAI_RELATIVE_START_TURN_STANDARD", 35)
    );
    if turn < startTurn then
        local neutral = GetNeutralRelativeState();
        neutral.RuntimeTurn = turn;
        m_RelativeRuntime[playerID] = neutral;
        return neutral;
    end

    local player = Players[playerID];
    local state = ReadRelativeState(player);
    state.RuntimeTurn = turn;
    state.EvaluatedThisTurn = false;
    if state.LastSampleTurn == turn then
        m_RelativeRuntime[playerID] = state;
        return state;
    end
    local humanStrength = GetHumanReference();
    if humanStrength == nil then
        m_RelativeRuntime[playerID] = state;
        return state;
    end

    local strengthSnapshot = GetStrengthSnapshot(playerID);
    local measurements = GetRelativeMeasurements(strengthSnapshot, humanStrength);
    local worldReference = Strategic.GetWorldReference();
    local competitiveReference = worldReference ~= nil
        and Strategic.GetCompetitiveReference(humanStrength, worldReference.Median)
        or humanStrength;
    local upperReference = worldReference ~= nil
        and worldReference.Upper or humanStrength;
    local competitiveMeasurements = GetRelativeMeasurements(
        strengthSnapshot,
        competitiveReference
    );
    local upperMeasurements = GetRelativeMeasurements(
        strengthSnapshot,
        upperReference
    );
    local initialized = state.LastSampleTurn >= 0;
    local smoothingAlpha = GetSmoothingAlpha();
    for _, key in ipairs({ "Overall", "Science", "Culture", "Empire", "Military" }) do
        local sampleTrend = initialized
            and measurements.Raw[key] - state.RawScores[key] or 0;
        state.Trends[key] = initialized
            and state.Trends[key] + smoothingAlpha * (sampleTrend - state.Trends[key])
            or 0;
    end
    state.RawScores = measurements.Raw;
    state.CompetitiveScores = competitiveMeasurements.Raw;
    state.WorldUpperScores = upperMeasurements.Raw;
    state.RawRatios = measurements.RawRatios;
    state.ControlledRatios = measurements.ControlledRatios;
    state.Scores = SmoothScores(
        state.Scores,
        measurements.Controlled,
        smoothingAlpha,
        initialized
    );
    local empireSnapshot = GetSnapshot(playerID);
    local plannedExpansion = (empireSnapshot.Settlers
        + empireSnapshot.InFlightSettlers > 0) and 1 or 0;
    state.MilitaryPlannedCities = strengthSnapshot.Cities + plannedExpansion;
    state.MilitaryUnitsPerPlannedCity = state.MilitaryPlannedCities > 0
        and strengthSnapshot.CombatUnits / state.MilitaryPlannedCities or 0;
    if state.MilitaryDominance == 1 and empireSnapshot.ActiveMajorWars > 0 then
        state.MilitaryDominance = 0;
        player:SetProperty(MILITARY_DOMINANCE_PROPERTY, 0);
        print(string.format(
            "ASAI_DOMINANCE turn=%d standard_turn=%.1f player=%d raw_military=%.3f competitive_military=%.3f military=%.3f planned_cities=%d units_per_planned_city=%.2f from=on to=off reason=active_major_war",
            turn,
            GetStandardEquivalentTurn(turn),
            playerID,
            state.RawScores.Military,
            state.CompetitiveScores.Military or state.RawScores.Military,
            state.Scores.Military,
            state.MilitaryPlannedCities,
            state.MilitaryUnitsPerPlannedCity
        ));
    end
    Strategic.UpdateExpansionState(state, empireSnapshot, turn);
    UpdateScaleExpansionAvailability(state, empireSnapshot);
    state.LastSampleTurn = turn;

    local thresholds = GetCompetitionThresholds(math.floor(humanStrength.Era + 0.5));
    state.Stage = thresholds.Stage;
    local evaluationInterval = ScaleStandardTurns(
        GetNumberParameter("ASAI_RELATIVE_CHECK_INTERVAL_STANDARD", 4)
    );
    local evaluationDue = state.LastEvaluationTurn < 0
        or turn - state.LastEvaluationTurn >= evaluationInterval;

    if evaluationDue then
        local previousBand = state.Band;
        local previousFocus = state.Focus;
        local previousSevere = state.SevereCatchup;
        local previousMilitaryReadiness = state.MilitaryReadiness;
        local previousMilitaryDominance = state.MilitaryDominance;
        local militaryDominanceChanged = false;
        local previousScaleRecovery = state.ScaleRecovery;
        local previousStrategicPlan = state.StrategicPlan;
        local previousStrategicSupport = state.StrategicSupport;
        local strategicPlanChanged = false;
        local strategicPlanReason = "unchanged";
        local previousSupport = previousSevere == 1 and "strong"
            or (previousBand == RELATIVE_CATCHUP and "mild" or "none");
        local minimumDwell = ScaleStandardTurns(
            GetNumberParameter("ASAI_RELATIVE_MIN_DWELL_STANDARD", 12)
        );
        local cooldown = ScaleStandardTurns(
            GetNumberParameter("ASAI_RELATIVE_COOLDOWN_STANDARD", 8)
        );

        local desiredBand = GetDesiredBand(state, thresholds);
        local canChangeBand = turn - state.BandChangedTurn >= minimumDwell;
        if state.Band == RELATIVE_MATCHED and turn < state.BandCooldownUntil then
            canChangeBand = false;
        end
        local bandChanged = false;
        state.Band,
        state.BandCandidate,
        state.BandStreak,
        bandChanged = Strategic.AdvanceConfirmedState(
            state.Band,
            state.BandCandidate,
            state.BandStreak,
            desiredBand,
            canChangeBand
        );
        if bandChanged then
            state.BandChangedTurn = turn;
            if state.Band == RELATIVE_MATCHED then
                state.BandCooldownUntil = turn + cooldown;
            end
        end

        local desiredSevere = GetDesiredSevereCatchup(state, empireSnapshot);
        local canChangeSevere = turn - state.SevereChangedTurn >= minimumDwell;
        local severeChanged = false;
        state.SevereCatchup,
        state.SevereCandidate,
        state.SevereStreak,
        severeChanged = Strategic.AdvanceConfirmedState(
            state.SevereCatchup,
            state.SevereCandidate,
            state.SevereStreak,
            desiredSevere,
            canChangeSevere
        );
        if severeChanged then
            state.SevereChangedTurn = turn;
        end

        local scaleStartTurn = ScaleStandardTurns(
            GetNumberParameter("ASAI_SCALE_RECOVERY_START_STANDARD", 50)
        );
        local scaleEnabled = turn >= scaleStartTurn;
        local desiredScaleRecovery = scaleEnabled
            and GetDesiredScaleRecovery(state) or 0;
        local scaleEmergencyThreshold = GetNumberParameter(
            "ASAI_SCALE_RECOVERY_EMERGENCY_X100",
            60
        ) / 100;
        local scaleEmergencyScore = math.min(
            state.RawScores.Empire,
            state.CompetitiveScores.Empire or state.RawScores.Empire
        );
        local scaleEmergency = scaleEnabled
            and scaleEmergencyScore <= scaleEmergencyThreshold;
        local canChangeScaleRecovery = turn - state.ScaleRecoveryChangedTurn
            >= minimumDwell;
        if state.ScaleRecovery == 0
            and turn < state.ScaleRecoveryCooldownUntil then
            canChangeScaleRecovery = false;
        end
        local scaleRecoveryChanged = false;
        if state.ScaleRecovery == 0 and scaleEmergency then
            state.ScaleRecovery = 1;
            state.ScaleRecoveryCandidate = 1;
            state.ScaleRecoveryStreak = 0;
            scaleRecoveryChanged = true;
        else
            state.ScaleRecovery,
            state.ScaleRecoveryCandidate,
            state.ScaleRecoveryStreak,
            scaleRecoveryChanged = Strategic.AdvanceConfirmedState(
                state.ScaleRecovery,
                state.ScaleRecoveryCandidate,
                state.ScaleRecoveryStreak,
                desiredScaleRecovery,
                canChangeScaleRecovery
            );
        end
        if scaleRecoveryChanged then
            state.ScaleRecoveryChangedTurn = turn;
            if state.ScaleRecovery == 0 then
                state.ScaleRecoveryCooldownUntil = turn + cooldown;
            end
        end

        state.MilitaryDominance = GetDesiredMilitaryDominance(
            state,
            empireSnapshot,
            turn
        );
        militaryDominanceChanged = state.MilitaryDominance
            ~= previousMilitaryDominance;

        local densityStartTurn = ScaleStandardTurns(
            GetNumberParameter("ASAI_MILITARY_DENSITY_START_STANDARD", 50)
        );
        local densityEnabled = turn >= densityStartTurn;
        local densityEnter = GetNumberParameter(
            "ASAI_MILITARY_UNITS_PER_PLANNED_CITY_ENTER_X100",
            175
        ) / 100;
        local militaryDensityGap = densityEnabled
            and state.MilitaryUnitsPerPlannedCity <= densityEnter;
        local desiredMilitaryReadiness = GetDesiredMilitaryReadiness(
            state,
            densityEnabled
        );
        local emergencyThreshold = GetNumberParameter(
            "ASAI_MILITARY_READINESS_EMERGENCY_X100",
            60
        ) / 100;
        local militaryEmergencyScore = math.min(
            state.RawScores.Military,
            state.CompetitiveScores.Military or state.RawScores.Military
        );
        local militaryEmergency = militaryEmergencyScore <= emergencyThreshold;
        local canChangeMilitaryReadiness = turn - state.MilitaryReadinessChangedTurn
            >= minimumDwell;
        if state.MilitaryReadiness == 0
            and turn < state.MilitaryReadinessCooldownUntil then
            canChangeMilitaryReadiness = false;
        end
        local militaryReadinessChanged = false;
        if state.MilitaryDominance == 1 then
            state.MilitaryReadiness = 0;
            state.MilitaryReadinessCandidate = 0;
            state.MilitaryReadinessStreak = 0;
            militaryReadinessChanged = previousMilitaryReadiness == 1;
        elseif state.MilitaryReadiness == 0
            and militaryEmergency then
            state.MilitaryReadiness = 1;
            state.MilitaryReadinessCandidate = 1;
            state.MilitaryReadinessStreak = 0;
            militaryReadinessChanged = true;
        else
            state.MilitaryReadiness,
            state.MilitaryReadinessCandidate,
            state.MilitaryReadinessStreak,
            militaryReadinessChanged = Strategic.AdvanceConfirmedState(
                state.MilitaryReadiness,
                state.MilitaryReadinessCandidate,
                state.MilitaryReadinessStreak,
                desiredMilitaryReadiness,
                canChangeMilitaryReadiness
            );
        end
        if militaryReadinessChanged then
            state.MilitaryReadinessChangedTurn = turn;
            if state.MilitaryReadiness == 0 then
                state.MilitaryReadinessCooldownUntil = turn + cooldown;
            end
        end
        UpdateScaleExpansionAvailability(state, empireSnapshot);

        if state.StrategicPlanOutcomeSchema < Strategic.OUTCOME_SCHEMA then
            local previousOutcomeSchema = state.StrategicPlanOutcomeSchema;
            local resetPressureBaseline = 0;
            local resetWarBaseline = 0;
            local resetExpansionBaseline = 0;
            local resetOutcomeBaseline = (state.StrategicPlan == Strategic.PRESSURE
                    and previousOutcomeSchema < 1)
                or (state.StrategicPlan == Strategic.WAR
                    and previousOutcomeSchema < 3)
                or (state.StrategicPlan == Strategic.EXPAND
                    and previousOutcomeSchema < Strategic.OUTCOME_SCHEMA);
            if resetOutcomeBaseline
                and state.StrategicPlanStartedTurn >= 0 then
                Strategic.ResetPlanReviewBaseline(
                    state,
                    empireSnapshot,
                    strengthSnapshot,
                    turn
                );
                state.StrategicPlanGain = 0;
                state.StrategicPlanResult = RELATIVE_FOCUS_RESULT_NONE;
                state.StrategicPlanExecution = 0;
                state.StrategicPlanStallCount = 0;
                if state.StrategicPlan == Strategic.PRESSURE then
                    resetPressureBaseline = 1;
                elseif state.StrategicPlan == Strategic.WAR then
                    resetWarBaseline = 1;
                else
                    resetExpansionBaseline = 1;
                end
            end
            state.StrategicPlanOutcomeSchema = Strategic.OUTCOME_SCHEMA;
            print(string.format(
                "ASAI_PLAN_MIGRATION turn=%d standard_turn=%.1f player=%d plan=%s from_schema=%d to_schema=%d reset_pressure_baseline=%d reset_war_baseline=%d reset_expansion_baseline=%d",
                turn,
                GetStandardEquivalentTurn(turn),
                playerID,
                Strategic.GetPlanName(state.StrategicPlan),
                previousOutcomeSchema,
                state.StrategicPlanOutcomeSchema,
                resetPressureBaseline,
                resetWarBaseline,
                resetExpansionBaseline
            ));
        end

        local strategicPlanRetired, expansionSettlerStalled = Strategic.ReviewPlan(
            playerID,
            state,
            empireSnapshot,
            strengthSnapshot,
            turn
        );
        if expansionSettlerStalled then
            local expansionCooldownStandard = GetNumberParameter(
                "ASAI_EXPANSION_STALL_COOLDOWN_STANDARD",
                16
            );
            local expansionCooldown = ScaleStandardTurns(
                expansionCooldownStandard
            );
            state.StrategicPlanCooldownUntil[Strategic.EXPAND] = math.max(
                state.StrategicPlanCooldownUntil[Strategic.EXPAND] or -1,
                turn + expansionCooldown
            );
            state.ExpansionBlockedUntil = math.max(
                state.ExpansionBlockedUntil,
                turn + expansionCooldown
            );
            print(string.format(
                "ASAI_EXPANSION_STOP_LOSS turn=%d standard_turn=%.1f player=%d era=%d phase=%s plan=%s settlers=%d settler_stall_count=%d cooldown_standard=%d cooldown_until=%d",
                turn,
                GetStandardEquivalentTurn(turn),
                playerID,
                empireSnapshot.Era,
                Strategic.GetExpansionPhaseName(state.ExpansionPhase),
                Strategic.GetPlanName(state.StrategicPlan),
                empireSnapshot.Settlers,
                state.ExpansionSettlerStallCount,
                expansionCooldownStandard,
                state.ExpansionBlockedUntil
            ));
        end
        if strategicPlanRetired then
            local retiredPlan = state.StrategicPlan;
            local retiredCooldownStandard = nil;
            if not (retiredPlan == Strategic.EXPAND
                    and expansionSettlerStalled) then
                retiredCooldownStandard = retiredPlan == Strategic.WAR
                    and GetNumberParameter(
                        "ASAI_WAR_STOP_LOSS_COOLDOWN_STANDARD",
                        20
                    )
                    or GetNumberParameter(
                        "ASAI_PLAN_STALL_COOLDOWN_STANDARD",
                        16
                    );
                if retiredPlan == Strategic.WAR then
                    retiredCooldownStandard = retiredCooldownStandard
                        + math.max(0, empireSnapshot.MajorWars - 1)
                            * GetNumberParameter(
                                "ASAI_WAR_STOP_LOSS_EXTRA_WAR_STANDARD",
                                8
                            );
                end
                local retiredCooldown = ScaleStandardTurns(
                    retiredCooldownStandard
                );
                state.StrategicPlanCooldownUntil[retiredPlan] = math.max(
                    state.StrategicPlanCooldownUntil[retiredPlan] or -1,
                    turn + retiredCooldown
                );
            end
            if retiredPlan == Strategic.WAR then
                print(string.format(
                    "ASAI_WAR_STOP_LOSS turn=%d standard_turn=%.1f player=%d stall_count=%d major_wars=%d active_major_wars=%d cooldown_standard=%d cooldown_until=%d",
                    turn,
                    GetStandardEquivalentTurn(turn),
                    playerID,
                    state.StrategicPlanStallCount,
                    empireSnapshot.MajorWars,
                    empireSnapshot.ActiveMajorWars,
                    retiredCooldownStandard,
                    state.StrategicPlanCooldownUntil[Strategic.WAR]
                ));
            end
        end
        Strategic.UpdateExpansionState(state, empireSnapshot, turn);
        state.StrategicPlanScores = Strategic.GetPlanScores(
            state,
            empireSnapshot,
            turn
        );
        local desiredStrategicPlan;
        desiredStrategicPlan, strategicPlanReason = Strategic.SelectPlan(
            state,
            empireSnapshot,
            state.StrategicPlanScores
        );
        local strategicPlanMinimumDwell = ScaleStandardTurns(
            GetNumberParameter("ASAI_PLAN_MIN_DWELL_STANDARD", 12)
        );
        local forcedStrategicPlan = strategicPlanReason == "active_major_war"
            or strategicPlanReason == "military_emergency"
            or strategicPlanReason == "war_stop_loss_military_emergency"
            or strategicPlanReason == "expansion_era_closed"
            or strategicPlanReason == "expansion_era_restricted"
            or strategicPlanReason == "expansion_stall_reallocate"
            or (strategicPlanReason == "war_stop_loss_reallocate"
                and state.StrategicPlan == Strategic.WAR);
        if desiredStrategicPlan ~= state.StrategicPlan
            and (strategicPlanRetired or forcedStrategicPlan) then
            state.StrategicPlan = desiredStrategicPlan;
            state.StrategicPlanCandidate = desiredStrategicPlan;
            state.StrategicPlanStreak = 0;
            strategicPlanChanged = true;
        else
            local canChangeStrategicPlan = turn - state.StrategicPlanChangedTurn
                >= strategicPlanMinimumDwell;
            if state.StrategicPlan == Strategic.WAR
                and empireSnapshot.ActiveMajorWars <= 0 then
                canChangeStrategicPlan = true;
            end
            state.StrategicPlan,
            state.StrategicPlanCandidate,
            state.StrategicPlanStreak,
            strategicPlanChanged = Strategic.AdvanceConfirmedState(
                state.StrategicPlan,
                state.StrategicPlanCandidate,
                state.StrategicPlanStreak,
                desiredStrategicPlan,
                canChangeStrategicPlan,
                math.max(1, GetNumberParameter("ASAI_PLAN_CONFIRM_SAMPLES", 2))
            );
        end
        if strategicPlanChanged then
            state.StrategicPlanChangedTurn = turn;
        end
        state.StrategicPlanScore = state.StrategicPlanScores[state.StrategicPlan] or 0;
        UpdateScaleExpansionAvailability(state, empireSnapshot);

        if state.FocusHandoffReady
            and turn - state.FocusChangedTurn >= minimumDwell then
            state.FocusHandoffReady = false;
        end

        local recoveryThresholds = GetRecoveryThresholds();
        local focusChanged = false;
        local focusRetired = ReviewActiveFocus(playerID, state, turn);
        if focusRetired then
            local stalledCooldown = ScaleStandardTurns(
                GetNumberParameter("ASAI_RELATIVE_FOCUS_STALL_COOLDOWN_STANDARD", 16)
            );
            state.FocusCooldownUntil[state.Focus] = math.max(
                state.FocusCooldownUntil[state.Focus] or -1,
                turn + stalledCooldown
            );
            state.Focus = RELATIVE_FOCUS_NONE;
            state.FocusCandidate = RELATIVE_FOCUS_NONE;
            state.FocusStreak = 0;
            state.FocusChangedTurn = turn;
            state.FocusHandoffReady = true;
            focusChanged = true;

            -- Start confirming the best alternative immediately. The failed
            -- pillar remains on cooldown, but the shared focus slot does not.
            local desiredFocus = GetDesiredFocus(state, recoveryThresholds, turn);
            local handoffChanged = false;
            state.Focus,
            state.FocusCandidate,
            state.FocusStreak,
            handoffChanged = Strategic.AdvanceConfirmedState(
                state.Focus,
                state.FocusCandidate,
                state.FocusStreak,
                desiredFocus,
                true
            );
            if handoffChanged then
                state.FocusHandoffReady = false;
            end
        else
            local desiredFocus = GetDesiredFocus(state, recoveryThresholds, turn);
            local canChangeFocus = state.FocusHandoffReady
                or turn - state.FocusChangedTurn >= minimumDwell
                or not Strategic.IsFocusCompatible(state, state.Focus);
            state.Focus,
            state.FocusCandidate,
            state.FocusStreak,
            focusChanged = Strategic.AdvanceConfirmedState(
                state.Focus,
                state.FocusCandidate,
                state.FocusStreak,
                desiredFocus,
                canChangeFocus
            );
        end
        if focusChanged then
            state.FocusChangedTurn = turn;
            if previousFocus ~= RELATIVE_FOCUS_NONE and not focusRetired then
                state.FocusCooldownUntil[previousFocus] = math.max(
                    state.FocusCooldownUntil[previousFocus] or -1,
                    turn + cooldown
                );
            end
            if state.Focus ~= RELATIVE_FOCUS_NONE then
                state.FocusHandoffReady = false;
                StartFocusReview(
                    state,
                    state.Focus,
                    turn,
                    strengthSnapshot
                );
            end
        end

        Strategic.UpdateSupport(state);
        if strategicPlanChanged then
            Strategic.StartPlanReview(state, empireSnapshot, strengthSnapshot, turn);
        elseif previousStrategicSupport ~= state.StrategicSupport then
            Strategic.ResetPlanReviewBaseline(
                state,
                empireSnapshot,
                strengthSnapshot,
                turn
            );
        end
        state.LastEvaluationTurn = turn;
        state.EvaluatedThisTurn = true;

        if bandChanged then
            print(string.format(
                "ASAI_PACING turn=%d standard_turn=%.1f player=%d stage=%s raw=%.3f controlled=%.3f from=%s to=%s",
                turn,
                GetStandardEquivalentTurn(turn),
                playerID,
                state.Stage,
                state.RawScores.Overall,
                state.Scores.Overall,
                GetBandName(previousBand),
                GetBandName(state.Band)
            ));
        end
        if severeChanged then
            print(string.format(
                "ASAI_SUPPORT turn=%d standard_turn=%.1f player=%d relative=%.3f second_core=%.3f from=%s to=%s",
                turn,
                GetStandardEquivalentTurn(turn),
                playerID,
                state.Scores.Overall,
                GetSecondWeakestCorePillarScore(state),
                previousSupport,
                GetSupportName(state)
            ));
        end
        if scaleRecoveryChanged then
            local scaleReason = state.ScaleRecovery == 0 and "recovered"
                or (scaleEmergency and "critical_gap" or "sustained_gap");
            print(string.format(
                "ASAI_SCALE turn=%d standard_turn=%.1f player=%d raw_empire=%.3f empire=%.3f from=%s to=%s reason=%s",
                turn,
                GetStandardEquivalentTurn(turn),
                playerID,
                state.RawScores.Empire,
                state.Scores.Empire,
                previousScaleRecovery == 1 and "on" or "off",
                state.ScaleRecovery == 1 and "on" or "off",
                scaleReason
            ));
        end
        if militaryDominanceChanged then
            local dominanceReason = state.MilitaryDominance == 1
                and "military_surplus" or "advantage_spent";
            print(string.format(
                "ASAI_DOMINANCE turn=%d standard_turn=%.1f player=%d raw_military=%.3f competitive_military=%.3f military=%.3f planned_cities=%d units_per_planned_city=%.2f from=%s to=%s reason=%s",
                turn,
                GetStandardEquivalentTurn(turn),
                playerID,
                state.RawScores.Military,
                state.CompetitiveScores.Military or state.RawScores.Military,
                state.Scores.Military,
                state.MilitaryPlannedCities,
                state.MilitaryUnitsPerPlannedCity,
                previousMilitaryDominance == 1 and "on" or "off",
                state.MilitaryDominance == 1 and "on" or "off",
                dominanceReason
            ));
        end
        if militaryReadinessChanged then
            local readinessReason = state.MilitaryDominance == 1
                and "military_surplus"
                or (state.MilitaryReadiness == 0 and "recovered"
                or (militaryEmergency and "critical_gap"
                    or (militaryDensityGap and "force_density" or "sustained_gap")));
            print(string.format(
                "ASAI_READINESS turn=%d standard_turn=%.1f player=%d raw_military=%.3f military=%.3f planned_cities=%d units_per_planned_city=%.2f from=%s to=%s reason=%s",
                turn,
                GetStandardEquivalentTurn(turn),
                playerID,
                state.RawScores.Military,
                state.Scores.Military,
                state.MilitaryPlannedCities,
                state.MilitaryUnitsPerPlannedCity,
                previousMilitaryReadiness == 1 and "on" or "off",
                state.MilitaryReadiness == 1 and "on" or "off",
                readinessReason
            ));
        end
        if strategicPlanChanged or previousStrategicSupport ~= state.StrategicSupport then
            print(string.format(
                "ASAI_PLAN turn=%d standard_turn=%.1f player=%d from=%s to=%s support_from=%s support_to=%s reason=%s score=%.1f develop=%.1f recover=%.1f expand=%.1f defend=%.1f pressure=%.1f war=%.1f result=%s expansion_phase=%s expansion_allowed=%d expansion_blocked=%d settler_stalls=%d",
                turn,
                GetStandardEquivalentTurn(turn),
                playerID,
                Strategic.GetPlanName(previousStrategicPlan),
                Strategic.GetPlanName(state.StrategicPlan),
                Strategic.GetSupportName(previousStrategicSupport),
                Strategic.GetSupportName(state.StrategicSupport),
                strategicPlanReason,
                state.StrategicPlanScore,
                state.StrategicPlanScores[Strategic.DEVELOP] or 0,
                state.StrategicPlanScores[Strategic.RECOVER] or 0,
                state.StrategicPlanScores[Strategic.EXPAND] or 0,
                state.StrategicPlanScores[Strategic.DEFEND] or 0,
                state.StrategicPlanScores[Strategic.PRESSURE] or 0,
                state.StrategicPlanScores[Strategic.WAR] or 0,
                GetFocusResultName(state.StrategicPlanResult),
                Strategic.GetExpansionPhaseName(state.ExpansionPhase),
                state.ExpansionPlanAllowed,
                turn < state.ExpansionBlockedUntil and 1 or 0,
                state.ExpansionSettlerStallCount
            ));
        end
        if focusChanged then
            print(string.format(
                "ASAI_RECOVERY turn=%d standard_turn=%.1f player=%d raw_science=%.3f raw_culture=%.3f raw_empire=%.3f science=%.3f culture=%.3f empire=%.3f from=%s to=%s result=%s handoff_ready=%d smoothed_closure=%.3f raw_closure=%.3f own_yield_gain=%.3f own_progress_gain=%d",
                turn,
                GetStandardEquivalentTurn(turn),
                playerID,
                state.RawScores.Science,
                state.RawScores.Culture,
                state.RawScores.Empire,
                state.Scores.Science,
                state.Scores.Culture,
                state.Scores.Empire,
                GetFocusName(previousFocus),
                GetFocusName(state.Focus),
                GetFocusResultName(state.FocusResult),
                state.FocusHandoffReady and 1 or 0,
                state.FocusGain,
                state.FocusRawGain,
                state.FocusOwnYieldGain,
                state.FocusOwnProgressGain
            ));
        end
    end

    SyncResultYields(playerID, player, state, turn);
    StoreRelativeState(player, state);
    m_RelativeRuntime[playerID] = state;
    return state;
end

GetRelativeState = function(playerID)
    return EvaluateRelativeState(playerID);
end

local function IsRelativeCatchup(playerID, threshold)
    local state = GetRelativeState(playerID);
    return state.StrategicPlan == Strategic.RECOVER
        and state.SevereCatchup ~= 1;
end
function ASAI_IsRelativeCatchup(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsRelativeCatchup",
        IsRelativeCatchup,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsRelativeCatchup.Add(ASAI_IsRelativeCatchup);

local function IsRelativeSevereCatchup(playerID, threshold)
    local state = GetRelativeState(playerID);
    return state.StrategicPlan == Strategic.RECOVER
        and state.SevereCatchup == 1;
end
function ASAI_IsRelativeSevereCatchup(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsRelativeSevereCatchup",
        IsRelativeSevereCatchup,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsRelativeSevereCatchup.Add(ASAI_IsRelativeSevereCatchup);

function ThreatResponse.GetUnitProfile(unitInfo)
    if unitInfo == nil then
        return 0, 0, 0, 0, 0;
    end
    local isAir = unitInfo.Domain == "DOMAIN_AIR" and 1 or 0;
    local isBomber = unitInfo.PromotionClass == "PROMOTION_CLASS_AIR_BOMBER"
        and 1 or 0;
    local isGDR = unitInfo.UnitType == "UNIT_GIANT_DEATH_ROBOT" and 1 or 0;
    local isAirDefense = ((tonumber(unitInfo.AntiAirCombat) or 0) > 0
            or unitInfo.PromotionClass == "PROMOTION_CLASS_AIR_FIGHTER")
        and 1 or 0;
    local isGDRCounter = (isBomber == 1 or isGDR == 1) and 1 or 0;
    return isAir, isBomber, isGDR, isAirDefense, isGDRCounter;
end

function ThreatResponse.Collect(playerID)
    local turn = Game.GetCurrentGameTurn();
    if not IsMajorAI(playerID) then
        return {
            Turn = turn,
            Active = false,
            EnemyAir = 0,
            EnemyBombers = 0,
            EnemyGDR = 0,
            AirDefense = 0,
            GDRCounters = 0,
            AirRequired = 0,
            GDRRequired = 0,
            AirGap = false,
            GDRGap = false,
            RecentAir = false,
            RecentGDR = false,
            AirThreatAge = -1,
            GDRThreatAge = -1
        };
    end
    local cached = ThreatResponse.Cache[playerID];
    if cached ~= nil and cached.Turn == turn then
        return cached;
    end

    local player = Players[playerID];
    local snapshot = GetSnapshot(playerID);
    local enemyAir = 0;
    local enemyBombers = 0;
    local enemyGDR = 0;
    for _, opponentID in ipairs(snapshot.MajorOpponents or {}) do
        local opponent = Players[opponentID];
        if opponent ~= nil and PlayerManager.IsAlive(opponentID) then
            for _, unit in opponent:GetUnits():Members() do
                local unitInfo = GameInfo.Units[unit:GetType()];
                local air, bomber, gdr = ThreatResponse.GetUnitProfile(unitInfo);
                enemyAir = enemyAir + air;
                enemyBombers = enemyBombers + bomber;
                enemyGDR = enemyGDR + gdr;
            end
        end
    end

    local airDefense = 0;
    local gdrCounters = 0;
    for _, unit in player:GetUnits():Members() do
        local unitInfo = GameInfo.Units[unit:GetType()];
        local _, _, _, antiAir, gdrCounter =
            ThreatResponse.GetUnitProfile(unitInfo);
        airDefense = airDefense + antiAir;
        gdrCounters = gdrCounters + gdrCounter;
    end

    local rawLastAirTurn = player:GetProperty(
        ThreatResponse.LAST_AIR_TURN_PROPERTY
    );
    local rawLastGDRTurn = player:GetProperty(
        ThreatResponse.LAST_GDR_TURN_PROPERTY
    );
    local lastAirTurn = tonumber(rawLastAirTurn) or -100000;
    local lastGDRTurn = tonumber(rawLastGDRTurn) or -100000;
    local responseWindow = ScaleStandardTurns(GetNumberParameter(
        "ASAI_HIGH_TECH_THREAT_WINDOW_STANDARD",
        10
    ));
    local recentAir = turn - lastAirTurn <= responseWindow;
    local recentGDR = turn - lastGDRTurn <= responseWindow;
    local airRequired = enemyAir > 0 and math.max(1, math.ceil(
        enemyAir * GetNumberParameter(
            "ASAI_HIGH_TECH_AIR_COUNTER_RATIO_X100",
            75
        ) / 100
    )) or 0;
    local gdrRequired = enemyGDR > 0 and math.max(1, math.ceil(
        enemyGDR * GetNumberParameter(
            "ASAI_HIGH_TECH_GDR_COUNTER_RATIO_X100",
            50
        ) / 100
    )) or 0;
    local airGap = enemyAir > 0 and airDefense < airRequired;
    local gdrGap = enemyGDR > 0 and gdrCounters < gdrRequired;
    local result = {
        Turn = turn,
        Active = snapshot.MajorWars > 0
            and ((recentAir and airGap) or (recentGDR and gdrGap)),
        EnemyAir = enemyAir,
        EnemyBombers = enemyBombers,
        EnemyGDR = enemyGDR,
        AirDefense = airDefense,
        GDRCounters = gdrCounters,
        AirRequired = airRequired,
        GDRRequired = gdrRequired,
        AirGap = airGap,
        GDRGap = gdrGap,
        RecentAir = recentAir,
        RecentGDR = recentGDR,
        AirThreatAge = lastAirTurn > -100000
            and GetStandardEquivalentTurn(turn - lastAirTurn) or -1,
        GDRThreatAge = lastGDRTurn > -100000
            and GetStandardEquivalentTurn(turn - lastGDRTurn) or -1
    };
    ThreatResponse.Cache[playerID] = result;
    return result;
end

local function IsHighTechDefense(playerID, threshold)
    return ThreatResponse.Collect(playerID).Active;
end
function ASAI_IsHighTechDefense(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsHighTechDefense",
        IsHighTechDefense,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsHighTechDefense.Add(ASAI_IsHighTechDefense);

local function IsMilitaryReadiness(playerID, threshold)
    local state = GetRelativeState(playerID);
    return state.StrategicPlan == Strategic.DEFEND;
end
function ASAI_IsMilitaryReadiness(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsMilitaryReadiness",
        IsMilitaryReadiness,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsMilitaryReadiness.Add(ASAI_IsMilitaryReadiness);

local function IsMilitaryDominance(playerID, threshold)
    local state = GetRelativeState(playerID);
    return state.StrategicPlan == Strategic.PRESSURE;
end
function ASAI_IsMilitaryDominance(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsMilitaryDominance",
        IsMilitaryDominance,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsMilitaryDominance.Add(ASAI_IsMilitaryDominance);

local function GetMilitaryQueueTarget(snapshot, state)
    local warStopLoss = snapshot.ActiveMajorWars > 0
        and snapshot.Turn
            < (state.StrategicPlanCooldownUntil[Strategic.WAR] or -1);
    local targetPercent = snapshot.ActiveMajorWars > 0 and not warStopLoss
        and GetNumberParameter("ASAI_WAR_QUEUE_TARGET_X100", 45)
        or GetNumberParameter("ASAI_MILITARY_QUEUE_TARGET_X100", 25);
    return snapshot.Cities > 0
        and math.max(1, math.ceil(snapshot.Cities * targetPercent / 100))
        or 0;
end

local function GetMilitaryExecutionStatus(playerID)
    if not IsMajorAI(playerID) then
        return false, 0;
    end
    local state = GetRelativeState(playerID);
    local snapshot = GetSnapshot(playerID);
    local target = GetMilitaryQueueTarget(snapshot, state);
    local failedWarReview = state.StrategicPlan == Strategic.WAR
        and (state.StrategicPlanResult == RELATIVE_FOCUS_RESULT_EXECUTING
            or state.StrategicPlanResult == RELATIVE_FOCUS_RESULT_STALLED);
    if (state.StrategicPlan ~= Strategic.DEFEND and not failedWarReview)
        or target <= 0 then
        return false, target;
    end
    local economic = GetEconomicSnapshot(playerID);
    return economic.QueueOk == 1 and economic.Queue.Combat < target, target;
end

local function IsMilitaryExecutionRecovery(playerID, threshold)
    local active = GetMilitaryExecutionStatus(playerID);
    return active;
end
function ASAI_IsMilitaryExecutionRecovery(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsMilitaryExecutionRecovery",
        IsMilitaryExecutionRecovery,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsMilitaryExecutionRecovery.Add(ASAI_IsMilitaryExecutionRecovery);

local function IsScaleRecovery(playerID, threshold)
    local state = GetRelativeState(playerID);
    return state.StrategicPlan == Strategic.EXPAND
        and state.ScaleRecovery == 1;
end
function ASAI_IsScaleRecovery(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsScaleRecovery",
        IsScaleRecovery,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsScaleRecovery.Add(ASAI_IsScaleRecovery);

local function IsRelativeConsolidate(playerID, threshold)
    local state = GetRelativeState(playerID);
    return state.StrategicPlan == Strategic.DEVELOP
        and state.Band == RELATIVE_CONSOLIDATE;
end
function ASAI_IsRelativeConsolidate(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsRelativeConsolidate",
        IsRelativeConsolidate,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsRelativeConsolidate.Add(ASAI_IsRelativeConsolidate);

function Strategic.IsDevelopmentPlan(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    local startTurn = ScaleStandardTurns(
        GetNumberParameter("ASAI_RELATIVE_START_TURN_STANDARD", 35)
    );
    return Game.GetCurrentGameTurn() >= startTurn
        and GetRelativeState(playerID).StrategicPlan == Strategic.DEVELOP;
end
function ASAI_IsDevelopmentPlan(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsDevelopmentPlan",
        Strategic.IsDevelopmentPlan,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsDevelopmentPlan.Add(ASAI_IsDevelopmentPlan);

local function IsScienceRecovery(playerID, threshold)
    return GetRelativeState(playerID).Recovery.Science;
end
function ASAI_IsScienceRecovery(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsScienceRecovery",
        IsScienceRecovery,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsScienceRecovery.Add(ASAI_IsScienceRecovery);

local function IsCultureRecovery(playerID, threshold)
    return GetRelativeState(playerID).Recovery.Culture;
end
function ASAI_IsCultureRecovery(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsCultureRecovery",
        IsCultureRecovery,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsCultureRecovery.Add(ASAI_IsCultureRecovery);

local function IsEmpireRecovery(playerID, threshold)
    return GetRelativeState(playerID).Recovery.Empire;
end
function ASAI_IsEmpireRecovery(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsEmpireRecovery",
        IsEmpireRecovery,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsEmpireRecovery.Add(ASAI_IsEmpireRecovery);

local function IsFocusExecutionRecovery(playerID, focus)
    local state = GetRelativeState(playerID);
    return state.Focus == focus
        and state.StrategicSupport == focus
        and (state.FocusResult == RELATIVE_FOCUS_RESULT_STALLED
            or state.FocusResult == RELATIVE_FOCUS_RESULT_EXECUTING);
end

local function IsScienceExecutionRecovery(playerID, threshold)
    return IsFocusExecutionRecovery(playerID, RELATIVE_FOCUS_SCIENCE);
end
function ASAI_IsScienceExecutionRecovery(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsScienceExecutionRecovery",
        IsScienceExecutionRecovery,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsScienceExecutionRecovery.Add(ASAI_IsScienceExecutionRecovery);

function ScienceExecution.IsMoon(playerID, threshold)
    local state = ScienceExecution.Collect(playerID);
    return state.Active and state.Stage == ScienceExecution.SATELLITE;
end
function ASAI_IsScienceMoonExecution(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsScienceMoonExecution",
        ScienceExecution.IsMoon,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsScienceMoonExecution.Add(ASAI_IsScienceMoonExecution);

function ScienceExecution.IsMars(playerID, threshold)
    local state = ScienceExecution.Collect(playerID);
    return state.Active and state.Stage == ScienceExecution.MOON;
end
function ASAI_IsScienceMarsExecution(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsScienceMarsExecution",
        ScienceExecution.IsMars,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsScienceMarsExecution.Add(ASAI_IsScienceMarsExecution);

function ScienceExecution.IsExoplanet(playerID, threshold)
    local state = ScienceExecution.Collect(playerID);
    return state.Active and state.Stage == ScienceExecution.MARS;
end
function ASAI_IsScienceExoplanetExecution(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsScienceExoplanetExecution",
        ScienceExecution.IsExoplanet,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsScienceExoplanetExecution.Add(ASAI_IsScienceExoplanetExecution);

function ScienceExecution.IsLaser(playerID, threshold)
    local state = ScienceExecution.Collect(playerID);
    return state.Active and state.Stage == ScienceExecution.EXOPLANET;
end
function ASAI_IsScienceLaserExecution(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsScienceLaserExecution",
        ScienceExecution.IsLaser,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsScienceLaserExecution.Add(ASAI_IsScienceLaserExecution);

function ScienceExecution.IsSpaceportScale(playerID, threshold)
    local state = ScienceExecution.Collect(playerID);
    return state.Active
        and state.Spaceports + state.SpaceportsInFlight < state.SpaceportTarget;
end
function ASAI_IsScienceSpaceportScale(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsScienceSpaceportScale",
        ScienceExecution.IsSpaceportScale,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsScienceSpaceportScale.Add(ASAI_IsScienceSpaceportScale);

local function IsCultureExecutionRecovery(playerID, threshold)
    return IsFocusExecutionRecovery(playerID, RELATIVE_FOCUS_CULTURE);
end
function ASAI_IsCultureExecutionRecovery(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsCultureExecutionRecovery",
        IsCultureExecutionRecovery,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsCultureExecutionRecovery.Add(ASAI_IsCultureExecutionRecovery);

local function IsEmpireExecutionRecovery(playerID, threshold)
    return IsFocusExecutionRecovery(playerID, RELATIVE_FOCUS_EMPIRE);
end
function ASAI_IsEmpireExecutionRecovery(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsEmpireExecutionRecovery",
        IsEmpireExecutionRecovery,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsEmpireExecutionRecovery.Add(ASAI_IsEmpireExecutionRecovery);

local function IsExpansionRecovery(playerID, threshold)
    local state = GetRelativeState(playerID);
    if state.ExpansionPlanAllowed ~= 1 then
        return false;
    end
    if state.StrategicPlan ~= Strategic.EXPAND then
        return false;
    end
    if state.ScaleRecovery == 1 and state.ScaleExpansionAllowed ~= 1 then
        return false;
    end
    if not state.Recovery.Empire and state.ScaleExpansionAllowed ~= 1 then
        return false;
    end
    local snapshot = GetSnapshot(playerID);
    if snapshot.Cities <= 0 or snapshot.ActiveMajorWars > 0 then
        return false;
    end
    local maximumInFlight = GetMaximumSettlersInFlight(
        snapshot,
        state.ScaleExpansionAllowed == 1
    );
    return snapshot.Settlers + snapshot.InFlightSettlers < maximumInFlight;
end
function ASAI_IsExpansionRecovery(playerID, threshold)
    return RunStrategyCondition(
        "ASAI_IsExpansionRecovery",
        IsExpansionRecovery,
        playerID,
        threshold
    );
end
GameEvents.ASAI_IsExpansionRecovery.Add(ASAI_IsExpansionRecovery);

local function IsCombatUnitNear(player, x, y, maximumDistance)
    for _, unit in player:GetUnits():Members() do
        local unitInfo = GameInfo.Units[unit:GetType()];
        if unitInfo ~= nil then
            local combat = math.max(
                tonumber(unitInfo.Combat) or 0,
                tonumber(unitInfo.RangedCombat) or 0,
                tonumber(unitInfo.Bombard) or 0,
                tonumber(unitInfo.AntiAirCombat) or 0
            );
            if combat > 0
                and Map.GetPlotDistance(x, y, unit:GetX(), unit:GetY())
                    <= maximumDistance then
                return true;
            end
        end
    end
    for _, city in player:GetCities():Members() do
        if Map.GetPlotDistance(x, y, city:GetX(), city:GetY()) <= maximumDistance then
            return true;
        end
    end
    return false;
end

function ThreatResponse.MarkNearbyThreat(playerID, opponent, x, y)
    if not IsMajorAI(playerID) or opponent == nil then
        return;
    end
    local maximumDistance = math.max(
        1,
        GetNumberParameter("ASAI_HIGH_TECH_THREAT_DISTANCE", 10)
    );
    local airThreat = false;
    local gdrThreat = false;
    for _, unit in opponent:GetUnits():Members() do
        local unitInfo = GameInfo.Units[unit:GetType()];
        local air, _, gdr = ThreatResponse.GetUnitProfile(unitInfo);
        if (air == 1 or gdr == 1)
            and Map.GetPlotDistance(x, y, unit:GetX(), unit:GetY())
                <= maximumDistance then
            airThreat = airThreat or air == 1;
            gdrThreat = gdrThreat or gdr == 1;
            if airThreat and gdrThreat then
                break;
            end
        end
    end
    if not airThreat and not gdrThreat then
        return;
    end
    local player = Players[playerID];
    local turn = Game.GetCurrentGameTurn();
    if airThreat then
        player:SetProperty(ThreatResponse.LAST_AIR_TURN_PROPERTY, turn);
    end
    if gdrThreat then
        player:SetProperty(ThreatResponse.LAST_GDR_TURN_PROPERTY, turn);
    end
    ThreatResponse.Cache[playerID] = nil;
end

local function MarkRecentMajorCombat(playerID)
    if not IsMajorAI(playerID) then
        return;
    end
    local player = Players[playerID];
    player:SetProperty(
        LAST_MAJOR_COMBAT_TURN_PROPERTY,
        Game.GetCurrentGameTurn()
    );
    Strategic.IncrementRuntimeCounter(
        player,
        Strategic.MAJOR_COMBAT_EVENTS_PROPERTY
    );
    m_Snapshots[playerID] = nil;
end

local function RecordUnitDamage(playerID, unitID, newDamage, oldDamage)
    if oldDamage ~= nil and newDamage <= oldDamage then
        return;
    end
    local targetPlayer = Players[playerID];
    local targetUnit = UnitManager.GetUnit(playerID, unitID);
    if targetPlayer == nil or targetUnit == nil or not targetPlayer:IsMajor() then
        return;
    end

    local diplomacy = targetPlayer:GetDiplomacy();
    local attributionDistance = math.max(
        1,
        GetNumberParameter("ASAI_WAR_COMBAT_ATTRIBUTION_DISTANCE", 4)
    );
    for _, opponentID in ipairs(PlayerManager.GetAliveMajorIDs()) do
        if opponentID ~= playerID and diplomacy:IsAtWarWith(opponentID) then
            local opponent = Players[opponentID];
            if opponent ~= nil then
                ThreatResponse.MarkNearbyThreat(
                    playerID,
                    opponent,
                    targetUnit:GetX(),
                    targetUnit:GetY()
                );
                if IsCombatUnitNear(
                    opponent,
                    targetUnit:GetX(),
                    targetUnit:GetY(),
                    attributionDistance
                ) then
                    MarkRecentMajorCombat(playerID);
                    MarkRecentMajorCombat(opponentID);
                end
            end
        end
    end
end

local function OnUnitDamageChanged(playerID, unitID, newDamage, oldDamage)
    local success, combatError = pcall(
        RecordUnitDamage,
        playerID,
        unitID,
        newDamage,
        oldDamage
    );
    if not success and m_ConditionErrors.ASAI_RecordUnitDamage == nil then
        print(string.format(
            "ASAI_ERROR condition=ASAI_RecordUnitDamage player=%s fallback=skip error=%s",
            tostring(playerID),
            tostring(combatError)
        ));
        m_ConditionErrors.ASAI_RecordUnitDamage = true;
    end
end

function ThreatResponse.RecordDistrictDamage(
    playerID,
    districtID,
    damageType,
    newDamage,
    oldDamage
)
    if not IsMajorAI(playerID) or newDamage <= oldDamage then
        return;
    end
    local player = Players[playerID];
    local districts = player:GetDistricts();
    local district = districts ~= nil and districts:FindID(districtID) or nil;
    if district == nil then
        return;
    end
    local diplomacy = player:GetDiplomacy();
    local attributionDistance = math.max(
        1,
        GetNumberParameter("ASAI_HIGH_TECH_THREAT_DISTANCE", 10)
    );
    for _, opponentID in ipairs(PlayerManager.GetAliveMajorIDs()) do
        if opponentID ~= playerID and diplomacy:IsAtWarWith(opponentID) then
            local opponent = Players[opponentID];
            if opponent ~= nil and IsCombatUnitNear(
                opponent,
                district:GetX(),
                district:GetY(),
                attributionDistance
            ) then
                MarkRecentMajorCombat(playerID);
                MarkRecentMajorCombat(opponentID);
                ThreatResponse.MarkNearbyThreat(
                    playerID,
                    opponent,
                    district:GetX(),
                    district:GetY()
                );
            end
        end
    end
end

function ThreatResponse.OnDistrictDamageChanged(
    playerID,
    districtID,
    damageType,
    newDamage,
    oldDamage
)
    local success, threatError = pcall(
        ThreatResponse.RecordDistrictDamage,
        playerID,
        districtID,
        damageType,
        newDamage,
        oldDamage
    );
    if not success and m_ConditionErrors.ASAI_RecordDistrictThreat == nil then
        print(string.format(
            "ASAI_ERROR condition=ASAI_RecordDistrictThreat player=%s fallback=skip error=%s",
            tostring(playerID),
            tostring(threatError)
        ));
        m_ConditionErrors.ASAI_RecordDistrictThreat = true;
    end
end

local function WriteMetrics(playerID, firstTimeThisTurn)
    if not firstTimeThisTurn or not IsMajorAI(playerID) then
        return;
    end
    if GetNumberParameter("ASAI_ENABLE_METRICS", 0) ~= 1 then
        return;
    end

    local relativeState = GetRelativeState(playerID);
    if not relativeState.EvaluatedThisTurn then
        return;
    end

    local snapshot = GetSnapshot(playerID);
    local strength = GetStrengthSnapshot(playerID);
    local infrastructureTarget = GetInfrastructureTarget(snapshot);
    local builderBudget = IsBuilderBudgetReachedSnapshot(snapshot) and 1 or 0;
    local traderBudget = IsTraderBudgetReachedSnapshot(snapshot) and 1 or 0;
    local scaleExpansion = relativeState.ScaleExpansionAllowed == 1;
    local settlerMaximum = GetMaximumSettlersInFlight(snapshot, scaleExpansion);
    local settlerBudget = IsSettlerBudgetReachedSnapshot(
        snapshot,
        scaleExpansion
    ) and 1 or 0;
    local secondCore = GetSecondWeakestCorePillarScore(relativeState);
    local weakestCore = GetWeakestCorePillarScore(relativeState);
    local handoffReady = relativeState.FocusHandoffReady and 1 or 0;
    local focusAge = relativeState.FocusStartedTurn >= 0
        and GetStandardEquivalentTurn(snapshot.Turn - relativeState.FocusStartedTurn)
        or 0;
    local strategicPlanAge = relativeState.StrategicPlanStartedTurn >= 0
        and GetStandardEquivalentTurn(
            snapshot.Turn - relativeState.StrategicPlanStartedTurn
        ) or 0;
    local combatAge = snapshot.LastMajorCombatTurn > -100000
        and GetStandardEquivalentTurn(snapshot.Turn - snapshot.LastMajorCombatTurn)
        or -1;
    local warCooldownUntil = relativeState.StrategicPlanCooldownUntil[
        Strategic.WAR
    ] or -1;
    local warStopLoss = snapshot.ActiveMajorWars > 0
        and snapshot.Turn < warCooldownUntil;
    local warStopLossRemaining = warStopLoss
        and GetStandardEquivalentTurn(warCooldownUntil - snapshot.Turn)
        or 0;
    local expansionBlocked = snapshot.Turn
        < relativeState.ExpansionBlockedUntil;
    local expansionCooldownRemaining = expansionBlocked
        and GetStandardEquivalentTurn(
            relativeState.ExpansionBlockedUntil - snapshot.Turn
        ) or 0;
    local expansionLastSuccessAge = relativeState.ExpansionLastSuccessTurn >= 0
        and GetStandardEquivalentTurn(
            snapshot.Turn - relativeState.ExpansionLastSuccessTurn
        ) or -1;
    local resultYieldsActive = (relativeState.MildResultYieldsActive == 1
        or relativeState.SevereResultYieldsActive == 1) and 1 or 0;
    print(string.format(
        "ASAI_METRIC turn=%d evaluated_turn=%d standard_turn=%.1f player=%d stage=%s cities=%d captured=%d pop=%d owned=%d improved=%d infratarget=%d builder_budget=%d trader_budget=%d settler_budget=%d settler_cap=%d builders=%d builders_inflight=%d traders=%d traders_inflight=%d settlers=%d settlers_inflight=%d capacity=%d capacity_target=%d gold=%.1f netgold=%.1f science=%.1f culture=%.1f techs=%d civics=%d military=%d wars=%d major_wars=%d active_major_wars=%d combat_age=%.1f combat_events=%d capture_events=%d pillage_events=%d war_stop_loss=%d war_stop_loss_remaining=%.1f minor_wars=%d era=%d relative_raw=%.3f relative=%.3f second_core=%.3f weakest_core=%.3f science_raw=%.3f science_ratio=%.3f culture_raw=%.3f culture_ratio=%.3f empire_raw=%.3f empire_ratio=%.3f military_raw=%.3f military_ratio=%.3f military_readiness=%d military_dominance=%d scale_recovery=%d scale_expansion=%d expansion_phase=%s expansion_allowed=%d expansion_blocked=%d expansion_cooldown_remaining=%.1f expansion_last_success_age=%.1f expansion_settler_stalls=%d result_yields=%d mild_result_yields=%d severe_result_yields=%d result_tier=%s pacing=%s support=%s focus=%s focus_result=%s handoff_ready=%d focus_gain=%.3f focus_raw_gain=%.3f focus_own_yield_gain=%.3f focus_own_progress_gain=%d focus_age=%.1f focus_execution=%d focus_stalls=%d plan=%s plan_support=%s plan_result=%s plan_score=%.1f plan_gain=%.3f plan_execution=%d plan_stalls=%d",
        snapshot.Turn,
        relativeState.LastEvaluationTurn,
        GetStandardEquivalentTurn(snapshot.Turn),
        playerID,
        relativeState.Stage,
        snapshot.Cities,
        snapshot.CapturedCities,
        snapshot.Population,
        snapshot.OwnedPlots,
        snapshot.Improvements,
        infrastructureTarget,
        builderBudget,
        traderBudget,
        settlerBudget,
        settlerMaximum,
        snapshot.Builders,
        snapshot.InFlightBuilders,
        snapshot.Traders,
        snapshot.InFlightTraders,
        snapshot.Settlers,
        snapshot.InFlightSettlers,
        snapshot.RouteCapacity,
        GetTradeCapacityTarget(snapshot),
        snapshot.GoldBalance,
        snapshot.NetGold,
        strength.Science,
        strength.Culture,
        strength.Techs,
        strength.Civics,
        strength.Military,
        snapshot.Wars,
        snapshot.MajorWars,
        snapshot.ActiveMajorWars,
        combatAge,
        snapshot.MajorCombatEvents,
        snapshot.MajorCaptureEvents,
        snapshot.MajorPillageEvents,
        warStopLoss and 1 or 0,
        warStopLossRemaining,
        snapshot.MinorWars,
        snapshot.Era,
        relativeState.RawScores.Overall,
        relativeState.Scores.Overall,
        secondCore,
        weakestCore,
        relativeState.RawScores.Science,
        relativeState.Scores.Science,
        relativeState.RawScores.Culture,
        relativeState.Scores.Culture,
        relativeState.RawScores.Empire,
        relativeState.Scores.Empire,
        relativeState.RawScores.Military,
        relativeState.Scores.Military,
        relativeState.MilitaryReadiness,
        relativeState.MilitaryDominance,
        relativeState.ScaleRecovery,
        relativeState.ScaleExpansionAllowed,
        Strategic.GetExpansionPhaseName(relativeState.ExpansionPhase),
        relativeState.ExpansionPlanAllowed,
        expansionBlocked and 1 or 0,
        expansionCooldownRemaining,
        expansionLastSuccessAge,
        relativeState.ExpansionSettlerStallCount,
        resultYieldsActive,
        relativeState.MildResultYieldsActive,
        relativeState.SevereResultYieldsActive,
        GetResultTierName(relativeState),
        GetBandName(relativeState.Band),
        GetSupportName(relativeState),
        GetFocusName(relativeState.Focus),
        GetFocusResultName(relativeState.FocusResult),
        handoffReady,
        relativeState.FocusGain,
        relativeState.FocusRawGain,
        relativeState.FocusOwnYieldGain,
        relativeState.FocusOwnProgressGain,
        focusAge,
        relativeState.FocusExecution,
        relativeState.FocusStallCount,
        Strategic.GetPlanName(relativeState.StrategicPlan),
        Strategic.GetSupportName(relativeState.StrategicSupport),
        GetFocusResultName(relativeState.StrategicPlanResult),
        relativeState.StrategicPlanScore,
        relativeState.StrategicPlanGain,
        relativeState.StrategicPlanExecution,
        relativeState.StrategicPlanStallCount
    ));
    print(string.format(
        "ASAI_COMPONENTS turn=%d player=%d tech_raw=%.3f tech_controlled=%.3f civics_raw=%.3f civics_controlled=%.3f science_raw=%.3f science_controlled=%.3f culture_raw=%.3f culture_controlled=%.3f cities_raw=%.3f cities_controlled=%.3f pop_raw=%.3f pop_controlled=%.3f military_raw=%.3f military_controlled=%.3f",
        snapshot.Turn,
        playerID,
        relativeState.RawRatios.Techs,
        relativeState.ControlledRatios.Techs,
        relativeState.RawRatios.Civics,
        relativeState.ControlledRatios.Civics,
        relativeState.RawRatios.Science,
        relativeState.ControlledRatios.Science,
        relativeState.RawRatios.Culture,
        relativeState.ControlledRatios.Culture,
        relativeState.RawRatios.Cities,
        relativeState.ControlledRatios.Cities,
        relativeState.RawRatios.Population,
        relativeState.ControlledRatios.Population,
        relativeState.RawRatios.Military,
        relativeState.ControlledRatios.Military
    ));
    print(string.format(
        "ASAI_STRATEGY_INPUT turn=%d player=%d plan=%s plan_candidate=%s plan_candidate_streak=%d plan_support=%s plan_age=%.1f competitive=%.3f competitive_science=%.3f competitive_culture=%.3f competitive_empire=%.3f competitive_military=%.3f upper=%.3f upper_science=%.3f upper_culture=%.3f upper_empire=%.3f upper_military=%.3f trend=%.4f trend_science=%.4f trend_culture=%.4f trend_empire=%.4f trend_military=%.4f score_develop=%.1f score_recover=%.1f score_expand=%.1f score_defend=%.1f score_pressure=%.1f score_war=%.1f",
        snapshot.Turn,
        playerID,
        Strategic.GetPlanName(relativeState.StrategicPlan),
        Strategic.GetPlanName(relativeState.StrategicPlanCandidate),
        relativeState.StrategicPlanStreak,
        Strategic.GetSupportName(relativeState.StrategicSupport),
        strategicPlanAge,
        relativeState.CompetitiveScores.Overall,
        relativeState.CompetitiveScores.Science,
        relativeState.CompetitiveScores.Culture,
        relativeState.CompetitiveScores.Empire,
        relativeState.CompetitiveScores.Military,
        relativeState.WorldUpperScores.Overall,
        relativeState.WorldUpperScores.Science,
        relativeState.WorldUpperScores.Culture,
        relativeState.WorldUpperScores.Empire,
        relativeState.WorldUpperScores.Military,
        relativeState.Trends.Overall,
        relativeState.Trends.Science,
        relativeState.Trends.Culture,
        relativeState.Trends.Empire,
        relativeState.Trends.Military,
        relativeState.StrategicPlanScores[Strategic.DEVELOP] or 0,
        relativeState.StrategicPlanScores[Strategic.RECOVER] or 0,
        relativeState.StrategicPlanScores[Strategic.EXPAND] or 0,
        relativeState.StrategicPlanScores[Strategic.DEFEND] or 0,
        relativeState.StrategicPlanScores[Strategic.PRESSURE] or 0,
        relativeState.StrategicPlanScores[Strategic.WAR] or 0
    ));
end

local function WriteEconomicDiagnostics(playerID, firstTimeThisTurn)
    if not firstTimeThisTurn or not IsMajorAI(playerID) then
        return;
    end
    if GetNumberParameter("ASAI_ENABLE_METRICS", 0) ~= 1 then
        return;
    end

    local relativeState = GetRelativeState(playerID);
    if not relativeState.EvaluatedThisTurn then
        return;
    end

    local snapshot = GetSnapshot(playerID);
    local economic = GetEconomicSnapshot(playerID);
    local player = Players[playerID];
    local queueHistory, queueHistoryOk = TryDiagnosticSensor(
        "queue_history",
        function()
            return Diagnostics.UpdateQueueIdleHistory(
                player,
                snapshot.Turn,
                economic.Queue,
                economic.QueueOk
            );
        end
    );
    queueHistory = queueHistory or {
        PreviousSampleTurn = -1,
        PersistentIdle = -1,
        MaximumIdleStreak = -1
    };
    local tradeRoutes, tradeRoutesOk = TryDiagnosticSensor(
        "trade_routes",
        function() return Diagnostics.CollectTradeRoutes(player); end,
        true
    );
    tradeRoutes = tradeRoutes or {
        Active = -1,
        Domestic = -1,
        International = -1,
        UnknownDestination = -1,
        IdleTraders = -1,
        TraderLinksOk = 0
    };
    local actualRouteCoverage = tradeRoutesOk == 1
        and snapshot.RouteCapacity > 0
        and tradeRoutes.Active / snapshot.RouteCapacity or -1;
    local routeGap = tradeRoutesOk == 1
        and math.max(0, snapshot.RouteCapacity - tradeRoutes.Active) or -1;
    local traderPipelineGap = math.max(
        0,
        snapshot.RouteCapacity
            - snapshot.Traders
            - snapshot.InFlightTraders
    );
    local capacityTarget = GetTradeCapacityTarget(snapshot);
    local capacityGap = math.max(0, capacityTarget - snapshot.RouteCapacity);
    local human = GetHumanEconomicReference();
    local productionRatio = human ~= nil
        and GetDiagnosticRatio(economic.Production, human.Production) or -1;
    local productionPerCityRatio = human ~= nil
        and GetDiagnosticRatio(
            economic.ProductionPerCity,
            human.ProductionPerCity
        ) or -1;
    print(string.format(
        "ASAI_ECONOMY turn=%d evaluated_turn=%d standard_turn=%.1f player=%d production=%.1f production_per_city=%.2f production_per_pop=%.2f production_ratio=%.3f production_per_city_ratio=%.3f district_used=%d district_completed=%d district_estimated_slots=%d district_util=%.3f district_slot_mode=population_formula route_capacity=%d route_coverage=%.3f route_pipeline=%.3f route_coverage_mode=trader_unit_proxy active_routes=%d actual_route_coverage=%.3f idle_traders=%d trader_links_ok=%d domestic_routes=%d international_routes=%d unknown_routes=%d route_gap=%d route_sensor_ok=%d improvement_coverage=%.3f improvement_pipeline=%.3f improved_land=%.3f production_ok=%d district_ok=%d",
        snapshot.Turn,
        relativeState.LastEvaluationTurn,
        GetStandardEquivalentTurn(snapshot.Turn),
        playerID,
        economic.Production,
        economic.ProductionPerCity,
        economic.ProductionPerPopulation,
        productionRatio,
        productionPerCityRatio,
        economic.Districts.Used,
        economic.Districts.Completed,
        economic.Districts.Slots,
        economic.DistrictUtilization,
        snapshot.RouteCapacity,
        economic.RouteCoverage,
        economic.RoutePipelineCoverage,
        tradeRoutes.Active,
        actualRouteCoverage,
        tradeRoutes.IdleTraders,
        tradeRoutes.TraderLinksOk,
        tradeRoutes.Domestic,
        tradeRoutes.International,
        tradeRoutes.UnknownDestination,
        routeGap,
        tradeRoutesOk,
        economic.ImprovementCoverage,
        economic.ImprovementPipelineCoverage,
        economic.ImprovedLand,
        economic.ProductionOk,
        economic.DistrictOk
    ));
    print(string.format(
        "ASAI_CONVERSION turn=%d evaluated_turn=%d standard_turn=%.1f player=%d cities=%d queue_units=%d queue_districts=%d queue_buildings=%d queue_projects=%d queue_wonders=%d queue_idle=%d queue_idle_at_evaluation=%d queue_idle_persistent=%d queue_idle_max_streak=%d queue_previous_sample_turn=%d queue_sample_phase=player_turn_activated queue_history_ok=%d queue_unknown=%d queue_science=%d queue_culture=%d queue_empire=%d gold=%.1f gold_reserve=%.1f gold_surplus=%.1f gold_per_city=%.1f queue_ok=%d resource_supported=%d upgrade_supported=%d",
        snapshot.Turn,
        relativeState.LastEvaluationTurn,
        GetStandardEquivalentTurn(snapshot.Turn),
        playerID,
        snapshot.Cities,
        economic.Queue.Units,
        economic.Queue.Districts,
        economic.Queue.Buildings,
        economic.Queue.Projects,
        economic.Queue.Wonders,
        economic.Queue.Idle,
        economic.Queue.Idle,
        queueHistory.PersistentIdle,
        queueHistory.MaximumIdleStreak,
        queueHistory.PreviousSampleTurn,
        queueHistoryOk,
        economic.Queue.Unknown,
        economic.Queue.Science,
        economic.Queue.Culture,
        economic.Queue.Empire,
        snapshot.GoldBalance,
        economic.GoldReserve,
        economic.GoldSurplus,
        economic.GoldPerCity,
        economic.QueueOk,
        economic.ResourceSupported,
        economic.UpgradeSupported
    ));
    print(string.format(
        "ASAI_TRADE turn=%d evaluated_turn=%d standard_turn=%.1f player=%d capacity=%d capacity_target=%d capacity_gap=%d traders=%d traders_inflight=%d trader_pipeline_gap=%d active_routes=%d route_gap=%d idle_traders=%d trader_links_ok=%d domestic_routes=%d international_routes=%d unknown_routes=%d trader_recovery=%d capacity_recovery=%d route_sensor_ok=%d",
        snapshot.Turn,
        relativeState.LastEvaluationTurn,
        GetStandardEquivalentTurn(snapshot.Turn),
        playerID,
        snapshot.RouteCapacity,
        capacityTarget,
        capacityGap,
        snapshot.Traders,
        snapshot.InFlightTraders,
        traderPipelineGap,
        tradeRoutes.Active,
        routeGap,
        tradeRoutes.IdleTraders,
        tradeRoutes.TraderLinksOk,
        tradeRoutes.Domestic,
        tradeRoutes.International,
        tradeRoutes.UnknownDestination,
        IsTradeRecovery(playerID) and 1 or 0,
        IsTradeCapacityRecovery(playerID) and 1 or 0,
        tradeRoutesOk
    ));
end

function Diagnostics.WriteCultureDiagnostics(playerID, firstTimeThisTurn)
    if not firstTimeThisTurn or not IsMajorAI(playerID) then
        return;
    end
    if GetNumberParameter("ASAI_ENABLE_METRICS", 0) ~= 1 then
        return;
    end

    local relativeState = GetRelativeState(playerID);
    if not relativeState.EvaluatedThisTurn then
        return;
    end
    local player = Players[playerID];
    local snapshot = GetSnapshot(playerID);
    local strength = GetStrengthSnapshot(playerID);
    local infrastructure, infrastructureOk = TryDiagnosticSensor(
        "culture_infrastructure",
        function()
            return Diagnostics.CollectCultureInfrastructure(player);
        end
    );
    infrastructure = infrastructure or {
        Theaters = -1,
        Monuments = -1,
        TheaterBuildings = -1
    };
    local cultureQueue, cultureQueueOk = TryDiagnosticSensor(
        "culture_queue",
        function() return Diagnostics.CollectCultureQueue(player); end
    );
    cultureQueue = cultureQueue or {
        Districts = -1,
        Monuments = -1,
        Buildings = -1,
        Projects = -1,
        Total = -1
    };
    local greatPeople, greatPeopleOk = TryDiagnosticSensor(
        "culture_great_people",
        function() return Diagnostics.CollectCulturalGreatPeople(player); end,
        true
    );
    greatPeople = greatPeople or { PerTurn = -1, Balance = -1 };
    print(string.format(
        "ASAI_CULTURE turn=%d evaluated_turn=%d standard_turn=%.1f player=%d culture=%.1f civics=%d theaters=%d theaters_inflight=%d monuments=%d monuments_inflight=%d theater_buildings=%d theater_buildings_inflight=%d theater_projects_inflight=%d culture_queue_total=%d cultural_gpp_per_turn=%.1f cultural_gpp_balance=%.1f recovery_active=%d focus_active=%d support_active=%d focus_result=%s focus_execution=%d infrastructure_sensor_ok=%d queue_sensor_ok=%d gpp_sensor_ok=%d",
        snapshot.Turn,
        relativeState.LastEvaluationTurn,
        GetStandardEquivalentTurn(snapshot.Turn),
        playerID,
        strength.Culture,
        strength.Civics,
        infrastructure.Theaters,
        cultureQueue.Districts,
        infrastructure.Monuments,
        cultureQueue.Monuments,
        infrastructure.TheaterBuildings,
        cultureQueue.Buildings,
        cultureQueue.Projects,
        cultureQueue.Total,
        greatPeople.PerTurn,
        greatPeople.Balance,
        relativeState.Recovery.Culture and 1 or 0,
        relativeState.Focus == RELATIVE_FOCUS_CULTURE and 1 or 0,
        relativeState.StrategicSupport == RELATIVE_FOCUS_CULTURE and 1 or 0,
        GetFocusResultName(relativeState.FocusResult),
        relativeState.FocusExecution,
        infrastructureOk,
        cultureQueueOk,
        greatPeopleOk
    ));
end

local function WriteMilitaryDiagnostics(playerID, firstTimeThisTurn)
    if not firstTimeThisTurn or not IsMajorAI(playerID) then
        return;
    end
    if GetNumberParameter("ASAI_ENABLE_METRICS", 0) ~= 1 then
        return;
    end

    local relativeState = GetRelativeState(playerID);
    if not relativeState.EvaluatedThisTurn then
        return;
    end

    local snapshot = GetSnapshot(playerID);
    local strength = GetStrengthSnapshot(playerID);
    local economic = GetEconomicSnapshot(playerID);
    local defenses, defenseSupported = TryDiagnosticSensor(
        "city_defenses",
        function() return CollectDefenseDiagnostics(Players[playerID]); end
    );
    defenses = defenses or { Cities = snapshot.Cities, DefendedCities = -1 };
    local assaultRoles, assaultRolesOk = TryDiagnosticSensor(
        "assault_roles",
        function() return Diagnostics.CollectAssaultRoles(Players[playerID]); end
    );
    assaultRoles = assaultRoles or {
        FieldedRanged = -1,
        FieldedWallBreakers = -1,
        FieldedAirSiege = -1,
        QueuedRanged = -1,
        QueuedWallBreakers = -1,
        QueuedAirSiege = -1
    };
    local unitsPerCity = snapshot.Cities > 0
        and strength.CombatUnits / snapshot.Cities or 0;
    local defenseCoverage = defenseSupported == 1 and defenses.Cities > 0
        and defenses.DefendedCities / defenses.Cities or -1;
    local militaryExecution, militaryQueueTarget = GetMilitaryExecutionStatus(playerID);
    local militaryQueueGap = economic.QueueOk == 1 and math.max(
        0,
        militaryQueueTarget - economic.Queue.Combat
    ) or -1;
    local forceDensityTarget = GetNumberParameter(
        "ASAI_MILITARY_UNITS_PER_PLANNED_CITY_EXIT_X100",
        225
    ) / 100;
    local combatForceTarget = math.ceil(
        relativeState.MilitaryPlannedCities * forceDensityTarget
    );
    local combatForceGap = math.max(
        0,
        combatForceTarget - strength.CombatUnits
    );
    local assaultRoleTarget = snapshot.ActiveMajorWars > 0 and 1 or 0;
    local operationRangedGap = assaultRolesOk == 1 and math.max(
        0,
        assaultRoleTarget
            - assaultRoles.FieldedRanged
            - assaultRoles.QueuedRanged
    ) or -1;
    local wallBreakerGap = assaultRolesOk == 1 and math.max(
        0,
        assaultRoleTarget
            - assaultRoles.FieldedWallBreakers
            - assaultRoles.QueuedWallBreakers
    ) or -1;
    local warStopLoss = snapshot.ActiveMajorWars > 0
        and snapshot.Turn < (
            relativeState.StrategicPlanCooldownUntil[Strategic.WAR] or -1
        );
    print(string.format(
        "ASAI_MILITARY turn=%d evaluated_turn=%d standard_turn=%.1f player=%d strength=%d combat_units=%d land_units=%d ranged_units=%d siege_units=%d mobile_units=%d naval_units=%d air_units=%d units_per_city=%.2f planned_cities=%d units_per_planned_city=%.2f combat_force_target=%d combat_force_gap=%d queue_combat=%d queue_target=%d queue_gap=%d military_execution=%d queue_land=%d queue_ranged=%d queue_siege=%d queue_mobile=%d queue_naval=%d queue_air=%d operation_ranged=%d operation_ranged_inflight=%d operation_ranged_gap=%d wall_breakers=%d wall_breakers_inflight=%d wall_breaker_gap=%d air_siege=%d air_siege_inflight=%d assault_role_target=%d assault_roles_ok=%d defended_cities=%d defense_coverage=%.3f defense_supported=%d military_raw=%.3f military_ratio=%.3f military_readiness=%d military_dominance=%d active_major_wars=%d war_stop_loss=%d combat_events=%d capture_events=%d pillage_events=%d",
        snapshot.Turn,
        relativeState.LastEvaluationTurn,
        GetStandardEquivalentTurn(snapshot.Turn),
        playerID,
        strength.Military,
        strength.CombatUnits,
        strength.LandCombatUnits,
        strength.RangedUnits,
        strength.SiegeUnits,
        strength.MobileUnits,
        strength.NavalUnits,
        strength.AirUnits,
        unitsPerCity,
        relativeState.MilitaryPlannedCities,
        relativeState.MilitaryUnitsPerPlannedCity,
        combatForceTarget,
        combatForceGap,
        economic.Queue.Combat,
        militaryQueueTarget,
        militaryQueueGap,
        militaryExecution and 1 or 0,
        economic.Queue.Land,
        economic.Queue.Ranged,
        economic.Queue.Siege,
        economic.Queue.Mobile,
        economic.Queue.Naval,
        economic.Queue.Air,
        assaultRoles.FieldedRanged,
        assaultRoles.QueuedRanged,
        operationRangedGap,
        assaultRoles.FieldedWallBreakers,
        assaultRoles.QueuedWallBreakers,
        wallBreakerGap,
        assaultRoles.FieldedAirSiege,
        assaultRoles.QueuedAirSiege,
        assaultRoleTarget,
        assaultRolesOk,
        defenses.DefendedCities,
        defenseCoverage,
        defenseSupported,
        relativeState.RawScores.Military,
        relativeState.Scores.Military,
        relativeState.MilitaryReadiness,
        relativeState.MilitaryDominance,
        snapshot.ActiveMajorWars,
        warStopLoss and 1 or 0,
        snapshot.MajorCombatEvents,
        snapshot.MajorCaptureEvents,
        snapshot.MajorPillageEvents
    ));
end

function ScienceExecution.WriteDiagnostics(playerID, firstTimeThisTurn)
    if not firstTimeThisTurn or not IsMajorAI(playerID) then
        return;
    end
    if GetNumberParameter("ASAI_ENABLE_METRICS", 0) ~= 1 then
        return;
    end
    local relativeState = GetRelativeState(playerID);
    if not relativeState.EvaluatedThisTurn then
        return;
    end
    local state = ScienceExecution.Collect(playerID);
    print(string.format(
        "ASAI_SCIENCE_EXECUTION turn=%d evaluated_turn=%d standard_turn=%.1f player=%d stage=%s active=%d suspended=%d progress_age=%.1f satellite=%d moon=%d mars=%d exoplanet=%d lasers=%d spaceports=%d spaceports_inflight=%d target=%d active_projects=%d current_project=%s migration_stage=%s migration_sensor_ok=%d future_frontier=%d space_race_civic=%d globalization=%d integrated_space_cell=%d international_space_agency=%d",
        state.Turn,
        relativeState.LastEvaluationTurn,
        GetStandardEquivalentTurn(state.Turn),
        playerID,
        ScienceExecution.GetStageName(state.Stage),
        state.Active and 1 or 0,
        state.Suspended and 1 or 0,
        state.ProgressAge,
        state.Satellite,
        state.Moon,
        state.Mars,
        state.Exoplanet,
        state.Lasers,
        state.Spaceports,
        state.SpaceportsInFlight,
        state.SpaceportTarget,
        state.ActiveProjects,
        state.CurrentProject,
        ScienceExecution.GetStageName(state.MigrationStage),
        state.MigrationSensorOk,
        state.FrontierTechs,
        state.SpaceRaceCivic and 1 or 0,
        state.GlobalizationCivic and 1 or 0,
        state.IntegratedSpaceCell,
        state.InternationalSpaceAgency
    ));
end

function ThreatResponse.WriteDiagnostics(playerID, firstTimeThisTurn)
    if not firstTimeThisTurn or not IsMajorAI(playerID) then
        return;
    end
    if GetNumberParameter("ASAI_ENABLE_METRICS", 0) ~= 1 then
        return;
    end
    local relativeState = GetRelativeState(playerID);
    if not relativeState.EvaluatedThisTurn then
        return;
    end
    local state = ThreatResponse.Collect(playerID);
    print(string.format(
        "ASAI_THREAT turn=%d evaluated_turn=%d standard_turn=%.1f player=%d active=%d enemy_air=%d enemy_bombers=%d enemy_gdr=%d air_defense=%d air_required=%d gdr_counters=%d gdr_required=%d air_gap=%d gdr_gap=%d recent_air=%d recent_gdr=%d air_threat_age=%.1f gdr_threat_age=%.1f",
        state.Turn,
        relativeState.LastEvaluationTurn,
        GetStandardEquivalentTurn(state.Turn),
        playerID,
        state.Active and 1 or 0,
        state.EnemyAir,
        state.EnemyBombers,
        state.EnemyGDR,
        state.AirDefense,
        state.AirRequired,
        state.GDRCounters,
        state.GDRRequired,
        state.AirGap and 1 or 0,
        state.GDRGap and 1 or 0,
        state.RecentAir and 1 or 0,
        state.RecentGDR and 1 or 0,
        state.AirThreatAge,
        state.GDRThreatAge
    ));
end

local function LogMetrics(playerID, firstTimeThisTurn)
    if firstTimeThisTurn and IsMajorAI(playerID) then
        local evaluationSuccess, evaluationError = pcall(EvaluateRelativeState, playerID);
        if not evaluationSuccess then
            if m_ConditionErrors.ASAI_EvaluateRelativeState == nil then
                print(string.format(
                    "ASAI_ERROR condition=ASAI_EvaluateRelativeState player=%s fallback=stored error=%s",
                    tostring(playerID),
                    tostring(evaluationError)
                ));
                m_ConditionErrors.ASAI_EvaluateRelativeState = true;
            end
            return;
        end
    end
    local success, metricError = pcall(WriteMetrics, playerID, firstTimeThisTurn);
    if not success and m_ConditionErrors.ASAI_LogMetrics == nil then
        print(string.format(
            "ASAI_ERROR condition=ASAI_LogMetrics player=%s fallback=skip error=%s",
            tostring(playerID),
            tostring(metricError)
        ));
        m_ConditionErrors.ASAI_LogMetrics = true;
    end
    local diagnosticSuccess, diagnosticError = pcall(
        WriteEconomicDiagnostics,
        playerID,
        firstTimeThisTurn
    );
    if not diagnosticSuccess and m_ConditionErrors.ASAI_LogEconomicDiagnostics == nil then
        print(string.format(
            "ASAI_ERROR condition=ASAI_LogEconomicDiagnostics player=%s fallback=skip error=%s",
            tostring(playerID),
            tostring(diagnosticError)
        ));
        m_ConditionErrors.ASAI_LogEconomicDiagnostics = true;
    end
    local cultureSuccess, cultureError = pcall(
        Diagnostics.WriteCultureDiagnostics,
        playerID,
        firstTimeThisTurn
    );
    if not cultureSuccess and m_ConditionErrors.ASAI_LogCultureDiagnostics == nil then
        print(string.format(
            "ASAI_ERROR condition=ASAI_LogCultureDiagnostics player=%s fallback=skip error=%s",
            tostring(playerID),
            tostring(cultureError)
        ));
        m_ConditionErrors.ASAI_LogCultureDiagnostics = true;
    end
    local militarySuccess, militaryError = pcall(
        WriteMilitaryDiagnostics,
        playerID,
        firstTimeThisTurn
    );
    if not militarySuccess and m_ConditionErrors.ASAI_LogMilitaryDiagnostics == nil then
        print(string.format(
            "ASAI_ERROR condition=ASAI_LogMilitaryDiagnostics player=%s fallback=skip error=%s",
            tostring(playerID),
            tostring(militaryError)
        ));
        m_ConditionErrors.ASAI_LogMilitaryDiagnostics = true;
    end
    local threatSuccess, threatError = pcall(
        ThreatResponse.WriteDiagnostics,
        playerID,
        firstTimeThisTurn
    );
    if not threatSuccess and m_ConditionErrors.ASAI_LogThreatDiagnostics == nil then
        print(string.format(
            "ASAI_ERROR condition=ASAI_LogThreatDiagnostics player=%s fallback=skip error=%s",
            tostring(playerID),
            tostring(threatError)
        ));
        m_ConditionErrors.ASAI_LogThreatDiagnostics = true;
    end
    local scienceSuccess, scienceError = pcall(
        ScienceExecution.WriteDiagnostics,
        playerID,
        firstTimeThisTurn
    );
    if not scienceSuccess and m_ConditionErrors.ASAI_LogScienceExecution == nil then
        print(string.format(
            "ASAI_ERROR condition=ASAI_LogScienceExecution player=%s fallback=skip error=%s",
            tostring(playerID),
            tostring(scienceError)
        ));
        m_ConditionErrors.ASAI_LogScienceExecution = true;
    end
end

function Strategic.RecordCityConquered(capturerID, ownerID)
    if not IsMajorAI(capturerID) then
        return;
    end
    if ownerID == nil or ownerID < 0 then
        return;
    end
    local owner = Players[ownerID];
    if owner == nil or not owner:IsMajor() then
        return;
    end
    Strategic.IncrementRuntimeCounter(
        Players[capturerID],
        Strategic.MAJOR_CAPTURE_EVENTS_PROPERTY
    );
    m_Snapshots[capturerID] = nil;
    m_Snapshots[ownerID] = nil;
end

function Strategic.OnCityConquered(capturerID, ownerID, cityID, cityX, cityY)
    local success, captureError = pcall(
        Strategic.RecordCityConquered,
        capturerID,
        ownerID
    );
    if not success and m_ConditionErrors.ASAI_RecordCityConquered == nil then
        print(string.format(
            "ASAI_ERROR condition=ASAI_RecordCityConquered player=%s fallback=skip error=%s",
            tostring(capturerID),
            tostring(captureError)
        ));
        m_ConditionErrors.ASAI_RecordCityConquered = true;
    end
end

function Strategic.RecordMajorPillage(playerID, plotIndex)
    if not IsMajorAI(playerID) then
        return;
    end
    local plot = Map.GetPlotByIndex(plotIndex);
    if plot == nil then
        return;
    end
    local ownerID = plot:GetOwner();
    if ownerID == nil or ownerID < 0 then
        return;
    end
    local owner = Players[ownerID];
    if owner == nil or not owner:IsMajor()
        or not Players[playerID]:GetDiplomacy():IsAtWarWith(ownerID) then
        return;
    end
    Strategic.IncrementRuntimeCounter(
        Players[playerID],
        Strategic.MAJOR_PILLAGE_EVENTS_PROPERTY
    );
    m_Snapshots[playerID] = nil;
end

function Strategic.OnPillage(
    playerID,
    unitID,
    improvementType,
    buildingType,
    districtType,
    plotIndex
)
    local success, pillageError = pcall(
        Strategic.RecordMajorPillage,
        playerID,
        plotIndex
    );
    if not success and m_ConditionErrors.ASAI_RecordMajorPillage == nil then
        print(string.format(
            "ASAI_ERROR condition=ASAI_RecordMajorPillage player=%s fallback=skip error=%s",
            tostring(playerID),
            tostring(pillageError)
        ));
        m_ConditionErrors.ASAI_RecordMajorPillage = true;
    end
end
Events.PlayerTurnActivated.Add(LogMetrics);
Events.UnitDamageChanged.Add(OnUnitDamageChanged);
Events.DistrictDamageChanged.Add(ThreatResponse.OnDistrictDamageChanged);
GameEvents.CityConquered.Add(Strategic.OnCityConquered);
GameEvents.OnPillage.Add(Strategic.OnPillage);
Events.CityProjectCompleted.Add(ScienceExecution.OnCityProjectCompleted);
