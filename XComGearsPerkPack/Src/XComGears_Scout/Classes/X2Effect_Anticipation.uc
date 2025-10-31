class X2Effect_Anticipation extends X2Effect_Persistent;


function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState) {
	local int i;
	
	if ( UnitState.HasSoldierAbility('Anticipation_II') ) 
    {
		for (i = 0; i < 2; ++i) {
			ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
		}
	}

    else if( UnitState.HasSoldierAbility('Anticipation_I') ) 
    {
		for (i = 0; i < 1; ++i) {
			ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
		}
	}
}

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "Anticipation"
}