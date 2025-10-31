
class X2Effect_CriticalHealing extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'LW2WotC_Savior_Triggered', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted, , UnitState);
	EventMgr.RegisterForEvent(EffectObj, 'XpHealDamage', ModifyMedikitHeal, ELD_OnStateSubmitted, 75,,, EffectObj);
}

static function EventListenerReturn ModifyMedikitHeal(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID, Object CallbackData)
{
	local XComGameState_Unit					TargetUnit, SourceUnit, ExpectedSourceUnit;
	local XComGameState_Effect					EffectState;
	local XComGameStateContext_Ability			AbilityContext;
	local X2Effect_CriticalHealing	            Effect;
    local XComGameState_Ability					AbilityState;
	local X2EventManager						EventMgr;

	// Get the Expected SourceUnit
	EffectState = XComGameState_Effect(CallbackData);
	ExpectedSourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
    AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

	// Get the Source and Target Units for the Heal Event
	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());

	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));

	// Check that the SourceUnit is the Expected SourceUnit
	if (ExpectedSourceUnit.ObjectID != SourceUnit.ObjectID)
	{
		return ELR_NoInterrupt;
	}
	
	// Activating extra healing on Target Unit
	//Effect = X2Effect_CriticalHealing(EffectState.GetX2Effect());

	if (`SYNC_RAND_STATIC(100) < 50)
		TargetUnit.ModifyCurrentStat(eStat_HP, 4);

    EventMgr = `XEVENTMGR;
	EventMgr.TriggerEvent('LW2WotC_Savior_Triggered', AbilityState, SourceUnit, NewGameState);

	return ELR_NoInterrupt;
}

defaultproperties
{
    DuplicateResponse=eDupe_Ignore
    EffectName="CriticalHealing";
}