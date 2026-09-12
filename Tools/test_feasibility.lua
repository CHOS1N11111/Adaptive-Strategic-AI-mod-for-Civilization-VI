-- Real production Lua at mocked engine boundaries. This cannot emulate the
-- native strategy scheduler, district placement or actual city orders.
return function(check, equal, upvalue)
    local now, properties, known, atWar, logs = 132, {}, {}, false, {};
    local function events()
        return setmetatable({}, { __index = function(t, key)
            local event = { Callbacks = {} };
            event.Add = function(fn) table.insert(event.Callbacks, fn); end;
            rawset(t, key, event); return event;
        end });
    end
    local function db(rows, field)
        local result = {};
        for i, row in ipairs(rows) do
            row.Index = row.Index or i;
            result[row[field]], result[row.Index] = row, row;
        end
        return setmetatable(result, { __call = function()
            local i = 0; return function() i = i + 1; return rows[i]; end;
        end });
    end
    local function members(rows) return { Members = function() return ipairs(rows); end }; end
    local player = {
        GetID = function() return 1; end, IsMajor = function() return true; end,
        IsHuman = function() return false; end,
        GetProperty = function(_, key) return properties[key], "metadata"; end,
        SetProperty = function(_, key, value) properties[key] = value; end,
        GetDiplomacy = function() return { IsAtWarWith = function() return atWar; end }; end,
        GetTechs = function() return { HasTech = function(_, name) return known[name] == true; end }; end,
        GetCulture = function() return { HasCivic = function() return true; end }; end,
        GetResources = function() return { GetResourceAmount = function() return 0; end }; end
    };
    local env = setmetatable({
        print = function(line) table.insert(logs, line); end,
        GlobalParameters = { ASAI_ENABLE_METRICS = 1, ASAI_VERSION = "test" },
        Game = { GetCurrentGameTurn = function() return now; end },
        GameConfiguration = { GetGameSpeedType = function() return "ONLINE"; end },
        Players = { [1] = player, [0] = { IsMajor = function() return true; end,
            IsHuman = function() return true; end } },
        PlayerManager = { IsAlive = function(id) return id == 0 or id == 1; end,
            GetAliveMajorIDs = function() return { 0, 1 }; end },
        PlayerConfigurations = { [1] = { GetCivilizationTypeName = function() return "CIV_TEST"; end,
            GetLeaderTypeName = function() return "LEADER_TEST"; end } },
        GameInfo = { GameSpeeds = { ONLINE = { CostMultiplier = 50 } },
            Eras = { ERA_INDUSTRIAL = { Index = 4 } }, Technologies = {},
            Buildings = db({}, "BuildingType"), Districts = db({}, "DistrictType"),
            Units = db({}, "UnitType"), Projects = {}, Yields = { YIELD_PRODUCTION = { Index = 3 } },
            BuildingReplaces = db({}, "ReplacesBuildingType"), DistrictReplaces = db({}, "ReplacesDistrictType"),
            UnitReplaces = db({}, "ReplacesUnitType"), UnitUpgrades = db({}, "Unit"),
            BuildingPrereqs = db({}, "Building"), Unit_BuildingPrereqs = db({}, "Unit"),
            MutuallyExclusiveBuildings = db({}, "Building"), ExcludedDistricts = db({}, "DistrictType"),
            CivilizationTraits = db({}, "CivilizationType"), LeaderTraits = db({}, "LeaderType"),
            Leaders = {}, Resources = { RESOURCE_IRON = { Index = 1 }, RESOURCE_ALUMINUM = { Index = 2 } } },
        GameEvents = events(), Events = events(), Map = {}
    }, { __index = _G });
    env._G = env;
    assert(loadfile("Lua/AdaptiveStrategicAI.lua", "t", env))();
    local E = upvalue(env.ASAI_IsLandRecovery, "Execution");
    local SC = upvalue(env.ASAI_IsScienceLaserExecution, "ScienceExecution");
    do
        local condition = upvalue(env.ASAI_IsMilitaryExecutionRecovery, "IsMilitaryExecutionRecovery");
        local status = upvalue(condition, "GetMilitaryExecutionStatus");
        local target = upvalue(status, "GetMilitaryQueueTarget");
        local strategic = upvalue(E.RecoveryBudget, "Strategic");
        local policy = { Execution = { Land = 20, Emergency = false, RecentAttrition = false },
            ScienceCapacity = { Active = true, HoldWar = false },
            StrategicPlanCooldownUntil = { [strategic.WAR] = -1 } };
        local snapshot = { Cities = 17, Turn = 140, ActiveMajorWars = 0, MajorWars = 0 };
        equal(target(snapshot, policy), 2, "safe science finish reduces only the Mod's ordinary recruitment budget to ten percent");
        snapshot.ActiveMajorWars, snapshot.MajorWars = 1, 1;
        equal(target(snapshot, policy), 8, "a new active major war cannot inherit the peaceful finish budget");
        policy.ScienceCapacity.HoldWar = true;
        policy.StrategicPlanCooldownUntil[strategic.WAR] = 150;
        equal(target(snapshot, policy), 2, "verified war stop-loss with a healthy army releases production for science");
        policy.Execution.Emergency = true;
        equal(target(snapshot, policy), 5, "military emergency cancels the science-specific recruitment cap");
        policy.Execution.Emergency, policy.Execution.Land = false, 2;
        equal(target(snapshot, policy), 5, "aircraft-heavy forces with too little land cover cannot be called healthy");
    end

    -- All migrated positive callback dispatchers must be re-entrant, not
    -- one-shot vetoes. Native engine re-entry is tested separately in-game.
    local gates = {
        { E, "IsLandRecovery", "ASAI_IsLandRecovery" },
        { E, "IsRanged", "ASAI_IsRangedReinforcement" },
        { E, "IsWriting", "ASAI_IsWritingPrerequisite" },
        { E, "IsEducation", "ASAI_IsEducationPrerequisite" },
        { E, "IsLaboratory", "ASAI_IsLaboratoryPrerequisite" },
        { E, "IsScienceConstruction", "ASAI_IsScienceConstructionExecution" },
        { E, "IsScienceProductionShare", "ASAI_IsScienceProductionShareExecution" },
        { SC, "IsCapacity", "ASAI_IsScienceCapacityExecution" },
        { E, "IsMinorFrontRecovery", "ASAI_IsMinorFrontRecoveryExecution" },
        { E, "IsCampusDemand", "ASAI_IsCampusDemand" },
        { E, "IsAntiCavalryDemand", "ASAI_IsAntiCavalryDemand" }
    };
    for _, gate in ipairs(gates) do
        local owner, key, name = table.unpack(gate);
        local original = owner[key];
        local callback = assert(env[name], name);
        equal(env.GameEvents[name].Callbacks[1], callback, name .. " registered");
        for _, value in ipairs({ false, true, false, true }) do
            now = now + 1;
            owner[key] = function() return value; end;
            equal(callback(1), value, name .. " off/on/off/on follows current evaluation");
        end
        owner[key] = function() error("temporary condition failure"); end;
        check(not callback(1), name .. " fails closed without disqualifying later requests");
        owner[key] = function() return true; end;
        now = now + 1;
        check(callback(1), name .. " recovers after a transient error");
        owner[key] = original;
    end
    check(not env.ASAI_IsRetiredStrategy(1), "old saved identity stays inert");
    check(not env.ASAI_IsUrgentLandDemand(0), "human never receives urgent production preferences");
    check(not env.ASAI_IsCampusSlotPressure(0), "human never receives campus preferences");
    check(not env.ASAI_IsOrbitalLaserDemand(0), "human never receives laser preferences");
    local before = #logs;
    E.TraceCondition("ASAI_IsLandRecovery", 1, false);
    E.TraceCondition("ASAI_IsLandRecovery", 1, true);
    E.TraceCondition("ASAI_IsLandRecovery", 1, true);
    now = now + 1;
    E.TraceCondition("ASAI_IsLandRecovery", 1, true);
    equal(#logs - before, 3, "trace records same-turn changes and next-turn reevaluation, deduplicates only duplicates");

    local units = {};
    for i, spec in ipairs({
        { "UNIT_PIKEMAN", 45, "TACTICS" }, { "UNIT_PIKE_AND_SHOT", 55, "METAL" },
        { "UNIT_AT_CREW", 75, "CHEMISTRY" }, { "UNIT_MODERN_AT", 85, "COMPOSITES" }
    }) do
        table.insert(units, { UnitType = spec[1], Combat = spec[2], PrereqTech = spec[3],
            PromotionClass = "PROMOTION_CLASS_ANTI_CAVALRY", Domain = "DOMAIN_LAND" });
        env.GameInfo.Technologies[spec[3]] = { Index = spec[3] };
        known[spec[3]] = true;
    end
    env.GameInfo.Units = db(units, "UnitType");
    env.GameInfo.UnitUpgrades = db({
        { Unit = "UNIT_PIKEMAN", UpgradeUnit = "UNIT_PIKE_AND_SHOT" },
        { Unit = "UNIT_PIKE_AND_SHOT", UpgradeUnit = "UNIT_AT_CREW" },
        { Unit = "UNIT_AT_CREW", UpgradeUnit = "UNIT_MODERN_AT" }
    }, "Unit");
    local function city(id, pop)
        return { GetID = function() return id; end, GetPopulation = function() return pop; end,
            GetBuildings = function() return { HasBuilding = function() return false; end }; end };
    end
    local function assets(rows)
        return { Player = player, Cities = rows, Traits = {}, Leaders = {}, Probes = {},
            ProbeReasons = {}, CandidateCities = {}, CandidateTypes = {}, Counts = {}, Queued = {} };
    end
    local row = { City = city(1, 10), Placed = {}, Unfinished = {}, Districts = {}, Production = 100 };
    E.Definitions = nil;
    local definitions = E.GetDefinitions();
    local a = assets({ row });
    check(E.CanBuild(a, "anticavalry"), "France modern anti-cavalry candidate exists");
    equal(a.CandidateTypes.anticavalry, "UNIT_MODERN_AT", "modern counter is preferred over first database-row pikeman");
    check(not E.IsCandidate(assets({row}), row, definitions.ByType.UNIT_PIKEMAN),
        "available successor chain invalidates an old unit without MandatoryObsoleteTech");
    known.METAL, known.CHEMISTRY = false, false;
    check(not E.IsCandidate(assets({row}), row, definitions.ByType.UNIT_PIKEMAN),
        "unlocked final successor is found past locked intermediate techs");
    known.COMPOSITES = false;
    check(E.IsCandidate(assets({row}), row, definitions.ByType.UNIT_PIKEMAN),
        "earlier unit remains a fallback before all successors unlock");
    known.COMPOSITES = true;
    units[4].TraitType = "TRAIT_FOREIGN";
    check(E.IsCandidate(assets({row}), row, definitions.ByType.UNIT_PIKEMAN),
        "foreign unique successor cannot obsolete our fallback");
    units[4].TraitType, units[4].StrategicResource = nil, "RESOURCE_IRON";
    check(E.IsCandidate(assets({row}), row, definitions.ByType.UNIT_PIKEMAN),
        "zero strategic resources do not falsely establish a trainable successor");
    units[4].StrategicResource = nil;
    known.COMPOSITES = false;
    definitions.Upgrades.UNIT_MODERN_AT = { "UNIT_PIKEMAN" };
    check(E.IsCandidate(assets({row}), row, definitions.ByType.UNIT_PIKEMAN),
        "a modded cyclic upgrade chain terminates safely");

    local campus = { DistrictType = "DISTRICT_CAMPUS", RequiresPopulation = true };
    env.GameInfo.Districts = db({ campus,
        { DistrictType = "DISTRICT_AERODROME", RequiresPopulation = true },
        { DistrictType = "DISTRICT_ENCAMPMENT", RequiresPopulation = true }
    }, "DistrictType");
    E.Definitions = nil;
    local crowded = { City = city(20, 4), Placed = { DISTRICT_AERODROME = true, DISTRICT_ENCAMPMENT = true },
        Districts = {}, Unfinished = {}, Production = 200 };
    local open = { City = city(21, 10), Placed = {}, Districts = {}, Unfinished = {}, Production = 100 };
    a = assets({ crowded, open });
    check(E.CanBuild(a, "campus"), "campus candidate survives missing UI-only slot APIs");
    equal(a.CandidateCities.campus, 21, "likely open city is preferred over the high-production estimated-full city");
    check(not E.DistrictCapacity(crowded).Known, "population estimate is not asserted to include traits or great people");
    check(E.CanBuild(assets({ crowded }), "campus"),
        "estimated full city may have an extra district allowance and is not categorically rejected");
    crowded.Unfinished.DISTRICT_CAMPUS, crowded.Placed.DISTRICT_CAMPUS = true, true;
    a = assets({ open, crowded });
    check(E.CanBuild(a, "campus"), "placed unfinished campus can resume without a new slot");
    equal(a.CandidateCities.campus, 20, "unfinished campus remains ahead of fresh high-quality foundations");
    crowded.Unfinished, crowded.Placed.DISTRICT_CAMPUS = {}, nil;
    now = 140;
    properties = { ASAI_SCIENCE_BUILD_ROLE = "campus", ASAI_SCIENCE_BUILD_CITY = 20,
        ASAI_SCIENCE_BUILD_SINCE = 132, ASAI_SCIENCE_BUILD_COUNT = 4 };
    a = assets({ crowded, open }); a.Counts.campus, a.Queued.campus = 4, 0;
    E.RefreshCampusRetry(player, a, 0, now);
    equal(properties.ASAI_CAMPUS_RETRY_UNTIL_20, nil, "unknown queues cannot accumulate no-order failures");
    a.Queued.campus = 1;
    E.RefreshCampusRetry(player, a, 1, now);
    equal(properties.ASAI_CAMPUS_RETRY_UNTIL_20, nil, "observed campus queue prevents candidate cooldown");
    a.Queued.campus = 0; a.Counts.campus = 5;
    E.RefreshCampusRetry(player, a, 1, now);
    equal(properties.ASAI_CAMPUS_RETRY_UNTIL_20, nil, "infrastructure growth prevents a false stall");
    a.Counts.campus = 4;
    E.RefreshCampusRetry(player, a, 1, now);
    equal(properties.ASAI_CAMPUS_RETRY_UNTIL_20, 148, "two Online reviews without orders create an eight-turn local cooldown");
    check(not E.CanBuild(assets({crowded}), "campus"), "cooldown avoids repeatedly nominating the same stalled foundation");
    now = 148;
    check(E.CanBuild(assets({crowded}), "campus"), "cooldown expires rather than permanently denying expansion");
    local originalCanBuild, originalTech = E.CanBuild, E.HasTech;
    E.CanBuild = function(_, role) return role == "laboratory"; end;
    a.Counts = { campus = 4, library = 4, university = 4, laboratory = 0 };
    local stage, role = E.ScienceFallback(a, 10, 5);
    equal(stage, "infrastructure", "blocked foundations can redirect to existing infrastructure");
    equal(role, "laboratory", "research labs are not starved behind a permanently blocked campus request");
    E.CanBuild = function() return false; end;
    E.HasTech = function() return false; end;
    equal(E.ScienceFallback(a, 10, 1), "blocked", "early slot trouble does not demand industrial Chemistry");
    equal(E.ScienceFallback(a, 10, 5), "laboratory_tech", "industrial infrastructure can request its missing prerequisite");
    E.CanBuild, E.HasTech = originalCanBuild, originalTech;

    local input = { Active = true, Emergency = false, Attrition = false, Offworld = true,
        Ports = 4, PowerReady = 1, PowerUnknown = 0, PowerShort = 3, Queued = 0,
        Aluminum = 0, Cost = 15, Coordinate = true };
    local laser = SC.DecideLaser(input);
    equal(laser.Preferred, "terrestrial", "Australia aluminum-zero / spare power chooses a terrestrial preference");
    check(laser.Target == 1 and laser.Handoff, "one measured powered port creates a bounded native production handoff");
    input.PowerReady, input.Aluminum = 0, 15;
    equal(SC.DecideLaser(input).Preferred, "orbital", "Online aluminum cost 15 is sufficient, not raw database cost 30");
    input.Aluminum = 14;
    laser = SC.DecideLaser(input);
    check(laser.Preferred == "none" and laser.PowerNeeded, "insufficient aluminum and measured power shortfall request power");
    input.PowerUnknown, input.PowerShort = 4, 0;
    laser = SC.DecideLaser(input);
    equal(laser.Reason, "aluminum_short_power_unverified", "unknown power keeps an explicitly tentative native alternative");
    input.Aluminum = -1;
    check(not SC.DecideLaser(input).Handoff, "unknown resources cannot promise a feasible handoff");
    input.PowerUnknown, input.Aluminum, input.Queued = 0, 0, 2;
    check(not SC.DecideLaser(input).Handoff, "two actual inflight lasers consume the bounded target");
    input.PowerReady, input.Queued = 1, 0;
    check(SC.DecideLaser(input).Handoff, "after completion the next needed laser is reconsidered, not declared finished");
    input.Aluminum, input.PowerReady = 1000, 0;
    equal(SC.DecideLaser(input).Target, 3, "laser handoff cannot take more than three port slots");
    for _, field in ipairs({ "Emergency", "Attrition" }) do
        input[field] = true;
        check(not SC.DecideLaser(input).Handoff, field .. " takes precedence over science coordination");
        input[field] = false;
    end
    input.Offworld = false;
    equal(SC.DecideLaser(input).Reason, "offworld_locked", "laser prerequisites are not bypassed");
    input.Offworld, input.Active = true, false;
    equal(SC.DecideLaser(input).Target, 0, "inactive victory execution has no laser demand");

    -- Read-only adapters use actual production functions, with a controllable
    -- mock for an absent Gameplay power capability.
    env.GameInfo.Project_ResourceCosts = db({ { ProjectType = "PROJECT_ORBITAL_LASER",
        ResourceType = "RESOURCE_ALUMINUM", StartProductionCost = 30 } }, "ProjectType");
    env.GameInfo.ProjectCompletionModifiers = db({
        { ProjectType = "PROJECT_TERRESTRIAL_LASER", ModifierId = "EXTRA_POWER" },
        { ProjectType = "PROJECT_TERRESTRIAL_LASER", ModifierId = "SCIENCE_VP" }
    }, "ModifierId");
    env.GameInfo.Modifiers = { EXTRA_POWER = { ModifierType = "MODIFIER_SINGLE_CITY_ADJUST_REQUIRED_POWER" },
        SCIENCE_VP = { ModifierType = "MODIFIER_PLAYER_ADJUST_SCIENCE_VICTORY_POINTS_PER_TURN" } };
    env.GameInfo.ModifierArguments = db({ { ModifierId = "EXTRA_POWER", Name = "Amount", Value = "5" } }, "ModifierId");
    equal(SC.LaserRules().Aluminum, 30, "resource-rule reader derives orbital base cost from its own project table");
    equal(SC.LaserRules().Power, 5, "resource-rule reader isolates the required-power completion modifier");
    local stock, powerAvailable = 0, true;
    local portCity = { GetID = function() return 31; end, GetYield = function() return 180; end,
        GetBuildQueue = function() return { CurrentlyBuilding = function() return "UNIT_MODERN_AT"; end }; end,
        GetPower = function()
            if not powerAvailable then error("unavailable gameplay power"); end
            return { GetFreePower = function() return 9; end,
                GetTemporaryPower = function() return 0; end, GetRequiredPower = function() return 0; end };
        end };
    env.GameInfo.Districts.DISTRICT_SPACEPORT = { DistrictType = "DISTRICT_SPACEPORT" };
    player.GetDistricts = function() return members({
        { GetType = function() return "DISTRICT_SPACEPORT"; end,
            IsComplete = function() return true; end, IsPillaged = function() return false; end,
            GetCity = function() return portCity; end }
    }); end;
    player.GetResources = function() return { GetResourceAmount = function() return stock; end }; end;
    SC.Collect = function() return { Active = true, Stage = SC.EXOPLANET }; end;
    SC.IsCapacity = function() return true; end;
    E.GetStatus = function() return { Emergency = false, RecentAttrition = false }; end;
    E.HasTech = function() return true; end;
    now = 160;
    laser = SC.GetLaserStatus(1);
    equal(laser.Input.Cost, 15, "live adapter scales the database laser resource cost for Online");
    equal(laser.Preferred, "terrestrial", "adapter measures current port power before selecting the resource-free laser");
    now, stock, powerAvailable = 162, 15, false;
    laser = SC.GetLaserStatus(1);
    equal(laser.Preferred, "orbital", "missing power capability does not erase a known affordable orbital option");
    equal(laser.Input.PowerUnknown, 1, "unavailable Gameplay power is explicitly unknown, not zero power");
    now, stock = 164, 0;
    equal(SC.GetLaserStatus(1).Reason, "aluminum_short_power_unverified",
        "a zero-stock save keeps an honest tentative terrestrial fallback when power is UI-only");
end
