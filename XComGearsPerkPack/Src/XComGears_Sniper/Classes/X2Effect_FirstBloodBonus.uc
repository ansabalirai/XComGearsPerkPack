class X2Effect_FirstBloodBonus extends X2Effect_Persistent;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local XComGameState_Unit    Target;
    local float                 ExtraDamage;

    Target = XComGameState_Unit(TargetDamageable);

    if (class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult))
	{
        if (CurrentDamage > 0 && Target != none && (Target.GetCurrentStat(eStat_HP) == Target.GetMaxStat(eStat_HP)) && AbilityState.GetMyTemplateName() == 'FirstBlood_I')
        {
            if (AppliedData.AbilityResultContext.HitResult == eHit_Crit)
                return 0;
                
            if (AppliedData.AbilityResultContext.HitResult == eHit_Success)
            {
                if (Attacker.HasSoldierAbility('FirstBlood_III') && Attacker.HasSoldierAbility('FirstBlood_II'))
                {
                    return max(1,int(CurrentDamage*0.75));
                }

                if (Attacker.HasSoldierAbility('FirstBlood_II'))
                {
                    return max(1,int(CurrentDamage*0.5));
                }

                return max(1,int(CurrentDamage*0.25));
            }
        }
    }
    return 0;


}

defaultproperties
{
	bDisplayInSpecialDamageMessageUI = true
}