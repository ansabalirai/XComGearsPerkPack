class X2Effect_Redeploy extends X2Effect_Persistent;

var int NumActionPoints;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local int i;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
        `Log("Unit currently has action points = " $ UnitState.ActionPoints.Length);

        if (UnitState.ActionPoints.Length > 0)
            UnitState.ActionPoints.Length = 0;

		for (i = 0; i < NumActionPoints; ++i)
		{
			UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);
		}
	}
}
