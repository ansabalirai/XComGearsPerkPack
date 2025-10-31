class X2Condition_UnitEffectsExtended extends X2Condition;

struct native EffectReason
{
	var() name EffectName;
	var() name Reason;
};

var() array<EffectReason> RequireAnyEffects;     //Condition will fail unless ANY effect in this list is on the unit

function AddRequireEffect(name EffectName, name Reason)
{
	local EffectReason Require;
	Require.EffectName = EffectName;
	Require.Reason = Reason;
	RequireAnyEffects.AddItem(Require);
}


event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{ 
	local XComGameState_Unit TargetUnit;
    local int Index;
	
    if (TargetUnit == none)
		return 'AA_NotAUnit';
	
	TargetUnit = XComGameState_Unit(kTarget);

    for(Index = RequireAnyEffects.Length - 1; Index >= 0; Index--)
    {
        if (TargetUnit.IsUnitAffectedByEffectName(RequireAnyEffects[Index].EffectName))
        {
            return 'AA_Success';
        }
    }

	return 'AA_NoTargets';
}