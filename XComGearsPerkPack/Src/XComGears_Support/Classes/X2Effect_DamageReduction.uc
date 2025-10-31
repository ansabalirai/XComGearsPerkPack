
class X2Effect_DamageReduction extends X2Effect_Persistent;

var float DamageReduction;
var int		DamageReductionAbs;
var bool 	bAbsoluteVal;


function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
    local XComGameState_Unit UnitState;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));


    EventMgr.RegisterForEvent(EffectObj, 'DRFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);


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
		`XEVENTMGR.TriggerEvent('DRFlyover', AbilityState, UnitState, NewGameState);
	
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

// Damage Reduction when shot through full cover
function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState)
{
	local XComGameState_Unit				TargetUnit;
	local int 								DamageMod;

	if (bAbsoluteVal)
	{
		if (CurrentDamage > 0)
		{
			DamageMod = -DamageReductionAbs;
		}

	}
	else
	{
		if (CurrentDamage > 0)
		{
			DamageMod = -int(float(CurrentDamage) * GetDamageReductionFromAbilities(EffectState));
		}
	}

	//`log("The Effect for damage reduction is " $ EffectState.GetX2Effect().EffectName $ "and final DR is " $ DamageMod);
	return DamageMod;
}


static function float GetDamageReductionFromAbilities(XComGameState_Effect EffectState)
{
	// Add additional conditions to modify the damage reduction values based on target units abilities and shit....
	local XComGameState_Unit AbilityOwnerUnit;
	local float 	FinalMod;

    AbilityOwnerUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));



    if (EffectState.GetX2Effect().EffectName == 'Distraction_DR')
    {
        FinalMod =  0.5f;
    }
    else if (EffectState.GetX2Effect().EffectName == 'StandTogether')
    {    
		FinalMod =  0.5f;
	}
	else if (EffectState.GetX2Effect().EffectName == 'Intimidate')
	{
		if (AbilityOwnerUnit.HasSoldierAbility('Intimidate_III'))
			FinalMod =  -0.3;
		else
			FinalMod =  0.0;
	}
	else
	{
		`log("Error: Could not find effect/condition for damage reduction amount calculation");
		FinalMod =  0;
	}
	
	`log("The Effect name is " $ EffectState.GetX2Effect().EffectName $ " and Unit that applied the Damage Reduction effect is " $ AbilityOwnerUnit.GetMyTemplateName() $ " and the final mod is " $ FinalMod);
	return FinalMod;
}


DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
	bDisplayInSpecialDamageMessageUI = true
	bAbsoluteVal = false;
}