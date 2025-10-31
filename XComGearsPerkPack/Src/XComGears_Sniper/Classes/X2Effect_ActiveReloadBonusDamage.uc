class X2Effect_ActiveReloadBonusDamage extends X2Effect_Persistent;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
    local UnitValue ActiveReloadWeaponValue;
    local XComGameState_Item SourceWeapon;
    local float ExtraDamage;

    if (NewGameState == none)
    {
        return 0;
    }

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

    ExtraDamage = float(CurrentDamage) * 0.25f;
    Attacker.SetUnitFloatValue('ActiveReloadWeaponRef', 0, eCleanup_BeginTurn);
    EffectState.RemoveEffect(NewGameState, NewGameState);

    return max(1, int(ExtraDamage + 0.5f));
}



defaultproperties
{
    DuplicateResponse=eDupe_Ignore
    EffectName="ActiveReloadBonusDamageEffect"
}