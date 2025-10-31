class X2Effect_RageShotDamageBonus extends X2Effect_Persistent;

var int MaxDamageBonus;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local int ExtraDamage;
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(TargetDamageable);

	if (TargetUnit != none && CurrentDamage > 0 && AbilityState.GetMyTemplateName() == 'RageShot_I')
	{
        ExtraDamage =  GetRageShotBonusDamage( Attacker);
    }
	
    return min(ExtraDamage,MaxDamageBonus );
}

private function int GetRageShotBonusDamage (XComGameState_Unit Attacker)
{
    local int MissingHealth;
    local int DamageMultiplier;

    MissingHealth = Attacker.GetMaxStat(eStat_HP) - Attacker.GetCurrentStat(eStat_HP);

    if (Attacker.HasSoldierAbility('RageShot_I'))
    {
        DamageMultiplier = MissingHealth * 0.5f;
    }

    if (Attacker.HasSoldierAbility('RageShot_II'))
    {
        DamageMultiplier = MissingHealth * 1.0f;
    }

    if (Attacker.HasSoldierAbility('RageShot_I'))
    {
        DamageMultiplier = MissingHealth * 1.5f;
    }

    return DamageMultiplier;

}