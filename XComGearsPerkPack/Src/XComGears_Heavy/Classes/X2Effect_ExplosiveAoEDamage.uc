class X2Effect_ExplosiveAoEDamage extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
    local XComGameState_Unit UnitState;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

    EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated',ExplosionOnDeathTrigger, ELD_OnStateSubmitted);


}

static function EventListenerReturn ExplosionOnDeathTrigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState NewGameState;
    local XComGameState_Ability AbilityState;
	local XComGameState_Unit  UnitState, DeadUnit, SourceUnit, TargetUnit;
    local XComGameState_Item SourceWeapon;
    local UnitValue StreakStacks;
    local int CurrentStacks, UpdatedStacks, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    DeadUnit =  XComGameState_Unit(EventData); // 
    UnitState = XComGameState_Unit(EventSource); // 
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
    TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
    SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

//    if (DeadUnit == none || UnitState == none || AbilityContext == none)
//        return ELR_NoInterrupt;
    
    if (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
    {
        if ( TargetUnit.GetTeam() != eTeam_TheLost && SourceUnit.GetTeam() == eTeam_XCom && AbilityState.GetMyTemplateName() == 'ExplosiveShot_I')
        {
            if (TargetUnit.IsDead())
            {
                `Log("Target unit is dead! Now triggering explosion via AbilityActivated Trigger!");
                if (class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(TargetUnit.GetReference(), 'ExplodeOnDeath'))
                    `log("Yay????");
            }

        }
    }    

    return ELR_NoInterrupt;

}



static function EventListenerReturn TriggerExplosionOnDeath(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
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


    AbilityState =  XComGameState_Ability(EventData); // 
    UnitState = XComGameState_Unit(EventSource); // 
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	if (AbilityState == none || UnitState == none || AbilityContext == none)
        return ELR_NoInterrupt;
    

    
    SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));


    	// ??
    if (class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(UnitState.GetReference(), 'ExplodeOnDeath'))
        `log("Yay????");

	return ELR_NoInterrupt;
}