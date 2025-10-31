class X2Effect_Fury extends X2Effect_Persistent;

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

	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated',CheckFuryTrigger, ELD_OnStateSubmitted,,,,AbilityState);
    EventMgr.RegisterForEvent(EffectObj, 'FuryFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);

}

static function EventListenerReturn CheckFuryTrigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState_Ability AbilityState, FuryAbility;
	local XComGameState_Unit  UnitState, SourceUnit, TargetUnit;
    local XComGameState_Item SourceWeapon;
    local UnitValue FuryTriggersThisTurn;
    local int FuryProcs, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    AbilityState =  XComGameState_Ability(EventData); // The shooting ability that needs to trigger Fury
    UnitState = XComGameState_Unit(EventSource); // The source unit for whom we trigger Fury
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	if (AbilityState == none || UnitState == none || AbilityContext == none)
        return ELR_NoInterrupt;

    FuryAbility = XComGameState_Ability(CallbackData);
    if ( !UnitState.HasSoldierAbility(FuryAbility.GetMyTemplateName()))
        return ELR_NoInterrupt;

    if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
    {
        //`Log("Interrupt State??");
    }
    else
    {
        if ( AbilityState.GetMyTemplateName() == 'StandardShot') // Todo: Add in other possible shots as well if needed via config
        {
           	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
            TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
            SourceWeapon = AbilityState.GetSourceWeapon();

            if (SourceWeapon != none && SourceWeapon.InventorySlot == eInvSlot_PrimaryWeapon && SourceWeapon.Ammo > 0 && (AbilityContext.ResultContext.HitResult == eHit_Graze || AbilityContext.ResultContext.HitResult == eHit_Miss))
            {
                UnitState.GetUnitValue('FuryTriggersThisTurn', FuryTriggersThisTurn);
                FuryProcs = int(FuryTriggersThisTurn.fValue);
                if (FuryProcs == 0)
                {
                    `Log("The shot was a graze or miss. Proccing a fury trigger");
                    UnitState.SetUnitFloatValue('FuryTriggersThisTurn', FuryProcs + 1, eCleanup_BeginTurn);
                    `XEVENTMGR.TriggerEvent('FuryActivationTrigger', AbilityState, TargetUnit, GameState);
                }
                else
                {
                    `Log("The shot was a graze or miss but we seem to have already procced fury this turn. No more triggers");
                    return ELR_NoInterrupt;
                }
            }
            
        }
    }
  
    return ELR_NoInterrupt;
}


static function EventListenerReturn TriggerFurySecondShot(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
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
    

    
    `Log("We are in the fury second shot trigger!");
    SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));


    	// ??
	class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(SourceUnit.GetReference(), 'FurySecondShot', UnitState.GetReference());

	return ELR_NoInterrupt;
}