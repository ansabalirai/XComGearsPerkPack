class X2Effect_EscapeRoute extends X2Effect_Persistent;

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

	if (TargetUnit != None && TargetUnit.IsDead() && SourceWeapon != none && SourceWeapon.InventorySlot == eInvSlot_PrimaryWeapon)
	{

        UnitState.GetUnitValue('CritKillsThisTurn', CritKills);
        if  ( UnitState.HasSoldierAbility('EscapeRoute') && (AbilityContext.ResultContext.HitResult == eHit_Crit) && CritKills.fValue < 1)
        {
            Modifier = 0;
            if (UnitState.SuperConcealmentLoss > 0)
            {
                // Reset the super concealment loss to 0
                SuperConcealedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Escape route super concealment reset");
                UnitState = XComGameState_Unit(SuperConcealedState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
                UnitState.SuperConcealmentLoss = 0;
                `TACTICALRULES.SubmitGameState(SuperConcealedState);
            }
            UnitState.SetUnitFloatValue('CritKillsThisTurn', CritKills.fValue + 1, eCleanup_BeginTurn );
            return true;
        }
	}

    // Catch all case in case we did not get a kill or any other case???
    Modifier = 100;
    SuperConcealedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Escape Route super concealment forced reveal");
    UnitState = XComGameState_Unit(SuperConcealedState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
    UnitState.SuperConcealmentLoss = 100;
    `TACTICALRULES.SubmitGameState(SuperConcealedState);
	return true;
}

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "EscapeRoute"
}