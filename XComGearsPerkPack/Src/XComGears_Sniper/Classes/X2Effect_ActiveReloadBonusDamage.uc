class X2Effect_ActiveReloadBonusDamage extends X2Effect_Persistent;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local float ExtraDamage;
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(TargetDamageable);
	if( NewGameState != none && Attacker.HasSoldierAbility('ActiveReload'))
	{
        if (TargetUnit != none && AbilityState.SourceWeapon == EffectState.ApplyEffectParameters.ItemStateObjectRef)
        {
            ExtraDamage = CurrentDamage * 0.25f;
        }
	    return int(ExtraDamage);
    }

    return 0;
}



defaultproperties
{
    DuplicateResponse=eDupe_Ignore
    EffectName="ActiveReloadBonusDamageEffect"
}