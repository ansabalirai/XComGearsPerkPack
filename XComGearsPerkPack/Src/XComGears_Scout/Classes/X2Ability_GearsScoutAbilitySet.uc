class X2Ability_GearsScoutAbilitySet extends XMBAbility config(GearsScoutAbilitySet);


/* 
Gears Scout:
    Shotgun/Knife

Squaddie skills:
    Cloak (Conceal with a cooldown/charges? Infinite duration or ?)
    Phantom?

Raider:
    Double shot I, II, III(Rapid fire? with second shot at a different enemy within x tiles and reduce cooldown of rampage/serial by 1 turn)
    Blood Rush (Kills grant increased movement for x turns)
    Exertion I, II (Gain extra 1/2 actions but take increased damage for x turns (negative DR))

Slayer (map to primary weapon):
    Finisher I, II, III (Increased +25/+50 hit/crit chance vs wounded enemies and reduced cooldown)
    Energized (Increased crit chance on the first shot of magazine)
    Assassination (Phantom kills grant 1 action)
    Escape route (1st crit kill per turn does not break concealment)
    

Recon:
    Sprint I, II, III (Activate to grant increased movement and decreased detection radius for 1 turn, with buff at lvl 2 and cooldown reduction at lvl 3)
    Anticipation I, II (Activate to start next turn with 1 extra action)
    Stalker (Increased movement bonus when concealed)
    Obfuscate (Conceal target non-phantom ally)

Commando (map to secondary weapon):
    Free Cloak (Using cloak is free/non-turn ending) + Quick Cloak (Reduce cloaking cooldown (and incresed duration if we have finite duration?))
    Silent Stab (1st Knife kill per turn does not break concealment?)
    Cutthroat
    Ambush (Passive damage boost when concealed)
    Regenerative cloak (Heal when cloaking)
    Relentless (First knife kill per turn gives 1 AP back) */


var config bool ExertionCausesDamage;
var config int 	DoubleShot_II_Distance;
var config int 	DoubleShot_III_Distance;


static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(ScoutShadow());

    // Raider
    Templates.AddItem(DoubleShot_I());
        Templates.AddItem(DoubleShot_SecondShot());
        Templates.AddItem(DoubleShot_II());
        Templates.AddItem(DoubleShot_III());
    Templates.AddItem(BloodRush());
    Templates.AddItem(Exertion_I());
        Templates.AddItem(Exertion_II());
	Templates.AddItem(Magnum());
	Templates.AddItem(HuntersInstinct());
    

    // Slayer
    Templates.AddItem(Finisher_I());
        Templates.AddItem(Finisher_II());
        Templates.AddItem(Finisher_III());
        Templates.AddItem(FinisherShotBonus());
    Templates.AddItem(Energized());
    Templates.AddItem(Assassination());
    Templates.AddItem(EscapeRoute());
	
    // Recon
    Templates.AddItem(Sprint_I());
        Templates.AddItem(Sprint_II());
        Templates.AddItem(Sprint_III());
    Templates.AddItem(Anticipation_I());
        Templates.AddItem(Anticipation_II());
    
    Templates.AddItem(Obfuscate());

    // Commando
    // Blademaster
    Templates.AddItem(QuickCloak());
    Templates.AddItem(SilentStab());
    Templates.AddItem(Cutthroat());
    Templates.AddItem(Ambush());
    Templates.AddItem(SliceAndDice());
    
    return Templates;
}



static function X2AbilityTemplate ScoutShadow()
{
	local X2AbilityTemplate						Template;
	local X2Effect_ScoutShadow                       StealthEffect;
	local X2Effect_PersistentStatChange         StatEffect, StealthyEffect;
    local X2Effect_StayConcealed                StayConcealedEffect;
	local X2AbilityCost_ActionPoints            ActionPointCost;
	local X2AbilityCooldownReduction            Cooldown;
	local X2AbilityCost_Charges					ChargeCost;
	local X2Condition_UnitEffects				ExcludeEffects;
	local X2Condition_UnitValue ValueCondition;
    local array<name>       CooldownAbilities;
    local array<int>       CooldownAmount;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ScoutShadow');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_shadow";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	ActionPointCost =  new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
    ActionPointCost.bConsumeAllPoints = false;
	ActionPointCost.bFreeCost = false;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityShooterConditions.AddItem(new class'X2Condition_Concealed');
	Template.AddShooterEffectExclusions();

	// Check that scout is not currently exerting
	ValueCondition = new class'X2Condition_UnitValue';
	ValueCondition.AddCheckValue('ScoutExertion', 0, eCheck_Exact,,,'AA_RunAndGunUsed');
	Template.AbilityShooterConditions.AddItem(ValueCondition);


	ExcludeEffects = new class'X2Condition_UnitEffects';
	ExcludeEffects.AddExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName, 'AA_UnitIsImmune');
	Template.AbilityTargetConditions.AddItem(ExcludeEffects);



    Cooldown = new class'X2AbilityCooldownReduction';
    Cooldown.BaseCooldown = 4;

    CooldownAbilities.AddItem('QuickCloak');
    CooldownAmount.AddItem(1);

    Cooldown.CooldownReductionAbilities = CooldownAbilities;
    Cooldown.CooldownReductionAmount = CooldownAmount;
    

    Template.AbilityCooldown = Cooldown; // Add abilities that lower the cooldown here

	StealthEffect = new class'X2Effect_ScoutShadow';
	StealthEffect.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnBegin);
	StealthEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	StealthEffect.bRemoveWhenTargetConcealmentBroken = true;
    //StealthEffect.EffectAddedFn = ShadowStarted;
	StealthEffect.EffectRemovedFn = ShadowExpired;
    //StealthEffect.VisualizationFn =  VisualizeShadowExpired;
    StealthEffect.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(StealthEffect);

	StatEffect = new class'X2Effect_PersistentStatChange';
	StatEffect.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnBegin);
	StatEffect.AddPersistentStatChange(eStat_DetectionModifier, 0.99f); // No need to add this since we handle it via the SuperConcealmentLoss instead
    StatEffect.AddPersistentStatChange(eStat_Mobility, 3);
    StatEffect.bRemoveWhenTargetConcealmentBroken = true;
    StatEffect.bRemoveWhenTargetDies = true;
    //Template.AbilityTargetConditions.AddItem(StalkerCondition);
	Template.AddTargetEffect(StatEffect);

	StayConcealedEffect = new class'X2Effect_StayConcealed';
	StayConcealedEffect.EffectName = 'ShadowIndividualConcealment';
	StayConcealedEffect.BuildPersistentEffect(1, true, false);
	Template.AddTargetEffect(StayConcealedEffect);


	Template.AddTargetEffect(class'X2Ability_ReaperAbilitySet'.static.ShadowAnimEffect());
	Template.AddTargetEffect(class'X2Effect_Spotted'.static.CreateUnspottedEffect());

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipExitCoverWhenFiring = true;
//BEGIN AUTOGENERATED CODE: Template Overrides 'Shadow'
	Template.bSkipFireAction = true;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.CustomFireAnim = 'NO_ShadowStart';
	Template.ActivationSpeech = 'ActivateConcealment';
//END AUTOGENERATED CODE: Template Overrides 'Shadow'
	//Template.AdditionalAbilities.AddItem('ShadowPassive');
	
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;
	
	return Template;
}

function ShadowStarted(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
    local XComGameState_Unit UnitState;

    UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
    if (UnitState != none)
    {
        UnitState.bHasSuperConcealment = true;
        UnitState.SuperConcealmentLoss = 25;
    }
	XComGameState_Unit(kNewTargetState).bHasSuperConcealment = true;
    XComGameState_Unit(kNewTargetState).SuperConcealmentLoss = 25;
}

static function ShadowExpired(
	X2Effect_Persistent PersistentEffect,
	const out EffectAppliedData ApplyEffectParameters,
	XComGameState NewGameState,
	bool bCleansed)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	UnitState.bHasSuperConcealment = false;

	`XEVENTMGR.TriggerEvent('ShadowExpired', UnitState, UnitState, NewGameState);
	`XEVENTMGR.TriggerEvent('EffectBreakUnitConcealment', UnitState, UnitState, NewGameState);
}

static function VisualizeShadowExpired(
	XComGameState VisualizeGameState,
	out VisualizationActionMetadata ActionMetadata,
	const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(none, "Shadow!", '', eColor_Bad);
}

static function X2AbilityTemplate EscapeRoute()
{
	local X2AbilityTemplate					Template;

    Template = PurePassive('EscapeRoute',"img:///XPerkIconPack.UIPerk_stealth_shot");

	// local X2Effect_EscapeRoute			Effect;

	// `CREATE_X2ABILITY_TEMPLATE(Template, 'EscapeRoute');
	// Template.IconImage = "";
	// Template.AbilitySourceName = 'eAbilitySource_Perk';
	// Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	// Template.Hostility = eHostility_Neutral;

	// Template.AbilityToHitCalc = default.DeadEye;
	// Template.AbilityTargetStyle = default.SelfTarget;
	// Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Effect = new class'X2Effect_EscapeRoute';
	// Effect.BuildPersistentEffect(1, true, false, false);
	// Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
	// Template.AddTargetEffect(Effect);

	// Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate SilentStab()
{
	local X2AbilityTemplate					Template;
    Template = PurePassive('SilentStab', "img:///XPerkIconPack.UIPerk_stealth_knife");
	// local X2Effect_SilentStab			Effect;

	// `CREATE_X2ABILITY_TEMPLATE(Template, 'SilentStab');
	// Template.IconImage = "";
	// Template.AbilitySourceName = 'eAbilitySource_Perk';
	// Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	// Template.Hostility = eHostility_Neutral;

	// Template.AbilityToHitCalc = default.DeadEye;
	// Template.AbilityTargetStyle = default.SelfTarget;
	// Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Effect = new class'X2Effect_SilentStab';
	// Effect.BuildPersistentEffect(1, true, false, false);
	// Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
	// Template.AddTargetEffect(Effect);

	// Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}



static function X2AbilityTemplate DoubleShot_I()
{
	local X2AbilityTemplate Template;
	local X2AbilityCooldownReduction	Cooldown;


	// Create the template using a helper function
	Template = Attack('DoubleShot_I', "img:///XPerkIconPack.UIPerk_shot_x2", true, none, class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY, eCost_WeaponConsumeAll, 1);

	
	Cooldown = new class'X2AbilityCooldownReduction';
	Cooldown.BaseCooldown = 3;
	Template.AbilityCooldown = Cooldown;

	Template.AdditionalAbilities.AddItem('DoubleShot_SecondShot');
	Template.PostActivationEvents.AddItem('DoubleShot_SecondShot');

	return Template;
}


static function X2AbilityTemplate DoubleShot_SecondShot()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCost_Ammo				AmmoCost;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;
	local X2AbilityTrigger_EventListener    Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DoubleShot_SecondShot');

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	Template.AbilityToHitCalc = ToHitCalc;
	Template.AbilityToHitOwnerOnMissCalc = ToHitCalc;

	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);

	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AssociatedPassives.AddItem('HoloTargeting');
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'DoubleShot_SecondShot';
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = DoubleShotListener;
	Template.AbilityTriggers.AddItem(Trigger);

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_shot_x2";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.MergeVisualizationFn = SequentialShot_MergeVisualization;
	
	Template.bShowActivation = true;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
//BEGIN AUTOGENERATED CODE: Template Overrides 'RapidFire2'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'RapidFire2'

	return Template;

}

static function X2AbilityTemplate DoubleShot_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('DoubleShot_II', "img:///XPerkIconPack.UIPerk_shot_x2");
	Template.bUniqueSource = true;
    Template.PrerequisiteAbilities.AddItem('DoubleShot_I');

	return Template;
}

static function X2AbilityTemplate DoubleShot_III()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('DoubleShot_III', "img:///XPerkIconPack.UIPerk_shot_x2");
	Template.bUniqueSource = true;
    
    Template.PrerequisiteAbilities.AddItem('DoubleShot_I');
    Template.PrerequisiteAbilities.AddItem('DoubleShot_II');

	return Template;
}


static function EventListenerReturn DoubleShotListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local X2WeaponTemplate	Weapon;
	local XComGameState_Unit Killer, OriginalTargetState, PossibleTargetState;
	local array<StateObjectReference> PossibleTargets, PrunedTargets;
	local StateObjectReference Target, OriginalTarget;
    local int i;
	//local array<X2Condition> Conditions;

	History = `XCOMHISTORY;
	//  We need to check if the source unit has the lvl 2 or 3 version of the ability and then select the target accordingly
    // EventData = DoubleShot_I Ability
    // EventSource = Scout Unit/Killer
    // CallBackData = SecondShot Ability


	Killer = XComGameState_Unit(EventSource);
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	Weapon = X2WeaponTemplate(XComGameState_Ability(History.GetGameStateForObjectId(AbilityContext.InputContext.AbilityRef.ObjectID)).GetSourceWeapon().GetMyTemplate());

    OriginalTargetState = XComGameState_Unit(History.GetGameStateForObjectId(AbilityContext.InputContext.PrimaryTarget.ObjectID));

    if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
        return ELR_NoInterrupt;


	if (Killer != None && Weapon != None )
	{
        // lvl 3
        if (Killer.HasSoldierAbility('DoubleShot_III'))
        {
            if (OriginalTargetState != none && !(OriginalTargetState.IsDead()))
            {
                class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(Killer.GetReference(), 'DoubleShot_SecondShot', AbilityContext.InputContext.PrimaryTarget);
                return ELR_NoInterrupt;
            }
            
            else
            {
                class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(Killer.ObjectID, PossibleTargets);
                for (i = 0; i < PossibleTargets.Length ; i++)
                {
                    PossibleTargetState = XComGameState_Unit(History.GetGameStateForObjectId(PossibleTargets[i].ObjectID));
                    if (Killer.TileDistanceBetween(PossibleTargetState) <= default.DoubleShot_III_Distance)
                    {
                        PrunedTargets.AddItem(PossibleTargets[i]);
                    }

                }
                `log("DoubleShot_SecondShot Listener: After pruning, the set of targets left are:" $ PrunedTargets.Length);
                Target = PrunedTargets[`SYNC_RAND_STATIC(PrunedTargets.length)];
                class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(Killer.GetReference(), 'DoubleShot_SecondShot', Target);
            }
        }

        else if (Killer.HasSoldierAbility('DoubleShot_II'))
        {
            if (OriginalTargetState != none && !(OriginalTargetState.IsDead()))
            {
                class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(Killer.GetReference(), 'DoubleShot_SecondShot', AbilityContext.InputContext.PrimaryTarget);
                return ELR_NoInterrupt;
            }
            
            else
            {
                class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(Killer.ObjectID, PossibleTargets);
                for (i = 0; i < PossibleTargets.Length ; i++)
                {
                    PossibleTargetState = XComGameState_Unit(History.GetGameStateForObjectId(PossibleTargets[i].ObjectID));
                    if (Killer.TileDistanceBetween(PossibleTargetState) <= default.DoubleShot_II_Distance)
                    {
                        PrunedTargets.AddItem(PossibleTargets[i]);
                    }

                }
                `log("DoubleShot_SecondShot Listener: After pruning, the set of targets left are:" $ PrunedTargets.Length);
                Target = PrunedTargets[`SYNC_RAND_STATIC(PrunedTargets.length)];
                class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(Killer.GetReference(), 'DoubleShot_SecondShot', Target);
            }
        }

        else
        {
            if (OriginalTargetState != none && !(OriginalTargetState.IsDead()))
            {
                class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(Killer.GetReference(), 'DoubleShot_SecondShot', AbilityContext.InputContext.PrimaryTarget);
            }

        }
		// // pick a random target
		// class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(Killer.ObjectID, PossibleTargets);
		// if (PossibleTargets.length > 0)
		// {
		// 	Target = PossibleTargets[`SYNC_RAND_STATIC(PossibleTargets.length)];
		// 	class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(Killer.GetReference(), 'DoubleShot_SecondShot', Target);
		// }
	}

	return ELR_NoInterrupt;
}

static function X2AbilityTemplate BloodRush()
{
	local X2AbilityTemplate						Template;
	local X2Effect_PersistentStatChange			StatChangeEffect;
	local X2AbilityTrigger_EventListener		EventListenerTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'BloodRush');
//BEGIN AUTOGENERATED CODE: Template Overrides 'FullThrottle'
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_FullThrottle";
	Template.ActivationSpeech = 'FullThrottle';
//END AUTOGENERATED CODE: Template Overrides 'FullThrottle'

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	
	EventListenerTrigger = new class'X2AbilityTrigger_EventListener';
	EventListenerTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListenerTrigger.ListenerData.EventID = 'UnitDied';
	EventListenerTrigger.ListenerData.Filter = eFilter_None;
	EventListenerTrigger.ListenerData.EventFn = class'XComGameState_Ability'.static.FullThrottleListener;
	Template.AbilityTriggers.AddItem(EventListenerTrigger);

	StatChangeEffect = new class'X2Effect_PersistentStatChange';
	StatChangeEffect.AddPersistentStatChange(eStat_Mobility, 3);	
	StatChangeEffect.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnEnd);
	StatChangeEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
	StatChangeEffect.EffectName = 'BloodRushStats';
	Template.AddTargetEffect(StatChangeEffect);

    Template.bSkipFireAction = false;
    Template.bShowActivation = true;
    Template.CustomFireAnim = 'HL_SignalYellA';
    Template.CinescriptCameraType = "ChosenAssassin_HarborWave";
    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
    Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

    AddIconPassive(Template);

	return Template;
}


static function X2AbilityTemplate Exertion_I()
{
	local X2AbilityTemplate				Template;
	local X2AbilityCooldown				Cooldown;
	local X2Effect_GrantActionPoints    ActionPointEffect;
	local X2AbilityCost_ActionPoints    ActionPointCost;
    local X2Effect_ApplyWeaponDamage    DamageEffect;
    local X2Effect_DamageReduction      DamageReductionEffect1;
	local X2Effect_PersistentStatChange	ReducedDefenseStatEffect, ReducedWillStatEffect;
	local X2Effect_SetUnitValue ValueEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Exertion_I');

	// Icon Properties
	Template.DisplayTargetHitChance = false;
	Template.AbilitySourceName = 'eAbilitySource_Perk';                                       // color of the icon
	Template.IconImage = "img:///XPerkIconPack.UIPerk_move_circle";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY;
	Template.Hostility = eHostility_Neutral;
	Template.ConcealmentRule = eConceal_Never; // Breaks concealment
	Template.SuperConcealmentLoss = 100;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilityConfirmSound = "TacticalUI_Activate_Ability_Run_N_Gun";

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 5;
	Template.AbilityCooldown = Cooldown;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;

	ValueEffect = new class'X2Effect_SetUnitValue';
	ValueEffect.UnitName = 'ScoutExertion';
	ValueEffect.NewValueToSet = 1;
	ValueEffect.CleanupType = eCleanup_BeginTurn;
	Template.AddTargetEffect(ValueEffect);


	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	ActionPointEffect = new class'X2Effect_GrantActionPoints';
	ActionPointEffect.NumActionPoints = 1;
	ActionPointEffect.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
	Template.AddTargetEffect(ActionPointEffect);

/*     if (default.ExertionCausesDamage)
    {
        DamageEffect = new class'X2Effect_ApplyWeaponDamage';
        DamageEffect.bIgnoreBaseDamage = true;
        DamageEffect.DamageTag = 'Exertion_I';
        Template.AddTargetEffect(DamageEffect);
    }
    else
    {
        DamageReductionEffect1 = new class'X2Effect_DamageReduction';
        DamageReductionEffect1.EffectName = 'Exertion_DR';
        DamageReductionEffect1.bAbsoluteVal = true;
        DamageReductionEffect1.DamageReductionAbs = -1;
        DamageReductionEffect1.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
        DamageReductionEffect1.SetDisplayInfo(ePerkBuff_Penalty, "Exertion I", "Exertion I", Template.IconImage,false,,Template.AbilitySourceName);
        DamageReductionEffect1.DuplicateResponse = eDupe_Allow;
        Template.AddTargetEffect(DamageReductionEffect1);
    } */

	// Add reduced defense and will effect
	ReducedDefenseStatEffect = new class'X2Effect_PersistentStatChange';
	ReducedDefenseStatEffect.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnEnd);
	ReducedDefenseStatEffect.AddPersistentStatChange(eStat_Defense, -20);
    ReducedDefenseStatEffect.bPersistThroughTacticalGameEnd = false;
	Template.AddTargetEffect(ReducedDefenseStatEffect);

	ReducedWillStatEffect = new class'X2Effect_PersistentStatChange';
	ReducedWillStatEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
	ReducedWillStatEffect.AddPersistentStatChange(eStat_Will, -4);
    ReducedWillStatEffect.bPersistThroughTacticalGameEnd = true;
	Template.AddTargetEffect(ReducedWillStatEffect);

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.bShowActivation = true;
	Template.bSkipFireAction = true;

	Template.ActivationSpeech = 'RunAndGun';
		
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.bCrossClassEligible = true;

	return Template;
}

static function X2AbilityTemplate Exertion_II()
{
	local X2AbilityTemplate				Template;
	local X2AbilityCooldown				Cooldown;
	local X2Effect_GrantActionPoints    ActionPointEffect;
	local X2AbilityCost_ActionPoints    ActionPointCost;
    local X2Effect_ApplyWeaponDamage    DamageEffect;
    local X2Effect_DamageReduction      DamageReductionEffect1;
	local X2Effect_PersistentStatChange	ReducedDefenseStatEffect, ReducedWillStatEffect;
	local X2Effect_SetUnitValue ValueEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Exertion_II');

	// Icon Properties
	Template.DisplayTargetHitChance = false;
	Template.AbilitySourceName = 'eAbilitySource_Perk';                                       // color of the icon
	Template.IconImage = "img:///XPerkIconPack.UIPerk_move_box";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY;
	Template.Hostility = eHostility_Neutral;
	Template.ConcealmentRule = eConceal_Never; // Breaks concealment
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilityConfirmSound = "TacticalUI_Activate_Ability_Run_N_Gun";

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 5;
	Template.AbilityCooldown = Cooldown;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;

	ValueEffect = new class'X2Effect_SetUnitValue';
	ValueEffect.UnitName = 'ScoutExertion';
	ValueEffect.NewValueToSet = 1;
	ValueEffect.CleanupType = eCleanup_BeginTurn;
	Template.AddTargetEffect(ValueEffect);
	
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	ActionPointEffect = new class'X2Effect_GrantActionPoints';
	ActionPointEffect.NumActionPoints = 2;
	ActionPointEffect.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
	Template.AddTargetEffect(ActionPointEffect);

    // if (default.ExertionCausesDamage)
    // {
    //     DamageEffect = new class'X2Effect_ApplyWeaponDamage';
    //     DamageEffect.bIgnoreBaseDamage = true;
    //     DamageEffect.DamageTag = 'Exertion_II';
    //     Template.AddTargetEffect(DamageEffect);
    // }
    // else
    // {
    //     DamageReductionEffect1 = new class'X2Effect_DamageReduction';
    //     DamageReductionEffect1.EffectName = 'Exertion_DR';
    //     DamageReductionEffect1.bAbsoluteVal = true;
    //     DamageReductionEffect1.DamageReductionAbs = -2;
    //     DamageReductionEffect1.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnEnd);
    //     DamageReductionEffect1.SetDisplayInfo(ePerkBuff_Bonus, "Exertion I", "Exertion I", Template.IconImage,false,,Template.AbilitySourceName);
    //     DamageReductionEffect1.DuplicateResponse = eDupe_Allow;
    //     Template.AddTargetEffect(DamageReductionEffect1);
    // }

	// Add reduced defense and will effect
	ReducedDefenseStatEffect = new class'X2Effect_PersistentStatChange';
	ReducedDefenseStatEffect.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnEnd);
	ReducedDefenseStatEffect.AddPersistentStatChange(eStat_Defense, -40);
    ReducedDefenseStatEffect.bPersistThroughTacticalGameEnd = false;
	Template.AddTargetEffect(ReducedDefenseStatEffect);

	ReducedWillStatEffect = new class'X2Effect_PersistentStatChange';
	ReducedWillStatEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
	ReducedWillStatEffect.AddPersistentStatChange(eStat_Will, -8);
    ReducedWillStatEffect.bPersistThroughTacticalGameEnd = true;
	Template.AddTargetEffect(ReducedWillStatEffect);

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.bShowActivation = true;
	Template.bSkipFireAction = true;

	Template.ActivationSpeech = 'RunAndGun';
		
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.bCrossClassEligible = true;

    Template.OverrideAbilities.AddItem('Exertion_I');

	return Template;
}

static function X2AbilityTemplate Finisher_I()
{
	local X2AbilityTemplate Template;
	local X2AbilityCooldownReduction	Cooldown;
    local array<name>       CooldownAbilities;
    local array<int>        CooldownAmount;
    local X2Condition_UnitStatCheck Condition;


	// Create the template using a helper function
	Template = Attack('Finisher_I', "img:///XPerkIconPack.UIPerk_crit_chevron", true, none, class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY, eCost_WeaponConsumeAll, 1);

	Condition = new class'X2Condition_UnitStatCheck';
	Condition.AddCheckStat(eStat_HP, 100, eCheck_LessThan,,, true);
    Template.AbilityTargetConditions.AddItem(Condition);
	
	Cooldown = new class'X2AbilityCooldownReduction';
	Cooldown.BaseCooldown = 5;

    CooldownAbilities.AddItem('Finisher_III');
    CooldownAmount.AddItem(2);
    Cooldown.CooldownReductionAbilities = CooldownAbilities;
    Cooldown.CooldownReductionAmount = CooldownAmount;

	Template.AbilityCooldown = Cooldown;

	Template.AdditionalAbilities.AddItem('FinisherShotBonus');

	return Template;
}

static function X2AbilityTemplate Finisher_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Finisher_II', "img:///XPerkIconPack.UIPerk_crit_chevron_x2");
	Template.bUniqueSource = true;

    Template.PrerequisiteAbilities.AddItem('Finisher_I');
	return Template;
}

static function X2AbilityTemplate Finisher_III()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Finisher_III', "img:///XPerkIconPack.UIPerk_crit_chevron_x3");
	Template.bUniqueSource = true;

    Template.PrerequisiteAbilities.AddItem('Finisher_I');
    Template.PrerequisiteAbilities.AddItem('Finisher_II');
	return Template;
}

static function X2AbilityTemplate FinisherShotBonus()
{
	local X2AbilityTemplate Template;
    local X2Effect_Finisher    Effect;

    `CREATE_X2ABILITY_TEMPLATE (Template, 'FinisherShotBonus');
    Template.IconImage = "img:///XPerkIconPack.UIPerk_crit_chevron";
    Template.AbilitySourceName = 'eAbilitySource_Perk';
    Template.eAbilityIconBehaviorHUD = 2;
    Template.Hostility = 2;
    Template.AbilityToHitCalc = default.DeadEye;
    Template.AbilityTargetStyle = default.SelfTarget;
    Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

    Effect = new class'X2Effect_Finisher';
    Effect.BuildPersistentEffect(1, true, false, false);
    Effect.SetDisplayInfo(0, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false,, Template.AbilitySourceName);
    Template.AddTargetEffect(Effect);
    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;


	return Template;
}

static function X2AbilityTemplate Energized()
{
	local X2AbilityTemplate						Template;
	local X2Effect_AlphaOmega 					EnergizedEffect;

    EnergizedEffect = new class'X2Effect_AlphaOmega';
    EnergizedEffect.EffectName = 'Energized';
    EnergizedEffect.EnergizedCritBonus = 40;


	Template = Passive('Energized', "img:///XPerkIconPack.UIPerk_ammo_crit",,EnergizedEffect);

	return Template;

}

static function X2AbilityTemplate Assassination()
{
	local X2AbilityTemplate						Template;
	local X2Effect_Assassination 				Effect;




    Effect = new class'X2Effect_Assassination';
	Effect.USES_PER_TURN = 1;
	Effect.ProcChance = 100;

	Template = Passive('Assassination', "img:///XPerkIconPack.UIPerk_stealth_command",,Effect);

	return Template;

}


static function X2AbilityTemplate Sprint_I()
{
	local X2AbilityTemplate				Template;
	local X2AbilityCooldownReduction				Cooldown;
	local X2Effect_GrantActionPoints    ActionPointEffect;
	local X2AbilityCost_ActionPoints    ActionPointCost;
    local X2Effect_PersistentStatChange      StatEffect, StatEffect2;
    local X2Condition_SourceHasAbility      SprintIICondition;
    local array<name>       CooldownAbilities;
    local array<int>       CooldownAmount;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Sprint_I');

	// Icon Properties
	Template.DisplayTargetHitChance = false;
	Template.AbilitySourceName = 'eAbilitySource_Perk';                                       // color of the icon
	Template.IconImage = "img:///XPerkIconPack.UIPerk_move_blaze";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY;
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilityConfirmSound = "TacticalUI_Activate_Ability_Run_N_Gun";

	Cooldown = new class'X2AbilityCooldownReduction';
	Cooldown.BaseCooldown = 3;

    CooldownAbilities.AddItem('Sprint_III');
    CooldownAmount.AddItem(1);

    Cooldown.CooldownReductionAbilities = CooldownAbilities;
    Cooldown.CooldownReductionAmount = CooldownAmount;
    
	Template.AbilityCooldown = Cooldown;


	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
    Template.AbilityShooterConditions.AddItem(new class'X2Condition_RequireConcealed');
	Template.AddShooterEffectExclusions();

	StatEffect = new class'X2Effect_PersistentStatChange';
	StatEffect.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnEnd);
	StatEffect.AddPersistentStatChange(eStat_DetectionModifier, 0.33f);
    StatEffect.AddPersistentStatChange(eStat_Mobility, 3);
    StatEffect.bRemoveWhenTargetConcealmentBroken = true;
    StatEffect.bRemoveWhenTargetDies = true;
	Template.AddTargetEffect(StatEffect);


    SprintIICondition = new class'X2Condition_SourceHasAbility';
    SprintIICondition.Abilities.AddItem('Sprint_II');



	StatEffect2 = new class'X2Effect_PersistentStatChange';
	StatEffect2.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnEnd);
	StatEffect2.AddPersistentStatChange(eStat_DetectionModifier, 0.33f);
    StatEffect2.AddPersistentStatChange(eStat_Mobility, 2);
    StatEffect2.bRemoveWhenTargetConcealmentBroken = true;
    StatEffect2.bRemoveWhenTargetDies = true;
    StatEffect.TargetConditions.AddItem(SprintIICondition);
	Template.AddTargetEffect(StatEffect2);

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

    Template.bShowActivation = true;
    Template.bSkipFireAction = false;
    Template.CustomFireAnim = 'HL_VanishingWind';
    Template.CinescriptCameraType = "ChosenAssassin_VanishingWind";
    Template.ActivationSpeech = 'RunAndGun';
		
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.bCrossClassEligible = true;

	return Template;
}


static function X2AbilityTemplate Sprint_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Sprint_II', "img:///XPerkIconPack.UIPerk_move_blaze");
	Template.bUniqueSource = true;

    Template.PrerequisiteAbilities.AddItem('Sprint_I');
	return Template;
}

static function X2AbilityTemplate Sprint_III()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Sprint_III', "img:///XPerkIconPack.UIPerk_move_blaze");
	Template.bUniqueSource = true;

    Template.PrerequisiteAbilities.AddItem('Sprint_II');
    Template.PrerequisiteAbilities.AddItem('Sprint_I');
	return Template;
}


static function X2AbilityTemplate Anticipation_I()
{
	local X2AbilityTemplate				Template;
	local X2AbilityCooldownReduction				Cooldown;
	local X2Effect_GrantActionPoints    ActionPointEffect;
	local X2AbilityCost_ActionPoints    ActionPointCost;
    local X2Effect_Anticipation      Effect;
    local X2Condition_SourceHasAbility      SprintIICondition;
    local array<name>       CooldownAbilities;
    local array<int>       CooldownAmount;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Anticipation_I');

	// Icon Properties
	Template.DisplayTargetHitChance = false;
	Template.AbilitySourceName = 'eAbilitySource_Perk';                                       // color of the icon
	Template.IconImage = "img:///XPerkIconPack.UIPerk_move_lightning";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY;
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilityConfirmSound = "TacticalUI_Activate_Ability_Run_N_Gun";

	Cooldown = new class'X2AbilityCooldownReduction';
	Cooldown.BaseCooldown = 6;    
	Template.AbilityCooldown = Cooldown;


	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Effect = new class'X2Effect_Anticipation';
    Effect.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnEnd);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

    Template.bShowActivation = true;
    Template.bSkipFireAction = false;
    Template.CustomFireAnim = 'HL_Teamwork';
    Template.CinescriptCameraType = "Skirmisher_CombatPresence";
    Template.ActivationSpeech = 'KillZone';
		
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.bCrossClassEligible = true;

	return Template;
}

static function X2AbilityTemplate Anticipation_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Anticipation_II', "img:///XPerkIconPack.UIPerk_move_lightning");
	Template.bUniqueSource = true;

    Template.PrerequisiteAbilities.AddItem('Anticipation_I');
	return Template;
}

static function X2AbilityTemplate Ambush()
{
	local X2AbilityTemplate				Template;
    local XMBEffect_ConditionalStatChange MobilityEffect;
    local XMBEffect_ConditionalBonus DamageEffect;


	
    Template = Passive('Ambush', "img:///XPerkIconPack.UIPerk_knife_blossom", true);

    MobilityEffect = new class'XMBEffect_ConditionalStatChange';
	MobilityEffect.EffectName = 'Ambush';
	MobilityEffect.AddPersistentStatChange(eStat_Mobility, 3);
	MobilityEffect.Conditions.AddItem(new class'X2Condition_RequireConcealed');
    Template.AddTargetEffect(MobilityEffect);

	DamageEffect = new class'XMBEffect_ConditionalBonus';
	DamageEffect.EffectName = 'Ambush';
	DamageEffect.AddPercentDamageModifier(50);
    DamageEffect.AbilityTargetConditionsAsTarget.AddItem(new class'X2Condition_RequireConcealed');
    Template.AddTargetEffect(DamageEffect);

    return Template;
}

static function X2AbilityTemplate Obfuscate()
{
	local X2AbilityTemplate				Template;
	local X2AbilityCost_ActionPoints	ActionPointCost;
	local X2Condition_UnitProperty		TargetProperty, ShooterProperty;
	local X2Effect_ApplySmokeGrenadeToWorld WeaponEffect;
	local X2Effect_RangerStealth		StealthEffect;
	local X2AbilityMultiTarget_Radius		RadiusMultiTarget;
	local X2AbilityCharges					Charges;
	local X2AbilityCost_Charges				ChargeCost;
	local X2Condition_UnitEffects			NotCarryingCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Obfuscate');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_ghost"; 
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
    Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.bCrossClassEligible = false;
	Template.bIsPassive = false;
	Template.bDisplayInUITacticalText = false;
    //Template.bHideWeaponDuringFire = true;
	Template.bLimitTargetIcons = true;
    //Template.bHideAmmoWeaponDuringFire = true;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
    ActionPointCost.iNumPoints = 1;
    ActionPointCost.bConsumeAllPoints = true;
    Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
    Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	
	ShooterProperty = new class'X2Condition_UnitProperty';
	Template.AbilityShooterConditions.AddItem(ShooterProperty);

	TargetProperty = new class'X2Condition_UnitProperty';
    TargetProperty.ExcludeDead = true;
    TargetProperty.ExcludeHostileToSource = true;
    TargetProperty.ExcludeFriendlyToSource = false;
    TargetProperty.RequireSquadmates = true;
	TargetProperty.ExcludeConcealed = true;
	TargetProperty.ExcludeCivilian = true;
	TargetProperty.ExcludeImpaired = true;
	TargetProperty.FailOnNonUnits = true;
	TargetProperty.IsAdvent = false;
	TargetProperty.ExcludePanicked = true;
	TargetProperty.ExcludeAlien = true;
	TargetProperty.IsBleedingOut = false;
	TargetProperty.IsConcealed = false;
	TargetProperty.ExcludeStunned = true;
	TargetProperty.IsImpaired = false;
    Template.AbilityTargetConditions.AddItem(TargetProperty);
	
	NotCarryingCondition = new class'X2Condition_UnitEffects';
	NotCarryingCondition.AddExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName, 'AA_CarryingUnit');
	NotCarryingCondition.AddExcludeEffect(class'X2StatusEffects'.default.BurningName, 'AA_UnitIsBurning');
	NotCarryingCondition.AddExcludeEffect(class'X2AbilityTemplateManager'.default.BoundName, 'AA_UnitIsBound');
	Template.AbilityTargetConditions.AddItem(NotCarryingCondition);

	Charges = new class'X2AbilityCharges';
    Charges.InitialCharges = 1;
    Template.AbilityCharges = Charges;
    ChargeCost = new class'X2AbilityCost_Charges';
    ChargeCost.NumCharges = 1;
    Template.AbilityCosts.AddItem(ChargeCost);


	StealthEffect = new class'X2Effect_RangerStealth';
    StealthEffect.BuildPersistentEffect(1, true, false, false, 8);
    StealthEffect.SetDisplayInfo(1, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
    StealthEffect.bRemoveWhenTargetConcealmentBroken = true;
    Template.AddTargetEffect(StealthEffect);
    Template.AddTargetEffect(class'X2Effect_Spotted'.static.CreateUnspottedEffect());

	Template.TargetingMethod = class'X2TargetingMethod_OvertheShoulder';

    Template.TargetHitSpeech = 'ActivateConcealment';

    Template.bSkipFireAction = false;
    Template.bSkipExitCoverWhenFiring = true;
    Template.CustomFireAnim = 'NO_ShadowStart';
    Template.ActivationSpeech = 'ActivateConcealment';
    Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
    Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	return Template;
}

static function X2AbilityTemplate QuickCloak()
{
    local X2AbilityTemplate					Template;
    local X2Effect_QuickCloak               Effect;

    Effect = new class'X2Effect_QuickCloak';
    Effect.VALID_ABILITIES.AddItem('ScoutShadow');

	Template =  Passive('QuickCloak', "img:///XPerkIconPack.UIPerk_stealth_box", false, Effect );

    Template.PrerequisiteAbilities.AddItem('ScoutShadow');

    return Template;
}

static function X2AbilityTemplate Cutthroat()
{
	local X2AbilityTemplate					Template;
	local X2Effect_Cutthroat				ArmorPiercingBonus;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'XGT_Cutthroat');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_knife_adrenaline";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bIsPassive = true;
	Template.bCrossClassEligible = false;

	ArmorPiercingBonus = new class 'X2Effect_Cutthroat';
	ArmorPiercingBonus.BuildPersistentEffect (1, true, false);
	ArmorPiercingBonus.Bonus_Crit_Chance = 15;
	ArmorPiercingBonus.Bonus_Crit_Damage = 2;
	ArmorPiercingBonus.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect (ArmorPiercingBonus);
	
    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;	
	//no visualization
	return Template;		
}


static function X2AbilityTemplate SliceAndDice()
{
	local X2AbilityTemplate						Template;
	local X2Effect_SliceAndDice 				Effect;




    Effect = new class'X2Effect_SliceAndDice';
	Effect.USES_PER_TURN = 1;
	Effect.ProcChance = 100;

	Template = Passive('XGT_SliceAndDice', "img:///XPerkIconPack.UIPerk_command_knife",,Effect);

	return Template;

}


// Perk name:		Magnum
// Perk effect:		Your pistol attacks get +10 Aim and deal +1 damage.
static function X2AbilityTemplate Magnum()
{
	local XMBEffect_ConditionalBonus Effect;

	// Create an effect that adds +10 to hit and +1 damage
	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.AddDamageModifier(1);
	Effect.AddToHitModifier(10);

	// Restrict to the weapon matching this ability
	Effect.AbilityTargetConditions.AddItem(default.MatchingWeaponCondition);

	return Passive('XGT_Magnum', "img:///UILibrary_PerkIcons.UIPerk_command", false, Effect);
}

// Perk name:		Hunters Instinct
// Perk effect:		You get an additional +25 Crit chance against flanked targets and do +2 crit damage.
static function X2AbilityTemplate HuntersInstinct()
{
	local XMBEffect_ConditionalBonus Effect;

	// Create a conditional bonus
	Effect = new class'XMBEffect_ConditionalBonus';

	Effect.AddToHitModifier(25, eHit_Crit);
	Effect.AddDamageModifier(2, eHit_Crit);


	// The bonus only applies while flanking
	Effect.AbilityTargetConditions.AddItem(default.FlankedCondition);

	// Create the template using a helper function
	return Passive('XGT_HuntersInstinct', "img:///UILibrary_PerkIcons.UIPerk_command", true, Effect);
}