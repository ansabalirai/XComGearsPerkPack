class X2Effect_PrecisionShotBonus extends X2Effect_Persistent;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local XComGameState_Unit    Target;

    Target = XComGameState_Unit(TargetDamageable);

    if (Target != none && CurrentDamage > 0)
    {
        if (AbilityState.GetMyTemplateName() == 'XGT_PrecisionShot_I' && (AppliedData.AbilityResultContext.HitResult == eHit_Crit))
        {
            if (Attacker.HasSoldierAbility('XGT_PrecisionShot_III') && Attacker.HasSoldierAbility('XGT_PrecisionShot_II'))
            {
                return max(1,int(CurrentDamage*0.5));
            }

            if (Attacker.HasSoldierAbility('XGT_PrecisionShot_II'))
            {
                return max(1,int(CurrentDamage*0.4));
            }

            return max(1,int(CurrentDamage*0.3));
        }
    }
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
    local int Tiles, AimBonusMultiplier;
    local XComGameState_Item SourceWeapon;
    local X2WeaponTemplate WeaponTemplate;
    local ShotModifierInfo ShotInfo;
    local UnitValue CurrentAnchorStacks;

    if (Target != none )
    {
        if (AbilityState.GetMyTemplateName() == 'XGT_PrecisionShot_I')
        {
            if (Attacker.HasSoldierAbility('XGT_PrecisionShot_III') && Attacker.HasSoldierAbility('XGT_PrecisionShot_II'))
            {
                AimBonusMultiplier = 5;
            }

            else if (Attacker.HasSoldierAbility('XGT_PrecisionShot_II'))
            {
                AimBonusMultiplier = 4;
            }

            else
                AimBonusMultiplier = 3;
            
            ShotInfo.Value = 10 * AimBonusMultiplier;
            ShotInfo.ModType = eHit_Success;
            ShotInfo.Reason = "Precision Shot";
            ShotModifiers.AddItem(ShotInfo);
        }
        
    }



}
