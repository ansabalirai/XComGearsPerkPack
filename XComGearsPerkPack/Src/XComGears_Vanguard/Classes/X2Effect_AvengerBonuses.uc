class X2Effect_AvengerBonuses extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
    local XComGameState_Unit UnitState;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	//EventMgr.RegisterForEvent(EffectObj, 'UnitDied',AvengerBonusActionPoints, ELD_OnStateSubmitted,,,, EffectObj);
    EventMgr.RegisterForEvent(EffectObj, 'UnitTakeEffectDamage',AvengerBonusDamage, ELD_OnStateSubmitted,,,, EffectObj);
    EventMgr.RegisterForEvent(EffectObj, 'AvengerFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
}

static function EventListenerReturn AvengerBonusDamage(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState_Ability AbilityState, FlyoverAbilityState;
	local XComGameState_Unit TargetUnit, SourceUnit, UnitState;
    local XComGameState_Effect			EffectState;
    local X2SoldierClassTemplate SoldierClassTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState NewGameState;
	local UnitValue AvengerDamageBonus;
    local int i, j;


    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
    EffectState = XComGameState_Effect(CallbackData);
    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));


	if (AbilityContext != none && AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
    {
        TargetUnit = XComGameState_Unit(EventData);

        for (i = 0; i < XComHQ.Squad.Length; i++)
		{
			if (XComHQ.Squad[i].ObjectID != 0)
			{
				UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Squad[i].ObjectID));
                if (UnitState.HasSoldierAbility('Avenger'))
                {
                    `log("The target unit is " $ TargetUnit.GetFullName() $ " and the effect source unit is : " $ UnitState.GetFullName() $ "and we are triggering AvengerBonusDamage eventlistener");

                    if (TargetUnit.GetTeam() == eTeam_XCom)
                    {
                        // Get current damage bonus stack and update as needed
                        UnitState.GetUnitValue('AvengerDamageBonusStacks',AvengerDamageBonus);
                        if ((AvengerDamageBonus.fValue < 4))
                        {
                            `LOG("Avenger damage tracker: " $ int(AvengerDamageBonus.fValue ) $ " are less than 4. Granting additional damage stack");
                            // Increment the activation tracker
                            AvengerDamageBonus.fValue += 1.0;
                            UnitState.SetUnitFloatValue('AvengerDamageBonusStacks', AvengerDamageBonus.fValue, eCleanup_BeginTactical);

                            FlyoverAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
                            `XEVENTMGR.TriggerEvent('AvengerFlyover', FlyoverAbilityState, UnitState, GameState);

                        }
                    }
                }
            }
        }
    }

    return ELR_NoInterrupt;

}

// static function EventListenerReturn AvengerBonusActionPoints(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
// {
//     local XComGameStateContext_Ability AbilityContext;
//     local XComGameState_HeadquartersXCom XComHQ;
//     local XComGameStateHistory	History;
//     local XComGameState_Ability AbilityState;
// 	local XComGameState_Unit TargetUnit, SourceUnit, UnitState;
//     local XComGameState_Effect			EffectState;
//     local X2SoldierClassTemplate SoldierClassTemplate;
// 	local X2AbilityTemplate AbilityTemplate;
// 	local XComGameState NewGameState;
// 	local UnitValue AvengerBonusActions, BonusActionsThisTurn;
//     local int i, j;

//     History = `XCOMHISTORY;
//     XComHQ = `XCOMHQ;
//     AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
//     EffectState = XComGameState_Effect(CallbackData);
//     AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

// 	TargetUnit = XComGameState_Unit(EventData);
//     SourceUnit = XComGameState_Unit(EventSource);
//     UnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));


//     `log("The target unit is " $ TargetUnit.GetFullName() $ " and the source unit is : " $ SourceUnit.GetFullName() $ " and the effect source unit is : " $ UnitState.GetFullName() $ "and we are triggering AvengerBonusActionPoints eventlistener");

//     if (TargetUnit != none && (TargetUnit.GetTeam() == eTeam_XCom) && TargetUnit.IsDead())
// 	{
//         for (i = 0; i < XComHQ.Squad.Length; i++)
// 		{
// 			if (XComHQ.Squad[i].ObjectID != 0)
// 			{
// 				UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Squad[i].ObjectID));
//                 if (UnitState.HasSoldierAbility('Avenger'))
//                 {

//                     // 
//                     UnitState.GetUnitValue('AvengerBonusActions',AvengerBonusActions);
//                     if ((AvengerBonusActions.fValue < XComHQ.Squad.Length - 1)) // Assuming we will not trigger more than once per squad member?
//                     {
//                         `LOG("Avenger bonus actions tracker: " $ int(AvengerBonusActions.fValue ) $ " are less than" $ XComHQ.Squad.Length $ ". Granting additional actions");
//                         // Increment the activation tracker
//                         AvengerBonusActions.fValue += 1.0;
//                         UnitState.SetUnitFloatValue('AvengerBonusActions', AvengerBonusActions.fValue, eCleanup_BeginTactical);
                
//                         UnitState.SetUnitFloatValue('AvengerBonusActionsThisTurn', 3, eCleanup_BeginTurn);
//                         UnitState.SetUnitFloatValue('NonTurnEndingActionsThisTurn', 3, eCleanup_BeginTactical);

//                         //	if it's the unit's current turn, give them an action immediately
//                         if (`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID == UnitState.ControllingPlayer.ObjectID)
//                         {
//                             if (UnitState.IsAbleToAct())
//                             {
//                                 // NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Skirmisher Reflex Immediate Action");
//                                 // TargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(TargetUnit.Class, TargetUnit.ObjectID));
//                                 //TargetUnit.SetUnitFloatValue(class'X2Effect_SkirmisherReflex'.default.TotalEarnedValue, TotalValue.fValue + 1, eCleanup_BeginTactical);
//                                 UnitState.ActionPoints.Length = 0;
//                                 // Add 3 actions?
//                                 UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
//                                 UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
//                                 UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
//                                 `XEVENTMGR.TriggerEvent('AvengerFlyover', AbilityState, UnitState, GameState);
//                             }
//                         }

//                         //	Modify turn start action points for next turn if this is not unit's current turn
//                         if (`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID != UnitState.ControllingPlayer.ObjectID)
//                         {

//                             `LOG("Avenger bonus actions tracker: Since this enemy turn, we modify the starting action points for next turn instead?");
//                             `XEVENTMGR.TriggerEvent('AvengerFlyover', AbilityState, UnitState, GameState);
//                         }

                        

//                     }
//                 }
//             }
//         }
//     }

//     return ELR_NoInterrupt;
// }



// function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
// {
// 	local XComGameState_Unit TargetUnit;
// 	local X2EventManager EventMgr;
// 	local XComGameState_Ability AbilityState;
//     local UnitValue AvengerBonusActionsThisTurn;
//     local int RemainingActionsThisTurn, i;


//     if (kAbility.GetMyTemplateName() == 'StandardShot' || kAbility.GetMyTemplateName() == 'SwordSlice') // seems to cover all relevant cases...
//     {
//         if (SourceUnit.GetUnitValue('NonTurnEndingActionsThisTurn',AvengerBonusActionsThisTurn) && PreCostActionPoints.Length > 0)
//         {
//             if ((AvengerBonusActionsThisTurn.fValue > 0) ) // We have bonus actions this turn
//             {
//                 `log("The unit is " $ SourceUnit.GetFullName() $ " and they have total actions this turn: " $ PreCostActionPoints.Length);
//                 RemainingActionsThisTurn = int(AvengerBonusActionsThisTurn.fValue) - 1;

//                 for (i = 0; i < RemainingActionsThisTurn; i++)
//                 {
//                     SourceUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
//                 }
//                 SourceUnit.SetUnitFloatValue('NonTurnEndingActionsThisTurn', AvengerBonusActionsThisTurn.fValue - 1, eCleanup_BeginTactical);
//                 return true;

//             }
//         }
//     }
//     return false;
// }


//////////////////////////////////////////////////////////////////////////////////////////////
function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local XComGameState_Unit TargetUnit;
    local UnitValue AvengerDamageBonus;
    local int NumCurrentStacks;

	TargetUnit = XComGameState_Unit(TargetDamageable);

	if (TargetUnit != none && Attacker.GetUnitValue('AvengerDamageBonusStacks',AvengerDamageBonus) && CurrentDamage > 0)
	{
        NumCurrentStacks = int(AvengerDamageBonus.fValue);
    }
	
    return NumCurrentStacks;
}

// function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
// {
// 	local int i;
// 	local int ActionPointsRemoved;
// 	local name ActionPointType;
//     local UnitValue AvengerBonusActionsThisTurn;
    
// 	ActionPointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
//     UnitState.ActionPoints.Length = 0;

//     if (UnitState.GetUnitValue('AvengerBonusActionsThisTurn',AvengerBonusActionsThisTurn))
//     {
//         if ((AvengerBonusActionsThisTurn.fValue > 0))
//         {
//             UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
//             UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
//             UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);

            
//         }
//     }

// }
