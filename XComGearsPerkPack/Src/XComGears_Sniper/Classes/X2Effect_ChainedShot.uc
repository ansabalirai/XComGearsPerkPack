class X2Effect_ChainedShot extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
    local XComGameState_Unit UnitState;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'UnitTakeEffectDamage',ChainedShotActionTrigger, ELD_OnStateSubmitted,,,,UnitState);

    EventMgr.RegisterForEvent(EffectObj, 'TriggerChainedShotI_Flyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
    EventMgr.RegisterForEvent(EffectObj, 'TriggerChainedShotII_Flyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);


}


static function EventListenerReturn ChainedShotActionTrigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState         NewGameState;
    local XComGameState_Ability AbilityState;
	local XComGameState_Unit  UnitState, SourceUnit;
    local XComGameState_Item SourceWeapon;
    local UnitValue APTrigger;
    local int CurrentStacks, UpdatedStacks, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    UnitState = XComGameState_Unit(EventData); // 
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
    SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

	if (AbilityState == none || UnitState == none || AbilityContext == none || SourceUnit == none)
        return ELR_NoInterrupt;
    
    if (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt && AbilityState.GetMyTemplateName() == 'ChainedShot_I')
    {
        NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Chained Shot AP");
        SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', SourceUnit.ObjectID));
        if (SourceUnit.HasSoldierAbility('ChainedShot_II'))
        {
            `Log("Chained Shot II is triggered for " $ SourceUnit.GetFullName() $ ". Now granting 2 action points");
            SourceUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
            SourceUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
            `XEVENTMGR.TriggerEvent('TriggerChainedShotII_Flyover', AbilityState, SourceUnit, NewGameState);
        }

        else
        {
            `Log("Chained Shot is triggered for " $ SourceUnit.GetFullName() $ ". Now granting 1 action point");
            SourceUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
            `XEVENTMGR.TriggerEvent('TriggerChainedShotI_Flyover', AbilityState, SourceUnit, NewGameState);
        }
        `XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
    }
    return ELR_NoInterrupt;

}