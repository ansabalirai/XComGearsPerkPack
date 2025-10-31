class X2Effect_Spree extends X2Effect_Persistent;

var int USES_PER_TURN;
var int ProcChance;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'TriggerSpreeFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
}


function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{

	local XComGameStateHistory					History;
	local XComGameState_Unit					TargetUnit, PrevTargetUnit;
	local X2AbilityTemplateManager				AbilityTemplateMgr;
	local X2AbilityTemplate						AbilityTemplate, FlyoverTemplate;
	local X2WeaponTemplate						WeaponTemplate;
	local bool									bCritKill, bLog;
	local bool									bGrantMovePoint, bGrantActionPoint;
	local UnitValue								TrackerUnitValue, RangeUnitValue;
	local string								sMessageBridge;
	local X2EventManager						EventManager;
	local XComGameState_Effect					RemoveEffectState;
	local XComGameStateContext_EffectRemoved	RemoveEffectContext;
	local XComGameState_Ability					AbilityState;
    local int                                   ActualProcChance;

	// Require the unit to have some action points before activating the ability (prevents triggering on overwatch or reaction attacks)
	if (PreCostActionPoints.Length == 0)
		return false;
	

	// Get Target's XComGameState_Unit
	History = `XCOMHISTORY;
	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));

	// Get the triggering source weapon
	WeaponTemplate = X2WeaponTemplate(XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID)).GetMyTemplate());
    //bCritKill = 

    if (TargetUnit != none && TargetUnit.IsDead())
	{
        SourceUnit.GetUnitValue('SpreeKills', TrackerUnitValue);
        if (TrackerUnitValue.fValue < USES_PER_TURN || True)
        {
            `LOG("Spree Kill tracker: " $ int(TrackerUnitValue.fValue ) $ " is less than " $ USES_PER_TURN );

            if (`SYNC_RAND_STATIC(100) < GetNextProcChance(int(TrackerUnitValue.fValue)))
            {
                `LOG("Refunding spree action points for this kill");

                TrackerUnitValue.fValue += 1.0;
                SourceUnit.SetUnitFloatValue('SpreeKills', TrackerUnitValue.fValue, eCleanup_BeginTurn);

                //  restore the pre cost action points to fully refund this action
                if (SourceUnit.ActionPoints.Length != PreCostActionPoints.Length)
                {
                    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
                    if (AbilityState != none)
                    {
                        SourceUnit.ActionPoints = PreCostActionPoints;
                        `XEVENTMGR.TriggerEvent('TriggerSpreeFlyover', AbilityState, SourceUnit, NewGameState);
                        return true;
                    }
                }
            }

            else
            {
                `LOG("Spree kill proc chance failed! No free shot for you!");
            }

        }
    }

    return false;

}

function int GetNextProcChance(int TimesProcced)
{
    local array<int> DiminishingSteps; // Define diminishing returns thresholds
    
    // Initialize diminishing steps (progressive penalty)
    DiminishingSteps[0] = ProcChance;
    DiminishingSteps[1] = 30;
    DiminishingSteps[2] = 15;
    DiminishingSteps[3] = 10;
    DiminishingSteps[4] = 0;
    
    // If TimesProcced exceeds the defined steps, return 0 (no further refunds)
    if (TimesProcced >= DiminishingSteps.Length)
    {
        return 0;
    }
    
    // Return the proc chance corresponding to the current TimesProcced
    return DiminishingSteps[TimesProcced];
}