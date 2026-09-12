-- Real gameplay callbacks with mocked engine delivery. These tests prove the
-- consumer, not that a particular native build will deliver every city event.
return function(check, equal, upvalue)
    local A, D, ID, UNIT, DISTRICT = 101, 102, 103, 21, 22;
    local function harness(eventMode)
        local h = { Turn = 100, Properties = {}, Wars = { [13] = true },
            Logs = {}, Held = false, Eliminated = false };
        local function events()
            return setmetatable({}, { __index = function(self, key)
                local event = { Callbacks = {} };
                event.Add = function(fn) table.insert(event.Callbacks, fn); end;
                rawset(self, key, event); return event;
            end });
        end
        local function player(id, major, human, free, barbarian)
            local props = {};
            h.Properties[id] = props;
            return {
                GetID = function() return id; end,
                IsMajor = function() return major == true; end,
                IsHuman = function() return human == true; end,
                IsFreeCities = function() return free == true; end,
                IsBarbarian = function() return barbarian == true; end,
                GetProperty = function(_, key) return props[key], "metadata"; end,
                SetProperty = function(_, key, value) props[key] = value; end,
                GetDiplomacy = function() return {
                    IsAtWarWith = function(_, other) return h.Wars[other] == true; end
                }; end,
                GetUnits = function() return { FindID = function(_, unitID)
                    if unitID == 999 then return nil; end -- already removed
                    return { GetType = function()
                        return unitID == 2 and "APOSTLE" or unitID == 4 and "SETTLER" or "WARRIOR";
                    end };
                end }; end,
                -- City result identities must survive an empty old-owner collection.
                GetDistricts = function() return { FindID = function() return nil; end }; end
            };
        end
        h.Env = setmetatable({
            print = function(text) table.insert(h.Logs, tostring(text)); end,
            GlobalParameters = { ASAI_ENABLE_METRICS = 1, ASAI_VERSION = "test" },
            CombatResultParameters = { ATTACKER = A, DEFENDER = D, ID = ID },
            ComponentType = { UNIT = UNIT, DISTRICT = DISTRICT },
            Game = { GetCurrentGameTurn = function() return h.Turn; end },
            GameConfiguration = { GetGameSpeedType = function() return "ONLINE"; end },
            GameInfo = { GameSpeeds = { ONLINE = { CostMultiplier = 50 } },
                Units = { WARRIOR = { Combat = 20 }, APOSTLE = { ReligiousStrength = 110 }, SETTLER = {} } },
            Players = { [3] = player(3, true), [1] = player(1, true), [0] = player(0, true, true),
                [13] = player(13), [14] = player(14), [62] = player(62, false, false, true),
                [63] = player(63, false, false, false, true) },
            PlayerManager = {
                IsAlive = function(id) return id ~= nil and not (id == 13 and h.Eliminated); end,
                GetAliveMajorIDs = function() return { 0, 1, 3 }; end,
                GetAliveIDs = function() return h.Eliminated and { 0, 1, 3, 14, 62, 63 }
                    or { 0, 1, 3, 13, 14, 62, 63 }; end
            },
            PlayerConfigurations = {},
            CityManager = { GetCityAt = function(x, y)
                if h.Held and x == 54 and y == 35 then return { GetOwner = function() return 3; end }; end
            end },
            Map = { GetPlotCount = function() error("combat sensor must not scan the map"); end }
        }, { __index = _G });
        h.Env._G = h.Env;
        h.Snapshot = { Cities = 12, MajorWars = 0 };
        h.Army = { Military = 870, CombatUnits = 15 };
        function h:Reload()
            self.Env.Events, self.Env.GameEvents = events(), events();
            if eventMode == "missing" then self.Env.Events.Combat = {};
            elseif eventMode == "throws" then
                self.Env.Events.Combat = { Add = function() error("unsupported event"); end };
            end
            assert(loadfile("Lua/AdaptiveStrategicAI.lua", "t", self.Env))();
            self.E = upvalue(self.Env.ASAI_IsScienceConstructionExecution, "Execution");
        end
        function h:Value(key, opponent, ai)
            return self.Properties[ai or 3][self.E.MinorKey(opponent or 13, key)];
        end
        function h:Result(a, at, aid, d, dt, did)
            self.Env.Events.Combat.Callbacks[1]({
                [A] = { [ID] = { player = a, type = at, id = aid } },
                [D] = { [ID] = { player = d, type = dt, id = did } }
            });
        end
        function h:Legacy(a, au, d, du, ad, dd)
            self.Env.GameEvents.OnCombatOccurred.Callbacks[1](a, au, d, du, ad, dd);
        end
        function h:Review()
            return self.E.UpdateMinorFronts(self.Env.Players[3], self.Snapshot, self.Army, self.Turn);
        end
        function h:City()
            self:Result(3, UNIT, 11, 13, DISTRICT, 65536);
        end
        h:Reload();
        return h;
    end

    local h = harness();
    equal(#h.Env.Events.Combat.Callbacks, 1, "actual result event is registered once");
    equal(#h.Env.GameEvents.OnCombatOccurred.Callbacks, 2, "legacy minor and defense observers stay registered");
    h:City();
    equal(h:Value("COMBAT_TURNS"), 1, "unit attacks a district absent from the old owner's collection");
    equal(h:Value("CITY_COMBAT_TURNS"), 1, "typed district is recognized without hardcoding type 3");
    h.Turn = 101;
    h:Result(13, DISTRICT, 65536, 3, UNIT, 11);
    equal(h:Value("COMBAT_TURNS"), 2, "city counterattack credits the defending major AI");
    h.Turn = 102;
    h:Result(3, DISTRICT, 65536, 13, DISTRICT, 65536);
    equal(h:Value("CITY_COMBAT_TURNS"), 3, "typed district identities do not confuse equal numeric object IDs");
    h.Turn = 103;
    h:Result(3, UNIT, 65536, 13, UNIT, 11);
    equal(h:Value("CITY_COMBAT_TURNS"), 3, "unit with a city-like numeric ID is not classified as a city");
    equal(h:Value("VERIFIED_COMBAT_TURNS"), 4, "military unit results also corroborate legacy receipts");
    h.Turn = 104;
    h:Result(3, UNIT, 999, 13, DISTRICT, 65536);
    equal(h:Value("COMBAT_TURNS"), 5, "destroyed attacker does not erase the event's surviving district identity");
    check(not table.concat(h.Logs, "\n"):find("ASAI_DIAGNOSTIC_ERROR", 1, true),
        "valid native-shaped payloads produce no diagnostic error");

    -- The exact 24 entity-pair rows from France/Palenque in the archived
    -- 2026-09-11 CombatLog, T107-114. Type enums are deliberately remapped.
    -- The old listener delivered only unit/unit rows in that run.
    local replay = {
        {107,3,13,UNIT,DISTRICT,7405570,65536},
        {107,3,13,UNIT,DISTRICT,5832705,65536},
        {107,3,13,UNIT,DISTRICT,6291461,65536},
        {107,13,3,UNIT,UNIT,1769473,6291461},
        {107,13,3,DISTRICT,UNIT,65536,6946842},
        {108,3,13,UNIT,DISTRICT,7405570,65536},
        {108,13,3,UNIT,UNIT,1769473,6553603},
        {108,13,3,DISTRICT,UNIT,65536,6553603},
        {109,3,13,UNIT,DISTRICT,7405570,65536},
        {109,13,3,DISTRICT,UNIT,65536,5832705},
        {110,3,13,UNIT,DISTRICT,7405570,65536},
        {110,3,13,UNIT,DISTRICT,5832705,65536},
        {110,13,3,UNIT,UNIT,1769473,7405570},
        {110,13,3,DISTRICT,UNIT,65536,6946842},
        {111,3,13,UNIT,DISTRICT,7405570,65536},
        {111,3,13,UNIT,DISTRICT,5832705,65536},
        {111,13,3,DISTRICT,UNIT,65536,5832705},
        {112,3,13,UNIT,DISTRICT,7405570,65536},
        {113,3,13,UNIT,DISTRICT,8192030,65536},
        {113,3,13,UNIT,UNIT,5832705,1703942},
        {113,13,3,UNIT,UNIT,1703942,5832705},
        {114,3,13,UNIT,DISTRICT,8192030,65536},
        {114,3,13,UNIT,DISTRICT,7405570,65536},
        {114,3,13,UNIT,DISTRICT,5832705,65536}
    };
    h = harness();
    local old = harness("missing");
    for turn = 107, 114 do
        h.Turn, old.Turn = turn, turn;
        for _, row in ipairs(replay) do
            if row[1] == turn then
                if row[4] == UNIT and row[5] == UNIT then
                    h:Legacy(row[2], row[6], row[3], row[7], -1, -1);
                    old:Legacy(row[2], row[6], row[3], row[7], -1, -1);
                end
                h:Result(row[2], row[4], row[6], row[3], row[5], row[7]);
            end
        end
        equal(h:Value("LAST_COMBAT"), turn, "replay contains actual combat on every T107-114 turn");
        equal(h:Review().SensorOk, 1, "complete typed receipts keep the replay review observable");
    end
    equal(#replay, 24, "replay preserves all 24 recorded France/Palenque combat rows");
    equal(old:Value("COMBAT_TURNS"), 4, "archived legacy delivery reproduces four recorded turns");
    equal(h:Value("COMBAT_TURNS"), 8, "dual delivery restores all eight distinct combat turns");
    equal(h:Value("CITY_COMBAT_TURNS"), 8, "the four missing city-only turns are included");
    equal(h:Value("VERIFIED_COMBAT_TURNS"), 8, "verified receipts are unique per pair and turn");
    check(not h:Review().StopLoss, "eight-turn capture window is not fabricated as two failed reviews");

    for _, resultFirst in ipairs({ false, true }) do
        h = harness();
        if resultFirst then h:City(); end
        h:Legacy(3, 11, 13, 11, -1, -1);
        if not resultFirst then h:City(); end
        for _ = 1, 20 do h:City(); h:Legacy(3, 11, 13, 11, -1, -1); end
        h.E.RecordMinorCapture(3, 13, 7, 54, 35);
        equal(h:Value("COMBAT_TURNS"), 1, "legacy/result/capture callback order cannot inflate combat turns");
        equal(h:Value("CITY_COMBAT_TURNS"), 1, "an earlier unit callback cannot hide later city activity");
        equal(h:Value("VERIFIED_COMBAT_TURNS"), 1, "capture and combat result share one verified turn");
        local _, logCount = table.concat(h.Logs, "\n"):gsub("ASAI_MINOR_COMBAT ", "");
        equal(logCount, 3, "duplicate delivery logs at most once for each unchanged source in the turn");
        h:Reload();
        h:City(); h:Legacy(3, 11, 13, 11, -1, -1); h.E.RecordMinorCapture(3, 13, 7, 54, 35);
        equal(h:Value("COMBAT_TURNS"), 1, "save/reload retains aggregate deduplication");
        equal(h:Value("VERIFIED_COMBAT_TURNS"), 1, "save/reload retains coverage deduplication");
        h.Wars[14] = true;
        h:Result(3, UNIT, 11, 14, DISTRICT, 65536);
        equal(h:Value("COMBAT_TURNS", 14), 1, "a different city-state gets its own same-turn activity");
    end

    h = harness();
    h.Wars[0], h.Wars[1], h.Wars[62], h.Wars[63] = true, true, true, true;
    for _, opponent in ipairs({ 0, 1, 62, 63 }) do
        h:Result(3, UNIT, 11, opponent, DISTRICT, 65536);
        equal(h:Value("COMBAT_TURNS", opponent), nil, "human/major/free-city/barbarian city fights are outside this sensor");
    end
    h:Result(0, UNIT, 11, 13, DISTRICT, 65536);
    h:Result(3, UNIT, 2, 13, UNIT, 2);
    h:Result(3, UNIT, 4, 13, UNIT, 4);
    h:Result(3, UNIT, 11, 3, DISTRICT, 65536);
    equal(h:Value("COMBAT_TURNS"), nil, "human, religious, civilian-only and same-owner results cannot create a front");
    h:Result(1, UNIT, 11, 13, DISTRICT, 65536);
    equal(h:Value("COMBAT_TURNS"), nil, "another AI's actual fight is not attributed to France");
    equal(h:Value("COMBAT_TURNS", 13, 1), 1, "the real participating AI gets its own receipt");
    h.Wars[13] = false;
    h:City();
    equal(h:Value("COMBAT_TURNS"), nil, "ordinary combat result requires an actual diplomatic war");
    h.Eliminated, h.Held = true, true;
    h.Env.GameEvents.CityConquered.Callbacks[2](3, 13, 7, 54, 35);
    equal(h:Value("COMBAT_TURNS"), 1, "confirmed last-city capture is recorded after elimination/peace");
    equal(h:Value("CITY_COMBAT_TURNS"), 1, "final conquest carries explicit city activity");
    equal(h:Review().Active, 0, "capture receipt cannot resurrect a finished war");
    check(h.E.HoldsMinorCapture(h.Env.Players[3], 13, 99), "the held-capture check still uses actual city ownership");
    h.Held = false;
    check(not h.E.HoldsMinorCapture(h.Env.Players[3], 13, 99), "a later lost city is not a continuing victory");

    -- Registration alone is not evidence of real engine delivery.
    for _, mode in ipairs({ "missing", "throws", "silent", "schema" }) do
        h = harness(mode);
        if mode == "schema" then h.Env.ComponentType = nil; end
        local front;
        for turn = 200, 212 do
            h.Turn = turn;
            h:Legacy(3, 11, 13, 11, -1, -1);
            front = h:Review();
        end
        check(not front.StopLoss and front.Rows[1].Stalls == 0,
            mode .. " result channel cannot turn incomplete observation into a stalled war");
        equal(front.SensorOk, 0, mode .. " result coverage is visibly unknown");
        equal(front.Rows[1].Reason, "combat_coverage_unknown", mode .. " fallback has an explicit reason");
    end
    h = harness();
    local front;
    for turn = 200, 218 do
        h.Turn = turn;
        h:Legacy(3, 11, 13, 11, -1, -1);
        if turn ~= 203 then h:City(); end
        front = h:Review();
        if turn == 206 then
            equal(front.Rows[1].Stalls, 0, "one missing interior turn invalidates the whole failed-review window");
            check(not front.StopLoss, "later valid receipts do not conceal an earlier observation gap");
        elseif turn == 212 then
            equal(front.Rows[1].Stalls, 1, "restored delivery starts a fresh complete failure window");
        end
    end
    check(front.StopLoss and front.Rows[1].Until == 230,
        "two subsequent fully covered reviews retain the existing bounded twelve-turn cooldown");
    h:Reload();
    check(h:Review().StopLoss, "existing justified cooldown survives reload");
    h.Wars[13] = false;
    equal(h:Review().Active, 0, "peace releases a fully observed front");

    -- A parse error invalidates its window even when valid events also arrive.
    h = harness();
    for turn = 300, 312 do
        h.Turn = turn; h:City();
        if turn == 303 then h:Result(3, 9999, 11, 13, UNIT, 11); h:Reload(); end
        front = h:Review();
        if turn == 306 then equal(front.Rows[1].Stalls, 0, "ambiguous typed identity persists as unknown across reload"); end
    end
    equal(front.Rows[1].Stalls, 1, "bad-payload protection expires after a clean new review window");
    h = harness();
    h.Env.Events.Combat.Callbacks[1](nil);
    h.Env.Events.Combat.Callbacks[1]({ [A] = {} });
    h.Env.Events.Combat.Callbacks[1]({ [A] = { [ID] = { player = 3, id = -1, type = UNIT } } });
    h:Result(3, UNIT, 999, 13, UNIT, 999);
    h.Env.CombatResultParameters = nil;
    h.E.OnMinorCombatResult({});
    equal(h:Value("COMBAT_TURNS"), nil, "malformed/unresolved results never fabricate activity");
    equal(h.Properties[3].ASAI_MINOR_RESULT_ERROR_TURN, h.Turn, "unattributable errors persist a conservative observation marker");
    check(table.concat(h.Logs, "\n"):find("fallback=unknown", 1, true) ~= nil,
        "missing fields are visible diagnostics, not swallowed success");
    h.Env.CombatResultParameters = { ATTACKER = A, DEFENDER = D, ID = ID };
    h.Turn = h.Turn + 1; h:City();
    equal(h:Value("COMBAT_TURNS"), 1, "a temporarily unavailable schema can recover without permanent disablement");
    local getUnits = h.Env.Players[3].GetUnits;
    h.Env.Players[3].GetUnits = function() error("injected unit lookup failure"); end;
    h.Turn = h.Turn + 1;
    h:City();
    equal(h:Value("COMBAT_TURNS"), 1, "engine-object error cannot count a partial combat result");
    check(table.concat(h.Logs, "\n"):find("injected unit lookup failure", 1, true) ~= nil,
        "callback failure is contained and retains its actual diagnostic error");
    h.Env.Players[3].GetUnits = getUnits;

    h = harness("silent");
    for turn = 500, 506 do
        h.Turn = turn; h:Legacy(3, 11, 13, 11, -1, -1);
        if turn == 506 then h.Army = { Military = 400, CombatUnits = 6 }; end
        front = h:Review();
    end
    check(front.StopLoss and front.Rows[1].Reason == "own_losses",
        "known serious own losses still permit bounded recovery when city coverage is unknown");
    h.Snapshot.MajorWars = 1;
    check(not h:Review().StopLoss, "major wars still veto global minor-front production restraint");

    h = harness();
    local props = h.Properties[3];
    props[h.E.MinorKey(13, "COMBAT_TURNS")] = 40;
    props[h.E.MinorKey(13, "LAST_COMBAT")] = 99;
    props[h.E.MinorKey(13, "REVIEW_TURN")] = 90;
    props[h.E.MinorKey(13, "BASE_EVENTS")] = 30;
    props[h.E.MinorKey(13, "STALLS")] = 1;
    h:City(); front = h:Review();
    check(not front.StopLoss and front.Rows[1].Stalls == 0,
        "old saves without new coverage baselines cannot immediately manufacture a second failed review");
    equal(h:Value("COMBAT_TURNS"), 41, "migration keeps existing activity counters instead of rewriting history");
end
