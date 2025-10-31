class X2Effect_SelfRevive extends X2Effect_Persistent;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit	TargetUnit;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	
	if (TargetUnit.IsBleedingOut() || TargetUnit.IsUnconscious())
	{
		VisualizationFn = class'X2StatusEffects'.static.UnconsciousVisualizationRemoved;
	}
}


// function RegisterForEvents(XComGameState_Effect EffectGameState)
// {
// 	local X2EventManager EventMgr;
// 	local Object EffectObj;
// 	local XComGameState_Unit EffectTargetUnit;

// 	EventMgr = `XEVENTMGR;
// 	EffectObj = EffectGameState;
// 	EffectTargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

// 	EventMgr.RegisterForEvent(EffectObj, 'UnitBleedingOut', OnUnitBleedingOut, ELD_OnStateSubmitted, , EffectTargetUnit);
// 	EventMgr.RegisterForEvent(EffectObj, 'PlayerTurnBegun', OnUnitBleedingOut, ELD_OnStateSubmitted, , EffectTargetUnit);
// }

// static function EventListenerReturn OnUnitBleedingOut(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
// {
// 	local XComGameState_Unit UnitState;
// 	local XComGameState_Effect BleedOutEffect;
// 	local  UnitValue BleedoutReviveUV;

// 	UnitState = XComGameState_Unit(EventData);
	
// 	BleedOutEffect = UnitState.GetUnitAffectedByEffectState(class'X2StatusEffects'.default.BleedingOutName);
// 	BleedOutEffect = XComGameState_Effect(GameState.GetGameStateForObjectID(BleedOutEffect.ObjectID));

// 	if (UnitState.GetUnitValue('BleedingOutReadyToRevive', BleedoutReviveUV))
// 	{
// 		`Log("Unit bleeding out ready to revive value is currently " $ BleedoutReviveUV.fValue);
// 	}

// 	if( BleedOutEffect != none && BleedOutEffect.iTurnsRemaining < class'X2StatusEffects'.default.BLEEDINGOUT_TURNS)
// 	{
// 		UnitState.SetUnitFloatValue('BleedingOutReadyToRevive', 1, eCleanup_BeginTactical);
// 		`Log("Unit bleeding out ready to revive value set");
// 	}

// 	return ELR_NoInterrupt;
// }