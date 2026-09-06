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

-- ProductionPanel.lua uses a typed unit request and a project/district hash.
-- A negative legality result is data, not an unavailable API.
local function ReadNumber(object, method, ...)
    if object == nil or object[method] == nil then return -1; end
    local ok, value = pcall(object[method], object, ...);
    return ok and tonumber(value) or -1;
end

local function ReadFlag(object, method, ...)
    if object == nil or object[method] == nil then return -1; end
    local ok, value = pcall(object[method], object, ...);
    if not ok or type(value) ~= "boolean" then return -1; end
    return value and 1 or 0;
end

local function Token(value)
    return tostring(value):gsub("%s", "_"):gsub("[=|]", "_"):sub(1, 160);
end

local function ProbeProduction(queue, row, kind)
    local result = { Can = -1, Visible = -1, Reason = "unknown_api",
        Cost = -1, Progress = -1, Turns = -1 };
    if queue == nil or row == nil or row.Hash == nil then return result; end
    local request = row.Hash;
    if kind == "Unit" then
        if MilitaryFormationTypes == nil
            or MilitaryFormationTypes.STANDARD_MILITARY_FORMATION == nil then return result; end
        request = { UnitType = row.Hash,
            MilitaryFormationType = MilitaryFormationTypes.STANDARD_MILITARY_FORMATION };
    end
    result.Cost = ReadNumber(queue, "Get" .. kind .. "Cost", row.Index);
    result.Progress = ReadNumber(queue, "Get" .. kind .. "Progress", row.Index);
    result.Turns = ReadNumber(queue, "GetTurnsLeft", row[kind .. "Type"]);
    if queue.CanProduce == nil then return result; end
    local ok, allowed, details = pcall(queue.CanProduce, queue, request, false, true);
    result.Visible = ReadFlag(queue, "CanProduce", request, true);
    if not ok or type(allowed) ~= "boolean" then
        result.Reason = "unknown_can_produce";
        return result;
    end
    result.Can, result.Reason = allowed and 1 or 0, allowed and "none" or "not_reported";
    local key = CityCommandResults ~= nil and CityCommandResults.FAILURE_REASONS or nil;
    local reasons = key ~= nil and type(details) == "table" and details[key] or nil;
    if not allowed and type(reasons) == "table" then
        local values = {};
        for i, reason in ipairs(reasons) do
            if i > 8 then table.insert(values, "more"); break; end
            table.insert(values, Token(reason));
        end
        if #values > 0 then result.Reason = table.concat(values, "|"); end
    end
    return result;
end

local laserRules;
local function LaserRules()
    if laserRules ~= nil then return laserRules; end
    local aluminum, power = -1, -1;
    pcall(function()
        local amount = 0;
        for row in GameInfo.Project_ResourceCosts() do
            if row.ProjectType == "PROJECT_ORBITAL_LASER"
                and row.ResourceType == "RESOURCE_ALUMINUM" then
                amount = amount + assert(tonumber(row.StartProductionCost));
            end
        end
        aluminum = amount;
    end);
    pcall(function()
        local ids, amount = {}, 0;
        for row in GameInfo.ProjectCompletionModifiers() do
            if row.ProjectType == "PROJECT_TERRESTRIAL_LASER" then
                local modifier = GameInfo.Modifiers[row.ModifierId];
                assert(modifier ~= nil);
                if modifier.ModifierType == "MODIFIER_SINGLE_CITY_ADJUST_REQUIRED_POWER" then
                    ids[row.ModifierId] = true;
                end
            end
        end
        for row in GameInfo.ModifierArguments() do
            if ids[row.ModifierId] and row.Name == "Amount" then
                amount = amount + assert(tonumber(row.Value));
                ids[row.ModifierId] = nil;
            end
        end
        assert(next(ids) == nil);
        power = amount;
    end);
    laserRules = { Aluminum = aluminum, Power = power };
    return laserRules;
end

local function PortStatus(city)
    local ok, district = pcall(function()
        return city:GetDistricts():GetDistrict("DISTRICT_SPACEPORT");
    end);
    if not ok then return -1, -1, -1; end
    if district == nil then return 0, 0, 0; end
    return 1, ReadFlag(district, "IsComplete"), ReadFlag(district, "IsPillaged");
end

local function WriteExecutionProbes(player, sampleTurn, observedTurn)
    local id = player:GetID();
    local trader = GameInfo.Units.UNIT_TRADER;
    local port = GameInfo.Districts.DISTRICT_SPACEPORT;
    -- Existing telemetry still works with missing DLC/type tables.
    if trader == nil and port == nil then return; end
    local capacity = ReadNumber(player:GetTrade(), "GetOutgoingRouteCapacity");
    local traders = 0;
    for _, unit in player:GetUnits():Members() do
        local info = GameInfo.Units[unit:GetType()];
        if info ~= nil and (info.MakeTradeRoute == true or info.MakeTradeRoute == 1) then
            traders = traders + 1;
        end
    end
    local demand = trader ~= nil and capacity >= 0 and capacity > traders;
    local stage = tonumber(player:GetProperty("ASAI_SCIENCE_EXECUTION_STAGE")) or -1;
    local techs = player.GetTechs ~= nil and player:GetTechs() or nil;
    local rocketry = GameInfo.Technologies ~= nil and GameInfo.Technologies.TECH_ROCKETRY or nil;
    local offworld = GameInfo.Technologies ~= nil and GameInfo.Technologies.TECH_OFFWORLD_MISSION or nil;
    local preparing = port ~= nil and stage <= 0 and rocketry ~= nil
        and ReadFlag(techs, "HasTech", rocketry.Index) == 1;
    local rule = (stage >= 3) and LaserRules() or nil;
    local aluminum = -1;
    local resource = GameInfo.Resources ~= nil and GameInfo.Resources.RESOURCE_ALUMINUM or nil;
    if rule ~= nil and resource ~= nil and player.GetResources ~= nil then
        aluminum = ReadNumber(player:GetResources(), "GetResourceAmount", resource.Index);
    end
    local pendingTraders, canTrade, unknownTrade = 0, 0, 0;
    for _, city in player:GetCities():Members() do
        local tradeObserved = false;
        -- One failing city never prevents the other cities being inspected.
        local ok = pcall(function()
            local queue = city:GetBuildQueue();
            local currentOk, current = pcall(CurrentItem, city);
            if not currentOk then current = "unknown"; end
            if trader ~= nil and current == trader.UnitType then pendingTraders = pendingTraders + 1; end
            if demand then
                local probe = ProbeProduction(queue, trader, "Unit");
                if probe.Can == 1 then canTrade = canTrade + 1;
                elseif probe.Can == -1 then unknownTrade = unknownTrade + 1; end
                tradeObserved = true;
                print(string.format(
                    "ASAI_UI_TRADER_CANDIDATE turn=%d observed_turn=%d player=%d city=%d unit=%s can_produce=%d visible=%d reasons=%s cost=%.1f progress=%.1f turns=%.1f current=%s source=ui native_demand=unverified",
                    sampleTurn, observedTurn, id, city:GetID(), trader.UnitType,
                    probe.Can, probe.Visible, probe.Reason, probe.Cost,
                    probe.Progress, probe.Turns, current));
            end
            if preparing then
                local probe = ProbeProduction(queue, port, "District");
                local production = YieldTypes ~= nil and ReadNumber(city, "GetYield", YieldTypes.PRODUCTION) or -1;
                print(string.format(
                    "ASAI_UI_PORT_CANDIDATE turn=%d observed_turn=%d player=%d city=%d can_produce=%d reasons=%s production=%.1f cost=%.1f progress=%.1f turns=%.1f current=%s nominated_city=%d nomination_turn=%d assignment=native plot=unverified",
                    sampleTurn, observedTurn, id, city:GetID(), probe.Can, probe.Reason,
                    production, probe.Cost, probe.Progress, probe.Turns, current,
                    tonumber(player:GetProperty("ASAI_SCIENCE_PORT_NOMINATION")) or -1,
                    tonumber(player:GetProperty("ASAI_SCIENCE_PORT_NOMINATION_TURN")) or -1));
            end
            if rule ~= nil and port ~= nil then
                local placed, complete, pillaged = PortStatus(city);
                if placed ~= 0 then
                    local power;
                    pcall(function() power = city:GetPower(); end);
                    local free = ReadNumber(power, "GetFreePower");
                    local temporary = ReadNumber(power, "GetTemporaryPower");
                    local required = ReadNumber(power, "GetRequiredPower");
                    local supplied = free >= 0 and temporary >= 0 and free + temporary or -1;
                    local margin = supplied >= 0 and required >= 0 and supplied - required or -1;
                    for _, name in ipairs({ "PROJECT_ORBITAL_LASER", "PROJECT_TERRESTRIAL_LASER" }) do
                        local row = GameInfo.Projects[name];
                        local probe = ProbeProduction(queue, row, "Project");
                        print(string.format(
                            "ASAI_UI_LASER_PREREQ turn=%d observed_turn=%d player=%d city=%d project=%s stage_property=%d offworld=%d port_placed=%d port_complete=%d port_pillaged=%d can_produce=%d visible=%d reasons=%s aluminum=%.1f orbital_aluminum_cost=%.1f power_supplied=%.1f power_required=%.1f fully_powered=%d observed_power_margin=%.1f terrestrial_extra_power=%.1f cost=%.1f progress=%.1f turns=%.1f current=%s project_count_property=%d coordination=%d coordination_turn=%d future_power=unverified source=ui",
                            sampleTurn, observedTurn, id, city:GetID(), name, stage,
                            offworld ~= nil and ReadFlag(techs, "HasTech", offworld.Index) or -1,
                            placed, complete, pillaged, probe.Can, probe.Visible, probe.Reason,
                            aluminum, rule.Aluminum, supplied, required, ReadFlag(power, "IsFullyPowered"),
                            margin, rule.Power, probe.Cost, probe.Progress, probe.Turns, current,
                            tonumber(player:GetProperty("ASAI_SCIENCE_PROJECT_COUNT_" .. name)) or -1,
                            tonumber(player:GetProperty("ASAI_SCIENCE_CAPACITY_ACTIVE")) or -1,
                            tonumber(player:GetProperty("ASAI_SCIENCE_CAPACITY_TURN")) or -1));
                    end
                end
            end
        end);
        if not ok then
            if demand and not tradeObserved then unknownTrade = unknownTrade + 1; end
            print(string.format(
                "ASAI_UI_DIAGNOSTIC_ERROR sensor=execution_city player=%d city=%d observed_turn=%d fallback=next_city",
                id, city:GetID(), observedTurn));
        end
    end
    if demand then
        print(string.format(
            "ASAI_UI_TRADER_DEMAND turn=%d observed_turn=%d player=%d capacity=%d traders=%d current_trader_queues=%d can_produce_cities=%d unknown_cities=%d gameplay_chain=%s gameplay_turn=%d demand_contract=unverified",
            sampleTurn, observedTurn, id, capacity, traders, pendingTraders,
            canTrade, unknownTrade, Token(player:GetProperty("ASAI_EXEC_TRADER_CHAIN") or "unknown"),
            tonumber(player:GetProperty("ASAI_EXEC_TRADER_CHAIN_TURN")) or -1));
    end
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
    TrySensor("execution_probes", function()
        WriteExecutionProbes(player, sampleTurn, observedTurn);
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
