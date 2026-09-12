-- Actual production functions; only engine objects are mocked.
return function(check, equal, upvalue)
    local now, props, logs, wars, held = 80, {}, {}, {}, false;
    local function events()
        return setmetatable({}, { __index = function(self, key)
            local value = { Callbacks = {} };
            value.Add = function(fn) table.insert(value.Callbacks, fn); end;
            rawset(self, key, value); return value;
        end });
    end
    local unit = { GetType = function() return "WARRIOR"; end };
    local religious = { GetType = function() return "APOSTLE"; end };
    local unitLookup = { [1] = unit, [2] = religious };
    local units = { FindID = function(_, id) return unitLookup[id]; end };
    local districts = { FindID = function(_, id) return id == 5 and {} or nil; end };
    local owned = { TECH_WRITING = true, TECH_EDUCATION = true };
    local player = {
        GetID = function() return 1; end,
        IsMajor = function() return true; end, IsHuman = function() return false; end,
        GetProperty = function(_, key) return props[key], "metadata"; end,
        SetProperty = function(_, key, value) props[key] = value; end,
        GetDiplomacy = function() return { IsAtWarWith = function(_, id) return wars[id] == true; end }; end,
        GetTechs = function() return { HasTech = function(_, name) return owned[name] == true; end }; end,
        GetUnits = function() return units; end, GetDistricts = function() return districts; end
    };
    local function minor(free, barbarian)
        return { IsMajor = function() return false; end, IsHuman = function() return false; end,
            IsBarbarian = function() return barbarian == true; end,
            IsFreeCities = function() return free == true; end,
            GetUnits = function() return units; end, GetDistricts = function() return districts; end };
    end
    local env = setmetatable({
        print = function(text) table.insert(logs, tostring(text)); end,
        GlobalParameters = { ASAI_ENABLE_METRICS = 1, ASAI_VERSION = "test" },
        Game = { GetCurrentGameTurn = function() return now; end },
        GameConfiguration = { GetGameSpeedType = function() return "ONLINE"; end },
        GameInfo = {
            GameSpeeds = { ONLINE = { CostMultiplier = 50 } },
            Eras = { ERA_CLASSICAL = { Index = 1 }, ERA_INDUSTRIAL = { Index = 4 } },
            Technologies = {}, Units = { WARRIOR = { Combat = 20 }, APOSTLE = {} }
        },
        Players = { [1] = player, [0] = {
            IsMajor = function() return true; end, IsHuman = function() return true; end
        }, [13] = minor(), [14] = minor(), [62] = minor(true), [63] = minor(false, true) },
        PlayerConfigurations = {},
        PlayerManager = {
            IsAlive = function(id) return id == 0 or id == 1 or id >= 13; end,
            GetAliveMajorIDs = function() return { 0, 1 }; end,
            GetAliveIDs = function() return { 0, 1, 13, 14, 62, 63 }; end
        },
        CityManager = { GetCityAt = function()
            return held and { GetOwner = function() return 1; end } or nil;
        end },
        GameEvents = events(), Events = events(), Map = {}
    }, { __index = _G });
    env._G = env;
    for _, name in ipairs({ "TECH_WRITING", "TECH_EDUCATION", "TECH_CHEMISTRY", "TECH_CURRENCY" }) do
        env.GameInfo.Technologies[name] = { Index = name };
    end
    assert(loadfile("Lua/AdaptiveStrategicAI.lua", "t", env))();
    local E = upvalue(env.ASAI_IsScienceConstructionExecution, "Execution");
    local relative = { RawRatios = { Science = .60, Techs = 1.0 },
        RawScores = { Military = 5 }, CompetitiveScores = { Science = 1, Military = 1 } };
    check(E.HasScienceHealthGap(relative, "campus", false), "tech parity permits construction health entry");
    check(not E.HasScienceDeficit(relative, false), "construction does not change the stock-deficit rule");
    relative.RawRatios.Science = .85;
    check(not E.HasScienceHealthGap(relative, "campus", false), "health enter threshold is 80 percent");
    check(E.HasScienceHealthGap(relative, "campus", true), "active health survives between thresholds");
    relative.RawRatios.Science = .90;
    check(not E.HasScienceHealthGap(relative, "campus", true), "health exits at 90 percent");
    relative.RawRatios.Science, relative.RawRatios.Techs = .5, 1.11;
    check(not E.HasScienceHealthGap(relative, "campus", false), "large knowledge lead protects Eureka economies");
    relative.RawRatios.Techs = 1;
    check(not E.HasScienceHealthGap(relative, "covered", true), "adequate facilities exit health request");
    check(not E.HasScienceHealthGap({ RawRatios = {} }, "campus", true), "missing ratios are unknown, not zero");

    local assets = { Counts = { campus = 4, library = 4, university = 4 },
        Queued = {}, Cities = {}, CityPlots = {}, Probes = {}, ProbeReasons = {},
        CandidateCities = { campus = 7 }, CandidateTypes = { campus = "DISTRICT_CAMPUS" } };
    local snapshot = { Cities = 12, Era = 4, ActiveMajorWars = 0, MajorWars = 0, RouteCapacity = 0 };
    local army = { CombatUnits = 15, LandUnits = 15, Military = 870, RangedUnits = 8, SiegeUnits = 0 };
    local economy = { QueueOk = 1, Queue = { Combat = 0, Ranged = 0, Siege = 0, Science = 9 } };
    E.CollectAssets = function() return assets; end;
    E.CanBuild = function(_, role) return role == "campus", "blocked"; end;
    E.UpdateStability = function() return -1, 0; end;
    upvalue(E.Update, "GetEconomicSnapshot", function() return economy; end);
    -- Actual Australia's recorded T80/T82/T86/T88 ratios; only the new health
    -- channel is enabled in this fixture. Native project queues are not buildings.
    for _, sample in ipairs({ {80, .946, .666}, {82, 1, .606}, {86, .974, .616}, {88, 1, .624},
            {96, .978, .604}, {98, 1, .546}, {102, .979, .535}, {104, .940, .554}, {106, .961, .495} }) do
        now = sample[1];
        relative.RawRatios.Techs, relative.RawRatios.Science = sample[2], sample[3];
        local status = E.Update(1, relative, snapshot, army, now);
        equal(status.ScienceAge, now - 80, "Australian stock parity must not reset real construction gap");
        equal(status.ScienceStage, now < 84 and "none" or "infrastructure",
            "native science projects do not consume facility budget");
        if now >= 84 then
            check(status.ScienceConstruction and status.MilitaryShare, "native construction and guarded production share activate");
        end
    end
    equal(props.ASAI_SCIENCE_BUILD_TYPE, "DISTRICT_CAMPUS", "exact candidate type published for UI legality");
    equal(E.ScienceFacilityQueue({ Queued = { campus = 1, university = 1, project = 8 } }), 2,
        "only physical facilities consume science construction budget");
    assets.Queued.campus = 3;
    now = 108;
    local status = E.Update(1, relative, snapshot, army, now);
    equal(status.ScienceStage, "inflight", "three facility queues satisfy bounded demand");
    check(not status.ScienceConstruction and not status.MilitaryShare, "queue coverage releases added priority");
    assets.Queued.campus = 0;
    assets.Counts.campus = 5;
    now = 110;
    status = E.Update(1, relative, snapshot, army, now);
    equal(status.ScienceConstructionGain, 1, "observed facility completion is tracked");
    equal(status.ScienceConstructionAge, 0, "real completion resets request wait");
    relative.CompetitiveScores.Military = .5;
    now = 112;
    check(not E.Update(1, relative, snapshot, army, now).MilitaryShare, "inferior army is not treated as safe by unit count");
    relative.CompetitiveScores.Military = 1;
    army.LandUnits, army.CombatUnits = 5, 5;
    now = 114;
    check(not E.Update(1, relative, snapshot, army, now).MilitaryShare, "thin land army retains ordinary recruitment");
    army.LandUnits, army.CombatUnits = 15, 15;
    snapshot.ActiveMajorWars, snapshot.MajorWars = 1, 1;
    now = 116;
    check(not E.Update(1, relative, snapshot, army, now).MilitaryShare, "major front vetoes military production share");
    snapshot.ActiveMajorWars, snapshot.MajorWars = 0, 0;
    relative.RawRatios.Science = 1;
    now = 118;
    check(not E.Update(1, relative, snapshot, army, now).ScienceConstruction, "recovered flow releases health-only demand");
    relative.RawRatios.Science = .6;
    assets.Counts.campus, assets.Counts.library, assets.Counts.university = 8, 6, 6;
    owned.TECH_CHEMISTRY = true;
    assets.Counts.laboratory = 6;
    now = 120;
    equal(E.Update(1, relative, snapshot, army, now).ScienceReason, "facilities_covered",
        "complete infrastructure does not acquire indefinite health support");

    props, wars = {}, { [13] = true };
    now = 200;
    local combat = env.GameEvents.OnCombatOccurred.Callbacks[1];
    combat(1, 2, 13, 2, -1, -1);
    equal(props[E.MinorKey(13, "COMBAT_TURNS")], nil, "religious combat is excluded");
    combat(0, 1, 13, 1, -1, -1);
    equal(props[E.MinorKey(13, "COMBAT_TURNS")], nil, "human combat is excluded");
    wars[62], wars[63] = true, true;
    combat(1, 1, 62, 1, -1, -1);
    combat(1, 1, 63, 1, -1, -1);
    check(props[E.MinorKey(62, "COMBAT_TURNS")] == nil and props[E.MinorKey(63, "COMBAT_TURNS")] == nil,
        "free cities and barbarians are excluded");
    combat(1, 1, 14, 1, -1, -1);
    equal(props[E.MinorKey(14, "COMBAT_TURNS")], nil, "non-war event cannot create a front");
    check(not E.UpdateMinorFronts(player, snapshot, army, now).StopLoss, "nominal minor war is not stalled combat");
    local fronts;
    for turn = 200, 212 do
        now = turn;
        combat(1, 1, 13, -1, -1, 5);
        combat(13, 1, 1, 1, -1, -1);
        fronts = E.UpdateMinorFronts(player, snapshot, army, now);
    end
    equal(props[E.MinorKey(13, "COMBAT_TURNS")], 13, "multiple combats in one turn count once");
    check(fronts.StopLoss and fronts.Active == 1 and fronts.Cooling == 1, "two active reviews without gain start bounded recovery");
    equal(props[E.MinorKey(13, "UNTIL")], 224, "online cooldown lasts twelve game turns");
    equal(fronts.Rows[1].Reason, "stalled", "first recovery sample preserves the triggering reason");
    local repeatFront = E.UpdateMinorFronts(player, snapshot, army, now);
    equal(repeatFront.Rows[1].Stalls, fronts.Rows[1].Stalls, "same-turn repeated review is idempotent");
    env.GameEvents, env.Events = events(), events();
    assert(loadfile("Lua/AdaptiveStrategicAI.lua", "t", env))();
    E = upvalue(env.ASAI_IsScienceConstructionExecution, "Execution");
    combat = env.GameEvents.OnCombatOccurred.Callbacks[1];
    local afterReload = E.UpdateMinorFronts(player, snapshot, army, now);
    check(afterReload.StopLoss and afterReload.Rows[1].Until == 224
        and afterReload.Rows[1].Stalls == 2, "same-turn reload preserves per-opponent failure and expiry");
    for turn = 213, 224 do
        now = turn;
        combat(1, 1, 13, 1, -1, -1);
        fronts = E.UpdateMinorFronts(player, snapshot, army, now);
    end
    check(not fronts.StopLoss and fronts.Actionable == 1, "cooldown exits despite ongoing native combat");
    equal(fronts.Rows[1].Stalls, 0, "cooldown expiry starts a fresh bounded attempt");

    props = {};
    for turn = 300, 306 do
        now = turn;
        combat(1, 1, 13, 1, -1, -1);
        if turn == 304 then
            E.RecordMinorCapture(1, 13, 7, 54, 35);
            held = true;
        end
        fronts = E.UpdateMinorFronts(player, snapshot, army, now);
    end
    equal(fronts.Rows[1].Reason, "held_capture", "only a retained conquest resets minor stagnation");
    equal(fronts.Rows[1].Stalls, 0, "confirmed capture is not counted as failure");
    held = false;
    check(not E.HoldsMinorCapture(player, 13, 300), "lost capture is not a held victory");
    props = {};
    for turn = 400, 412 do
        now = turn;
        combat(1, 1, 13, 1, -1, -1);
        if turn == 404 then snapshot.Cities = 13; end;
        fronts = E.UpdateMinorFronts(player, snapshot, army, now);
    end
    check(fronts.StopLoss, "ordinary founding does not disguise an unproductive minor front");
    wars[14] = true;
    combat(1, 1, 14, 1, -1, -1);
    fronts = E.UpdateMinorFronts(player, snapshot, army, now);
    check(not fronts.StopLoss and fronts.Actionable == 1, "one fresh front prevents global minor recovery");
    wars[14] = false;
    snapshot.MajorWars = 1;
    check(not E.UpdateMinorFronts(player, snapshot, army, now).StopLoss,
        "any major war prevents minor-only global recovery");
    snapshot.MajorWars = 0;
    wars[13] = false;
    equal(E.UpdateMinorFronts(player, snapshot, army, now).Active, 0, "peace releases activity without deleting saved cooldown");
    wars[13] = true;
    now = 430;
    equal(E.UpdateMinorFronts(player, snapshot, army, now).Active, 0, "old combat is not a permanently active front");
    props = {};
    for turn = 500, 506 do
        now = turn;
        combat(1, 1, 13, 1, -1, -1);
        if turn == 506 then army.CombatUnits, army.Military = 6, 400; end
        fronts = E.UpdateMinorFronts(player, snapshot, army, now);
    end
    check(fronts.StopLoss and fronts.Rows[1].Reason == "own_losses",
        "serious own losses do not need a second failed review");
    army.CombatUnits, army.Military = 15, 870;
    local alive = env.PlayerManager.GetAliveIDs;
    env.PlayerManager.GetAliveIDs = nil;
    equal(E.UpdateMinorFronts(player, snapshot, army, now).SensorOk, 0,
        "unavailable opponent inventory is not reported as verified peace");
    env.PlayerManager.GetAliveIDs = alive;

    local signal = E.MilitarySignals({ Cities = 10, ActiveMajorWars = 0, ActiveMinorFronts = 1 },
        { CombatUnits = 12, LandUnits = 12, RangedUnits = 0, SiegeUnits = 0 }, { Combat = 0, Ranged = 0, Siege = 0 }, false);
    check(signal.RangedNeeded and signal.SiegeNeeded, "real minor combat gets bounded missing-role reinforcement");
    signal = E.MilitarySignals({ Cities = 10, ActiveMajorWars = 0, ActiveMinorFronts = 1, MinorFrontStopLoss = true },
        { CombatUnits = 12, LandUnits = 12, RangedUnits = 0, SiegeUnits = 0 }, { Combat = 0, Ranged = 0, Siege = 0 }, false);
    check(signal.RangedNeeded and not signal.SiegeNeeded, "minor cooldown preserves defense but stops added siege emphasis");
    local originalStatus = E.GetStatus;
    E.GetStatus = function() return { MinorStopLoss = true, Emergency = true }; end;
    check(not E.IsMinorFrontRecovery(1), "acute emergency vetoes global minor production restraint");
    E.GetStatus = function() return { MinorStopLoss = true, MilitaryShare = true }; end;
    check(not E.IsMinorFrontRecovery(1), "identical military-specialization lists cannot stack twice");
    E.GetStatus = function() return { ScienceConstruction = true, MilitaryShare = true }; end;
    check(env.ASAI_IsScienceConstructionExecution(1) and env.ASAI_IsScienceProductionShareExecution(1),
        "native registered strategy callbacks consume the constructed request");
    E.GetStatus = originalStatus;
    check(not env.ASAI_IsScienceConstructionExecution(0), "human players cannot activate new native strategy");
    check(#logs > 0 and not table.concat(logs, "\n"):find("ASAI_DIAGNOSTIC_ERROR", 1, true),
        "tested event and controller paths produce no diagnostic exception");
end
