class X2EventListener_XComGearsPerkPack extends X2EventListener;


static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateTacticalMissionListenerTemplate());
    Templates.AddItem(CreateAnchoredUITemplate());

	return Templates;
}


// 'TacticalMission' event listeners
static function CHEventListenerTemplate CreateTacticalMissionListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'CleanupTacticalMission');

	Template.RegisterInTactical = true;

	Template.AddCHEvent('CleanupTacticalMission', MedivacOverrideCleanupTacticalMission, ELD_OnStateSubmitted);
    //Template.AddCHEvent('UnitDied', ExplosionOnDeathTrigger, ELD_OnStateSubmitted);
	return Template;
}

static function X2EventListenerTemplate CreateAnchoredUITemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'Anchored_UI');

	Template.RegisterInTactical = true;
	Template.AddCHEvent('OverrideUnitFocusUI', OnOverrideFocus, ELD_Immediate);

	return Template;
} 



// Apply post-mission healing from Medivac and Bastion (Field Surgeon)
static function EventListenerReturn MedivacOverrideCleanupTacticalMission(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComGameStateHistory		History;
    local XComGameState_Unit		TargetUnit;
    local XComGameState_Effect		EffectState;
    local StateObjectReference		EffectRef;


    History = `XCOMHISTORY;

    // Process Medivac Post-Mission Healing Effects:
    // ---------------------------------------------
    // Get total number of Medivac Healing charges (unused Medikit ammo on Medivac source units)
    foreach History.IterateByClassType(class'XComGameState_Unit', TargetUnit)
    {
        // Source units must be alive, conscious, and must not be mind-controlled/captured
        if (TargetUnit.IsAlive() && !TargetUnit.bCaptured)
        {
            foreach TargetUnit.AffectedByEffects(EffectRef)
            {
                // Source unit must be under the MedivacSource effect
                EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
                if (EffectState.GetX2Effect().EffectName == class'X2Effect_BattlefieldMedic'.default.EffectName)
                {
                    X2Effect_BattlefieldMedic(EffectState.GetX2Effect()).ApplyMedivacHealing(EffectState,TargetUnit,GameState);
                }

                if (EffectState.GetX2Effect().EffectName == class'X2Effect_BastionPostMissionHealing'.default.EffectName)
                {
                    X2Effect_BastionPostMissionHealing(EffectState.GetX2Effect()).ApplyBastionPostMissionHealing(EffectState,TargetUnit,GameState);
                }
            }
        }
    }

    return ELR_NoInterrupt;
}

// Apply death explosion on unit killed by an ability
static function EventListenerReturn ExplosionOnDeathTrigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState NewGameState;
    local XComGameState_Ability AbilityState;
	local XComGameState_Unit  UnitState, DeadUnit, SourceUnit, TargetUnit;
    local XComGameState_Item SourceWeapon;
    local UnitValue StreakStacks;
    local int CurrentStacks, UpdatedStacks, i;

    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;

    DeadUnit =  XComGameState_Unit(EventData); // 
    UnitState = XComGameState_Unit(EventSource); // 
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
    TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
    SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));


    if (DeadUnit.IsEnemyUnit(SourceUnit) && DeadUnit.GetTeam() != eTeam_TheLost && SourceUnit.GetTeam() == eTeam_XCom && DeadUnit.GetMyTemplateName() != 'PsiZombie' &&	DeadUnit.GetMyTemplateName() != 'PsiZombieHuman' && AbilityState.GetMyTemplateName() == 'ExplosiveShot_I')
    {
        `Log("Target unit is dead! Now triggering explosion via global event Trigger!");
        `XEVENTMGR.TriggerEvent('ExplosiveShotActivationTrigger', AbilityState, DeadUnit, GameState);

        if (class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(DeadUnit.GetReference(), 'ExplodeOnDeath', DeadUnit.GetReference()))
            `Log("Triggered!!!!");
        
    }

    return ELR_NoInterrupt;

}

//based Robojumper be praised, all of this is his work
static function EventListenerReturn OnOverrideFocus(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit	UnitState;
	local XComLWTuple			Tuple;
	local UnitValue				UV;

	Tuple = XComLWTuple(EventData);
	UnitState = XComGameState_Unit(EventSource);

	//doing the class / effect checks to ensure compatibility with AWC and RPGO, while not cluttering UI for other classes.
	if (UnitState.IsUnitAffectedByEffectName(class'X2Effect_Anchored'.default.EffectName))
	{
		UnitState.GetUnitValue('AnchorStacks', UV);

		Tuple.Data[0].b = true;
		Tuple.Data[1].i = UV.fValue;
		Tuple.Data[2].i = class'X2Ability_GearsHeavyAbilitySet'.default.MaxAnchorStacks;
		Tuple.Data[3].s = "0xff3206"; //Set red color
		Tuple.Data[4].s = "img:///XPerkIconPack.UIPerk_suppression_blossom";
		Tuple.Data[5].s = "Anchor stacks";
		Tuple.Data[6].s = "Anchor";

	}
	return ELR_NoInterrupt;
}