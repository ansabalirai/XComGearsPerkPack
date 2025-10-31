class X2Effect_Embers extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
    local XComGameState_Unit UnitState;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));


    EventMgr.RegisterForEvent(EffectObj, 'PlayerTurnBegun', RollEmbersProcChance, ELD_OnStateSubmitted,,,,EffectObj);


    EventMgr.RegisterForEvent(EffectObj, 'EmbersFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);


}

static function EventListenerReturn RollEmbersProcChance(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_Player  Player;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState_Ability AbilityState, EmbersAbility;
	local XComGameState_Unit  UnitState;
    local XComGameState_Item SourceWeapon;
    local XComGameState_Effect			EffectState;
    local UnitValue CurrentAnchorStacks, Preparation;
    local int CurrentStacks, UpdatedStacks, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    EffectState = XComGameState_Effect(CallbackData);
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID)); // The source unit for whom we need to modify anchor stacks
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
    Player = XComGameState_Player(EventData);
    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

    if (UnitState == none || Player == none)
        return ELR_NoInterrupt;
    

    if ( UnitState.IsAbleToAct() && UnitState.HasSoldierAbility('Embers') && Player.GetTeam() == eTeam_XCom)
    {
        for (i = 0; i < UnitState.Abilities.Length; ++i)
        {
            AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitState.Abilities[i].ObjectID));
            if (AbilityState.GetMyTemplateName() == 'HeatUp_I' && AbilityState.iCooldown > 0)
            {
                if (`SYNC_RAND_STATIC(100) < class'X2Ability_GearsHeavyAbilitySet'.default.EmbersProcChance)
                {
                   `XEVENTMGR.TriggerEvent('HeatUpFreeTrigger', AbilityState, UnitState, GameState);
                   //AbilityState.iCooldown = 0;
                    //if (AbilityState.AbilityTriggerAgainstSingleTarget(UnitState.GetReference(), false))
                    `Log("Proccing Embers for " $ UnitState.GetFullName());

                    EmbersAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

                    `XEVENTMGR.TriggerEvent('EmbersFlyover', EmbersAbility, UnitState, GameState);

                    //class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(UnitState.GetReference(), 'HeatUp_I', UnitState.GetReference());
                }
            }
        }
        
    }

    return ELR_NoInterrupt;
}