class MZ_Effect_Duel extends X2Effect_ToHitModifier;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit ControllerState;
	local Object EffectObj;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	ControllerState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	EffectObj = NewEffectState;

	`XEVENTMGR.RegisterForEvent(EffectObj, 'ImpairingEffect', NewEffectState.OnSourceBecameImpaired, ELD_OnStateSubmitted, , ControllerState);
}