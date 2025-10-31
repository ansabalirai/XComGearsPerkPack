class X2Ability_GearsSniperAbilitySet extends XMBAbility config(GearsSniperAbilitySet);


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/* 
Gears Sniper:
Sniper/pistol

Squaddie skills:
    Squadsight

Marksman:
    First blood I, II, III (Special shot that does 1.5/1.75/2x damage boost vs enemies at full health)
    Spree (25% chance to get 2 actions back after a kill/crit kill, once per turn)
    Alpha (Increased damage on the first shot of magazine)
    Extra round (crits grant +1 ammo)

Assassin:
    Precision Shot I, II, III (Special shot with aim and damage boost, 30/40/50%)
    Omega (Increased damage on last shot of magazine)
    Head Hunter (kills grant increased damage to a cap)
    Weak Spot (+10% crit chance against wounded enemies)
    Lucky Streak (When this unit hits an enemy with a Critical Hit, this unit gains +20% Critical Hit Chance for this turn.)?

Stalker:
    Concussion Shot I, II, III (Disabling shot from LWOTC, buffed to have increased crit chance against them and cooldown reduction)
    Terrified (Passive chance to panic/disorient enemies on kill/crit aka Apex Predator)
    Sure Thing (Passive: Any shot that's not a crit increases crit chance, until you crit)
    Active Reload (When this unit uses Reload on an empty magazine, this unit deals +25% Damage for 2 turns or until reloading)?

Hunter:
    Magnum + QuickDraw
    Fast Fingers I, II (Passive: Kill reload primary weapon and then grants action)
    Chain Shot I, II (1/2 actions if the shot hits)
    Run and Gun (50% damage for this turn after moving. Increased high ground bonus)
    Setup (When your turn ends and this unit has not taken a Shot, reduce the cooldown of all this unit's abilities and Skills by 1 turn) */
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var config int SPREE_USES_PER_TURN;
var config int SPREE_PROC_CHANCE;

var config int ALPHA_BONUS_DAMAGE;
var config int OMEGA_BONUS_DAMAGE;

var config int MaxHeadHunterDamage;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

    //Squadsight - Base Game
    // PistolStandardShot

    // Marksman
    Templates.AddItem(FirstBlood_I());
        Templates.AddItem(FirstBloodShotBonus());
        Templates.AddItem(FirstBlood_II());
        Templates.AddItem(FirstBlood_III());
    Templates.AddItem(Spree());
    Templates.AddItem(Alpha());
    Templates.AddItem(ExtraRound());
    //Templates.AddItem(LuckyStreak());

    // Assassin
    Templates.AddItem(XGT_PrecisionShot_I());
        Templates.AddItem(XGT_PrecisionShot_II());
        Templates.AddItem(XGT_PrecisionShot_III());
        Templates.AddItem(XGT_PrecisionShotBonus());
    Templates.AddItem(Omega());
    Templates.AddItem(HeadHunter());
    Templates.AddItem(WeakSpot());

    // Stalker
    Templates.AddItem(ConcussionShot_I());
        Templates.AddItem(ConcussionShot_II());
        Templates.AddItem(ConcussionShot_III());
        Templates.AddItem(XGT_ConcussionShotBonus());
    Templates.AddItem(Terrified());
        Templates.AddItem(TerrifiedApply());
    Templates.AddItem(SureThing());
    Templates.AddItem(ActiveReload());
        Templates.AddItem(ActiveReload_Triggered());


    // Hunter
    Templates.AddItem(Pistoleer());
    Templates.AddItem(FastFingers_I());
        Templates.AddItem(FastFingers_II());
    Templates.AddItem(ChainedShot_I());
        Templates.AddItem(ChainedShot_Passive());
        Templates.AddItem(ChainedShot_II());
    Templates.AddItem(XGT_RunAndGun());
    //Templates.AddItem(Setup());

	return Templates;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Perk name:		FirstBlood_I
// Perk effect:		Special shot that does 1.5/1.75/2x damage boost vs enemies at full health. 5 turns cooldown
// Localized text:	Special shot that does 1.5/1.75/2x damage boost vs enemies at full health.
// Config:			(AbilityName="FirstBlood_I")
static function X2AbilityTemplate FirstBlood_I()
{
	local X2AbilityTemplate Template;
	local X2AbilityCooldownReduction	Cooldown;
	local array<name> CooldownReductionAbilities;
	local array<int> CooldownReductionAmount;
    local X2Condition_UnitStatCheck FullHealthCondition;
    

	// Create the template using a helper function
	Template = Attack('FirstBlood_I', "img:///XPerkIconPack.UIPerk_sniper_bullet", true, none, class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY, eCost_WeaponConsumeAll, 1);

	FullHealthCondition = new class'X2Condition_UnitStatCheck';
	FullHealthCondition.AddCheckStat(eStat_HP, 100, eCheck_Exact, 100, 100, true);
    Template.AbilityTargetConditions.AddItem(FullHealthCondition);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);

	Cooldown = new class'X2AbilityCooldownReduction';
	Cooldown.BaseCooldown = 4;
	Template.AbilityCooldown = Cooldown;

    Template.ActivationSpeech = 'DeadEye';
    Template.AdditionalAbilities.AddItem('FirstBloodShotBonus');

	return Template;
}

// Perk name:		FirstBlood_II
// Perk effect:		First Blood damage bonus is increased to 1.75x.
// Localized text:	First Blood damage bonus is increased to 1.75x. Requires First Blood
// Config:			(AbilityName="FirstBlood_II")
static function X2AbilityTemplate FirstBlood_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('FirstBlood_II', "img:///XPerkIconPack.UIPerk_sniper_bullet_x2");
	Template.bUniqueSource = true;

    Template.PrerequisiteAbilities.AddItem('FirstBlood_I');
	return Template;
}

// Perk name:		FirstBlood_III
// Perk effect:		First Blood damage bonus is increased to 2x.
// Localized text:	First Blood damage bonus is increased to 2x. Requires First Blood and First Blood II
// Config:			(AbilityName="FirstBlood_III")
static function X2AbilityTemplate FirstBlood_III()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('FirstBlood_III', "img:///XPerkIconPack.UIPerk_sniper_bullet_x3");
	Template.bUniqueSource = true;

    Template.PrerequisiteAbilities.AddItem('FirstBlood_I');
    Template.PrerequisiteAbilities.AddItem('FirstBlood_II');
	return Template;
}



// This is part of the High Power Shot effect, above
static function X2AbilityTemplate FirstBloodShotBonus()
{
	local X2AbilityTemplate Template;
    local X2Effect_FirstBloodBonus    Effect;

    `CREATE_X2ABILITY_TEMPLATE (Template, 'FirstBloodShotBonus');
    Template.IconImage = "img:///XPerkIconPack.UIPerk_sniper_bullet";
    Template.AbilitySourceName = 'eAbilitySource_Perk';
    Template.eAbilityIconBehaviorHUD = 2;
    Template.Hostility = 2;
    Template.AbilityToHitCalc = default.DeadEye;
    Template.AbilityTargetStyle = default.SelfTarget;
    Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

    Effect = new class'X2Effect_FirstBloodBonus';
    Effect.BuildPersistentEffect(1, true, false, false);
    Effect.SetDisplayInfo(0, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false,, Template.AbilitySourceName);
    Template.AddTargetEffect(Effect);
    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;


	return Template;
}

// Perk name:		Spree
// Perk effect:		When this unit kills an enemy with a Critical Hit, there is a 25% chance that this unit will get 2 Actions. This effect may only trigger once per turn.
// Localized text:	When this unit kills an enemy with a Critical Hit, there is a 25% chance that this unit will get 2 Actions. This effect may only trigger once per turn.
// Config:			(AbilityName="Spree")
static function X2AbilityTemplate Spree()
{
	local X2AbilityTemplate						Template;
	local X2Effect_Spree 					SpreeEffect;




    SpreeEffect = new class'X2Effect_Spree';
	SpreeEffect.USES_PER_TURN = default.SPREE_USES_PER_TURN;
	SpreeEffect.ProcChance = default.SPREE_PROC_CHANCE;

	Template = Passive('Spree', "img:///XPerkIconPack.UIPerk_command_sniper",,SpreeEffect);

	return Template;

}

// Perk name:		Alpha
// Perk effect:		When this unit takes the first Shot with a full magazine, it gets a +15% Damage bonus.
// Localized text:	WWhen this unit takes the first Shot with a full magazine, it gets a +15% Damage bonus.
// Config:			(AbilityName="Alpha")
static function X2AbilityTemplate Alpha()
{
	local X2AbilityTemplate						Template;
	local X2Effect_AlphaOmega 					AlphaEffect;




    AlphaEffect = new class'X2Effect_AlphaOmega';
    AlphaEffect.EffectName = 'AlphaEffect';
	AlphaEffect.ApplyTo = 'FirstShot';
    AlphaEffect.BonusDamagePercent = default.ALPHA_BONUS_DAMAGE;


	Template = Passive('Alpha', "img:///XPerkIconPack.UIPerk_sniper_crit",,AlphaEffect);

	return Template;

}

static function X2AbilityTemplate ExtraRound()
{
	local X2AbilityTemplate                 Template;	
	local X2Condition_UnitProperty          ShooterPropertyCondition;
	local X2Condition_AbilitySourceWeapon   WeaponCondition;
	local X2AbilityTrigger_EventListener	EventListener;
	local array<name>                       SkipExclusions;
	local X2Condition_UnitInventory			InventoryCondition;
	local X2Effect_ReloadPrimaryWeapon Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ExtraRound');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_ammo_plus";
	Template.bDontDisplayInAbilitySummary = false;
	
	ShooterPropertyCondition = new class'X2Condition_UnitProperty';	
	ShooterPropertyCondition.ExcludeDead = true;                    //Can't reload while dead
	Template.AbilityShooterConditions.AddItem(ShooterPropertyCondition);

	
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'KillMail';
	EventListener.ListenerData.EventFn = AbilityTriggerEventListener_CritKill;
	EventListener.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(EventListener);
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.RELOAD_PRIORITY;
	Template.bNoConfirmationWithHotKey = true;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.DisplayTargetHitChance = false;

	Effect = new class'X2Effect_ReloadPrimaryWeapon';
	Effect.AmmoToReload = 1;
    Template.AddTargetEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = ExtraRound_BuildVisualization;

	Template.Hostility = eHostility_Neutral;

	Template.CinescriptCameraType="GenericAccentCam";


	return Template;
}

static function EventListenerReturn AbilityTriggerEventListener_CritKill(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit			DeadUnit, KillerUnit;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Ability			AbilityState;


	if (GameState.GetContext().InterruptionStatus != eInterruptionStatus_Interrupt)
	{
		DeadUnit = XComGameState_Unit(EventData);
        KillerUnit = XComGameState_Unit(EventSource);
		if (DeadUnit != none && KillerUnit != none)
		{
			AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
			if ((AbilityContext != none))
			{
                AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
                

                // Check if it was a crit kill?
                if (AbilityContext.ResultContext.HitResult == eHit_Crit)
                {
                    class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName( KillerUnit.GetReference(), 'ExtraRound', KillerUnit.GetReference() );
                }
			}
		}
	}
	return ELR_NoInterrupt;
}



function ExtraRound_BuildVisualization(XComGameState VisualizeGameState) // , out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory				History;
    local XComGameStateContext_Ability		context;
    local StateObjectReference				InteractingUnitRef;
    //local VisualizationTrack				EmptyTrack, BuildTrack, TargetTrack; // deprecated in WOTC
	local VisualizationActionMetadata		ActionMetadata, TargetMetadata;
    local X2Action_PlayAnimation			PlayAnimationAction;
	local X2Action_PlaySoundAndFlyOver		SoundAndFlyover, SoundAndFlyoverTarget;
	local XComGameState_Ability				Ability;
	local XComGameState_Effect				EffectState;
	local XComGameState_Unit				UnitState, SourceUnit;

    History = `XCOMHISTORY;
    context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	Ability = XComGameState_Ability(History.GetGameStateForObjectID(context.InputContext.AbilityRef.ObjectID, 1, VisualizeGameState.HistoryIndex - 1));
    InteractingUnitRef = context.InputContext.SourceObject;
	SourceUnit =  XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', EffectState)
	{

		//TargetTrack = EmptyTrack;
		UnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

		if ((UnitState != none) && (EffectState.StatChanges.Length > 0))
		{
			TargetMetadata.StateObject_NewState = UnitState;
			TargetMetadata.StateObject_OldState = `XCOMHISTORY.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1); 
			TargetMetadata.VisualizeActor = UnitState.GetVisualizer();
			SoundandFlyoverTarget = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(TargetMetadata, context, false, TargetMetadata.LastActionAdded));
			SoundandFlyoverTarget.SetSoundAndFlyOverParameters(none, Ability.GetMyTemplate().LocFlyOverText, 'None', eColor_Good,Ability.GetMyTemplate().IconImage);
		}
		
	}
}


// Perk name:		LuckyStreak
// Perk effect:		When this unit hits an enemy with a Critical Hit, this unit gains +20% Critical Hit Chance for this turn.
// Localized text:	When this unit hits an enemy with a Critical Hit, this unit gains +20% Critical Hit Chance for this turn.
// Config:			(AbilityName="LuckyStreak")
static function X2AbilityTemplate LuckyStreak()
{
	local X2AbilityTemplate Template;



    return Template;
}

// Perk name:		Omega
// Perk effect:		When this unit takes the last Shot in their magazine, it gets a +25% Damage bonus.
// Localized text:	When this unit takes the last Shot in their magazine, it gets a +25% Damage bonus.
// Config:			(AbilityName="Omega")
static function X2AbilityTemplate Omega()
{
	local X2AbilityTemplate						Template;
	local X2Effect_AlphaOmega 					OmegaEffect;




    OmegaEffect = new class'X2Effect_AlphaOmega';
    OmegaEffect.EffectName = 'OmegaEffect';
	OmegaEffect.ApplyTo = 'LastShot';
    OmegaEffect.BonusDamagePercent = default.OMEGA_BONUS_DAMAGE;


	Template = Passive('Omega', "img:///XPerkIconPack.UIPerk_sniper_crit2",,OmegaEffect);

	return Template;

}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Perk name:		XGT_PrecisionShot_I
// Perk effect:		Special shot with aim and damage boost, 30/40/50%. 4 turns cooldown
// Localized text:	Special shot with aim and damage boost, 30/40/50%. 4 turns cooldown
// Config:			(AbilityName="XGT_PrecisionShot_I")
static function X2AbilityTemplate XGT_PrecisionShot_I()
{
	local X2AbilityTemplate Template;
	local X2AbilityCooldownReduction	Cooldown;
	local array<name> CooldownReductionAbilities;
	local array<int> CooldownReductionAmount;
    

	// Create the template using a helper function
	Template = Attack('XGT_PrecisionShot_I', "img:///XPerkIconPack.UIPerk_sniper_chevron", true, none, class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY, eCost_WeaponConsumeAll, 1);

	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	
	Cooldown = new class'X2AbilityCooldownReduction';
	Cooldown.BaseCooldown = 4;
	Template.AbilityCooldown = Cooldown;

    Template.ActivationSpeech = 'DeadEye';
    Template.AdditionalAbilities.AddItem('XGT_PrecisionShotBonus');

	return Template;
}

// Perk name:		XGT_PrecisionShot_II
// Perk effect:		Special shot with aim and damage boost, 30/40/50%. 4 turns cooldown
// Localized text:	Special shot with aim and damage boost, 30/40/50%. 4 turns cooldown
// Config:			(AbilityName="XGT_PrecisionShot_II")
static function X2AbilityTemplate XGT_PrecisionShot_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('XGT_PrecisionShot_II', "img:///XPerkIconPack.UIPerk_sniper_chevron_x2");
	Template.bUniqueSource = true;

    Template.PrerequisiteAbilities.AddItem('XGT_PrecisionShot_I');
	return Template;
}

// Perk name:		XGT_PrecisionShot_III
// Perk effect:		Special shot with aim and damage boost, 30/40/50%. 4 turns cooldown
// Localized text:	Special shot with aim and damage boost, 30/40/50%. 4 turns cooldown
// Config:			(AbilityName="XGT_PrecisionShot_III")
static function X2AbilityTemplate XGT_PrecisionShot_III()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('XGT_PrecisionShot_III', "img:///XPerkIconPack.UIPerk_sniper_chevron_x3");
	Template.bUniqueSource = true;

    Template.PrerequisiteAbilities.AddItem('XGT_PrecisionShot_I');
    Template.PrerequisiteAbilities.AddItem('XGT_PrecisionShot_II');
	return Template;
}


static function X2AbilityTemplate XGT_PrecisionShotBonus()
{
	local X2AbilityTemplate Template;
    local X2Effect_PrecisionShotBonus    Effect;

    `CREATE_X2ABILITY_TEMPLATE (Template, 'XGT_PrecisionShotBonus');
    Template.IconImage = "img:///XPerkIconPack.UIPerk_sniper_chevron";
    Template.AbilitySourceName = 'eAbilitySource_Perk';
    Template.eAbilityIconBehaviorHUD = 2;
    Template.Hostility = 2;
    Template.AbilityToHitCalc = default.DeadEye;
    Template.AbilityTargetStyle = default.SelfTarget;
    Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

    Effect = new class'X2Effect_PrecisionShotBonus';
    Effect.BuildPersistentEffect(1, true, false, false);
    Effect.SetDisplayInfo(0, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false,, Template.AbilitySourceName);
    Template.AddTargetEffect(Effect);
    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}


// Perk name:		Head Hunter
// Perk effect:		Increased damage bonus for every kill.
// Localized text:	Increased damage bonus for every kill.
// Config:			(AbilityName="HeadHunter")

static function X2AbilityTemplate HeadHunter()
{
	local X2AbilityTemplate						Template;
	local X2Effect_HeadHunter 					Effect;




    Effect = new class'X2Effect_HeadHunter';


	Template = Passive('HeadHunter', "img:///XPerkIconPack.UIPerk_stealth_sniper",,Effect);

	return Template;

}

static function X2AbilityTemplate WeakSpot()
{
	local XMBEffect_ConditionalBonus Effect;
	local X2Condition_UnitStatCheck Condition;

	// Create a condition that checks that the unit is at less than 100% HP.
	// X2Condition_UnitStatCheck can also check absolute values rather than percentages, by
	// using "false" instead of "true" for the last argument.
	Condition = new class'X2Condition_UnitStatCheck';
	Condition.AddCheckStat(eStat_HP, 100, eCheck_LessThan,,, true);

	// Create a conditional bonus effect
	Effect = new class'XMBEffect_ConditionalBonus';

	// The effect grants +10 Crit chance and +20 Defense
	Effect.AddToHitModifier(10, eHit_Crit);

	// The effect only applies while wounded
	EFfect.AbilityTargetConditions.AddItem(Condition);
	
	// Create the template using a helper function
	return Passive('WeakSpot', "img:///XPerkIconPack.UIPerk_enemy_shot_plus", true, Effect);
}





// Perk name:		Concussion Shot
// Perk effect:		Special shot that applies the Stunned status effect for 2 turns.
// Localized text:	Special shot that applies the Stunned status effect for 2 turns.
// Config:			(AbilityName="ConcussionShot_I")
static function X2AbilityTemplate ConcussionShot_I()
{
	local X2AbilityTemplate              Template;
	local X2Effect_Stunned	             StunnedEffect;
    local X2AbilityToHitCalc_StandardAim ToHitCalc;
    local XMBEffect_ConditionalBonus    BonusAimEffect;
    local XMBCondition_AbilityName      Condition;
    local X2Condition_HasAbility  AbilityCondition;
    local X2AbilityCooldownReduction    Cooldown;
    local array<name>                   CooldownReductionAbilities;
    local array<Int>                           CooldownReductionAmount;

	// Create the template using a helper function
	Template = Attack('ConcussionShot_I', "img:///XPerkIconPack.UIPerk_mind_chevron", false, none, class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY, eCost_WeaponConsumeAll, 1);

	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);

	// Create Stun effect
	StunnedEffect = class'X2StatusEffects'.static.CreateStunnedStatusEffect(2, 100, false);
	StunnedEffect.bRemoveWhenSourceDies = false;
	Template.AddTargetEffect(StunnedEffect);
	
	// Custom hit calc to disallow critical hits
	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	ToHitCalc.bAllowCrit = false;
	Template.AbilityToHitCalc = ToHitCalc;
	Template.AbilityToHitOwnerOnMissCalc = ToHitCalc;


	Cooldown = new class'X2AbilityCooldownReduction';
	Cooldown.BaseCooldown = 4;
    CooldownReductionAmount.AddItem(2);
    CooldownReductionAbilities.AddItem('ConcussionShot_III');
    Cooldown.CooldownReductionAbilities = CooldownReductionAbilities;
    Cooldown.CooldownReductionAmount = CooldownReductionAmount;

	Template.AbilityCooldown = Cooldown;
 
    Template.AdditionalAbilities.AddItem('XGT_ConcussionShotBonus');

	return Template;
}


static function X2AbilityTemplate XGT_ConcussionShotBonus()
{
	local X2AbilityTemplate Template;
    local X2Effect_ConcussionShotBonus    Effect;

    `CREATE_X2ABILITY_TEMPLATE (Template, 'XGT_ConcussionShotBonus');
    Template.IconImage = "img:///XPerkIconPack.UIPerk_mind_chevron";
    Template.AbilitySourceName = 'eAbilitySource_Perk';
    Template.eAbilityIconBehaviorHUD = 2;
    Template.Hostility = 2;
    Template.AbilityToHitCalc = default.DeadEye;
    Template.AbilityTargetStyle = default.SelfTarget;
    Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

    Effect = new class'X2Effect_ConcussionShotBonus';
    Effect.BuildPersistentEffect(1, true, false, false);
    Effect.SetDisplayInfo(0, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false,, Template.AbilitySourceName);
    Template.AddTargetEffect(Effect);
    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}



// Perk name:		Concussion Shot II
// Perk effect:		Increased aim on concussion shot
// Localized text:	Increased aim on concussion shot
// Config:			(AbilityName="ConcussionShot_II")

static function X2AbilityTemplate ConcussionShot_II()
{
	local X2AbilityTemplate						Template;



	Template = Passive('ConcussionShot_II', "img:///XPerkIconPack.UIPerk_mind_chevron_x2");

    Template.PrerequisiteAbilities.AddItem('ConcussionShot_I');

	return Template;

}

// Perk name:		Concussion Shot III
// Perk effect:		Cooldown reduced by 2 turns
// Localized text:	Cooldown reduced by 2 turns
// Config:			(AbilityName="ConcussionShot_III")

static function X2AbilityTemplate ConcussionShot_III()
{
	local X2AbilityTemplate						Template;



	Template = Passive('ConcussionShot_III', "img:///XPerkIconPack.UIPerk_mind_chevron_x3");

    Template.PrerequisiteAbilities.AddItem('ConcussionShot_I');

	return Template;

}


// Apex Predator - Passive: When this unit kills an enemy with a Shot, all enemies within 10 meters get disoriented. When this unit kills an enemy with a Critical Hit, enemies get panicked instead.
static function X2AbilityTemplate Terrified()
{

	local X2AbilityTemplate										Template;
    local X2Effect_Terrified                                    Effect;

    Effect = new class'X2Effect_Terrified';

	Template = Passive('Terrified', "img:///XPerkIconPack.UIPerk_panic_shot", false, Effect);

	Template.AdditionalAbilities.AddItem('TerrifiedApply');


	return Template;
}

static function X2AbilityTemplate TerrifiedApply()
{

	local X2AbilityTemplate										Template;	
	local X2AbilityTrigger_EventListener						EventListener;
	local X2AbilityMultiTarget_Radius							RadiusMultiTarget;
	local X2Condition_UnitProperty								UnitPropertyCondition;
	local X2Effect_Persistent									DisorientedEffect;
	local X2Effect_Persistent									PanickedEffect;


	`CREATE_X2ABILITY_TEMPLATE(Template, 'TerrifiedApply');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_panic_shot";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.bCrossClassEligible = false;

	
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);


	// This ability triggers after a Critical Hit
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'TerrifiedTrigger';
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.VoidRiftInsanityListener;
	Template.AbilityTriggers.AddItem(EventListener);



	// Setup Multitarget attributes
	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	//RadiusMultiTarget.bAddPrimaryTargetAsMultiTarget = true;
	RadiusMultiTarget.bIgnoreBlockingCover = true;
	RadiusMultiTarget.bAllowDeadMultiTargetUnits = false;
	// RadiusMultiTarget.bExcludeSelfAsTargetIfWithinRadius = false;
	RadiusMultiTarget.bUseWeaponRadius = false;
	RadiusMultiTarget.fTargetRadius = 10;
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;



	// Don't apply to allies
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.ExcludeCivilian = true;
	UnitPropertyCondition.FailOnNonUnits = true;
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	// Create the Panicked effect on the targets
	DisorientedEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect(, , false);
	DisorientedEffect.EffectName = 'Terrified';
    DisorientedEffect.VisualizationFn = EffectFlyOver_Visualization;
    Template.AddMultiTargetEffect(DisorientedEffect);
	Template.AddTargetEffect(DisorientedEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

static function EventListenerReturn ApplyTerrifiedOnKill(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit			DeadUnit, SourceUnit;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Ability			AbilityState;


	if (GameState.GetContext().InterruptionStatus != eInterruptionStatus_Interrupt)
	{
		DeadUnit = XComGameState_Unit(EventData);
		if (DeadUnit != none)
		{
			AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
			if ((AbilityContext != none) )
			{
                AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
                SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

                if (SourceUnit != none && SourceUnit.HasSoldierAbility('Terrified'))
                {
                    class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName( DeadUnit.GetReference(), 'TerrifiedApply', DeadUnit.GetReference());
                }
			}
		}
	}
	return ELR_NoInterrupt;
}

// Perk name:		Sure Thing
// Perk effect:		When this unit hits with a Shot that is not a Critical Hit, this unit gets +20% Critical Hit Chance. When this unit hits an enemy with a Critical Hit, this effect is removed.
// Localized text:	When this unit hits with a Shot that is not a Critical Hit, this unit gets +20% Critical Hit Chance. When this unit hits an enemy with a Critical Hit, this effect is removed.
// Config:			(AbilityName="SureThing")

static function X2AbilityTemplate SureThing()
{
	local X2AbilityTemplate						Template;
	local X2Effect_SureThing 					Effect;




    Effect = new class'X2Effect_SureThing';


	Template = Passive('SureThing', "img:///XPerkIconPack.UIPerk_stabilize_crit",,Effect);

	return Template;

}


static function X2AbilityTemplate ActiveReload()
{
	local X2AbilityTemplate						Template;
	local X2Effect_ActiveReload					Effect;




    Effect = new class'X2Effect_ActiveReload';


	Template = Passive('ActiveReload', "img:///XPerkIconPack.UIPerk_stabilize_crit",,Effect);
    Template.AdditionalAbilities.AddItem('ActiveReload_Triggered');

	return Template;

}

static function X2AbilityTemplate ActiveReload_Triggered()
{
    local X2AbilityTemplate			Template;
    local X2Effect_ActiveReloadBonusDamage Effect;
    local X2AbilityTrigger_EventListener    EventTrigger;



    Template = SelfTargetTrigger('ActiveReload_Triggered', "img:///XPerkIconPack.UIPerk_crit_chevron", false, none, 'ActiveReloadTrigger');

    Effect = new class'X2Effect_ActiveReloadBonusDamage';
	Effect.BuildPersistentEffect (2, false, true, , eGameRule_PlayerTurnEnd);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, "Active Reload", "This unit has increased damage due to active reload", Template.IconImage, true,,Template.AbilitySourceName);
    Effect.DuplicateResponse = eDupe_Refresh;
	Template.AddTargetEffect (Effect);

	Template.bShowActivation = true;


    return Template;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Perk name:		Pistoleer
// Perk effect:		Your pistol attacks get +10 Aim and deal +1 damage.
// Localized text:	"Your pistol attacks get <Ability:+ToHit/> Aim and deal <Ability:+Damage/> damage."
// Config:			(AbilityName="Pistoleer", ApplyToWeaponSlot=eInvSlot_SecondaryWeapon)
static function X2AbilityTemplate Pistoleer()
{
	local XMBEffect_ConditionalBonus    DamageEffect;
    local X2Effect_ModifyRangePenalties RangeEffect;
    local X2AbilityTemplate						Template;

	// Create an effect that adds +10 to hit and +1 damage
	DamageEffect = new class'XMBEffect_ConditionalBonus';
	DamageEffect.AddDamageModifier(1);

	RangeEffect = new class'X2Effect_ModifyRangePenalties';
	RangeEffect.RangePenaltyMultiplier = -1;
	RangeEffect.BaseRange = 11;
	RangeEffect.bLongRange = true;
	RangeEffect.EffectName = 'Pistoleer';

	// Restrict to the weapon matching this ability
	DamageEffect.AbilityTargetConditions.AddItem(default.MatchingWeaponCondition);
    RangeEffect.AbilityTargetConditions.AddItem(default.MatchingWeaponCondition);

    Template = Passive('Pistoleer', "img:///XPerkIconPack.UIPerk_pistol_box", false, DamageEffect);
    Template.AddTargetEffect(RangeEffect);

    Template.AdditionalAbilities.AddItem('Quickdraw');

    return Template;
}

// Perk name:		FastFingers_I
// Perk effect:		If your pistol attacks kills the target, this unit reloads their primary weapon.
// Localized text:	If your pistol attacks kills the target, this unit reloads their primary weapon.
// Config:			(AbilityName="FastFingers_I")
static function X2AbilityTemplate FastFingers_I()
{
	local X2AbilityTemplate						Template;
	local X2Effect_FastFingers 					Effect;




    Effect = new class'X2Effect_FastFingers';
	Template = Passive('FastFingers_I', "img:///XPerkIconPack.UIPerk_pistol_cycle",,Effect);

	return Template;

}

// Perk name:		FastFingers_II
// Perk effect:		If your pistol attacks kills the target, this unit gets 1 AP.
// Localized text:	If your pistol attacks kills the target, this unit gets 1 AP.
// Config:			(AbilityName="FastFingers_II")
static function X2AbilityTemplate FastFingers_II()
{
	local X2AbilityTemplate						Template;






	Template = Passive('FastFingers_II', "img:///XPerkIconPack.UIPerk_move_pistol");

    Template.PrerequisiteAbilities.AddItem('FastFingers_I');
	return Template;

}


// Perk name:		ChainedShot_I
// Perk effect:		1/2 actions if the shot hits. 5 turns cooldown
// Localized text:	Special shot that grants 1 AP back if it hits the target. 5 turn cooldown
// Config:			(AbilityName="ChainedShot_I")
static function X2AbilityTemplate ChainedShot_I()
{
	local X2AbilityTemplate Template;
	local X2AbilityCooldownReduction	Cooldown;
    local X2Condition_Visibility        VisibilityCondition;


	// Create the template using a helper function
	Template = Attack('ChainedShot_I', "img:///XPerkIconPack.UIPerk_pistol_chevron", true, none, class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY, eCost_WeaponConsumeAll, 1);

	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bRequireGameplayVisible = true;
	VisibilityCondition.bAllowSquadsight = false;

	Template.AbilityTargetConditions.AddItem(VisibilityCondition);
	
	Cooldown = new class'X2AbilityCooldownReduction';
	Cooldown.BaseCooldown = 2;
	Template.AbilityCooldown = Cooldown;

    Template.AdditionalAbilities.AddItem('ChainedShot_Passive');

	return Template;
}

// Perk name:		ChainedShot_II
// Perk effect:		1/2 actions if the shot hits. 5 turns cooldown
// Localized text:	The bonus AP granted by Chained Shot are increased from 1 to 2. Passive. Requires ChainedShot_I
// Config:			(AbilityName="ChainedShot_I")
static function X2AbilityTemplate ChainedShot_II()
{
	local X2AbilityTemplate						Template;






	Template = Passive('ChainedShot_II', "img:///XPerkIconPack.UIPerk_pistol_chevron_x2");

    Template.PrerequisiteAbilities.AddItem('ChainedShot_I');
	return Template;

}


static function X2AbilityTemplate ChainedShot_Passive()
{
	local X2AbilityTemplate						Template;
	local X2Effect_ChainedShot 					Effect;




    Effect = new class'X2Effect_ChainedShot';
	Template = Passive('ChainedShot_Passive', "img:///XPerkIconPack.UIPerk_pistol_chevron",,Effect);
    HidePerkIcon(Template);

	return Template;

}



static function X2AbilityTemplate XGT_RunAndGun()
{
	local XMBEffect_ConditionalBonus Effect;
	local X2AbilityTemplate Template;
    local X2Condition_UnitValue         ValueCondition;

	// Create a conditional bonus for the Aim bonus
	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'XGT_RunAndGun';

	// The bonus adds +20 Aim
	Effect.AddToHitModifier(20);

	// When attacking, require that the target have height disadvantage
	Effect.AbilityTargetConditions.AddItem(default.HeightDisadvantageCondition);
	Effect.AbilityTargetConditionsAsTarget.AddItem(default.HeightAdvantageCondition);


	// Create the template using a helper function
	Template = Passive('XGT_RunAndGun', "img:///XPerkIconPack.UIPerk_pistol_blossom", true, Effect);


	Effect = new class'XMBEffect_ConditionalBonus';
    Effect.FriendlyName = "Run And Gun";
	Effect.AddPercentDamageModifier(50);

	ValueCondition = new class'X2Condition_UnitValue';
	ValueCondition.AddCheckValue('MovesThisTurn', 0, eCheck_GreaterThan);
	Effect.AbilityShooterConditions.AddItem(ValueCondition);
    Effect.AbilityShooterConditionsAsTarget.AddItem(ValueCondition);

    Template.AddTargetEffect(Effect);

	return Template;
}