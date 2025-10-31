class X2Condition_HasAbility extends X2Condition;


var array<name> Abilities;
var bool RequireAll;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{ 
	local XComGameState_Unit TargetUnit;
	local name Ability;
	local bool RValue;

	TargetUnit = XComGameState_Unit(kTarget);
	
	if (TargetUnit == none)
		return 'AA_NotAUnit';

	if (TargetUnit.IsDead())
		return 'AA_UnitIsDead';

	if(RequireAll)
	{
		RValue = true;
		foreach Abilities(Ability)
		{
			if(!TargetUnit.HasSoldierAbility(Ability))
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
			if(TargetUnit.HasSoldierAbility(Ability)) return 'AA_Success'; 
		}
		return 'AA_NoAbility';
	}
}

DefaultProperties
{
	RequireAll = true
}
