class X2Effect_SureThing extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
    local XComGameState_Unit UnitState;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'UnitTakeEffectDamage',CheckSureThingTrigger, ELD_OnStateSubmitted,,,,EffectObj);

	EventMgr.RegisterForEvent(EffectObj, 'TriggerSureThingFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);


}



static function EventListenerReturn CheckSureThingTrigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState_Ability AbilityState, SureThingAbility;
	local XComGameState_Unit  UnitState, SourceUnit;
    local XComGameState_Item SourceWeapon;
    local X2AbilityToHitCalc_StandardAim Aim;
    local XComGameState_Effect			EffectState;
    local float CurrentStacks;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    UnitState = XComGameState_Unit(EventData); // 
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
    SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
    EffectState = XComGameState_Effect(CallbackData);
    SureThingAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

	if (AbilityState == none || UnitState == none || AbilityContext == none || SourceUnit == none)
        return ELR_NoInterrupt;
    
    Aim = X2AbilityToHitCalc_StandardAim(AbilityState.GetMyTemplate().AbilityToHitCalc);

    if (Aim == none || Aim.bIndirectFire)
        return ELR_NoInterrupt;

    if (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt && SourceUnit.HasSoldierAbility('SureThing'))
    {
        if (AbilityContext.ResultContext.HitResult == eHit_Crit)
        {
            CurrentStacks = 0;
            SourceUnit.SetUnitFloatValue('SureThingToggle',CurrentStacks, eCleanup_BeginTactical);
            `log("Sure Thing toggled to 0 since we got a crit!");
            `XEVENTMGR.TriggerEvent('TriggerSureThingFlyover', SureThingAbility, SourceUnit, GameState);
        }

        else //if (AbilityContext.ResultContext.HitResult == eHit_Success || AbilityContext.ResultContext.HitResult == eHit_Graze)
        {
            CurrentStacks = 1;
            SourceUnit.SetUnitFloatValue('SureThingToggle',CurrentStacks, eCleanup_BeginTactical);
            `log("Sure Thing toggled to 1 since we did not get a crit!");
            
        }
        
    }
    return ELR_NoInterrupt;

}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
    local ShotModifierInfo ShotInfo;
    local UnitValue CurrentStacks;

    if (Attacker.HasSoldierAbility('SureThing'))
    {
        Attacker.GetUnitValue('SureThingToggle', CurrentStacks);
        if (CurrentStacks.fValue > 0)
        {
            ShotInfo.Value = 20;
            ShotInfo.ModType = eHit_Crit;
            ShotInfo.Reason = "Sure Thing";
            ShotModifiers.AddItem(ShotInfo);
        }
    }
}