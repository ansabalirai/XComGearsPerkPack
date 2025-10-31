class X2Effect_ScoutShadow extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
    local XComGameState_Unit UnitState;
    local XComGameState_Ability AbilityState;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', ModifySuperConcealmentLoss, ELD_OnStateSubmitted,,,,AbilityState);
}


static function EventListenerReturn ModifySuperConcealmentLoss(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState_Ability AbilityState, AnchoredAbility;
	local XComGameState_Unit  UnitState;
    local XComGameState_Item SourceWeapon;
    local UnitValue CurrentAnchorStacks;
    local int CurrentStacks, UpdatedStacks, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    AbilityState =  XComGameState_Ability(EventData); // The shooting ability that modifies anchor stacks
    UnitState = XComGameState_Unit(EventSource); // The source unit for whom we need to modify anchor stacks

    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	if (AbilityState == none || UnitState == none || AbilityContext == none)
        return ELR_NoInterrupt;

    if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
        return ELR_NoInterrupt;

    if (AbilityState.GetMyTemplateName() == 'ScoutShadow')
    {
        if (UnitState.bHasSuperConcealment == true)
            `log(UnitState.GetFullName() $ " has super concealment at " $ UnitState.SuperConcealmentLoss $ " with base detection radius of " $ UnitState.GetBaseStat(eStat_DetectionModifier) $ " and current detection radius modifier of " $ UnitState.GetCurrentStat(eStat_DetectionModifier) );

        //UnitState.bHasSuperConcealment = true;
        //UnitState.SuperConcealmentLoss = 50;
    }

    return ELR_NoInterrupt;

}


simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
	
	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
        
		UnitState.bHasSuperConcealment = true;
        UnitState.SuperConcealmentLoss = 0;
	}
    `XEVENTMGR.TriggerEvent('EffectEnterUnitConcealment', UnitState, UnitState, NewGameState);
}

// simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
// {
// 	local XComGameState_Unit UnitState;
// 	local float SourceUnitDetectionRadius; 
// 	local int SourceUnitMaxHP;
// 	local StatChange ShieldUnitHP;

// 	UnitState = XComGameState_Unit(kNewTargetState);
// 	SourceUnitDetectionRadius = UnitState.GetCurrentStat(eStat_DetectionModifier);

// 	`log("Entering Shadow! The detection modifier is" $ SourceUnitDetectionRadius);

// 	ShieldUnitHP.StatType = eStat_DetectionModifier;
// 	ShieldUnitHP.StatAmount = 1.0f;
// 	NewEffectState.StatChanges.AddItem(ShieldUnitHP);

// 	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
// }

function bool AdjustSuperConcealModifier(XComGameState_Unit UnitState, XComGameState_Effect EffectState, XComGameState_Ability AbilityState, XComGameState RespondToGameState, const int BaseModifier, out int Modifier)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit TargetUnit;
	local XComGameState_Item SourceWeapon;
    local XComGameState SuperConcealedState;
	local UnitValue			KnifeKills, CritKills;
	local bool forceReveal;


	if (RespondToGameState == none)
		return false;	// nothing special is previewed for this effect

	AbilityContext = XComGameStateContext_Ability(RespondToGameState.GetContext());
	TargetUnit = XComGameState_Unit(RespondToGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	
    if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
        return false;

    SourceWeapon = AbilityState.GetSourceWeapon();
    if (SourceWeapon == none || TargetUnit == None)
        return false;


    // Check shooting abilities
	if (UnitState.HasSoldierAbility('EscapeRoute'))
	{
        UnitState.GetUnitValue('CritKillsThisTurn', CritKills);
        if  ( TargetUnit.IsDead() && SourceWeapon.InventorySlot == eInvSlot_PrimaryWeapon && (AbilityContext.ResultContext.HitResult == eHit_Crit) && CritKills.fValue < 1)
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

/*         else
        {
            Modifier = 100;
            SuperConcealedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Super concealment forced reveal");
            UnitState = XComGameState_Unit(SuperConcealedState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
            UnitState.SuperConcealmentLoss = 100;
            `TACTICALRULES.SubmitGameState(SuperConcealedState);
            return true;
        } */
	}


    // Check Melee abilities
	if (TargetUnit.IsDead() && AbilityState.IsMeleeAbility() && UnitState.HasSoldierAbility('SilentStab') && SourceWeapon.InventorySlot == eInvSlot_SecondaryWeapon)
	{		
		UnitState.GetUnitValue('KnifeKillsThisTurn', KnifeKills);
		if ( KnifeKills.fValue < 1)
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

    // Catch all case in case we did not get a kill or any other case???
    if (true) //!UnitState.HasSoldierAbility('EscapeRoute') && !UnitState.HasSoldierAbility('SilentStab'))
    {
        Modifier = 100;
        SuperConcealedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Super concealment forced reveal");
        UnitState = XComGameState_Unit(SuperConcealedState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
        UnitState.SuperConcealmentLoss = 100;
        `TACTICALRULES.SubmitGameState(SuperConcealedState);
        return true;
    }

    return false;

}

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "ScoutShadow"
}