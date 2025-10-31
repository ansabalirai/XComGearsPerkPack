class X2Effect_AlphaOmega extends X2Effect_Persistent;

var name ApplyTo;
var float BonusDamagePercent;
var float EnergizedCritBonus;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local float ExtraDamage;
	local XComGameState_Unit TargetUnit;
    local XComGameState_Item SourceWeapon;
    local int CurrentAmmo;

	TargetUnit = XComGameState_Unit(TargetDamageable);

	if (TargetUnit != none && CurrentDamage > 0)
	{
        SourceWeapon = AbilityState.GetSourceWeapon();
        if ( AbilityState.SourceWeapon == EffectState.ApplyEffectParameters.ItemStateObjectRef && CurrentDamage > 0 && 
        (Attacker.HasSoldierAbility('Alpha') || Attacker.HasSoldierAbility('Omega')))
        {
            //`log("Source Weapon clip size is " $ SourceWeapon.GetClipSize());
            CurrentAmmo = SourceWeapon.Ammo;
            if ( ApplyTo == 'FirstShot' && CurrentAmmo == SourceWeapon.GetClipSize())
            {
                return max(1, int(CurrentDamage * 0.01*BonusDamagePercent));
            }

            if ( ApplyTo == 'LastShot' && CurrentAmmo ==  1)
            {
                return max(1, int(CurrentDamage * 0.01*BonusDamagePercent));
            }

        }	
	}
    
	return 0;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
    local int CurrentAmmo, CritBonus;
    local XComGameState_Item SourceWeapon;
    local X2WeaponTemplate WeaponTemplate;
    local ShotModifierInfo ShotInfo;
    local UnitValue CurrentAnchorStacks;


    if (Target != none && !(bMelee || bIndirectFire)) // Maybe need to check primary weapon as well?
    {

        if (Attacker.HasSoldierAbility('Energized'))
        {
            SourceWeapon = AbilityState.GetSourceWeapon();
            if (SourceWeapon != none && SourceWeapon.Ammo == SourceWeapon.GetClipSize())
            {
                CritBonus = EnergizedCritBonus;
            }
        }
        
        ShotInfo.Value = CritBonus;
        ShotInfo.ModType = eHit_Crit;
        ShotInfo.Reason = "Energized";
        ShotModifiers.AddItem(ShotInfo);
    }
}