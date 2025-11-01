class X2Ability_GearsHeavyAbilitySet extends XMBAbility config(GearsHeavyAbilitySet);
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
GearsHeavy:
    Cannon/GrenadeLauncher

Squaddie skills:
    Traverse Fire (LW2)
    Anchor (stacking aim and damage buff when taking a shot, max 3, removed when moving)

Specialist:
    Redeploy I, II (Activate to get 3 move actions only without losing anchored buffs/decrease cooldown)
    Fury (Missing or grazing triggers another shot)
    Refreshing Reload (Reload reduced all cooldowns by 1. Once per turn)
    Streak (On kill, gain 1 stack of the Streak status effect. When reaching 5 stacks of Streak, this unit gains 1 Action and loses all stacks)
    Preparation (35% chance to gain an achored stack each turn)
    Payback (Gain crit chance when taking damage during enemy turn for 1 turn)

Artillery:
    Reckless shot I, II, III (Increased crit chance (and aim?) shot)
    Heat Up I, II (Activate to increase damage by 25%/Auto reload)
    Banish
    Embers (20% chance to gain heat up at start of turn when it is on cooldown)

Defender:
    Suppressing Fire I, II, III (area suppression with opportunist; increased aoe and reduce cooldown)
    At the Ready (Overwatch reduces cooldown of all abilities by 1)
    Defensive anchor (20% DR when anchored)
    Counter Push (Kills on overwatch/suppression grant +3 mob (non-stacking) on the next turn)
    Slayer (Increased damage on OW and suppression shots)

Demolitionist (most likely one to get grenade perks from base game mixed in):
    Explosive shot I, II, III (special shot that explodes target enemy (carrying grenade?) in an increasing radius and dealing increasing damage)
    Dig in I, II (Activated ability to grant surrounding allies +10/+20 aim)
    Demolition (base game)
    Heavy Frags I, II, III (Grenades get bonus use, have increased damage and increased radius)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 */
var config int MaxAnchorStacks;
var config int AnchorAimBonus;
var config float AnchorDamageBonus;

var config array<name> AbilitiesListForAnchoredStacks;
var config array<name> AnchorMoveExemptEffects;

var config float DefensiveAnchorDR;

var config int RedployAPCost;
var config int RedployBaseCooldown;
var config int RedployII_CooldownReduction;

var config int RefreshingReloadCooldownReduction;

var config int PreparationProcChance;

var config int MaxStreakStacks;

var config int RecklessShotCooldown;
var config int RecklessShotCritBonusI, RecklessShotCritBonusII, RecklessShotCritBonusIII;

var config float HeatUpBonusDamage;
var config int HeatUpCooldown;

var config int EmbersProcChance;

var config int ExplosiveShotCooldown;
var config int ExplosiveShotRadius;

var config int DigInCooldown, DigInRadius;
var config int DigInAimBonusI, DigInAimBonusII;

var config int AtTheReadyCooldownReduction;

var config int CounterPushMobilityBonus;
var config int SlayerDamageBonus;


var config int FULL_KIT_BONUS;
var config array<name> FULL_KIT_ITEMS;



static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Anchor());
    Templates.AddItem(TraverseFire());

    //Specialist
    Templates.AddItem(Redeploy_I());
    Templates.AddItem(Redeploy_II());
    Templates.AddItem(Fury());
        Templates.AddItem(FurySecondShot());
    Templates.AddItem(RefreshingReload());
    Templates.AddItem(Preparation());
    Templates.AddItem(Streak());

    // Artillery
    Templates.AddItem(RecklessShot_I());
        Templates.AddItem(RecklessShot_II());
        Templates.AddItem(RecklessShotBonus());
    Templates.AddItem(HeatUp_I());
        Templates.AddItem(HeatUp_II());
        Templates.AddItem(Embers());
        Templates.AddItem(HeatUp_FreeVersion());
	Templates.AddItem(DefensiveAnchor());
	// Banish - Base game with cooldown instead of charges
    
    // Defender
    // Ever Vigilant
    Templates.AddItem(SuppressiveFire());
    // CUP
    Templates.AddItem(AtTheReady());
    // Sentinel/Guardian
    Templates.AddItem(CounterPush());
    Templates.AddItem(Slayer());



    // Demolistionist
    Templates.AddItem(ExplosiveShot_I());
        Templates.AddItem(ExplodeOnDeath());
    Templates.AddItem(DigIn_I());
    Templates.AddItem(DigIn_II());
    // Demolition - Base game
    //HeavyOrdnance
    //BiggestBooms
    //VolatileMix
	Templates.AddItem(XGT_FullKit());

	return Templates;
}

// Perk name:		Traverse Fire
// Perk effect:		After taking a standard shot with your primary weapon with your first action, you may take an additional non-movement action.
// Localized text:	"After taking a standard shot with your primary weapon with your first action, you may take an additional non-movement action."
// Config:			(AbilityName="Heavy_TraverseFire")
static function X2AbilityTemplate TraverseFire()
{
	local X2Effect_GrantActionPoints Effect;
	local X2AbilityTemplate Template;
	local XMBCondition_AbilityCost CostCondition;
	local XMBCondition_AbilityName NameCondition;

	// Add a single non-movement action point to the unit
	Effect = new class'X2Effect_GrantActionPoints';
	Effect.NumActionPoints = 1;
	Effect.PointType = class'X2CharacterTemplateManager'.default.RunAndGunActionPoint;

	// Create a triggered ability that will activate whenever the unit uses an ability that meets the condition
	Template = SelfTargetTrigger('Heavy_TraverseFire', "img:///XPerkIconPack.UIPerk_shot_box", false, Effect, 'AbilityActivated');

	// Trigger abilities don't appear as passives. Add a passive ability icon.
	AddIconPassive(Template);

	// Require that the activated ability costs 1 action point but actually spent at least 2
	CostCondition = new class'XMBCondition_AbilityCost';
	CostCondition.bRequireMaximumCost = true;
	CostCondition.MaximumCost = 1;
	CostCondition.bRequireMinimumPointsSpent = true;
	CostCondition.MinimumPointsSpent = 2;
	AddTriggerTargetCondition(Template, CostCondition);
    
	// The bonus only applies to standard shots
	NameCondition = new class'XMBCondition_AbilityName';
	NameCondition.IncludeAbilityNames.AddItem('StandardShot');
	NameCondition.IncludeAbilityNames.AddItem('SniperStandardFire');
	AddTriggerTargetCondition(Template, NameCondition);

	// Show a flyover when Traverse Fire is activated
	Template.bShowActivation = true;

	return Template;
}

// Perk name:		Anchor
// Perk effect:		When this unit Shoots, it gets one stack of the Anchored status effect, to a maximum of 3 stacks. Units with Anchored get +10% Accuracy and +15% Damage per stack. Units lose Anchored if they move..
// Localized text:	When this unit Shoots, it gets one stack of the Anchored status effect, to a maximum of 3 stacks. Units with Anchored get +10% Accuracy and +15% Damage per stack. Units lose Anchored if they move.
// Config:			(AbilityName="Anchor")
static function X2AbilityTemplate Anchor()
{
	local X2Effect_Anchored Effect;
	local X2AbilityTemplate Template;
    local array<name>       ExemptEffects;




	`CREATE_X2ABILITY_TEMPLATE(Template, 'Anchor');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_suppression_blossom";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bIsPassive = true;

	Effect = new class'X2Effect_Anchored';
	Effect.MaxAnchorStacks = default.MaxAnchorStacks;
	Effect.AnchorAimBonus = default.AnchorAimBonus;
	Effect.AnchorDamageBonus = default.AnchorDamageBonus;
	Effect.AbilitiesListForAnchoredStacks = default.AbilitiesListForAnchoredStacks;
	Effect.AnchorMoveExemptEffects = default.AnchorMoveExemptEffects;
	Effect.DefensiveAnchorDR = default.DefensiveAnchorDR;

	Effect.BuildPersistentEffect (1, true, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect (Effect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;


	return Template;
}

static function X2AbilityTemplate DefensiveAnchor()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('DefensiveAnchor', "img:///XPerkIconPack.UIPerk_suppression_move");
	Template.bUniqueSource = true;

	HidePerkIcon(Template);
	return Template;
}

// Perk name:		Redeploy_I
// Perk effect:		This unit gets 3 Actions. This unit cannot shoot this turn. When this unit moves, it does not lose Anchored.
// Localized text:	This unit gets 3 Actions. This unit cannot shoot this turn. When this unit moves, it does not lose Anchored.
// Config:			(AbilityName="Redeploy_I")
static function X2AbilityTemplate Redeploy_I()
{


    local X2Effect_Redeploy     RedeployEffect;

    local X2AbilityTemplate				Template;
	local X2AbilityCooldownReduction				Cooldown;
	local X2Effect_GrantActionPoints    ActionPointEffect;
	local X2AbilityCost_ActionPoints    ActionPointCost;
    local array<name> CooldownReductionAbilities;
    local array<int> CooldownReductionAmount;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Redeploy_I');

	// Icon Properties
	Template.DisplayTargetHitChance = false;
	Template.AbilitySourceName = 'eAbilitySource_Perk';                                       // color of the icon
	Template.IconImage = "img:///XPerkIconPack.UIPerk_suppression_move2";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY;
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilityConfirmSound = "TacticalUI_Activate_Ability_Run_N_Gun";

    Template.AbilityTargetStyle = default.SelfTarget;	
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Cooldown = new class'X2AbilityCooldownReduction';
	Cooldown.BaseCooldown = default.RedployBaseCooldown;
        CooldownReductionAbilities.AddItem('Redeploy_II');
        CooldownReductionAmount.AddItem(default.RedployII_CooldownReduction);
    Cooldown.CooldownReductionAbilities = CooldownReductionAbilities;
    Cooldown.CooldownReductionAmount = CooldownReductionAmount;
	Template.AbilityCooldown = Cooldown;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = default.RedployAPCost;
	ActionPointCost.bFreeCost = false;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();


    RedeployEffect = new class'X2Effect_Redeploy';
    RedeployEffect.EffectName = 'Redeploy';
    RedeployEffect.NumActionPoints = 3;
    RedeployEffect.BuildPersistentEffect (1, false, false,,eGameRule_PlayerTurnEnd);
	RedeployEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect (RedeployEffect);

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

// Perk name:		Redeploy_II
// Perk effect:		Redeploy cooldown is reduced by 2 turns.
// Localized text:	Redeploy cooldown is reduced by 2 turns. Passive. Requires Redeploy_I
// Config:			(AbilityName="Redeploy_II")
static function X2AbilityTemplate Redeploy_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Redeploy_II', "img:///XPerkIconPack.UIPerk_suppression_move");
	Template.bUniqueSource = true;

	Template.PrerequisiteAbilities.AddItem('Redeploy_I');
	HidePerkIcon(Template);
	return Template;
}


// Perk name:		Fury
// Perk effect:		When missing or landing a partial hit with the Shoot ability, shoot the target again (if ammo available and target still alive). May trigger only once per turn
// Localized text:	When missing or landing a partial hit with the Shoot ability, shoot the target again (if ammo available and target still alive). May trigger only once per turn. Passive
// Config:			(AbilityName="Fury")
static function X2AbilityTemplate Fury()
{
	local X2Effect_Fury Effect;
	local X2AbilityTemplate Template;
    local array<name>       ExemptEffects;
    
    `CREATE_X2ABILITY_TEMPLATE(Template, 'Fury');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_shot_crit2";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bIsPassive = true;

	Effect = new class'X2Effect_Fury';
	Effect.BuildPersistentEffect (1, true, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect (Effect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

    Template.AdditionalAbilities.AddItem('FurySecondShot');

    return Template;

}

static function X2AbilityTemplate FurySecondShot()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventTrigger;
    local X2Condition_UnitValue 			FuryLimitPerTurnCondition;
	local X2AbilityCost_Ammo AmmoCost;


	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot('FurySecondShot', false);

	Template.AbilitySourceName = 'eAbilitySource_Commander';
	Template.IconImage = "img:///XPerkIconPack.UIPerk_shot_crit2";
    // Limit to once per turn
	FuryLimitPerTurnCondition = new class'X2Condition_UnitValue';
    FuryLimitPerTurnCondition.AddCheckValue('FuryShotsThisTurn', 1, eCheck_LessThan);
	Template.AbilityShooterConditions.AddItem(FuryLimitPerTurnCondition);

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityCosts.Length = 0;

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	Template.DefaultSourceItemSlot = eInvSlot_PrimaryWeapon;
	Template.bShowActivation = true;
	Template.CinescriptCameraType = ""; // disable fancy cameras, otherwise the player can't see what is happening

	// check for activation when a unit is targeted by an offensive ability
	Template.AbilityTriggers.Length = 0;
	EventTrigger = new class'X2AbilityTrigger_EventListener';
	EventTrigger.ListenerData.EventID = 'FuryActivationTrigger';
	EventTrigger.ListenerData.EventFn = class'X2Effect_Fury'.static.TriggerFurySecondShot;
	EventTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Template.AbilityTriggers.AddItem(EventTrigger);

	Template.bFrameEvenWhenUnitIsHidden = true;	
	return Template;
}

// Perk name:		RefreshingReload
// Perk effect:		Reloading reduces all ability and Skill cooldowns by 1. This effect may trigger only once per turn.
// Localized text:	Reloading reduces all ability and Skill cooldowns by 1. This effect may trigger only once per turn.. Passive
// Config:			(AbilityName="RefreshingReload")
static function X2AbilityTemplate RefreshingReload()
{
	local X2Effect_RefreshingReload Effect;
    local X2Effect_ManualOverride   ManualOverrideEffect;
	local X2AbilityTemplate Template;
    local X2Condition_UnitValue LimitPerTurnCondition;
    local X2AbilityTrigger_EventListener EventTrigger;
    
    `CREATE_X2ABILITY_TEMPLATE(Template, 'RefreshingReload');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_ammo_cycle";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.bIsPassive = true;

    // Limit to once per turn
	LimitPerTurnCondition = new class'X2Condition_UnitValue';
    LimitPerTurnCondition.AddCheckValue('ReloadsThisTurn', 1, eCheck_LessThan);
	//Template.AbilityTargetConditions.AddItem(LimitPerTurnCondition);

	Effect = new class'X2Effect_RefreshingReload';
	Effect.BuildPersistentEffect (1, true, true);
	Effect.SetDisplayInfo(ePerkBuff_Passive, "Refreshing Reload", "All ability and skill cooldowns reduced by 1 turn", Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect (Effect);

	EventTrigger = new class'X2AbilityTrigger_EventListener';
	EventTrigger.ListenerData.EventID = 'AbilityActivated';
	EventTrigger.ListenerData.EventFn = class'X2Effect_RefreshingReload'.static.RefreshingReloadTrigger;
	EventTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Template.AbilityTriggers.AddItem(EventTrigger);




	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

    return Template;

}

// Perk name:		Preparation
// Perk effect:		This unit gets a 35% chance to gain a stack of Anchored at the beginning of your turn.
// Localized text:	This unit gets a 35% chance to gain a stack of Anchored at the beginning of your turn. Passive
// Config:			(AbilityName="Preparation")
static function X2AbilityTemplate Preparation()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Preparation', "img:///XPerkIconPack.UIPerk_suppression_box");
	Template.bUniqueSource = true;
	return Template;
}

// Perk name:		Streak
// Perk effect:		On kill, gain 1 stack of the Streak status effect. When reaching 5 stacks of Streak, this unit gains 1 Action and loses all stacks.
// Localized text:	On kill, gain 1 stack of the Streak status effect. When reaching 5 stacks of Streak, this unit gains 1 Action and loses all stacks.. Passive
// Config:			(AbilityName="Streak")
static function X2AbilityTemplate Streak()
{
	local X2Effect_Streak Effect;
	local X2AbilityTemplate Template;
    local array<name>       ExemptEffects;
    
    `CREATE_X2ABILITY_TEMPLATE(Template, 'Streak');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_command_suppression";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bIsPassive = true;

	Effect = new class'X2Effect_Streak';
	Effect.BuildPersistentEffect (1, true, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect (Effect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;


    return Template;

}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Perk name:		RecklessShot_I
// Perk effect:		Special shot that has +30/+40/+50 crit chance and has a 4 turn cooldown.
// Localized text:	Special shot that has +30 crit chance and has a 4 turn cooldown.
// Config:			(AbilityName="RecklessShot_I")
static function X2AbilityTemplate RecklessShot_I()
{
	local X2AbilityTemplate Template;
	local X2AbilityCooldownReduction	Cooldown;
	local array<name> CooldownReductionAbilities;
	local array<int> CooldownReductionAmount;
    

	// Create the template using a helper function
	Template = Attack('RecklessShot_I', "img:///XPerkIconPack.UIPerk_suppression_chevron", true, none, class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY, eCost_WeaponConsumeAll, 1);

	
	// Add a cooldown. The internal cooldown numbers include the turn the cooldown is applied, so
	// this is actually a 4 turn cooldown.
	Cooldown = new class'X2AbilityCooldownReduction';
	Cooldown.BaseCooldown = default.RecklessShotCooldown;
	Template.AbilityCooldown = Cooldown;

    Template.AdditionalAbilities.AddItem('RecklessShotBonus');

	return Template;
}

// This is part of the High Power Shot effect, above
static function X2AbilityTemplate RecklessShotBonus()
{
	local X2AbilityTemplate Template;
	local XMBCondition_AbilityName Condition;
    local X2Effect_RecklessShotBonus    CritEffect;

    `CREATE_X2ABILITY_TEMPLATE (Template, 'RecklessShotBonus');
    Template.IconImage = "img:///XPerkIconPack.UIPerk_suppression_chevron";
    Template.AbilitySourceName = 'eAbilitySource_Perk';
    Template.eAbilityIconBehaviorHUD = 2;
    Template.Hostility = 2;
    Template.AbilityToHitCalc = default.DeadEye;
    Template.AbilityTargetStyle = default.SelfTarget;
    Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
    CritEffect = new class'X2Effect_RecklessShotBonus';
    CritEffect.BuildPersistentEffect(1, true, false, false);
    CritEffect.SetDisplayInfo(0, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false,, Template.AbilitySourceName);
    Template.AddTargetEffect(CritEffect);
    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;


	return Template;
}

// Perk name:		RecklessShot_II
// Perk effect:		Special shot that has +40 crit chance and has a 4 turn cooldown.
// Localized text:	Special shot that has +40 crit chance and has a 4 turn cooldown. Requires RecklessShot_I
// Config:			(AbilityName="RecklessShot_I")
static function X2AbilityTemplate RecklessShot_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('RecklessShot_II', "img:///XPerkIconPack.UIPerk_suppression_chevron_x2");
	Template.bUniqueSource = true;

    Template.PrerequisiteAbilities.AddItem('RecklessShot_I');
	return Template;
}

// Perk name:		RecklessShot_II
// Perk effect:		Special shot that has +50 crit chance and has a 4 turn cooldown.
// Localized text:	Special shot that has +50 crit chance and has a 4 turn cooldown. Requires RecklessShot_II
// Config:			(AbilityName="RecklessShot_I")
static function X2AbilityTemplate RecklessShot_III()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('RecklessShot_III', "img:///XPerkIconPack.UIPerk_suppression_chevron_x3");
	Template.bUniqueSource = true;

    Template.PrerequisiteAbilities.AddItem('RecklessShot_II');
	return Template;
}


// Perk name:		Heat Up I
// Perk effect:		Gain +25% Damage this turn. This effect stacks every time this unit shoots this turn. Free Action.
// Localized text:	Gain +25% Damage this turn. This effect stacks every time this unit shoots this turn. Free Action.
// Config:			(AbilityName="HeatUp_I")
static function X2AbilityTemplate HeatUp_I()
{
    local X2AbilityTemplate			Template;
    local X2Effect_HeatUp           HeatedUpEffect;
    local X2AbilityCooldownReduction    Cooldown;


    Template = SelfTargetActivated('HeatUp_I', "img:///XPerkIconPack.UIPerk_crit_chevron", false, none, , eCost_Free);

    HeatedUpEffect = new class'X2Effect_HeatUp';
    HeatedUpEffect.EffectName = 'HeatedUp';
	HeatedUpEffect.BuildPersistentEffect (1, false, true, , eGameRule_PlayerTurnEnd);
	HeatedUpEffect.SetDisplayInfo(ePerkBuff_Bonus, "Heated Up", "This unit has increased damage this turn", Template.IconImage, true,,Template.AbilitySourceName);
	HeatedUpEffect.VisualizationFn = HeatUpFlyOver_Visualization;
	Template.AddTargetEffect (HeatedUpEffect);

	Cooldown = new class'X2AbilityCooldownReduction';
	Cooldown.BaseCooldown = default.HeatUpCooldown;
	Template.AbilityCooldown = Cooldown;

	Template.BuildVisualizationFn = class'X2Ability_DefaultAbilitySet'.static.ReloadAbility_BuildVisualization;

    return Template;
}

// Perk name:		Heat Up II
// Perk effect:		Unit auto reloads when activating heated up.
// Localized text:	Unit auto reloads when activating heated up.
// Config:			(AbilityName="HeatUp_II")
static function X2AbilityTemplate HeatUp_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('HeatUp_II', "img:///XPerkIconPack.UIPerk_crit_chevron_x2");
	Template.bUniqueSource = true;

    Template.PrerequisiteAbilities.AddItem('HeatUp_I');

    return Template;
}


simulated static function HeatUpFlyOver_Visualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyOver;
	local X2AbilityTemplate             AbilityTemplate;
	local X2AbilityTemplateManager				AbilityTemplateMgr;
	local XComGameStateContext_Ability  Context;
	local AbilityInputContext           AbilityContext;
	local EWidgetColor					MessageColor;
	local XComGameState_Unit			SourceUnit;
	local bool							bGoodAbility;
	local XComGameState_Effect				EffectState;
	local XComGameState_Unit				UnitState;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityContext = Context.InputContext;

	AbilityTemplateMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateMgr.FindAbilityTemplate('HeatUp_I');
	
	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.SourceObject.ObjectID));

	bGoodAbility = SourceUnit.IsFriendlyToLocalPlayer();
	MessageColor = bGoodAbility ? eColor_Good : eColor_Bad;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', EffectState)
	{

		//TargetTrack = EmptyTrack;
		UnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		if ((UnitState != none) && (EffectState.StatChanges.Length > 0) && EffectApplyResult == 'AA_Success' && XGUnit(ActionMetadata.VisualizeActor).IsAlive())
		{
			ActionMetadata.StateObject_NewState = UnitState;
			ActionMetadata.StateObject_OldState = `XCOMHISTORY.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1); 
			ActionMetadata.VisualizeActor = UnitState.GetVisualizer();
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, context, false, ActionMetadata.LastActionAdded));
			if (UnitState.HasSoldierAbility('HeatUp_II'))
			{
				SoundAndFlyOver.SetSoundAndFlyOverParameters(none, "Heat Up", 'None', MessageColor,AbilityTemplate.IconImage);
			}
			else
			{
				SoundAndFlyOver.SetSoundAndFlyOverParameters(none, "Heat Up II", 'None', MessageColor,AbilityTemplate.IconImage);
			}
			
		}
		
	}
}




// Perk name:		Embers
// Perk effect:		20% Chance to become Heated Up at the beginning of your turn while the Heat Up Skill is on cooldown.
// Localized text:	20% Chance to become Heated Up at the beginning of your turn while the Heat Up Skill is on cooldown.
// Config:			(AbilityName="Embers")
static function X2AbilityTemplate Embers()
{
    local X2AbilityTemplate			Template;
    local X2Effect_Embers           Effect;

    `CREATE_X2ABILITY_TEMPLATE(Template, 'Embers');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_crit_chevron_x3";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bIsPassive = true;

	Effect = new class'X2Effect_Embers';
	Effect.BuildPersistentEffect (1, true, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect (Effect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

    Template.PrerequisiteAbilities.AddItem('HeatUp_I');
    Template.AdditionalAbilities.AddItem('HeatUp_Free');

    return Template;
}

// This is a triggered version of heat up which is needed for embers to proc
static function X2AbilityTemplate HeatUp_FreeVersion()
{
    local X2AbilityTemplate			Template;
    local X2Effect_HeatUp           HeatedUpEffect;
    local X2AbilityTrigger_EventListener    EventTrigger;



    Template = SelfTargetTrigger('HeatUp_Free', "img:///XPerkIconPack.UIPerk_crit_chevron", false, none, 'HeatUpFreeTrigger');

    HeatedUpEffect = new class'X2Effect_HeatUp';
    HeatedUpEffect.EffectName = 'HeatedUpFree';
	HeatedUpEffect.BuildPersistentEffect (1, false, true, , eGameRule_PlayerTurnEnd);
	HeatedUpEffect.SetDisplayInfo(ePerkBuff_Bonus, "Heated Up: Embers", "This unit has increased damage this turn", Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect (HeatedUpEffect);

	Template.bShowActivation = true;


    return Template;
}


// Perk name:		Suppressive Fire
// Perk effect:		Suppression grants AoE suppression around the primary target in a 4 tile radius.
// Localized text:	Suppression grants AoE suppression around the primary target in a 4 tile radius.
// Config:			(AbilityName="SuppressiveFire")
static function X2AbilityTemplate SuppressiveFire()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('SuppressiveFire', "img:///XPerkIconPack.UIPerk_suppression_circle");
	Template.bUniqueSource = true;


    return Template;
}







static function X2AbilityTemplate ExplosiveShot_I()
{
	local X2AbilityTemplate						Template;
	local X2Effect_ApplyWeaponDamage		WeaponDamageEffect;
    local X2Effect_ExplosiveAoEDamage       Effect;
	local X2AbilityCooldown					Cooldown;
	local X2AbilityMultiTarget_Radius			TargetStyle;
	local X2Effect_Knockback				KnockbackEffect;
    local X2Condition_PrimaryTargetDead     DeadCondition;

	Template = Attack('ExplosiveShot_I', "img:///XPerkIconPack.UIPerk_shot_grenade",false);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.ExplosiveShotCooldown;
	Template.AbilityCooldown = Cooldown;

    TargetStyle = new class'X2AbilityMultiTarget_Radius';
	TargetStyle.fTargetRadius = default.ExplosiveShotRadius;//4
	TargetStyle.bIgnoreBlockingCover = true;
	Template.AbilityMultiTargetStyle = TargetStyle;
	
    Template.TargetingMethod = class'X2TargetingMethod_TopDown';


    //DeadCondition = new class'X2Condition_PrimaryTargetDead';

    //Effect.TargetConditions.AddItem(DeadCondition);
    // We need to add a condition here to check if the primary target of the ability is dead or not
    //Template.AbilityMultiTargetConditions.AddItem(default.DeadCondition);    
    //Template.AddTargetEffect(Effect);

	return Template;
}

static function X2AbilityTemplate ExplodeOnDeath()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2AbilityMultiTarget_Radius MultiTarget;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Effect_ApplyWeaponDamage DamageEffect;
	local X2Effect_KillUnit KillUnitEffect;



	`CREATE_X2ABILITY_TEMPLATE(Template, 'ExplodeOnDeath');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_purifierdeathexplosion";

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Offensive;

	// This ability is only valid if there has not been another death explosion on the unit
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeDeadFromSpecialDeath = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'UnitDied';
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = AbilityTriggerEventListener_ExplodeOnDeath;
	Template.AbilityTriggers.AddItem(EventListener);

	// Targets the unit so the blast center is its dead body
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityToHitCalc = default.DeadEye;


	// Target everything in this blast radius
	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.fTargetRadius = default.ExplosiveShotRadius;//4
	Template.AbilityMultiTargetStyle = MultiTarget;

	Template.AddTargetEffect(new class'X2Effect_SetSpecialDeath');

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.FailOnNonUnits = false; //The grenade can affect interactive objects, others
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	// Everything in the blast radius receives physical damage
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.EffectDamageValue = class'X2Item_XpackWeapons'.default.ADVPURIFIER_DEATH_EXPLOSION_BASEDAMAGE;
	DamageEffect.EnvironmentalDamageAmount = 10;
	Template.AddMultiTargetEffect(DamageEffect);

	// If the unit is alive, kill it
	KillUnitEffect = new class'X2Effect_KillUnit';
	KillUnitEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	KillUnitEffect.EffectName = 'KillUnit';
	KillUnitEffect.DeathActionClass = class'X2Action_ExplodingUnitDeathAction';
	Template.AddTargetEffect(KillUnitEffect);   
    
    Template.bShowActivation = true;
	Template.bSkipFireAction = true;
    //Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = class'X2Ability_Death'.static.DeathExplosion_BuildVisualization;
	Template.MergeVisualizationFn = class'X2Ability_Death'.static.DeathExplostion_MergeVisualization;
	//Template.VisualizationTrackInsertedFn = class'X2Ability_Death'.static.DeathExplosion_VisualizationTrackInsert;

	Template.FrameAbilityCameraType = eCameraFraming_Never;

	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.GrenadeLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;


	return Template;
}


static function EventListenerReturn AbilityTriggerEventListener_ExplodeOnDeath(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit			DeadUnit;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Ability			AbilityState;


	if (GameState.GetContext().InterruptionStatus != eInterruptionStatus_Interrupt)
	{
		DeadUnit = XComGameState_Unit(EventData);
		if (DeadUnit != none)
		{
			AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
			if ((AbilityContext != none) && (AbilityContext.InputContext.AbilityTemplateName == 'ExplosiveShot_I'))
			{
                AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
                class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName( DeadUnit.GetReference(), 'ExplodeOnDeath', DeadUnit.GetReference() );
				//return AbilityState.AbilityTriggerEventListener_Self(EventData, EventSource, GameState, EventID, CallbackData);
			}
		}
	}
	return ELR_NoInterrupt;
}



// Perk name:		DigIn_I
// Perk effect:		Allies within 8 meters gain +15% Accuracy this turn.
// Localized text:	Allies within 8 meters gain +15% Accuracy this turn.
// Config:			(AbilityName="DigIn_I")
static function X2AbilityTemplate DigIn_I()
{
	local X2Effect_PersistentStatChange Effect, WeakPointEffect;
	local X2AbilityTemplate Template;
	local X2AbilityMultiTarget_Radius MultiTarget;
    local X2Condition_AbilityProperty                   OwnerHasAbilityCondition;

    Template = SelfTargetActivated('DigIn_I', "img:///XPerkIconPack.UIPerk_enemy_defense_chevron", true, none,,eCost_Single);

    Template.bSkipFireAction = false;
    Template.bSkipExitCoverWhenFiring = true;
    Template.CustomFireAnim = 'HL_Revive';
    Template.ActivationSpeech = 'CombatPresence';
    Template.CinescriptCameraType = "Skirmisher_CombatPresence";
	
    AddCooldown(Template, default.DigInCooldown);
	// Create a persistent stat change effect to grant aim
	Effect = new class'X2Effect_PersistentStatChange';
	Effect.EffectName = 'DigInEffect';
	Effect.AddPersistentStatChange(eStat_Offense, default.DigInAimBonusI);
	Effect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	Effect.SetDisplayInfo(ePerkBuff_Bonus,  Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, true, , Template.AbilitySourceName);
	// If the effect is added multiple times, it refreshes the duration of the existing effect, i.e. no stacking
	Effect.DuplicateResponse = eDupe_Ignore;
	// The effect only applies to living, friendly targets
	Effect.TargetConditions.AddItem(default.LivingFriendlyTargetProperty);
	// Show a flyover over the target unit when the effect is added
	Effect.VisualizationFn = EffectFlyOver_Visualization;
	// The multitargets are also affected by the persistent effect we created
	Template.AddMultiTargetEffect(Effect);

    // The ability targets the unit that has it, but also effects all friendly units that meet
	// the conditions on the multitarget effect.
	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.fTargetRadius = `UNITSTOMETERS(`TILESTOUNITS(default.DigInRadius));//8
	MultiTarget.bUseWeaponRadius = false;
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.bAddPrimaryTargetAsMultiTarget = false;
	MultiTarget.bAllowDeadMultiTargetUnits = false;
	MultiTarget.bAllowSameTarget = false;
	MultiTarget.bExcludeSelfAsTargetIfWithinRadius = TRUE;
	Template.AbilityMultiTargetStyle = MultiTarget;

    return Template;

}

// Perk name:		DigIn_II
// Perk effect:		Allies within 8 meters gain +25% Accuracy this turn.
// Localized text:	Allies within 8 meters gain +25% Accuracy this turn.
// Config:			(AbilityName="DigIn_II")
static function X2AbilityTemplate DigIn_II()
{
	local X2Effect_PersistentStatChange Effect, WeakPointEffect;
	local X2AbilityTemplate Template;
	local X2AbilityMultiTarget_Radius MultiTarget;
    local X2Condition_AbilityProperty                   OwnerHasAbilityCondition;

    Template = SelfTargetActivated('DigIn_II', "img:///XPerkIconPack.UIPerk_enemy_defense_chevron_x2", true, none,,eCost_Single);

    Template.bSkipFireAction = false;
    Template.bSkipExitCoverWhenFiring = true;
    Template.CustomFireAnim = 'HL_Revive';
    Template.ActivationSpeech = 'CombatPresence';
    Template.CinescriptCameraType = "Skirmisher_CombatPresence";
	
    AddCooldown(Template, default.DigInCooldown);
	// Create a persistent stat change effect to grant aim
	Effect = new class'X2Effect_PersistentStatChange';
	Effect.EffectName = 'DigInEffect';
	Effect.AddPersistentStatChange(eStat_Offense, default.DigInAimBonusII);
	Effect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	Effect.SetDisplayInfo(ePerkBuff_Bonus,  Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, true, , Template.AbilitySourceName);
	// If the effect is added multiple times, it refreshes the duration of the existing effect, i.e. no stacking
	Effect.DuplicateResponse = eDupe_Ignore;
	// The effect only applies to living, friendly targets
	Effect.TargetConditions.AddItem(default.LivingFriendlyTargetProperty);
	// Show a flyover over the target unit when the effect is added
	Effect.VisualizationFn = EffectFlyOver_Visualization;
	// The multitargets are also affected by the persistent effect we created
	Template.AddMultiTargetEffect(Effect);

    // The ability targets the unit that has it, but also effects all friendly units that meet
	// the conditions on the multitarget effect.
	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.fTargetRadius = `UNITSTOMETERS(`TILESTOUNITS(default.DigInRadius));
	MultiTarget.bUseWeaponRadius = false;
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.bAddPrimaryTargetAsMultiTarget = false;
	MultiTarget.bAllowDeadMultiTargetUnits = false;
	MultiTarget.bAllowSameTarget = false;
	MultiTarget.bExcludeSelfAsTargetIfWithinRadius = TRUE;
	Template.AbilityMultiTargetStyle = MultiTarget;

    Template.OverrideAbilities.AddItem('DigIn_I');

    return Template;

}

// Perk name:		Full Kit
// Perk effect:		Grants additional charges per grenade item in a utility slot (vanilla items only)
// Localized text:	"Grants +1 charge per grenade item in a utility slot (vanilla items only)"
// Config:			(AbilityName="XGT_FullKit")
static function X2AbilityTemplate XGT_FullKit()
{
	local XMBEffect_AddItemCharges BonusItemEffect;
	local X2AbilityTemplate Template;

	// The number of charges and the items that are affected are gotten from the config
	BonusItemEffect = new class'XMBEffect_AddItemCharges';
	BonusItemEffect.PerItemBonus = default.FULL_KIT_BONUS;
	BonusItemEffect.ApplyToNames = default.FULL_KIT_ITEMS;
	BonusItemEffect.ApplyToSlots.AddItem(eInvSlot_Utility);

	// Create the template using a helper function
	Template =  Passive('XGT_FullKit', "img:///XPerkIconPack.UIPerk_grenade_plus", false, BonusItemEffect);

	Template.AdditionalAbilities.AddItem('EGT_CombatEngineer'); // For compatibility with explsoves tweak mod

	return Template;
}




// Perk name:		AtTheReady
// Perk effect:		When this unit enters Overwatch, reduce the cooldown of all its Skills by 1.
// Localized text:	When this unit enters Overwatch, reduce the cooldown of all its Skills by 1.
// Config:			(AbilityName="AtTheReady")
static function X2AbilityTemplate AtTheReady()
{
	local X2Effect_AtTheReady Effect;
	local X2AbilityTemplate Template;
    local array<name>       ExemptEffects;




	`CREATE_X2ABILITY_TEMPLATE(Template, 'AtTheReady');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_overwatch_cycle";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bIsPassive = true;

	Effect = new class'X2Effect_AtTheReady';
	Effect.BuildPersistentEffect (1, true, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect (Effect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

    return Template;
}

// Perk name:		CounterPush
// Perk effect:		When this unit kills an enemy with an Overwatch Shot, it gets +3 mobility on its next turn. This effect does not stack
// Localized text:	When this unit kills an enemy with an Overwatch Shot, it gets +3 mobility on its next turn. This effect does not stack
// Config:			(AbilityName="CounterPush")
static function X2AbilityTemplate CounterPush()
{
	local X2AbilityTemplate						Template;
	local X2Effect_PersistentStatChange			StatChangeEffect;
	local X2AbilityTrigger_EventListener		EventListenerTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CounterPush');
//BEGIN AUTOGENERATED CODE: Template Overrides 'FullThrottle'
	Template.IconImage = "img:///XPerkIconPack.UIPerk_overwatch_move";
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
	EventListenerTrigger.ListenerData.EventFn = CounterPushListener;
	//EventListenerTrigger.ListenerData.EventFn = class'XComGameState_Ability'.static.FullThrottleListener;
	Template.AbilityTriggers.AddItem(EventListenerTrigger);

	StatChangeEffect = new class'X2Effect_PersistentStatChange';
	StatChangeEffect.AddPersistentStatChange(eStat_Mobility, default.CounterPushMobilityBonus);	
	StatChangeEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	StatChangeEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
    StatChangeEffect.DuplicateResponse = eDupe_Ignore;
	StatChangeEffect.EffectName = 'FullThrottleStats';
	StatChangeEffect.VisualizationFn = EffectFlyOver_Visualization;
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

static function EventListenerReturn CounterPushListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
    local XComGameState_Ability AbilityState;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	AbilityState = XComGameState_Ability(CallbackData);

	if (AbilityContext != None && AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
	{
        //AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
		//	were we the killer?
		if ((AbilityContext.InputContext.AbilityTemplateName == 'Overwatch' ||
            AbilityContext.InputContext.AbilityTemplateName == 'OverwatchShot'))
		{
			`log("CounterPush triggered: Ability proccing this is " $ AbilityContext.InputContext.AbilityTemplateName);
            return AbilityState.AbilityTriggerEventListener_Self(EventData, EventSource, GameState, EventID, CallbackData);
		}
	}

	return ELR_NoInterrupt;
}

// Perk name:		Slayer
// Perk effect:		This unit's Overwatch shots deal +50% Damage
// Localized text:	This unit's Overwatch shots deal +50% Damage
// Config:			(AbilityName="Slayer")
static function X2AbilityTemplate Slayer()
{
	local XMBEffect_ConditionalBonus			ReactionFire;
	
	// Create a conditional bonus
	ReactionFire = new class'XMBEffect_ConditionalBonus';
	ReactionFire.AddPercentDamageModifier(default.SlayerDamageBonus, eHit_Success);
	ReactionFire.AbilityTargetConditions.AddItem(default.ReactionFireCondition);
	ReactionFire.bDisplayInUI = false;
	
	return Passive('Slayer', "img:///XPerkIconPack.UIPerk_overwatch_blossom", true, ReactionFire);
}





static function X2Effect_Persistent SuppressiveFireEffect()
{
    local X2Effect_Suppression      SuppressionEffect;
    local X2Condition_SourceHasAbility   Condition;

    SuppressionEffect = new class'X2Effect_Suppression';
    SuppressionEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	SuppressionEffect.bRemoveWhenTargetDies = true;
	SuppressionEffect.bRemoveWhenSourceDamaged = true;
	SuppressionEffect.bBringRemoveVisualizationForward = true;
	SuppressionEffect.SetDisplayInfo(ePerkBuff_Penalty, "Suppressed", "The unit is Suppressed", "img:///UILibrary_PerkIcons.UIPerk_supression");
	

        // Only apply if shooter has the required effect
	Condition = new class'X2Condition_SourceHasAbility';
	Condition.Abilities.AddItem('SuppressiveFire');
	SuppressionEffect.TargetConditions.AddItem(Condition);

    return SuppressionEffect;
}