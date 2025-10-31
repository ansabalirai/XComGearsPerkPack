class X2Effect_AtTheReady extends X2Effect_Persistent;

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

    EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated',AtTheReadyTrigger, ELD_OnStateSubmitted,,,,AbilityState);


    EventMgr.RegisterForEvent(EffectObj, 'AtTheReadyFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
}


static function EventListenerReturn AtTheReadyTrigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState NewGameState;
    local XComGameState_Ability AbilityState, FlyoverAbility;
	local XComGameState_Unit  UnitState, DeadUnit, SourceUnit, TargetUnit;
    local XComGameState_Item SourceWeapon;
    local UnitValue StreakStacks;
    local int CurrentStacks, UpdatedStacks, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;


    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
    TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
    SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

    if (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
    {
        if (AbilityState.GetMyTemplateName() == 'Overwatch' && SourceUnit.HasSoldierAbility('AtTheReady'))
        {
            `Log("Overwatch activated! No lowering all ability cooldowns by 1");

            FlyoverAbility = XComGameState_Ability(CallbackData);
            `XEVENTMGR.TriggerEvent('AtTheReadyFlyover', FlyoverAbility, UnitState, GameState);

            for (i = 0; i < SourceUnit.Abilities.Length; ++i)
            {
                AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(SourceUnit.Abilities[i].ObjectID));
                if (AbilityState != none && AbilityState.iCooldown > 0)
                {
                    AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
                    AbilityState.iCooldown = max(0,AbilityState.iCooldown - class'X2Ability_GearsHeavyAbilitySet'.default.AtTheReadyCooldownReduction);
                    `log("Ability cooldown reduced by 1 for: " $ AbilityState.Name);
                }
            }
        }
    }

    return ELR_NoInterrupt;
}