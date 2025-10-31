class X2AbilityCooldownReduction extends X2AbilityCooldown;

var int BaseCooldown;
var array<name> CooldownReductionAbilities;
var array<int> CooldownReductionAmount;

simulated function int GetNumTurns(XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
    local int FinalCooldown, i;
	local name AbilityName;

    FinalCooldown = BaseCooldown;


	for (i = 0; i < CooldownReductionAbilities.Length ; i++)
	{
		if (XComGameState_Unit(AffectState).HasSoldierAbility(CooldownReductionAbilities[i]))
		{
			FinalCooldown =  FinalCooldown - CooldownReductionAmount[i];
		}
	}

	return FinalCooldown;
}