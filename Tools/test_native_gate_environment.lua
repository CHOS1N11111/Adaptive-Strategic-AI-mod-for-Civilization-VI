-- Load the complete shipping script without assuming that the host exposes _G.
-- Only demand collectors and game APIs are mocked; registered condition
-- wrappers, stored callback bindings, slot allocation and reloads stay real.
return function(check, equal, upvalue)
    for _, mode in ipairs({ "missing", "poisoned" }) do
        local now, logs, props, players, wanted, evaluations = 116, {}, {}, {}, true, 0;
        local globalReads = 0;
        for id = 1, 4 do
            local playerID = id;
            props[id] = {};
            players[id] = {
                IsMajor = function() return true; end,
                IsHuman = function() return false; end,
                GetProperty = function(_, key) return props[playerID][key], "metadata"; end,
                SetProperty = function(_, key, value) props[playerID][key] = value; end
            };
        end
        local function events()
            return setmetatable({}, { __index = function(self, name)
                local event = { Callbacks = {} };
                event.Add = function(fn) event.Callbacks[#event.Callbacks + 1] = fn; end;
                rawset(self, name, event);
                return event;
            end });
        end
        local poison = setmetatable({}, { __index = function()
            error("host global lookup must not be used");
        end });
        local env = setmetatable({
            print = function(text) logs[#logs + 1] = tostring(text); end,
            GlobalParameters = { ASAI_ENABLE_METRICS = 1, ASAI_VERSION = "test" },
            Game = { GetCurrentGameTurn = function() return now; end },
            GameInfo = {}, Players = players,
            PlayerManager = { IsAlive = function(id) return players[id] ~= nil; end }
        }, { __index = function(_, key)
            if key == "_G" then
                globalReads = globalReads + 1;
                if mode == "poisoned" then return poison; end
                return nil;
            end
            return _G[key];
        end });
        local E, allowed, blocked;
        local function reload()
            env.Events, env.GameEvents = events(), events();
            assert(loadfile("Lua/AdaptiveStrategicAI.lua", "t", env))();
            E = upvalue(env.ASAI_IsLandRecovery, "Execution");
            local science = upvalue(env.ASAI_IsScienceCapacityExecution, "ScienceExecution");
            local collectors = {
                { E, "IsLandRecovery" }, { E, "IsRanged" },
                { E, "IsWriting" }, { E, "IsEducation" },
                { E, "IsLaboratory" }, { E, "IsScienceConstruction" },
                { E, "IsScienceProductionShare" }, { science, "IsCapacity" },
                { E, "IsMinorFrontRecovery" }, { E, "IsCampusDemand" },
                { E, "IsAntiCavalryDemand" }, { E, "IsUrgentLand" },
                { E, "IsCampusSlotPressure" }, { science, "IsOrbitalDemand" },
                { science, "IsTerrestrialDemand" }, { science, "IsPowerDemand" },
                { science, "IsPortHandoff" }
            };
            for _, entry in ipairs(collectors) do
                entry[1][entry[2]] = function()
                    evaluations = evaluations + 1;
                    if wanted == "error" then error("injected demand collector failure"); end
                    return wanted;
                end;
            end
            allowed = env.GameEvents.ASAI_IsNativeExecutionAllowed.Callbacks[1];
            blocked = env.GameEvents.ASAI_IsNativeExecutionBlocked.Callbacks[1];
            assert(type(allowed) == "function" and type(blocked) == "function");
        end
        local function select(player, family)
            local selected, count = 0, 0;
            for slot = 1, 12 do
                local token = family * 100 + slot;
                local yes, no = allowed(player, token), blocked(player, token);
                assert(yes == not no, "registered allow/veto polarity must agree");
                if yes then selected, count = slot, count + 1; end
            end
            assert(count <= 1, "one active identity per family");
            return selected;
        end
        reload();
        -- Keep this first: the unmodified 0.11.21 script fails here at line8785,
        -- not merely because it lacks a newly named dispatch-table field.
        equal(select(1, 1), 1, mode .. " _G: registered gate admits the first request; "
            .. tostring(logs[#logs]));
        for family, name in ipairs(E.NativeGateCallbacks) do
            check(E.NativeGateEvaluators[family] == env.GameEvents[name].Callbacks[1],
                mode .. " _G: binds the actual registered callback " .. name);
        end
        for player = 1, 4 do
            for family = 1, 17 do
                assert(select(player, family) == 1, "all families admit the initial request");
            end
        end
        equal(evaluations, 68, mode .. " _G: each registered family evaluates once per AI turn");
        now, wanted = 117, false;
        for player = 1, 4 do
            for family = 1, 17 do
                assert(select(player, family) == 0, "false demand releases every family");
                assert(props[player]["ASAI_GATE_" .. family .. "_REUSE_1"] == 139,
                    "release preserves the native cooldown");
            end
        end
        check(true, mode .. " _G: all 68 families release with the existing 22-turn reuse guard");
        now, wanted = 118, true;
        for player = 1, 4 do
            for family = 1, 17 do
                assert(select(player, family) == 2, "re-entry uses a fresh identity");
            end
        end
        local before = evaluations;
        reload();
        for player = 1, 4 do
            for family = 1, 17 do
                assert(select(player, family) == 2, "same-turn reload preserves selection");
            end
        end
        equal(evaluations, before, mode .. " _G: reload neither reallocates nor resamples");
        now, wanted = 119, "error";
        for player = 1, 4 do
            for family = 1, 17 do
                assert(select(player, family) == 0, "collector errors safely release every family");
            end
        end
        local failures = 0;
        for _, text in ipairs(logs) do
            if text:find("ASAI_ERROR", 1, true) then failures = failures + 1; end
            assert(not text:find("condition=ASAI_IsNativeExecutionBlocked", 1, true),
                "dispatch must not produce the original gate error");
        end
        equal(failures, 17, mode .. " _G: errors are isolated and reported once per failing collector");
        now, wanted = 120, true;
        for player = 1, 4 do
            for family = 1, 17 do
                assert(select(player, family) == 3, "recovered collectors use a cooldown-safe identity");
            end
        end
        check(true, mode .. " _G: every family recovers after a collector error without stacking");
        equal(globalReads, 0, mode .. " _G: full script and registered gates never consult _G");
    end
end
