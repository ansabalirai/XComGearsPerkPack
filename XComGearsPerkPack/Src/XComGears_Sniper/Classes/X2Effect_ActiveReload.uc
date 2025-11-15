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
    local XComGameState_Ability AbilityState, ActiveReloadAbility;
	local XComGameState_Unit  UnitState, SourceUnitState, OwnerUnitState;
    local XComGameState_Effect			EffectState;
    local XComGameState_Item SourceWeapon;
    local XComGameState_Item PreviousSourceWeapon;
    local int HistoryIndex;
	local bool bFoundPreviousState;
	local bool bReloadFromEmpty;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    AbilityState =  XComGameState_Ability(EventData); // The ability 
    SourceUnitState = XComGameState_Unit(EventSource); // The source unit 
    EffectState = XComGameState_Effect(CallbackData);
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	if (AbilityState == none || SourceUnitState == none || AbilityContext == none || EffectState == none)
        return ELR_NoInterrupt;

    OwnerUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
    if (OwnerUnitState == none || OwnerUnitState.ObjectID != SourceUnitState.ObjectID)
        return ELR_NoInterrupt;


	UnitState = XComGameState_Unit(GameState.ModifyStateObject(class'XComGameState_Unit', SourceUnitState.ObjectID));
	if (UnitState == none)
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
            if (GameState.HistoryIndex > 0)
            {
                HistoryIndex = GameState.HistoryIndex - 1;

                while (PreviousSourceWeapon == none && HistoryIndex >= 0)
                {
                    PreviousSourceWeapon = XComGameState_Item(History.GetGameStateForObjectID(SourceWeapon.ObjectID,, HistoryIndex));
                    HistoryIndex--;
                }

				if (PreviousSourceWeapon != none)
				{
					bFoundPreviousState = true;
					bReloadFromEmpty = (PreviousSourceWeapon.Ammo == 0);
				}
            }

			if (UnitState.IsUnitAffectedByEffectName('ActiveReloadBonusDamageEffect') && (!bFoundPreviousState || !bReloadFromEmpty))
			{
				RemoveActiveReloadBonus(UnitState, GameState);
			}

            if (bFoundPreviousState && bReloadFromEmpty)
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


static function RemoveActiveReloadBonus(XComGameState_Unit UnitState, XComGameState GameState)
{
	local XComGameState_Effect BonusEffect;

	if (UnitState == none)
		return;

	BonusEffect = UnitState.GetUnitAffectedByEffectState('ActiveReloadBonusDamageEffect');
	if (BonusEffect != none)
	{
		BonusEffect.RemoveEffect(GameState, GameState);
	}

	UnitState.SetUnitFloatValue('ActiveReloadActive', 0, eCleanup_BeginTurn);
	UnitState.SetUnitFloatValue('ActiveReloadWeaponRef', 0, eCleanup_BeginTurn);
}

// function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
// {
// 	local XComGameState_Unit TargetUnit;
//     local UnitValue AvengerDamageBonus;
//     local int NumCurrentStacks;

// 	TargetUnit = XComGameState_Unit(TargetDamageable);

// 	if (TargetUnit != none && Attacker.AffectedByEffectNames.Find('ActiveReloadBonusDamageEffect') != -1 && CurrentDamage > 0)
// 	{
//         // Add additional conditions here for base damage only if needed and special shots that this may not apply to?
//         return max(1,CurrentDamage * 0.25);
//     }
// }
