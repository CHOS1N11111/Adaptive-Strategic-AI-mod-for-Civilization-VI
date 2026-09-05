-- Execute the actual Lua functions with a deterministic mock game boundary.
-- This verifies behavior and persistence, not availability of engine APIs.
local checks = 0;
local function check(value, label)
    assert(value, label);
    checks = checks + 1;
end
local function equal(actual, expected, label)
    check(actual == expected, label .. ": expected " .. tostring(expected)
        .. ", got " .. tostring(actual));
end
local function events()
    return setmetatable({}, { __index = function(self, name)
        local entry = { Callbacks = {} };
        entry.Add = function(fn) table.insert(entry.Callbacks, fn); end;
        entry.Remove = function(fn)
            for i = #entry.Callbacks, 1, -1 do
                if entry.Callbacks[i] == fn then table.remove(entry.Callbacks, i); end
            end
        end;
        rawset(self, name, entry);
        return entry;
    end });
end
local function upvalue(fn, wanted, replacement)
    for index = 1, 100 do
        local name, value = debug.getupvalue(fn, index);
        if name == nil then break; end
        if name == wanted then
            if replacement ~= nil then debug.setupvalue(fn, index, replacement); end
            return value;
        end
    end
    error("missing upvalue " .. wanted);
end
local now = 50;
local logs = {};
local env = setmetatable({
    print = function(message) table.insert(logs, tostring(message)); end,
    GlobalParameters = { ASAI_ENABLE_METRICS = 1, ASAI_VERSION = "test" },
    Game = { GetCurrentGameTurn = function() return now; end },
    GameConfiguration = { GetGameSpeedType = function() return "ONLINE"; end },
    GameInfo = { GameSpeeds = { ONLINE = { CostMultiplier = 50 } },
        Eras = { ERA_CLASSICAL = { Index = 1 }, ERA_INDUSTRIAL = { Index = 4 },
            ERA_MODERN = { Index = 5 } }, Technologies = {} },
    Players = {}, PlayerConfigurations = {},
    PlayerManager = { IsAlive = function(id) return id == 0 or id == 1; end },
    GameEvents = events(), Events = events(), Map = {}
}, { __index = _G });
env._G = env;
assert(loadfile("Lua/AdaptiveStrategicAI.lua", "t", env))();
local E = upvalue(env.ASAI_IsEducationPrerequisite, "Execution");
local S = upvalue(env.GameEvents.CityConquered.Callbacks[1], "Strategic");

-- War outcomes: global enemy decline is diagnostic-only, including the
-- observed Maori T82 case and a same-count/different-opponent case.
local state = { StrategicPlanBaselineOpponents = "2:4" };
local snapshot = { MajorOpponents = { 4, 2 } };
local good, external, stable = S.AssessWarOutcome(state, snapshot, -1, 0, 0, 0, .171, 0);
check(not good and external and stable, "Maori T82 must not count as war progress");
good = S.AssessWarOutcome(state, snapshot, 0, 0, 0, 0, .50, 0);
check(not good, "enemy global losses alone do not prove our execution");
good, external, stable = S.AssessWarOutcome(state, { MajorOpponents = { 2, 3 } }, 0, 0, 0, 0, .5, 0);
check(not good and not external and not stable, "equal war count is not a stable opponent set");
check(S.AssessWarOutcome(state, snapshot, 1, 1, 1, 0, 0, 0), "held major capture counts");
check(not S.AssessWarOutcome(state, snapshot, 1, 1, 0, 0, 0, 0), "settlement or free flip is not major capture");
check(not S.AssessWarOutcome(state, snapshot, 0, 0, 1, 0, 0, 0), "lost recapture does not prove held progress");
check(S.AssessWarOutcome(state, snapshot, 0, 0, 0, 2, 0, .1), "effective pillaging counts");
check(not S.AssessWarOutcome(state, snapshot, 0, 0, 0, 2, 0, .25), "serious own loss prevents success reset");
local review = { StrategicPlanReviewTurn = 84, StrategicPlanStartedTurn = 84,
    StrategicPlanBaselineCombatEvents = 90, StrategicPlanStallCount = 1 };
S.UpdatePlanReviewForChanges(review, {}, {}, 88, false);
equal(review.StrategicPlanReviewTurn, 84, "support change keeps primary review due at 90");
equal(review.StrategicPlanBaselineCombatEvents, 90, "support change preserves combat window");
equal(review.StrategicPlanStallCount, 1, "support change preserves stop-loss count");
local originalStart = S.StartPlanReview;
local started = 0;
S.StartPlanReview = function() started = started + 1; end;
S.UpdatePlanReviewForChanges(review, {}, {}, 88, true);
equal(started, 1, "real plan switch starts its own review");
S.StartPlanReview = originalStart;
local recovery = { CompetitiveScores = { Science = .7, Culture = 1.2 }, StrategicSupport = 1 };
equal(S.GetPlanOutcomeScore(recovery, S.RECOVER), .7, "primary recovery measures the weak knowledge pillar");
recovery.StrategicSupport = 2;
equal(S.GetPlanOutcomeScore(recovery, S.RECOVER), .7, "switching support does not manufacture a primary score gain");

-- Science stages use actual unlocks and completed knowledge, not civ names.
local owned = {};
local hasTech = function(name) return owned[name] == true; end;
local counts = { campus = 3, library = 2, university = 0, laboratory = 0, spaceport = 0 };
equal(E.SelectScienceGoal(hasTech, counts, 3, 8), "writing", "missing writing first");
owned.TECH_WRITING = true;
equal(E.SelectScienceGoal(hasTech, counts, 3, 8), "education", "missing education unlocks universities");
owned.TECH_EDUCATION = true;
local stage, goal = E.SelectScienceGoal(hasTech, counts, 3, 8);
check(stage == "infrastructure" and goal == "university", "education hands off to existing campus universities");
counts.university = 2;
stage, goal = E.SelectScienceGoal(hasTech, counts, 3, 8);
check(stage == "infrastructure" and goal == "campus", "expand campuses after current upgrade bottleneck");
counts.campus, counts.library, counts.university = 5, 4, 4;
equal(E.SelectScienceGoal(hasTech, counts, 4, 8), "laboratory_tech", "industrial science can target chemistry");
owned.TECH_CHEMISTRY = true;
stage, goal = E.SelectScienceGoal(hasTech, counts, 4, 8);
check(stage == "infrastructure" and goal == "laboratory", "chemistry hands off to laboratories");
counts.spaceport = 1;
equal(E.SelectScienceGoal(hasTech, counts, 5, 8), "none", "do not compete with existing space-race execution");
check(not E.HasScienceDeficit({ RawRatios = { Techs = 42 / 41 }, CompetitiveScores = { Science = .65 } }, false),
    "Babylon-like completed-tech lead prevents yield-only research boost");
check(E.HasScienceDeficit({ RawRatios = { Techs = .75 }, CompetitiveScores = { Science = .70 } }, false),
    "actual science and completed-knowledge deficit qualifies");
check(not E.HasScienceDeficit({ RawRatios = { Techs = .95 }, CompetitiveScores = { Science = .97 } }, true),
    "science recovery exits after score recovery");

-- Attrition, physical density and role pipelines; no dependence on human army.
local army = { CombatUnits = 6, RangedUnits = 0, SiegeUnits = 0 };
local front = { ActiveMajorWars = 2, Cities = 12 };
local queue = { Combat = 2, Ranged = 2, Siege = 0 };
local signal = E.MilitarySignals(front, army, queue, true);
check(signal.Emergency and signal.ThinArmy, "Khmer-like losses trigger immediate survival response");
check(not signal.RangedNeeded, "two in-flight ranged units cover target");
check(not signal.SiegeNeeded, "survival response does not demand premature siege");
signal = E.MilitarySignals(front, { CombatUnits = 18, RangedUnits = 0, SiegeUnits = 0 },
    { Combat = 0, Ranged = 0, Siege = 0 }, false);
check(not signal.Emergency and signal.RangedNeeded and signal.SiegeNeeded, "healthy army can lack exact roles");
signal = E.MilitarySignals(front, army, { Combat = 10, Ranged = 2, Siege = 1 }, true);
check(not signal.Emergency, "large committed replacement pipeline stops general top-up");
check(E.ShouldRearm({ Execution = signal, StrategicPlanCooldownUntil = { [S.WAR] = 84 } }, front),
    "offensive reentry still waits for physical troops");
check(not E.MilitarySignals({ ActiveMajorWars = 0, Cities = 12 }, army, queue, true).Emergency,
    "peace clears wartime top-up eligibility");

-- Reproducible persisted timers and per-turn sampled history.
local properties = {};
local player = {
    GetID = function() return 1; end,
    GetProperty = function(_, key) return properties[key]; end,
    SetProperty = function(_, key, value) properties[key] = value; end,
    IsMajor = function() return true; end, IsHuman = function() return false; end,
    GetTechs = function() return { HasTech = function(_, index) return owned[index] == true; end }; end
};
env.Players[1] = player;
env.Players[0] = { IsMajor = function() return true; end, IsHuman = function() return true; end };
for _, name in ipairs({ "TECH_WRITING", "TECH_EDUCATION", "TECH_CHEMISTRY", "TECH_CURRENCY" }) do
    env.GameInfo.Technologies[name] = { Index = name };
end
equal(E.UpdateTimer(player, "timer", true, 50, false), 0, "deficit begins at zero age");
equal(E.UpdateTimer(player, "timer", true, 54, false), 4, "deficit age survives independent calls");
equal(E.UpdateTimer(player, "timer", true, 54, true), 0, "real progress resets age");
equal(E.UpdateTimer(player, "timer", false, 55, false), 0, "exit clears deficit timer");
equal(properties.timer, -1, "cleared timer is persisted");

local originalAssets, originalCanBuild, originalStability = E.CollectAssets, E.CanBuild, E.UpdateStability;
local assetFixture = { Counts = { campus = 3, library = 2, university = 0, spaceport = 0 },
    Queued = { trade_building = 0, trade_district = 0 }, CityPlots = {}, Cities = {}, BuildabilityOk = 1 };
E.CollectAssets = function() return assetFixture; end;
E.CanBuild = function(_, role) return role ~= "trade_district"; end;
E.UpdateStability = function() return -1, 0; end;
local economy = { QueueOk = 1, Queue = { Combat = 0, Ranged = 0, Siege = 0, Science = 0 } };
upvalue(E.Update, "GetEconomicSnapshot", function() return economy; end);
local relative = { RawRatios = { Techs = .75 }, CompetitiveScores = { Science = .70 } };
snapshot = { Cities = 8, Era = 3, ActiveMajorWars = 0, MajorWars = 0, RouteCapacity = 2 };
army = { CombatUnits = 12, Military = 600, RangedUnits = 2, SiegeUnits = 1 };
owned.TECH_WRITING, owned.TECH_EDUCATION, owned.TECH_CURRENCY = true, false, true;
properties = {};
E.Cache = {};
equal(E.Update(1, relative, snapshot, army, 50).ScienceStage, "none", "new shortfall waits for confirmation duration");
equal(E.Update(1, relative, snapshot, army, 53).ScienceStage, "none", "shortfall below four online turns waits");
equal(E.Update(1, relative, snapshot, army, 54).ScienceStage, "education", "persistent deficit enables education priority");
equal(E.Update(1, relative, snapshot, army, 56).TradeStage, "building", "stalled capacity chooses missing capacity buildings");
assetFixture.Queued.trade_building = 2;
equal(E.Update(1, relative, snapshot, army, 57).TradeStage, "inflight", "committed capacity budget stops escalation");
assetFixture.Queued.trade_building = 0;
snapshot.RouteCapacity = 3;
equal(E.Update(1, relative, snapshot, army, 58).TradeAge, 0, "actual capacity improvement resets trade stall timer");
snapshot.RouteCapacity = 4;
equal(E.Update(1, relative, snapshot, army, 60).TradeStage, "none", "capacity target exits execution");
owned.TECH_EDUCATION = true;
local liveStatus = E.Update(1, relative, snapshot, army, 61);
check(liveStatus.ScienceStage == "infrastructure" and liveStatus.ScienceGoal == "university",
    "persisted shortfall hands off after real education unlock");
economy.Queue.Science = 2;
equal(E.Update(1, relative, snapshot, army, 62).ScienceStage, "inflight", "science queue budget prevents duplicate emphasis");
equal(E.Update(1, relative, snapshot, army, 62), E.Cache[1], "same-turn callbacks reuse the same sample");
snapshot.ActiveMajorWars, snapshot.MajorWars = 1, 1;
army.CombatUnits, army.Military, army.RangedUnits = 4, 200, 0;
check(E.Update(1, relative, snapshot, army, 63).Emergency, "observed unit losses persist immediate response");
E.Cache = {};
check(E.Update(1, relative, snapshot, army, 63).RecentAttrition, "same-turn reload retains attrition expiry");

snapshot.ActiveMajorWars, snapshot.MajorWars, snapshot.RouteCapacity = 0, 0, 2;
army.CombatUnits, army.Military = 12, 600;
economy.Queue.Science = 0;
E.CanBuild = function(_, role) return role == "trade_district" or role == "university"; end;
E.Update(1, relative, snapshot, army, 64);
equal(E.Update(1, relative, snapshot, army, 70).TradeStage, "district", "missing eligible capacity buildings hands off to districts");
E.CanBuild = function() return false; end;
owned.TECH_CURRENCY = false;
equal(E.Update(1, relative, snapshot, army, 71).TradeStage, "research", "locked trade capacity targets Currency");
owned.TECH_CURRENCY = true;
equal(E.Update(1, relative, snapshot, army, 72).TradeStage, "blocked", "no legal candidate is reported as blocked, not productive");
assetFixture.Queued.trade_district = 2;
equal(E.Update(1, relative, snapshot, army, 73).TradeStage, "inflight", "district pipeline also consumes the capacity budget");
assetFixture.Queued.trade_district, assetFixture.Queued.spaceport = 0, 1;
liveStatus = E.Update(1, relative, snapshot, army, 74);
check(liveStatus.ScienceStage == "none" and liveStatus.ScienceGoal == "space_race"
    and liveStatus.TradeStage == "space_race", "queued spaceport protects existing victory execution");
assetFixture.Queued.spaceport, assetFixture.Counts.spaceport = 0, 1;
equal(E.Update(1, relative, snapshot, army, 75).TradeStage, "space_race", "completed spaceport retains execution protection");
E.CollectAssets = function() error("mock missing asset API"); end;
snapshot.ActiveMajorWars, snapshot.MajorWars = 1, 1;
army.CombatUnits, army.Military = 4, 200;
liveStatus = E.Update(1, relative, snapshot, army, 76);
check(liveStatus.AssetsOk == 0 and liveStatus.Emergency
    and not liveStatus.RangedNeeded and liveStatus.ScienceStage == "none",
    "asset sensor failure preserves survival response and isolates optional escalation");
E.CollectAssets, E.CanBuild, E.UpdateStability = originalAssets, originalCanBuild, originalStability;

local originalStatus = E.GetStatus;
E.GetStatus = function() return { ScienceStage = "infrastructure", ScienceGoal = "university" }; end;
check(E.IsEducation(1) and not E.IsWriting(1) and not E.IsLaboratory(1),
    "university handoff activates only its specific facility strategy");
E.GetStatus = function() return { ScienceStage = "inflight", ScienceGoal = "university" }; end;
check(not E.IsEducation(1), "committed science budget suspends stage-specific weighting");
E.GetStatus = originalStatus;
equal(E.GetStatus(0).ScienceStage, "none", "human players do not enter the execution controller");

-- Buildability is fail-closed and a second capacity building is not a new slot.
E.Definitions = { ByRole = { trade_building = { { Info = { Hash = 7 } } } } };
local attempts = 0;
local city = { GetBuildQueue = function() return { CanProduce = function(_, hash, exclusion)
    attempts = attempts + 1; equal(exclusion, false, "use actual-production probe, not visibility probe");
    return hash == 7;
end }; end };
local assets = { Cities = { { City = city, TradeBuildings = 1 } }, Probes = {}, BuildabilityOk = 1 };
check(not E.CanBuild(assets, "trade_building") and attempts == 0, "do not buy another capacity building for an already-served city");
assets.Cities[1].TradeBuildings, assets.Probes = 0, {};
check(E.CanBuild(assets, "trade_building"), "legal capacity building can be prioritized");
assets.Cities[1].City, assets.Probes = { GetBuildQueue = function() return {}; end }, {};
check(not E.CanBuild(assets, "trade_building") and assets.BuildabilityOk == 0, "missing production API is unknown, not buildable");

-- Only verified free-city ownership loss triggers the bounded stability hold.
properties = { ASAI_EXEC_CITY_PLOTS = "10,20" };
env.Map.GetPlotByIndex = function(index)
    return { GetOwner = function() return index == 20 and 62 or 1; end, IsCity = function() return true; end };
end;
env.Players[62] = { IsFreeCities = function() return true; end };
local untilTurn, losses = E.UpdateStability(player, { CityPlots = { 10 } }, 79);
check(untilTurn == 87 and losses == 1, "loyalty transfer triggers eight-online-turn stabilization");
untilTurn, losses = E.UpdateStability(player, { CityPlots = { 10 } }, 80);
check(untilTurn == 87 and losses == 0, "same lost city does not extend cooldown every turn");
properties.ASAI_EXEC_CITY_PLOTS = "10,20";
env.Players[62].IsFreeCities = function() return false; end;
untilTurn, losses = E.UpdateStability(player, { CityPlots = { 10 } }, 85);
check(untilTurn == 87 and losses == 0, "non-free-city transfer is not mislabeled loyalty loss");

properties = {};
env.PlayerManager.GetAliveIDs = function() return { 0, 1, 62 }; end;
env.Players[62].IsFreeCities = function() return true; end;
env.Players[62].GetCities = function() return { Members = function() return ipairs({
    { GetOriginalOwner = function() return 1; end },
    { GetOriginalOwner = function() return 2; end }
}); end }; end;
untilTurn, losses = E.UpdateStability(player, { CityPlots = { 10 } }, 90);
check(untilTurn == 98 and losses == 0, "old-save free city seeds a bounded hold without inventing a new loss");
check(string.find(logs[#logs], "existing_free_cities=1", 1, true) ~= nil,
    "old-save audit counts only this AI's original cities");
untilTurn, losses = E.UpdateStability(player, { CityPlots = { 10 } }, 91);
check(untilTurn == 98 and losses == 0, "old-save audit does not repeat after baseline persistence");

-- UI APIs execute in their own environment and must not touch Gameplay state.
local uiLogs, uiEvents = {}, events();
local ui = setmetatable({ print = function(s) table.insert(uiLogs, s); end,
    GlobalParameters = { ASAI_ENABLE_METRICS = 1 }, Events = uiEvents,
    Game = { GetCurrentGameTurn = function() return now; end },
    GameConfiguration = env.GameConfiguration,
    GameInfo = { GameSpeeds = env.GameInfo.GameSpeeds, GreatPersonClasses = {
        GREAT_PERSON_CLASS_WRITER = { Index = 1 }, GREAT_PERSON_CLASS_ARTIST = { Index = 2 },
        GREAT_PERSON_CLASS_MUSICIAN = { Index = 3 } }, Units = { BUILDER = { UnitType = "UNIT_BUILDER" },
        TRADER = { MakeTradeRoute = true } }, Buildings = {}, Districts = {}, Projects = {} },
    Players = {}, ContextPtr = { SetShutdown = function(self, fn) self.Shutdown = fn; end }
}, { __index = _G });
ui._G = ui;
local function members(items) return { Members = function() return ipairs(items); end }; end
local uiCity = { GetID = function() return 11; end, GetX = function() return 4; end, GetY = function() return 5; end,
    GetTrade = function() return { GetOutgoingRoutes = function() return {
        { DestinationCityPlayer = 1, TraderUnitID = 9 } }; end }; end,
    GetBuildQueue = function() return { CurrentlyBuilding = function() return "BUILDER"; end }; end };
ui.Players[1] = { IsAlive = function() return true; end, IsMajor = function() return true; end,
    IsHuman = function() return false; end, GetID = function() return 1; end,
    GetProperty = function() return now; end,
    SetProperty = function() error("UI diagnostic attempted a game-state write"); end,
    GetCities = function() return members({ uiCity }); end,
    GetUnits = function() return members({ { GetID = function() return 9; end, GetType = function() return "TRADER"; end } }); end,
    GetTrade = function() return { GetNumOutgoingRoutes = function() return 1; end }; end,
    GetGreatPeoplePoints = function() return { GetPointsPerTurn = function(_, index) return index; end,
        GetPointsTotal = function(_, index) return index * 10; end }; end };
ui.Players[0] = { IsAlive = function() return true; end, IsMajor = function() return true; end, IsHuman = function() return true; end };
assert(loadfile("UI/ASAI_Diagnostics.lua", "t", ui))();
now = 92;
uiEvents.CityProductionCompleted.Callbacks[1](1, 11);
uiEvents.PlayerTurnDeactivated.Callbacks[1](1);
equal(#uiLogs, 1, "UI waits for published state before sampling");
uiEvents.GameCoreEventPublishComplete.Callbacks[1]();
check(string.find(uiLogs[2], "active_routes=1", 1, true) ~= nil, "UI actual route count is read");
check(string.find(uiLogs[3], "cultural_gpp_per_turn=6.0", 1, true) ~= nil, "UI cultural point sum is read");
check(string.find(uiLogs[4], "completions_since_sample=1", 1, true) ~= nil, "completion evidence accompanies queue phase");
uiEvents.PlayerTurnDeactivated.Callbacks[1](1);
uiEvents.PlayerTurnDeactivated.Callbacks[1](0);
uiEvents.GameCoreEventPublishComplete.Callbacks[1]();
equal(#uiLogs, 4, "duplicate callbacks and human turns do not create extra samples");
uiCity.GetTrade = nil;
now = 94;
uiEvents.PlayerTurnDeactivated.Callbacks[1](1);
uiEvents.GameCoreEventPublishComplete.Callbacks[1]();
check(string.find(table.concat(uiLogs, "\n"), "route_sensor_ok=0", 1, true) ~= nil, "missing UI route capability degrades independently");
check(string.find(uiLogs[#uiLogs - 1], "gpp_sensor_ok=1", 1, true) ~= nil, "culture sensor survives route failure");
ui.ContextPtr.Shutdown();
equal(#uiEvents.PlayerTurnDeactivated.Callbacks, 0, "UI shutdown removes handlers");

print(string.format("LUA REGRESSION PASSED: %d checks; real Lua functions, mocked game boundary", checks));
