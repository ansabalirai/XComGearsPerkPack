class X2Condition_PrimaryTargetDead extends X2Condition;


// Need to check the primary target of the ability to see if it is dead
event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget)
{ 
	local XComGameState_Unit TargetUnit, PrimaryTargetUnitState;
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_Ability Ability;

	TargetUnit = XComGameState_Unit(kTarget);

    AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(kAbility, kTarget.ObjectID);

	if (TargetUnit == none)
		return 'AA_NotAUnit';

	if (!TargetUnit.IsDead())
		return 'AA_Success';

	return 'AA_Success';
}