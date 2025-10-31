class X2Effect_SliceAndDice extends X2Effect_Persistent;

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

	EventMgr.RegisterForEvent(EffectObj, 'TriggerSliceAndDiceFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
}


function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{

	local XComGameStateHistory					History;
	local XComGameState_Unit					TargetUnit, PrevTargetUnit;
	local X2AbilityTemplateManager				AbilityTemplateMgr;
	local X2AbilityTemplate						AbilityTemplate, FlyoverTemplate;
	local X2WeaponTemplate						WeaponTemplate, AbilitySourceWeapon;
	local bool									bLightWeapon, bLog;
	local bool									bGrantMovePoint, bGrantActionPoint;
	local UnitValue								TrackerUnitValue, RangeUnitValue;
	local string								sMessageBridge;
	local X2EventManager						EventManager;
	local XComGameState_Effect					RemoveEffectState;
	local XComGameStateContext_EffectRemoved	RemoveEffectContext;
	local XComGameState_Ability					AbilityState;

	// Require the unit to have some action points before activating the ability (prevents triggering on overwatch or reaction attacks)
	if (PreCostActionPoints.Length == 0)
		return false;
	

	// Get Target's XComGameState_Unit
	History = `XCOMHISTORY;
	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));

	// Get the triggering source weapon
	WeaponTemplate = X2WeaponTemplate(XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID)).GetMyTemplate());


    if (WeaponTemplate.InventorySlot != eInvSlot_SecondaryWeapon)
    {
        `LOG("SliceAndDice Kill weapon is not valid!" );
        return false;
    }



    if (TargetUnit != none && TargetUnit.IsDead() && WeaponTemplate.InventorySlot == eInvSlot_SecondaryWeapon)
	{
        SourceUnit.GetUnitValue('SliceAndDiceKills', TrackerUnitValue);
        if (TrackerUnitValue.fValue < USES_PER_TURN)
        {
            `LOG("SliceAndDice Kill tracker: " $ int(TrackerUnitValue.fValue ) $ " is less than " $ USES_PER_TURN );

            if (`SYNC_RAND_STATIC(100) < ProcChance)
            {
                `LOG("Refunding SliceAndDice action points for this kill");

                TrackerUnitValue.fValue += 1.0;
                SourceUnit.SetUnitFloatValue('SliceAndDiceKills', TrackerUnitValue.fValue, eCleanup_BeginTurn);

                //  restore the pre cost action points to fully refund this action
                if (SourceUnit.ActionPoints.Length != PreCostActionPoints.Length)
                {
                    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
                    if (AbilityState != none)
                    {
                        SourceUnit.ActionPoints = PreCostActionPoints;
                        `XEVENTMGR.TriggerEvent('TriggerSliceAndDiceFlyover', AbilityState, SourceUnit, NewGameState);
                        return true;
                    }
                }
            }

            else
            {
                `LOG("SliceAndDice kill proc chance failed! No free slice for you!");
            }

        }
    }

    return false;

}