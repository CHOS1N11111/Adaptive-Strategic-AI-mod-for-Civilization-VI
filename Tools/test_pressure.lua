-- Real pressure-controller functions with a deterministic game boundary.
-- Paths are engine responses, not a replacement pathfinder or scripted orders.
return function(check, equal, upvalue)
    local function events()
        return setmetatable({}, { __index = function(self, key)
            local event = { Callbacks = {} };
            event.Add = function(fn) table.insert(event.Callbacks, fn); end;
            rawset(self, key, event);
            return event;
        end });
    end
    local function members(items)
        return { Members = function() return ipairs(items); end };
    end
    local function distance(x1, y1, x2, y2)
        local x, y = x2 - x1, y2 - y1;
        return (math.abs(x) + math.abs(y) + math.abs(x + y)) / 2;
    end
    local now, properties, logs = 60, {}, {};
    local plots, byIndex, hidden, cities, units, met, allowed, alive, armies;
    local pathCalls, pathMode, allWater, coastal, impassable, foreignStaging, diplomacyUnknown;
    local function plot(x, y)
        local key = x .. ":" .. y;
        if plots[key] == nil then
            local index = (x + 100) * 1000 + y + 100;
            local p = { X = x, Y = y, Index = index, Owner = -1 };
            p.GetX = function() return p.X; end;
            p.GetY = function() return p.Y; end;
            p.GetIndex = function() return p.Index; end;
            p.GetOwner = function()
                if p.Owner == -1 and foreignStaging then return 9; end
                return p.Owner;
            end;
            p.IsCoastalLand = function() return coastal; end;
            p.IsWater = function() return allWater and p.Owner == -1; end;
            p.IsImpassable = function() return impassable and p.Owner == -1; end;
            plots[key], byIndex[index] = p, p;
        end
        return plots[key];
    end
    local function city(owner, x, y)
        plot(x, y).Owner = owner;
        return { GetX = function() return x; end, GetY = function() return y; end };
    end
    local function unit(id, x, y, kind)
        local u = { ID = id, X = x, Y = y, Kind = kind or "LAND" };
        u.GetID = function() return u.ID; end;
        u.GetX = function() return u.X; end;
        u.GetY = function() return u.Y; end;
        u.GetType = function() return u.Kind; end;
        return u;
    end
    local diplomacy = {
        HasMet = function(_, id) return met[id] == true; end,
        IsAtWarWith = function() return false; end,
        CanDeclareWarOn = function(_, id)
            if diplomacyUnknown then error("diplomacy unavailable"); end
            return allowed[id];
        end,
        DeclareWarOn = function() error("no declaration is authorized"); end
    };
    local player = {
        GetID = function() return 1; end,
        IsMajor = function() return true; end, IsHuman = function() return false; end,
        GetProperty = function(_, key) return properties[key], "metadata"; end,
        SetProperty = function(_, key, value) properties[key] = value; end,
        GetCities = function() return members(cities[1]); end,
        GetUnits = function() return members(units); end,
        GetDiplomacy = function() return diplomacy; end,
        GetAi_Military = function() error("do not assume a native-operation reader"); end
    };
    local env = setmetatable({
        print = function(message) table.insert(logs, tostring(message)); end,
        Game = { GetCurrentGameTurn = function() return now; end },
        GlobalParameters = { ASAI_VERSION = "test", ASAI_ENABLE_METRICS = 1 },
        GameConfiguration = { GetGameSpeedType = function() return "ONLINE"; end },
        GameInfo = {
            GameSpeeds = { ONLINE = { CostMultiplier = 50 } },
            Eras = { ERA_CLASSICAL = { Index = 1 }, ERA_INDUSTRIAL = { Index = 4 },
                ERA_MODERN = { Index = 5 } }, Technologies = {},
            Units = {
                LAND = { Domain = "DOMAIN_LAND", Combat = 40 },
                SEA = { Domain = "DOMAIN_SEA", Combat = 45 },
                AIR = { Domain = "DOMAIN_AIR", Combat = 0, RangedCombat = 90 },
                CIVILIAN = { Domain = "DOMAIN_LAND", Combat = 0 }
            }
        },
        Players = { [1] = player }, PlayerConfigurations = {},
        PlayerManager = {
            GetAliveMajorIDs = function() return { 0, 1, 2, 3 }; end,
            IsAlive = function(id) return alive[id] == true; end
        },
        PlayersVisibility = { [1] = { IsRevealed = function(_, x, y)
            return not hidden[x .. ":" .. y];
        end } },
        Map = {
            GetPlotDistance = distance, GetPlot = plot,
            GetPlotByIndex = function(index) return byIndex[index]; end,
            GetPlotXYWithRangeCheck = function(x, y, dx, dy, range)
                if distance(x, y, x + dx, y + dy) <= range then return plot(x + dx, y + dy); end
            end,
            GetPlotCount = function() error("full-map scans are outside this feature"); end
        },
        UnitManager = {
            GetMoveToPath = function(u, target)
                pathCalls = pathCalls + 1;
                if pathMode == "error" then error("native path API unavailable"); end
                if pathMode == "none" then return {}; end
                if pathMode == "partial" then return { plot(u.X, u.Y):GetIndex() }; end
                if pathMode == "unknown" then return nil; end
                return { plot(u.X, u.Y):GetIndex(), target };
            end,
            RequestOperation = function() error("no unit order is authorized"); end
        },
        GameEvents = events(), Events = events()
    }, { __index = _G });
    env._G = env;
    for _, id in ipairs({ 0, 2, 3 }) do
        env.Players[id] = {
            GetCities = function() return members(cities[id]); end,
            IsMajor = function() return true; end,
            IsHuman = function() return id == 0; end
        };
    end
    assert(loadfile("Lua/AdaptiveStrategicAI.lua", "t", env))();
    local S = upvalue(env.GameEvents.CityBuilt.Callbacks[1], "Strategic");
    local evaluate = upvalue(upvalue(S.IsDevelopmentPlan, "GetRelativeState"), "EvaluateRelativeState");
    local neutral = upvalue(evaluate, "GetNeutralRelativeState");
    local read, store = upvalue(evaluate, "ReadRelativeState"), upvalue(evaluate, "StoreRelativeState");
    upvalue(S.PressureCandidates, "GetStrengthSnapshot", function(id) return { Military = armies[id] }; end);
    local function reset()
        plots, byIndex, hidden, properties = {}, {}, {}, {};
        cities = { [1] = { city(1, 0, 0) }, [0] = { city(0, 8, 0) },
            [2] = { city(2, 9, 1) }, [3] = { city(3, 7, 3) } };
        units = { unit(1, -5, 0), unit(2, -6, 0), unit(3, -7, 0) };
        met, allowed, alive = { [0] = true }, { [0] = true, [2] = true, [3] = true },
            { [0] = true, [1] = true, [2] = true, [3] = true };
        armies = { [0] = 300, [1] = 600, [2] = 350, [3] = 250 };
        pathCalls, pathMode, allWater, coastal, impassable = 0, "good", false, false, false;
        foreignStaging, diplomacyUnknown = false, false;
        env.GlobalParameters.ASAI_PRESSURE_TARGET_MIN_RATIO_X100 = nil;
        local state = neutral();
        state.MilitaryDominance = 1;
        state.MilitaryUnitsPerPlannedCity = 3;
        state.RawScores = { Overall = 1, Science = 1, Culture = 1, Empire = 1, Military = 1.6 };
        state.CompetitiveScores, state.WorldUpperScores, state.Scores =
            state.RawScores, state.RawScores, state.RawScores;
        local snapshot = { Turn = 60, PlayerID = 1, Cities = 6, Settlers = 0,
            CapturedCities = 0, FoundedEvents = 6, LastFoundedTurn = 40, Era = 3,
            ActiveMajorWars = 0, MajorWars = 0, MajorOpponents = {}, OwnedPlots = 70,
            MajorCombatEvents = 0, MajorCaptureEvents = 0, MajorPillageEvents = 0 };
        local strength = { Military = 600, CombatUnits = 12, LandUnits = 10 };
        return state, snapshot, strength;
    end
    local state, snapshot, strength = reset();
    S.UpdatePressure(1, state, snapshot, strength, 60);
    check(state.Pressure.Eligible == 1 and state.Pressure.TargetID == 0,
        "known legal nearby major with a verified staging path is eligible");
    check(state.Pressure.RallyPlot >= 0 and state.Pressure.Distance == 8,
        "candidate includes a concrete city and deployment plot");
    check(pathCalls > 0 and pathCalls <= 4, "normal candidate uses bounded native path probes");
    check(S.GetPlanScores(state, snapshot, 60)[S.PRESSURE] > 0,
        "eligible target permits the existing pressure scoring curve");
    check(logs[#logs]:find("native_operation=unverified assignment=advisory path_scope=staging", 1, true) ~= nil,
        "diagnostic does not claim native adoption or complete invasion reachability");
    local firstCalls, firstRally = pathCalls, state.Pressure.RallyPlot;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    equal(pathCalls, firstCalls, "same-turn callbacks do not repeat path queries");
    store(player, state);
    state = read(player);
    equal(state.Pressure.RallyPlot, firstRally, "staging choice survives reload");
    S.UpdatePressure(1, state, snapshot, strength, 60);
    equal(pathCalls, firstCalls, "same-turn reload preserves the sampled path budget");
    state.StrategicPlan = S.PRESSURE;
    S.UpdatePressure(1, state, snapshot, strength, 62);
    check(pathCalls > firstCalls, "later decision refreshes feasibility instead of trusting old paths forever");

    state, snapshot, strength = reset();
    state.MilitaryDominance, state.RawScores.Military = 0, 1;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    check(state.Pressure.Reason == "not_ready" and pathCalls == 0 and state.Pressure.PlotChecks == 0,
        "no military advantage means no extra target or path work");
    state, snapshot, strength = reset();
    state.StrategicPlanCooldownUntil[S.PRESSURE] = 70;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    check(state.Pressure.Reason == "plan_cooldown" and pathCalls == 0,
        "global pressure cooldown avoids unnecessary path work");

    state, snapshot, strength = reset();
    met = {};
    S.UpdatePressure(1, state, snapshot, strength, 60);
    check(state.Pressure.Eligible == 0 and pathCalls == 0,
        "unmet civilizations cannot become pressure targets");
    equal(S.GetPlanScores(state, snapshot, 60)[S.PRESSURE], 0,
        "military dominance alone cannot bypass missing targets");
    state.StrategicPlan, state.StrategicPlanChangedTurn = S.PRESSURE, 60;
    local selected, reason = S.SelectPlan(state, snapshot, S.GetPlanScores(state, snapshot, 60));
    check(selected ~= S.PRESSURE and reason == "pressure_target_unavailable",
        "lost target requests immediate exit even when minimum dwell has just started");
    snapshot.ActiveMajorWars = 1;
    selected, reason = S.SelectPlan(state, snapshot, S.GetPlanScores(state, snapshot, 60));
    check(selected == S.WAR and reason == "active_major_war",
        "target gate does not suppress the existing actual-war override");

    state, snapshot, strength = reset();
    allowed[0] = false;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    check(state.Pressure.Eligible == 0 and pathCalls == 0,
        "native diplomatic prohibition excludes protected or unavailable opponents");
    state, snapshot, strength = reset();
    diplomacyUnknown = true;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    check(state.Pressure.Eligible == 0 and state.Pressure.Reason == "diplomacy_unknown",
        "unavailable diplomatic permission stays unknown, not allowed");
    state, snapshot, strength = reset();
    allowed[0] = nil;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    equal(state.Pressure.Reason, "diplomacy_unknown", "non-boolean permission is not silently accepted");
    state, snapshot, strength = reset();
    alive[0] = false;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    equal(state.Pressure.Eligible, 0, "dead target is excluded even from a stale major-player listing");
    state, snapshot, strength = reset();
    hidden["8:0"] = true;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    check(state.Pressure.Eligible == 0 and pathCalls == 0, "unrevealed city is not a known target");
    state, snapshot, strength = reset();
    armies[0] = 1000;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    equal(state.Pressure.Eligible, 0, "overall advantage does not justify targeting an overwhelmingly stronger opponent");
    state, snapshot, strength = reset();
    armies[0], strength.Military = 600, 540;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    equal(state.Pressure.Eligible, 1, "exact target-relative minimum boundary qualifies");
    state, snapshot, strength = reset();
    cities[0] = { city(0, 13, 0) };
    S.UpdatePressure(1, state, snapshot, strength, 60);
    equal(state.Pressure.Eligible, 0, "distant city is outside the bounded pressure opportunity radius");
    state, snapshot, strength = reset();
    plot(8, 0).Owner = 2;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    equal(state.Pressure.Eligible, 0, "changed city ownership invalidates a stale target");
    state, snapshot, strength = reset();
    cities[1] = {};
    S.UpdatePressure(1, state, snapshot, strength, 60);
    equal(state.Pressure.Reason, "no_anchor", "no own city means no geographical pressure anchor");

    state, snapshot, strength = reset();
    units = { unit(1, -5, 0, "CIVILIAN"), unit(2, -6, 0, "AIR") };
    S.UpdatePressure(1, state, snapshot, strength, 60);
    check(state.Pressure.Eligible == 0 and pathCalls == 0,
        "civilian and air-only forces cannot certify surface deployment");
    state, snapshot, strength = reset();
    foreignStaging = true;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    equal(state.Pressure.Eligible, 0, "third-party territory is not appropriated as a staging point");
    state, snapshot, strength = reset();
    impassable = true;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    equal(state.Pressure.Eligible, 0, "impassable staging plots are rejected before native path queries");
    state, snapshot, strength = reset();
    units = { unit(1, -5, 0, "SEA"), unit(2, -6, 0, "SEA") };
    allWater, coastal = true, true;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    check(state.Pressure.Eligible == 1 and byIndex[state.Pressure.RallyPlot]:IsWater(),
        "naval force may establish reachable water deployment near a coastal target");
    state, snapshot, strength = reset();
    units, allWater = { unit(1, -5, 0, "SEA") }, true;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    equal(state.Pressure.Eligible, 0, "naval force does not certify an inland city approach");

    for _, mode in ipairs({ "none", "partial", "unknown", "error" }) do
        state, snapshot, strength = reset();
        pathMode = mode;
        S.UpdatePressure(1, state, snapshot, strength, 60);
        check(state.Pressure.Eligible == 0 and pathCalls <= 4,
            mode .. " engine path does not become a reachability claim");
    end
    state, snapshot, strength = reset();
    hidden["-5:0"], hidden["-6:0"], hidden["-7:0"] = true, true, true;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    equal(state.Pressure.Reason, "path_not_revealed", "unrevealed path nodes cannot justify target feasibility");
    state, snapshot, strength = reset();
    met[2], met[3], pathMode = true, true, "none";
    S.UpdatePressure(1, state, snapshot, strength, 60);
    check(pathCalls == 4 and state.Pressure.PathChecks == 4,
        "three candidates share a hard four-query native path budget");
    check(state.Pressure.PlotChecks <= 183, "three local radius-four disks do not become a full-map scan");
    equal(state.Pressure.Reason, "path_budget", "budget exhaustion is not mislabeled permanent unreachability");
    state, snapshot, strength = reset();
    for id = 4, 30 do table.insert(units, unit(id, -id, 0)); end
    equal(#S.PressureUnits(player, { X = 8, Y = 0 }), 8, "large armies use only eight nearby deployment probes");
    local pair = { Unit = { Unit = units[1], ID = 1, X = 2, Y = 0 },
        X = 2, Y = 0, Plot = plot(2, 0):GetIndex() };
    local reachable, pathReason = S.VerifyPressurePath(1, pair);
    check(reachable and pathReason == "at_staging" and pathCalls == 0,
        "observed presence already at staging needs no pathfinder call");
    pair.Unit.X = -5;
    local nativePath = env.UnitManager.GetMoveToPath;
    env.UnitManager.GetMoveToPath = function()
        local path = {};
        for _ = 1, 25 do table.insert(path, pair.Plot); end
        return path;
    end;
    reachable, pathReason = S.VerifyPressurePath(1, pair);
    check(not reachable and pathReason == "path_horizon", "paths outside the node horizon remain unverified");
    env.UnitManager.GetMoveToPath = nativePath;

    state, snapshot, strength = reset();
    S.UpdatePressure(1, state, snapshot, strength, 60);
    local targetPlot, rallyPlot = state.Pressure.CityPlot, state.Pressure.RallyPlot;
    state.StrategicPlan = S.PRESSURE;
    S.StartPlanReview(state, snapshot, strength, 60);
    cities[2], met[2] = { city(2, 3, 0) }, true;
    S.UpdatePressure(1, state, snapshot, strength, 62);
    check(state.Pressure.TargetID == 0 and state.Pressure.CityPlot == targetPlot
        and state.Pressure.RallyPlot == rallyPlot,
        "still-feasible existing target and staging are retained despite a closer new candidate");
    equal(state.StrategicPlanReviewTurn, 60, "refreshing target feasibility does not postpone the primary review");
    local pathBeforeRetarget = env.UnitManager.GetMoveToPath;
    env.UnitManager.GetMoveToPath = function(u, target)
        if target == rallyPlot then pathCalls = pathCalls + 1; return {}; end
        return pathBeforeRetarget(u, target);
    end;
    S.UpdatePressure(1, state, snapshot, strength, 64);
    equal(state.Pressure.TargetID, 2, "an infeasible old staging route can hand off to a verified alternative");
    local preparation, advanced, preparationReason = S.PressurePreparation(state);
    check(not preparation and preparationReason == "target_changed",
        "changing the target cannot manufacture deployment progress");
    equal(state.StrategicPlanReviewTurn, 60, "retargeting cannot reset the primary review clock");
    env.UnitManager.GetMoveToPath = pathBeforeRetarget;

    local function preparing()
        local s, x, army = reset();
        s.StrategicPlan = S.PRESSURE;
        s.Pressure.Eligible, s.Pressure.TargetID = 1, 0;
        s.Pressure.CityPlot, s.Pressure.RallyPlot = plot(8, 0):GetIndex(), plot(4, 0):GetIndex();
        s.Pressure.Units = "1:12,2:12,3:15";
        S.StartPlanReview(s, x, army, 60);
        return s, x, army;
    end
    state, snapshot, strength = preparing();
    state.Pressure.Units = "1:10,2:10,3:15";
    preparation, advanced = S.PressurePreparation(state);
    check(preparation and advanced == 2, "two existing units approaching the same staging point are preparation");
    equal(S.GetPlanExecution(1, state, snapshot), 1, "peaceful observed preparation is execution, not unknown");
    state.Pressure.Units = "1:12,2:12,3:15,4:0,5:0";
    check(not S.PressurePreparation(state), "newly produced units alone cannot manufacture preparation");
    state.Pressure.Units = "1:10,2:12,3:15";
    check(not S.PressurePreparation(state), "one roaming unit does not represent a preparing force");
    state.Pressure.BaselineUnits, state.Pressure.Units = "1:3,2:3", "1:2,2:2";
    check(S.PressurePreparation(state), "two known units crossing into deployment range are recognized");
    state.Pressure.RallyPlot = state.Pressure.RallyPlot + 1;
    check(not S.PressurePreparation(state), "changing only staging also invalidates a distance comparison");
    state, snapshot, strength = preparing();
    state.Pressure.Eligible = 0;
    check(not S.PressurePreparation(state), "no valid target means no preparation credit");

    state, snapshot, strength = preparing();
    state.StrategicPlanStallCount = 1;
    state.Pressure.Units = "1:10,2:10,3:15";
    local retired = S.ReviewPlan(1, state, snapshot, strength, 66);
    check(not retired and state.StrategicPlanResult == 2 and state.StrategicPlanStallCount == 1
        and state.Pressure.PrepWindowsUsed == 1,
        "first real preparation window earns time without success or failure-history reset");
    S.ReviewPlan(1, state, snapshot, strength, 66);
    equal(state.Pressure.PrepWindowsUsed, 1, "same-turn review cannot consume or duplicate preparation credit");
    store(player, state);
    state = read(player);
    equal(state.Pressure.PrepWindowsUsed, 1, "used preparation budget survives reload");
    equal(state.Pressure.BaselineUnits, "1:10,2:10,3:15", "comparison units survive reload");
    state.Pressure.Units = "1:8,2:8,3:15";
    retired = S.ReviewPlan(1, state, snapshot, strength, 72);
    check(not retired and state.Pressure.PrepWindowsUsed == 2 and state.StrategicPlanStallCount == 1,
        "second real preparation window reaches the bounded grace cap");
    state.Pressure.Units = "1:6,2:6,3:15";
    retired = S.ReviewPlan(1, state, snapshot, strength, 78);
    check(retired and state.Pressure.PrepWindowsUsed == 2 and state.StrategicPlanStallCount == 2,
        "even continued preparation cannot postpone a fruitless plan forever");
    S.RecordPressureStop(player, state, 78);
    equal(properties.ASAI_PRESSURE_TARGET_COOLDOWN_0, 94, "failed opponent gets a speed-scaled bounded cooldown");
    check(S.PressureTargetCooling(player, 0, 93) and not S.PressureTargetCooling(player, 0, 94),
        "failed-target cooldown has an exact exit and does not ban the target permanently");
    properties.ASAI_PRESSURE_TARGET_COOLDOWN_0 = 100;
    S.RecordPressureStop(player, state, 78);
    equal(properties.ASAI_PRESSURE_TARGET_COOLDOWN_0, 100, "a later existing target cooldown is not shortened");
    check(string.find(logs[#logs], "target_cooldown_until=100", 1, true) ~= nil,
        "stop diagnostics report the actual retained cooldown");
    state.Pressure.TargetID = -1;
    S.RecordPressureStop(player, state, 90);
    equal(properties.ASAI_PRESSURE_TARGET_COOLDOWN_0, 106,
        "lost current target still cools the failed baseline opponent, not an arbitrary new one");
    state, snapshot, strength = preparing();
    state.StrategicPlanStallCount, state.Pressure.TargetID = 1, 2;
    retired = S.ReviewPlan(1, state, snapshot, strength, 66);
    check(retired and state.Pressure.BaselineTargetID == 0,
        "a failed review retains the opponent it actually evaluated after a fresh retarget");
    S.RecordPressureStop(player, state, 66);
    check(properties.ASAI_PRESSURE_TARGET_COOLDOWN_0 == 82
        and properties.ASAI_PRESSURE_TARGET_COOLDOWN_2 == nil,
        "retirement cools the reviewed opponent without punishing an untried replacement");
    state.Pressure.BaselineTargetID = -1;
    S.RecordPressureStop(player, state, 66);
    equal(properties.ASAI_PRESSURE_TARGET_COOLDOWN_2, 82,
        "a missing legacy baseline falls back to the known current opponent");
    state, snapshot, strength = preparing();
    state.StrategicPlanStallCount, state.Pressure.Units = 1, "1:10,2:10,3:15";
    snapshot.Cities = snapshot.Cities - 1;
    retired = S.ReviewPlan(1, state, snapshot, strength, 66);
    check(retired and state.Pressure.PrepWindowsUsed == 0, "own city loss vetoes extra preparation grace");
    state, snapshot, strength = preparing();
    state.Pressure.Units, strength.Military = "1:10,2:10", 400;
    S.ReviewPlan(1, state, snapshot, strength, 66);
    equal(state.Pressure.PrepWindowsUsed, 0, "serious own military loss vetoes extra preparation grace");
    state, snapshot, strength = preparing();
    S.ReviewPlan(1, state, snapshot, strength, 66);
    check(state.StrategicPlanStallCount == 1 and state.Pressure.PrepWindowsUsed == 0,
        "stationary staging forces do not renew the plan merely by existing");
    state, snapshot, strength = preparing();
    state.Pressure.PrepWindowsUsed, state.Pressure.TargetID = 2, 2;
    S.ResetPressureBaseline(state, false);
    equal(state.Pressure.PrepWindowsUsed, 2, "retarget/rebaseline preserves exhausted plan-level grace");
    S.StartPlanReview(state, snapshot, strength, 70);
    equal(state.Pressure.PrepWindowsUsed, 0, "a genuinely new primary plan gets its own bounded budget");
    state, snapshot, strength = preparing();
    state.Pressure.PrepWindowsUsed = 2;
    snapshot.Cities, snapshot.CapturedCities, snapshot.MajorCaptureEvents = 7, 1, 1;
    S.ReviewPlan(1, state, snapshot, strength, 66);
    check(state.StrategicPlanResult == 1 and state.StrategicPlanStallCount == 0,
        "real attributable war gains remain outcomes after preparation grace is exhausted");
    equal(state.Pressure.PrepWindowsUsed, 2, "actual outcome does not replenish preparation loopholes");
    check(string.find(logs[#logs], "reason=attributable_war_outcome", 1, true) ~= nil,
        "pressure review diagnostics distinguish actual outcomes from preparation");

    state, snapshot, strength = reset();
    met[2], properties.ASAI_PRESSURE_TARGET_COOLDOWN_0 = true, 76;
    S.UpdatePressure(1, state, snapshot, strength, 60);
    equal(state.Pressure.TargetID, 2, "cooling one failed opponent leaves other opponents eligible");
    state, snapshot, strength = preparing();
    state.StrategicPlanOutcomeSchema, state.Pressure.PrepWindowsUsed = 7, 2;
    S.MigratePlanOutcome(1, state, snapshot, strength, 64);
    check(state.StrategicPlanOutcomeSchema == 8 and state.StrategicPlanReviewTurn == 64
        and state.Pressure.PrepWindowsUsed == 0, "schema-seven PRESSURE migrates its new comparison contract once");
    S.MigratePlanOutcome(1, state, snapshot, strength, 66);
    equal(state.StrategicPlanReviewTurn, 64, "repeated migration cannot keep delaying the next review");
    for _, plan in ipairs({ S.DEVELOP, S.RECOVER, S.EXPAND, S.DEFEND, S.WAR }) do
        state, snapshot, strength = preparing();
        state.StrategicPlan, state.StrategicPlanOutcomeSchema = plan, 7;
        state.StrategicPlanStallCount = 2;
        S.MigratePlanOutcome(1, state, snapshot, strength, 64);
        check(state.StrategicPlanReviewTurn == 60 and state.StrategicPlanStallCount == 2,
            "schema-seven non-pressure plan " .. plan .. " keeps its existing review state");
    end
    properties = {};
    local restored = read(player);
    check(restored.Pressure.Eligible == 0 and restored.Pressure.Reason == "not_sampled",
        "legacy save without target evidence starts unverified rather than inventing a target");
    local dominance = upvalue(env.ASAI_IsMilitaryDominance, "IsMilitaryDominance");
    state = neutral();
    state.StrategicPlan = S.PRESSURE;
    upvalue(dominance, "GetRelativeState", function() return state; end);
    check(not dominance(1, 0), "pressure priority callback itself rejects missing eligibility");
    state.Pressure.Eligible = 1;
    check(dominance(1, 0), "pressure callback accepts a verified sampled target");
end;
