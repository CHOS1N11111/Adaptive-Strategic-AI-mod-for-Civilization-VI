-- Isolated behavioral regressions for the Spain-session feedback fixes.
-- Execute production functions; mock only the game boundary, not decisions.
return function(check, equal, upvalue)
    local function events()
        return setmetatable({}, { __index = function(self, name)
            local event = { Callbacks = {} };
            event.Add = function(fn) table.insert(event.Callbacks, fn); end;
            rawset(self, name, event);
            return event;
        end });
    end
    local function members(items)
        return { Members = function() return ipairs(items); end };
    end
    local now, properties, logs, attachments = 30, {}, {}, {};
    local failModifier, era, currentCities = nil, 3, {};
    local cityByID = {};
    local player = {
        GetID = function() return 1; end,
        IsMajor = function() return true; end,
        IsHuman = function() return false; end,
        -- Some game bindings return additional values; numeric readers must
        -- not forward those into tonumber's optional base argument.
        GetProperty = function(_, key) return properties[key], "metadata"; end,
        SetProperty = function(_, key, value) properties[key] = value; end,
        GetCities = function() return members(currentCities); end,
        GetEra = function() return era; end,
        GetTrade = function() return { GetOutgoingRouteCapacity = function() return 2; end }; end,
        GetTreasury = function() return {
            GetGoldBalance = function() return 100; end,
            GetGoldYield = function() return 10; end,
            GetTotalMaintenance = function() return 2; end
        }; end,
        AttachModifierByID = function(_, modifier)
            if modifier == failModifier then error("simulated attachment failure"); end
            table.insert(attachments, modifier);
        end
    };
    local env = setmetatable({
        print = function(message) table.insert(logs, tostring(message)); end,
        GlobalParameters = { ASAI_ENABLE_METRICS = 1, ASAI_VERSION = "test" },
        Game = { GetCurrentGameTurn = function() return now; end },
        GameConfiguration = { GetGameSpeedType = function() return "ONLINE"; end },
        GameInfo = { GameSpeeds = { ONLINE = { CostMultiplier = 50 } },
            Eras = { ERA_CLASSICAL = { Index = 1 }, ERA_INDUSTRIAL = { Index = 4 },
                ERA_MODERN = { Index = 5 } }, Technologies = {} },
        Players = { [1] = player, [0] = {
            IsMajor = function() return true; end, IsHuman = function() return true; end
        } },
        PlayerConfigurations = {},
        PlayerManager = { IsAlive = function(id) return id == 0 or id == 1; end },
        CityManager = { GetCity = function(playerID, cityID)
            return playerID == 1 and cityByID[cityID] or nil;
        end },
        GameEvents = events(), Events = events(), Map = {}
    }, { __index = _G });
    env._G = env;
    assert(loadfile("Lua/AdaptiveStrategicAI.lua", "t", env))();
    local S = upvalue(env.GameEvents.CityConquered.Callbacks[1], "Strategic");
    local evaluate = upvalue(upvalue(S.IsDevelopmentPlan, "GetRelativeState"), "EvaluateRelativeState");
    local neutral = upvalue(evaluate, "GetNeutralRelativeState");
    local read = upvalue(evaluate, "ReadRelativeState");
    local store = upvalue(evaluate, "StoreRelativeState");
    local sync = upvalue(evaluate, "SyncResultYields");
    local desiredSevere = upvalue(evaluate, "GetDesiredSevereCatchup");
    local collect = upvalue(evaluate, "GetSnapshot");
    local snapshots = upvalue(collect, "m_Snapshots");
    local peaceful = { ActiveMajorWars = 0 };
    local function relative(overall, science, culture, empire, military)
        local state = neutral();
        state.SevereCatchup, state.Band = 1, -1;
        state.Scores = { Overall = overall, Science = science, Culture = culture,
            Empire = empire, Military = military or 1 };
        state.RawScores = state.Scores;
        state.CompetitiveScores = state.Scores;
        return state;
    end

    -- A long-lived single-pillar decision deficit must not entitle the whole
    -- economy to the strong tier. Replay France's actual T30 score tuple.
    local france = relative(1.196, 1.363, 1.433, .698);
    equal(desiredSevere(france, peaceful), 1, "France retains single-pillar severe decision help");
    sync(1, player, france, 30, peaceful);
    sync(1, player, france, 100, peaceful);
    equal(france.SevereResultYieldsActive, 0, "France cannot obtain strong full-yield aid from empire alone");
    equal(france.MildResultYieldsActive, 0, "France does not evade the check through the mild tier");
    equal(#attachments, 0, "ineligible aid attaches no modifiers");
    france.SevereResultYieldsActive = 1; -- Existing 0.11.13 save.
    sync(1, player, france, 101, peaceful);
    equal(attachments[1], "ASAI_SEVERE_RESULT_YIELDS_OFF", "legacy ineligible strong aid is removed");
    sync(1, player, france, 102, peaceful);
    equal(#attachments, 1, "strong removal is not attached repeatedly");

    local broad = relative(.80, .79, .90, 1);
    S.UpdateResultEligibility(broad, peaceful, 40);
    check(not broad.SevereResultEligible, "new broad gap has an independent confirmation clock");
    equal(broad.SevereResultGapSince, 40, "broad clock does not borrow single-pillar history");
    S.UpdateResultEligibility(broad, peaceful, 40);
    check(not broad.SevereResultEligible, "duplicate same-turn samples cannot confirm broad support");
    S.UpdateResultEligibility(broad, peaceful, 41);
    check(not broad.SevereResultEligible, "one online turn is shorter than the confirmation interval");
    store(player, broad);
    broad = read(player);
    equal(broad.SevereResultGapSince, 40, "independent broad-gap clock survives save/load");
    S.UpdateResultEligibility(broad, peaceful, 42);
    check(broad.SevereResultEligible, "persistent overall gap at the enter boundary qualifies");
    sync(1, player, broad, 42, peaceful);
    equal(broad.SevereResultYieldsActive, 1, "confirmed broad gap activates the strong tier");
    local attached = #attachments;
    store(player, broad);
    broad = read(player);
    sync(1, player, broad, 43, peaceful);
    equal(#attachments, attached, "restored active tier is not reapplied on load");

    local twoPillars = relative(1.1, .78, 1.3, .77);
    S.UpdateResultEligibility(twoPillars, peaceful, 50);
    S.UpdateResultEligibility(twoPillars, peaceful, 52);
    check(twoPillars.SevereResultEligible, "two severe pillars qualify even if overall is high");
    local boundary = relative(.801, .781, 1.2, .780);
    S.UpdateResultEligibility(boundary, peaceful, 50);
    S.UpdateResultEligibility(boundary, peaceful, 100);
    check(not boundary.SevereResultEligible, "scores just above both enter thresholds are ineligible");
    broad.Scores = { Overall = .879, Science = 1, Culture = 1, Empire = 1 };
    S.UpdateResultEligibility(broad, peaceful, 44);
    check(broad.SevereResultEligible, "active tier retains overall exit hysteresis");
    broad.Scores.Overall = .88;
    S.UpdateResultEligibility(broad, peaceful, 45);
    check(not broad.SevereResultEligible, "exact overall exit boundary exits strong support");
    broad.Scores = { Overall = 1.1, Science = .859, Culture = 1.3, Empire = .858 };
    S.UpdateResultEligibility(broad, peaceful, 46);
    check(broad.SevereResultEligible, "active tier retains two-pillar exit hysteresis");
    broad.Scores.Science = .86;
    S.UpdateResultEligibility(broad, peaceful, 47);
    check(not broad.SevereResultEligible, "exact second-core exit boundary exits strong support");
    equal(broad.SevereResultGapSince, -1, "resolved broad gap clears its persistent clock");
    broad.SevereResultYieldsActive = 0;
    broad.Scores.Overall = .75;
    S.UpdateResultEligibility(broad, peaceful, 48);
    check(not broad.SevereResultEligible, "a new broad gap must confirm again after recovery");
    broad.SevereResultGapSince = 999;
    S.UpdateResultEligibility(broad, peaceful, 49);
    equal(broad.SevereResultGapSince, 49, "a future clock cannot manufacture elapsed confirmation");
    env.GameInfo.GameSpeeds.ONLINE.CostMultiplier = 100;
    S.UpdateResultEligibility(broad, peaceful, 51);
    check(not broad.SevereResultEligible, "standard-speed confirmation scales to four turns");
    S.UpdateResultEligibility(broad, peaceful, 53);
    check(broad.SevereResultEligible, "standard-speed gap confirms after four turns");
    env.GameInfo.GameSpeeds.ONLINE.CostMultiplier = 50;

    local emergency = relative(1.2, 1.3, 1.3, 1.1, .60);
    S.UpdateResultEligibility(emergency, { ActiveMajorWars = 1 }, 50);
    check(emergency.SevereResultEligible and emergency.SevereResultWarEmergency,
        "active major-war military emergency keeps strong eligibility");
    emergency.SevereCatchup = 0;
    S.UpdateResultEligibility(emergency, { ActiveMajorWars = 1 }, 50);
    check(not emergency.SevereResultEligible, "emergency still requires confirmed severe decision state");
    emergency.SevereCatchup = 1;
    S.UpdateResultEligibility(emergency, { ActiveMajorWars = 0, MinorWars = 1 }, 51);
    check(not emergency.SevereResultEligible, "minor-only war does not authorize emergency full yields");
    emergency.RawScores.Military = .601;
    S.UpdateResultEligibility(emergency, { ActiveMajorWars = 1 }, 52);
    check(not emergency.SevereResultEligible, "military just above emergency threshold does not qualify");

    -- Transaction ordering: successful removal before applying another tier.
    attachments = {};
    local fallback = relative(.91, 1.1, 1.1, .69);
    fallback.SevereResultYieldsActive = 1;
    failModifier = "ASAI_SEVERE_RESULT_YIELDS_OFF";
    sync(1, player, fallback, 60, peaceful);
    equal(fallback.SevereResultYieldsActive, 1, "failed strong removal retains actual active flag");
    equal(fallback.MildResultYieldsActive, 0, "failed strong removal blocks overlapping mild activation");
    equal(#attachments, 0, "failed downgrade has no successful attachment");
    failModifier = nil;
    sync(1, player, fallback, 61, peaceful);
    equal(attachments[1], "ASAI_SEVERE_RESULT_YIELDS_OFF", "downgrade removes strong first");
    equal(attachments[2], "ASAI_MILD_RESULT_YIELDS_ON", "eligible broad mild gap is the fallback");
    check(fallback.MildResultYieldsActive == 1 and fallback.SevereResultYieldsActive == 0,
        "severe decision status can coexist with only eligible mild result help");
    sync(1, player, fallback, 62, peaceful);
    equal(#attachments, 2, "stable fallback does not stack repeat modifiers");
    fallback.Scores.Overall = .75;
    sync(1, player, fallback, 63, peaceful);
    failModifier = "ASAI_MILD_RESULT_YIELDS_OFF";
    sync(1, player, fallback, 65, peaceful);
    check(fallback.MildResultYieldsActive == 1 and fallback.SevereResultYieldsActive == 0,
        "failed mild removal prevents premature strong activation");
    failModifier = nil;
    sync(1, player, fallback, 66, peaceful);
    equal(attachments[3], "ASAI_MILD_RESULT_YIELDS_OFF", "upgrade removes mild first");
    equal(attachments[4], "ASAI_SEVERE_RESULT_YIELDS_ON", "upgrade activates strong only after removal");
    env.GlobalParameters.ASAI_SEVERE_RESULT_YIELDS_ENABLED = 0;
    env.GlobalParameters.ASAI_MILD_RESULT_YIELDS_ENABLED = 0;
    sync(1, player, fallback, 67, peaceful);
    check(fallback.SevereResultYieldsActive == 0 and fallback.MildResultYieldsActive == 0,
        "disabling result support removes the active tier");
    env.GlobalParameters.ASAI_SEVERE_RESULT_YIELDS_ENABLED = nil;
    env.GlobalParameters.ASAI_MILD_RESULT_YIELDS_ENABLED = nil;

    local function planFixture(plan, turn)
        local state = relative(1, 1, 1, 1);
        state.StrategicPlan = plan;
        local snapshot = { Cities = 4, CapturedCities = 0, Settlers = 1, OwnedPlots = 40,
            MajorOpponents = {}, MajorWars = 0, ActiveMajorWars = 0, MajorCombatEvents = 0,
            MajorCaptureEvents = 0, MajorPillageEvents = 0, FoundedEvents = 4,
            LastFoundedTurn = 20, Era = 3, PlayerID = 1 };
        local strength = { CombatUnits = 8, LandUnits = 8, Military = 300 };
        S.StartPlanReview(state, snapshot, strength, turn or 30);
        return state, snapshot, strength;
    end
    -- Actual Cree T36 / Canada T54 failure pattern: expansion is not pressure.
    local pressure, p, army = planFixture(S.PRESSURE);
    pressure.CompetitiveScores.Empire = 1.041;
    p.Cities, p.FoundedEvents, p.LastFoundedTurn = 5, 5, 35;
    local retired = S.ReviewPlan(1, pressure, p, army, 36);
    check(not retired and pressure.StrategicPlanResult == 3 and pressure.StrategicPlanStallCount == 1,
        "Cree ordinary settlement plus .041 empire gain is a stalled PRESSURE window");
    equal(pressure.StrategicPlanExecution, -1, "no war is not claimed as pressure execution");
    pressure.CompetitiveScores.Empire = .974;
    p.Cities, p.FoundedEvents = 6, 6;
    army.CombatUnits, army.LandUnits = 10, 10;
    retired = S.ReviewPlan(1, pressure, p, army, 42);
    check(retired and pressure.StrategicPlanStallCount == 2,
        "Canada-style settlement and two new units cannot erase persistent pressure failure");

    pressure, p, army = planFixture(S.PRESSURE);
    p.ActiveMajorWars, p.MajorWars, p.MajorCombatEvents = 1, 1, 10;
    S.ReviewPlan(1, pressure, p, army, 36);
    check(pressure.StrategicPlanResult == 2 and pressure.StrategicPlanStallCount == 1,
        "war and combat activity are execution, not completed pressure success");
    retired = S.ReviewPlan(1, pressure, p, army, 42);
    check(retired, "mere ongoing war cannot retain a failed pressure plan forever");
    pressure, p, army = planFixture(S.PRESSURE);
    p.Cities, p.CapturedCities, p.MajorCaptureEvents = 5, 1, 1;
    S.ReviewPlan(1, pressure, p, army, 36);
    check(pressure.StrategicPlanResult == 1 and pressure.StrategicPlanStallCount == 0,
        "attributable held major-city capture is valid pressure progress");
    pressure, p, army = planFixture(S.PRESSURE);
    p.Cities, p.CapturedCities = 5, 1;
    S.ReviewPlan(1, pressure, p, army, 36);
    check(pressure.StrategicPlanResult ~= 1, "free-city acquisition without a major capture event is not pressure success");
    pressure, p, army = planFixture(S.PRESSURE);
    p.MajorPillageEvents = 1;
    S.ReviewPlan(1, pressure, p, army, 36);
    check(pressure.StrategicPlanResult ~= 1, "one pillage is below the effective-pressure threshold");
    pressure, p, army = planFixture(S.PRESSURE);
    p.MajorPillageEvents = 2;
    S.ReviewPlan(1, pressure, p, army, 36);
    check(pressure.StrategicPlanResult == 1, "two attributed major-war pillages count as pressure progress");
    pressure, p, army = planFixture(S.PRESSURE);
    p.MajorPillageEvents, p.Cities = 2, 3;
    S.ReviewPlan(1, pressure, p, army, 36);
    check(pressure.StrategicPlanResult ~= 1, "city loss vetoes a false pressure success");
    pressure, p, army = planFixture(S.PRESSURE);
    p.MajorPillageEvents, army.Military = 2, 225;
    S.ReviewPlan(1, pressure, p, army, 36);
    check(pressure.StrategicPlanResult ~= 1, "25 percent own military loss vetoes pressure success");

    pressure, p, army = planFixture(S.PRESSURE);
    pressure.StrategicPlanOutcomeSchema, pressure.StrategicPlanResult = 6, 1;
    pressure.StrategicPlanStallCount = 1;
    S.MigratePlanOutcome(1, pressure, p, army, 40);
    check(pressure.StrategicPlanOutcomeSchema == S.OUTCOME_SCHEMA and pressure.StrategicPlanReviewTurn == 40
        and pressure.StrategicPlanResult == 0, "old PRESSURE outcome is rebaselined under the current schema");
    equal(pressure.StrategicPlanStartedTurn, 30, "migration preserves primary plan age");
    S.MigratePlanOutcome(1, pressure, p, army, 42);
    equal(pressure.StrategicPlanReviewTurn, 40, "migration does not keep postponing reviews");
    for _, plan in ipairs({ S.DEVELOP, S.RECOVER, S.EXPAND, S.DEFEND, S.WAR }) do
        local state, snapshot, strength = planFixture(plan);
        state.StrategicPlanOutcomeSchema, state.StrategicPlanStallCount = 6, 2;
        S.MigratePlanOutcome(1, state, snapshot, strength, 40);
        check(state.StrategicPlanOutcomeSchema == S.OUTCOME_SCHEMA and state.StrategicPlanReviewTurn == 30
            and state.StrategicPlanStallCount == 2, "schema six non-pressure plan " .. plan .. " retains its review and failures");
    end
    local legacy, legacySnapshot, legacyArmy = planFixture(S.DEFEND);
    legacy.StrategicPlanOutcomeSchema, legacy.StrategicPlanStallCount = 5, 3;
    S.MigratePlanOutcome(1, legacy, legacySnapshot, legacyArmy, 40);
    check(legacy.StrategicPlanReviewTurn == 40 and legacy.StrategicPlanStallCount == 3,
        "older defense migration still rebaselines without discarding persistent failures");

    -- Exercise the actual Gameplay event -> player properties -> cached
    -- snapshot -> relative state chain, including reload and ownership checks.
    local function city(id, originalOwner, owner)
        local properties = {};
        local c = {
            GetID = function() return id; end,
            GetOwner = function() return owner or 1; end,
            GetOriginalOwner = function() return originalOwner; end,
            GetPopulation = function() return 3; end,
            GetProperty = function(_, key) return properties[key]; end,
            SetProperty = function(_, key, value) properties[key] = value; end
        };
        cityByID[id] = c;
        return c;
    end
    upvalue(collect, "CountUnits", function() return 1, 1, 2; end);
    upvalue(collect, "CountInFlightUnits", function() return 0, 0, 0; end);
    upvalue(collect, "CountOwnedPlots", function() return 40, 10; end);
    upvalue(collect, "CountWarsByOpponentType", function() return 0, 0, {}; end);
    upvalue(collect, "CountActiveMajorWars", function() return 0, -100000; end);
    properties, now = {}, 48;
    currentCities = { city(10, 1), city(11, 0) };
    snapshots[1] = nil;
    local before = collect(1);
    equal(before.FoundedEvents, 0, "existing cities do not synthesize a new founding history");
    equal(before.LastFoundedTurn, -1, "missing founding date stays unknown on an old save");
    equal(before.CapturedCities, 1, "production collector preserves original-ownership distinction");
    local created = city(12, 1);
    table.insert(currentCities, created);
    env.GameEvents.CityBuilt.Callbacks[1](1, 12, 3, 4);
    local after = collect(1);
    check(after ~= before and after.Cities == 3 and after.FoundedEvents == 1,
        "real founding event invalidates the city snapshot and publishes a new event");
    equal(after.LastFoundedTurn, 48, "snapshot publishes actual founding turn");
    local expansion = neutral();
    expansion.ExpansionLastSuccessTurn, expansion.ExpansionSettlerStallCount = 30, 2;
    expansion.ExpansionBlockedUntil, expansion.StrategicPlanCooldownUntil[S.EXPAND] = 50, 50;
    expansion.StrategicPlanStartedTurn, expansion.StrategicPlanReviewTurn = 42, 42;
    S.UpdateExpansionState(expansion, after, 49);
    check(expansion.ExpansionBlockedUntil == -1 and expansion.ExpansionSettlerStallCount == 0
        and expansion.StrategicPlanCooldownUntil[S.EXPAND] == -1,
        "Australia-style actual founding releases both matching failure holds on the next sample");
    equal(expansion.ExpansionLastSuccessTurn, 48, "success age uses founding time, not the later review");
    equal(expansion.ExpansionPlanAllowed, 1, "normal-era expansion becomes eligible again");
    equal(expansion.StrategicPlanReviewTurn, 42, "founding does not reset the unrelated plan review clock");
    store(player, expansion);
    expansion = read(player);
    equal(expansion.ExpansionBlockedUntil, -1, "released cooldown persists across reload");
    equal(expansion.StrategicPlanCooldownUntil[S.EXPAND], -1, "released plan cooldown persists across reload");
    equal(expansion.ExpansionLastSuccessTurn, 48, "confirmed success date survives reload");
    now = 49;
    env.GameEvents.CityBuilt.Callbacks[1](1, 12, 3, 4);
    equal(properties[S.FOUNDED_EVENTS_PROPERTY], 1, "duplicate founding callback does not count twice");
    equal(properties[S.LAST_FOUNDED_TURN_PROPERTY], 48, "duplicate callback cannot refresh success time");
    S.UpdateExpansionState(expansion, collect(1), now);
    equal(expansion.ExpansionLastSuccessTurn, 48, "re-reading one event cannot prolong recent-success eligibility");
    S.RecordCityConquered(1, 0);
    equal(properties[S.FOUNDED_EVENTS_PROPERTY], 1, "capture event does not fabricate a founding event");
    S.OnCityBuilt(1, 11);
    equal(properties[S.FOUNDED_EVENTS_PROPERTY], 1, "city with a different original owner is not self-founded");
    S.OnCityBuilt(0, 12);
    S.OnCityBuilt(1, 999);
    city(13, 1, 0);
    S.OnCityBuilt(1, 13);
    equal(properties[S.FOUNDED_EVENTS_PROPERTY], 1, "human, missing and mismatched-owner callbacks are ignored");

    -- Same city marker with a fresh Lua runtime models a reload, not just a
    -- second function call in the same runtime.
    env.GameEvents, env.Events = events(), events();
    assert(loadfile("Lua/AdaptiveStrategicAI.lua", "t", env))();
    local reloadedS = upvalue(env.GameEvents.CityBuilt.Callbacks[1], "Strategic");
    reloadedS.OnCityBuilt(1, 12);
    equal(properties[reloadedS.FOUNDED_EVENTS_PROPERTY], 1, "persistent city marker deduplicates after Lua reload");

    local function held(snapshot, untilTurn)
        local s = neutral();
        s.ExpansionSettlerStallCount, s.ExpansionBlockedUntil = 2, untilTurn or 56;
        s.StrategicPlanCooldownUntil[S.EXPAND] = untilTurn or 56;
        S.UpdateExpansionState(s, snapshot, 50);
        return s;
    end
    local e = { Cities = 6, Settlers = 0, Era = 3, ActiveMajorWars = 0,
        FoundedEvents = 1, LastFoundedTurn = 49, PlayerID = 1 };
    expansion = neutral();
    expansion.ExpansionBlockedUntil, expansion.ExpansionSettlerStallCount = 54, 2;
    expansion.StrategicPlanCooldownUntil[S.EXPAND] = 60;
    S.UpdateExpansionState(expansion, e, 50);
    check(expansion.ExpansionBlockedUntil == -1 and expansion.StrategicPlanCooldownUntil[S.EXPAND] == 60,
        "confirmed founding does not remove a longer independent plan cooldown");
    e.Era = 5;
    check(held(e).ExpansionPlanAllowed == 0 and held(e).ExpansionPhase == S.EXPANSION_CLOSED,
        "modern-era cutoff remains closed after successful founding");
    e.Era = 4;
    check(held(e).ExpansionPlanAllowed == 1 and held(e).ExpansionPhase == S.EXPANSION_RESTRICTED,
        "industrial-era recent success uses the existing restricted exception");
    e.Era, e.ActiveMajorWars = 3, 1;
    equal(held(e).ExpansionPlanAllowed, 0, "active major war still blocks expansion after success");
    e.ActiveMajorWars = 0;
    expansion = neutral();
    expansion.ExpansionBlockedUntil = 56;
    expansion.Execution = { StabilityUntil = 60 };
    S.UpdateExpansionState(expansion, e, 50);
    equal(expansion.ExpansionPlanAllowed, 0, "loyalty stability hold survives successful founding");
    e.FoundedEvents, e.LastFoundedTurn = 0, -1;
    check(held(e).ExpansionBlockedUntil == 56 and held(e).ExpansionPlanAllowed == 0,
        "city count alone or missing legacy event data cannot unlock a failed expansion");
    e.FoundedEvents, e.LastFoundedTurn = 1, 99;
    equal(held(e).ExpansionBlockedUntil, 56, "future founding timestamp cannot release a current cooldown");
    e.LastFoundedTurn = 49;
    expansion = held(e);
    expansion.ExpansionBlockedUntil, expansion.ExpansionSettlerStallCount = 58, 2;
    S.UpdateExpansionState(expansion, e, 51);
    equal(expansion.ExpansionBlockedUntil, 58, "consumed old success cannot clear a later failure hold");

    local expand, x, units = planFixture(S.EXPAND, 40);
    x.Cities = 5; -- Return/flip without any founding event.
    S.ReviewPlan(1, expand, x, units, 46);
    equal(expand.ExpansionLastSuccessTurn, -1, "ordinary net city gain cannot refresh founding success");
    equal(expand.ExpansionSettlerStallCount, 1, "idle settler failure still counts without a genuine founding");
    local _, stalled = S.ReviewPlan(1, expand, x, units, 52);
    check(stalled and expand.ExpansionSettlerStallCount == 2,
        "two genuine idle-settler windows retain the existing stop-loss trigger");
    expand, x, units = planFixture(S.EXPAND, 48);
    x.Cities, x.FoundedEvents, x.LastFoundedTurn = 5, 5, 48;
    S.UpdateExpansionState(expand, x, 49);
    S.ReviewPlan(1, expand, x, units, 54);
    check(expand.StrategicPlanResult == 1 and expand.ExpansionSettlerStallCount == 0,
        "founding later in the baseline turn is recognized through the event counter");
    equal(expand.ExpansionLastSuccessTurn, 48, "later plan review does not move the success date");
    store(player, expand);
    equal(read(player).StrategicPlanBaselineFoundedEvents, 5,
        "founding-event review baseline is persisted independently of raw city counts");

    env.CityManager.GetCity = function() error("simulated unavailable city API"); end;
    local countBefore = properties[S.FOUNDED_EVENTS_PROPERTY];
    S.OnCityBuilt(1, 12);
    equal(properties[S.FOUNDED_EVENTS_PROPERTY], countBefore,
        "city API failure fails closed without guessed founding evidence");
    check(logs[#logs]:find("ASAI_ERROR condition=ASAI_RecordCityBuilt", 1, true) ~= nil,
        "unknown founding API is diagnosable rather than silently treated as success");
end;
