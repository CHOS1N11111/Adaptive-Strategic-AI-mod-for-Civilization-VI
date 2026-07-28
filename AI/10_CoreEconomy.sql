-- High-value global corrections. These values affect AI valuation, not yields.
UPDATE PseudoYields
SET DefaultValue = MAX(DefaultValue, 4.0)
WHERE PseudoYieldType = 'PSEUDOYIELD_IMPROVEMENT';

UPDATE PseudoYields
SET DefaultValue = MAX(DefaultValue, 4.0)
WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_TRADE';

UPDATE PseudoYields
SET DefaultValue = MAX(DefaultValue, 4.0)
WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_AIR_COMBAT';

-- Reserve gold for upgrades and purchases before leaving it in the slush fund.
UPDATE AiFavoredItems SET Value = 1
WHERE ListType = 'DefaultSavings' AND Item = 'SAVING_GREAT_PEOPLE';
UPDATE AiFavoredItems SET Value = 2
WHERE ListType = 'DefaultSavings' AND Item = 'SAVING_UNITS';
UPDATE AiFavoredItems SET Value = 3
WHERE ListType = 'DefaultSavings' AND Item = 'SAVING_PLOTS';
UPDATE AiFavoredItems SET Value = 4
WHERE ListType = 'DefaultSavings' AND Item = 'SAVING_SLUSH_FUND';

-- Production remains the universal bottleneck, but science and culture must not
-- be neglected after the opening expansion phase.
UPDATE AiFavoredItems SET Value = 22
WHERE ListType = 'DefaultYieldBias' AND Item = 'YIELD_PRODUCTION';
UPDATE AiFavoredItems SET Value = 14
WHERE ListType = 'DefaultYieldBias' AND Item = 'YIELD_SCIENCE';
UPDATE AiFavoredItems SET Value = 14
WHERE ListType = 'DefaultYieldBias' AND Item = 'YIELD_CULTURE';
UPDATE AiFavoredItems SET Value = 16
WHERE ListType = 'DefaultYieldBias' AND Item = 'YIELD_GOLD';

-- Defaults used by the gameplay script and the optional metrics logger.
INSERT OR REPLACE INTO GlobalParameters (Name, Value) VALUES
    ('ASAI_VERSION', '0.2.1'),
    ('ASAI_ENABLE_METRICS', 0),
    ('ASAI_METRICS_INTERVAL', 25),
    ('ASAI_INFRA_START_TURN', 20),
    ('ASAI_INFRA_IMPROVEMENTS_PER_POP_X100', 80),
    ('ASAI_GOLD_RESERVE_PER_CITY', 15),
    ('ASAI_RELATIVE_PACING_ENABLED', 1),
    ('ASAI_RELATIVE_START_TURN', 35),
    ('ASAI_RELATIVE_CHECK_INTERVAL', 5),
    ('ASAI_RELATIVE_TRAILING_ENTER_X100', 85),
    ('ASAI_RELATIVE_TRAILING_EXIT_X100', 92),
    ('ASAI_RELATIVE_LEADING_EXIT_X100', 108),
    ('ASAI_RELATIVE_LEADING_ENTER_X100', 115),
    ('ASAI_RELATIVE_COMPONENT_MIN_X100', 55),
    ('ASAI_RELATIVE_COMPONENT_MAX_X100', 145),
    ('ASAI_RELATIVE_WEIGHT_TECHS', 20),
    ('ASAI_RELATIVE_WEIGHT_CIVICS', 18),
    ('ASAI_RELATIVE_WEIGHT_SCIENCE', 12),
    ('ASAI_RELATIVE_WEIGHT_CULTURE', 12),
    ('ASAI_RELATIVE_WEIGHT_CITIES', 10),
    ('ASAI_RELATIVE_WEIGHT_POPULATION', 15),
    ('ASAI_RELATIVE_WEIGHT_MILITARY', 13);
