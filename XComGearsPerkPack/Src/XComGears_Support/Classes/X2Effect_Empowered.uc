class X2Effect_Empowered extends X2Effect_Persistent;

var int 	BonusDamage;
var float 	BonusDamageMultiplier;
var bool 	bUseMultiplier;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
    local XComGameState_Unit UnitState;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

    EventMgr.RegisterForEvent(EffectObj, 'EmpoweredFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);


}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Item ItemState, InnerItemState;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;
	local int i, j, modifier;


	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	UnitState = XComGameState_Unit(kNewTargetState);

	if (AbilityState != none && UnitState != none)
		`XEVENTMGR.TriggerEvent('EmpoweredFlyover', AbilityState, UnitState, NewGameState);
	
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local float ExtraDamage;
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(TargetDamageable);

	if (TargetUnit != none)
	{
		if (bUseMultiplier)
		{
			ExtraDamage = CurrentDamage * BonusDamageMultiplier;
		}
		else
		{
			ExtraDamage =  BonusDamage;
		}
		
	}
	return int(ExtraDamage);
}


defaultproperties
{
	EffectName = "Empowered";
}