class X2Effect_BreachTarget extends X2Effect_Persistent;

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{

	local XComGameStateHistory					History;
	local XComGameState_Unit					TargetUnit, PrevTargetUnit;
	local X2AbilityTemplateManager				AbilityTemplateMgr;
	local X2AbilityTemplate						AbilityTemplate, FlyoverTemplate;
	local X2WeaponTemplate						WeaponTemplate;
	local bool									bLightWeapon, bLog;
	local bool									bGrantMovePoint, bGrantActionPoint;
	local UnitValue								TrackerUnitValue, RangeUnitValue;
	local string								sMessageBridge;
	local X2EventManager						EventManager;
	local XComGameState_Effect					RemoveEffectState;
	local XComGameStateContext_EffectRemoved	RemoveEffectContext;
	local XComGameState_Ability					AbilityState;

	// Require the unit to have some action points before activating the ability (prevents triggering on overwatch or reaction attacks)
	if (PreCostActionPoints.Length == 0)
		return false;
	

	// Get Target's XComGameState_Unit
	History = `XCOMHISTORY;
	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	PrevTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnit.ObjectID));

	// Get the triggering ability template
	AbilityTemplateMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateMgr.FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

	// Get the triggering source weapon
	WeaponTemplate = X2WeaponTemplate(XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID)).GetMyTemplate());

    if (TargetUnit != none && 
    (TargetUnit.AffectedbyEffectNames.Find('BreachTarget') != INDEX_NONE) &&
    TargetUnit.IsDead())
	{


        //  restore the pre cost action points to fully refund this action
        if ((SourceUnit.AffectedbyEffectNames.Find('BreachSource') != INDEX_NONE) &&
        SourceUnit.ActionPoints.Length != PreCostActionPoints.Length)
        {
            AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
            if (AbilityState != none)
            {
                SourceUnit.ActionPoints = PreCostActionPoints;
                return true;
            }
        }

    }

    return false;

}
