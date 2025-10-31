//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_SilentKiller.uc
//  AUTHOR:  Joshua Bouscher  --  7/11/2016
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_SilentStab extends X2Effect_Persistent;


function bool AdjustSuperConcealModifier(XComGameState_Unit UnitState, XComGameState_Effect EffectState, XComGameState_Ability AbilityState, XComGameState RespondToGameState, const int BaseModifier, out int Modifier)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit TargetUnit;
	local XComGameState_Item SourceWeapon;
	local XComGameState SuperConcealedState;
	local UnitValue			KnifeKills, CritKills;
	local bool bOutVal;
	
	if (RespondToGameState == none)
		return false;	// nothing special is previewed for this effect

	AbilityContext = XComGameStateContext_Ability(RespondToGameState.GetContext());
	TargetUnit = XComGameState_Unit(RespondToGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	
    if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
        return false;

	SourceWeapon = AbilityState.GetSourceWeapon();
	
	if (TargetUnit != None && TargetUnit.IsDead() && AbilityState.IsMeleeAbility() && SourceWeapon != none && SourceWeapon.InventorySlot == eInvSlot_SecondaryWeapon)
	{		
		UnitState.GetUnitValue('KnifeKillsThisTurn', KnifeKills);
		if (UnitState.HasSoldierAbility('SilentStab') && KnifeKills.fValue < 1)
		{
			Modifier = 0;
			if (UnitState.SuperConcealmentLoss > 0)
			{
				// Reset the super concealment loss to 0
				SuperConcealedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Silent Stab super concealment reset");
				UnitState = XComGameState_Unit(SuperConcealedState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
				UnitState.SuperConcealmentLoss = 0;
				`TACTICALRULES.SubmitGameState(SuperConcealedState);
			}
			UnitState.SetUnitFloatValue('KnifeKillsThisTurn', KnifeKills.fValue + 1, eCleanup_BeginTurn );
			return true;
		}

	}
	Modifier = 100;
	// Reset the super concealment loss to 0
	SuperConcealedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Silent Stab super concealment forced reveal");
	UnitState = XComGameState_Unit(SuperConcealedState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
	UnitState.SuperConcealmentLoss = 100;
	`TACTICALRULES.SubmitGameState(SuperConcealedState);

	return true;
}

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "SilentStab"
}

