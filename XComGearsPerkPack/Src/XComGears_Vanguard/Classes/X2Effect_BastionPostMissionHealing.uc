class X2Effect_BastionPostMissionHealing extends X2Effect_Persistent;


var int HpToBeHealed;
var name UnitBleedingOut;


function RegisterForEvents(XComGameState_Effect EffectGameState)
{
    local Object EffectObj;

    EffectObj = EffectGameState;

    // Remove the default UnitRemovedFromPlay registered by XComGameState_Effect. This is necessary so we can
    // suppress the usual behavior of the effects being removed when a unit evacs. We can't process field surgeon
    // at that time because we could evac a wounded unit and then have the surgeon get killed on a later turn. We
    // need to wait until the mission ends and then process FS.
    `XEVENTMGR.UnRegisterFromEvent(EffectObj, 'UnitRemovedFromPlay');
    	// Because bleeding out status will be cleared at the CleanupTacticalMission point we have to record
	// that unit was bleeding out at some point during the mission.
	//`XEVENTMGR.RegisterForEvent(EffectObj, 'UnitBleedingOut', OnUnitBleedingOut, ELD_OnStateSubmitted, ,,, EffectObj);
}

function ApplyBastionPostMissionHealing(XComGameState_Effect EffectState, XComGameState_Unit OrigUnitState, XComGameState NewGameState)
{
    local XComGameState_Unit        SourceUnitState, UnitState;
    local int                       NumEffects;
    local UnitValue                 AppliedFSValue;
    local bool                      bApplyFieldSurgeon;
    local Int                       MissingHP, ToBeHealedHP, tempHP;

    UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(OrigUnitState.ObjectID));
    if (UnitState == none)
    {
        UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', OrigUnitState.ObjectID));
        NewGameState.AddStateObject(UnitState);
    }

    SourceUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
    `LOG("Field Surgeon: TargetUnit=" $ UnitState.GetFullName() $ ", SourceUnit=" $ SourceUnitState.GetFullName());

    if(!FieldSurgeonEffectIsValidForSource(SourceUnitState)) { return; }

    `LOG("Field Surgeon: Source Unit Valid.");

    if(UnitState == none) { return; }
    if(UnitState.IsDead()) { return; }
    if(UnitState.IsBleedingOut()) { return; }
    if(!CanBeHealed(UnitState)) { return; }

    
    //`LOG("Field Surgeon: ApplyFieldSurgeon=" $ bApplyFieldSurgeon);


    MissingHP = UnitState.HighestHP - UnitState.LowestHP;

    if (MissingHP > 0)
    {
        `LOG("Field Surgeon: Target Unit Can Be Healed.");
        ToBeHealedHP = min(HpToBeHealed, MissingHP);
        
        `LOG("Field Surgeon : Current HP =" $ UnitState.GetCurrentStat(eStat_HP));
        `LOG("Field Surgeon : Pre update LowestHP=" $ UnitState.LowestHP);
        UnitState.LowestHP = min(UnitState.LowestHP + ToBeHealedHP, UnitState.HighestHP);
        `LOG("Field Surgeon : Post update LowestHP=" $ UnitState.LowestHP);

        // Armor HP may have already been removed, apparently healing the unit since we have not yet
        // executed EndTacticalHealthMod. We may only appear injured here for large injuries (or little
        // armor HP). Current HP is used in the EndTacticalHealthMod adjustment, so we should increase it
        // if it's less than the max, but don't exceed the max HP.
        if ((UnitState.GetCurrentStat(eStat_HP))  < UnitState.HighestHP)
        {
            TempHp = UnitState.HighestHP - UnitState.GetCurrentStat(eStat_HP);
            UnitState.ModifyCurrentStat(eStat_HP, min(ToBeHealedHP, tempHP));
        }
    }    
    //UnitState.SetUnitFloatValue(default.FieldSurgeonAppliedUnitValue, AppliedFSValue.fValue + 1, eCleanup_BeginTactical);
}




function bool CanBeHealed(XComGameState_Unit UnitState)
{
    // Note: Only test lowest/highest HP here: CurrentHP cannot be trusted in UnitEndedTacticalPlay because
    // armor HP may have already been removed, but we have not yet invoked the EndTacticalHealthMod adjustment.
     return (UnitState.LowestHP < UnitState.HighestHP && UnitState.LowestHP > 0);
}

function bool FieldSurgeonEffectIsValidForSource(XComGameState_Unit SourceUnit)
{
    if(SourceUnit == none) { return false; }
    if(SourceUnit.IsDead()) { return false; }
    if(SourceUnit.IsBleedingOut()) { return false; }
    if(SourceUnit.bCaptured) { return false; }
    if(SourceUnit.LowestHP == 0) { return false; }
    if(SourceUnit.IsUnconscious()) { return false; }
    return true;
}


static function EventListenerReturn OnUnitBleedingOut(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Effect EffectState;
	local XComGameState_Unit UnitState;

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == None) {
		return ELR_NoInterrupt;
	}

	UnitState = XComGameState_Unit(EventData);
	if (UnitState == None) {
		return ELR_NoInterrupt;
	}

	if (UnitState.ObjectID != EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID)
	{
		return ELR_NoInterrupt;
	}

	if (EventID == 'UnitBleedingOut' && UnitState.IsBleedingOut() && UnitState.GetBleedingOutTurnsRemaining() > 0)
	{
		UnitState.SetUnitFloatValue(default.UnitBleedingOut, 1, eCleanup_BeginTactical);
	}
	return ELR_NoInterrupt;
}


DefaultProperties
{
    EffectName="BastionPostMissionHealing"
    DuplicateResponse=eDupe_Allow
    UnitBleedingOut="BastionUnitBleedingOut"
}
