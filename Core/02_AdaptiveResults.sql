-- Bounded result support for sustained catch-up on Deity.
-- Gameplay Lua attaches the positive ledger entry when a support tier begins
-- and the exact inverse when it ends. Civ VI does not expose a modifier detach
-- API, so paired stackable entries keep the net effect at either this cap or 0.

DELETE FROM ModifierArguments
WHERE ModifierId IN (
    'ASAI_MILD_RESULT_YIELDS_ON',
    'ASAI_MILD_RESULT_YIELDS_OFF',
    'ASAI_SEVERE_RESULT_YIELDS_ON',
    'ASAI_SEVERE_RESULT_YIELDS_OFF'
);

DELETE FROM Modifiers
WHERE ModifierId IN (
    'ASAI_MILD_RESULT_YIELDS_ON',
    'ASAI_MILD_RESULT_YIELDS_OFF',
    'ASAI_SEVERE_RESULT_YIELDS_ON',
    'ASAI_SEVERE_RESULT_YIELDS_OFF'
);

INSERT INTO Modifiers
    (ModifierId, ModifierType, OwnerRequirementSetId, Permanent, RunOnce)
VALUES
    ('ASAI_MILD_RESULT_YIELDS_ON',
     'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER',
     'ASAI_DEITY_AI', 0, 0),
    ('ASAI_MILD_RESULT_YIELDS_OFF',
     'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER',
     'ASAI_DEITY_AI', 0, 0),
    ('ASAI_SEVERE_RESULT_YIELDS_ON',
     'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER',
     'ASAI_DEITY_AI', 0, 0),
    ('ASAI_SEVERE_RESULT_YIELDS_OFF',
     'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER',
     'ASAI_DEITY_AI', 0, 0);

INSERT INTO ModifierArguments
    (ModifierId, Name, Value)
VALUES
    ('ASAI_MILD_RESULT_YIELDS_ON', 'YieldType',
     'YIELD_PRODUCTION, YIELD_SCIENCE, YIELD_CULTURE, YIELD_FOOD'),
    ('ASAI_MILD_RESULT_YIELDS_ON', 'Amount', '20, 15, 15, 10'),
    ('ASAI_MILD_RESULT_YIELDS_OFF', 'YieldType',
     'YIELD_PRODUCTION, YIELD_SCIENCE, YIELD_CULTURE, YIELD_FOOD'),
    ('ASAI_MILD_RESULT_YIELDS_OFF', 'Amount', '-20, -15, -15, -10'),
    ('ASAI_SEVERE_RESULT_YIELDS_ON', 'YieldType',
     'YIELD_PRODUCTION, YIELD_SCIENCE, YIELD_CULTURE, YIELD_FOOD'),
    ('ASAI_SEVERE_RESULT_YIELDS_ON', 'Amount', '40, 30, 30, 20'),
    ('ASAI_SEVERE_RESULT_YIELDS_OFF', 'YieldType',
     'YIELD_PRODUCTION, YIELD_SCIENCE, YIELD_CULTURE, YIELD_FOOD'),
    ('ASAI_SEVERE_RESULT_YIELDS_OFF', 'Amount', '-40, -30, -30, -20');
