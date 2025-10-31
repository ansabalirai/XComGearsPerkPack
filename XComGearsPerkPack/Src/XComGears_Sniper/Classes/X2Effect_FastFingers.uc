class X2Effect_FastFingers extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
    local XComGameState_Unit UnitState;
    local XComGameState_Ability Ability;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
    Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'KillMail',FastFingersTrigger, ELD_OnStateSubmitted,,,,Ability);

	EventMgr.RegisterForEvent(EffectObj, 'TriggerFastFingersFlyover_I', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
    EventMgr.RegisterForEvent(EffectObj, 'TriggerFastFingersFlyover_II', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);


}

static function EventListenerReturn FastFingersTrigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState NewGameState;
    local XComGameState_Ability AbilityState, FlyoverAbilityState;
	local XComGameState_Unit  UnitState, DeadUnit;
    local XComGameState_Item SourceWeapon, PrimaryWeapon, NewWeaponState;
    local UnitValue FastFingerStacks;
    local int CurrentStacks, UpdatedStacks, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    DeadUnit =  XComGameState_Unit(EventData); // 
    UnitState = XComGameState_Unit(EventSource); // 
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

    if (DeadUnit == none || UnitState == none || AbilityContext == none)
        return ELR_NoInterrupt;

    UnitState.GetUnitValue('FastFingersThisTurn', FastFingerStacks);
    if (DeadUnit.IsEnemyUnit(UnitState) && DeadUnit.GetTeam() != eTeam_TheLost && UnitState.GetTeam() == eTeam_XCom && UnitState.HasSoldierAbility('FastFingers_I') && int(FastFingerStacks.fValue) == 0)
    {

        SourceWeapon = AbilityState.GetSourceWeapon();
        if (SourceWeapon != none && SourceWeapon.InventorySlot == eInvSlot_SecondaryWeapon && (SourceWeapon.GetWeaponCategory() == 'pistol' || SourceWeapon.GetWeaponCategory() == 'sidearm') && AbilityState.GetMyTemplateName() == 'PistolStandardShot')
        {
            FlyoverAbilityState = XComGameState_Ability(CallbackData);
            
            
            `log("Fast Fingers I is proccd from " $ AbilityState.GetMyTemplateName() $ " ! We will reload the primary weapon if not already at full ammo");
            PrimaryWeapon = UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, GameState);
            if (PrimaryWeapon != none && (PrimaryWeapon.Ammo < PrimaryWeapon.GetClipSize()))
            {
                //NewWeaponState = XComGameState_Item(NewGameState.ModifyStateObject(PrimaryWeapon.Class, PrimaryWeapon.ObjectID));
                PrimaryWeapon.Ammo = PrimaryWeapon.GetClipSize();
                `XEVENTMGR.TriggerEvent('TriggerFastFingersFlyover_I', FlyoverAbilityState, UnitState, GameState);
            }

            if (UnitState.HasSoldierAbility('FastFingers_II'))
            {
                `log("Fast Fingers II is also proccd! We will also grant a move action point to the unit");

                //UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
                UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);
                `XEVENTMGR.TriggerEvent('TriggerFastFingersFlyover_II', FlyoverAbilityState, UnitState, GameState);

            }
            UnitState.SetUnitFloatValue('FastFingersThisTurn', 1 , eCleanup_BeginTurn);
        }
    }

    return ELR_NoInterrupt;
}

