-- Tests production Lua and its fail-closed boundaries. These are NOT an
-- emulation of the proprietary contract scheduler or proof of native orders.
return function(check, equal, upvalue)
    local now, props, logs, wars = 124, {}, {}, {};
    local function events()
        return setmetatable({}, { __index = function(t, key)
            local entry = { Callbacks = {} };
            entry.Add = function(fn) table.insert(entry.Callbacks, fn); end;
            rawset(t, key, entry); return entry;
        end });
    end
    local function members(list)
        return { Members = function() return ipairs(list); end,
            FindID = function(_, id) return list[id]; end };
    end
    local ownUnits, enemyUnits = {}, {
        { GetType = function() return "UNIT_MODERN_ARMOR"; end },
        { GetType = function() return "UNIT_INFANTRY"; end }
    };
    local player = {
        GetID = function() return 1; end,
        IsMajor = function() return true; end, IsHuman = function() return false; end,
        GetProperty = function(_, key) return props[key], "metadata"; end,
        SetProperty = function(_, key, value) props[key] = value; end,
        GetDiplomacy = function()
            return { IsAtWarWith = function(_, id) return wars[id] == true; end };
        end,
        GetUnits = function() return members(ownUnits); end
    };
    local env = setmetatable({
        print = function(text) table.insert(logs, tostring(text)); end,
        GlobalParameters = { ASAI_ENABLE_METRICS = 1, ASAI_VERSION = "test" },
        Game = { GetCurrentGameTurn = function() return now; end },
        GameConfiguration = { GetGameSpeedType = function() return "ONLINE"; end },
        GameInfo = { GameSpeeds = { ONLINE = { CostMultiplier = 50 } },
            Eras = {}, Projects = {}, Technologies = {}, Buildings = {}, Districts = {},
            Units = {
                UNIT_MODERN_ARMOR = { UnitType = "UNIT_MODERN_ARMOR",
                    PromotionClass = "PROMOTION_CLASS_HEAVY_CAVALRY" },
                UNIT_INFANTRY = { UnitType = "UNIT_INFANTRY", PromotionClass = "PROMOTION_CLASS_MELEE" },
                UNIT_AT_CREW = { UnitType = "UNIT_AT_CREW", PromotionClass = "PROMOTION_CLASS_ANTI_CAVALRY" }
            }, Yields = { YIELD_PRODUCTION = { Index = 1 } } },
        Players = { [1] = player, [0] = {
            IsMajor = function() return true; end, IsHuman = function() return true; end,
            GetUnits = function() return members(enemyUnits); end
        }, [13] = {
            IsMajor = function() return false; end, IsHuman = function() return false; end
        } },
        PlayerManager = {
            IsAlive = function(id) return id == 0 or id == 1 or id == 13; end,
            GetAliveMajorIDs = function() return { 0, 1 }; end
        },
        GameEvents = events(), Events = events(), Map = {}
    }, { __index = _G });
    env._G = env;
    assert(loadfile("Lua/AdaptiveStrategicAI.lua", "t", env))();
    local E = upvalue(env.ASAI_IsLandRecovery, "Execution");
    local S = upvalue(E.RecoveryBudget, "Strategic");
    local state = { StrategicPlan = S.DEFEND, StrategicPlanStallCount = 0 };
    local snapshot = { Cities = 13, ActiveMajorWars = 1 };
    local army = { CombatUnits = 6, LandUnits = 6, RangedUnits = 0, SiegeUnits = 2 };
    local economy = { QueueOk = 1, Queue = { Combat = 1, Land = 0, Ranged = 0, Siege = 0 } };
    local function defense(turn, attrition)
        local result = E.EmptyStatus(turn);
        for key, value in pairs(E.MilitarySignals(snapshot, army, economy.Queue, attrition)) do
            result[key] = value;
        end
        E.RecoveryBudget(player, state, snapshot, economy, result, turn);
        return result;
    end
    local status = defense(124, false);
    check(status.Emergency and status.LandNeeded and status.EmergencyLevel == 0,
        "France first shortage opens land demand immediately, not at T128");
    equal(status.LandQueueTarget, 2, "initial land demand remains bounded");
    status = defense(124, true);
    check(status.AcuteDefense and status.EmergencyLevel == 1 and status.LandNeeded,
        "acute losses escalate on first sample without a review delay");
    check(not status.EconomyAllowed, "acute losses cannot be labeled safe economic recovery");
    army.CombatUnits, army.LandUnits = 3, 3;
    status = defense(130, false);
    check(status.AcuteDefense, "France three land units for thirteen cities is acute even without a fresh loss flag");
    equal(status.LandQueueTarget, 3, "critical defense has a three-city online-window budget");
    economy.Queue.Land, economy.Queue.Combat = 3, 6;
    check(not defense(130, true).LandNeeded, "queued land units consume emergency demand");
    economy.Queue.Land, economy.Queue.Combat = 0, 6;
    check(defense(130, true).LandNeeded, "naval/air orders do not replace missing ground defenders");
    economy.QueueOk = 0;
    check(not defense(130, true).LandNeeded, "unknown queues are not empty queues");
    economy.QueueOk = 1;
    army.CombatUnits, army.LandUnits = 18, 14;
    status = defense(132, false);
    check(not status.Emergency and not status.LandNeeded and status.EmergencyLevel == 0,
        "real recovery ends emergency requests");
    snapshot.ActiveMajorWars = 0;
    army.CombatUnits, army.LandUnits = 3, 3;
    check(not defense(134, false).LandNeeded, "peace clears the demand despite low unit count");
    equal(props.ASAI_EXEC_EMERGENCY_SINCE, -1, "emergency exit is persisted");
    local militaryCondition = upvalue(env.ASAI_IsMilitaryExecutionRecovery, "IsMilitaryExecutionRecovery");
    local militaryStatus = upvalue(militaryCondition, "GetMilitaryExecutionStatus");
    local militaryTarget = upvalue(militaryStatus, "GetMilitaryQueueTarget");
    local stale = { Execution = { MilitaryShare = true },
        StrategicPlanCooldownUntil = { [S.WAR] = -1 } };
    equal(militaryTarget({ Cities = 13, Turn = 124, MajorWars = 1, ActiveMajorWars = 1 }, stale), 6,
        "new major war bypasses cached ten-percent science-sharing queue cap");
    equal(militaryTarget({ Cities = 13, Turn = 124, MajorWars = 0, ActiveMajorWars = 0 }, stale), 2,
        "peaceful sharing still has its bounded ordinary recruitment target");

    -- Observed cavalry only; no global opponent roster scan.
    now = 124;
    E.RecordDefenseCombat(0, 1, 1, 1);
    equal(props.ASAI_EXEC_CAVALRY_THREAT_UNTIL, nil, "non-war events cannot create a counter demand");
    wars[0] = true;
    E.RecordDefenseCombat(0, 2, 1, 1);
    equal(props.ASAI_EXEC_CAVALRY_THREAT_UNTIL, nil, "ordinary infantry is not mislabeled as cavalry");
    env.GameEvents.OnCombatOccurred.Callbacks[2](0, 1, 1, -1);
    equal(props.ASAI_EXEC_CAVALRY_THREAT_UNTIL, 128, "actual modern armor combat creates four-turn online memory");
    E.RecordDefenseCombat(0, -1, 1, 1);
    equal(props.ASAI_EXEC_CAVALRY_THREAT_UNTIL, 128, "unavailable killed-unit identity is not fabricated");
    snapshot.ActiveMajorWars = 1;
    local assets = { Counts = { anticavalry = 0 }, Queued = { anticavalry = 0 } };
    local canBuild = E.CanBuild;
    E.CanBuild = function(_, role) return role == "anticavalry"; end;
    status = defense(124, true);
    E.AntiCavalryBudget(player, snapshot, economy, assets, status, 124);
    check(status.AntiCavalryNeeded and status.AntiCavalryTarget == 2, "observed armor requests bounded legal counters");
    assets.Queued.anticavalry = 2;
    E.AntiCavalryBudget(player, snapshot, economy, assets, status, 124);
    check(not status.AntiCavalryNeeded, "two queued counters close the role demand");
    assets.Queued.anticavalry = 0;
    E.CanBuild = function() return false; end;
    E.AntiCavalryBudget(player, snapshot, economy, assets, status, 124);
    check(not status.AntiCavalryNeeded and status.LandNeeded, "blocked counters fall back to general land reinforcement");
    E.CanBuild = function() return true; end;
    E.AntiCavalryBudget(player, snapshot, economy, assets, status, 128);
    check(not status.AntiCavalryNeeded, "unrefreshed cavalry memory expires");
    E.CanBuild = canBuild;

    -- Every SQL disqualifier is fail-closed on unknowns/errors, even when an
    -- old positive strategy condition would have silently returned false.
    local getStatus = E.GetStatus;
    local SC = upvalue(env.ASAI_IsScienceCapacityDisqualified, "ScienceExecution");
    local capacity = SC.IsCapacity;
    local active = {
        LandNeeded = true, RangedNeeded = true, ScienceConstruction = true,
        ScienceConstructionRole = "campus", MilitaryShare = false,
        MinorStopLoss = true, AntiCavalryNeeded = false
    };
    E.GetStatus = function() return active; end;
    SC.IsCapacity = function() return true; end;
    wars[0] = false;
    local gates = {
        "LandRecovery", "ScienceConstruction", "ScienceCapacity", "CampusDemand", "MinorRecovery"
    };
    for _, label in ipairs(gates) do
        local name = "ASAI_Is" .. label .. "Disqualified";
        local fn = env[name];
        equal(env.GameEvents[name].Callbacks[1], fn, name .. " is registered");
        check(not fn(1), name .. " permits valid major-AI requests");
        check(fn(0), name .. " rejects humans");
        check(fn(13), name .. " rejects city states");
        check(fn(99), name .. " rejects dead/unknown players");
    end
    check(not env.ASAI_IsRangedReinforcementDisqualified(1), "ranged role is active without an urgent counter");
    active.AntiCavalryNeeded = true;
    check(env.ASAI_IsRangedReinforcementDisqualified(1), "counter role takes precedence within the same land budget");
    check(not env.ASAI_IsAntiCavalryDemandDisqualified(1), "counter role can enter");
    active.MilitaryShare = true;
    check(not env.ASAI_IsScienceShareDisqualified(1), "peaceful science sharing can enter");
    wars[0] = true;
    check(env.ASAI_IsScienceShareDisqualified(1), "new war vetoes sharing even with a cached true Lua state");
    active.MilitaryShare = false;
    check(env.ASAI_IsMinorRecoveryDisqualified(1), "major war vetoes stale city-state recruitment suppression");
    active.ScienceConstructionRole = "laboratory";
    check(env.ASAI_IsCampusDemandDisqualified(1), "laboratory deficit never keeps the campus-only strategy active");
    for _, stage in ipairs({ { "campus", "Writing" }, { "university", "Education" }, { "laboratory", "Laboratory" } }) do
        active.ScienceStage, active.ScienceGoal = "infrastructure", stage[1];
        check(not env["ASAI_Is" .. stage[2] .. "Disqualified"](1), stage[1] .. " prerequisite/asset phase can enter");
        active.ScienceStage = "inflight";
        check(env["ASAI_Is" .. stage[2] .. "Disqualified"](1), stage[1] .. " covered queue explicitly vetoes its phase");
    end
    active = E.EmptyStatus(now);
    SC.IsCapacity = function() return false; end;
    for _, label in ipairs({ "LandRecovery", "ScienceConstruction", "ScienceCapacity", "CampusDemand",
        "MinorRecovery", "RangedReinforcement", "AntiCavalryDemand", "ScienceShare",
        "Writing", "Education", "Laboratory" }) do
        check(env["ASAI_Is" .. label .. "Disqualified"](1), label .. " exits when its request is false");
    end
    E.GetStatus = function() error("mock unavailable state"); end;
    SC.IsCapacity = E.GetStatus;
    for _, label in ipairs({ "LandRecovery", "ScienceConstruction", "ScienceCapacity", "CampusDemand",
        "MinorRecovery", "RangedReinforcement", "AntiCavalryDemand", "ScienceShare",
        "Writing", "Education", "Laboratory" }) do
        check(env["ASAI_Is" .. label .. "Disqualified"](1), label .. " errors veto instead of retaining the strategy");
    end
    check(table.concat(logs, "\n"):find("fallback=true", 1, true) ~= nil, "veto failures log their actual safe return");
    E.GetStatus, SC.IsCapacity = getStatus, capacity;

    -- Actual queues, waiting without orders, unknowns and count changes are
    -- separate outcomes. Capture/repair is never asserted to be new building.
    props = {};
    local function demand(turn, requested, queued, count, idle)
        local result = E.EmptyStatus(turn);
        E.RecordProductionDemand(player, result, "campus", requested, queued, count, idle, turn);
        return result.Demands[1];
    end
    equal(demand(108, true, 0, 4, 0).Phase, "awaiting_native_order", "request is not an order");
    equal(demand(112, true, 0, 4, 0).Phase, "stalled_no_order", "one online review without orders is a real stall");
    equal(demand(112, true, 0, 4, 0).NoOrderAge, 4, "duplicate callback does not advance the clock");
    equal(demand(114, true, 1, 4, 0).Phase, "partial_inflight", "one real queue is visible partial execution");
    equal(demand(116, true, nil, 4, nil).Queued, -1, "unknown queues keep a missing sentinel");
    equal(demand(118, true, 0, 4, 1).NoOrderAge, 0, "unknown intervals are not charged as idle turns");
    equal(demand(118, true, 0, 4, 1).PlacedIdle, 1, "placed but paused campus is not counted as an active queue");
    equal(demand(120, false, 0, 5, 0).AssetDelta, 1, "asset growth is recorded without claiming completion origin");
    equal(demand(124, true, 0, 5, 0).NoOrderAge, 0, "disabled demand does not preserve a stale no-order timer");
    env.GameEvents, env.Events = events(), events();
    assert(loadfile("Lua/AdaptiveStrategicAI.lua", "t", env))();
    E = upvalue(env.ASAI_IsLandRecovery, "Execution");
    equal(demand(126, true, 0, 5, 0).NoOrderAge, 2, "save properties preserve active demand age through a Lua reload");

    -- Resume a physically placed district; do not count it as a completed
    -- campus or reject it simply because it already occupies its plot.
    local info = { DistrictType = "DISTRICT_CAMPUS", Index = 10 };
    env.GameInfo.Districts.DISTRICT_CAMPUS = info;
    local city = {
        GetID = function() return 20; end, GetYield = function() return 80; end,
        GetX = function() return 1; end, GetY = function() return 2; end,
        GetBuildings = function() return { HasBuilding = function() return false; end }; end,
        GetBuildQueue = function() return { CurrentlyBuilding = function() return "NONE"; end }; end
    };
    local complete = false;
    player.GetCities = function() return members({ city }); end;
    player.GetDistricts = function() return members({
        { GetType = function() return "DISTRICT_CAMPUS"; end, GetCity = function() return city; end,
          IsComplete = function() return complete; end, IsPillaged = function() return false; end }
    }); end;
    env.Map.GetPlot = function() return { GetIndex = function() return 12; end }; end;
    local entry = { Info = info, Kind = "district", Role = "campus" };
    E.Definitions = { ByType = { DISTRICT_CAMPUS = entry },
        ByRole = { campus = { entry } }, Replacements = {}, ExcludedDistricts = {} };
    local collected = E.CollectAssets(player);
    equal(collected.Counts.campus, 0, "placed campus is not completed infrastructure");
    equal(collected.Incomplete.campus, 1, "incomplete district is explicitly counted");
    collected.Traits, collected.Leaders = {}, {};
    check(E.IsCandidate(collected, collected.Cities[1], entry), "unfinished campus remains eligible for native resume");
    local freshRow = { City = { GetID = function() return 99; end },
        Districts = {}, Placed = {}, Unfinished = {} };
    collected.Cities = { freshRow, collected.Cities[1] };
    check(E.CanBuild(collected, "campus"), "paused campus can reach the construction candidate path");
    equal(collected.CandidateCities.campus, 20, "resuming an unfinished campus precedes nominating a fresh foundation");
    complete = true;
    collected = E.CollectAssets(player);
    collected.Traits, collected.Leaders = {}, {};
    check(not E.IsCandidate(collected, collected.Cities[1], entry), "completed campus does not generate a duplicate demand");
    equal(collected.Counts.campus, 1, "completed campus enters facility coverage");
end
