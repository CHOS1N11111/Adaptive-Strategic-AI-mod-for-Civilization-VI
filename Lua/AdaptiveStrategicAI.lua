print("Adaptive Strategic AI " .. tostring(GlobalParameters.ASAI_VERSION) .. " loaded");

local m_Snapshots = {};
local m_StrengthSnapshots = {};
local m_HumanReference = { Turn = -1, Value = nil };
local m_ConditionErrors = {};

local RELATIVE_CATCHUP = -1;
local RELATIVE_MATCHED = 0;
local RELATIVE_CONSOLIDATE = 1;
local RELATIVE_BAND_PROPERTY = "ASAI_RELATIVE_BAND";
local RELATIVE_TURN_PROPERTY = "ASAI_RELATIVE_LAST_EVAL_TURN";
local RELATIVE_SCORE_PROPERTIES = {
    Overall = "ASAI_RELATIVE_SCORE_X1000",
    Science = "ASAI_RELATIVE_SCIENCE_X1000",
    Culture = "ASAI_RELATIVE_CULTURE_X1000",
    Empire = "ASAI_RELATIVE_EMPIRE_X1000",
    Military = "ASAI_RELATIVE_MILITARY_X1000"
};
local RELATIVE_RECOVERY_PROPERTIES = {
    Science = "ASAI_RELATIVE_SCIENCE_RECOVERY",
    Culture = "ASAI_RELATIVE_CULTURE_RECOVERY",
    Empire = "ASAI_RELATIVE_EMPIRE_RECOVERY"
};

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
    for _, otherID in ipairs(PlayerManager.GetAliveIDs()) do
        local otherPlayer = Players[otherID];
        if otherID ~= playerID
            and otherPlayer ~= nil
            and not otherPlayer:IsBarbarian()
            and diplomacy:IsAtWarWith(otherID) then
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
    local ownedPlots, improvements = CountOwnedPlots(playerID);
    local trade = player:GetTrade();
    local treasury = player:GetTreasury();
    local snapshot = {
        Turn = turn,
        Cities = cities,
        Population = population,
        OwnedPlots = ownedPlots,
        Improvements = improvements,
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

local function GetInfrastructureTarget(snapshot)
    local perCity = GetNumberParameter("ASAI_INFRA_IMPROVEMENTS_PER_CITY_X100", 200);
    local perPopulation = GetNumberParameter("ASAI_INFRA_IMPROVEMENTS_PER_POP_X100", 65);
    local ownedPlotsCap = GetNumberParameter("ASAI_INFRA_OWNED_PLOTS_CAP_X100", 30);
    local cityFloor = snapshot.Cities * perCity / 100;
    local populationTarget = snapshot.Population * perPopulation / 100;
    local landCap = snapshot.OwnedPlots * ownedPlotsCap / 100;
    return math.ceil(math.max(cityFloor, math.min(populationTarget, landCap)));
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
    local target = GetInfrastructureTarget(snapshot);
    local builderCredit = GetNumberParameter("ASAI_INFRA_BUILDER_CREDIT", 2);
    local covered = snapshot.Improvements + snapshot.Builders * builderCredit;
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

local function GetRelativeScores(aiStrength, humanStrength)
    local minimum = GetNumberParameter("ASAI_RELATIVE_COMPONENT_MIN_X100", 55) / 100;
    local maximum = GetNumberParameter("ASAI_RELATIVE_COMPONENT_MAX_X100", 145) / 100;
    local militaryMaximum = GetNumberParameter("ASAI_RELATIVE_MILITARY_MAX_X100", 120) / 100;
    militaryMaximum = Clamp(militaryMaximum, minimum, maximum);
    local ratios = {};
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
        ratios[component.Key] = Clamp(ratio, minimum, componentMaximum);
        weights[component.Key] = weight;
        table.insert(allKeys, component.Key);
    end

    return {
        Overall = GetWeightedScore(ratios, weights, allKeys),
        Science = GetWeightedScore(ratios, weights, RELATIVE_PILLARS.Science),
        Culture = GetWeightedScore(ratios, weights, RELATIVE_PILLARS.Culture),
        Empire = GetWeightedScore(ratios, weights, RELATIVE_PILLARS.Empire),
        Military = GetWeightedScore(ratios, weights, RELATIVE_PILLARS.Military)
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

local function GetNeutralRelativeState()
    return {
        Band = RELATIVE_MATCHED,
        Scores = { Overall = 1, Science = 1, Culture = 1, Empire = 1, Military = 1 },
        Recovery = { Science = false, Culture = false, Empire = false }
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
    for pillar, propertyName in pairs(RELATIVE_RECOVERY_PROPERTIES) do
        state.Recovery[pillar] = GetStoredNumber(player, propertyName, 0) == 1;
    end
    return state;
end

local function UpdateRecoveryState(active, score, enterThreshold, exitThreshold)
    if active then
        return score < exitThreshold;
    end
    return score <= enterThreshold;
end

local function StoreRelativeState(player, turn, state)
    player:SetProperty(RELATIVE_BAND_PROPERTY, state.Band);
    for pillar, propertyName in pairs(RELATIVE_SCORE_PROPERTIES) do
        player:SetProperty(propertyName, math.floor(state.Scores[pillar] * 1000 + 0.5));
    end
    for pillar, propertyName in pairs(RELATIVE_RECOVERY_PROPERTIES) do
        player:SetProperty(propertyName, state.Recovery[pillar] and 1 or 0);
    end
    player:SetProperty(RELATIVE_TURN_PROPERTY, turn);
end

local function GetRelativeState(playerID)
    if not IsMajorAI(playerID) or GetNumberParameter("ASAI_RELATIVE_PACING_ENABLED", 1) ~= 1 then
        return GetNeutralRelativeState();
    end

    local turn = Game.GetCurrentGameTurn();
    local player = Players[playerID];
    local state = ReadRelativeState(player);
    local startTurn = GetNumberParameter("ASAI_RELATIVE_START_TURN", 35);
    if turn < startTurn then
        return GetNeutralRelativeState();
    end

    local interval = math.max(1, GetNumberParameter("ASAI_RELATIVE_CHECK_INTERVAL", 5));
    local lastTurn = GetStoredNumber(player, RELATIVE_TURN_PROPERTY, -interval);
    if turn - lastTurn < interval then
        return state;
    end

    local humanStrength = GetHumanReference();
    if humanStrength == nil then
        return GetNeutralRelativeState();
    end

    local previousBand = state.Band;
    local previousRecovery = {
        Science = state.Recovery.Science,
        Culture = state.Recovery.Culture,
        Empire = state.Recovery.Empire
    };
    state.Scores = GetRelativeScores(GetStrengthSnapshot(playerID), humanStrength);

    local trailingEnter = GetNumberParameter("ASAI_RELATIVE_TRAILING_ENTER_X100", 90) / 100;
    local trailingExit = GetNumberParameter("ASAI_RELATIVE_TRAILING_EXIT_X100", 96) / 100;
    local leadingExit = GetNumberParameter("ASAI_RELATIVE_LEADING_EXIT_X100", 108) / 100;
    local leadingEnter = GetNumberParameter("ASAI_RELATIVE_LEADING_ENTER_X100", 115) / 100;
    local leadingPillarMinimum = GetNumberParameter("ASAI_RELATIVE_LEADING_PILLAR_MIN_X100", 90) / 100;
    local weakestCorePillar = math.min(
        state.Scores.Science,
        state.Scores.Culture,
        state.Scores.Empire
    );

    if state.Band == RELATIVE_CATCHUP then
        if state.Scores.Overall >= trailingExit then
            state.Band = RELATIVE_MATCHED;
        end
    elseif state.Band == RELATIVE_CONSOLIDATE then
        if state.Scores.Overall <= leadingExit or weakestCorePillar < leadingPillarMinimum then
            state.Band = RELATIVE_MATCHED;
        end
    elseif state.Scores.Overall <= trailingEnter then
        state.Band = RELATIVE_CATCHUP;
    elseif state.Scores.Overall >= leadingEnter and weakestCorePillar >= leadingPillarMinimum then
        state.Band = RELATIVE_CONSOLIDATE;
    end

    state.Recovery.Science = UpdateRecoveryState(
        state.Recovery.Science,
        state.Scores.Science,
        GetNumberParameter("ASAI_RELATIVE_SCIENCE_ENTER_X100", 80) / 100,
        GetNumberParameter("ASAI_RELATIVE_SCIENCE_EXIT_X100", 92) / 100
    );
    state.Recovery.Culture = UpdateRecoveryState(
        state.Recovery.Culture,
        state.Scores.Culture,
        GetNumberParameter("ASAI_RELATIVE_CULTURE_ENTER_X100", 75) / 100,
        GetNumberParameter("ASAI_RELATIVE_CULTURE_EXIT_X100", 88) / 100
    );
    state.Recovery.Empire = UpdateRecoveryState(
        state.Recovery.Empire,
        state.Scores.Empire,
        GetNumberParameter("ASAI_RELATIVE_EMPIRE_ENTER_X100", 80) / 100,
        GetNumberParameter("ASAI_RELATIVE_EMPIRE_EXIT_X100", 92) / 100
    );

    StoreRelativeState(player, turn, state);

    if state.Band ~= previousBand then
        print(string.format(
            "ASAI_PACING turn=%d player=%d overall=%.3f science=%.3f culture=%.3f empire=%.3f military=%.3f from=%s to=%s",
            turn,
            playerID,
            state.Scores.Overall,
            state.Scores.Science,
            state.Scores.Culture,
            state.Scores.Empire,
            state.Scores.Military,
            GetBandName(previousBand),
            GetBandName(state.Band)
        ));
    end
    for _, pillar in ipairs({ "Science", "Culture", "Empire" }) do
        if state.Recovery[pillar] ~= previousRecovery[pillar] then
            print(string.format(
                "ASAI_RECOVERY turn=%d player=%d pillar=%s score=%.3f active=%s",
                turn,
                playerID,
                string.lower(pillar),
                state.Scores[pillar],
                tostring(state.Recovery[pillar])
            ));
        end
    end
    return state;
end

local function IsRelativeCatchup(playerID, threshold)
    return GetRelativeState(playerID).Band == RELATIVE_CATCHUP;
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
    return GetRelativeState(playerID).Band == RELATIVE_CONSOLIDATE;
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

local function WriteMetrics(playerID, firstTimeThisTurn)
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
    local relativeState = GetRelativeState(playerID);
    local infrastructureTarget = GetInfrastructureTarget(snapshot);
    print(string.format(
        "ASAI_METRIC turn=%d player=%d cities=%d pop=%d owned=%d improved=%d infratarget=%d builders=%d traders=%d capacity=%d gold=%.1f netgold=%.1f science=%.1f culture=%.1f techs=%d civics=%d military=%d wars=%d era=%d relative=%.3f science_ratio=%.3f culture_ratio=%.3f empire_ratio=%.3f military_ratio=%.3f pacing=%s recover_science=%s recover_culture=%s recover_empire=%s",
        snapshot.Turn,
        playerID,
        snapshot.Cities,
        snapshot.Population,
        snapshot.OwnedPlots,
        snapshot.Improvements,
        infrastructureTarget,
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
        relativeState.Scores.Overall,
        relativeState.Scores.Science,
        relativeState.Scores.Culture,
        relativeState.Scores.Empire,
        relativeState.Scores.Military,
        GetBandName(relativeState.Band),
        tostring(relativeState.Recovery.Science),
        tostring(relativeState.Recovery.Culture),
        tostring(relativeState.Recovery.Empire)
    ));
end

local function LogMetrics(playerID, firstTimeThisTurn)
    local success, metricError = pcall(WriteMetrics, playerID, firstTimeThisTurn);
    if not success and m_ConditionErrors.ASAI_LogMetrics == nil then
        print(string.format(
            "ASAI_ERROR condition=ASAI_LogMetrics player=%s fallback=skip error=%s",
            tostring(playerID),
            tostring(metricError)
        ));
        m_ConditionErrors.ASAI_LogMetrics = true;
    end
end
Events.PlayerTurnActivated.Add(LogMetrics);
