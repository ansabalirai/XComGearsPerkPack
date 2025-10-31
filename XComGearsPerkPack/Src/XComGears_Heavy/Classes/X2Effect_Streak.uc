class X2Effect_Streak extends X2Effect_Persistent;

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

	EventMgr.RegisterForEvent(EffectObj, 'KillMail',TrackStreakStacks, ELD_OnStateSubmitted,,,,AbilityState);
    EventMgr.RegisterForEvent(EffectObj, 'StreakFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);


}

/* 'AbilityActivated', AbilityState, SourceUnitState, NewGameState
'PlayerTurnBegun', PlayerState, PlayerState, NewGameState
'PlayerTurnEnded', PlayerState, PlayerState, NewGameState
'UnitDied', UnitState, UnitState, NewGameState
'KillMail', UnitState, Killer, NewGameState
'UnitTakeEffectDamage', UnitState, UnitState, NewGameState
'OnUnitBeginPlay', UnitState, UnitState, NewGameState
'OnTacticalBeginPlay', X2TacticalGameRuleset, none, NewGameState 

TriggerAbilityFlyover
	UnitState = XComGameState_Unit(EventSource);
	AbilityState = XComGameState_Ability(EventData);
*/



static function EventListenerReturn TrackStreakStacks(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState NewGameState;
    local XComGameState_Ability AbilityState, StreakAbility;
	local XComGameState_Unit  UnitState, DeadUnit;
    local XComGameState_Item SourceWeapon;
    local UnitValue StreakStacks;
    local int CurrentStacks, UpdatedStacks, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    DeadUnit =  XComGameState_Unit(EventData); // 
    UnitState = XComGameState_Unit(EventSource); // 
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

    if (DeadUnit == none || UnitState == none || AbilityContext == none)
        return ELR_NoInterrupt;

    if (DeadUnit.IsEnemyUnit(UnitState) && DeadUnit.GetTeam() != eTeam_TheLost && UnitState.GetTeam() == eTeam_XCom && DeadUnit.GetMyTemplateName() != 'PsiZombie' &&	DeadUnit.GetMyTemplateName() != 'PsiZombieHuman')
    {
        UnitState.GetUnitValue('StreakStacks', StreakStacks);
        CurrentStacks = int(StreakStacks.fValue);

        NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Updating Streak Stacks");
        UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));


        if (CurrentStacks < (class'X2Ability_GearsHeavyAbilitySet'.default.MaxStreakStacks - 1))    // Increment stacks until max
        {
            UpdatedStacks = CurrentStacks+1;
            `Log("Updating the current streak stacks for " $ UnitState.GetFullName() $ "to: " $ UpdatedStacks $ " because we got a valid kill");
            UnitState.SetUnitFloatValue('StreakStacks', UpdatedStacks, eCleanup_BeginTactical);
        }
        else // After 3 kills, Reset the stacks and grant action point
        {
            UpdatedStacks = 0;
            UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
            `Log("Reseting the current streak stacks for " $ UnitState.GetFullName() $ "to: " $ UpdatedStacks $ " and granting an action point");
            UnitState.SetUnitFloatValue('StreakStacks', UpdatedStacks, eCleanup_BeginTactical);

            StreakAbility = XComGameState_Ability(CallbackData);
            `XEVENTMGR.TriggerEvent('StreakFlyover', StreakAbility, UnitState, GameState);
            
        }
        `XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

    }
    return ELR_NoInterrupt;
}

