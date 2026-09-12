-- Ordinary native strategies wait 20 (unscaled) turns between changes.
-- Forbidden is a temporary veto; Disqualifier permanently retires a strategy.
-- Keep long-term strategy hysteresis unchanged. Only execution requests use a
-- bounded pool: Lua selects at most ONE slot per family and leaves a stopped
-- slot unused for 22 turns. Twelve slots cover even alternating on/off turns.
-- No native code is patched and no production order or free unit is created.
CREATE TABLE IF NOT EXISTS ASAI_ExecutionGateDefinitions (
    GateId INTEGER PRIMARY KEY,
    StrategyType TEXT NOT NULL UNIQUE,
    Callback TEXT NOT NULL
);
DELETE FROM ASAI_ExecutionGateDefinitions;
INSERT INTO ASAI_ExecutionGateDefinitions VALUES
    (1, 'ASAI_STRATEGY_LAND_RECOVERY_R2', 'ASAI_IsLandRecovery'),
    (2, 'ASAI_STRATEGY_RANGED_REINFORCEMENT_R2', 'ASAI_IsRangedReinforcement'),
    (3, 'ASAI_STRATEGY_WRITING_PREREQUISITE_R2', 'ASAI_IsWritingPrerequisite'),
    (4, 'ASAI_STRATEGY_EDUCATION_PREREQUISITE_R2', 'ASAI_IsEducationPrerequisite'),
    (5, 'ASAI_STRATEGY_LABORATORY_PREREQUISITE_R2', 'ASAI_IsLaboratoryPrerequisite'),
    (6, 'ASAI_STRATEGY_SCIENCE_CONSTRUCTION_R2', 'ASAI_IsScienceConstructionExecution'),
    (7, 'ASAI_STRATEGY_SCIENCE_PRODUCTION_SHARE_R2', 'ASAI_IsScienceProductionShareExecution'),
    (8, 'ASAI_STRATEGY_SCIENCE_CAPACITY_R2', 'ASAI_IsScienceCapacityExecution'),
    (9, 'ASAI_STRATEGY_MINOR_FRONT_RECOVERY_R2', 'ASAI_IsMinorFrontRecoveryExecution'),
    (10, 'ASAI_STRATEGY_CAMPUS_DEMAND_R2', 'ASAI_IsCampusDemand'),
    (11, 'ASAI_STRATEGY_ANTICAVALRY_DEMAND_R2', 'ASAI_IsAntiCavalryDemand'),
    (12, 'ASAI_STRATEGY_URGENT_LAND', 'ASAI_IsUrgentLandDemand'),
    (13, 'ASAI_STRATEGY_CAMPUS_SLOT_PRESSURE', 'ASAI_IsCampusSlotPressure'),
    (14, 'ASAI_STRATEGY_LASER_ORBITAL', 'ASAI_IsOrbitalLaserDemand'),
    (15, 'ASAI_STRATEGY_LASER_TERRESTRIAL', 'ASAI_IsTerrestrialLaserDemand'),
    (16, 'ASAI_STRATEGY_LASER_POWER', 'ASAI_IsLaserPowerDemand'),
    (17, 'ASAI_STRATEGY_LASER_PORT_HANDOFF', 'ASAI_IsLaserPortHandoff');
CREATE TEMP TABLE ASAI_ExecutionSlots (Slot INTEGER PRIMARY KEY);
INSERT INTO ASAI_ExecutionSlots VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12);

INSERT INTO Types (Type, Kind)
SELECT StrategyType || '_S' || s.Slot, 'KIND_VICTORY_STRATEGY'
FROM ASAI_ExecutionGateDefinitions CROSS JOIN ASAI_ExecutionSlots s;
INSERT INTO Strategies (StrategyType, NumConditionsNeeded)
SELECT StrategyType || '_S' || s.Slot, 1
FROM ASAI_ExecutionGateDefinitions CROSS JOIN ASAI_ExecutionSlots s;
INSERT INTO StrategyConditions
    (StrategyType, ConditionFunction, StringValue, ThresholdValue, Forbidden, Disqualifier, Exclusive)
SELECT StrategyType || '_S' || s.Slot, 'Call Lua Function',
       'ASAI_IsNativeExecutionAllowed', GateId * 100 + s.Slot, 0, 0, 0
FROM ASAI_ExecutionGateDefinitions CROSS JOIN ASAI_ExecutionSlots s;
-- A positive readiness condition is essential: if gameplay Lua does not load,
-- an absent veto alone must NOT turn every slot on. Exclusive distinguishes
-- the two Call Lua Function rows in the engine's composite primary key. It is
-- set ONLY on a true veto, which forces this slot OFF. These utility strategies
-- have no VictoryType and cannot participate in exclusive victory selection.
INSERT INTO StrategyConditions
    (StrategyType, ConditionFunction, StringValue, ThresholdValue, Forbidden, Disqualifier, Exclusive)
SELECT StrategyType || '_S' || s.Slot, 'Call Lua Function',
       'ASAI_IsNativeExecutionBlocked', GateId * 100 + s.Slot, 1, 0, 1
FROM ASAI_ExecutionGateDefinitions CROSS JOIN ASAI_ExecutionSlots s;
INSERT INTO StrategyConditions (StrategyType, ConditionFunction, Disqualifier)
SELECT StrategyType || '_S' || s.Slot, 'Is Not Major', 1
FROM ASAI_ExecutionGateDefinitions CROSS JOIN ASAI_ExecutionSlots s;
INSERT INTO Strategy_Priorities (StrategyType, ListType)
SELECT p.StrategyType || '_S' || s.Slot, p.ListType
FROM Strategy_Priorities p JOIN ASAI_ExecutionGateDefinitions d USING (StrategyType)
CROSS JOIN ASAI_ExecutionSlots s;

-- Preserve saved type identities but never leave two owners contributing the
-- old and new weights together. The old identities have no remaining effects.
DELETE FROM Strategy_Priorities
WHERE StrategyType IN (SELECT StrategyType FROM ASAI_ExecutionGateDefinitions);
UPDATE StrategyConditions SET StringValue = 'ASAI_IsRetiredStrategy',
    Forbidden = 0, Disqualifier = 0, Exclusive = 0
WHERE ConditionFunction = 'Call Lua Function'
  AND StrategyType IN (SELECT StrategyType FROM ASAI_ExecutionGateDefinitions);
DROP TABLE ASAI_ExecutionSlots;
