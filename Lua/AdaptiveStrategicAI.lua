print("Adaptive Strategic AI " .. tostring(GlobalParameters.ASAI_VERSION) .. " loaded");

local m_Snapshots = {};
local m_StrengthSnapshots = {};
local m_HumanReference = { Turn = -1, Value = nil };
local m_ConditionErrors = {};

local RELATIVE_CATCHUP = -1;
local RELATIVE_MATCHED = 0;
local RELATIVE_CONSOLIDATE = 1;
local RELATIVE_BAND_PROPERTY = "ASAI_RELATIVE_BAND";
local RELATIVE_SCORE_PROPERTY = "ASAI_RELATIVE_SCORE_X1000";
local RELATIVE_TURN_PROPERTY = "ASAI_RELATIVE_LAST_EVAL_TURN";

local RELATIVE_COMPONENTS = {
    { Key = "Techs", Parameter = "ASAI_RELATIVE_WEIGHT_TECHS", Weight = 20 },
    { Key = "Civics", Parameter = "ASAI_RELATIVE_WEIGHT_CIVICS", Weight = 18 },
    { Key = "Science", Parameter = "ASAI_RELATIVE_WEIGHT_SCIENCE", Weight = 12 },
    { Key = "Culture", Parameter = "ASAI_RELATIVE_WEIGHT_CULTURE", Weight = 12 },
    { Key = "Cities", Parameter = "ASAI_RELATIVE_WEIGHT_CITIES", Weight = 10 },
    { Key = "Population", Parameter = "ASAI_RELATIVE_WEIGHT_POPULATION", Weight = 15 },
    { Key = "Military", Parameter = "ASAI_RELATIVE_WEIGHT_MILITARY", Weight = 13 }
};

local function GetNumberParameter(name, fallback)
    local value = tonumber(GlobalParameters[name]);
    if value == nil then
        return fallback;
    end
    return value;
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

local function IsMajorAI(playerID)
    if not PlayerManager.IsAlive(playerID) then
        return false;
    end
    local player = Players[playerID];
    return player ~= nil and player:IsMajor() and not player:IsHuman();
end

local function CountOwnedImprovements(playerID)
    local count = 0;
    for plotIndex = 0, Map.GetPlotCount() - 1 do
        local plot = Map.GetPlotByIndex(plotIndex);
        if plot ~= nil and plot:GetOwner() == playerID and plot:GetImprovementType() >= 0 then
            count = count + 1;
        end
    end
    return count;
end

local function CountUnits(player)
    local builders = 0;
    local traders = 0;
    for _, unit in player:GetUnits():Members() do
        local unitInfo = GameInfo.Units[unit:GetType()];
        if unitInfo ~= nil then
            if unitInfo.UnitType == "UNIT_BUILDER" then
                builders = builders + 1;
            end
            if unitInfo.MakeTradeRoute then
                traders = traders + 1;
            end
        end
    end
    return builders, traders;
end

local function CountWars(playerID, player)
    local wars = 0;
    local diplomacy = player:GetDiplomacy();
    for _, otherID in ipairs(PlayerManager.GetAliveMajorIDs()) do
        if otherID ~= playerID and diplomacy:IsAtWarWith(otherID) then
            wars = wars + 1;
        end
    end
    return wars;
end

local function GetSnapshot(playerID)
    local turn = Game.GetCurrentGameTurn();
    local cached = m_Snapshots[playerID];
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

    local builders, traders = CountUnits(player);
    local trade = player:GetTrade();
    local treasury = player:GetTreasury();
    local snapshot = {
        Turn = turn,
        Cities = cities,
        Population = population,
        Improvements = CountOwnedImprovements(playerID),
        Builders = builders,
        Traders = traders,
        RouteCapacity = trade:GetOutgoingRouteCapacity(),
        GoldBalance = treasury:GetGoldBalance(),
        NetGold = treasury:GetGoldYield() - treasury:GetTotalMaintenance(),
        Wars = CountWars(playerID, player),
        Era = player:GetEra()
    };
    m_Snapshots[playerID] = snapshot;
    return snapshot;
end

local function IsInfrastructureRecovery(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    local snapshot = GetSnapshot(playerID);
    local startTurn = GetNumberParameter("ASAI_INFRA_START_TURN", 20);
    if snapshot.Turn < startTurn or snapshot.Population <= 0 then
        return false;
    end
    local ratio = GetNumberParameter("ASAI_INFRA_IMPROVEMENTS_PER_POP_X100", 80);
    local target = math.ceil(snapshot.Population * ratio / 100);
    local covered = snapshot.Improvements + snapshot.Builders * 2;
    return covered < target;
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

local function IsTradeRecovery(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    local snapshot = GetSnapshot(playerID);
    -- Active routes still own trader units, so total trader units already
    -- includes both assigned and idle traders and prevents queue overshoot.
    return snapshot.RouteCapacity > snapshot.Traders;
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
    return GetSnapshot(playerID).Wars > 0;
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
    for _, unit in player:GetUnits():Members() do
        local unitInfo = GameInfo.Units[unit:GetType()];
        if unitInfo ~= nil then
            strength = strength + math.max(
                tonumber(unitInfo.Combat) or 0,
                tonumber(unitInfo.RangedCombat) or 0,
                tonumber(unitInfo.Bombard) or 0,
                tonumber(unitInfo.AntiAirCombat) or 0
            );
        end
    end
    return strength;
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
    local snapshot = {
        Turn = turn,
        Techs = techs,
        Civics = civics,
        Science = math.max(0, player:GetTechs():GetScienceYield()),
        Culture = math.max(0, player:GetCulture():GetCultureYield()),
        Cities = cities,
        Population = population,
        Military = EstimateMilitaryStrength(player)
    };
    m_StrengthSnapshots[playerID] = snapshot;
    return snapshot;
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
        Military = 0
    };
    local humans = 0;
    for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
        local player = Players[playerID];
        if player ~= nil and player:IsHuman() then
            local strength = GetStrengthSnapshot(playerID);
            humans = humans + 1;
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
    m_HumanReference = { Turn = turn, Value = total };
    return total;
end

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value));
end

local function GetRelativeScore(aiStrength, humanStrength)
    local minimum = GetNumberParameter("ASAI_RELATIVE_COMPONENT_MIN_X100", 55) / 100;
    local maximum = GetNumberParameter("ASAI_RELATIVE_COMPONENT_MAX_X100", 145) / 100;
    local weightedScore = 0;
    local totalWeight = 0;

    for _, component in ipairs(RELATIVE_COMPONENTS) do
        local humanValue = humanStrength[component.Key];
        local ratio = 1;
        local weight = math.max(0, GetNumberParameter(component.Parameter, component.Weight));
        if humanValue > 0 then
            ratio = aiStrength[component.Key] / humanValue;
        end
        weightedScore = weightedScore + Clamp(ratio, minimum, maximum) * weight;
        totalWeight = totalWeight + weight;
    end
    if totalWeight <= 0 then
        return 1;
    end
    return weightedScore / totalWeight;
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

local function GetRelativeBand(playerID)
    if not IsMajorAI(playerID) or GetNumberParameter("ASAI_RELATIVE_PACING_ENABLED", 1) ~= 1 then
        return RELATIVE_MATCHED, 1;
    end

    local turn = Game.GetCurrentGameTurn();
    local player = Players[playerID];
    local band = GetStoredNumber(player, RELATIVE_BAND_PROPERTY, RELATIVE_MATCHED);
    if band ~= RELATIVE_CATCHUP and band ~= RELATIVE_CONSOLIDATE then
        band = RELATIVE_MATCHED;
    end

    local storedScore = GetStoredNumber(player, RELATIVE_SCORE_PROPERTY, 1000) / 1000;
    local startTurn = GetNumberParameter("ASAI_RELATIVE_START_TURN", 35);
    if turn < startTurn then
        return RELATIVE_MATCHED, storedScore;
    end

    local interval = math.max(1, GetNumberParameter("ASAI_RELATIVE_CHECK_INTERVAL", 5));
    local lastTurn = GetStoredNumber(player, RELATIVE_TURN_PROPERTY, -interval);
    if turn - lastTurn < interval then
        return band, storedScore;
    end

    local humanStrength = GetHumanReference();
    if humanStrength == nil then
        return RELATIVE_MATCHED, 1;
    end

    local score = GetRelativeScore(GetStrengthSnapshot(playerID), humanStrength);
    local previousBand = band;
    local trailingEnter = GetNumberParameter("ASAI_RELATIVE_TRAILING_ENTER_X100", 85) / 100;
    local trailingExit = GetNumberParameter("ASAI_RELATIVE_TRAILING_EXIT_X100", 92) / 100;
    local leadingExit = GetNumberParameter("ASAI_RELATIVE_LEADING_EXIT_X100", 108) / 100;
    local leadingEnter = GetNumberParameter("ASAI_RELATIVE_LEADING_ENTER_X100", 115) / 100;

    if band == RELATIVE_CATCHUP then
        if score >= trailingExit then
            band = RELATIVE_MATCHED;
        end
    elseif band == RELATIVE_CONSOLIDATE then
        if score <= leadingExit then
            band = RELATIVE_MATCHED;
        end
    elseif score <= trailingEnter then
        band = RELATIVE_CATCHUP;
    elseif score >= leadingEnter then
        band = RELATIVE_CONSOLIDATE;
    end

    player:SetProperty(RELATIVE_BAND_PROPERTY, band);
    player:SetProperty(RELATIVE_SCORE_PROPERTY, math.floor(score * 1000 + 0.5));
    player:SetProperty(RELATIVE_TURN_PROPERTY, turn);

    if band ~= previousBand then
        print(string.format(
            "ASAI_PACING turn=%d player=%d score=%.3f from=%s to=%s",
            turn,
            playerID,
            score,
            GetBandName(previousBand),
            GetBandName(band)
        ));
    end
    return band, score;
end

local function IsRelativeCatchup(playerID, threshold)
    local band = GetRelativeBand(playerID);
    return band == RELATIVE_CATCHUP;
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

local function IsRelativeConsolidate(playerID, threshold)
    local band = GetRelativeBand(playerID);
    return band == RELATIVE_CONSOLIDATE;
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

local function LogMetrics(playerID, firstTimeThisTurn)
    if not firstTimeThisTurn or not IsMajorAI(playerID) then
        return;
    end
    if GetNumberParameter("ASAI_ENABLE_METRICS", 0) ~= 1 then
        return;
    end

    local interval = math.max(1, GetNumberParameter("ASAI_METRICS_INTERVAL", 25));
    local snapshot = GetSnapshot(playerID);
    if snapshot.Turn % interval ~= 0 then
        return;
    end

    local strength = GetStrengthSnapshot(playerID);
    local relativeBand, relativeScore = GetRelativeBand(playerID);
    print(string.format(
        "ASAI_METRIC turn=%d player=%d cities=%d pop=%d improved=%d builders=%d traders=%d capacity=%d gold=%.1f netgold=%.1f science=%.1f culture=%.1f techs=%d civics=%d military=%d wars=%d era=%d relative=%.3f pacing=%s",
        snapshot.Turn,
        playerID,
        snapshot.Cities,
        snapshot.Population,
        snapshot.Improvements,
        snapshot.Builders,
        snapshot.Traders,
        snapshot.RouteCapacity,
        snapshot.GoldBalance,
        snapshot.NetGold,
        strength.Science,
        strength.Culture,
        strength.Techs,
        strength.Civics,
        strength.Military,
        snapshot.Wars,
        snapshot.Era,
        relativeScore,
        GetBandName(relativeBand)
    ));
end
Events.PlayerTurnActivated.Add(LogMetrics);
