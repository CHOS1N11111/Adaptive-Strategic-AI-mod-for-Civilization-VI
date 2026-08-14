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
    BASELINE_COMBAT_PROPERTY = "ASAI_STRATEGIC_PLAN_BASELINE_COMBAT",
    GAIN_PROPERTY = "ASAI_STRATEGIC_PLAN_GAIN_X1000",
    RESULT_PROPERTY = "ASAI_STRATEGIC_PLAN_RESULT",
    EXECUTION_PROPERTY = "ASAI_STRATEGIC_PLAN_EXECUTION",
    STALL_COUNT_PROPERTY = "ASAI_STRATEGIC_PLAN_STALL_COUNT",
    SCORE_PROPERTY = "ASAI_STRATEGIC_PLAN_SCORE_X100",
    SUPPORT_PROPERTY = "ASAI_STRATEGIC_SUPPORT",
    OUTCOME_SCHEMA = 2,
    OUTCOME_SCHEMA_PROPERTY = "ASAI_STRATEGIC_PLAN_OUTCOME_SCHEMA"
};
Strategic.COOLDOWN_PROPERTIES = {
    [Strategic.DEVELOP] = "ASAI_PLAN_DEVELOP_COOLDOWN_UNTIL",
    [Strategic.RECOVER] = "ASAI_PLAN_RECOVER_COOLDOWN_UNTIL",
    [Strategic.EXPAND] = "ASAI_PLAN_EXPAND_COOLDOWN_UNTIL",
    [Strategic.DEFEND] = "ASAI_PLAN_DEFEND_COOLDOWN_UNTIL",
    [Strategic.PRESSURE] = "ASAI_PLAN_PRESSURE_COOLDOWN_UNTIL",
    [Strategic.WAR] = "ASAI_PLAN_WAR_COOLDOWN_UNTIL"
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

local function TryDiagnosticSensor(sensorName, collector)
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
        Empire = 0
    };
    for _, city in player:GetCities():Members() do
        local productionType = GetCurrentProductionType(city);
        if productionType == nil then
            result.Idle = result.Idle + 1;
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
        ActiveMajorWars = activeMajorWars,
        LastMajorCombatTurn = lastMajorCombatTurn,
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
        Empire = -1
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
        ResourceSupported = 0,
        UpgradeSupported = 0
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
        StrategicPlanBaselineCombat = 0,
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
    state.StrategicPlanBaselineCombat = GetStoredNumber(
        player,
        Strategic.BASELINE_COMBAT_PROPERTY,
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
        Strategic.BASELINE_COMBAT_PROPERTY,
        state.StrategicPlanBaselineCombat
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

local function SyncMildResultYields(playerID, player, state, turn)
    local enabled = GetNumberParameter(
        "ASAI_MILD_RESULT_YIELDS_ENABLED",
        1
    ) == 1;
    local desiredActive = enabled
        and state.Band == RELATIVE_CATCHUP
        and state.SevereCatchup ~= 1;
    local currentlyActive = state.MildResultYieldsActive == 1;
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
        "ASAI_RESULT turn=%d standard_turn=%.1f player=%d tier=mild active=%d action=%s production=%d science=%d culture=%d food=%d relative=%.3f second_core=%.3f weakest_core=%.3f",
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
        GetWeakestCorePillarScore(state)
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

local function UpdateScaleExpansionAvailability(state, snapshot)
    local densityExit = GetNumberParameter(
        "ASAI_MILITARY_UNITS_PER_PLANNED_CITY_EXIT_X100",
        225
    ) / 100;
    state.ScaleExpansionAllowed = state.StrategicPlan == Strategic.EXPAND
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
    if state.MilitaryDominance == 1 then
        return state.RawScores.Military >= exit and 1 or 0;
    end
    return state.RawScores.Military >= enter and 1 or 0;
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

local function StartFocusReview(state, focus, turn)
    state.FocusStartedTurn = turn;
    state.FocusReviewTurn = turn;
    state.FocusBaseline = GetFocusScore(state, focus, false);
    state.FocusRawBaseline = GetFocusScore(state, focus, true);
    state.FocusGain = 0;
    state.FocusRawGain = 0;
    state.FocusResult = RELATIVE_FOCUS_RESULT_NONE;
    state.FocusExecution = 0;
    state.FocusStallCount = 0;
end

local function ResetFocusReviewBaseline(state, turn)
    state.FocusReviewTurn = turn;
    state.FocusBaseline = GetFocusScore(state, state.Focus, false);
    state.FocusRawBaseline = GetFocusScore(state, state.Focus, true);
end

local function ReviewActiveFocus(playerID, state, turn)
    if state.Focus == RELATIVE_FOCUS_NONE then
        return false;
    end
    if not Strategic.IsFocusCompatible(state, state.Focus) then
        ResetFocusReviewBaseline(state, turn);
        state.FocusExecution = 0;
        return false;
    end
    if state.FocusReviewTurn < 0 then
        StartFocusReview(state, state.Focus, turn);
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
    if state.FocusGain < minimumGain and state.FocusRawGain < minimumRawGain then
        state.FocusStallCount = state.FocusStallCount + 1;
        state.FocusResult = state.FocusExecution == 0
            and RELATIVE_FOCUS_RESULT_STALLED
            or RELATIVE_FOCUS_RESULT_EXECUTING;
    else
        state.FocusResult = RELATIVE_FOCUS_RESULT_IMPROVING;
        state.FocusStallCount = 0;
    end

    print(string.format(
        "ASAI_FOCUS turn=%d standard_turn=%.1f player=%d focus=%s result=%s queue_response=%d stall_count=%d gain=%.3f raw_gain=%.3f",
        turn,
        GetStandardEquivalentTurn(turn),
        playerID,
        GetFocusName(state.Focus),
        GetFocusResultName(state.FocusResult),
        state.FocusExecution,
        state.FocusStallCount,
        state.FocusGain,
        state.FocusRawGain
    ));

    local stallLimit = math.max(
        1,
        GetNumberParameter("ASAI_RELATIVE_FOCUS_STALL_LIMIT", 3)
    );
    local retireFocus = state.FocusResult ~= RELATIVE_FOCUS_RESULT_IMPROVING
        and state.FocusStallCount >= stallLimit;
    if not retireFocus then
        ResetFocusReviewBaseline(state, turn);
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

function Strategic.StartPlanReview(state, snapshot, strength, turn)
    state.StrategicPlanStartedTurn = turn;
    state.StrategicPlanReviewTurn = turn;
    state.StrategicPlanBaseline = Strategic.GetPlanOutcomeScore(
        state,
        state.StrategicPlan
    );
    state.StrategicPlanBaselineCities = snapshot.Cities;
    state.StrategicPlanBaselineCaptured = snapshot.CapturedCities;
    state.StrategicPlanBaselineCombat = strength.CombatUnits;
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
    state.StrategicPlanBaselineCombat = strength.CombatUnits;
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
    local combatGain = strength.CombatUnits - state.StrategicPlanBaselineCombat;
    local minimumGain = GetNumberParameter("ASAI_PLAN_MIN_GAIN_X100", 2) / 100;
    local improved = state.StrategicPlanGain >= minimumGain;
    if state.StrategicPlan == Strategic.EXPAND then
        improved = improved or cityGain > 0;
    elseif state.StrategicPlan == Strategic.DEFEND then
        improved = improved or combatGain > 0;
    elseif state.StrategicPlan == Strategic.PRESSURE then
        improved = improved or snapshot.ActiveMajorWars > 0 or cityGain > 0;
    elseif state.StrategicPlan == Strategic.WAR then
        improved = improved or capturedGain > 0;
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
        "ASAI_PLAN_REVIEW turn=%d standard_turn=%.1f player=%d plan=%s result=%s execution=%d stall_count=%d gain=%.3f city_gain=%d capture_gain=%d combat_gain=%d active_major_wars=%d",
        turn,
        GetStandardEquivalentTurn(turn),
        playerID,
        Strategic.GetPlanName(state.StrategicPlan),
        GetFocusResultName(state.StrategicPlanResult),
        state.StrategicPlanExecution,
        state.StrategicPlanStallCount,
        state.StrategicPlanGain,
        cityGain,
        capturedGain,
        combatGain,
        snapshot.ActiveMajorWars
    ));

    local stallLimit = math.max(
        1,
        GetNumberParameter("ASAI_PLAN_STALL_LIMIT", 2)
    );
    local retirePlan = state.StrategicPlan ~= Strategic.DEVELOP
        and state.StrategicPlan ~= Strategic.WAR
        and state.StrategicPlanResult ~= RELATIVE_FOCUS_RESULT_IMPROVING
        and state.StrategicPlanStallCount >= stallLimit;
    if not retirePlan then
        Strategic.ResetPlanReviewBaseline(state, snapshot, strength, turn);
    end
    return retirePlan;
end

function Strategic.GetPlanScores(state, snapshot, turn)
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
    scores[Strategic.WAR] = snapshot.ActiveMajorWars > 0
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
            and plan ~= Strategic.WAR
            and plan ~= Strategic.DEFEND then
            scores[plan] = 0;
        end
    end
    return scores;
end

function Strategic.SelectPlan(state, snapshot, scores)
    if snapshot.ActiveMajorWars > 0 then
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
        return Strategic.DEFEND, "military_emergency";
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
    return selected, "highest_score";
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
            "ASAI_DOMINANCE turn=%d standard_turn=%.1f player=%d raw_military=%.3f military=%.3f from=on to=off reason=active_major_war",
            turn,
            GetStandardEquivalentTurn(turn),
            playerID,
            state.RawScores.Military,
            state.Scores.Military
        ));
    end
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
            local resetOutcomeBaseline = (state.StrategicPlan == Strategic.PRESSURE
                    and previousOutcomeSchema < 1)
                or (state.StrategicPlan == Strategic.WAR
                    and previousOutcomeSchema < 2);
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
                else
                    resetWarBaseline = 1;
                end
            end
            state.StrategicPlanOutcomeSchema = Strategic.OUTCOME_SCHEMA;
            print(string.format(
                "ASAI_PLAN_MIGRATION turn=%d standard_turn=%.1f player=%d plan=%s from_schema=%d to_schema=%d reset_pressure_baseline=%d reset_war_baseline=%d",
                turn,
                GetStandardEquivalentTurn(turn),
                playerID,
                Strategic.GetPlanName(state.StrategicPlan),
                previousOutcomeSchema,
                state.StrategicPlanOutcomeSchema,
                resetPressureBaseline,
                resetWarBaseline
            ));
        end

        local strategicPlanRetired = Strategic.ReviewPlan(
            playerID,
            state,
            empireSnapshot,
            strengthSnapshot,
            turn
        );
        if strategicPlanRetired then
            local stalledPlanCooldown = ScaleStandardTurns(
                GetNumberParameter("ASAI_PLAN_STALL_COOLDOWN_STANDARD", 16)
            );
            state.StrategicPlanCooldownUntil[state.StrategicPlan] = math.max(
                state.StrategicPlanCooldownUntil[state.StrategicPlan] or -1,
                turn + stalledPlanCooldown
            );
        end
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
            or strategicPlanReason == "military_emergency";
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
                StartFocusReview(state, state.Focus, turn);
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
                "ASAI_DOMINANCE turn=%d standard_turn=%.1f player=%d raw_military=%.3f military=%.3f from=%s to=%s reason=%s",
                turn,
                GetStandardEquivalentTurn(turn),
                playerID,
                state.RawScores.Military,
                state.Scores.Military,
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
                "ASAI_PLAN turn=%d standard_turn=%.1f player=%d from=%s to=%s support_from=%s support_to=%s reason=%s score=%.1f develop=%.1f recover=%.1f expand=%.1f defend=%.1f pressure=%.1f war=%.1f result=%s",
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
                GetFocusResultName(state.StrategicPlanResult)
            ));
        end
        if focusChanged then
            print(string.format(
                "ASAI_RECOVERY turn=%d standard_turn=%.1f player=%d raw_science=%.3f raw_culture=%.3f raw_empire=%.3f science=%.3f culture=%.3f empire=%.3f from=%s to=%s result=%s handoff_ready=%d gain=%.3f raw_gain=%.3f",
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
                state.FocusRawGain
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

local function GetMilitaryQueueTarget(snapshot)
    local targetPercent = snapshot.ActiveMajorWars > 0
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
    local target = GetMilitaryQueueTarget(snapshot);
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

local function MarkRecentMajorCombat(playerID)
    if not IsMajorAI(playerID) then
        return;
    end
    Players[playerID]:SetProperty(
        LAST_MAJOR_COMBAT_TURN_PROPERTY,
        Game.GetCurrentGameTurn()
    );
    m_Snapshots[playerID] = nil;
end

local function RecordUnitDamage(playerID, unitID, damage)
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
            if opponent ~= nil and IsCombatUnitNear(
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

local function OnUnitDamageChanged(playerID, unitID, damage)
    local success, combatError = pcall(
        RecordUnitDamage,
        playerID,
        unitID,
        damage
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
    local resultYieldsActive = (relativeState.MildResultYieldsActive == 1
        or relativeState.SevereResultYieldsActive == 1) and 1 or 0;
    print(string.format(
        "ASAI_METRIC turn=%d evaluated_turn=%d standard_turn=%.1f player=%d stage=%s cities=%d captured=%d pop=%d owned=%d improved=%d infratarget=%d builder_budget=%d trader_budget=%d settler_budget=%d settler_cap=%d builders=%d builders_inflight=%d traders=%d traders_inflight=%d settlers=%d settlers_inflight=%d capacity=%d capacity_target=%d gold=%.1f netgold=%.1f science=%.1f culture=%.1f techs=%d civics=%d military=%d wars=%d major_wars=%d active_major_wars=%d combat_age=%.1f minor_wars=%d era=%d relative_raw=%.3f relative=%.3f second_core=%.3f weakest_core=%.3f science_raw=%.3f science_ratio=%.3f culture_raw=%.3f culture_ratio=%.3f empire_raw=%.3f empire_ratio=%.3f military_raw=%.3f military_ratio=%.3f military_readiness=%d military_dominance=%d scale_recovery=%d scale_expansion=%d result_yields=%d mild_result_yields=%d severe_result_yields=%d result_tier=%s pacing=%s support=%s focus=%s focus_result=%s handoff_ready=%d focus_gain=%.3f focus_raw_gain=%.3f focus_age=%.1f focus_execution=%d focus_stalls=%d plan=%s plan_support=%s plan_result=%s plan_score=%.1f plan_gain=%.3f plan_execution=%d plan_stalls=%d",
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
    local human = GetHumanEconomicReference();
    local productionRatio = human ~= nil
        and GetDiagnosticRatio(economic.Production, human.Production) or -1;
    local productionPerCityRatio = human ~= nil
        and GetDiagnosticRatio(
            economic.ProductionPerCity,
            human.ProductionPerCity
        ) or -1;
    print(string.format(
        "ASAI_ECONOMY turn=%d evaluated_turn=%d standard_turn=%.1f player=%d production=%.1f production_per_city=%.2f production_per_pop=%.2f production_ratio=%.3f production_per_city_ratio=%.3f district_used=%d district_completed=%d district_estimated_slots=%d district_util=%.3f district_slot_mode=population_formula route_capacity=%d route_coverage=%.3f route_pipeline=%.3f improvement_coverage=%.3f improvement_pipeline=%.3f improved_land=%.3f production_ok=%d district_ok=%d",
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
        economic.ImprovementCoverage,
        economic.ImprovementPipelineCoverage,
        economic.ImprovedLand,
        economic.ProductionOk,
        economic.DistrictOk
    ));
    print(string.format(
        "ASAI_CONVERSION turn=%d evaluated_turn=%d standard_turn=%.1f player=%d cities=%d queue_units=%d queue_districts=%d queue_buildings=%d queue_projects=%d queue_wonders=%d queue_idle=%d queue_unknown=%d queue_science=%d queue_culture=%d queue_empire=%d gold=%.1f gold_reserve=%.1f gold_surplus=%.1f gold_per_city=%.1f queue_ok=%d resource_supported=%d upgrade_supported=%d",
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
    local unitsPerCity = snapshot.Cities > 0
        and strength.CombatUnits / snapshot.Cities or 0;
    local defenseCoverage = defenseSupported == 1 and defenses.Cities > 0
        and defenses.DefendedCities / defenses.Cities or -1;
    local militaryExecution, militaryQueueTarget = GetMilitaryExecutionStatus(playerID);
    print(string.format(
        "ASAI_MILITARY turn=%d evaluated_turn=%d standard_turn=%.1f player=%d strength=%d combat_units=%d land_units=%d ranged_units=%d siege_units=%d mobile_units=%d naval_units=%d air_units=%d units_per_city=%.2f planned_cities=%d units_per_planned_city=%.2f queue_combat=%d queue_target=%d military_execution=%d queue_land=%d queue_ranged=%d queue_siege=%d queue_mobile=%d queue_naval=%d queue_air=%d defended_cities=%d defense_coverage=%.3f defense_supported=%d military_raw=%.3f military_ratio=%.3f military_readiness=%d military_dominance=%d active_major_wars=%d",
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
        economic.Queue.Combat,
        militaryQueueTarget,
        militaryExecution and 1 or 0,
        economic.Queue.Land,
        economic.Queue.Ranged,
        economic.Queue.Siege,
        economic.Queue.Mobile,
        economic.Queue.Naval,
        economic.Queue.Air,
        defenses.DefendedCities,
        defenseCoverage,
        defenseSupported,
        relativeState.RawScores.Military,
        relativeState.Scores.Military,
        relativeState.MilitaryReadiness,
        relativeState.MilitaryDominance,
        snapshot.ActiveMajorWars
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
end
Events.PlayerTurnActivated.Add(LogMetrics);
Events.UnitDamageChanged.Add(OnUnitDamageChanged);
