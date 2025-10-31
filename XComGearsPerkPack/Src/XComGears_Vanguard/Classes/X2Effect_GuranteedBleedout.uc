///---------------------------------------------------------------------------------------
//  FILE:    X2Effect_GuranteedBleedout.uc
//  AUTHOR:  Rai / Amineri (Pavonis Interactive)
//  PURPOSE: Implements EmergencyLifeSupport, auto-succeeds at first bleedout roll
//--------------------------------------------------------------------------------------- 
class X2Effect_GuranteedBleedout extends X2Effect_Persistent;


var protectedwrite name ELSDeathUsed;
var protectedwrite name ELSStabilizeUsed;


function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit)
{
	local bool Relevant;
	local UnitValue ELSValue;

	Relevant = false;

	if (TargetUnit.GetUnitValue('BleedingOutReadyToRevive', ELSValue))
	{
		if (ELSValue.fValue > 0)
			Relevant = true;
	}
	if (TargetUnit.GetUnitValue(default.ELSDeathUsed, ELSValue))
	{
		if (ELSValue.fValue == 0)
			Relevant = true;
	}
	return Relevant;
}




function bool PreDeathCheck(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState)
{
	local UnitValue ELSValue;

	`Log("EmergencyLifeSupport: Starting PreDeath Check.");

	if (UnitState.GetUnitValue(default.ELSDeathUsed, ELSValue))
	{
		if (ELSValue.fValue > 0)
		{
			`Log("EmergencyLifeSupport: Already used, failing.");
			return false;
		}
	}
	`Log("EmergencyLifeSupport: Triggered, setting unit value.");
	UnitState.SetUnitFloatValue(default.ELSDeathUsed, 1, eCleanup_BeginTactical);
	if (ApplyBleedingOut(UnitState, NewGameState ))
	{
		`Log("EmergencyLifeSupport: Successfully applied bleeding-out.");
		UnitState.LowestHP = 1; // makes wound times correct if ELS gets used
		return true;
	}
	`REDSCREEN("EmergencyLifeSupport : Unit" @ UnitState.GetFullName() @ "should have bled out but ApplyBleedingOut failed. Killing it instead.");

	return false;
}

function bool ApplyBleedingOut(XComGameState_Unit UnitState, XComGameState NewGameState)
{
	local EffectAppliedData ApplyData;
	local X2Effect BleedOutEffect;

	if (NewGameState != none)
	{
		BleedOutEffect = GetBleedOutEffect();
		ApplyData.PlayerStateObjectRef = UnitState.ControllingPlayer;
		ApplyData.SourceStateObjectRef = UnitState.GetReference();
		ApplyData.TargetStateObjectRef = UnitState.GetReference();
		ApplyData.EffectRef.LookupType = TELT_BleedOutEffect;
		if (BleedOutEffect.ApplyEffect(ApplyData, UnitState, NewGameState) == 'AA_Success')
		{
			`Log("Emergency Life Support : Triggered ApplyBleedingOut.");
			return true;
		}
	}
	return false;
}

DefaultProperties
{
	EffectName = "EmergencyLifeSupport"
	ELSDeathUsed = "EmergencyLifeSupportDeathUsed"
	ELSStabilizeUsed = "EmergencyLifeSupportStabilizeUsed"
}