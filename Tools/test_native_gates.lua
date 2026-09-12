-- Execute the shipping Lua allocator against a deliberately delayed native
-- boundary model. The model covers the observed 20-turn hold and temporary
-- Forbidden veto, NOT the complete proprietary scheduler or city production.
return function(check, equal, upvalue)
    local now, logs, properties, evaluations = 1, {}, {}, 0;
    local wanted = {};
    local function events()
        return setmetatable({}, { __index = function(self, name)
            local event = { Add = function() end };
            rawset(self, name, event);
            return event;
        end });
    end
    local players = {};
    for id = 0, 5 do
        local p = id;
        properties[p] = {};
        players[p] = {
            IsMajor = function() return p ~= 5; end,
            IsHuman = function() return p == 0; end,
            GetProperty = function(_, name) return properties[p][name], "metadata"; end,
            SetProperty = function(_, name, value) properties[p][name] = value; end
        };
    end
    local env = setmetatable({
        print = function(text) logs[#logs + 1] = text; end,
        GlobalParameters = { ASAI_VERSION = "test", ASAI_ENABLE_METRICS = 1 },
        Game = { GetCurrentGameTurn = function() return now; end },
        GameInfo = {},
        PlayerManager = { IsAlive = function(id) return players[id] ~= nil; end },
        Players = players, Events = events(), GameEvents = events()
    }, { __index = function(_, key)
        if key ~= "_G" then return _G[key]; end
    end });
    local E;
    local function reload()
        env.Events, env.GameEvents = events(), events();
        assert(loadfile("Lua/AdaptiveStrategicAI.lua", "t", env))();
        E = upvalue(env.ASAI_IsLandRecovery, "Execution");
        -- This suite isolates the allocator. The environment suite separately
        -- exercises all shipping registered wrappers without replacing bindings.
        for family in ipairs(E.NativeGateCallbacks) do
            local f = family;
            E.NativeGateEvaluators[family] = function(player)
                evaluations = evaluations + 1;
                return wanted[player] and wanted[player][f] == true;
            end;
        end
    end
    reload();
    equal(E.NativeGateSlots, 12, "bounded spare identity count");
    equal(E.NativeGateReuseTurns, 22, "unscaled native cooldown plus phase margin");
    local function select(player, family, reverse)
        local active, count = 0, 0;
        for step = 1, E.NativeGateSlots do
            local slot = reverse and E.NativeGateSlots + 1 - step or step;
            local allowed = env.ASAI_IsNativeExecutionAllowed(player, family * 100 + slot);
            local blocked = env.ASAI_IsNativeExecutionBlocked(player, family * 100 + slot);
            assert(allowed == not blocked, "positive readiness and temporary veto must agree");
            if allowed and not blocked then
                active, count = slot, count + 1;
            end
        end
        assert(count <= 1, "one family must never contribute multiple copies");
        return active;
    end
    for _, invalid in ipairs({ -1, 0, 100, 113, 1801, 201.5, "garbage" }) do
        check(env.ASAI_IsNativeExecutionBlocked(1, invalid), "invalid slot fails closed: " .. tostring(invalid));
    end
    check(env.ASAI_IsNativeExecutionBlocked(0, 201), "human cannot acquire preferences");
    check(env.ASAI_IsNativeExecutionBlocked(5, 201), "minor cannot acquire preferences");
    check(env.ASAI_IsNativeExecutionBlocked(99, 201), "missing player cannot acquire preferences");

    -- The exact German ranged desire intervals in the archived T1-102 game.
    local oldActive, oldNext, oldEvents = false, 0, {};
    local native, mismatches, maxSlots = {}, 0, 0;
    local function updateNative(state, blocked, allowed)
        if blocked then
            if state.Active then state.Active, state.Next = false, now + 20; end
        elseif allowed and not state.Active and now >= state.Next then
            state.Active, state.Next = true, now + 20;
        end
    end
    local unloaded = { Active = false, Next = 0 };
    updateNative(unloaded, false, false);
    check(not unloaded.Active, "missing gameplay Lua cannot admit a slot when both native callbacks return false");
    local oldWrong, newWrong = {}, {};
    for turn = 1, 102 do
        now = turn;
        local desired = turn >= 46 and turn <= 53
            or turn >= 69 and turn <= 87 or turn >= 97;
        wanted[1] = { [2] = desired };
        if now >= oldNext and desired ~= oldActive then
            oldActive, oldNext = desired, now + 20;
            oldEvents[#oldEvents + 1] = turn;
        end
        if oldActive ~= desired then oldWrong[#oldWrong + 1] = turn; end
        local selected = select(1, 2, turn % 2 == 0);
        local following = 0;
        for slot = 1, 12 do
            native[slot] = native[slot] or { Active = false, Next = 0 };
            updateNative(native[slot], selected ~= slot, selected == slot);
            if native[slot].Active then following = following + 1; end
        end
        maxSlots = math.max(maxSlots, following);
        if (following == 1) ~= desired then newWrong[#newWrong + 1] = turn; end
        -- Reload at a release and at a subsequent re-entry; saved cooldown
        -- and same-turn selection must survive, not be reconstructed as new.
        if turn == 54 or turn == 69 or turn == 98 then
            local before = evaluations;
            reload();
            assert(select(1, 2, true) == selected, "reload cannot allocate twice");
            assert(evaluations == before, "same-turn reload does not resample demand");
        end
    end
    equal(table.concat(oldEvents, ","), "46,66,86", "old model reproduces actual native Following/Stopped turns");
    equal(#oldWrong, 38, "old path reproduces both delayed exits and delayed re-entry");
    equal(#newWrong, 0, "German 102-turn replay has no gate mismatch in the delayed boundary model");
    equal(maxSlots, 1, "re-entry never stacks preferences");
    check(#logs < 40, "slot queries do not multiply diagnostic output");

    -- Worst-case alternating requests and mixed simultaneous AI/families.
    -- Aggregate assertions rather than presenting every loop as an independent
    -- real-game test. Each native model keeps its own full 20-turn cooldown.
    properties, wanted, logs = {}, {}, {};
    for id = 0, 5 do properties[id] = {}; end
    reload();
    local states, lastSelections = {}, {};
    local start = os.clock();
    local before = evaluations;
    for turn = 1, 600 do
        now = turn;
        for player = 1, 4 do
            wanted[player] = {};
            states[player], lastSelections[player] = states[player] or {}, lastSelections[player] or {};
            for family = 1, #E.NativeGateCallbacks do
                -- One-turn bursts, long runs, and persistent inactive families.
                local desired = family % 3 == 0 and turn % 2 == player % 2
                    or family % 3 == 1 and (turn + player) % 41 < 29;
                wanted[player][family] = desired;
                local selected = select(player, family, (turn + family) % 2 == 0);
                local familyStates = states[player][family] or {};
                states[player][family] = familyStates;
                local following = 0;
                for slot = 1, 12 do
                    familyStates[slot] = familyStates[slot] or { Active = false, Next = 0 };
                    updateNative(familyStates[slot], slot ~= selected, slot == selected);
                    following = following + (familyStates[slot].Active and 1 or 0);
                end
                assert(following == (desired and 1 or 0), "native hold blocks a pooled request");
                local previous = lastSelections[player][family];
                if previous and previous > 0 and desired then
                    assert(selected == previous, "stable need must not churn slots");
                end
                lastSelections[player][family] = selected;
            end
        end
        if turn % 53 == 0 then reload(); end
    end
    equal(evaluations - before, 600 * 4 * 17, "each family scans demand only once per AI turn");
    check(true, "600-turn mixed replay: 4 AIs, 17 families, alternating requests, reloads, no stacking or gap");
    local elapsed = os.clock() - start;
    print(string.format("NATIVE GATE MODEL: 979200 slot calls in %.3fs; mocked boundary, not game frame timing", elapsed));

    now = 601;
    wanted[1] = { [2] = true };
    local beforeFailure = select(1, 2);
    check(beforeFailure > 0, "fault test begins with an admitted native identity");
    now = 602;
    E.NativeGateEvaluators[2] = function() error("injected collector error"); end;
    equal(select(1, 2), 0, "collector failure closes every spare slot");
    equal(select(1, 2, true), 0, "later callbacks cannot resurrect an errored family");
    now = 603;
    E.NativeGateEvaluators[2] = function() return true; end;
    local afterFailure = select(1, 2);
    check(afterFailure > 0 and afterFailure ~= beforeFailure,
        "transient failure retires the old slot before native cooldown-safe recovery");
    now = 604;
    properties[1].ASAI_GATE_2_SLOT = 99;
    equal(select(1, 2), 0, "corrupt saved slot fails closed");
    properties[1].ASAI_GATE_2_SLOT = 0;
    now = 605;
    players[1].SetProperty = function() error("injected property failure"); end;
    equal(select(1, 2), 0, "failed persistence cannot open multiple slots");
    equal(select(1, 2, true), 0, "partial write failure stays blocked for the turn");
end
