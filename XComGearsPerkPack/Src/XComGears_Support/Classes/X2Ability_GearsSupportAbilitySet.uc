class X2Ability_GearsSupportAbilitySet extends XMBAbility config(GearsSupportAbilitySet);


/*
Squaddie Level skills:
    Adrenaline (grant sheild to all allies on kill)
    Intrusion Protocol (Hacking)
    MediEvac (post mission healing for all soldiers)

Surgeon Tree:
    Recovery Patch I, II, III (Heal targeted ally and grant damage reduction for increasing amounts each turn)
    Revival Protocol I, II, III (Revive and heal ally for increasing amounts and grant AP)

Combat Medic:
    Enhanced adrenaline I, II (Increased shield HP from adrenaline and duration)
    Group therapy I, II, III (Shield/Heal all allies) ala restoration/shield protocol
    Reactive therapy (Ally killed resets cooldown/grants charge for group therapy)

Paragon:
    Empower I, II, II (grant action point and damage boost to 1 ally)
    Teamwork I, II (targetted ally gets APs when killing a target)
    Lock and Load (Each ally reloads and gets damage boost for 1 turn)

Strategist:
    PowerShot I, II, III (Special shot with increased damage and progressively decreasing cooldown)
    Weak Point (Kill boosts allies crit chance for 2 turns) ala old adrenaline/combat rush
    Holotargeting (Base game skill)
    Surge (Reset all cooldown for targeted ally including self) ala manual override)
 */
var localized string SerialChargeBasedDescription;

var config int 			RECOVERY_PATCH_II_BONUS;
var config int 			RECOVERY_PATCH_III_BONUS;
var config array<name>	RECOVERY_PATCH_ITEMS;

var config int TeamworkKills_LVL_I;
var config int TeamworkKills_LVL_II;



static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Adrenaline('Adrenaline_I', 2,2,'LVL1', "img:///XPerkIconPack.UIPerk_stim_chevron"));
    Templates.AddItem(MediEvac());


	// Paragon
    Templates.AddItem(Empower_I());
    Templates.AddItem(Empower_II());
    Templates.AddItem(Empower_III());
	Templates.AddItem(Teamwork_I());
	Templates.AddItem(Teamwork_II());
	Templates.AddItem(LockAndLoad());
    

	// Surgeon
	Templates.AddItem(RecoveryPatch_I());
		//Templates.AddItem(RecoveryPatchDR());
    Templates.AddItem(RecoveryPatch_II());
    Templates.AddItem(RecoveryPatch_III());
	Templates.AddItem(Stim_I());
    Templates.AddItem(Stim_II());
    Templates.AddItem(Stim_III());


	// Strategist
	Templates.AddItem(HighPowerShot_I());
    Templates.AddItem(HighPowerShot_II());
    Templates.AddItem(HighPowerShot_III());
	// Holotargeting - Base game
	Templates.AddItem(Weakpoint());
    Templates.AddItem(Surge());
	
	// Combat Medic
	Templates.AddItem(Adrenaline('Adrenaline_II', 3,2,'LVL2', "img:///XPerkIconPack.UIPerk_stim_chevron_x2"));
	Templates.AddItem(Adrenaline('Adrenaline_III', 4,3,'LVL3', "img:///XPerkIconPack.UIPerk_stim_chevron_x3"));
	Templates.AddItem(CriticalHealing());
	Templates.AddItem(GroupTherapy());
	Templates.AddItem(ReactiveTherapy());



	// Helpers
	Templates.AddItem(Serial_ChargeBased_I());
	Templates.AddItem(Serial_ChargeBased_II());


	return Templates;
}


// Perk name:		Adrenaline (changed from Command as it was called in G:T)
// Perk effect:		When you get a kill, you and nearby friendly units get +2 ablative HP for 2 turns.
// Localized text:	"When you get a kill, you and nearby friendly units get <Ability:+AblativeHP/> Ablative HP for 2 turns."
// Config:			(AbilityName="Adrenaline")??
static function X2AbilityTemplate Adrenaline(name AbilityTemplateName, int ablativeHP, int Duration, name Tier, string IconPath)
{
	local X2Effect_PersistentStatChange Effect, WeakPointEffect;
	local X2AbilityTemplate Template;
	local X2AbilityMultiTarget_AllAllies RadiusMultiTarget;
    local X2Condition_AbilityProperty                   OwnerHasAbilityCondition;

		// Create the template using a helper function. This ability triggers when we kill another unit.
	Template = SelfTargetTrigger(AbilityTemplateName, IconPath, true, none, 'KillMail');
	
	// Create a persistent stat change effect to grant ablative
	Effect = new class'X2Effect_PersistentStatChange';
	Effect.EffectName = 'AdrenalineEffect';
	Effect.AddPersistentStatChange(eStat_ShieldHP, ablativeHP);
	Effect.BuildPersistentEffect(Duration, false, false, false, eGameRule_PlayerTurnEnd);
	Effect.SetDisplayInfo(ePerkBuff_Bonus,  "Adrenaline Ablative HP Effect", "", Template.IconImage, true, , Template.AbilitySourceName);
	Effect.DuplicateResponse = eDupe_Ignore;
	// The effect only applies to living, friendly targets
	Effect.TargetConditions.AddItem(default.LivingFriendlyTargetProperty);
	// Show a flyover over the target unit when the effect is added
	Effect.VisualizationFn = AdrenalineShieldFlyOver_Visualization;
	// The multitargets are also affected by the persistent effect we created
	Template.AddMultiTargetEffect(Effect);



	// Create another effect to grant crit chance to allies if you have the weak point ability
	WeakPointEffect = new class'X2Effect_PersistentStatChange';
	WeakPointEffect.EffectName = 'AdrenalineWeakPointEffect';
	WeakPointEffect.AddPersistentStatChange(eStat_CritChance, 10);
	WeakPointEffect.BuildPersistentEffect(2, false, false, false, eGameRule_PlayerTurnEnd);
	WeakPointEffect.SetDisplayInfo(ePerkBuff_Bonus, "Adrenaline Crit Boost","", Template.IconImage, true, , Template.AbilitySourceName);
	// If the effect is added multiple times, it refreshes the duration of the existing effect, i.e. no stacking
	WeakPointEffect.DuplicateResponse = eDupe_Ignore;
	// The effect only applies to living, friendly targets
	WeakPointEffect.TargetConditions.AddItem(default.LivingFriendlyTargetProperty);
	// Show a flyover over the target unit when the effect is added
	WeakPointEffect.VisualizationFn = WeakPointsFlyOver_Visualization;
	// Add condition for the unit to have the weak point ability
	OwnerHasAbilityCondition = new class'X2Condition_AbilityProperty';
    OwnerHasAbilityCondition.OwnerHasSoldierAbilities.AddItem('WeakPoint');
	WeakPointEffect.TargetConditions.AddItem(OwnerHasAbilityCondition);
	Template.AddMultiTargetEffect(WeakPointEffect);


	// Trigger abilities don't appear as passives. Add a passive ability icon.
	HidePerkIcon(Template);
	AddIconPassive(Template);

	// The ability targets the unit that has it, but also effects all friendly units that meet
	// the conditions on the multitarget effect.
	RadiusMultiTarget = new class'X2AbilityMultiTarget_AllAllies';

    // We can add additional conditions later on RadiusMultiTarget if it is deemed too strong

	// Add the multitarget to the ability
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;


	// Shitty way of handling overrides
	switch(Tier)
	{
		case 'LVL2':
			Template.OverrideAbilities.AddItem('Adrenaline_I');
			break;
		case 'LVL3':
			Template.OverrideAbilities.AddItem('Adrenaline_I');
			Template.OverrideAbilities.AddItem('Adrenaline_II');
			break;
		default:
			break;
	}

	return Template;
}

simulated static function AdrenalineShieldFlyOver_Visualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyOver;
	local X2AbilityTemplate             AbilityTemplate;
	local XComGameStateContext_Ability  Context;
	local AbilityInputContext           AbilityContext;
	local EWidgetColor					MessageColor;
	local XComGameState_Unit			SourceUnit;
	local bool							bGoodAbility;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityContext = Context.InputContext;
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.AbilityTemplateName);
	
	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.SourceObject.ObjectID));

	bGoodAbility = SourceUnit.IsFriendlyToLocalPlayer();
	MessageColor = bGoodAbility ? eColor_Good : eColor_Bad;

	if (EffectApplyResult == 'AA_Success' && XGUnit(ActionMetadata.VisualizeActor).IsAlive())
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', MessageColor, AbilityTemplate.IconImage);
	}
}

simulated static function WeakPointsFlyOver_Visualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
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
	AbilityTemplate = AbilityTemplateMgr.FindAbilityTemplate('WeakPoint');
	
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
			SoundAndFlyOver.SetSoundAndFlyOverParameters(none, "Adrenaline: WeakPoint", 'None', MessageColor,AbilityTemplate.IconImage);
		}
		
	}
}








// Perk name:		MediEvac
// Perk effect:		Post mission healing for squad up to 50% of their max HP if it was lower than that.
// Localized text:	"Reduce wound times for heavily injured soldiers (restoring up to 50% of their total HP for wound time calculations)"
// Config:			(AbilityName="MediEvac")
static function X2AbilityTemplate MediEvac()
{
	local X2AbilityTemplate				Template;
	local X2Effect_BattlefieldMedic     MediEvacEffect;


    MediEvacEffect = new class'X2Effect_BattlefieldMedic';
    MediEvacEffect.MediVac_HP_Threshold = 0.5;
	MediEvacEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);



    Template = SquadPassive('MediEvac', "img:///XPerkIconPack.UIPerk_command_medkit", true, MediEvacEffect, ePerkBuff_Passive);
	HidePerkIcon(Template);

    return Template;
}

// Perk name:		Empower_I
// Perk effect:		Spend an action to grant 1 action point to an ally.
// Localized text:	"Spend an action to grant 1 action point to an ally."
// Config:			(AbilityName="Empower_I")
static function X2AbilityTemplate Empower_I()
{
	local X2AbilityTemplate				Template;
	local X2Condition_HasAbility		AbilityCondition2, AbilityCondition3;
	local X2Effect_GrantActionPoints	ActionPointEffect1;

	// AbilityCondition2 = new class 'X2Condition_HasAbility';
	// AbilityCondition2.Abilities.AddItem('Empower_II');

	// AbilityCondition3 = new class 'X2Condition_HasAbility';
	// AbilityCondition3.Abilities.AddItem('Empower_III');
	
	
	// Set up effect granting action point	for all levels
	ActionPointEffect1 = new class'X2Effect_GrantActionPoints';
	ActionPointEffect1.NumActionPoints = 1;
	ActionPointEffect1.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
	ActionPointEffect1.bSelectUnit = true;

	Template = TargetedBuff('Empower_I', "img:///XPerkIconPack.UIPerk_command_chevron", true, ActionPointEffect1, class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY, eCost_SingleConsumeAll);
	
    Template.bLimitTargetIcons = true;
	// Add a cooldown. The internal cooldown numbers include the turn the cooldown is applied, so
	// this is actually a 3 turn cooldown.
	AddCooldown(Template, 4);

	// By default, you can target a unit with an ability even if it already has the effect the
	// ability adds. This helper function prevents targetting units that already have the effect.
    // To do: Check how this stacks with higher versions of this ability
	PreventStackingEffects(Template);

	Template.CustomFireAnim = 'HL_Teamwork';
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

    return Template;
}


// Perk name:		Empower_II
// Perk effect:		Spend an action to grant 1 action point to an ally. The ally also gets +1 damage for 1 turn.
// Localized text:	"Spend an action to grant 1 action point to an ally. The ally also gets +1 damage for 1 turn"
// Config:			(AbilityName="Empower_II")
static function X2AbilityTemplate Empower_II()
{
	local X2AbilityTemplate				Template;
	local X2Condition_HasAbility		AbilityCondition2, AbilityCondition3;
	local X2Effect_GrantActionPoints	ActionPointEffect1;
	local X2Effect_Empowered            DamageBoostEffect2;

	Template = TargetedBuff('Empower_II', "img:///XPerkIconPack.UIPerk_command_chevron_x2", true, none, class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY, eCost_SingleConsumeAll);

	// Set up effect granting action point	for all levels
	ActionPointEffect1 = new class'X2Effect_GrantActionPoints';
	ActionPointEffect1.NumActionPoints = 1;
	ActionPointEffect1.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
	ActionPointEffect1.bSelectUnit = true;
	Template.AddTargetEffect(ActionPointEffect1);



    DamageBoostEffect2 = new class'X2Effect_Empowered';
	DamageBoostEffect2.bUseMultiplier = false;
    DamageBoostEffect2.BonusDamage = 1;
	DamageBoostEffect2.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	DamageBoostEffect2.SetDisplayInfo(ePerkBuff_Bonus, "Empowered I", "This unit has increased damage this turn", Template.IconImage);
	Template.AddTargetEffect(DamageBoostEffect2);

    Template.bLimitTargetIcons = true;
	// Add a cooldown. The internal cooldown numbers include the turn the cooldown is applied, so
	// this is actually a 3 turn cooldown.
	AddCooldown(Template, 4);

	// By default, you can target a unit with an ability even if it already has the effect the
	// ability adds. This helper function prevents targetting units that already have the effect.
    // To do: Check how this stacks with higher versions of this ability
	PreventStackingEffects(Template);

	Template.CustomFireAnim = 'HL_Teamwork';
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

    //Template.PrerequisiteAbilities.AddItem('Empower_I');
	Template.OverrideAbilities.AddItem('Empower_I');
    return Template;
}


// Perk name:		Empower_III
// Perk effect:		Spend an action to grant 1 action point to an ally. The ally also gets +2 damage for 1 turn.
// Localized text:	"Spend an action to grant 1 action point to an ally. The ally also gets +2 damage for 1 turn"
// Config:			(AbilityName="Empower_III")
static function X2AbilityTemplate Empower_III()
{
	local X2AbilityTemplate				Template;
	local X2Condition_HasAbility		AbilityCondition2, AbilityCondition3;
	local X2Effect_GrantActionPoints	ActionPointEffect1;
	local X2Effect_Empowered            DamageBoostEffect2;

	Template = TargetedBuff('Empower_III', "img:///XPerkIconPack.UIPerk_command_chevron_x3", true, none, class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY, eCost_SingleConsumeAll);

	// Set up effect granting action point	for all levels
	ActionPointEffect1 = new class'X2Effect_GrantActionPoints';
	ActionPointEffect1.NumActionPoints = 1;
	ActionPointEffect1.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
	ActionPointEffect1.bSelectUnit = true;
	Template.AddTargetEffect(ActionPointEffect1);

	DamageBoostEffect2 = new class'X2Effect_Empowered';
	DamageBoostEffect2.bUseMultiplier = false;
    DamageBoostEffect2.BonusDamage = 2;
	DamageBoostEffect2.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	DamageBoostEffect2.SetDisplayInfo(ePerkBuff_Bonus, "Empowered II", "This unit has increased damage this turn", Template.IconImage);
	Template.AddTargetEffect(DamageBoostEffect2);


	Template.bLimitTargetIcons = true;
	// Add a cooldown. The internal cooldown numbers include the turn the cooldown is applied, so
	// this is actually a 3 turn cooldown.
	AddCooldown(Template, 4);

	// By default, you can target a unit with an ability even if it already has the effect the
	// ability adds. This helper function prevents targetting units that already have the effect.
    // To do: Check how this stacks with higher versions of this ability
	PreventStackingEffects(Template);
    
	Template.CustomFireAnim = 'HL_Teamwork';
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.OverrideAbilities.AddItem('Empower_I');
	Template.OverrideAbilities.AddItem('Empower_II');
    return Template;
}

function Empower_BuildVisualization(XComGameState VisualizeGameState) // , out array<VisualizationTrack> OutVisualizationTracks)
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






// Perk name:		Teamwork_I
// Perk effect:		Targeted ally gets 1 AP back when killing a target (upto a max 2 this turn).
// Localized text:	"Spend an action to grant to target an ally. Targeted ally gets 1 AP back when killing a target (upto a max 2 this turn). 5 turn cooldown"
// Config:			(AbilityName="Teamwork_I")
static function X2AbilityTemplate Teamwork_I()
{
	local X2AbilityTemplate						Template;
	local XMBEffect_AddAbility 					SerialKillEffect;

	SerialKillEffect = new class'XMBEffect_AddAbility';
	SerialKillEffect.AbilityName = 'SerialChargeBased_I';
	SerialKillEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	

	Template = TargetedBuff('Teamwork_I', "img:///XPerkIconPack.UIPerk_enemy_command_chevron", true, SerialKillEffect,, eCost_Single);



	Template.bLimitTargetIcons = true;
	// Add a cooldown. The internal cooldown numbers include the turn the cooldown is applied, so
	// this is actually a 4 turn cooldown.
	AddCooldown(Template, 5);

	// By default, you can target a unit with an ability even if it already has the effect the
	// ability adds. This helper function prevents targetting units that already have the effect.
    // To do: Check how this stacks with higher versions of this ability
	PreventStackingEffects(Template);
	Template.bShowActivation = true;
	Template.bSkipFireAction = false;
	Template.bSkipExitCoverWhenFiring = true;
	Template.AbilityConfirmSound = "Combat_Presence_Activate";
	Template.CustomFireAnim = 'HL_Teamwork';
	Template.ActivationSpeech = 'CombatPresence';
	Template.CinescriptCameraType = "Skirmisher_CombatPresence";

	//SerialKillEffect.VisualizationFn = EffectFlyOver_Visualization;

	return Template;

}


// Perk name:		Teamwork_II
// Perk effect:		Targeted ally gets 1 AP back when killing a target (upto a max 3 this turn).
// Localized text:	"Spend an action to grant to target an ally. Targeted ally gets 1 AP back when killing a target (upto a max 3 this turn). 4 turn cooldown"
// Config:			(AbilityName="Teamwork_II")
static function X2AbilityTemplate Teamwork_II()
{
	local X2AbilityTemplate						Template;
	local XMBEffect_AddAbility 					SerialKillEffect;

	SerialKillEffect = new class'XMBEffect_AddAbility';
	SerialKillEffect.AbilityName = 'SerialChargeBased_II';
	SerialKillEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	SerialKillEffect.VisualizationFn = EffectFlyOver_Visualization;

	Template = TargetedBuff('Teamwork_II', "img:///XPerkIconPack.UIPerk_enemy_command_chevron_x2", true, SerialKillEffect,, eCost_Single);

	Template.bLimitTargetIcons = true;
	// Add a cooldown. The internal cooldown numbers include the turn the cooldown is applied, so
	// this is actually a 3 turn cooldown.
	AddCooldown(Template, 4);

	// By default, you can target a unit with an ability even if it already has the effect the
	// ability adds. This helper function prevents targetting units that already have the effect.
    // To do: Check how this stacks with higher versions of this ability
	PreventStackingEffects(Template);
	Template.bShowActivation = true;
	Template.bSkipFireAction = false;
	Template.bSkipExitCoverWhenFiring = true;
	Template.AbilityConfirmSound = "Combat_Presence_Activate";
	Template.CustomFireAnim = 'HL_Teamwork';
	Template.ActivationSpeech = 'CombatPresence';
	Template.CinescriptCameraType = "Skirmisher_CombatPresence";

	Template.OverrideAbilities.AddItem('Teamwork_I');
	return Template;

}

// Perk name:		Lock And Load
// Perk effect:		Each unit reloads and gets +50% Damage for this turn..
// Localized text:	"Activate to make each allied unit reload and get +50% Damage for this turn."
// Config:			(AbilityName="LockAndLoad")??
static function X2AbilityTemplate LockAndLoad()
{
	local X2AbilityTemplate						Template;
	local X2AbilityMultiTarget_AllAllies 		RadiusMultiTarget;
	local X2Effect_ReloadPrimaryWeapon 			ReloadEffect;
	local X2Effect_Empowered					BonusDamageEffect;

	Template = SelfTargetActivated('XComGearsSpecialist_LockAndLoad', "img:///XPerkIconPack.UIPerk_gremlin_rifle", true, none,, eCost_Single);
	
	ReloadEffect = new class'X2Effect_ReloadPrimaryWeapon';
	ReloadEffect.AmmoToReload = 99; // Basically forces a fill clip reload
	Template.AddMultiTargetEffect(ReloadEffect);

	BonusDamageEffect = new class'X2Effect_Empowered';
	BonusDamageEffect.EffectName = 'LockAndLoad_Empowered';
	BonusDamageEffect.bUseMultiplier = true;
    BonusDamageEffect.BonusDamageMultiplier = 0.5f;
	BonusDamageEffect.BuildPersistentEffect(1, false, false);
	BonusDamageEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddMultiTargetEffect(BonusDamageEffect);

	// The ability targets the unit that has it, but also effects all friendly units that meet
	// the conditions on the multitarget effect.
	RadiusMultiTarget = new class'X2AbilityMultiTarget_AllAllies';
	RadiusMultiTarget.bAllowSameTarget = true;
	RadiusMultiTarget.NumTargetsRequired = 1; //At least one ally must be a valid target	
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	// Targets must want a reload
	//Template.AbilityMultiTargetConditions.AddItem(new class 'X2Condition_WantsReload');
	
	// Add a cooldown. The internal cooldown numbers include the turn the cooldown is applied, so
	// this is actually a 6 turn cooldown.
	AddCooldown(Template, 7);

	// By default, you can target a unit with an ability even if it already has the effect the
	// ability adds. This helper function prevents targetting units that already have the effect.
    // To do: Check how this stacks with higher versions of this ability
	PreventStackingEffects(Template);

	// Gremlin animation code
    Template.BuildNewGameStateFn = class'X2Ability_SpecialistAbilitySet'.static.SendGremlinToOwnerLocation_BuildGameState;
    Template.BuildVisualizationFn = class'X2Ability_SpecialistAbilitySet'.static.GremlinRestoration_BuildVisualization;
    Template.bSkipFireAction = false;
    Template.bShowActivation = true;
    Template.bStationaryWeapon = true;
    Template.bSkipPerkActivationActions = false;
    Template.PostActivationEvents.AddItem('ItemRecalled');
    Template.TargetingMethod = class'X2TargetingMethod_GremlinAOE';
    Template.bSkipExitCoverWhenFiring = true;
    Template.CustomFireAnim = 'HL_Teamwork';
    Template.ActivationSpeech = 'CombatPresence';
    Template.CinescriptCameraType = "Skirmisher_CombatPresence";
    Template.AbilityConfirmSound = "Combat_Presence_Activate";


	return Template;

}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Perk name:		Recovery Patch I
// Perk effect:		Grants the medical protocol abilities and also grants 30% damage reduction to healed ally for 1 turn.
// Localized text:	"Grants the medical protocol ability for ranged healing and grants 30% damage reduction to healed ally for 1 turn."
// Config:			(AbilityName="RecoveryPatch_I")
static function X2AbilityTemplate RecoveryPatch_I()
{
	local X2AbilityTemplate			Template;
	local X2Effect_RecoveryPatch	RecoveryPatchEffect;

	RecoveryPatchEffect = new class'X2Effect_RecoveryPatch';
	RecoveryPatchEffect.EffectName = 'RecoveryPatchSource_I';

	Template = Passive('RecoveryPatch_I', "img:///XPerkIconPack.UIPerk_medkit_chevron");
	Template.bUniqueSource = true;

	Template.AdditionalAbilities.AddItem('MedicalProtocol'); // Check if heal/stabilize are added properly
	//Template.AdditionalAbilities.AddItem('RecoveryPatchDR');
	return Template;
}




// Perk name:		Recovery Patch II
// Perk effect:		Grants the medical protocol abilities and also grants 40% damage reduction to healed ally for 1 turn.
// Localized text:	"Grants the medical protocol ability for ranged healing and grants 40% damage reduction to healed ally for 1 turn."
// Config:			(AbilityName="RecoveryPatch_II")
static function X2AbilityTemplate RecoveryPatch_II()
{
	local X2AbilityTemplate			Template;
	local XMBEffect_AddItemCharges BonusItemEffect;

	// The number of charges and the items that are affected are gotten from the config
	BonusItemEffect = new class'XMBEffect_AddItemCharges';
	BonusItemEffect.PerItemBonus = default.RECOVERY_PATCH_II_BONUS;
	BonusItemEffect.ApplyToNames = default.RECOVERY_PATCH_ITEMS;
	BonusItemEffect.ApplyToSlots.AddItem(eInvSlot_Utility);

	Template = Passive('RecoveryPatch_II', "img:///XPerkIconPack.UIPerk_medkit_chevron_x2", false, BonusItemEffect);
	Template.bUniqueSource = true;

	//Template.AdditionalAbilities.AddItem('MedicalProtocol'); // Check if heal/stabilize are added properly

	Template.PrerequisiteAbilities.AddItem('RecoveryPatch_I');


	return Template;
}


// Perk name:		Recovery Patch III
// Perk effect:		Grants the medical protocol abilities and also grants 50% damage reduction to healed ally for 1 turn.
// Localized text:	"Grants the medical protocol ability for ranged healing and grants 50% damage reduction to healed ally for 1 turn."
// Config:			(AbilityName="RecoveryPatch_III")
static function X2AbilityTemplate RecoveryPatch_III()
{
	local X2AbilityTemplate			Template;
	local XMBEffect_AddItemCharges BonusItemEffect;

	// The number of charges and the items that are affected are gotten from the config
	BonusItemEffect = new class'XMBEffect_AddItemCharges';
	BonusItemEffect.PerItemBonus = default.RECOVERY_PATCH_III_BONUS;
	BonusItemEffect.ApplyToNames = default.RECOVERY_PATCH_ITEMS;
	BonusItemEffect.ApplyToSlots.AddItem(eInvSlot_Utility);

	Template = Passive('RecoveryPatch_III', "img:///XPerkIconPack.UIPerk_medkit_chevron_x3", false, BonusItemEffect);
	Template.bUniqueSource = true;

	//Template.AdditionalAbilities.AddItem('MedicalProtocol'); // Check if heal/stabilize are added properly


	Template.PrerequisiteAbilities.AddItem('RecoveryPatch_I');
	Template.PrerequisiteAbilities.AddItem('RecoveryPatch_II');
	
	//Template.OverrideAbilities.AddItem('RecoveryPatch_I');
	//Template.OverrideAbilities.AddItem('RecoveryPatch_II');

	
	return Template;
}

static function X2AbilityTemplate RecoveryPatchDR()
{
	local X2AbilityTemplate			Template;
	local X2AbilityTrigger_EventListener						EventListener;
	local X2Condition_UnitProperty								UnitPropertyCondition;
	local X2Effect_DamageReduction	DamageReductionEffect1;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RecoveryPatchDR');
	Template.IconImage = "img:///UILibrary_WOTC_APA_Class_Pack.perk_ApexPredator";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.bCrossClassEligible = false;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'RecoveryPatch';
	EventListener.ListenerData.Filter = eFilter_None;
	EventListener.ListenerData.EventFn = class'X2Effect_RecoveryPatch'.static.RecoveryPatchDRListener;
	Template.AbilityTriggers.AddItem(EventListener);


	DamageReductionEffect1 = new class'X2Effect_DamageReduction';
	DamageReductionEffect1.EffectName = 'RecoveryPatchTargetDR';
	DamageReductionEffect1.bAbsoluteVal = true;
	DamageReductionEffect1.DamageReductionAbs = 1;
	DamageReductionEffect1.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnBegin);
	DamageReductionEffect1.SetDisplayInfo(ePerkBuff_Bonus, "Recovery Patched", "Recovery Patched", Template.IconImage,false,,Template.AbilitySourceName);
	DamageReductionEffect1.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(DamageReductionEffect1);


	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.DefaultSourceItemSlot = eInvSlot_Unknown;
	return Template;

}



// Perk name:		Stim I
// Perk effect:		Grants the revival protocol ability and also grants a standard heal after revival.
// Localized text:	"Grants the revival protocol ability. Revived heal is also healed afterwards."
// Config:			(AbilityName="Stim_I")
static function X2AbilityTemplate Stim_I()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Stim_I', "img:///XPerkIconPack.UIPerk_revive_plus");
	Template.bUniqueSource = true;

	Template.AdditionalAbilities.AddItem('RevivalProtocol');
	HidePerkIcon(Template);
	return Template;
}

// Perk name:		Stim II
// Perk effect:		Revival protocol now imparts a combat stim effect on the target.
// Localized text:	"Revival protocol now imparts a combat stim effect on the target, granting incresed armor, mobility, dodge and immunuity to mental attacks for 2 turns."
// Config:			(AbilityName="Stim_II")
static function X2AbilityTemplate Stim_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Stim_II', "img:///XPerkIconPack.UIPerk_revive_defense");
	Template.bUniqueSource = true;

	Template.AdditionalAbilities.AddItem('RevivalProtocol');
	

	//HidePerkIcon(Template);
	return Template;
}

// Perk name:		Stim III
// Perk effect:		Revival protocol now also imparts one extra action point.
// Localized text:	"Revival protocol imparts the revived ally with 1 bonus action point."
// Config:			(AbilityName="Stim_III")
static function X2AbilityTemplate Stim_III()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('Stim_III', "img:///XPerkIconPack.UIPerk_revive_move");
	Template.bUniqueSource = true;

	Template.AdditionalAbilities.AddItem('RevivalProtocol');
	//HidePerkIcon(Template);
	return Template;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Perk name:		HighPowerShot I
// Perk effect:		Special shot that does +50% damage and has a 4 turn cooldown.
// Localized text:	"Special shot that does +50% damage and has a 4 turn cooldown."
// Config:			(AbilityName="HighPowerShot_I")
static function X2AbilityTemplate HighPowerShot_I()
{
	local X2AbilityTemplate Template;
	local X2AbilityCooldownReduction	Cooldown;
	local array<name> CooldownReductionAbilities;
	local array<int> CooldownReductionAmount;

	// Create the template using a helper function
	Template = Attack('HighPowerShot_I', "img:///XPerkIconPack.UIPerk_rifle_chevron", true, none, class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY, eCost_WeaponConsumeAll, 1);

	CooldownReductionAbilities.AddItem('HighPowerShot_II');
	CooldownReductionAmount.AddItem(1);
	CooldownReductionAbilities.AddItem('HighPowerShot_III');
	CooldownReductionAmount.AddItem(1);
	
	// Add a cooldown. The internal cooldown numbers include the turn the cooldown is applied, so
	// this is actually a 4 turn cooldown.
	Cooldown = new class'X2AbilityCooldownReduction';
	Cooldown.BaseCooldown = 4;
	Cooldown.CooldownReductionAbilities = CooldownReductionAbilities;
	Cooldown.CooldownReductionAmount = CooldownReductionAmount;
	Template.AbilityCooldown = Cooldown;

	// Add a secondary ability to provide bonuses on the shot
	AddSecondaryAbility(Template, HighPowerShotBonus());

	return Template;
}

// This is part of the High Power Shot effect, above
static function X2AbilityTemplate HighPowerShotBonus()
{
	local X2AbilityTemplate Template;
	local XMBEffect_ConditionalBonus Effect;
	local XMBCondition_AbilityName Condition;

	// Create a conditional bonus effect
	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'HighPowerShotBonus';
	Effect.DuplicateResponse = eDupe_Ignore;

	// The bonus adds +50% damage
	Effect.AddPercentDamageModifier(50);

	// The bonus only applies to the Power Shot ability
	Condition = new class'XMBCondition_AbilityName';
	Condition.IncludeAbilityNames.AddItem('HighPowerShot_I');
	Effect.AbilityTargetConditions.AddItem(Condition);

	// Create the template using a helper function
	Template = Passive('HighPowerShotBonus', "img:///UILibrary_PerkIcons.UIPerk_command", false, Effect);

	// The Power Shot ability will show up as an active ability, so hide the icon for the passive damage effect
	HidePerkIcon(Template);

	return Template;
}

// Perk name:		HighPowerShot II
// Perk effect:		High power shot's cooldown is reduced by 1 turn.
// Localized text:	"High power shot's cooldown is reduced by 1 turn (4 to 3 turns)"
// Config:			(AbilityName="HighPowerShot_II")
static function X2AbilityTemplate HighPowerShot_II()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('HighPowerShot_II', "img:///XPerkIconPack.UIPerk_rifle_chevron_x2");
	Template.bUniqueSource = true;
	HidePerkIcon(Template);
	Template.PrerequisiteAbilities.AddItem('HighPowerShot_I');

	return Template;
}

// Perk name:		HighPowerShot III
// Perk effect:		High power shot's cooldown is further reduced by 1 turn.
// Localized text:	"High power shot's cooldown is further reduced by 1 turn."
// Config:			(AbilityName="HighPowerShot_III")
static function X2AbilityTemplate HighPowerShot_III()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('HighPowerShot_III', "img:///XPerkIconPack.UIPerk_rifle_chevron_x3");
	Template.bUniqueSource = true;
	HidePerkIcon(Template);
	Template.PrerequisiteAbilities.AddItem('HighPowerShot_I');

	return Template;
}

// Perk name:		WeakPoint
// Perk effect:		Adrenaline now also grants allies +10 crit.
// Localized text:	"When this unit's Adrenaline is triggered, each ally gets +10% Critical Hit Chance for 2 turns."
// Config:			(AbilityName="WeakPoint")
static function X2AbilityTemplate WeakPoint()
{
	local X2AbilityTemplate			Template;

	Template = PurePassive('WeakPoint', "img:///XPerkIconPack.UIPerk_crit_adrenaline");
	Template.bUniqueSource = true;

	//Template.PrerequisiteAbilities.AddItem('Adrenaline');

	return Template;
}

// Perk name:		Surge
// Perk effect:		Activate to reset all ability cooldowns (excluding surge).
// Localized text:	"Activate to reset all ability cooldowns (excluding surge). 1 AP non turn ending, 6 turns cooldown "
// Config:			(AbilityName="Surge")
static function X2AbilityTemplate Surge()
{
	local X2Effect_ResetCooldown Effect;
	local X2AbilityTemplate Template;

	Effect = new class'X2Effect_ResetCooldown';
	Effect.ExcludedAbilities.AddItem('Surge');
	
	// Create the template as a helper function. This is an activated ability that doesn't cost an action.
	Template = SelfTargetActivated('Surge', "img:///XPerkIconPack.UIPerk_stim_cycle", true, Effect, class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY, eCost_Single);

	Template.AbilityShooterConditions.AddItem(new class'X2Condition_ManualOverride');
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();	

	// Add a cooldown. The internal cooldown numbers include the turn the cooldown is applied, so
	// this is actually a 6 turn cooldown.
	AddCooldown(Template, 7);

	//Template.BuildNewGameStateFn = class'X2Ability_SpecialistAbilitySet'.static.AttachGremlinToTarget_BuildGameState;
	//Template.BuildVisualizationFn = class'X2Ability_SpecialistAbilitySet'.static.GremlinSingleTarget_BuildVisualization;
    Template.bShowActivation = true;
    Template.bSkipFireAction = false;
    Template.bSkipExitCoverWhenFiring = true;
    Template.CustomFireAnim = 'HL_VanishingWind';
    Template.ActivationSpeech = 'ManualOverride';
    Template.CinescriptCameraType = "ChosenAssassin_VanishingWind";

    return Template;
}


// Perk name:		Group Therapy
// Perk effect:		Allows restoration protocol to also grant bonus shield HP.
// Localized text:	"Allows restoration protocol to also grant bonus shield HP. Passive"
// Config:			(AbilityName="GroupTherapy")

static function X2AbilityTemplate GroupTherapy()
{
	local X2AbilityTemplate			Template;

	Template = Passive('GroupTherapy', "img:///XPerkIconPack.UIPerk_gremlin_stim");
	Template.bUniqueSource = true;
	HidePerkIcon(Template);
	Template.PrerequisiteAbilities.AddItem('RestorativeMist');



	return Template;
}

static function X2AbilityTemplate CriticalHealing()
{
	local X2Effect_CriticalHealing				Effect;

	// This effect will add a listener to the soldier that listens for them to apply a heal.
	// When the heal is applied XComGameState_Effect_LW2WotC_Savior.OnMedkitHeal() is called to increase the potency of the heal.
	Effect = new class 'X2Effect_CriticalHealing';

	// Create the template using a helper function
	return Passive('CriticalHealing', "img:///XPerkIconPack.UIPerk_medkit_crit", true, Effect);
}


// Perk name:		Reactive Therapy
// Perk effect:		When an ally takes dies, restoration protocol cooldown is reset.
// Localized text:	"When an ally takes dies, restoration protocol cooldown is reset. Passive"
// Config:			(AbilityName="ReactiveTherapy")

static function X2AbilityTemplate ReactiveTherapy()
{
	local X2AbilityTemplate			Template;
	local X2Condition_UnitProperty          ShooterProperty, MultiTargetProperty;
	local X2Effect_Vengeance                VengeanceEffect;
	local X2Effect_ResetCooldown 			Effect;
	local X2Effect_ReactiveTherapy			Deflect;
	local X2AbilityTrigger_EventListener    Listener;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ReactiveTherapy');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///XPerkIconPack.UIPerk_gremlin_cycle";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Deflect = new class'X2Effect_ReactiveTherapy';
	Deflect.BuildPersistentEffect(1, true);
	Deflect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(Deflect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;


/*
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllAllies';

	Effect = new class'X2Effect_ResetCooldown';
	Effect.IncludedAbilities.AddItem('RestorativeMist');
	Template.AddTargetEffect(Effect);
	Template.AddMultiTargetEffect(Effect);

	VengeanceEffect = new class'X2Effect_Vengeance';
	VengeanceEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	VengeanceEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage);
	Template.AddMultiTargetEffect(VengeanceEffect);

	Listener = new class'X2AbilityTrigger_EventListener';
	Listener.ListenerData.Filter = eFilter_Unit;
	Listener.ListenerData.Deferral = ELD_OnStateSubmitted;
	Listener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_SelfWithAdditionalTargets;
	Listener.ListenerData.EventID = 'UnitDied';
	Template.AbilityTriggers.AddItem(Listener);

	ShooterProperty = new class'X2Condition_UnitProperty';
	ShooterProperty.ExcludeAlive = false;
	ShooterProperty.ExcludeDead = false;
	//Template.AbilityShooterConditions.AddItem(ShooterProperty);

	MultiTargetProperty = new class'X2Condition_UnitProperty';
	MultiTargetProperty.ExcludeAlive = false;
	MultiTargetProperty.ExcludeDead = true;
	MultiTargetProperty.ExcludeHostileToSource = true;
	MultiTargetProperty.ExcludeFriendlyToSource = false;
	MultiTargetProperty.RequireSquadmates = true;	
	MultiTargetProperty.ExcludePanicked = true;
	//Template.AbilityMultiTargetConditions.AddItem(MultiTargetProperty);

	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
*/
	Template.PrerequisiteAbilities.AddItem('RestorativeMist');

	return Template;
}








////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static function X2AbilityTemplate Serial_ChargeBased_I()
{
	local X2AbilityTemplate							Template;
	local X2Effect_Persistent						IconEffect;
	local X2Effect_TeamworkKillsActionRefunds    TeamWorkEffect;

	`CREATE_X2ABILITY_TEMPLATE (Template, 'SerialChargeBased_I');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_InTheZone";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bCrossClassEligible = false;
	Template.bUniqueSource = true;
	Template.bIsPassive = true;

	// Dummy effect to show a passive icon in the tactical UI for the SourceUnit
	IconEffect = new class'X2Effect_Persistent';
	IconEffect.BuildPersistentEffect(1, true, false, false, eGameRule_PlayerTurnEnd);
	IconEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, ,, Template.AbilitySourceName);
	IconEffect.EffectName = 'SerialChargeBased';
	//Template.AddTargetEffect(IconEffect);



	TeamWorkEffect = new class'X2Effect_TeamworkKillsActionRefunds';
	TeamWorkEffect.EffectName = 'SerialChargeBased_I';
	TeamWorkEffect.BuildPersistentEffect(1, true, false, false, eGameRule_PlayerTurnEnd);
	TeamWorkEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, default.SerialChargeBasedDescription, Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(TeamWorkEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}


static function X2AbilityTemplate Serial_ChargeBased_II()
{
	local X2AbilityTemplate							Template;
	local X2Effect_Persistent						IconEffect;
	local X2Effect_TeamworkKillsActionRefunds    TeamWorkEffect;

	`CREATE_X2ABILITY_TEMPLATE (Template, 'SerialChargeBased_II');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_InTheZone";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bCrossClassEligible = false;
	Template.bUniqueSource = true;
	Template.bIsPassive = true;

	// Dummy effect to show a passive icon in the tactical UI for the SourceUnit
	IconEffect = new class'X2Effect_Persistent';
	IconEffect.BuildPersistentEffect(1, true, false, false, eGameRule_PlayerTurnEnd);
	IconEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, ,, Template.AbilitySourceName);
	IconEffect.EffectName = 'SerialChargeBased';
	//Template.AddTargetEffect(IconEffect);



	TeamWorkEffect = new class'X2Effect_TeamworkKillsActionRefunds';
	TeamWorkEffect.EffectName = 'SerialChargeBased_II';
	TeamWorkEffect.BuildPersistentEffect(1, true, false, false, eGameRule_PlayerTurnEnd);
	TeamWorkEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, default.SerialChargeBasedDescription, Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(TeamWorkEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}