print("Adaptive Strategic AI " .. tostring(GlobalParameters.ASAI_VERSION) .. " loaded");

local m_Snapshots = {};

local function GetNumberParameter(name, fallback)
    local value = tonumber(GlobalParameters[name]);
    if value == nil then
        return fallback;
    end
    return value;
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
        ActiveRoutes = trade:GetNumOutgoingRoutes(),
        RouteCapacity = trade:GetOutgoingRouteCapacity(),
        GoldBalance = treasury:GetGoldBalance(),
        NetGold = treasury:GetGoldYield() - treasury:GetTotalMaintenance(),
        Wars = CountWars(playerID, player),
        Era = player:GetEra()
    };
    m_Snapshots[playerID] = snapshot;
    return snapshot;
end

function ASAI_IsInfrastructureRecovery(playerID, threshold)
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
GameEvents.ASAI_IsInfrastructureRecovery.Add(ASAI_IsInfrastructureRecovery);

function ASAI_IsTradeRecovery(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    local snapshot = GetSnapshot(playerID);
    -- Active routes still own trader units, so total trader units already
    -- includes both assigned and idle traders and prevents queue overshoot.
    return snapshot.RouteCapacity > snapshot.Traders;
end
GameEvents.ASAI_IsTradeRecovery.Add(ASAI_IsTradeRecovery);

function ASAI_IsGoldRecovery(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    local snapshot = GetSnapshot(playerID);
    local reservePerCity = GetNumberParameter("ASAI_GOLD_RESERVE_PER_CITY", 15);
    return snapshot.NetGold < 0 and snapshot.GoldBalance < snapshot.Cities * reservePerCity;
end
GameEvents.ASAI_IsGoldRecovery.Add(ASAI_IsGoldRecovery);

function ASAI_IsWarMobilization(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    return GetSnapshot(playerID).Wars > 0;
end
GameEvents.ASAI_IsWarMobilization.Add(ASAI_IsWarMobilization);

function ASAI_IsLateGame(playerID, threshold)
    if not IsMajorAI(playerID) then
        return false;
    end
    local modern = GameInfo.Eras["ERA_MODERN"];
    return modern ~= nil and GetSnapshot(playerID).Era >= modern.Index;
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

    local player = Players[playerID];
    local techs, civics = CountResearched(player);
    local science = player:GetTechs():GetScienceYield();
    local culture = player:GetCulture():GetCultureYield();
    local military = player:GetStats():GetMilitaryStrengthWithoutTreasury();
    print(string.format(
        "ASAI_METRIC turn=%d player=%d cities=%d pop=%d improved=%d builders=%d routes=%d/%d gold=%.1f netgold=%.1f science=%.1f culture=%.1f techs=%d civics=%d military=%d wars=%d era=%d",
        snapshot.Turn,
        playerID,
        snapshot.Cities,
        snapshot.Population,
        snapshot.Improvements,
        snapshot.Builders,
        snapshot.ActiveRoutes,
        snapshot.RouteCapacity,
        snapshot.GoldBalance,
        snapshot.NetGold,
        science,
        culture,
        techs,
        civics,
        military,
        snapshot.Wars,
        snapshot.Era
    ));
end
Events.PlayerTurnActivated.Add(LogMetrics);
