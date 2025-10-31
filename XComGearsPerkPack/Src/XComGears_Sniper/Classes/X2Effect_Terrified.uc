
class X2Effect_Terrified extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'TriggerTerrifiedFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
}

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState) 
{
	local XComGameState_Ability TerrifiedAbilityState;
	// Only trigger on the actual shot
	if (NewGameState != none)
	{
		// Must be attack with Primary Weapon
		if (AbilityState.SourceWeapon == Attacker.GetItemInSlot(eInvSlot_PrimaryWeapon).GetReference())
		{
			TerrifiedAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
			`XEVENTMGR.TriggerEvent('TerrifiedTrigger', XComGameState_Unit(TargetDamageable), Attacker, NewGameState);

			`XEVENTMGR.TriggerEvent('TriggerTerrifiedFlyover', TerrifiedAbilityState , XComGameState_Unit(TargetDamageable), NewGameState);
		}
	}

	return 0;
}


DefaultProperties
{
	bDisplayInSpecialDamageMessageUI = false
}
