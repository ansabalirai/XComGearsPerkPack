class X2Effect_Leech extends X2Effect_Persistent;

var name UnitValueToRead;
var localized string HealedMessage;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));


	EventMgr.RegisterForEvent(EffectObj, 'UnitTakeEffectDamage', LeechListener, ELD_OnStateSubmitted,,,, EffectObj);
    EventMgr.RegisterForEvent(EffectObj, 'TriggerLeechFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
    

}

static function EventListenerReturn LeechListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local XComGameState_Unit AbilityOwnerUnit, TargetUnit, SourceUnit;
	local int DamageDealt, DmgIdx;
	local float StolenHP;
    local XComGameState_Effect			EffectState;
	local XComGameState_Ability AbilityState, InputAbilityState;
	local X2TacticalGameRuleset Ruleset;
    local XComGameState_Item    SourceWeapon;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
    EffectState = XComGameState_Effect(CallbackData);

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	InputAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

    if (AbilityState == none || InputAbilityState == none)
    {
        return ELR_NoInterrupt;
    }
    
	if (AbilityContext != none && AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
	{
		Ruleset = `TACTICALRULES;
		TargetUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
		SourceUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
        SourceWeapon = XComGameState_Item(GameState.GetGameStateForObjectID(AbilityState.SourceWeapon.ObjectID));

        if (TargetUnit == none || SourceUnit == none || !TargetUnit.IsEnemyUnit(SourceUnit))
        {
            return ELR_NoInterrupt;
        }

		if (TargetUnit != none)
		{

            if(AbilityState.OwnerStateObject.ObjectID == EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID) // Check if we need weapon specific check here
            {
                for (DmgIdx = 0; DmgIdx < TargetUnit.DamageResults.Length; ++DmgIdx)
                {
                    if (TargetUnit.DamageResults[DmgIdx].Context == AbilityContext)
                    {
                        DamageDealt += TargetUnit.DamageResults[DmgIdx].DamageAmount;
                    }
                }

                `log("Source Weapon is " $ SourceWeapon.GetMyTemplateName());
                if (DamageDealt > 0)
                {
                    StolenHP = int(float(DamageDealt) * GetLifeStealMod(EffectState, GameState));
                    if (StolenHP > 0)
                    {
                        SourceUnit.ModifyCurrentStat(eStat_HP, StolenHP);
                        `log(SourceUnit.GetFullName() $ "healed by " $ StolenHP);
                        `XEVENTMGR.TriggerEvent('TriggerLeechFlyover', AbilityState, SourceUnit, GameState);

                    }
                }
            }
			
		}
	}

	return ELR_NoInterrupt;
}

static function float GetLifeStealMod (XComGameState_Effect EffectState, XComGameState GameState)
{
    local XComGameState_Unit AbilityOwnerUnit;

    AbilityOwnerUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

    `log("Unit that applied the Rally effect is " $ AbilityOwnerUnit.GetMyTemplateName());

    if (AbilityOwnerUnit.HasSoldierAbility('Rally_II'))
    {
        return 0.4;
    }
    else
        return 0.25;


}