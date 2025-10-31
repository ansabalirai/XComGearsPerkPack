class X2Effect_Executioner extends X2Effect_Persistent;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local float ExtraDamage;
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(TargetDamageable);

	if (TargetUnit != none && (TargetUnit.GetCurrentStat(eStat_HP) <= (TargetUnit.GetMaxStat(eStat_HP) / 2)))
	{

			ExtraDamage = CurrentDamage * 0.3f;
		
	}
	return int(ExtraDamage);
}



defaultproperties
{
    DuplicateResponse=eDupe_Ignore
    EffectName="Executioner"
}