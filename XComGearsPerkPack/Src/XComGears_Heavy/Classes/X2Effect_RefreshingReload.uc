class X2Effect_RefreshingReload extends X2Effect_Persistent;

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
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated',RefreshingReloadTrigger, ELD_OnStateSubmitted,,,,AbilityState);
    
    
    EventMgr.RegisterForEvent(EffectObj, 'RefreshingReloadFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);


}

static function EventListenerReturn RefreshingReloadTrigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState NewGameState;
    local XComGameState_Ability AbilityState, SourceAbilityState;
	local XComGameState_Unit  UnitState, SourceUnit, TargetUnit;
    local XComGameState_Item SourceWeapon;
    local UnitValue ReloadsThisTurn;
    local X2Effect_ManualOverride ManualOverrideEffect;
    local EffectAppliedData ApplyData;
    local int Reloads, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    AbilityState =  XComGameState_Ability(EventData); // The shooting ability that needs to trigger Refreshing Reload
    UnitState = XComGameState_Unit(EventSource); // The source unit for whom we trigger Refreshing Reload
    SourceAbilityState = XComGameState_Ability(CallbackData); // The ability whose effect we are in
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	if (AbilityState == none || UnitState == none || AbilityContext == none)
        return ELR_NoInterrupt;

    if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
    {
        // skip
    }

    else
    {
         if( AbilityState.GetMyTemplateName() == 'Reload')
         {
            SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
            TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));

            
            UnitState.GetUnitValue('ReloadsThisTurn', ReloadsThisTurn);
            Reloads = int(ReloadsThisTurn.fValue);

            if (Reloads == 0)
            {
                `Log("First Reload this turn. Applying cooldown reduction...");


                NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Refreshing Reload");
                UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
                
                
                ResetCooldowns(UnitState,NewGameState);
                UnitState.SetUnitFloatValue('ReloadsThisTurn', Reloads + 1, eCleanup_BeginTurn);


                `XEVENTMGR.TriggerEvent('RefreshingReloadFlyover', SourceAbilityState, SourceUnit, NewGameState);
                
                
                
                `XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
            }
         }
    }
    return ELR_NoInterrupt;
}

// Copied from manual override
static function ResetCooldowns(XComGameState_Unit UnitState, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Ability AbilityState;
    local UnitValue ReloadsThisTurn;
	local int i, Reloads;

	History = `XCOMHISTORY;

    UnitState.GetUnitValue('ReloadsThisTurn', ReloadsThisTurn);
    Reloads = int(ReloadsThisTurn.fValue);

    if (Reloads == 0) // Only for the first reload
    {

        for (i = 0; i < UnitState.Abilities.Length; ++i)
        {
            AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitState.Abilities[i].ObjectID));
            if (AbilityState != none && AbilityState.iCooldown > 0)
            {
                AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
                AbilityState.iCooldown = max(0,AbilityState.iCooldown - class'X2Ability_GearsHeavyAbilitySet'.default.RefreshingReloadCooldownReduction);
            }
        }
    }
}