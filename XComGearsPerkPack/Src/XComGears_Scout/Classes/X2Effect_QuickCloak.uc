class X2Effect_QuickCloak extends X2Effect_Persistent;

var array<name> VALID_ABILITIES;

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{
	local name						AbilityName;
	local name						TestName;
	local XComGameState_Ability		AbilityState;
	local bool						bFreeActivation;
	local X2WeaponTemplate			SourceWeaponAmmoTemplate;

	if(kAbility == none)
		return false;

	AbilityName = kAbility.GetMyTemplateName();


	if (VALID_ABILITIES.Find(AbilityName) != -1)
		bFreeActivation = true;


	if(bFreeActivation)
	{
		if (SourceUnit.ActionPoints.Length != PreCostActionPoints.Length)
		{
            SourceUnit.ActionPoints = PreCostActionPoints; // Refund this ability cost
            return true;
		}
	}
	return false;
}