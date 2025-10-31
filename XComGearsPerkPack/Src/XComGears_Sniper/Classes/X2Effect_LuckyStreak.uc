class X2Effect_LuckyStreak extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
    local XComGameState_Unit UnitState;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	//EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated',LuckyStreakBonusCheck, ELD_OnStateSubmitted,,,,UnitState);
}

/*
static function EventListenerReturn LuckyStreakBonusCheck(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState_Ability AbilityState;
	local XComGameState_Unit  UnitState, TargetUnit;
    local XComGameState_Item SourceWeapon;
    local UnitValue CurrentAnchorStacks;
    local int CurrentStacks, UpdatedStacks, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    AbilityState =  XComGameState_Ability(EventData); // The shooting ability that modifies anchor stacks
    UnitState = XComGameState_Unit(EventSource); // The source unit for whom we need to modify anchor stacks
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
    TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));

	if (AbilityState == none || UnitState == none || AbilityContext == none || TargetUnit == none)
        return ELR_NoInterrupt;

    if (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
    {
        if (AbilityCOntext.ResultContext.HitResult == eHit_Crit)
        {
            UnitState.SetUnitFloatValue('LuckyStreak'
        }
    }


}
*/