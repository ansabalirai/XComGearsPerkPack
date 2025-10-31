class X2Effect_ActiveReload extends X2Effect_Persistent;

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

        EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated',TriggerActiveReload, ELD_OnStateSubmitted,,,,EffectObj);
        EventMgr.RegisterForEvent(EffectObj, 'SetupFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);


}

static function EventListenerReturn TriggerActiveReload(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState_Ability AbilityState, AnchoredAbility, ActiveReloadAbility;
	local XComGameState_Unit  UnitState;
    local XComGameState_Effect			EffectState;
    local XComGameState_Item SourceWeapon;
    local XComGameState_Item PreviousSourceWeapon;
    local XComGameState PreviousGameState;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    AbilityState =  XComGameState_Ability(EventData); // The ability 
    UnitState = XComGameState_Unit(EventSource); // The source unit 
    EffectState = XComGameState_Effect(CallbackData);
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	if (AbilityState == none || UnitState == none || AbilityContext == none)
        return ELR_NoInterrupt;

    if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
    {
        //`Log("Interrupt State??");
    }
    else
    {
        SourceWeapon = AbilityState.GetSourceWeapon();
        if (SourceWeapon == none)
            return ELR_NoInterrupt;

        if (AbilityState.GetMyTemplateName() == 'Reload')
        {
            PreviousGameState = History.GetPreviousGameStateFromID(GameState.ParentGameStateID);
            if (PreviousGameState != none)
            {
                PreviousSourceWeapon = XComGameState_Item(PreviousGameState.GetGameStateForObjectID(SourceWeapon.ObjectID));
            }

            if (PreviousSourceWeapon == none && History.GetCurrentHistoryIndex() > 0)
            {
                PreviousSourceWeapon = XComGameState_Item(History.GetGameStateForObjectID(SourceWeapon.ObjectID, GameState.HistoryIndex - 1));
            }

            if (PreviousSourceWeapon != none && PreviousSourceWeapon.Ammo == 0)
            {
                UnitState.SetUnitFloatValue('ActiveReloadWeaponRef', SourceWeapon.ObjectID, eCleanup_BeginTurn);
                `Log("Empty Reload! Now triggering bonus damage effect on " $ UnitState.GetFullName());
                `XEVENTMGR.TriggerEvent('ActiveReloadTrigger', AbilityState, UnitState, GameState);

                ActiveReloadAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
                `XEVENTMGR.TriggerEvent('SetupFlyover', ActiveReloadAbility, UnitState, GameState);
            }
        }
    }

    return ELR_NoInterrupt;

}


function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local XComGameState_Unit TargetUnit;
    local UnitValue AvengerDamageBonus;
    local int NumCurrentStacks;

	TargetUnit = XComGameState_Unit(TargetDamageable);

	if (TargetUnit != none && Attacker.AffectedByEffectNames.Find('HeatedUp') != -1 && CurrentDamage > 0)
	{
        // Add additional conditions here for base damage only if needed and special shots that this may not apply to?
        return max(1,CurrentDamage * 0.25);
    }
}