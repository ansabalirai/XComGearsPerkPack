class X2Effect_HeadHunter extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
    local XComGameState_Unit UnitState;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'KillMail',HeadHunterTracker, ELD_OnStateSubmitted,,,, EffectObj);
    EventMgr.RegisterForEvent(EffectObj, 'HeadHunterTriggerFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);


}


static function EventListenerReturn HeadHunterTracker(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState NewGameState;
    local XComGameState_Ability AbilityState, HeadHunterAbilityState;
	local XComGameState_Unit  UnitState, DeadUnit;
    local XComGameState_Item SourceWeapon;
    local XComGameState_Effect			EffectState;
    local UnitValue KillStacks;
    local int CurrentStacks, UpdatedStacks, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    DeadUnit =  XComGameState_Unit(EventData); // 
    UnitState = XComGameState_Unit(EventSource); // 
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
    EffectState = XComGameState_Effect(CallbackData);

    if (DeadUnit == none || UnitState == none || AbilityContext == none)
        return ELR_NoInterrupt;
    
    if (DeadUnit.IsEnemyUnit(UnitState) && DeadUnit.GetTeam() != eTeam_TheLost && UnitState.GetTeam() == eTeam_XCom &&  UnitState.HasSoldierAbility('HeadHunter'))
    {
        UnitState.GetUnitValue('KillsThisMission', KillStacks);
        CurrentStacks = int(KillStacks.fValue);

        UpdatedStacks = CurrentStacks+1;
        `Log("HeadHunter: Updating the current kill stacks for " $ UnitState.GetFullName() $ "to: " $ UpdatedStacks $ " because we got a valid kill");
        UnitState.SetUnitFloatValue('KillsThisMission', UpdatedStacks, eCleanup_BeginTactical);


        if (UpdatedStacks <= class'X2Ability_GearsSniperAbilitySet'.default.MaxHeadHunterDamage)
        {
            HeadHunterAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
            `XEVENTMGR.TriggerEvent('HeadHunterTriggerFlyover', HeadHunterAbilityState, UnitState, GameState);
        }
    }

    return ELR_NoInterrupt;
}


function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local int ExtraDamage;
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(TargetDamageable);

	if (TargetUnit != none && CurrentDamage > 0)
	{
        ExtraDamage =  GetHeadHunterBonusDamage( Attacker);
    }
	
    return ExtraDamage;
}

private function int GetHeadHunterBonusDamage (XComGameState_Unit Attacker)
{

    local UnitValue CurrentStacks;
    local int BonusDamage;

    if (Attacker.GetUnitValue('KillsThisMission', CurrentStacks))
    {
        BonusDamage = int(CurrentStacks.fValue);
    }

    return min(BonusDamage, class'X2Ability_GearsSniperAbilitySet'.default.MaxHeadHunterDamage);

}