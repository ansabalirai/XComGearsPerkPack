class X2Effect_TeamworkKillsActionRefunds extends X2Effect_Persistent;


function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
    local XComGameState_Unit UnitState;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

    EventMgr.RegisterForEvent(EffectObj, 'KillFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);


}

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{

	local XComGameStateHistory					History;
	local XComGameState_Unit					TargetUnit, PrevTargetUnit;
	local X2AbilityTemplateManager				AbilityTemplateMgr;
	local X2AbilityTemplate						AbilityTemplate, FlyoverTemplate;
	local X2WeaponTemplate						WeaponTemplate;
	local bool									bLightWeapon, bLog;
	local bool									bGrantMovePoint, bGrantActionPoint;
	local UnitValue								TrackerUnitValue, RangeUnitValue;
	local string								sMessageBridge;
	local X2EventManager						EventManager;
	local XComGameState_Effect					RemoveEffectState;
	local XComGameStateContext_EffectRemoved	RemoveEffectContext;
	local XComGameState_Ability					AbilityState;
	local int 									USES_PER_TURN;

	// Require the unit to have some action points before activating the ability (prevents triggering on overwatch or reaction attacks)
	if (PreCostActionPoints.Length == 0)
		return false;
	

	// Get Target's XComGameState_Unit
	History = `XCOMHISTORY;
	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	PrevTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnit.ObjectID));

	// Get the triggering ability template
	AbilityTemplateMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateMgr.FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

	// Get the triggering source weapon
	WeaponTemplate = X2WeaponTemplate(XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID)).GetMyTemplate());

    if (TargetUnit != none && TargetUnit.IsDead())
	{
        SourceUnit.GetUnitValue('TeamworkKills', TrackerUnitValue);

		if (EffectState.GetX2Effect().EffectName == 'SerialChargeBased_I')
			USES_PER_TURN = class'X2Ability_GearsSupportAbilitySet'.default.TeamworkKills_LVL_I ;

		if (EffectState.GetX2Effect().EffectName == 'SerialChargeBased_II')
			USES_PER_TURN = class'X2Ability_GearsSupportAbilitySet'.default.TeamworkKills_LVL_II;

        if (TrackerUnitValue.fValue < USES_PER_TURN)
        {
            `LOG("TeamworkKills tracker: " $ int(TrackerUnitValue.fValue ) $ " are less than " $ USES_PER_TURN $ ". Granting serial action point");
			// Increment the activation tracker
			TrackerUnitValue.fValue += 1.0;
			SourceUnit.SetUnitFloatValue('TeamworkKills', TrackerUnitValue.fValue, eCleanup_BeginTurn);
			
            //  restore the pre cost action points to fully refund this action
			if (SourceUnit.ActionPoints.Length != PreCostActionPoints.Length)
			{
				AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
				if (AbilityState != none)
				{
					SourceUnit.ActionPoints = PreCostActionPoints;
					`XEVENTMGR.TriggerEvent('KillFlyover', AbilityState, SourceUnit, NewGameState);
					return true;
				}
			}
        }
    }

    return false;

}


defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "TeamWorkKillsActionPointRefund"
}