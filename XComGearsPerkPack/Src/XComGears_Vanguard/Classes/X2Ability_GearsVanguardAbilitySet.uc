class X2Ability_GearsVanguardAbilitySet extends XMBAbility config(GearsVanguardAbilitySet);

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  GearsVanguard:
//     Shotgun/Bullpup
//     Sword

// Squaddie Level skills:
//     Bastion (Heal 1 HP per turn if injured and increased post mission healing, i.e. upto 3 HP)

// Warden Tree:
//     Distraction I, II, III (Mimic beacon like effect, with increased damage reduction and then reduce cooldown)
//     Vampiric Aura (Damage dealt heals by a percentage amount)
//     Self Revive (Revive at the end of turn on bleeding out)
//     Badass (75% damage reduction against 1st attack this enemy turn)

// Paladin Tree:
//     Unnerve (Damaged enemies get decreased damage)
//     Bastion II (Increased post mission healing)
//     Inspiration I, II (Grant target unit increased defense until start of next turn)
//     Rally I, II, III (Group Vampiric aura with increased amount and duration)
//     Stand Together (Area wide revival and damage reduction by 50% until end of turn)

// Shock Trooper:
//     Intimidate I, II, III (Targeted enemy gets panic roll and knock back)
//     Breach (Enemies get breached status: They take increased damage and killing them gives 1 AP )
//     Demoralize (Attacking enemies debuffs them)

// Assault:
//     Executioner (Increased damage against injured enemies)
//     Rage Shot I, II, III(Deal Increased damage scaling with missing health)
//     Close and Personal (LW2)
//     HEMORRHAGE (Crit on enemies applies bleed)
//     Avenger (When an ally takes damage, this unit gets +25% Damage for this turn, to a maximum of 4 stacks. When an ally dies, this unit gets 3 Actions.)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var config int 	FortressHealAmount;
var config int	FortressPostMissionHealing;

var config int 	Distraction_I_Cooldown;
var config int 	Distraction_III_CooldownReduction;


static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(XComGearsVanguard_Fortress());

	// Warden
	Templates.AddItem(CreateDuelAbility());
	/*>>*/Templates.AddItem(CreateDuelInitiatedAbility());
	Templates.AddItem(Distraction_II());
	Templates.AddItem(Distraction_III());
	Templates.AddItem(Leech());
	Templates.AddItem(SelfRevive());
		Templates.AddItem(SelfReviveOnBleedout());
	Templates.AddItem(Badass());

	// Paladin
	Templates.AddItem(XComGearsVanguard_Bastion());
	Templates.AddItem(Inspiration_I());
	Templates.AddItem(Inspiration_II());
	Templates.AddItem(Rally_I());
	Templates.AddItem(Rally_II());
	Templates.AddItem(Rally_III());
	Templates.AddItem(StandTogether());
	
	// Shock Trooper
	Templates.AddItem(Intimidate_I());
	Templates.AddItem(Intimidate_II());
	Templates.AddItem(Intimidate_III());
	Templates.AddItem(Unnerve());
	Templates.AddItem(Menacing());
		Templates.AddItem(MenacingApply());
	Templates.AddItem(Breach());
		Templates.AddItem(Breach_Passive());
	
	// Assault
	Templates.AddItem(Executioner());
	Templates.AddItem(Hemorrhage());
	Templates.AddItem(Expertise());
	Templates.AddItem(RageShot_I());
		Templates.AddItem(RageShotBonus());
	Templates.AddItem(RageShot_II());
	Templates.AddItem(RageShot_III());
	Templates.AddItem(Avenger());



	return Templates;
}


// Perk name:		Fortress
// Perk effect:		Heal 1 HP per turn if injured and increased post mission healing, i.e. upto 3 HP.
// Localized text:	"Heal 1 HP per turn if injured and increased post mission healing, i.e. upto 3 HP. Passive"
// Config:			(AbilityName="XComGearsVanguard_Fortress")??

static function X2AbilityTemplate XComGearsVanguard_Fortress()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_Regeneration				RegenerationEffect;
	local X2Effect_BastionPostMissionHealing		BastionPostMissionHealing;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'XComGearsVanguard_Fortress');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_medkit_blaze";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = True;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);



	// Build the regeneration effect
	RegenerationEffect = new class'X2Effect_Regeneration';
	RegenerationEffect.BuildPersistentEffect(1, true, false, false, eGameRule_PlayerTurnBegin);
	RegenerationEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	RegenerationEffect.HealAmount = default.FortressHealAmount;
	RegenerationEffect.MaxHealAmount = 99999999; // Basically near infinite
	RegenerationEffect.HealthRegeneratedName = 'StasisVestHealthRegenerated';
	RegenerationEffect.VisualizationFn = EffectFlyOver_Visualization;
	Template.AddTargetEffect(RegenerationEffect);


	// Apply the bastion post mission healing effect
	BastionPostMissionHealing = new class'X2Effect_BastionPostMissionHealing';
	BastionPostMissionHealing.HpToBeHealed = default.FortressPostMissionHealing;
	BastionPostMissionHealing.BuildPersistentEffect(1, true, false, false, eGameRule_PlayerTurnBegin);
	BastionPostMissionHealing.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	Template.AddTargetEffect(BastionPostMissionHealing);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}



// Perk name:		Distraction
// Perk effect:		Targeted enemy will try to attack this unit on its next turn.
// Localized text:	"Activate to grant targeted enemy +100 hit chance against you. 4 turns cooldown"
// Config:			(AbilityName="MZDuel")??

static function X2DataTemplate CreateDuelAbility()
{
	local X2AbilityTemplate							Template;
	local X2AbilityCost_ActionPoints				ActionPointCost;
	local X2Condition_UnitProperty					UnitPropertyCondition;
	local X2Condition_Visibility					TargetVisibilityCondition;
	local X2Condition_UnitEffects					UnitEffectsCondition;
	local X2Condition_UnitValue						IsNotImmobilized;
	local MZ_Effect_Duel							ToHitModifier;
	local X2Condition_UnitEffectsWithAbilitySource	EffectsWithSourceCondition;
	local X2Condition_UnitEffectsWithAbilityTarget	EffectsWithTargetCondition;
    local X2Condition_AbilityProperty                   OwnerHasAbilityCondition;
    local X2Effect_DamageReduction                      DamageReductionEffect;
	local X2AbilityCooldownReduction					Cooldown;
	local array<name> CooldownReductionAbilities;
	local array<int> CooldownReductionAmount;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'MZDuel'); // Copied from Mitzruti's perk pack - Credit given in mod description

	Template.IconImage = "img:///XPerkIconPack.UIPerk_psi_shot";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.Hostility = eHostility_Offensive;
	Template.AdditionalAbilities.AddItem('MZDuelInitiated');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
	Template.bShowActivation = true;


	CooldownReductionAbilities.AddItem('Distraction_III');
	CooldownReductionAmount.AddItem(default.Distraction_III_CooldownReduction);




	// The shooter cannot be mind controlled
	UnitEffectsCondition = new class'X2Condition_UnitEffects';
	UnitEffectsCondition.AddExcludeEffect(class'X2Effect_MindControl'.default.EffectName, 'AA_UnitIsMindControlled');
	Template.AbilityShooterConditions.AddItem(UnitEffectsCondition);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// Shooter and target cannot already be dueling
	UnitEffectsCondition = new class'X2Condition_UnitEffects';
	UnitEffectsCondition.AddExcludeEffect('MZDuelShooter', 'AA_DuplicateEffectIgnored');
	UnitEffectsCondition.AddExcludeEffect('MZDuelTarget', 'AA_DuplicateEffectIgnored');
	Template.AbilityShooterConditions.AddItem(UnitEffectsCondition);

	IsNotImmobilized = new class'X2Condition_UnitValue';
	IsNotImmobilized.AddCheckValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName, 0);
	Template.AbilityShooterConditions.AddItem(IsNotImmobilized);

	UnitEffectsCondition = new class'X2Condition_UnitEffects';
	UnitEffectsCondition.AddExcludeEffect('MZDuelShooter', 'AA_DuplicateEffectIgnored');
	UnitEffectsCondition.AddExcludeEffect('MZDuelTarget', 'AA_DuplicateEffectIgnored');
	Template.AbilityTargetConditions.AddItem(UnitEffectsCondition);

	IsNotImmobilized = new class'X2Condition_UnitValue';
	IsNotImmobilized.AddCheckValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName, 0);
	Template.AbilityTargetConditions.AddItem(IsNotImmobilized);

	// Target must be an enemy
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.RequireWithinRange = false;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	// Target must be visible and may use squad sight
	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	// 100% chance to hit
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = new class'X2AbilityTarget_Single';
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_PlayerInput');

	// Create the Duel effects
	EffectsWithSourceCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	EffectsWithSourceCondition.AddRequireEffect('MZDuelTarget', 'AA_MissingRequiredEffect');
	ToHitModifier = new class'MZ_Effect_Duel';
	ToHitModifier.DuplicateResponse = eDupe_Ignore;
	ToHitModifier.EffectName = 'MZDuelShooter';
	ToHitModifier.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	ToHitModifier.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true, , Template.AbilitySourceName);
	ToHitModifier.AddEffectHitModifier( eHit_Success, 100, Template.LocFriendlyName );
	ToHitModifier.AddEffectHitModifier( eHit_Success, 100, Template.LocFriendlyName, class'X2AbilityToHitCalc_StandardMelee' );
	ToHitModifier.ToHitConditions.AddItem(EffectsWithSourceCondition);
	ToHitModifier.bRemoveWhenSourceDies = true;
	ToHitModifier.bRemoveWhenTargetDies = true;
	//ToHitModifier.bRemoveWhenSourceUnconscious = true;
	//ToHitModifier.bRemoveWhenTargetUnconscious = true;
	Template.AddShooterEffect(ToHitModifier);

	EffectsWithTargetCondition = new class'X2Condition_UnitEffectsWithAbilityTarget';
	EffectsWithTargetCondition.AddRequireEffect('MZDuelTarget', 'AA_MissingRequiredEffect');
	ToHitModifier = new class'MZ_Effect_Duel';
	ToHitModifier.DuplicateResponse = eDupe_Ignore;
	ToHitModifier.EffectName = 'MZDuelTarget';	//perk will add both target and shooter VFX
	ToHitModifier.BuildPersistentEffect(2, false, false, false, eGameRule_PlayerTurnEnd); // Make sure it lasts entil start of player turn, i.e. thru the alien turn
	ToHitModifier.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true, , Template.AbilitySourceName);
	ToHitModifier.AddEffectHitModifier(eHit_Success, 100, Template.LocFriendlyName);
	ToHitModifier.AddEffectHitModifier( eHit_Success, 100, Template.LocFriendlyName, class'X2AbilityToHitCalc_StandardMelee' );
	ToHitModifier.ToHitConditions.AddItem(EffectsWithTargetCondition);
	ToHitModifier.bRemoveWhenSourceDies = true;
	ToHitModifier.bRemoveWhenTargetDies = true;
	//ToHitModifier.bRemoveWhenSourceUnconscious = true;
	//ToHitModifier.bRemoveWhenTargetUnconscious = true;
	//ToHitModifier.EffectRemovedFn = DuelTargetEffect_Removed; //Maybe not needed since we can keep the DR effect even if target is dead. It runs out in 1 turn anyway
	Template.AddTargetEffect(ToHitModifier);


    // Add DR to shooter if shooter has lvl 2 perk
    DamageReductionEffect = new class'X2Effect_DamageReduction';
		DamageReductionEffect.EffectName = 'Distraction_DR';
		DamageReductionEffect.bAbsoluteVal = false;
		DamageReductionEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
		DamageReductionEffect.SetDisplayInfo(ePerkBuff_Bonus, "Distraction II", "Distraction II", Template.IconImage,,,Template.AbilitySourceName);
		DamageReductionEffect.DuplicateResponse = eDupe_Ignore;
	EffectsWithSourceCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
		EffectsWithSourceCondition.AddRequireEffect('MZDuelShooter', 'AA_MissingRequiredEffect');
		DamageReductionEffect.TargetConditions.AddItem(EffectsWithSourceCondition);
    
	Template.AddShooterEffect(DamageReductionEffect);

    // Add more DR and/or dodge if unit has lvl 3 perk
    //CooldownReductionEffect = 
	Cooldown = new class'X2AbilityCooldownReduction';
	Cooldown.BaseCooldown = default.Distraction_I_Cooldown;
	Cooldown.CooldownReductionAbilities = CooldownReductionAbilities;
	Cooldown.CooldownReductionAmount = CooldownReductionAmount;
	Template.AbilityCooldown = Cooldown;

	Template.CustomFireAnim = 'HL_SignalPoint';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = Duel_BuildVisualization;
	Template.CinescriptCameraType = "Mark_Target";
	Template.bFrameEvenWhenUnitIsHidden = true;

	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	//Template.ActivationSpeech = 'AbilDuel';

	return Template;
}

//DuelTargetEffect_Removed
//removes the duel shooter effect from the shooter if the duel target effect is removed ( when the target dies for example )
// static function DuelTargetEffect_Removed(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
// {
// 	local XComGameState_Unit UnitState;
// 	local XComGameState_Effect EffectState;

// 	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
// 	if (UnitState == none)
// 	{
// 		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
// 		if (UnitState == none)
// 		{
// 			`RedScreen("DuelTargetEffect_Removed could not find source unit.");
// 			return;
// 		}
// 	}
// 	EffectState = UnitState.GetUnitAffectedByEffectState('MZDuelShooter');
// 	if( EffectState != None && !EffectState.bRemoved )
// 	{
// 		EffectState.RemoveEffect(NewGameState, NewGameState, true); //Cleansed
// 	}
// }

simulated function Duel_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory				History;
	local XComGameStateContext_Ability		Context;
	local StateObjectReference				ShooterUnitRef;
	local StateObjectReference				TargetUnitRef;
	local XComGameState_Ability				Ability;
	local X2AbilityTemplate					AbilityTemplate;
	local AbilityInputContext				AbilityContext;
	local VisualizationActionMetadata		EmptyTrack;
	local VisualizationActionMetadata		ActionMetadata;
	local X2Action_PlaySoundAndFlyOver		SoundAndFlyOver;	
	local X2Action_PlayAnimation            PlayAnimation;
	local Actor								TargetVisualizer, ShooterVisualizer;
	local X2VisualizerInterface				TargetVisualizerInterface, ShooterVisualizerInterface;
	local int								EffectIndex;
	local name								ApplyResult;

	History = `XCOMHISTORY;
	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	AbilityContext = Context.InputContext;
	Ability = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.AbilityRef.ObjectID));
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.AbilityTemplateName);

	//Configure the visualization track for the shooter
	//****************************************************************************************
	ShooterUnitRef = Context.InputContext.SourceObject;
	ShooterVisualizer = History.GetVisualizer(ShooterUnitRef.ObjectID);
	ShooterVisualizerInterface = X2VisualizerInterface(ShooterVisualizer);

	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(ShooterUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(ShooterUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(ShooterUnitRef.ObjectID);

	if (AbilityTemplate != None)
	{
		if (!AbilityTemplate.bSkipFireAction && !AbilityTemplate.bSkipExitCoverWhenFiring)
		{
			class'X2Action_ExitCover'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
		}
	}

//	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
//	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, Ability.GetMyTemplate().LocFlyOverText, '', eColor_Bad);

	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	PlayAnimation.Params.AnimName = ( AbilityTemplate != None && AbilityTemplate.CustomFireAnim != '' ) ? AbilityTemplate.CustomFireAnim: 'FF_Duel';

	if (AbilityTemplate != None && AbilityTemplate.AbilityTargetEffects.Length > 0)			//There are effects to apply
	{
		//Add any X2Actions that are specific to this effect being applied. These actions would typically be instantaneous, showing UI world messages
		//playing any effect specific audio, starting effect specific effects, etc. However, they can also potentially perform animations on the 
		//track actor, so the design of effect actions must consider how they will look/play in sequence with other effects.
		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
		{
			ApplyResult = Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]);

			// Source effect visualization
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, ActionMetadata, ApplyResult);
		}
	}

	if (ShooterVisualizerInterface != none)
	{
		ShooterVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
	}

	if (AbilityTemplate != None)
	{
		if (!AbilityTemplate.bSkipFireAction && !AbilityTemplate.bSkipExitCoverWhenFiring)
		{
			class'X2Action_EnterCover'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
		}
	}

	//****************************************************************************************
	//Configure the visualization track for the target
	//****************************************************************************************
	TargetUnitRef = Context.InputContext.PrimaryTarget;
	TargetVisualizer = History.GetVisualizer(AbilityContext.PrimaryTarget.ObjectID);
	TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);

	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(TargetUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(TargetUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(TargetUnitRef.ObjectID);

	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));

	if (AbilityTemplate != None && AbilityTemplate.AbilityTargetEffects.Length > 0)			//There are effects to apply
	{
		//Add any X2Actions that are specific to this effect being applied. These actions would typically be instantaneous, showing UI world messages
		//playing any effect specific audio, starting effect specific effects, etc. However, they can also potentially perform animations on the 
		//track actor, so the design of effect actions must consider how they will look/play in sequence with other effects.
		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
		{
			ApplyResult = Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]);

			// Target effect visualization
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, ApplyResult);
		}

		if (TargetVisualizerInterface != none)
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
		}
	}
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, Ability.GetMyTemplate().LocFlyOverText, '', eColor_Bad);
	//****************************************************************************************
}
// THIS IS A BOGUS ABILITY
// only used for AI code to verify that a particular target was targeted by the shooter for a duel
static function X2AbilityTemplate CreateDuelInitiatedAbility()
{
	local X2AbilityTemplate				Template;
	local X2AbilityCost_ActionPoints			ActionPointCost;
	local X2Condition_UnitEffectsWithAbilitySource	EffectsWithSourceCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'MZDuelInitiated');

	// Icon Properties
	Template.IconImage = "img:///XPerkIconPack.UIPerk_psi_shot";
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 100;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	//must have initiated a duel with the target
	EffectsWithSourceCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	EffectsWithSourceCondition.AddRequireEffect('MZDuelTarget', 'AA_MissingRequiredEffect');
	Template.AbilityTargetConditions.AddItem(EffectsWithSourceCondition);

	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = None;

	return Template;
}


// Perk name:		Distraction II
// Perk effect:		Distraction grants +50% DR for one turn.
// Localized text:	"Distraction grants 50% DR for one turn. Passive"
// Config:			(AbilityName="Distraction_II")
static function X2AbilityTemplate Distraction_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Distraction_II', "img:///XPerkIconPack.UIPerk_psi_defense");
	Template.bUniqueSource = true;
	HidePerkIcon(Template);
	Template.PrerequisiteAbilities.AddItem('MZDuel');

	return Template;
}

// Perk name:		Distraction III
// Perk effect:		Distraction cooldown is reduced by 2 turns.
// Localized text:	"Distraction cooldown is reduced by 2 turns. Passive"
// Config:			(AbilityName="Distraction_III")
static function X2AbilityTemplate Distraction_III()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Distraction_III', "img:///XPerkIconPack.UIPerk_psi_cycle");
	Template.bUniqueSource = true;
	HidePerkIcon(Template);
	Template.PrerequisiteAbilities.AddItem('MZDuel');

	return Template;
}

// Perk name:		Leech
// Perk effect:		When an enemy is damaged by a shot from this unit, this unit heals for an amount equal to 25% of the damage dealt.
// Localized text:	"When an enemy is damaged by a shot from this unit, this unit heals for an amount equal to 25% of the damage dealt. Passive"
// Config:			(AbilityName="Leech")
static function X2AbilityTemplate Leech()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    EventListener;
	local X2Condition_UnitProperty          ShooterProperty;
	local X2Effect_SoulSteal                StealEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Leech');

	Template.bDisplayInUITooltip = true;
	Template.bDisplayInUITacticalText = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.IconImage = "img:///XPerkIconPack.UIPerk_medkit_rifle";
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	ShooterProperty = new class'X2Condition_UnitProperty';
	ShooterProperty.ExcludeAlive = false;
	ShooterProperty.ExcludeDead = true;
	ShooterProperty.ExcludeFriendlyToSource = false;
	ShooterProperty.ExcludeHostileToSource = true;
	ShooterProperty.ExcludeFullHealth = true;
	Template.AbilityShooterConditions.AddItem(ShooterProperty);

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventFn = LeechListener;
	EventListener.ListenerData.EventID = 'UnitTakeEffectDamage';
	EventListener.ListenerData.Filter = eFilter_None;
	Template.AbilityTriggers.AddItem(EventListener);

	StealEffect = new class'X2Effect_SoulSteal';
	StealEffect.UnitValueToRead = 'LeechAmount';
	Template.AddShooterEffect(StealEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;

	AddIconPassive(Template);

	return Template;
}





// Perk name:		Self Revive
// Perk effect:		Guaranteed bleedout once per turn and revive at the end of turn on bleeding out.
// Localized text:	"Guaranteed bleedout once per mission. When this unit is bleeding out at the beginning of your turn, this unit revives. Passive"
// Config:			(AbilityName="SelfRevive")
static function X2AbilityTemplate SelfRevive()
{
	local X2AbilityTemplate					Template;
	local X2Effect_GuranteedBleedout		LifeSupportEffect;

	`CREATE_X2ABILITY_TEMPLATE (Template, 'SelfRevive');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_medkit_circle";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
    Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bCrossClassEligible = false;
	Template.bDisplayInUITooltip = true;
	Template.bDisplayInUITacticalText = true;
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;

	LifeSupportEffect = new class'X2Effect_GuranteedBleedout';
	LifeSupportEffect.BuildPersistentEffect(1, true, false);
	LifeSupportEffect.SetDisplayInfo (ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage,,, Template.AbilitySourceName);
	Template.AddTargetEffect(LifeSupportEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.AdditionalAbilities.AddItem('SelfReviveOnBleedout');

	return Template;
}


static function X2AbilityTemplate SelfReviveOnBleedout()
{
	local X2AbilityTemplate					Template;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Condition_UnitValue 			UnitValueCondition;
	local X2Effect_RemoveEffects            RemoveEffects;
	local X2AbilityTrigger_EventListener    EventListener;
	local X2Condition_UnitEffects	EffectsWithSourceCondition;


	`CREATE_X2ABILITY_TEMPLATE (Template, 'SelfReviveOnBleedout');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_medkit_circle";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
    Template.AbilityTargetStyle = default.SelfTarget;
	Template.bCrossClassEligible = false;
	Template.bDisplayInUITooltip = true;
	Template.bDisplayInUITacticalText = true;
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeAlive = false;
	UnitPropertyCondition.ExcludeHostileToSource = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.IsBleedingOut = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'PlayerTurnBegun';
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	EventListener.ListenerData.Filter = eFilter_Player;
	Template.AbilityTriggers.AddItem(EventListener);

	UnitValueCondition = new class'X2Condition_UnitValue';
	UnitValueCondition.AddCheckValue('BleedingOutReadyToRevive', 1, eCheck_GreaterThanOrEqual);


	EffectsWithSourceCondition = new class'X2Condition_UnitEffects';
	EffectsWithSourceCondition.AddRequireEffect('BleedingOut', 'AA_MissingRequiredEffect');
	Template.AbilityTargetConditions.AddItem(EffectsWithSourceCondition);
	
	Template.AddTargetEffect(new class'X2Effect_SelfRevive');

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.BleedingOutName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.UnconsciousName);
	RemoveEffects.bDoNotVisualize = true;
	//RemoveEffects.TargetConditions.AddItem(UnitValueCondition);
	Template.AddTargetEffect(RemoveEffects);
	Template.bShowPostActivation = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.CustomFireAnim = 'HL_Revive';

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}


// Perk name:		Badass
// Perk effect:		75% Damage Reduction against first attack each turn..
// Localized text:	"75% Damage Reduction against first attack each turn. Passive"
// Config:			(AbilityName="Badass")
static function X2AbilityTemplate Badass()
{
	local X2AbilityTemplate					Template;
	local X2Effect_Badass					BadassEffect;

	`CREATE_X2ABILITY_TEMPLATE (Template, 'Badass');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_defense_blaze";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
    Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bDisplayInUITooltip = true;
	Template.bDisplayInUITacticalText = true;

    BadassEffect = new class'X2Effect_Badass';
    BadassEffect.DamageReductionMod = 0.75f;
	BadassEffect.NumOfShotsShruggedOff = 1;
    BadassEffect.BuildPersistentEffect(1, true, false);
    BadassEffect.SetDisplayInfo(ePerkBuff_Passive, "Badass", "Badass", Template.IconImage,,,Template.AbilitySourceName);

	Template.AddTargetEffect(BadassEffect);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bCrossClassEligible = true;


	return Template;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////// PALADIN
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Perk name:		Unnerve
// Perk effect:		Enemies targeted (not necessarily hit) by this unit's standard shots get the Weaken status effect, dealing -50% Damage for one turn.
// Localized text:	"Enemies targeted (not necessarily hit) by this unit's standard shots get the Weaken status effect, dealing -50% Damage for one turn. Passive"
// Config:			(AbilityName="Unnerve")

static function X2AbilityTemplate Unnerve()
{
	local X2AbilityTemplate			Template;
	local X2Condition_UnitProperty          ShooterProperty, MultiTargetProperty;
	local X2Effect_Persistent			Effect;
	local X2AbilityTrigger_EventListener    Listener;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Unnerve');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///XPerkIconPack.UIPerk_mind_shot_psi";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_Persistent';
	Effect.EffectName = 'UnnerveSourceEffect';
	Effect.BuildPersistentEffect(1, true);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	
	return Template;
}

static function X2AbilityTemplate Menacing()
{
	local X2AbilityTemplate			Template;
	local X2Condition_UnitProperty          ShooterProperty, MultiTargetProperty;
	local X2Effect_Menacing			Effect;
	local X2AbilityTrigger_EventListener    Listener;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Menacing');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///XPerkIconPack.UIPerk_mind_shot_psi";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_Menacing';
	Effect.EffectName = 'MenacingEffect';
	Effect.BuildPersistentEffect(1, true);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.AdditionalAbilities.AddItem('MenacingApply');
	return Template;
}

static function X2AbilityTemplate MenacingApply()
{

	local X2AbilityTemplate										Template;	
	local X2AbilityTrigger_EventListener						EventListener;
	local X2AbilityMultiTarget_Radius							RadiusMultiTarget;
	local X2Condition_UnitProperty								UnitPropertyCondition;
	local X2Effect_PersistentStatChange									DisorientedEffect;
	local X2Effect_Persistent									PanickedEffect;


	`CREATE_X2ABILITY_TEMPLATE(Template, 'MenacingApply');
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


	// This ability triggers after a Kill
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'MenacingTrigger';
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

	// Create the Disoriented effect on the targets
	DisorientedEffect = new class'X2Effect_PersistentStatChange';
	DisorientedEffect.EffectName = 'Menaced';
	DisorientedEffect.AddPersistentStatChange(eStat_Offense, -20);
	DisorientedEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	DisorientedEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
	DisorientedEffect.VisualizationFn = EffectFlyOver_Visualization;
    Template.AddMultiTargetEffect(DisorientedEffect);
	Template.AddTargetEffect(DisorientedEffect);

	HidePerkIcon(Template);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}


// Added to StandardShot in OnPostTemplatesCreated()
static function X2Effect_Empowered UnnerveEffect()
{
	local X2Effect_Empowered		Effect;
	local X2Condition_UnitEffectsOnSource   Condition;
	local X2Condition_UnitProperty          Condition_UnitProperty;

    // Only on non-robots
	Condition_UnitProperty = new class'X2Condition_UnitProperty';
	Condition_UnitProperty.ExcludeRobotic = true;
	Condition_UnitProperty.TreatMindControlledSquadmateAsHostile = true;
    
    // Effect that reduces damage
	Effect = new class'X2Effect_Empowered';
	Effect.EffectName = 'Unnerved';
	Effect.bUseMultiplier = true;
    Effect.BonusDamageMultiplier = -0.5;
	Effect.bApplyOnMiss = TRUE;
	Effect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	Effect.SetDisplayInfo(ePerkBuff_Penalty, "Unnerved", "This unit has been weakened this turn", "img:///XPerkIconPack.UIPerk_mind_shot_psi");
	Effect.VisualizationFn = EffectFlyOver_Visualization;
	Effect.TargetConditions.AddItem(Condition_UnitProperty);

    // Only apply if shooter has the required unnerve effect
	Condition = new class'X2Condition_UnitEffectsOnSource';
	Condition.AddRequireEffect('UnnerveSourceEffect', 'AA_MissingRequiredEffect');
	Effect.TargetConditions.AddItem(Condition);

	return Effect;
}


// Perk name:		Bastion
// Perk effect:		Effects from this unit's Regeneration Skill are applied to each ally within 5 tiles.
// Localized text:	"Each ally within 5 tile range of this Heal 1 HP per turn if injured. Passive"
// Config:			(AbilityName="XComGearsVanguard_Bastion")??

static function X2AbilityTemplate XComGearsVanguard_Bastion()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_Regeneration				RegenerationEffect;
	local X2AbilityMultiTarget_Radius		MultiTarget;
	local X2Condition_UnitProperty			UnitPropertyCondition;
	local X2Effect_BastionPostMissionHealing		BastionPostMissionHealing;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'XComGearsVanguard_Bastion');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_medkit_blossom";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = True;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.fTargetRadius = `UNITSTOMETERS(`TILESTOUNITS(5));
	MultiTarget.bUseWeaponRadius = false;
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.bAddPrimaryTargetAsMultiTarget = false;
	MultiTarget.bAllowDeadMultiTargetUnits = false;
	MultiTarget.bAllowSameTarget = false;
	MultiTarget.bExcludeSelfAsTargetIfWithinRadius = TRUE;
	Template.AbilityMultiTargetStyle = MultiTarget;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeUnrevealedAI = true;
	UnitPropertyCondition.ExcludeConcealed = false;
	UnitPropertyCondition.TreatMindControlledSquadmateAsHostile = true;
	UnitPropertyCondition.ExcludeAlive = false;
	UnitPropertyCondition.ExcludeHostileToSource = true;
	UnitPropertyCondition.RequireSquadmates = true;
	UnitPropertyCondition.ExcludePanicked = false;
	UnitPropertyCondition.ExcludeRobotic = true;
	UnitPropertyCondition.ExcludeStunned = false;
	UnitPropertyCondition.ExcludeNoCover = false;
	UnitPropertyCondition.FailOnNonUnits = true;
	UnitPropertyCondition.ExcludeCivilian = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);




	// Build the regeneration effect
	RegenerationEffect = new class'X2Effect_Regeneration'; // Maybe update to add IsEffectCurrentlyRelevant() to update based on distance between source and target unit like in X2Effect_Bastion
	RegenerationEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	RegenerationEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	RegenerationEffect.HealAmount = 1;
	RegenerationEffect.MaxHealAmount = 99999999;
	RegenerationEffect.HealthRegeneratedName = 'StasisVestHealthRegenerated';
	RegenerationEffect.VisualizationFn = EffectFlyOver_Visualization;
	Template.AddMultiTargetEffect(RegenerationEffect);

	PreventStackingEffects(Template);
	HidePerkIcon(Template);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

// Perk name:		Inspiration
// Perk effect:		Select a target ally in cover. Target gains +40% Dodge until start of next turn.
// Localized text:	"target ally in cover. Target gains +40% Dodge until start of next turn. Upgraded to +60% dodge if you have Inspiration II. Passive"
// Config:			(AbilityName="Inspiration")??

static function X2AbilityTemplate Inspiration_I()
{
	local X2Effect_PersistentStatChange Effect, EffectLvl2;
	local X2AbilityTemplate Template;
	local X2AbilityCooldown Cooldown;
	local X2Condition_SourceHasAbility AbilityCondition;
	local array<name> Abilities;

	// Create a persistent stat change effect that grants +50 Dodge
	Effect = new class'X2Effect_PersistentStatChange';
	Effect.EffectName = 'Inspiration';
	Effect.AddPersistentStatChange(eStat_Dodge, 40);

	// Prevent the effect from applying to a unit more than once
	Effect.DuplicateResponse = eDupe_Ignore;

	// The effect lasts until the beginning of the player's next turn
	Effect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);

	// Add a visualization that plays a flyover over the target unit
	Effect.VisualizationFn = EffectFlyOver_Visualization;

	// Create a targeted buff that affects allies
	Template = TargetedBuff('Inspiration_I', "img:///XPerkIconPack.UIPerk_defense_blaze", true, Effect, class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY, eCost_Free);


	// Add another effect with a condition for source to have the lvl2 ability as well
	EffectLvl2 = new class'X2Effect_PersistentStatChange';
	EffectLvl2.EffectName = 'InspirationLvl2';
	EffectLvl2.AddPersistentStatChange(eStat_Dodge, 20);

	// Prevent the effect from applying to a unit more than once
	EffectLvl2.DuplicateResponse = eDupe_Ignore;

	// The effect lasts until the beginning of the player's next turn
	EffectLvl2.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	
	AbilityCondition = new class'X2Condition_SourceHasAbility';
		Abilities.AddItem('Inspiration_II');
	AbilityCondition.Abilities = Abilities;
	EffectLvl2.TargetConditions.AddItem(AbilityCondition);
	Template.AddTargetEffect(EffectLvl2);

	AddCooldown(Template, 5);

	// By default, you can target a unit with an ability even if it already has the effect the
	// ability adds. This helper function prevents targetting units that already have the effect.
	PreventStackingEffects(Template);


	return Template;
}

// Perk name:		Inspiration II
// Perk effect:		.
// Localized text:	""
// Config:			(AbilityName="Inspiration_II")
static function X2AbilityTemplate Inspiration_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Inspiration_II', "img:///XPerkIconPack.UIPerk_defense_blossom");
	Template.bUniqueSource = true;

	Template.PrerequisiteAbilities.AddItem('Inspiration_I');
	HidePerkIcon(Template);
	return Template;
}



// Perk name:		Rally
// Perk effect:		Allies within 8 meters gain 25% Lifesteal for this turn.
// Localized text:	"Activate to grant Allies within 8 meters gain 25% Lifesteal for this turn. 5 turn cooldown"
// Config:			(AbilityName="Rally_I")??
static function X2AbilityTemplate Rally_I()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    EventListener;
	local X2Condition_UnitProperty          MultiTargetProperty;
	local X2Condition_UnitEffectsWithAbilitySource	Condition;
	local X2Effect_SoulSteal                StealEffect;
	local X2AbilityMultiTarget_AllAllies		MultiTarget;
	local X2Effect_Leech				LeechAura;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Rally_I');

	//Template.AbilitySourceName = default.OfficerSourceName;
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = 317;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AddShooterEffectExclusions();

	Template.AbilityCosts.AddItem(ActionPointCost(eCost_Single));
	AddCooldown(Template, 5);

	MultiTarget = new class'X2AbilityMultiTarget_AllAllies';
	// MultiTarget.bUseWeaponRadius = false;
	// MultiTarget.bIgnoreBlockingCover = true;
	// MultiTarget.bAddPrimaryTargetAsMultiTarget = false;
	// MultiTarget.bAllowDeadMultiTargetUnits = false;
	// MultiTarget.bAllowSameTarget = false;
	// MultiTarget.bExcludeSelfAsTargetIfWithinRadius = TRUE;
	Template.AbilityMultiTargetStyle = MultiTarget;

	MultiTargetProperty = new class'X2Condition_UnitProperty';
	MultiTargetProperty.ExcludeAlive = false;
    MultiTargetProperty.ExcludeDead = true;
    MultiTargetProperty.ExcludeHostileToSource = true;
    MultiTargetProperty.ExcludeFriendlyToSource = false;
    MultiTargetProperty.RequireSquadmates = true;
    MultiTargetProperty.ExcludePanicked = true;
	MultiTargetProperty.ExcludeRobotic = true;
	MultiTargetProperty.ExcludeStunned = true;
	MultiTargetProperty.ExcludeCivilian = true;
	Template.AbilityMultiTargetConditions.AddItem(MultiTargetProperty);


	Template.IconImage = "img:///XPerkIconPack.UIPerk_enemy_crit_chevron";

	LeechAura = new class'X2Effect_Leech';
	LeechAura.EffectName = 'LeechAura_I';
	LeechAura.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	LeechAura.SetDisplayInfo (ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage,,, Template.AbilitySourceName); // adjust?
	LeechAura.DuplicateResponse = eDupe_Refresh;
	//LeechAura.TargetConditions.AddItem(MultiTargetProperty); // prevent exclusion on effect apply instead of in targeting
	LeechAura.VisualizationFn = EffectFlyOver_Visualization;
	Condition = new class'X2Condition_UnitEffectsWithAbilitySource';
	Condition.AddExcludeEffect(LeechAura.EffectName, 'AA_UnitIsImmune');
	LeechAura.TargetConditions.AddItem(Condition);

	Template.AddMultiTargetEffect(LeechAura);



	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;

	return Template;
}



// Perk name:		Rally II
// Perk effect:		.
// Localized text:	"Increased Rally lifesteal aura to 40%"
// Config:			(AbilityName="Rally_II")
static function X2AbilityTemplate Rally_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Rally_II', "img:///XPerkIconPack.UIPerk_enemy_crit_chevron_x2");
	Template.bUniqueSource = true;

	Template.PrerequisiteAbilities.AddItem('Rally_I');
	HidePerkIcon(Template);
	return Template;
}

// Perk name:		Rally III
// Perk effect:		.
// Localized text:	"Increased Rally lifesteal effect to end of next turn"
// Config:			(AbilityName="Rally_III")
static function X2AbilityTemplate Rally_III()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    EventListener;
	local X2Condition_UnitProperty          MultiTargetProperty;
	local X2Condition_UnitEffectsWithAbilitySource	Condition;
	local X2Effect_SoulSteal                StealEffect;
	local X2AbilityMultiTarget_AllAllies		MultiTarget;
	local X2Effect_Leech				LeechAura;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Rally_III');

	//Template.AbilitySourceName = default.OfficerSourceName;
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = 317;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AddShooterEffectExclusions();

	Template.AbilityCosts.AddItem(ActionPointCost(eCost_Single));
	AddCooldown(Template, 5);

	MultiTarget = new class'X2AbilityMultiTarget_AllAllies';
	// MultiTarget.fTargetRadius = `UNITSTOMETERS(`TILESTOUNITS(8));
	// MultiTarget.bUseWeaponRadius = false;
	// MultiTarget.bIgnoreBlockingCover = true;
	// MultiTarget.bAddPrimaryTargetAsMultiTarget = false;
	// MultiTarget.bAllowDeadMultiTargetUnits = false;
	// MultiTarget.bAllowSameTarget = false;
	// MultiTarget.bExcludeSelfAsTargetIfWithinRadius = TRUE;
	Template.AbilityMultiTargetStyle = MultiTarget;

	MultiTargetProperty = new class'X2Condition_UnitProperty';
	MultiTargetProperty.ExcludeAlive = false;
    MultiTargetProperty.ExcludeDead = true;
    MultiTargetProperty.ExcludeHostileToSource = true;
    MultiTargetProperty.ExcludeFriendlyToSource = false;
    MultiTargetProperty.RequireSquadmates = true;
    MultiTargetProperty.ExcludePanicked = true;
	MultiTargetProperty.ExcludeRobotic = true;
	MultiTargetProperty.ExcludeStunned = true;
	MultiTargetProperty.ExcludeCivilian = true;
	Template.AbilityMultiTargetConditions.AddItem(MultiTargetProperty);

	Template.IconImage = "img:///XPerkIconPack.UIPerk_enemy_crit_chevron_x3";

	LeechAura = new class'X2Effect_Leech';
	LeechAura.EffectName = 'LeechAura_III';
	LeechAura.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnEnd);
	LeechAura.SetDisplayInfo (ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage,,, Template.AbilitySourceName); // adjust?
	LeechAura.DuplicateResponse = eDupe_Refresh;
	LeechAura.VisualizationFn = EffectFlyOver_Visualization;
	//LeechAura.TargetConditions.AddItem(MultiTargetProperty); // prevent exclusion on effect apply instead of in targeting

	Condition = new class'X2Condition_UnitEffectsWithAbilitySource';
	Condition.AddExcludeEffect(LeechAura.EffectName, 'AA_UnitIsImmune');
	LeechAura.TargetConditions.AddItem(Condition);

	Template.AddMultiTargetEffect(LeechAura);



	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;

	Template.OverrideAbilities.AddItem('Rally_I');
	Template.PrerequisiteAbilities.AddItem('Rally_I');

	return Template;
}



// Perk name:		Stand Together
// Perk effect:		Impaired allies within 10 meters are cleansed and get 50% Damage Reduction until the start of your next turn.
// Localized text:	"Impaired allies within 10 meters are cleansed and get 50% Damage Reduction until the start of your next turn."
// Config:			(AbilityName="StandTogether")
static function X2AbilityTemplate StandTogether()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityMultiTarget_Radius		MultiTarget;
	local X2Effect_RemoveEffects            RemoveEffects;
	local X2Effect_DamageReduction			DamageReductionEffect;
	local X2Condition_UnitEffectsExtended	EffectsWithSourceCondition;
	local X2Condition_UnitProperty			MultiTargetProperty;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'StandTogether');

	//Template.AbilitySourceName = default.OfficerSourceName;
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = 317;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AddShooterEffectExclusions();

	Template.AbilityCosts.AddItem(ActionPointCost(eCost_SingleConsumeAll));
	AddCooldown(Template, 8);

	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.fTargetRadius = `UNITSTOMETERS(`TILESTOUNITS(10));
	MultiTarget.bUseWeaponRadius = false;
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.bAddPrimaryTargetAsMultiTarget = false;
	MultiTarget.bAllowDeadMultiTargetUnits = false;
	MultiTarget.bAllowSameTarget = false;
	MultiTarget.bExcludeSelfAsTargetIfWithinRadius = FALSE;
	Template.AbilityMultiTargetStyle = MultiTarget;

	// Add multi target conditions
	MultiTargetProperty = new class'X2Condition_UnitProperty';
	MultiTargetProperty.ExcludeAlive = false;
    MultiTargetProperty.ExcludeDead = false;
    MultiTargetProperty.ExcludeHostileToSource = true;
    MultiTargetProperty.ExcludeFriendlyToSource = false;
    MultiTargetProperty.RequireSquadmates = true;
    MultiTargetProperty.ExcludePanicked = false;
	MultiTargetProperty.ExcludeRobotic = true;
	MultiTargetProperty.ExcludeStunned = false;
	MultiTargetProperty.ExcludeCivilian = true;
	MultiTargetProperty.FailOnNonUnits = TRUE;
	Template.AbilityMultiTargetConditions.AddItem(MultiTargetProperty);

	Template.IconImage = "img:///XPerkIconPack.UIPerk_shield_circle";

	// EffectsWithSourceCondition = new class'X2Condition_UnitEffectsExtended';
	// EffectsWithSourceCondition.AddRequireEffect('BleedingOut', 'AA_MissingRequiredEffect');
	// EffectsWithSourceCondition.AddRequireEffect('Unconscious', 'AA_MissingRequiredEffect');
	// Template.AbilityMultiTargetConditions.AddItem(EffectsWithSourceCondition);

	// // Needed to fix visualization with stunned/unconscious units
	// Template.AddMultiTargetEffect(new class'X2Effect_SelfRevive');


	// RemoveEffects = new class'X2Effect_RemoveEffects';
	// RemoveEffects.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.BleedingOutName);
	// RemoveEffects.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.UnconsciousName);
	// RemoveEffects.bDoNotVisualize = true;
	// //RemoveEffects.TargetConditions.AddItem(UnitValueCondition);
	// Template.AddMultiTargetEffect(RemoveEffects);


	//Clearing all common status effects as well?
	Template.AddMultiTargetEffect(class'X2Ability_SpecialistAbilitySet'.static.RemoveAdditionalEffectsForRevivalProtocolAndRestorativeMist());
	Template.AddMultiTargetEffect(new class'X2Effect_RestoreActionPoints');      //  put the unit back to full actions


	DamageReductionEffect = new class'X2Effect_DamageReduction';
	DamageReductionEffect.DamageReduction = 0.5;
	DamageReductionEffect.bAbsoluteVal = false;
	DamageReductionEffect.EffectName = 'StandTogether';
	DamageReductionEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	DamageReductionEffect.SetDisplayInfo(ePerkBuff_Bonus, "Stand Together", "Stand Together", Template.IconImage,,,Template.AbilitySourceName);
	DamageReductionEffect.DuplicateResponse = eDupe_Ignore;
	Template.AddMultiTargetEffect(DamageReductionEffect);


	Template.bShowPostActivation = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.CustomFireAnim = 'HL_SignalYellA';

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////// SHOCK TROOPER
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Perk name:		Intimidate_I
// Perk effect:		Target unit is knocked back and suppressed.
// Localized text:	""
// Config:			(AbilityName="Intimidate_I")
static function X2AbilityTemplate Intimidate_I()
{
	local X2Effect_Knockback	KnockbackEffect;
	local X2AbilityTemplate                 Template;
	local X2Condition_UnitType				UnitGroupCondition;
	local X2Condition_UnitProperty			Condition_UnitProperty;
	local X2Effect_Suppression              SuppressionEffect;
	local X2Effect_PersistentStatChange		IntimidateEffect;

	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 2;
	
	Template = TargetedDebuff('Intimidate_I', "img:///XPerkIconPack.UIPerk_enemy_psi_chevron", , KnockbackEffect, ,  eCost_SingleConsumeAll);



	AddCooldown(Template, 5);
	PreventStackingEffects(Template);

	//	Always break concealment when activating this ability
	Template.AddShooterEffect(new class'X2Effect_BreakUnitConcealment');
	Template.ConcealmentRule = eConceal_Never;

	IntimidateEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect(true,,);

	UnitGroupCondition = new class'X2Condition_UnitType';
	UnitGroupCondition.ExcludeTypes.AddItem('Sectopod');
	UnitGroupCondition.ExcludeTypes.AddItem('AdventPsiWitch');
	UnitGroupCondition.ExcludeTypes.AddItem('Gatekeeper');
	IntimidateEffect.TargetConditions.AddItem(UnitGroupCondition);

	Condition_UnitProperty = new class'X2Condition_UnitProperty';
	Condition_UnitProperty.ExcludeOrganic = false;
	Condition_UnitProperty.ExcludeRobotic = true;
	IntimidateEffect.TargetConditions.AddItem(Condition_UnitProperty);

	Template.AddTargetEffect(IntimidateEffect);


/* 	SuppressionEffect = new class'X2Effect_Suppression';
	SuppressionEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	SuppressionEffect.bRemoveWhenTargetDies = true;
	SuppressionEffect.bRemoveWhenSourceDamaged = false;
	SuppressionEffect.bBringRemoveVisualizationForward = true;
	SuppressionEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.LocFriendlyName, Template.IconImage);
	Template.AddTargetEffect(SuppressionEffect);
	 */

	Template.CustomFireAnim = 'HL_Psi_MindControl';
	Template.ActivationSpeech = 'Insanity';

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

// Perk name:		Intimidate_II
// Perk effect:		Target units in a 5 tile radius are knocked back and suppressed.
// Localized text:	""
// Config:			(AbilityName="Intimidate_II")
static function X2AbilityTemplate Intimidate_II()
{
	local X2Effect_Singularity_LEBPsi				KnockbackEffect;
	local X2AbilityTemplate                 Template;
	local X2AbilityMultiTarget_Radius			TargetStyle;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Effect_Suppression              SuppressionEffect;
	local X2Condition_UnitType				UnitGroupCondition;
	local X2AbilityToHitCalc_StandardAim		StandardAim;
	local X2Effect_DamageReduction			DamageReductionEffect;
	local X2AbilityTarget_Cursor			CursorTarget;
	local X2Effect_PersistentStatChange		IntimidateEffect;


	
	Template = TargetedDebuff('Intimidate_II', "img:///XPerkIconPack.UIPerk_enemy_psi_chevron_x2", , , ,  eCost_SingleConsumeAll);

	TargetStyle = new class'X2AbilityMultiTarget_Radius';
	TargetStyle.fTargetRadius = 8;
	TargetStyle.bIgnoreBlockingCover = true;
	TargetStyle.bExcludeSelfAsTargetIfWithinRadius = true;
	Template.AbilityMultiTargetStyle = TargetStyle;

	Template.AbilityToHitCalc = default.DeadEye;

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToSquadsightRange = true;
	CursorTarget.FixedAbilityRange =15;
	Template.AbilityTargetStyle = CursorTarget;
	Template.TargetingMethod = class'X2TargetingMethod_VoidRift';

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeRobotic = false;
	UnitPropertyCondition.ExcludeAlien = false;
	UnitPropertyCondition.ExcludeInStasis = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.FailOnNonUnits = true;
	UnitPropertyCondition.ExcludeTurret = true;
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);



	KnockbackEffect = new class'X2Effect_Singularity_LEBPsi';
	//KnockbackEffect.KnockbackDistance = 2;
	Template.AddMultiTargetEffect(KnockbackEffect);

	IntimidateEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect(true,,);
	Template.AddMultiTargetEffect(IntimidateEffect);


/* 	SuppressionEffect = new class'X2Effect_Suppression';
	SuppressionEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	SuppressionEffect.bRemoveWhenTargetDies = true;
	SuppressionEffect.bRemoveWhenSourceDamaged = false;
	SuppressionEffect.bBringRemoveVisualizationForward = true;
	SuppressionEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.LocFriendlyName, Template.IconImage);
	Template.AddMultiTargetEffect(SuppressionEffect); */
	
	// Maybe add target exclusions for robotics and other immune units here later
	DamageReductionEffect = new class'X2Effect_DamageReduction';
	DamageReductionEffect.DamageReduction = -0.2;
	DamageReductionEffect.bAbsoluteVal = false;
	DamageReductionEffect.EffectName = 'Intimidate';
	DamageReductionEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	DamageReductionEffect.SetDisplayInfo(ePerkBuff_Penalty, "Intimidated", "Intimidated and taking more damage", Template.IconImage,,,Template.AbilitySourceName);
	DamageReductionEffect.DuplicateResponse = eDupe_Ignore;
	DamageReductionEffect.VisualizationFn = EffectFlyOver_Visualization;
	Template.AddMultiTargetEffect(DamageReductionEffect);


	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	Template.CustomFireAnim = 'HL_Psi_MindControl';
	Template.CinescriptCameraType = "Psionic_FireAtUnit";
	Template.ActivationSpeech = 'Insanity';

	//	Always break concealment when activating this ability
	Template.AddShooterEffect(new class'X2Effect_BreakUnitConcealment');
	Template.ConcealmentRule = eConceal_Never;

	AddCooldown(Template, 5);
	PreventStackingEffects(Template);

	//Template.OverrideAbilities.AddItem('Intimidate_I');
	Template.PrerequisiteAbilities.AddItem('Intimidate_I');

	return Template;
}

// Perk name:		Intimidate_III
// Perk effect:		Intimidated units also take 40% increased damage this turn.
// Localized text:	""
// Config:			(AbilityName="Intimidate_III")
static function X2AbilityTemplate Intimidate_III()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Intimidate_III', "img:///XPerkIconPack.UIPerk_enemy_psi_chevron_x3");
	Template.bUniqueSource = true;

	Template.PrerequisiteAbilities.AddItem('Intimidate_II');
	HidePerkIcon(Template);
	return Template;
}

// Perk name:		Breach
// Perk effect:		All enemies within 5 meters gain the Breached status effect. Allies who kill Breached enemies recover action points (aka serial).
// Localized text:	"All enemies within 5 meters gain the Breached status effect. Allies who kill Breached enemies recover action points (aka serial)"
// Config:			(AbilityName="Breach")
static function X2AbilityTemplate Breach()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityMultiTarget_Radius		MultiTarget;
	local X2Effect_BreachTarget			BreachTargetEffect;
	local X2Condition_UnitEffectsExtended	EffectsWithSourceCondition;
	local X2Condition_UnitProperty			MultiTargetProperty;
	local X2Condition_UnitProperty          UnitPropertyCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Breach');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_psi_blaze";

	//Template.AbilitySourceName = default.OfficerSourceName;
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = 317;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AddShooterEffectExclusions();

	Template.AbilityCosts.AddItem(ActionPointCost(eCost_SingleConsumeAll));
	AddCooldown(Template, 8);

	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.fTargetRadius = `UNITSTOMETERS(`TILESTOUNITS(10));
	MultiTarget.bUseWeaponRadius = false;
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.bAddPrimaryTargetAsMultiTarget = false;
	MultiTarget.bAllowDeadMultiTargetUnits = false;
	MultiTarget.bAllowSameTarget = false;
	MultiTarget.bExcludeSelfAsTargetIfWithinRadius = TRUE;
	Template.AbilityMultiTargetStyle = MultiTarget;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeRobotic = false;
	UnitPropertyCondition.ExcludeAlien = false;
	UnitPropertyCondition.ExcludeInStasis = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.FailOnNonUnits = true;
	UnitPropertyCondition.ExcludeTurret = false;
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	BreachTargetEffect = new class'X2Effect_BreachTarget';
	BreachTargetEffect.EffectName = 'BreachTarget';
	BreachTargetEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	BreachTargetEffect.SetDisplayInfo(ePerkBuff_Penalty, "Breached", "Breached", Template.IconImage,,,Template.AbilitySourceName);
	BreachTargetEffect.DuplicateResponse = eDupe_Ignore;
	BreachTargetEffect.VisualizationFn = EffectFlyOver_Visualization;
	Template.AddMultiTargetEffect(BreachTargetEffect);


	//	Always break concealment when activating this ability
	Template.AddShooterEffect(new class'X2Effect_BreakUnitConcealment');
	Template.ConcealmentRule = eConceal_Never;

	Template.AbilityConfirmSound = "Battlelord_Activate";
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.ActivationSpeech = 'KillZone';
	Template.CustomFireAnim = 'HL_SignalYellA';
	Template.CinescriptCameraType = "Psionic_FireAtLocation";

	Template.AdditionalAbilities.AddItem('BreachPassive');

	return Template;
}

static function X2AbilityTemplate Breach_Passive()
{
	local X2AbilityTemplate Template;
	local X2Effect_Persistent Effect;

	Effect = new class'X2Effect_Persistent';
	Effect.EffectName = 'BreachSource';
	Effect.DuplicateResponse = eDupe_Allow;

	Template = SquadPassive('BreachPassive', "img:///XPerkIconPack.UIPerk_psi_cycle", false, Effect);

	HidePerkIcon(Template);

	return Template;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////// ASSAULT
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Perk name:		Executioner
// Perk effect:		Increased damage (30%) to targets at or below 50% health.
// Localized text:	"Increased damage (30%) to targets at or below 50% health. Passive"
// Config:			(AbilityName="Executioner")
static function X2AbilityTemplate Executioner()
{
	local X2AbilityTemplate					Template;
	local X2Effect_Executioner			ExecutionerEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Executioner');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_enemy_shot_crit";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bIsPassive = true;

	ExecutionerEffect = new class 'X2Effect_Executioner';
	ExecutionerEffect.BuildPersistentEffect (1, true, false);
	ExecutionerEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect (ExecutionerEffect);
	Template.bCrossClassEligible = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;		
}

// Perk name:		Expertise
// Perk effect:		When within the Effective Range of the equipped primary weapon, this unit gets +25% Critical Hit Chance on primary weapon attacks.
// Localized text:	"When within the Effective Range of the equipped primary weapon, this unit gets +25% Critical Hit Chance on primary weapon attacks. Passive"
// Config:			(AbilityName="Expertise")
static function X2AbilityTemplate Expertise()
{
	local X2AbilityTemplate						Template;
	local X2Effect_Expertise				CritModifier;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Expertise');
	Template.IconImage = "img:///XPerkIconPack.UIPerk_star_crit";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bIsPassive = true;
	
	CritModifier = new class 'X2Effect_Expertise';
	CritModifier.BuildPersistentEffect (1, true, false);
	CritModifier.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect (CritModifier);
	Template.bCrossClassEligible = false;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

// Perk name:		Hemorrhage
// Perk effect:		When this unit gets a Critical Hit on an enemy, that enemy receives the Bleed status effect.
// Localized text:	When this unit gets a Critical Hit on an enemy, that enemy receives the Bleed status effect."
// Config:			(AbilityName="Hemorrhage", ApplyToWeaponSlot=eInvSlot_PrimaryWeapon)
static function X2AbilityTemplate Hemorrhage()
{
	local X2AbilityTemplate			Template;
	local X2Condition_UnitProperty          ShooterProperty, MultiTargetProperty;
	local X2Effect_Persistent			Effect;
	local X2AbilityTrigger_EventListener    Listener;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Hemorrhage');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///XPerkIconPack.UIPerk_rifle_adrenaline";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	
	return Template;
}


// Added to StandardShot in OnPostTemplatesCreated()
static function X2Effect_Persistent BleedingEffect()
{
	local X2Effect_Persistent		Effect;
	local X2Condition_UnitEffectsOnSource   Condition;
	local X2Condition_UnitProperty          Condition_UnitProperty;
	local X2Condition_AbilityProperty		AbilityCondition;
    
    // Effect that reduces damage
	Effect = class'X2StatusEffects'.static.CreateBleedingStatusEffect(3, 2);
	Effect.bApplyonMiss = false;
	Effect.DuplicateResponse = eDupe_Allow;

	AbilityCondition = new class'X2Condition_AbilityProperty';
	AbilityCondition.OwnerHasSoldierAbilities.AddItem('Hemorrhage');
	Effect.TargetConditions.AddItem(AbilityCondition);

	return Effect;
}

// Perk name:		Rage Shot I
// Perk effect:		Shoot with a Damage bonus. The Damage bonus is equal to 50% of your missing health (to a max of 6?).
// Localized text:	"Shoot with a Damage bonus. The Damage bonus is equal to 50% of your missing health (to a max of 6?). 5 turn cooldown"
// Config:			(AbilityName="RageShot_I", ApplyToWeaponSlot=eInvSlot_PrimaryWeapon)
static function X2AbilityTemplate RageShot_I()
{
	local X2AbilityTemplate Template;
	local X2Condition_UnitStatCheck	Condition;

	// Create the template using a helper function
	Template = Attack('RageShot_I', "img:///XPerkIconPack.UIPerk_fire_chevron", true, none, class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY, eCost_WeaponConsumeAll, 1);

	// Add a condition for the shooter missing HP
	Condition = new class'X2Condition_UnitStatCheck';
	Condition.AddCheckStat(eStat_HP, 100, eCheck_LessThan,,, true);
    Template.AbilityShooterConditions.AddItem(Condition);

	// Add a cooldown. The internal cooldown numbers include the turn the cooldown is applied, so
	// this is actually a 5 turn cooldown.
	AddCooldown(Template, 6);

	// Add a secondary ability to provide bonuses on the shot
	AddSecondaryAbility(Template, RageShotBonus());

	return Template;
}

// This is part of the Rage Shot effect, above
static function X2AbilityTemplate RageShotBonus()
{
    local X2AbilityTemplate 			Template;
    local X2Effect_RageShotDamageBonus	Effect;

    `CREATE_X2ABILITY_TEMPLATE (Template, 'RageShotBonus');
    Template.IconImage = "img:///XPerkIconPack.UIPerk_fire";
    Template.AbilitySourceName = 'eAbilitySource_Perk';
    Template.eAbilityIconBehaviorHUD = 2;
    Template.Hostility = 2;
    Template.AbilityToHitCalc = default.DeadEye;
    Template.AbilityTargetStyle = default.SelfTarget;
    Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

    Effect = new class'X2Effect_RageShotDamageBonus';
	Effect.MaxDamageBonus = 6;
    Effect.BuildPersistentEffect(1, true, false, false);
    Effect.SetDisplayInfo(0, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false,, Template.AbilitySourceName);
    Template.AddTargetEffect(Effect);
    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
    return Template;

	return Template;
}


// Perk name:		RageShot_II
// Perk effect:		Increase rage shot bonus damage to 100% of missing health.
// Localized text:	Increase rage shot bonus damage to 100% of missing health. Passive. Requires PowerShot_I
// Config:			(AbilityName="RageShot_II")
static function X2AbilityTemplate RageShot_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('RageShot_II', "img:///XPerkIconPack.UIPerk_fire_chevron_x2");
	Template.bUniqueSource = true;

	Template.PrerequisiteAbilities.AddItem('RageShot_I');
	HidePerkIcon(Template);
	return Template;
}

// Perk name:		RageShot_III
// Perk effect:		Increase rage shot bonus damage to 150% of missing health.
// Localized text:	Increase rage shot bonus damage to 150% of missing health. Passive. Requires RageShot_I and RageShot_II
// Config:			(AbilityName="RageShot_III")
static function X2AbilityTemplate RageShot_III()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('RageShot_III', "img:///XPerkIconPack.UIPerk_fire_chevron_x3");
	Template.bUniqueSource = true;

	Template.PrerequisiteAbilities.AddItem('RageShot_I');
	Template.PrerequisiteAbilities.AddItem('RageShot_II');
	HidePerkIcon(Template);
	return Template;
}

// Perk name:		Avenger
// Perk effect:		When an ally takes damage, this unit gets +25% Damage for this turn, to a maximum of 4 stacks. When an ally is downed, this unit gets +1 Action. When an ally dies, this unit gets 3 Actions.
// Localized text:	When an ally takes damage, this unit gets +25% Damage for this turn, to a maximum of 4 stacks. When an ally is downed, this unit gets +1 Action. When an ally dies, this unit gets 3 Actions.
// Config:			(AbilityName="Avenger")

static function X2AbilityTemplate Avenger()
{
	local X2AbilityTemplate			Template;
	local X2Condition_UnitProperty          ShooterProperty, MultiTargetProperty;
	local X2Effect_Vengeance                VengeanceEffect;
	local X2Effect_AvengerBonuses			Deflect;
	local X2Effect_Persistent				ShotNonTurnEndingEffect;
	local X2AbilityTrigger_EventListener    Listener;
	local X2Condition_UnitValue				UnitValueCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Avenger');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///XPerkIconPack.UIPerk_stealth_cycle";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Deflect = new class'X2Effect_AvengerBonuses';
	Deflect.BuildPersistentEffect(1, true);
	Deflect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(Deflect);


	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static function EventListenerReturn LeechListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local XComGameState_Unit AbilityOwnerUnit, TargetUnit, SourceUnit;
	local int DamageDealt, DmgIdx;
	local float StolenHP;
	local XComGameState_Ability AbilityState, InputAbilityState;
	local X2TacticalGameRuleset Ruleset;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	AbilityState = XComGameState_Ability(CallbackData);
	InputAbilityState = XComGameState_Ability(GameState.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	if (AbilityContext != none && AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
	{
		Ruleset = `TACTICALRULES;
		TargetUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
		SourceUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

		if (TargetUnit != none)
		{
			if(SourceUnit.ObjectID == AbilityState.OwnerStateObject.ObjectID)
			{
				if(TRUE || InputAbilityState.SourceWeapon.ObjectID == AbilityState.SourceWeapon.ObjectID) // Check if we need weapon specific check here
				{
					for (DmgIdx = 0; DmgIdx < TargetUnit.DamageResults.Length; ++DmgIdx)
					{
						if (TargetUnit.DamageResults[DmgIdx].Context == AbilityContext)
						{
							DamageDealt += TargetUnit.DamageResults[DmgIdx].DamageAmount;
						}
					}
					if (DamageDealt > 0)
					{
						StolenHP = int(float(DamageDealt) * 0.25);
						if (StolenHP > 0)
						{
							NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Chosen Soul Steal Amount");
							AbilityOwnerUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityState.OwnerStateObject.ObjectID));
							AbilityOwnerUnit.SetUnitFloatValue('LeechAmount', StolenHP);
							Ruleset.SubmitGameState(NewGameState);

							AbilityState.AbilityTriggerAgainstSingleTarget(AbilityState.OwnerStateObject, false);

						}
					}
				}
			}
		}
	}

	return ELR_NoInterrupt;
}


static simulated function SelfRevival_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local X2AbilityTemplate             AbilityTemplate, ThreatTemplate;
	local StateObjectReference          InteractingUnitRef;
	local XComGameState_Item			GremlinItem;
	local XComGameState_Unit			TargetUnitState;
	local XComGameState_Unit			AttachedUnitState;
	local XComGameState_Unit			GremlinUnitState, ActivatingUnitState;
	local array<PathPoint> Path;
	local TTile                         TargetTile;
	local TTile							StartTile;

	local VisualizationActionMetadata        EmptyTrack;
	local VisualizationActionMetadata        ActionMetadata;
	local X2Action_WaitForAbilityEffect DelayAction;
	local X2Action_AbilityPerkStart		PerkStartAction;
	local X2Action_CameraLookAt			CameraAction;

	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local int EffectIndex;
	local PathingInputData              PathData;
	local PathingResultData				ResultData;
	local X2Action_PlayAnimation		PlayAnimation;

	local X2VisualizerInterface TargetVisualizerInterface;
	local string FlyOverText, FlyOverIcon;
	local X2AbilityTag AbilityTag;

	local X2Action_CameraLookAt			TargetCameraAction;
	local Actor TargetVisualizer;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	TargetUnitState = XComGameState_Unit( VisualizeGameState.GetGameStateForObjectID( Context.InputContext.PrimaryTarget.ObjectID ) );

	GremlinItem = XComGameState_Item( History.GetGameStateForObjectID( Context.InputContext.ItemObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1 ) );
	GremlinUnitState = XComGameState_Unit( History.GetGameStateForObjectID( GremlinItem.CosmeticUnitRef.ObjectID ) );
	AttachedUnitState = XComGameState_Unit( History.GetGameStateForObjectID( GremlinItem.AttachedUnitRef.ObjectID ) );
	ActivatingUnitState = XComGameState_Unit( History.GetGameStateForObjectID( Context.InputContext.SourceObject.ObjectID) );

	//****************************************************************************************

	//Configure the visualization track for the target
	//****************************************************************************************
	InteractingUnitRef = Context.InputContext.PrimaryTarget;
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = TargetVisualizer;

	DelayAction = X2Action_WaitForAbilityEffect( class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree( ActionMetadata, Context ) );
	//DelayAction.ChangeTimeoutLength( default.GREMLIN_ARRIVAL_TIMEOUT );       //  give the gremlin plenty of time to show up
	
	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityTargetEffects[ EffectIndex ].AddX2ActionsForVisualization( VisualizeGameState, ActionMetadata, Context.FindTargetEffectApplyResult( AbilityTemplate.AbilityTargetEffects[ EffectIndex ] ) );
	}
					
	if (AbilityTemplate.bShowActivation)
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));

		FlyOverText = AbilityTemplate.LocFlyOverText;
		FlyOverIcon = AbilityTemplate.IconImage;
		
		AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
		AbilityTag.ParseObj = History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID);
		FlyOverText = `XEXPAND.ExpandString(FlyOverText);
		AbilityTag.ParseObj = none;

		SoundAndFlyOver.SetSoundAndFlyOverParameters(none, FlyOverText, '', eColor_Good, FlyOverIcon, 1.5f, true);
	}

	TargetVisualizerInterface = X2VisualizerInterface(ActionMetadata.VisualizeActor);
	if (TargetVisualizerInterface != none)
	{
		//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
		TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
	}

	if( TargetCameraAction != none )
	{
		TargetCameraAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		TargetCameraAction.CameraTag = 'TargetFocusCamera';
		TargetCameraAction.bRemoveTaggedCamera = true;
	}

	//****************************************************************************************
}