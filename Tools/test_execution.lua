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
equal(E.SelectScienceGoal(hasTech, counts, 5, 8), "infrastructure", "one spaceport does not veto the whole empire's research recovery");
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
check(signal.Emergency and signal.ReinforcementCommitted, "committed troops consume budget but do not prove physical recovery");
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
E.CanBuild = function(_, role) return role ~= "trade_district", role ~= "trade_district" and "candidate" or "blocked"; end;
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
E.CanBuild = function(_, role) return role == "trade_district" or role == "university", "blocked"; end;
E.Update(1, relative, snapshot, army, 64);
equal(E.Update(1, relative, snapshot, army, 70).TradeStage, "district", "missing eligible capacity buildings hands off to districts");
E.CanBuild = function() return false, "blocked"; end;
owned.TECH_CURRENCY = false;
equal(E.Update(1, relative, snapshot, army, 71).TradeStage, "research", "locked trade capacity targets Currency");
owned.TECH_CURRENCY = true;
equal(E.Update(1, relative, snapshot, army, 72).TradeStage, "blocked", "no legal candidate is reported as blocked, not productive");
assetFixture.Queued.trade_district = 2;
equal(E.Update(1, relative, snapshot, army, 73).TradeStage, "inflight", "district pipeline also consumes the capacity budget");
assetFixture.Queued.trade_district, assetFixture.Queued.spaceport = 0, 1;
liveStatus = E.Update(1, relative, snapshot, army, 74);
check(liveStatus.ScienceStage == "blocked" and liveStatus.ScienceGoal == "university"
    and liveStatus.TradeStage == "blocked", "one queued port does not veto other cities' economic candidates");
assetFixture.Queued.spaceport, assetFixture.Counts.spaceport = 0, 1;
equal(E.Update(1, relative, snapshot, army, 75).TradeStage, "blocked", "completed spaceport does not erase trade deficit");
E.CollectAssets = function() error("mock missing asset API"); end;
snapshot.ActiveMajorWars, snapshot.MajorWars = 1, 1;
army.CombatUnits, army.Military = 4, 200;
liveStatus = E.Update(1, relative, snapshot, army, 76);
check(liveStatus.AssetsOk == 0 and liveStatus.Emergency
    and not liveStatus.RangedNeeded and liveStatus.ScienceStage == "none",
    "asset sensor failure preserves survival response and isolates optional escalation");
E.CollectAssets, E.CanBuild, E.UpdateStability = originalAssets, originalCanBuild, originalStability;

-- Continuous Khmer-style recovery: land defense, finite escalation, economic
-- continuity, and rebaselining even when the same DEFEND job must be retained.
properties = {};
local khmer = { Cities = 14, ActiveMajorWars = 2, MajorWars = 2, RouteCapacity = 3,
    CapturedCities = 0, Settlers = 0, OwnedPlots = 150, MajorOpponents = {},
    MajorCombatEvents = 10, MajorCaptureEvents = 0, MajorPillageEvents = 0 };
local khmerArmy = { CombatUnits = 8, LandUnits = 4, NavalUnits = 3, AirUnits = 1,
    RangedUnits = 0, SiegeUnits = 0, Military = 800 };
local defense = { StrategicPlan = S.DEFEND, StrategicPlanCooldownUntil = { [S.WAR] = -1 },
    StrategicPlanStallCount = 0, CompetitiveScores = { Military = .8 },
    ExpansionSettlerStallCount = 0, ExpansionBlockedUntil = -1 };
economy.Queue.Land, economy.Queue.Combat = 0, 0;
local function recover(turn, attrition)
    local result = E.EmptyStatus(turn);
    for key, value in pairs(E.MilitarySignals(khmer, khmerArmy, economy.Queue, attrition)) do
        result[key] = value;
    end
    E.RecoveryBudget(player, defense, khmer, economy, result, turn);
    return result;
end
defense.Execution = recover(100, false);
check(defense.Execution.ThinArmy and defense.Execution.Land == 4
    and defense.Execution.LandTarget == 8, "Khmer 4 land + 3 sea + 1 air is not eight land defenders");
check(not defense.Execution.EconomyAllowed and not defense.Execution.LandNeeded,
    "initial emergency preserves the immediate baseline/role response");
defense.Execution = recover(106, false);
check(defense.Execution.EmergencyLevel == 1 and defense.Execution.LandNeeded
    and defense.Execution.LandQueueTarget == 3, "first persistent window requests a bounded land pipeline");
check(defense.Execution.EconomyAllowed, "prolonged low density no longer vetoes all economic recovery");
defense.Execution = recover(112, false);
check(defense.Execution.EmergencyLevel == 2 and defense.Execution.LandQueueTarget == 4,
    "second persistent window reaches the capped escalation");
equal(recover(200, false).EmergencyLevel, 2, "escalation does not grow without bound");
economy.Queue.Land, economy.Queue.Combat = 4, 4;
check(not recover(114, false).LandNeeded, "already queued land defenders consume the bounded budget");
check(not recover(114, true).EconomyAllowed, "fresh serious attrition still interrupts economic escalation");
economy.Queue.Land, economy.Queue.Combat = 0, 0;
economy.QueueOk = 0;
check(not recover(115, false).LandNeeded and not recover(115, false).EconomyAllowed,
    "unknown production does not justify parallel reinforcement assumptions");
economy.QueueOk = 1;
defense.Execution = recover(116, false);
local restored, partial = S.AssessDefenseOutcome(khmer, defense.Execution, 0, 0, 0);
check(not restored and not partial, "relative army-score improvement with zero land gain is not recovery");
restored, partial = S.AssessDefenseOutcome(khmer, defense.Execution, 0, 1, 0);
check(not restored and partial, "one new land defender is partial progress, not completed recovery");
restored, partial = S.AssessDefenseOutcome(khmer, defense.Execution, -1, 3, 0);
check(not restored and not partial, "city loss prevents false defensive success");
S.StartPlanReview(defense, khmer, khmerArmy, 116);
defense.StrategicPlanStallCount = 2;
defense.CompetitiveScores.Military = 1.2;
local retired = S.ReviewPlan(1, defense, khmer, khmerArmy, 122);
check(not retired and defense.StrategicPlanReviewTurn == 122,
    "T122 forced same DEFEND advances baseline without a futile retirement");
equal(defense.StrategicPlanStallCount, 3, "relative score alone does not reset persistent defense failures");
S.ReviewPlan(1, defense, khmer, khmerArmy, 124);
equal(defense.StrategicPlanReviewTurn, 122, "T124 does not re-review the stale T116 interval");
khmerArmy.LandUnits, khmerArmy.CombatUnits = 5, 9;
S.ReviewPlan(1, defense, khmer, khmerArmy, 128);
check(defense.StrategicPlanReviewTurn == 128 and defense.StrategicPlanBaselineLand == 5
    and defense.StrategicPlanStallCount == 3, "partial land recovery advances baseline without clearing failed-window history");
khmerArmy.LandUnits, khmerArmy.CombatUnits = 12, 18;
defense.Execution = recover(130, false);
check(not defense.Execution.Emergency and not defense.Execution.LandNeeded
    and defense.Execution.EmergencyLevel == 0, "real fielded recovery exits escalation");
check(S.AssessDefenseOutcome(khmer, defense.Execution, 0, 7, 0), "safe defense can be recognized as recovered");
khmer.ActiveMajorWars, khmer.MajorWars = 0, 0;
check(not recover(132, false).Emergency, "peace clears persistent emergency timer");
equal(properties.ASAI_EXEC_EMERGENCY_SINCE, -1, "cleared defense timer survives reload");

-- Babylon T128: capacity 6, two actual traders, no trader in flight. Never
-- use route-end transients or read-only UI data to order extra traders.
properties = {};
local babylon = { Cities = 14, RouteCapacity = 6, Traders = 2, InFlightTraders = 0 };
local function trader(turn, emergency, allowed)
    local result = E.EmptyStatus(turn);
    result.Emergency, result.EconomyAllowed = emergency or false, allowed ~= false;
    E.TraderBudget(player, babylon, economy, result, turn);
    return result;
end
equal(trader(100).TraderStage, "none", "trader deficit has its own persistence timer");
equal(trader(105).TraderStage, "none", "trader escalation waits six online turns");
local tradeStatus = trader(106);
check(tradeStatus.TraderStage == "candidate" and tradeStatus.TraderGap == 4
    and tradeStatus.TraderQueueTarget == 2, "six slots/two traders requests at most a two-trader pipeline");
babylon.InFlightTraders = 2;
equal(trader(107).TraderStage, "inflight", "queued traders stop extra preference before production completes");
babylon.Traders, babylon.InFlightTraders = 3, 1;
equal(trader(108).TraderAge, 0, "an actual new trader resets escalation age");
check(trader(114).TraderStage == "candidate", "a remaining persistent deficit can restart the bounded pipeline");
babylon.Traders, babylon.InFlightTraders = 6, 0;
check(trader(115).TraderStage == "none" and trader(115).TraderQueueTarget == 0,
    "all slots have traders: exit even if routes briefly end");
babylon.RouteCapacity = 4;
equal(trader(116).TraderGap, 0, "lost route capacity never creates a negative/extra trader order");
babylon.RouteCapacity, babylon.Traders = 6, 2;
trader(118);
check(trader(124, true).TraderQueueTarget == 1, "prolonged defense allows only one parallel trader");
equal(trader(124, true, false).TraderStage, "emergency", "acute threat preempts trader escalation");
economy.QueueOk = 0;
equal(trader(124).TraderStage, "unknown", "unknown queue cannot silently become zero pending traders");
economy.QueueOk = 1;

local originalStatus = E.GetStatus;
E.GetStatus = function() return { ScienceStage = "infrastructure", ScienceGoal = "university" }; end;
check(E.IsEducation(1) and not E.IsWriting(1) and not E.IsLaboratory(1),
    "university handoff activates only its specific facility strategy");
E.GetStatus = function() return { ScienceStage = "inflight", ScienceGoal = "university" }; end;
check(not E.IsEducation(1), "committed science budget suspends stage-specific weighting");
E.GetStatus = originalStatus;
equal(E.GetStatus(0).ScienceStage, "none", "human players do not enter the execution controller");

-- Context contract: Gameplay has CurrentlyBuilding but neither the UI hash
-- method nor a trusted CanProduce signature. Candidate fixtures have no Hash.
local savedInfo = env.GameInfo;
local function db(rows, key)
    local values = {};
    for index, row in ipairs(rows) do
        row.Index = row.Index or index;
        values[row.Index], values[row[key]] = row, row;
    end
    return setmetatable(values, { __call = function()
        local index = 0;
        return function() index = index + 1; return rows[index]; end;
    end });
end
local function members(items) return { Members = function() return ipairs(items); end }; end
env.GameInfo = setmetatable({
    Buildings = db({
        { BuildingType = "BUILDING_LIBRARY", PrereqTech = "TECH_WRITING", PrereqDistrict = "DISTRICT_CAMPUS" },
        { BuildingType = "BUILDING_UNIVERSITY", PrereqTech = "TECH_EDUCATION", PrereqDistrict = "DISTRICT_CAMPUS" },
        { BuildingType = "BUILDING_MARKET", PrereqTech = "TECH_CURRENCY", PrereqDistrict = "DISTRICT_COMMERCIAL_HUB" },
        { BuildingType = "BUILDING_LIGHTHOUSE", PrereqDistrict = "DISTRICT_HARBOR" }
    }, "BuildingType"),
    Districts = db({
        { DistrictType = "DISTRICT_CAMPUS", PrereqTech = "TECH_WRITING" },
        { DistrictType = "DISTRICT_COMMERCIAL_HUB", PrereqTech = "TECH_CURRENCY" },
        { DistrictType = "DISTRICT_HARBOR" },
        { DistrictType = "DISTRICT_SPACEPORT", PrereqTech = "TECH_ROCKETRY", Cost = 1800 }
    }, "DistrictType"),
    Units = db({
        { UnitType = "UNIT_ARCHER", Domain = "DOMAIN_LAND", PromotionClass = "PROMOTION_CLASS_RANGED", RangedCombat = 25 },
        { UnitType = "UNIT_FOREIGN_ARCHER", Domain = "DOMAIN_LAND", PromotionClass = "PROMOTION_CLASS_RANGED", RangedCombat = 30, TraitType = "TRAIT_FOREIGN" },
        { UnitType = "UNIT_CATAPULT", Domain = "DOMAIN_LAND", PromotionClass = "PROMOTION_CLASS_SIEGE", Bombard = 35, StrategicResource = "RESOURCE_IRON" },
        { UnitType = "UNIT_TRADER", MakeTradeRoute = true, PrereqCivic = "CIVIC_FOREIGN_TRADE" }
    }, "UnitType"),
    Projects = db({ { ProjectType = "PROJECT_LAUNCH_EARTH_SATELLITE", SpaceRace = true } }, "ProjectType"),
    BuildingReplaces = db({}, "CivUniqueBuildingType"),
    DistrictReplaces = db({}, "CivUniqueDistrictType"),
    UnitReplaces = db({ { CivUniqueUnitType = "UNIT_FOREIGN_ARCHER", ReplacesUnitType = "UNIT_ARCHER" } }, "CivUniqueUnitType"),
    BuildingPrereqs = db({ { Building = "BUILDING_UNIVERSITY", PrereqBuilding = "BUILDING_LIBRARY" } }, "Building"),
    Unit_BuildingPrereqs = db({}, "Unit"), MutuallyExclusiveBuildings = db({}, "Building"),
    ExcludedDistricts = db({ { DistrictType = "DISTRICT_HARBOR", TraitType = "TRAIT_NO_HARBOR" } }, "DistrictType"),
    CivilizationTraits = db({}, "CivilizationType"), LeaderTraits = db({}, "LeaderType"),
    Leaders = db({ { LeaderType = "LEADER_TEST", InheritFrom = "LEADER_BASE" } }, "LeaderType"),
    Resources = { RESOURCE_IRON = { Index = 0 } },
    Civics = { CIVIC_FOREIGN_TRADE = { Index = 1 } },
    Yields = { YIELD_PRODUCTION = { Index = 3 } }
}, { __index = savedInfo });
env.PlayerConfigurations[1] = { GetCivilizationTypeName = function() return "CIV_TEST"; end,
    GetLeaderTypeName = function() return "LEADER_TEST"; end };
local present, current, iron, civic = {}, nil, 1, true;
local city = { GetID = function() return 11; end, GetX = function() return 1; end,
    GetY = function() return 2; end, GetPopulation = function() return 7; end,
    GetYield = function() return 90; end,
    GetBuildings = function() return { HasBuilding = function(_, index) return present[index] == true; end }; end,
    GetBuildQueue = function() return { CurrentlyBuilding = function() return current; end }; end };
local districtComplete, districtPillaged = true, false;
local districts = {};
for _, index in ipairs({ 1, 2 }) do
    table.insert(districts, { GetType = function() return index; end,
        GetCity = function() return city; end,
        IsComplete = function() return districtComplete; end,
        IsPillaged = function() return districtPillaged; end });
end
player.GetCities = function() return members({ city }); end;
player.GetDistricts = function() return members(districts); end;
player.GetResources = function() return { GetResourceAmount = function() return iron; end }; end;
player.GetCulture = function() return { HasCivic = function() return civic; end }; end;
env.Map.GetPlot = function() return { GetIndex = function() return 10; end }; end;
E.Definitions = nil;
local function assets() return E.CollectAssets(player); end
local probe = assets();
check(E.CanBuild(probe, "trade_building"), "market candidate works with actual Gameplay boundary, no Hash/CanProduce");
equal(probe.BuildabilityOk, 1, "candidate sensor succeeds separately from final native legality");
equal(probe.CandidateCities.trade_building, 11, "candidate city is recorded for audit, not a forced order");
present[3] = true;
check(not E.CanBuild(assets(), "trade_building"), "existing market is not another route slot");
present[3] = false;
check(not E.CanBuild(assets(), "university"), "university requires a library in this city");
present[1] = true;
check(E.CanBuild(assets(), "university"), "owned education hands off to an existing campus library");
districtComplete = false;
check(not E.CanBuild(assets(), "university"), "unfinished district does not qualify for a university");
districtComplete, districtPillaged = true, true;
check(not E.CanBuild(assets(), "university"), "pillaged district is not a functioning prerequisite");
districtPillaged = false;
check(E.CanBuild(assets(), "ranged"), "generic ranged remains available despite foreign uniques");
probe = assets(); probe.Traits, probe.Leaders = { TRAIT_FOREIGN = true }, {};
check(not E.IsCandidate(probe, probe.Cities[1], E.GetDefinitions().ByType.UNIT_ARCHER), "owned unique replaces generic candidate");
check(E.IsCandidate(probe, probe.Cities[1], E.GetDefinitions().ByType.UNIT_FOREIGN_ARCHER), "eligible unique is preserved");
local foreignArcher = env.GameInfo.Units.UNIT_FOREIGN_ARCHER;
foreignArcher.TraitType, foreignArcher.LeaderType = nil, "LEADER_OTHER";
probe = assets();
check(E.IsCandidate(probe, probe.Cities[1], E.GetDefinitions().ByType.UNIT_ARCHER),
    "another leader's traitless unique must not suppress our generic unit");
check(not E.IsCandidate(probe, probe.Cities[1], E.GetDefinitions().ByType.UNIT_FOREIGN_ARCHER),
    "leader-specific unique still requires its actual leader");
foreignArcher.TraitType, foreignArcher.LeaderType = "TRAIT_FOREIGN", nil;
local archer = env.GameInfo.Units.UNIT_ARCHER;
archer.ObsoleteTech = "TECH_EDUCATION";
check(not E.CanBuild(assets(), "ranged"), "obsolete unit and foreign unique cannot create a fake candidate");
archer.ObsoleteTech = nil;
check(E.CanBuild(assets(), "siege"), "real siege role with resource access qualifies");
iron = 0;
check(not E.CanBuild(assets(), "siege"), "known zero stockpile prevents resource candidate");
iron = nil; probe = assets();
local available, reason = E.CanBuild(probe, "siege");
check(not available and reason == "unknown" and probe.BuildabilityOk == 0,
    "unreadable resource API is unknown rather than ordinary blocked");
check(E.CanBuild(probe, "ranged"), "one failing role cannot poison independent candidates");
iron = 1;
check(E.CanBuild(assets(), "trader"), "civilian trader has its own candidate role");
civic = false;
check(not E.CanBuild(assets(), "trader"), "trader civic prerequisite is respected");
civic = true;
current = "DISTRICT_SPACEPORT";
check(not E.CanBuild(assets(), "trade_building"), "economic candidates skip a city currently building a spaceport");
check(E.CanBuild(assets(), "ranged"), "immediate defense is not vetoed by a spaceport commitment");
current = "PROJECT_LAUNCH_EARTH_SATELLITE";
check(not E.CanBuild(assets(), "university"), "economic candidates skip actual space project cities");
current = nil;
probe = assets(); probe.Traits, probe.Leaders = { TRAIT_NO_HARBOR = true }, {};
check(not E.IsCandidate(probe, probe.Cities[1], E.GetDefinitions().ByType.DISTRICT_HARBOR), "trait-excluded district is filtered");

-- Real science collector: Rocketry -> first port -> satellite -> original
-- milestone chain, including reload, canceled projects and acute defense.
local science = upvalue(env.ASAI_IsScienceSatelliteExecution, "ScienceExecution");
equal(science.PreparationBudget(7, { 100, 80, 70 }, 900), 1,
    "Maori-sized empire does not request three pre-satellite ports");
equal(science.PreparationBudget(14, { 90, 80, 50 }, 900), 2,
    "large empire with two productive cores can support two first-stage ports");
equal(science.PreparationBudget(14, { 90, 30, 20 }, 900), 1,
    "city count alone cannot justify a slow second port");
equal(science.PreparationBudget(0, {}, 900), 0, "no-city civilization gets no port budget");
check(not science.IsPreparing(0, false, 14, true), "no Rocketry means no preparation strategy");
check(not science.IsPreparing(1, true, 14, true), "completed satellite hands off to the existing milestone chain");
check(not science.IsPreparing(0, true, 14, false), "disabled science victory does not start preparation");
savedInfo.Technologies.TECH_ROCKETRY = { Index = "TECH_ROCKETRY" };
owned.TECH_ROCKETRY = true;
local scienceSnapshot = { Cities = 7, ActiveMajorWars = 0, LastMajorCombatTurn = -1000 };
local realSnapshot = upvalue(science.Collect, "GetSnapshot", function() return scienceSnapshot; end);
local realPolicy = science.GetPolicyStatus;
science.GetPolicyStatus = function() return 0, 0; end;
properties = {}; now = 120; science.Cache = {};
local prepared = science.Collect(1);
check(prepared.Active and prepared.Preparing and prepared.Stage == 0
    and prepared.SpaceportTarget == 1, "Rocketry activates execution before any space milestone");
check(science.IsSpaceportScale(1) and not science.IsSatellite(1), "first port has an execution owner before it is built");
equal(prepared.ProgressAge, 0, "age since game start is not mislabeled as a space-project stall");
current = "DISTRICT_SPACEPORT"; now = 122;
prepared = science.Collect(1);
check(prepared.Preparing and prepared.SpaceportsInFlight == 1
    and not science.IsSpaceportScale(1) and science.IsPreparationBudgetReached(1),
    "one committed first port consumes the small-empire budget without cancellation");
equal(prepared.PreparationAge, 4, "preparation timer starts at observed unlock rather than turn zero");
science.Cache = {};
equal(science.Collect(1).PreparationAge, 4, "same-turn reload preserves preparation age");
current = nil;
table.insert(districts, { GetType = function() return 4; end, GetCity = function() return city; end,
    IsComplete = function() return true; end, IsPillaged = function() return districtPillaged; end });
now = 123;
check(science.IsSatellite(1), "completed usable first port hands off immediately to satellite priority");
districtPillaged, now = true, 124;
check(not science.IsSatellite(1) and not science.IsPreparationBudgetReached(1),
    "pillaged first port neither launches nor receives a repair-suppressing port budget penalty");
districtPillaged = false;
properties[S.PROPERTY] = S.DEFEND;
scienceSnapshot.ActiveMajorWars, scienceSnapshot.LastMajorCombatTurn, now = 1, 125, 125;
check(not science.IsSatellite(1) and science.Collect(1).Suspended,
    "real recent defensive combat suspends first satellite execution");
scienceSnapshot.ActiveMajorWars, now = 0, 126;
check(science.IsSatellite(1), "satellite preparation resumes after defensive interruption");
current, now = "PROJECT_LAUNCH_EARTH_SATELLITE", 127;
check(science.Collect(1).ActiveProjects == 1 and not science.IsSatellite(1),
    "already queued satellite consumes the project budget");
science.RecordProjectCompletion(1, 11, 1, true);
equal(science.GetProjectCount(player, "PROJECT_LAUNCH_EARTH_SATELLITE"), 0,
    "canceled project is never a fabricated milestone");
science.RecordProjectCompletion(1, 11, 1, false);
current, now = nil, 128;
prepared = science.Collect(1);
check(prepared.Stage == science.SATELLITE and not prepared.Preparing
    and science.IsMoon(1), "real satellite completion hands off to existing Moon strategy");
science.Cache = {};
check(science.Collect(1).Stage == science.SATELLITE and science.IsMoon(1),
    "completed project count and handoff survive same-turn reload");
equal(science.GetSpaceportTarget(science.EXOPLANET, 14), 3,
    "existing late-game laser scale target remains unchanged");
upvalue(science.Collect, "GetSnapshot", realSnapshot);
science.GetPolicyStatus = realPolicy;
env.GameInfo = savedInfo;

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
        GREAT_PERSON_CLASS_MUSICIAN = { Index = 3 } }, Units = { [1234] = { UnitType = "UNIT_BUILDER" },
        TRADER = { MakeTradeRoute = true } }, Buildings = {}, Districts = {}, Projects = {} },
    Players = {}, ContextPtr = { SetShutdown = function(self, fn) self.Shutdown = fn; end }
}, { __index = _G });
ui._G = ui;
local uiHash = 1234;
local uiCity = { GetID = function() return 11; end, GetX = function() return 4; end, GetY = function() return 5; end,
    GetTrade = function() return { GetOutgoingRoutes = function() return {
        { DestinationCityPlayer = 1, TraderUnitID = 9 } }; end }; end,
    GetBuildQueue = function() return { GetCurrentProductionTypeHash = function() return uiHash; end }; end };
local uiTotal = 1;
ui.Players[1] = { IsAlive = function() return true; end, IsMajor = function() return true; end,
    IsHuman = function() return false; end, GetID = function() return 1; end,
    GetProperty = function() return now; end,
    SetProperty = function() error("UI diagnostic attempted a game-state write"); end,
    GetCities = function() return members({ uiCity }); end,
    GetUnits = function() return members({ { GetID = function() return 9; end, GetType = function() return "TRADER"; end } }); end,
    GetTrade = function() return { GetNumOutgoingRoutes = function() return uiTotal; end }; end,
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
check(string.find(uiLogs[5], "completions_since_sample=1", 1, true) ~= nil, "completion evidence accompanies correct UI hash queue phase");
check(string.find(uiLogs[5], "current=UNIT_BUILDER", 1, true) ~= nil,
    "UI resolves an actual numeric production hash to the correct type");
uiEvents.PlayerTurnDeactivated.Callbacks[1](1);
uiEvents.PlayerTurnDeactivated.Callbacks[1](0);
uiEvents.GameCoreEventPublishComplete.Callbacks[1]();
equal(#uiLogs, 5, "duplicate callbacks and human turns do not create extra samples");
uiTotal, now = 0, 94;
uiEvents.PlayerTurnDeactivated.Callbacks[1](1);
uiEvents.GameCoreEventPublishComplete.Callbacks[1]();
check(string.find(uiLogs[#uiLogs - 2], "route_consistent=0 consensus_routes=-1", 1, true) ~= nil,
    "same turn but disagreeing route totals are not asserted as a true count");
uiTotal = 1;
uiEvents.GameCoreEventPublishComplete.Callbacks[1]();
check(string.find(uiLogs[#uiLogs], "same_turn=1 consensus_routes=1", 1, true) ~= nil,
    "one later publish can confirm a same-turn consistent reread");
local afterRetry = #uiLogs;
uiEvents.GameCoreEventPublishComplete.Callbacks[1]();
equal(#uiLogs, afterRetry, "route reread never becomes a polling loop");
uiTotal, now = 0, 96;
uiEvents.PlayerTurnDeactivated.Callbacks[1](1);
uiEvents.GameCoreEventPublishComplete.Callbacks[1]();
uiTotal, now = 1, 97;
uiEvents.GameCoreEventPublishComplete.Callbacks[1]();
check(string.find(uiLogs[#uiLogs], "same_turn=0 consensus_routes=-1", 1, true) ~= nil,
    "next-turn route state never backfills the earlier turn");
uiCity.GetTrade = nil;
now = 98;
uiEvents.PlayerTurnDeactivated.Callbacks[1](1);
uiEvents.GameCoreEventPublishComplete.Callbacks[1]();
check(string.find(table.concat(uiLogs, "\n"), "route_sensor_ok=0", 1, true) ~= nil, "missing UI route capability degrades independently");
check(string.find(uiLogs[#uiLogs - 1], "gpp_sensor_ok=1", 1, true) ~= nil, "culture sensor survives route failure");
uiHash, now = -1, 100;
uiEvents.PlayerTurnDeactivated.Callbacks[1](1);
uiEvents.GameCoreEventPublishComplete.Callbacks[1]();
check(string.find(uiLogs[#uiLogs], "current=none", 1, true) ~= nil,
    "negative empty production hash is a valid empty queue, not an interface failure");
ui.ContextPtr.Shutdown();
equal(#uiEvents.PlayerTurnDeactivated.Callbacks, 0, "UI shutdown removes handlers");

print(string.format("LUA REGRESSION PASSED: %d checks; real Lua functions, mocked game boundary", checks));
