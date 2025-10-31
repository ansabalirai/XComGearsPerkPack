class X2Effect_Badass extends X2Effect_Persistent;

var float DamageReductionMod;
var int     NumOfShotsShruggedOff;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', IncomingShotCheck, ELD_OnStateSubmitted,,,, EffectObj);
	EventMgr.RegisterForEvent(EffectObj, 'TriggerBadassFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
}

static function EventListenerReturn IncomingShotCheck(Object EventData, Object EventSource, XComGameState GameState, name EventID, Object CallbackData)
{
	local XComGameState_Unit			AttackingUnit, DefendingUnit, OwnerUnit;
	local XComGameState_Ability			ActivatedAbilityState;
	local XComGameState_Ability			LightningReflexesAbilityState;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Effect			EffectState;
	local UnitValue						BadassCounterValue;
	local X2AbilityToHitCalc_StandardAim 	StandardAim;

	EffectState = XComGameState_Effect(CallbackData);
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	LightningReflexesAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	DefendingUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	OwnerUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));	
	if (DefendingUnit != none)
	{
		if (DefendingUnit.HasSoldierAbility('Badass') 
        && !DefendingUnit.IsImpaired(false) && !DefendingUnit.IsBurning() && !DefendingUnit.IsPanicked() 
        && DefendingUnit.ObjectID == OwnerUnit.ObjectID)
		{
			AttackingUnit = class'X2TacticalGameRulesetDataStructures'.static.GetAttackingUnitState(GameState);
			if(AttackingUnit != none && AttackingUnit.IsEnemyUnit(DefendingUnit))
			{
				ActivatedAbilityState = XComGameState_Ability(EventData);
				if (ActivatedAbilityState != none)
				{
					StandardAim = X2AbilityToHitCalc_StandardAim(ActivatedAbilityState.GetMyTemplate().AbilityToHitCalc);
					if (StandardAim != none && !(StandardAim.bReactionFire) && !(StandardAim.bIndirectFire) && !(StandardAim.bMultiTargetOnly))
					{
						// Update the Lightning Reflexes counter
						DefendingUnit.GetUnitValue('BadassShotsCounter', BadassCounterValue);
                        //`Log ("Badass UnitValue currently is:" @ string(BadassCounterValue.fValue));
						DefendingUnit.SetUnitFloatValue ('BadassShotsCounter', BadassCounterValue.fValue + 1, eCleanup_BeginTurn);
						//`Log ("Badass TRIGGERING with new UnitValue at :" @ string(BadassCounterValue.fValue));

						// Send event to trigger the flyover, but only for the first shot
						if (BadassCounterValue.fValue == 0)
						{
							`XEVENTMGR.TriggerEvent('TriggerBadassFlyover', LightningReflexesAbilityState, DefendingUnit, GameState);
						}
					}
				}
			}
		}	
	}
	return ELR_NoInterrupt;
}



// Damage Reduction when shot through full cover
function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState)
{
	local XComGameState_Unit				TargetUnit;
    local X2AbilityToHitCalc_StandardAim    Aim;
	local int 								DamageMod;
    local UnitValue                         BadassCounterValue;

    TargetUnit = XComGameState_Unit(TargetDamageable);

    if (TargetUnit.IsImpaired(false) || TargetUnit.IsBurning() || TargetUnit.IsPanicked())
	    return 0;
	
    TargetUnit.GetUnitValue('BadassShotsCounter', BadassCounterValue);

    Aim = X2AbilityToHitCalc_StandardAim(AbilityState.GetMyTemplate().AbilityToHitCalc);

    if (Aim != none && !(Aim.bReactionFire) && !(Aim.bIndirectFire) && !(Aim.bMultiTargetOnly))
	{
        
		if ((int(BadassCounterValue.fValue) <= NumOfShotsShruggedOff) && CurrentDamage > 0)
		{
			DamageMod = -int(float(CurrentDamage) * DamageReductionMod);
		}
	}


	return DamageMod;
}
