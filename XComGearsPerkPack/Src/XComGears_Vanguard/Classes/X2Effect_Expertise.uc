class X2Effect_Expertise extends X2Effect_Persistent;


function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
    local int Tiles, RangeModifier;
    local XComGameState_Item SourceWeapon;
    local X2WeaponTemplate WeaponTemplate;
    local ShotModifierInfo ShotInfo;

    SourceWeapon = AbilityState.GetSourceWeapon();    
    if(SourceWeapon != none)
    {        
        RangeModifier =  GetWeaponRangeModifier(Attacker, Target, SourceWeapon);
        Tiles = Attacker.TileDistanceBetween(Target);

        if (RangeModifier > 0)
        {
            ShotInfo.Value = 25;
        }
        ShotInfo.ModType = eHit_Crit;
        ShotInfo.Reason = "Expertise";
        ShotModifiers.AddItem(ShotInfo);
    }    
}



function int GetWeaponRangeModifier(XComGameState_Unit Shooter, XComGameState_Unit Target, XComGameState_Item Weapon)
{
	local X2WeaponTemplate WeaponTemplate;
	local int Tiles, Modifier;

	if (Shooter != none && Target != none && Weapon != none)
	{
		WeaponTemplate = X2WeaponTemplate(Weapon.GetMyTemplate());

		if (WeaponTemplate != none)
		{
			Tiles = Shooter.TileDistanceBetween(Target);
			if (WeaponTemplate.RangeAccuracy.Length > 0)
			{
				if (Tiles < WeaponTemplate.RangeAccuracy.Length)
					Modifier = WeaponTemplate.RangeAccuracy[Tiles];
				else  //  if this tile is not configured, use the last configured tile					
					Modifier = WeaponTemplate.RangeAccuracy[WeaponTemplate.RangeAccuracy.Length-1];
			}
		}
	}

	return Modifier;
}

defaultproperties
{
    DuplicateResponse=eDupe_Ignore
    EffectName="Expertise"
}