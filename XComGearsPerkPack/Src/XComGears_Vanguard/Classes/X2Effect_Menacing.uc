class X2Effect_Menacing extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
	local XComGameState_Unit UnitState;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'KillMail', OnMenacingKill, ELD_OnStateSubmitted,,,, EffectGameState);
	EventMgr.RegisterForEvent(EffectObj, 'MenacingFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
}

static function EventListenerReturn OnMenacingKill(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit DeadUnit, SourceUnit;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameState_Item SourceWeapon;
	local XComGameState_Effect EffectState;
	local XComGameState_Ability MenacingAbility;
	local name AbilityToTrigger;

	DeadUnit = XComGameState_Unit(EventData);
	SourceUnit = XComGameState_Unit(EventSource);
	EffectState = XComGameState_Effect(CallbackData);

	if (DeadUnit == none || SourceUnit == none || EffectState == none)
	{
		return ELR_NoInterrupt;
	}

	if (!SourceUnit.HasSoldierAbility('Menacing'))
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
		AbilityToTrigger = 'MenacingApply_Panic';
	}
	else
	{
		AbilityToTrigger = 'MenacingApply';
	}

	if (class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(SourceUnit.GetReference(), AbilityToTrigger, DeadUnit.GetReference()))
	{
		MenacingAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		if (MenacingAbility != none)
		{
			`XEVENTMGR.TriggerEvent('MenacingFlyover', MenacingAbility, SourceUnit, GameState);
		}
	}

	return ELR_NoInterrupt;
}
