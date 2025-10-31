//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_XComGearsPerkPack.uc                                    
//           
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_XComGearsPerkPack extends X2DownloadableContentInfo;

delegate ModifyTemplate(X2DataTemplate DataTemplate);
/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{}

static function OnPostTemplatesCreated()
{

    `log("XComGearsPerkPack: Now patching abilities and weapon templates...");
    IterateTemplatesAllDiff(class'X2WeaponTemplate', PatchWeaponTemplates);
    IterateTemplatesAllDiff(class'X2AbilityTemplate', PatchAbilityTemplate);
    IterateTemplatesAllDiff(class'X2CharacterTemplate', PatchCharacterTemplates);
    UpdateStartingXPACKWeaponTemplates(true);
    `log("XComGearsPerkPack: Finished patching abilities and weapon templates...");
}

/////////////////////////////////////////////////////////////////////////////////////

static function PatchWeaponTemplates(X2DataTemplate DataTemplate)
{
    //
}

static function PatchCharacterTemplates(X2DataTemplate DataTemplate)
{
	local X2CharacterTemplateManager CharMgr;
	local X2CharacterTemplate Template;    
    
    Template = X2CharacterTemplate(DataTemplate);
    if ((Template.bIsAlien || Template.bIsAdvent) && !Template.bIsChosen)
    {
        
        Template.Abilities.AddItem('ExplodeOnDeath');
        //Template.Abilities.AddItem('TerrifiedApply');

    }
}

static function PatchAbilityTemplate(X2DataTemplate DataTemplate)
{
    local X2AbilityTemplate                             Template;
    local X2Condition_AbilityProperty                   OwnerHasAbilityCondition;
	local X2Effect_PersistentStatChange			        StatEffect;
    local X2AbilityCharges                              Charges;
    local X2AbilityCost_ActionPoints                    ActionPointCost;
    local X2AbilityCooldown                             Cooldown;
    local X2AbilityCost                                 Cost;
    local X2AbilityToHitCalc_StandardAim            StandardAim;
    local X2AbilityMultiTarget_Radius               RadiusMultiTarget;

    local int i,k;

    Template = X2AbilityTemplate(DataTemplate);

    if (Template.DataName == 'GremlinHeal')
    {
        AddRecoveryPatchEffectToGremlinHeal(Template);
    }

    if (Template.DataName == 'RevivalProtocol')
    {
        AddStimEffectToRevivalProtocol(Template);
    }

    if (Template.DataName == 'RestorativeMist')
    {
        `Log("Adding cooldown and shielding effect to" @ Template.DataName);

		// Kill the charges and the charge cost
		Template.AbilityCosts.Length = 0;
		Template.AbilityCharges = none;

		// Killing the above results in some collateral damage so we have to re-add the action point costs
		ActionPointCost = new class'X2AbilityCost_ActionPoints';
		ActionPointCost.iNumPoints = 1;
		ActionPointCost.bFreeCost = true;
		Template.AbilityCosts.AddItem(ActionPointCost);
        
        Cooldown = new class'X2AbilityCooldown';
	    Cooldown.iNumTurns = 5;
	    Template.AbilityCooldown = Cooldown;
          
        OwnerHasAbilityCondition = new class'X2Condition_AbilityProperty';
        OwnerHasAbilityCondition.OwnerHasSoldierAbilities.AddItem('GroupTherapy');
        
        StatEffect = new class'X2Effect_PersistentStatChange';
        StatEffect.EffectName = 'GroupTherapy';
        StatEffect.DuplicateResponse = eDupe_Ignore;
        StatEffect.BuildPersistentEffect(1, true, false);
        StatEffect.SetDisplayInfo(ePerkBuff_Bonus, "Group Therapy", "Group Therapy has provided ablative HP to this unit", Template.IconImage, false);
        StatEffect.AddPersistentStatChange(eStat_ShieldHP, class'X2Ability_DefaultAbilitySet'.default.MEDIKIT_PERUSEHP);
        StatEffect.TargetConditions.AddItem(OwnerHasAbilityCondition);
        Template.AddMultiTargetEffect(StatEffect);

    }


    if (Template.DataName == 'StandardShot' || Template.DataName == 'PistolStandardShot')
    {
        `Log("Adding unnerve and bleeding effect to " @ Template.DataName);
        Template.AddTargetEffect(class'X2Ability_GearsVanguardAbilitySet'.static.UnnerveEffect());
        Template.AddTargetEffect(class'X2Ability_GearsVanguardAbilitySet'.static.BleedingEffect());

        for (i = 0; i < Template.AbilityCosts.Length; i++)
        {
            if (X2AbilityCost_ActionPoints(Template.AbilityCosts[i]) != none)
            {
                X2AbilityCost_ActionPoints(Template.AbilityCosts[i]).DoNotConsumeAllEffects.AddItem('AvengerNonTurnEndingShots');
                X2AbilityCost_ActionPoints(Template.AbilityCosts[i]).DoNotConsumeAllEffects.AddItem('Anticipation');
                X2AbilityCost_ActionPoints(Template.AbilityCosts[i]).DoNotConsumeAllEffects.AddItem('Exertion_DR');
            }
        }
    }

    if (Template.DataName == 'Suppression')
    {
        `Log("Adding AoE suppression effect for Heavy to " @ Template.DataName);

        RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
        RadiusMultiTarget.bIgnoreBlockingCover = true;
        RadiusMultiTarget.bAllowDeadMultiTargetUnits = false;
        RadiusMultiTarget.bExcludeSelfAsTargetIfWithinRadius = true;
        RadiusMultiTarget.bUseWeaponRadius = false;
        RadiusMultiTarget.ftargetradius = 4;
        Template.AbilityMultiTargetStyle = RadiusMultiTarget;
        //Template.AbilityMultiTargetConditions.AddItem(default.Living);

        Template.AddMultiTargetEffect(class'X2Ability_GearsHeavyAbilitySet'.static.SuppressiveFireEffect());

    }




    if (Template.DataName == 'SoulReaper')
    {
        `Log("Converting charge to cooldown for " @ Template.DataName);
        foreach Template.AbilityCosts(Cost)
        {
            if (Cost.isA('X2AbilityCost_Charges'))
            {
                Template.AbilityCosts.RemoveItem(Cost);
                break;
            }
        }

	Template.AbilityCharges = none;

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 8;
	Template.AbilityCooldown = Cooldown;

    }



}


static function AddRecoveryPatchEffectToGremlinHeal(X2AbilityTemplate Template)
{
    local X2Condition_AbilityProperty                   OwnerHasAbilityCondition;
    local X2Effect_DamageReduction                      DamageReductionEffect1, DamageReductionEffect2, DamageReductionEffect3;
    `Log("Adding Recovery Patch Effect to" @ Template.DataName);
    
    DamageReductionEffect1 = new class'X2Effect_DamageReduction';
    DamageReductionEffect1.EffectName = 'RecoveryPatchI';
    DamageReductionEffect1.bAbsoluteVal = true;
    DamageReductionEffect1.DamageReductionAbs = 1;
    DamageReductionEffect1.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnBegin);
    DamageReductionEffect1.SetDisplayInfo(ePerkBuff_Bonus, "Recovery Patch I", "Recovery Patch I", Template.IconImage,true,,Template.AbilitySourceName);
    DamageReductionEffect1.DuplicateResponse = eDupe_Ignore;

    OwnerHasAbilityCondition = new class'X2Condition_AbilityProperty';
    OwnerHasAbilityCondition.OwnerHasSoldierAbilities.AddItem('RecoveryPatch_I');
    DamageReductionEffect1.TargetConditions.AddItem(OwnerHasAbilityCondition);
    Template.AddTargetEffect(DamageReductionEffect1);

    DamageReductionEffect2 = new class'X2Effect_DamageReduction';
    DamageReductionEffect2.EffectName = 'RecoveryPatchII';
    DamageReductionEffect2.bAbsoluteVal = true;
    DamageReductionEffect2.DamageReductionAbs = 1;
    DamageReductionEffect2.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnBegin);
    DamageReductionEffect2.SetDisplayInfo(ePerkBuff_Bonus, "Recovery Patch II", "Recovery Patch II", Template.IconImage,true,,Template.AbilitySourceName);
    DamageReductionEffect2.DuplicateResponse = eDupe_Ignore;

    OwnerHasAbilityCondition = new class'X2Condition_AbilityProperty';
    OwnerHasAbilityCondition.OwnerHasSoldierAbilities.AddItem('RecoveryPatch_II');
    DamageReductionEffect2.TargetConditions.AddItem(OwnerHasAbilityCondition);        
    Template.AddTargetEffect(DamageReductionEffect2);


    DamageReductionEffect3 = new class'X2Effect_DamageReduction';
    DamageReductionEffect3.EffectName = 'RecoveryPatchIII';
    DamageReductionEffect3.bAbsoluteVal = true;
    DamageReductionEffect3.DamageReductionAbs = 1;
    DamageReductionEffect3.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnBegin);
    DamageReductionEffect3.SetDisplayInfo(ePerkBuff_Bonus, "Recovery Patch III", "Recovery Patch III", Template.IconImage,true,,Template.AbilitySourceName);
    DamageReductionEffect3.DuplicateResponse = eDupe_Ignore;

    OwnerHasAbilityCondition = new class'X2Condition_AbilityProperty';
    OwnerHasAbilityCondition.OwnerHasSoldierAbilities.AddItem('RecoveryPatch_III');
    DamageReductionEffect3.TargetConditions.AddItem(OwnerHasAbilityCondition);        
    Template.AddTargetEffect(DamageReductionEffect3);
}



static function AddStimEffectToRevivalProtocol(X2AbilityTemplate Template)
{
    local X2Effect_ApplyMedikitHeal                     HealEffect;
	local X2Effect_CombatStims					        StimEffect;
	local X2Effect_PersistentStatChange			        StatEffect;
    local X2Effect_GrantActionPoints                    PointEffect3;
    local X2Condition_AbilityProperty                   OwnerHasAbilityCondition;

    `Log("Adding Stim Effect to" @ Template.DataName);
    
    // Tier 1 stims adds healing when reviving
    OwnerHasAbilityCondition = new class'X2Condition_AbilityProperty';
    OwnerHasAbilityCondition.OwnerHasSoldierAbilities.AddItem('Stim_I');
    
    HealEffect = new class'X2Effect_ApplyMedikitHeal';
    HealEffect.PerUseHP = class'X2Ability_DefaultAbilitySet'.default.MEDIKIT_PERUSEHP;
    HealEffect.IncreasedHealProject = 'BattlefieldMedicine';
    HealEffect.IncreasedPerUseHP = class'X2Ability_DefaultAbilitySet'.default.NANOMEDIKIT_PERUSEHP;
    HealEffect.TargetConditions.AddItem(OwnerHasAbilityCondition);
    Template.AddTargetEffect(HealEffect);

    // Tier 2 stim adds combat stim effects
    OwnerHasAbilityCondition = new class'X2Condition_AbilityProperty';
    OwnerHasAbilityCondition.OwnerHasSoldierAbilities.AddItem('Stim_II');

    StimEffect = new class'X2Effect_CombatStims';
    StimEffect.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnEnd);
    StimEffect.SetDisplayInfo(ePerkBuff_Bonus, "Enhanced Stim", "This unit has increased mobility, dodge, armor, and immunity to mental defects", Template.IconImage);
    StimEffect.TargetConditions.AddItem(OwnerHasAbilityCondition);        
    Template.AddTargetEffect(StimEffect);

    StatEffect = new class'X2Effect_PersistentStatChange';
    StatEffect.EffectName = 'Stim_II';
    StatEffect.DuplicateResponse = eDupe_Refresh;
    StatEffect.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnEnd);
    StatEffect.SetDisplayInfo(ePerkBuff_Bonus, "Enhanced Stim", "This unit has increased mobility, dodge, armor, and immunity to mental defects", Template.IconImage, false);
    StatEffect.AddPersistentStatChange(eStat_Mobility, 1.5, MODOP_Multiplication);
    StatEffect.AddPersistentStatChange(eStat_Dodge, 15);
    StatEffect.TargetConditions.AddItem(OwnerHasAbilityCondition);        
    Template.AddTargetEffect(StatEffect);


    // Tier 3 stims adds bonus AP when reviving
    OwnerHasAbilityCondition = new class'X2Condition_AbilityProperty';
    OwnerHasAbilityCondition.OwnerHasSoldierAbilities.AddItem('Stim_III');

    PointEffect3 = new class'X2Effect_GrantActionPoints';
    PointEffect3.NumActionPoints = 1;
    PointEffect3.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
    PointEffect3.TargetConditions.AddItem(OwnerHasAbilityCondition);        
    Template.AddTargetEffect(PointEffect3);
}

// Copied from Proficiency Classes
static function UpdateStartingXPACKWeaponTemplates(bool bDebugLogging)
{
	local X2ItemTemplateManager					ItemTemplateManager;
	local X2WeaponTemplate						WeaponTemplate;
	local X2SchematicTemplate					SchematicTemplate;
	local array<X2DataTemplate>					SchematicTemplates;
	local X2DataTemplate						DataTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// Update Bullpup Items
	WeaponTemplate = X2WeaponTemplate(ItemTemplateManager.FindItemTemplate('Bullpup_CV'));
	WeaponTemplate.StartingItem = true;
	`Log("Making Bullpups a starting item", bDebugLogging);

	ItemTemplateManager.FindDataTemplateAllDifficulties('Bullpup_MG_Schematic', SchematicTemplates);
	foreach SchematicTemplates(DataTemplate)
	{
		SchematicTemplate = X2SchematicTemplate(DataTemplate);
		if (SchematicTemplate != none)
		{
			SchematicTemplate.Requirements.RequiredSoldierClass = '';
	}	}

	ItemTemplateManager.FindDataTemplateAllDifficulties('Bullpup_BM_Schematic', SchematicTemplates);
	foreach SchematicTemplates(DataTemplate)
	{
		SchematicTemplate = X2SchematicTemplate(DataTemplate);
		if (SchematicTemplate != none)
		{
			SchematicTemplate.Requirements.RequiredSoldierClass = '';
	}	}

	// Update Vektor Rifle Items
	WeaponTemplate = X2WeaponTemplate(ItemTemplateManager.FindItemTemplate('VektorRifle_CV'));
	WeaponTemplate.StartingItem = true;
	WeaponTemplate.iTypicalActionCost = 1;
	`Log("Making Vektor Rifles a starting item and fix T1 iTypicalActionCost value", bDebugLogging);
	
	ItemTemplateManager.FindDataTemplateAllDifficulties('VektorRifle_MG_Schematic', SchematicTemplates);
	foreach SchematicTemplates(DataTemplate)
	{
		SchematicTemplate = X2SchematicTemplate(DataTemplate);
		if (SchematicTemplate != none)
		{
			SchematicTemplate.Requirements.RequiredSoldierClass = '';
	}	}

	ItemTemplateManager.FindDataTemplateAllDifficulties('VektorRifle_BM_Schematic', SchematicTemplates);
	foreach SchematicTemplates(DataTemplate)
	{
		SchematicTemplate = X2SchematicTemplate(DataTemplate);
		if (SchematicTemplate != none)
		{
			SchematicTemplate.Requirements.RequiredSoldierClass = '';
	}	}
}

//=========================================================================================
//================= BEGIN ABILITY TAG HANDLER ====================================
//=========================================================================================

static function bool AbilityTagExpandHandler_CH(string InString, out string OutString, Object ParseObj, Object StrategyParseOb, XComGameState GameState)
{
	local name Type;
	local XComGameState_Ability AbilityState;
	local XComGameState_Effect EffectState;
	local XComGameState_Unit UnitState;
	local X2AbilityTemplate AbilityTemplate;
	local int CurrentKills;
    local UnitValue								TrackerUnitValue;
	local int k;

	Type = name(InString);
	switch(Type)
	{
        case 'SERIAL_KILLS':
            OutString = "0";
            AbilityState = XComGameState_Ability(ParseObj);
            if (AbilityState != none)
            {
                UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
            }
            else
            {
                EffectState = XComGameState_Effect(ParseObj);
                if (EffectState != none)
                {
                    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
                }
            }

            if (UnitState != none)
            {
                UnitState.GetUnitValue('TeamworkKills', TrackerUnitValue);
                CurrentKills = int(TrackerUnitValue.fValue);

                //`log("The effect name for TeamworkKillsEffect is " $ EffectState.GetX2Effect().EffectName );
                // We assume the EffectState is one of the two SerialChargeBased ones....
                if (EffectState.GetX2Effect().EffectName == 'SerialChargeBased_I')
                {
                    OutString = string(CurrentKills) $ "/" $ string(class'X2Ability_GearsSupportAbilitySet'.default.TeamworkKills_LVL_I);
                }

                if (EffectState.GetX2Effect().EffectName == 'SerialChargeBased_II')
                {
                    OutString = string(CurrentKills) $ "/" $ string(class'X2Ability_GearsSupportAbilitySet'.default.TeamworkKills_LVL_II);
                }
                
                
            }
            return true;
        default:
            return false;
    }
}
















// Helper Functions for patching ability and weapon templtes - Courtesy of Iridar
///////////////////////////////////////////////////////////////////////////////////
static private function IterateTemplatesAllDiff(class TemplateClass, delegate<ModifyTemplate> ModifyTemplateFn)
{
    local X2DataTemplate                                    IterateTemplate;
    local X2DataTemplate                                    DataTemplate;
    local array<X2DataTemplate>                             DataTemplates;
    local X2DownloadableContentInfo_XComGearsPerkPack CDO;

    local X2ItemTemplateManager             ItemMgr;
    local X2AbilityTemplateManager          AbilityMgr;
    local X2CharacterTemplateManager        CharMgr;
    local X2StrategyElementTemplateManager  StratMgr;
    local X2SoldierClassTemplateManager     ClassMgr;

    if (ClassIsChildOf(TemplateClass, class'X2ItemTemplate'))
    {
        CDO = GetCDO();
        ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

        foreach ItemMgr.IterateTemplates(IterateTemplate)
        {
            if (!ClassIsChildOf(IterateTemplate.Class, TemplateClass)) continue;

            ItemMgr.FindDataTemplateAllDifficulties(IterateTemplate.DataName, DataTemplates);
            foreach DataTemplates(DataTemplate)
            {   
                CDO.CallModifyTemplateFn(ModifyTemplateFn, DataTemplate);
            }
        }
    }
    else if (ClassIsChildOf(TemplateClass, class'X2AbilityTemplate'))
    {
        CDO = GetCDO();
        AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

        foreach AbilityMgr.IterateTemplates(IterateTemplate)
        {
            if (!ClassIsChildOf(IterateTemplate.Class, TemplateClass)) continue;

            AbilityMgr.FindDataTemplateAllDifficulties(IterateTemplate.DataName, DataTemplates);
            foreach DataTemplates(DataTemplate)
            {
                CDO.CallModifyTemplateFn(ModifyTemplateFn, DataTemplate);
            }
        }
    }
    else if (ClassIsChildOf(TemplateClass, class'X2CharacterTemplate'))
    {
        CDO = GetCDO();
        CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
        foreach CharMgr.IterateTemplates(IterateTemplate)
        {
            if (!ClassIsChildOf(IterateTemplate.Class, TemplateClass)) continue;

            CharMgr.FindDataTemplateAllDifficulties(IterateTemplate.DataName, DataTemplates);
            foreach DataTemplates(DataTemplate)
            {
                CDO.CallModifyTemplateFn(ModifyTemplateFn, DataTemplate);
            }
        }
    }
    else if (ClassIsChildOf(TemplateClass, class'X2StrategyElementTemplate'))
    {
        CDO = GetCDO();
        StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
        foreach StratMgr.IterateTemplates(IterateTemplate)
        {
            if (!ClassIsChildOf(IterateTemplate.Class, TemplateClass)) continue;

            StratMgr.FindDataTemplateAllDifficulties(IterateTemplate.DataName, DataTemplates);
            foreach DataTemplates(DataTemplate)
            {
                CDO.CallModifyTemplateFn(ModifyTemplateFn, DataTemplate);
            }
        }
    }
    else if (ClassIsChildOf(TemplateClass, class'X2SoldierClassTemplate'))
    {

        CDO = GetCDO();
        ClassMgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
        foreach ClassMgr.IterateTemplates(IterateTemplate)
        {
            if (!ClassIsChildOf(IterateTemplate.Class, TemplateClass)) continue;

            ClassMgr.FindDataTemplateAllDifficulties(IterateTemplate.DataName, DataTemplates);
            foreach DataTemplates(DataTemplate)
            {
                CDO.CallModifyTemplateFn(ModifyTemplateFn, DataTemplate);
            }
        }
    }    
}

static private function ModifyTemplateAllDiff(name TemplateName, class TemplateClass, delegate<ModifyTemplate> ModifyTemplateFn)
{
    local X2DataTemplate                                    DataTemplate;
    local array<X2DataTemplate>                             DataTemplates;
    local X2DownloadableContentInfo_XComGearsPerkPack    CDO;

    local X2ItemTemplateManager             ItemMgr;
    local X2AbilityTemplateManager          AbilityMgr;
    local X2CharacterTemplateManager        CharMgr;
    local X2StrategyElementTemplateManager  StratMgr;
    local X2SoldierClassTemplateManager     ClassMgr;

    if (ClassIsChildOf(TemplateClass, class'X2ItemTemplate'))
    {
        ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
        ItemMgr.FindDataTemplateAllDifficulties(TemplateName, DataTemplates);
    }
    else if (ClassIsChildOf(TemplateClass, class'X2AbilityTemplate'))
    {
        AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
        AbilityMgr.FindDataTemplateAllDifficulties(TemplateName, DataTemplates);
    }
    else if (ClassIsChildOf(TemplateClass, class'X2CharacterTemplate'))
    {
        CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
        CharMgr.FindDataTemplateAllDifficulties(TemplateName, DataTemplates);
    }
    else if (ClassIsChildOf(TemplateClass, class'X2StrategyElementTemplate'))
    {
        StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
        StratMgr.FindDataTemplateAllDifficulties(TemplateName, DataTemplates);
    }
    else if (ClassIsChildOf(TemplateClass, class'X2SoldierClassTemplate'))
    {
        ClassMgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
        ClassMgr.FindDataTemplateAllDifficulties(TemplateName, DataTemplates);
    }
    else return;

    CDO = GetCDO();
    foreach DataTemplates(DataTemplate)
    {
        CDO.CallModifyTemplateFn(ModifyTemplateFn, DataTemplate);
    }
}

static private function X2DownloadableContentInfo_XComGearsPerkPack GetCDO()
{
    return X2DownloadableContentInfo_XComGearsPerkPack(class'XComEngine'.static.GetClassDefaultObjectByName(default.Class.Name));
}

protected function CallModifyTemplateFn(delegate<ModifyTemplate> ModifyTemplateFn, X2DataTemplate DataTemplate)
{
    ModifyTemplateFn(DataTemplate);
}



///////////////////////////////////////////////////////////////////////////////////////////////////////////
exec function PlayTestXComGears()
{
}
