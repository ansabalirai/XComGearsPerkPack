class X2Effect_RecoveryPatch extends X2Effect_Persistent;


function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
    local XComGameState_Unit UnitState;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', TriggerRecoveryPatchEffect, ELD_OnStateSubmitted,,,,UnitState);


    EventMgr.RegisterForEvent(EffectObj, 'RecoveryPatchFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);


}

static function EventListenerReturn TriggerRecoveryPatchEffect(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState_Ability AbilityState;
	local XComGameState_Unit  UnitState, HealedUnitState;
    local XComGameState_Item SourceWeapon;
    local UnitValue CurrentAnchorStacks;
    local int CurrentStacks, UpdatedStacks, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    AbilityState =  XComGameState_Ability(EventData); // 
    UnitState = XComGameState_Unit(EventSource); // 
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
    HealedUnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));


	if (AbilityState == none || UnitState == none || AbilityContext == none)
        return ELR_NoInterrupt;

    if (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
    {
        if (AbilityState.GetMyTemplateName() == 'GremlinHeal' || AbilityState.GetMyTemplateName() == 'MedikitHeal' || AbilityState.GetMyTemplateName() == 'NanoMedikitHeal') // Ideally we should only check for GremlinHeal
        {
            if (UnitState.HasSoldierAbility('RecoveryPatch_III'))
            {
                `log("Applying Recovery patch DR effect III");
                `XEVENTMGR.TriggerEvent('RecoveryPatch', HealedUnitState, UnitState, GameState);
            }

            if (UnitState.HasSoldierAbility('RecoveryPatch_II'))
            {
                `log("Applying Recovery patch DR effect II");
                `XEVENTMGR.TriggerEvent('RecoveryPatch', HealedUnitState, UnitState, GameState);
            }

            if (UnitState.HasSoldierAbility('RecoveryPatch_I'))
            {
                `log("Applying Recovery patch DR effect I");
                class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(HealedUnitState.GetReference(), 'RecoveryPatchDR');
                `XEVENTMGR.TriggerEvent('RecoveryPatch', HealedUnitState, UnitState, GameState);
            }
        }
    }

    return ELR_NoInterrupt;
}


static function EventListenerReturn RecoveryPatchDRListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState_Ability AbilityState;
	local XComGameState_Unit  UnitState, SourceUnit, TargetUnit;
    local XComGameState_Item SourceWeapon;
    local UnitValue FuryTriggersThisTurn;
    local int FuryProcs, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    // EventData: StandardShot
    // EventSource = Enemy Target
    // CallbackData = FurySecondShot
    // AbilityContext = StandardShotContext


    UnitState =  XComGameState_Unit(EventData); // 
    TargetUnit = XComGameState_Unit(EventSource); // 
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	if (TargetUnit == none || UnitState == none || AbilityContext == none)
        return ELR_NoInterrupt;
    

    SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

    	// ??
	if (class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(UnitState.GetReference(), 'RecoveryPatchDR'))
        `XEVENTMGR.TriggerEvent('DRFlyover', AbilityState, UnitState, GameState);

	return ELR_NoInterrupt;
}