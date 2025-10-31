class X2Effect_BattlefieldMedic extends X2Effect_Persistent;

var float MediVac_HP_Threshold;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{

	local Object EffectObj;

	EffectObj = EffectGameState;

	// Remove the default UnitRemovedFromPlay registered by XComGameState_Effect. This is necessary so we can suppress
	// the usual behavior of the effects being removed when a unit evacs. We need to wait until the mission ends and then
	// process the Medivac ability.
	`XEVENTMGR.UnRegisterFromEvent(EffectObj, 'UnitRemovedFromPlay');
}


function int ApplyMedivacHealing(XComGameState_Effect EffectState, XComGameState_Unit OrigUnitState, XComGameState NewGameState)
{

	local XComGameStateHistory		History;
	local XComGameState_Unit		TargetUnit, PrevTargetUnit, SourceUnit;
	local bool						bLog;

	bLog = TRUE;

	History = `XCOMHISTORY;
	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	if(!BattlefieldMedicEffectIsValidForSource(SourceUnit)) { return 0; }

	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(OrigUnitState.ObjectID));
	if (TargetUnit == none)
	{
		TargetUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', OrigUnitState.ObjectID));
		NewGameState.AddStateObject(TargetUnit);
	}

	if (TargetUnit.IsRobotic()) { return 0; }
	if(!(TargetUnit.LowestHP < TargetUnit.HighestHP && TargetUnit.LowestHP > 0)) { return 0; }

	PrevTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnit.ObjectID));
	
	`Log("WOTC_APA_Medic - Medivac: Beginning HP checks for " $ PrevTargetUnit.GetFullName(), bLog);
	`Log("WOTC_APA_Medic - Medivac:" $ PrevTargetUnit.GetFullName() $ "'s current LowestHP/HighestHP: " $ PrevTargetUnit.LowestHP $ "/" $ PrevTargetUnit.HighestHP, bLog);
	`Log("WOTC_APA_Medic - Medivac:" $ PrevTargetUnit.GetFullName() $ "'s LowestHP cap for Medivac to apply: " $ int(PrevTargetUnit.HighestHP * MediVac_HP_Threshold), bLog);

	// Check that the target's LowestHP value is below the %-cap threshold
	if (PrevTargetUnit.LowestHP < Round(PrevTargetUnit.HighestHP * MediVac_HP_Threshold))
	{
		TargetUnit.LowestHP = Round(PrevTargetUnit.HighestHP * MediVac_HP_Threshold);
		TargetUnit.ModifyCurrentStat(eStat_HP, (TargetUnit.LowestHP - TargetUnit.GetCurrentStat(eStat_HP)));
	    `Log("WOTC_APA_Medic - Medivac:" $ PrevTargetUnit.GetFullName() $ "'s LowestHP set to: " $ int(PrevTargetUnit.HighestHP * MediVac_HP_Threshold), bLog);
		super.UnitEndedTacticalPlay(EffectState, TargetUnit);
		return 1;
	}

	// If the target's LowestHP is the minimum of 1 and their HighestHP is too low to be eligible for boosts, give the minimum 1 HP boost
	if (PrevTargetUnit.LowestHP == 1)
	{
		TargetUnit.LowestHP += 1;
		TargetUnit.ModifyCurrentStat(eStat_HP, 1);
	    `Log("WOTC_APA_Medic - Medivac:" $ PrevTargetUnit.GetFullName() $ "'s LowestHP set to: 2 (Minimum boost applied - Target's total HP too low to qualify normally)", bLog);
		super.UnitEndedTacticalPlay(EffectState, TargetUnit);
		return 1;
	}

	return 0;
}

function bool BattlefieldMedicEffectIsValidForSource(XComGameState_Unit SourceUnit)
{
	if(SourceUnit == none) { return false; }
	if(SourceUnit.IsDead()) { return false; }
	if(SourceUnit.bCaptured) { return false; }
	if(SourceUnit.LowestHP == 0) { return false; }
	// These two checks do nothing, as these effects are cleared at this point. However, as perk description
	// does not describe this requirement in the first place fixing these checks might nt be necessary.
	if(SourceUnit.IsBleedingOut()) { return false; }
	if(SourceUnit.IsUnconscious()) { return false; }
	return true;
}

DefaultProperties
{
	EffectName="X2Effect_BattlefieldMedic"
	DuplicateResponse=eDupe_Ignore
}