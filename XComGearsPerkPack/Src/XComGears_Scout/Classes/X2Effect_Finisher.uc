class X2Effect_Finisher extends X2Effect_Persistent;


function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
    local int Tiles, AimBonus, CritBonus;
    local XComGameState_Item SourceWeapon;
    local X2WeaponTemplate WeaponTemplate;
    local ShotModifierInfo ShotInfo;
    local UnitValue CurrentAnchorStacks;

    if (Target != none && Target.GetCurrentStat(eStat_HP) <= Target.GetMaxStat(eStat_HP))
    {
        if (AbilityState.GetMyTemplateName() == 'Finisher_I')
        {
            if (Attacker.HasSoldierAbility('Finisher_II'))
            {
                AimBonus = 50;
                CritBonus = 50;
            }

            else
            {
                AimBonus = 25;
                CritBonus = 25;
            }
            
            ShotInfo.Value = AimBonus;
            ShotInfo.ModType = eHit_Success;
            ShotInfo.Reason = "Finisher";
            ShotModifiers.AddItem(ShotInfo);

            ShotInfo.Value = CritBonus;
            ShotInfo.ModType = eHit_Crit;
            ShotInfo.Reason = "Finisher";
            ShotModifiers.AddItem(ShotInfo);
        }
        
    }



}

defaultproperties
{
    DuplicateResponse=eDupe_Ignore
    EffectName="Finisher"
}