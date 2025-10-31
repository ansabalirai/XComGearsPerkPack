class X2Condition_SourceHasAbility extends X2Condition;


var array<name> Abilities;
var bool RequireAll;

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{ 
	local XComGameState_Unit TargetUnit, SourceUnit;
	local name Ability;
	local bool RValue;

	TargetUnit = XComGameState_Unit(kTarget);
    SourceUnit = XComGameState_Unit(kSource);
	
	if (SourceUnit == none)
		return 'AA_NotAUnit';

	if (SourceUnit.IsDead())
		return 'AA_UnitIsDead';

	if(RequireAll)
	{
		RValue = true;
		foreach Abilities(Ability)
		{
			if(!SourceUnit.HasSoldierAbility(Ability))
			{
				RValue = false;
				break;
			}
		}
		if (Rvalue) return 'AA_Success'; 
		else return 'AA_NoAbility';
	}
	else
	{
		foreach Abilities(Ability)
		{
			if(SourceUnit.HasSoldierAbility(Ability)) return 'AA_Success'; 
		}
		return 'AA_NoAbility';
	}
}

DefaultProperties
{
	RequireAll = true
}
