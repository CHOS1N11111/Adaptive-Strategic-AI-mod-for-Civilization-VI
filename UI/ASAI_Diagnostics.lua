-- Read-only UI telemetry. These APIs belong to UI, not Gameplay. Nothing in
-- this context writes properties, issues orders, or feeds the AI controller.
local pending = {};
local lastSample = {};
local completions = {};
local unavailable = {};
local errors = {};
local routeRechecks = {};
local capabilitiesLogged = false;

local function Parameter(name, fallback)
    return tonumber(GlobalParameters[name]) or fallback;
end

local function ScaleTurns(value)
    local info = GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()];
    local multiplier = info ~= nil and tonumber(info.CostMultiplier) or 100;
    if multiplier <= 0 then multiplier = 100; end
    return math.max(1, math.floor(value * multiplier / 100 + 0.5));
end

local function MajorAI(playerID)
    local player = Players[playerID];
    return player ~= nil and player:IsAlive() and player:IsMajor() and not player:IsHuman();
end

local function TrySensor(name, collector)
    if unavailable[name] then return nil, 0; end
    local success, value = pcall(collector);
    if success then return value, 1; end
    if errors[name] == nil then
        print("ASAI_UI_DIAGNOSTIC_ERROR sensor=" .. name
            .. " fallback=unknown error=" .. tostring(value));
        errors[name] = true;
    end
    -- Missing capability is permanent for this context; transient city/turn
    -- errors may recover on the next sample and must not poison every AI.
    unavailable[name] = string.find(tostring(value), "UNAVAILABLE:", 1, true) ~= nil;
    return nil, 0;
end

local function TradeRoutes(player)
    local result = { Active = 0, Domestic = 0, International = 0, Unknown = 0,
        Idle = 0, LinksOk = 1, EngineTotal = -1 };
    local traders = {};
    for _, city in player:GetCities():Members() do
        if city.GetTrade == nil then error("UNAVAILABLE: UI City:GetTrade"); end
        local trade = city:GetTrade();
        if trade == nil or trade.GetOutgoingRoutes == nil then
            error("UNAVAILABLE: UI CityTrade:GetOutgoingRoutes");
        end
        local routes = trade:GetOutgoingRoutes();
        if type(routes) ~= "table" then error("UI route table missing"); end
        for _, route in ipairs(routes) do
            result.Active = result.Active + 1;
            if route.DestinationCityPlayer == player:GetID() then
                result.Domestic = result.Domestic + 1;
            elseif route.DestinationCityPlayer == nil or route.DestinationCityPlayer < 0 then
                result.Unknown = result.Unknown + 1;
            else
                result.International = result.International + 1;
            end
            if route.TraderUnitID ~= nil and route.TraderUnitID >= 0 then
                traders[route.TraderUnitID] = true;
            else
                result.LinksOk = 0;
            end
        end
    end
    if result.LinksOk == 1 then
        for _, unit in player:GetUnits():Members() do
            local info = GameInfo.Units[unit:GetType()];
            if info ~= nil and info.MakeTradeRoute and not traders[unit:GetID()] then
                result.Idle = result.Idle + 1;
            end
        end
    else
        result.Idle = -1;
    end
    local trade = player:GetTrade();
    if trade ~= nil and trade.GetNumOutgoingRoutes ~= nil then
        result.EngineTotal = trade:GetNumOutgoingRoutes();
    end
    return result;
end

local function CulturalPoints(player)
    if player.GetGreatPeoplePoints == nil then error("UNAVAILABLE: UI GreatPeoplePoints"); end
    local points = player:GetGreatPeoplePoints();
    if points == nil or points.GetPointsPerTurn == nil or points.GetPointsTotal == nil then
        error("UNAVAILABLE: UI cultural point methods");
    end
    local result = { PerTurn = 0, Total = 0 };
    for _, classType in ipairs({ "GREAT_PERSON_CLASS_WRITER",
            "GREAT_PERSON_CLASS_ARTIST", "GREAT_PERSON_CLASS_MUSICIAN" }) do
        local info = GameInfo.GreatPersonClasses[classType];
        if info ~= nil then
            result.PerTurn = result.PerTurn + points:GetPointsPerTurn(info.Index);
            result.Total = result.Total + points:GetPointsTotal(info.Index);
        end
    end
    return result;
end

local function CurrentItem(city)
    local queue = city:GetBuildQueue();
    if not capabilitiesLogged and queue ~= nil then
        print(string.format(
            "ASAI_UI_CAPABILITIES current_hash=%d can_produce=%d current_api=GetCurrentProductionTypeHash",
            queue.GetCurrentProductionTypeHash ~= nil and 1 or 0,
            queue.CanProduce ~= nil and 1 or 0));
        capabilitiesLogged = true;
    end
    if queue == nil or queue.GetCurrentProductionTypeHash == nil then
        error("UNAVAILABLE: UI BuildQueue:GetCurrentProductionTypeHash");
    end
    local item = queue:GetCurrentProductionTypeHash();
    if item == nil or item == "" or item == "NONE" or item == 0 or item == -1 then
        return "none";
    end
    for _, tableName in ipairs({ "Units", "Buildings", "Districts", "Projects" }) do
        local info = GameInfo[tableName][item];
        if info ~= nil then
            return info.UnitType or info.BuildingType or info.DistrictType or info.ProjectType;
        end
    end
    return tostring(item):gsub("%s", "_");
end

local function RoutesConsistent(routes, ok)
    if ok ~= 1 or routes.EngineTotal < 0 then return -1; end
    return routes.Active == routes.EngineTotal and 1 or 0;
end

local function WriteSample(playerID, sampleTurn)
    local player = Players[playerID];
    local observedTurn = Game.GetCurrentGameTurn();
    local evaluatedTurn = tonumber(player:GetProperty("ASAI_RELATIVE_LAST_EVAL_TURN")) or -1;
    local routes, routeOk = TrySensor("trade_routes", function() return TradeRoutes(player); end);
    routes = routes or { Active = -1, Domestic = -1, International = -1,
        Unknown = -1, Idle = -1, LinksOk = 0, EngineTotal = -1 };
    local consistent = RoutesConsistent(routes, routeOk);
    print(string.format(
        "ASAI_UI_TRADE turn=%d observed_turn=%d evaluated_turn=%d player=%d phase=ui_after_publish active_routes=%d domestic_routes=%d international_routes=%d unknown_routes=%d idle_traders=%d trader_links_ok=%d engine_total=%d route_sensor_ok=%d route_consistent=%d consensus_routes=%d",
        sampleTurn, observedTurn, evaluatedTurn, playerID, routes.Active,
        routes.Domestic, routes.International, routes.Unknown, routes.Idle,
        routes.LinksOk, routes.EngineTotal, routeOk, consistent,
        consistent == 1 and routes.Active or -1));
    if consistent == 0 then
        routeRechecks[playerID] = { Turn = observedTurn, Active = routes.Active,
            Total = routes.EngineTotal };
    end
    local points, pointsOk = TrySensor("culture_great_people", function() return CulturalPoints(player); end);
    points = points or { PerTurn = -1, Total = -1 };
    print(string.format(
        "ASAI_UI_CULTURE turn=%d observed_turn=%d evaluated_turn=%d player=%d phase=ui_after_publish cultural_gpp_per_turn=%.1f cultural_gpp_balance=%.1f gpp_sensor_ok=%d",
        sampleTurn, observedTurn, evaluatedTurn, playerID, points.PerTurn, points.Total, pointsOk));
    TrySensor("city_queues", function()
        for _, city in player:GetCities():Members() do
            local key = tostring(playerID) .. ":" .. tostring(city:GetID());
            local completed = completions[key] or { Turn = -1, Count = 0 };
            print(string.format(
                "ASAI_UI_CITY_QUEUE turn=%d observed_turn=%d player=%d city=%d x=%d y=%d phase=ui_after_publish current=%s last_completion_turn=%d completions_since_sample=%d",
                sampleTurn, observedTurn, playerID, city:GetID(), city:GetX(), city:GetY(),
                CurrentItem(city), completed.Turn, completed.Count));
            completed.Count = 0;
            completions[key] = completed;
        end
        return true;
    end);
end

local function OnTurnDeactivated(playerID)
    if Parameter("ASAI_ENABLE_METRICS", 0) ~= 1 or not MajorAI(playerID) then return; end
    local turn = Game.GetCurrentGameTurn();
    local first = ScaleTurns(Parameter("ASAI_RELATIVE_START_TURN_STANDARD", 35));
    local interval = ScaleTurns(Parameter("ASAI_RELATIVE_CHECK_INTERVAL_STANDARD", 4));
    if turn < first or (lastSample[playerID] ~= nil and turn - lastSample[playerID] < interval) then return; end
    pending[playerID] = turn;
end

local function OnPublishComplete()
    -- At most one retry, on a later publish event. Retain both original
    -- readings; a reread on another turn is never backfilled into this turn.
    for playerID, previous in pairs(routeRechecks) do
        routeRechecks[playerID] = nil;
        if MajorAI(playerID) then
            local routes, ok = TrySensor("trade_routes", function()
                return TradeRoutes(Players[playerID]);
            end);
            local turn = Game.GetCurrentGameTurn();
            local consistent = routes ~= nil and RoutesConsistent(routes, ok) or -1;
            print(string.format(
                "ASAI_UI_TRADE_RECHECK turn=%d observed_turn=%d player=%d original_active=%d original_engine_total=%d active_routes=%d engine_total=%d route_consistent=%d same_turn=%d consensus_routes=%d",
                previous.Turn, turn, playerID, previous.Active, previous.Total,
                routes ~= nil and routes.Active or -1, routes ~= nil and routes.EngineTotal or -1,
                consistent, turn == previous.Turn and 1 or 0,
                turn == previous.Turn and consistent == 1 and routes.Active or -1));
        end
    end
    for playerID, turn in pairs(pending) do
        pending[playerID] = nil;
        if MajorAI(playerID) then
            local success, value = pcall(WriteSample, playerID, turn);
            if not success and errors.sample == nil then
                print("ASAI_UI_DIAGNOSTIC_ERROR sensor=sample fallback=skip error=" .. tostring(value));
                errors.sample = true;
            end
            lastSample[playerID] = turn;
        end
    end
end

local function OnProductionCompleted(playerID, cityID)
    if Parameter("ASAI_ENABLE_METRICS", 0) ~= 1 or not MajorAI(playerID) then return; end
    local key = tostring(playerID) .. ":" .. tostring(cityID);
    local completed = completions[key] or { Turn = -1, Count = 0 };
    completed.Turn = Game.GetCurrentGameTurn();
    completed.Count = completed.Count + 1;
    completions[key] = completed;
end

Events.PlayerTurnDeactivated.Add(OnTurnDeactivated);
Events.GameCoreEventPublishComplete.Add(OnPublishComplete);
Events.CityProductionCompleted.Add(OnProductionCompleted);
ContextPtr:SetShutdown(function()
    Events.PlayerTurnDeactivated.Remove(OnTurnDeactivated);
    Events.GameCoreEventPublishComplete.Remove(OnPublishComplete);
    Events.CityProductionCompleted.Remove(OnProductionCompleted);
end);
print("ASAI_UI_DIAGNOSTICS loaded source=ui read_only=1");
