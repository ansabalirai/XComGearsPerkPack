class X2Effect_ResetCooldown extends X2Effect;

// Make sure either excluded or included ability array is filled, not both at the same time. If needed, just set bResetAll to true

var array<name> ExcludedAbilities;
var array<name> IncludedAbilities;
var bool 		bResetAll;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_Ability AbilityState;
	local int i;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(kNewTargetState);

	if (bResetAll) // Reset all abilities cooldowns
	{	
		for (i = 0; i < UnitState.Abilities.Length; ++i)
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitState.Abilities[i].ObjectID));
			if (AbilityState != none && AbilityState.iCooldown > 0)
			{
				AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
				AbilityState.iCooldown = 0;
				`log("Ability cooldown reset for: " $ AbilityState.Name);
			}
		}
	}

	else if (ExcludedAbilities.Length > 0) //All except the excluded ones
	{
		for (i = 0; i < UnitState.Abilities.Length; ++i)
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitState.Abilities[i].ObjectID));
			if (AbilityState != none && AbilityState.iCooldown > 0)
			{
				if ((ExcludedAbilities.Find(AbilityState.GetMyTemplateName()) != Index_None))
					{}
				else
				{
					AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
					AbilityState.iCooldown = 0;				
				}
			}
		}		
	}

	else if (IncludedAbilities.Length > 0) // Only the included ones
	{
		for (i = 0; i < UnitState.Abilities.Length; ++i)
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitState.Abilities[i].ObjectID));
			if (AbilityState != none && AbilityState.iCooldown > 0)
			{
				if ( (IncludedAbilities.Find(AbilityState.GetMyTemplateName()) != Index_None))
				{
					AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
					AbilityState.iCooldown = 0;
					`log("Ability cooldown reset for: " $ AbilityState.Name);
				}
			}
		}
	}


}

defaultproperties
{
    bResetAll=FALSE
}