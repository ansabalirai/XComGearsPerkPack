class X2Effect_Anchored extends X2Effect_Persistent;

var int MaxAnchorStacks;
var int AnchorAimBonus;
var float AnchorDamageBonus;

var array<name> AbilitiesListForAnchoredStacks;
var array<name> AnchorMoveExemptEffects;

var float DefensiveAnchorDR;


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

	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated',ModifyAnchoredStacksOnShoot, ELD_OnStateSubmitted,,,,AbilityState);
    EventMgr.RegisterForEvent(EffectObj, 'UnitMoveFinished', RemoveAnchoredStacksOnMove, ELD_OnStateSubmitted,,,,AbilityState);
    EventMgr.RegisterForEvent(EffectObj, 'PlayerTurnBegun', RollAnchorStackChance, ELD_OnStateSubmitted,,,,EffectGameState);


    //EventMgr.RegisterForEvent(EffectObj, 'AnchoredFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);


}

/* 'AbilityActivated', AbilityState, SourceUnitState, NewGameState
'PlayerTurnBegun', PlayerState, PlayerState, NewGameState
'PlayerTurnEnded', PlayerState, PlayerState, NewGameState
'UnitDied', UnitState, UnitState, NewGameState
'KillMail', UnitState, Killer, NewGameState
'UnitTakeEffectDamage', UnitState, UnitState, NewGameState
'OnUnitBeginPlay', UnitState, UnitState, NewGameState
'OnTacticalBeginPlay', X2TacticalGameRuleset, none, NewGameState */

static function EventListenerReturn ModifyAnchoredStacksOnShoot(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState_Ability AbilityState, AnchoredAbility;
	local XComGameState_Unit  UnitState;
    local XComGameState_Item SourceWeapon;
    local UnitValue CurrentAnchorStacks;
    local int CurrentStacks, UpdatedStacks, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    AbilityState =  XComGameState_Ability(EventData); // The shooting ability that modifies anchor stacks
    UnitState = XComGameState_Unit(EventSource); // The source unit for whom we need to modify anchor stacks

    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	if (AbilityState == none || UnitState == none || AbilityContext == none)
        return ELR_NoInterrupt;

    AnchoredAbility = XComGameState_Ability(CallbackData);
    if ( !UnitState.HasSoldierAbility(AnchoredAbility.GetMyTemplateName()))
        return ELR_NoInterrupt;

    if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
    {
        //`Log("Interrupt State??");
    }
    else
    {
        //if ( AbilityState.GetMyTemplateName() == 'StandardShot') 
        //if (AbilityState.IsAbilityInputTriggered() && (AbilityState.GetMyTemplate().Hostility == eHostility_Offensive))// || 
    if (class'X2Ability_GearsHeavyAbilitySet'.default.AbilitiesListForAnchoredStacks.Find(AbilityState.GetMyTemplateName()) != -1)
        {
            SourceWeapon = AbilityState.GetSourceWeapon();
            if (SourceWeapon != none && SourceWeapon.InventorySlot == eInvSlot_PrimaryWeapon)
            {
                UnitState.GetUnitValue('AnchorStacks', CurrentAnchorStacks);
                CurrentStacks = int(CurrentAnchorStacks.fValue);
                UpdatedStacks = min(CurrentStacks+1 , class'X2Ability_GearsHeavyAbilitySet'.default.MaxAnchorStacks);
                `Log("Updating the current anchor stacks for " $ UnitState.GetFullName() $ "to: " $ UpdatedStacks $ " because the Ability " $ AbilityState.GetMyTemplateName() $ " was used");
                UnitState.SetUnitFloatValue('AnchorStacks', UpdatedStacks, eCleanup_BeginTactical);


                
                `XEVENTMGR.TriggerEvent('AnchoredFlyover', AnchoredAbility, UnitState, GameState);
            
            }
        }
    }
  
    return ELR_NoInterrupt;
}

static function EventListenerReturn RemoveAnchoredStacksOnMove(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{

    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState_Ability AbilityState, AnchoredAbility;
    local XComGameState_Unit  UnitState;
    local UnitValue CurrentAnchorStacks;
    local int i;

    AbilityState =  XComGameState_Ability(EventData); // The shooting ability that modifies anchor stacks
    UnitState = XComGameState_Unit(EventSource); // The source unit for whom we need to modify anchor stacks
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

    if (UnitState == none )
        return ELR_NoInterrupt;

    AnchoredAbility = XComGameState_Ability(CallbackData);
    if ( !UnitState.HasSoldierAbility(AnchoredAbility.GetMyTemplateName()))
        return ELR_NoInterrupt;

    UnitState.GetUnitValue('AnchorStacks', CurrentAnchorStacks);



    for ( i = 0; i < class'X2Ability_GearsHeavyAbilitySet'.default.AnchorMoveExemptEffects.Length; i++)
    {
        if (UnitState.AffectedByEffectNames.Find(class'X2Ability_GearsHeavyAbilitySet'.default.AnchorMoveExemptEffects[i]) != -1)
        {
            `Log("Unit " $ UnitState.GetFullName() $ "affected by " $ class'X2Ability_GearsHeavyAbilitySet'.default.AnchorMoveExemptEffects[i] $ ". Not reseting the anchored stacks for this move." );
            return ELR_NoInterrupt;
        }
    }

    if (CurrentAnchorStacks.fValue > 0)
    {
        `Log("Reseting the anchor stacks for " $ UnitState.GetFullName() $ " from "  $ int(CurrentAnchorStacks.fValue) $ " since the unit moved" );
        UnitState.SetUnitFloatValue('AnchorStacks', 0, eCleanup_BeginTactical);

        
        //`XEVENTMGR.TriggerEvent('AnchoredFlyover', AnchoredAbility, UnitState, GameState);
    }
    

    return ELR_NoInterrupt;

}

static function EventListenerReturn RollAnchorStackChance(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_Player  Player;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState_Ability AbilityState;
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
    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

    if (UnitState == none || Player == none)
        return ELR_NoInterrupt;
    

    if ( UnitState.IsAbleToAct() && UnitState.HasSoldierAbility('Preparation') && (`SYNC_RAND_STATIC(100) < class'X2Ability_GearsHeavyAbilitySet'.default.PreparationProcChance) && Player.GetTeam() == eTeam_XCom)
    {
        UnitState.GetUnitValue('AnchorStacks', CurrentAnchorStacks);
        CurrentStacks = int(CurrentAnchorStacks.fValue);
        UpdatedStacks = min(CurrentStacks+1 , class'X2Ability_GearsHeavyAbilitySet'.default.MaxAnchorStacks);
        `Log("Updating the current anchor stacks for " $ UnitState.GetFullName() $ "to: " $ UpdatedStacks $ " because of Preparation proc at turn start");
        UnitState.SetUnitFloatValue('AnchorStacks', UpdatedStacks, eCleanup_BeginTactical);




        `XEVENTMGR.TriggerEvent('AnchoredFlyover', AbilityState, UnitState, GameState);
    }

    return ELR_NoInterrupt;
}


function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local int ExtraDamage;
	local XComGameState_Unit TargetUnit;
    local X2AbilityToHitCalc_StandardAim	StandardHit;

	TargetUnit = XComGameState_Unit(TargetDamageable);

    StandardHit = X2AbilityToHitCalc_StandardAim(AbilityState.GetMyTemplate().AbilityToHitCalc);
	if (StandardHit.bIndirectFire)
		return 0;

	if (TargetUnit != none && CurrentDamage > 0)
	{
        ExtraDamage =  GetAnchoredBonusDamage( Attacker);
    }
	
    return ExtraDamage;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
    local int Tiles, CurrentStacks;
    local XComGameState_Item SourceWeapon;
    local X2WeaponTemplate WeaponTemplate;
    local ShotModifierInfo ShotInfo;
    local UnitValue CurrentAnchorStacks;

    if (Attacker.GetUnitValue('AnchorStacks', CurrentAnchorStacks))
    {
        CurrentStacks = int(CurrentAnchorStacks.fValue);
    }


    ShotInfo.Value = class'X2Ability_GearsHeavyAbilitySet'.default.AnchorAimBonus * CurrentStacks;
    ShotInfo.ModType = eHit_Success;
    ShotInfo.Reason = "Anchored";
    ShotModifiers.AddItem(ShotInfo);

}


// Damage Reduction when anchored
function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState)
{
	local XComGameState_Unit				TargetUnit;
	local GameRulesCache_VisibilityInfo		VisInfo;

	if (CurrentDamage > 0)
	{
		TargetUnit = XComGameState_Unit(TargetDamageable);
		if (`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, TargetUnit.ObjectID, VisInfo) && TargetUnit.HasSoldierAbility('DefensiveAnchor'))
		{

            return -(CurrentDamage * class'X2Ability_GearsHeavyAbilitySet'.default.DefensiveAnchorDR);
		}
	}

	return 0;
}








private function int GetAnchoredBonusDamage (XComGameState_Unit Attacker)
{

    local UnitValue CurrentAnchorStacks;
    local float BonusDamage;

    if (Attacker.GetUnitValue('AnchorStacks', CurrentAnchorStacks))
    {
        BonusDamage = class'X2Ability_GearsHeavyAbilitySet'.default.AnchorDamageBonus * int(CurrentAnchorStacks.fValue);
        BonusDamage = min(BonusDamage, class'X2Ability_GearsHeavyAbilitySet'.default.AnchorDamageBonus * class'X2Ability_GearsHeavyAbilitySet'.default.MaxAnchorStacks);
    }

    return int(BonusDamage);

}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyOver;
	local XComGameState_Unit			UnitState;
    local UnitValue                     AnchorStacks;
	local UnitValue						PenaltyStatus;
	local int							InitialMobilityBonus;
	local int							CurrentMobilityBonus;
	local string						FlyoverText;

	if (EffectApplyResult == 'AA_Success')
	{
		UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

        if (UnitState.GetUnitValue('AnchorStacks', AnchorStacks) && AnchorStacks.fValue > 0)
        {
            SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
            FlyoverText = "Anchor Stacks: " $ int(AnchorStacks.fValue);
            SoundAndFlyOver.SetSoundAndFlyOverParameters(None, FlyoverText, '', eColor_Attention, "img:///XPerkIconPack.UIPerk_suppression_blossom");
        }
	}

	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}







defaultproperties
{
	DuplicateResponse=eDupe_Ignore
	EffectName="Anchored"
}