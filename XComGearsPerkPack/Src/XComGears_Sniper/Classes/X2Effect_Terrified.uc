class X2Effect_Terrified extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'KillMail', OnTerrifiedKill, ELD_OnStateSubmitted,,,, EffectGameState);
	EventMgr.RegisterForEvent(EffectObj, 'TerrifiedFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
}

static function EventListenerReturn OnTerrifiedKill(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit DeadUnit, SourceUnit;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameState_Item SourceWeapon;
	local XComGameState_Effect EffectState;
	local XComGameState_Ability TerrifiedAbility;
	local name AbilityToTrigger;

	DeadUnit = XComGameState_Unit(EventData);
	SourceUnit = XComGameState_Unit(EventSource);
	EffectState = XComGameState_Effect(CallbackData);

	if (DeadUnit == none || SourceUnit == none || EffectState == none)
	{
		return ELR_NoInterrupt;
	}

	if (!SourceUnit.HasSoldierAbility('Terrified'))
	{
		return ELR_NoInterrupt;
	}

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none)
	{
		return ELR_NoInterrupt;
	}

	if (AbilityContext.InputContext.SourceObject.ObjectID != SourceUnit.ObjectID)
	{
		return ELR_NoInterrupt;
	}

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	if (AbilityState == none)
	{
		return ELR_NoInterrupt;
	}

	SourceWeapon = AbilityState.GetSourceWeapon();
	if (SourceWeapon == none || SourceWeapon.InventorySlot != eInvSlot_PrimaryWeapon)
	{
		return ELR_NoInterrupt;
	}

	if (!DeadUnit.IsDead() || !DeadUnit.IsEnemyUnit(SourceUnit))
	{
		return ELR_NoInterrupt;
	}

	if (AbilityContext.ResultContext.HitResult == eHit_Crit)
	{
		AbilityToTrigger = 'TerrifiedApply_Panic';
	}
	else
	{
		AbilityToTrigger = 'TerrifiedApply';
	}

	if (class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(SourceUnit.GetReference(), AbilityToTrigger, DeadUnit.GetReference()))
	{
		TerrifiedAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		if (TerrifiedAbility != none)
		{
			`XEVENTMGR.TriggerEvent('TerrifiedFlyover', TerrifiedAbility, SourceUnit, GameState);
		}
	}

	return ELR_NoInterrupt;
}

DefaultProperties
{
	bDisplayInSpecialDamageMessageUI = false
}
