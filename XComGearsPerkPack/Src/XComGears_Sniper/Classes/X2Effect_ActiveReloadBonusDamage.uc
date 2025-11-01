class X2Effect_ActiveReloadBonusDamage extends X2Effect_Persistent;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		UnitState.SetUnitFloatValue('ActiveReloadActive', 1, eCleanup_BeginTurn);
	}
}

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
    local UnitValue ActiveReloadWeaponValue;
    local XComGameState_Item SourceWeapon;
    local float ExtraDamage;

    if (!Attacker.HasSoldierAbility('ActiveReload'))
    {
        return 0;
    }

    if (AbilityState == none)
    {
        return 0;
    }

    SourceWeapon = AbilityState.GetSourceWeapon();
    if (SourceWeapon == none)
    {
        return 0;
    }

    if (!Attacker.GetUnitValue('ActiveReloadWeaponRef', ActiveReloadWeaponValue) || int(ActiveReloadWeaponValue.fValue) != SourceWeapon.ObjectID)
    {
        return 0;
    }

    if (CurrentDamage <= 0)
    {
        return 0;
    }

    // ExtraDamage = float(CurrentDamage) * 0.25f;

    return max(1,CurrentDamage * 0.25);
}



simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', RemovedEffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState != none)
	{
		UnitState.SetUnitFloatValue('ActiveReloadActive', 0, eCleanup_BeginTurn);
		UnitState.SetUnitFloatValue('ActiveReloadWeaponRef', 0, eCleanup_BeginTurn);
	}

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);
}

defaultproperties
{
    DuplicateResponse=eDupe_Ignore
    EffectName="ActiveReloadBonusDamageEffect"
}
