class X2Effect_HeatUp extends X2Effect_Persistent;


function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local XComGameState_Unit TargetUnit;
    local UnitValue AvengerDamageBonus;
    local int NumCurrentStacks;

	TargetUnit = XComGameState_Unit(TargetDamageable);

	if (TargetUnit != none && Attacker.AffectedByEffectNames.Find('HeatedUp') != -1 && CurrentDamage > 0)
	{
        // Add additional conditions here for base damage only if needed and special shots that this may not apply to?
        return max(1,CurrentDamage * class'X2Ability_GearsHeavyAbilitySet'.default.HeatUpBonusDamage);
    }
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit;
	local XComGameState_Item WeaponState, NewWeaponState;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if (TargetUnit != none && TargetUnit.HasSoldierAbility('HeatUp_II'))
	{
		WeaponState = TargetUnit.GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState);
		if (WeaponState != none)
		{
			NewWeaponState = XComGameState_Item(NewGameState.ModifyStateObject(WeaponState.Class, WeaponState.ObjectID));
			if (NewWeaponState.Ammo < WeaponState.GetClipSize())
			{
				NewWeaponState.Ammo = WeaponState.GetClipSize();
			}
		}
	}
}