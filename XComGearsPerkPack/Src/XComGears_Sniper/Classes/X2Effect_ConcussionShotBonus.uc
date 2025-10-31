class X2Effect_ConcussionShotBonus extends X2Effect_Persistent;

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
    local int Tiles, AimBonusMultiplier;
    local XComGameState_Item SourceWeapon;
    local X2WeaponTemplate WeaponTemplate;
    local ShotModifierInfo ShotInfo;
    local UnitValue CurrentAnchorStacks;

    if (Target != none )
    {
        if (AbilityState.GetMyTemplateName() == 'ConcussionShot_I')
        {
            if (Attacker.HasSoldierAbility('ConcussionShot_II'))
            {
                AimBonusMultiplier = 2;
            }



            else
                AimBonusMultiplier = 0;
            
            ShotInfo.Value = 10 * AimBonusMultiplier;
            ShotInfo.ModType = eHit_Success;
            ShotInfo.Reason = "Concussion Shot II";
            ShotModifiers.AddItem(ShotInfo);
        }
        
    }



}
