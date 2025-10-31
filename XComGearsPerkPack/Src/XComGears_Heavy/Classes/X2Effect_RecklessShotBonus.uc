class X2Effect_RecklessShotBonus extends X2Effect_Persistent;


function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
    local int Tiles, CurrentStacks;
    local XComGameState_Item SourceWeapon;
    local X2WeaponTemplate WeaponTemplate;
    local ShotModifierInfo ShotInfo;
    local UnitValue CurrentAnchorStacks;

    SourceWeapon = AbilityState.GetSourceWeapon();
    if (SourceWeapon != none && Target != none)
	{
        if (AbilityState.GetMyTemplateName() == 'RecklessShot_I')
        {
            if (Attacker.HasSoldierAbility('RecklessShot_III') && Attacker.HasSoldierAbility('RecklessShot_II'))
            {
                ShotInfo.Value = class'X2Ability_GearsHeavyAbilitySet'.default.RecklessShotCritBonusIII;
                ShotInfo.ModType = eHit_Crit;
                ShotInfo.Reason = "Reckless Shot III";
                ShotModifiers.AddItem(ShotInfo);
            }

            else if (Attacker.HasSoldierAbility('RecklessShot_II'))
            {
                ShotInfo.Value = class'X2Ability_GearsHeavyAbilitySet'.default.RecklessShotCritBonusII;
                ShotInfo.ModType = eHit_Crit;
                ShotInfo.Reason = "Reckless Shot II";
                ShotModifiers.AddItem(ShotInfo);
            }

            else
            {
                ShotInfo.Value = class'X2Ability_GearsHeavyAbilitySet'.default.RecklessShotCritBonusI;
                ShotInfo.ModType = eHit_Crit;
                ShotInfo.Reason = "Reckless Shot I";
                ShotModifiers.AddItem(ShotInfo);
            }            
        }
    }

}