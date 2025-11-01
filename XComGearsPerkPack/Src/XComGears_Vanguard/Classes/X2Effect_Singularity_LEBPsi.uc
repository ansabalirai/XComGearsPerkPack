//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_Singularity_LEBPsi
//  AUTHOR:  LeaderEnemyBoss
//  PURPOSE: the big one ...mostly based on Knockback
//--------------------------------------------------------------------------------------- 

class X2Effect_Singularity_LEBPsi extends X2Effect;


/** Used to step the knockback forward along the movement vector until either knock back distance is reached, or there are no more valid tiles*/
var private float IncrementalStepSize;

/** If true, the knocked back unit will cause non fragile destruction ( like kinetic strike ) */
var bool bKnockbackDestroysNonFragile;

var float DefaultDamage;
var float DefaultRadius;

var private vector EndingLocation;
var private array<string> OccupiedTiles;

function name WasTargetPreviouslyDead(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	// A unit that was dead before this game state should not get a knockback, they are already a corpse
	local name AvailableCode;
	local XComGameState_Unit PreviousTargetStateObject;
	local XComGameStateHistory History;


	AvailableCode = 'AA_Success';

	History = `XCOMHISTORY;

	PreviousTargetStateObject = XComGameState_Unit(History.GetGameStateForObjectID(kNewTargetState.ObjectID));
	if( (PreviousTargetStateObject != none) && PreviousTargetStateObject.IsDead() )
	{
		return 'AA_UnitIsDead';
	}

	//`LEBMSG("Applychance:" @AvailableCode);

	return AvailableCode;
}

private function bool CanBeDestroyed(XComInteractiveLevelActor InteractiveActor, float DamageAmount)
{
	//make sure the knockback damage can destroy this actor.
	//check the number of interaction points to prevent larger objects from being destroyed.
	return InteractiveActor != none && DamageAmount >= InteractiveActor.Health && InteractiveActor.InteractionPoints.Length <= 8;
}

//Returns the list of tiles that the unit will pass through as part of the knock back. The last tile in the array is the final destination.
private function GetTilesEnteredArray(XComGameStateContext_Ability AbilityContext, XComGameState_BaseObject kNewTargetState, out array<TTile> OutTilesEntered, out Vector OutAttackDirection, float DamageAmount)
{
	local XComWorldData WorldData;
	local XComGameState_Unit TargetUnit;
	local Vector SourceLocation;
	local Vector TargetLocation;
	local Vector StartLocation;
	local TTile  TempTile, StartTile;
	local TTile  LastTempTile;
	local Vector KnockbackToLocation;	
	local float  StepDistance;
	local Vector TestLocation;
	local float  TestDistanceUnits;
	local TTile  MoveToTile;

	local ActorTraceHitInfo TraceHitInfo;
	local array<ActorTraceHitInfo> Hits;

	local X2AbilityTemplate AbilityTemplate;

	WorldData = `XWORLD;
	//History = `XCOMHISTORY;	
	if(AbilityContext != none)
	{
		AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

		TargetUnit = XComGameState_Unit(kNewTargetState);
		TargetUnit.GetKeystoneVisibilityLocation(TempTile);
		StartTile = TempTile;
		//`LEBMSG("TargetUnit Location:" @TargetUnit.GetFullName() @TempTile.X @TempTile.Y @TempTile.Z);

		TargetLocation = WorldData.GetPositionFromTileCoordinates(TempTile);
		TargetLocation.Z += 120;

		if (AbilityTemplate != none && AbilityTemplate.AbilityTargetStyle.IsA('X2AbilityTarget_Cursor'))
		{
			//attack source is at cursor location
			`assert( AbilityContext.InputContext.TargetLocations.Length > 0 );
			SourceLocation = AbilityContext.InputContext.TargetLocations[0];

			TempTile = WorldData.GetTileCoordinatesFromPosition(SourceLocation);
			//`LEBMSG("Source Location:" @TargetUnit.GetFullName() @TempTile.X @TempTile.Y @TempTile.Z);
			SourceLocation = WorldData.GetPositionFromTileCoordinates(TempTile);

			If (StartTile.X == TempTile.X && StartTile.Y == TempTile.Y) 
			{
				OutTilesEntered.Length = 0;
				OutTilesEntered.AddItem(StartTile);
				return;
			}

			//Need to produce a non-zero vector
			//bCursorTargetFound = (SourceLocation.X != TargetLocation.X || SourceLocation.Y != TargetLocation.Y);
		}

			OutAttackDirection = Normal(SourceLocation - TargetLocation);
			OutAttackDirection.Z = 0.0f;
			StartLocation = TargetLocation;
			KnockbackToLocation = SourceLocation; 

			if (WorldData.GetAllActorsTrace(StartLocation, KnockbackToLocation, Hits))
			{
				foreach Hits(TraceHitInfo)
				{
					//`LEBMSG("Trace:" @TargetUnit.GetFullName() @TraceHitInfo.HitActor.Name);
					
					if((!CanBeDestroyed(XComInteractiveLevelActor(TraceHitInfo.HitActor), DamageAmount) && XComFracLevelActor(TraceHitInfo.HitActor) == none) || !bKnockbackDestroysNonFragile)
					{
						
						//`LEBMSG("Trace Indestructible:" @TargetUnit.GetFullName() @TraceHitInfo.HitActor.Name);
						//We hit an indestructible object
						KnockbackToLocation = TraceHitInfo.HitLocation + (-OutAttackDirection * 16.0f); //Scoot the hit back a bit and use that as the knockback location
						break;
					}
				}
			}

			//Walk in increments down the attack vector. We will stop if we can't find a floor, or have reached the knock back distance
			TestDistanceUnits = VSize2D(KnockbackToLocation - StartLocation);
			StepDistance = 0.0f;
			OutTilesEntered.Length = 0;
			OutTilesEntered.AddItem(StartTile);
			while(StepDistance < TestDistanceUnits)
			{
				TestLocation = StartLocation + (OutAttackDirection * StepDistance);
				if(!WorldData.GetFloorTileForPosition(TestLocation, TempTile, true))
				{
					TestLocation -= (OutAttackDirection * StepDistance * 2);
					break;
				}

				//if (!WorldData.CanUnitsEnterTile(TempTile)) `LEBMSG("Tile Blocked:" @TargetUnit.GetFullName() @TempTile.X @TempTile.Y @TempTile.Z);
				if(LastTempTile != TempTile && OccupiedTiles.Find(""$TempTile.X$TempTile.Y$TempTile.Z) == INDEX_NONE && WorldData.CanUnitsEnterTile(TempTile))
				{
					OutTilesEntered.AddItem(TempTile);
					LastTempTile = TempTile;
				}
				
				StepDistance += IncrementalStepSize;
			}

			//Move the target unit to the knockback location
			//except when its blocked, then take the last valid tile
			WorldData.GetFloorTileForPosition(TestLocation, MoveToTile, true);
			if(OccupiedTiles.Find(""$MoveToTile.X$MoveToTile.Y$MoveToTile.Z) == INDEX_NONE && WorldData.CanUnitsEnterTile(MoveToTile)) OutTilesEntered.AddItem(MoveToTile);
	}
}

simulated function ApplyEffectToWorld(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_BaseObject kNewTargetState;
	local int Index;
	local XComGameState_EnvironmentDamage DamageEvent;
	local XComWorldData WorldData;
	local TTile HitTile;
	local array<TTile> TilesEntered;
	local Vector AttackDirection;
	local XComGameState_Item SourceItemStateObject;
	local XComGameStateHistory History;
	//local X2WeaponTemplate WeaponTemplate;
	local array<StateObjectReference> Targets;
	local StateObjectReference CurrentTarget;
	local XComGameState_Unit TargetUnit;
	local TTile NewTileLocation;
	local float KnockbackDamage;
	local float KnockbackRadius;
	local int EffectIndex, MultiTargetIndex;
	local X2Effect_Singularity_LEBPsi KnockbackEffect;

	//`LEBMSG("ApplyEffectToWorld");

	OccupiedTiles.length = 0;

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if(AbilityContext != none)
	{
		//`LEBMSG("If1");
		//if (AbilityContext.InputContext.PrimaryTarget.ObjectID > 0)
		//{
			//`LEBMSG("If2");
			//// Check the Primary Target for a successful knockback
			//for (EffectIndex = 0; EffectIndex < AbilityContext.ResultContext.TargetEffectResults.Effects.Length; ++EffectIndex)
			//{
				//`LEBMSG("If3");
				//KnockbackEffect = X2Effect_Singularity_LEBPsi(AbilityContext.ResultContext.TargetEffectResults.Effects[EffectIndex]);
				//if (KnockbackEffect != none)
				//{
					//`LEBMSG("If4");
					////if (AbilityContext.ResultContext.TargetEffectResults.ApplyResults[EffectIndex] == 'AA_Success')
					////{
						//`LEBMSG("If5");
						//Targets.AddItem(AbilityContext.InputContext.PrimaryTarget);
						//break;
					////}
				//}
			//}
		//}

		for (MultiTargetIndex = 0; MultiTargetIndex < AbilityContext.InputContext.MultiTargets.Length; ++MultiTargetIndex)
		{
			//`LEBMSG("Multi If1");
			
			// Check the MultiTargets for a successful knockback
			for (EffectIndex = 0; EffectIndex < AbilityContext.ResultContext.MultiTargetEffectResults[MultiTargetIndex].Effects.Length; ++EffectIndex)
			{
				//`LEBMSG("Multi If2");
				
				KnockbackEffect = X2Effect_Singularity_LEBPsi(AbilityContext.ResultContext.MultiTargetEffectResults[MultiTargetIndex].Effects[EffectIndex]);
				if (KnockbackEffect != none)
				{
					//`LEBMSG("Multi If3" @AbilityContext.ResultContext.MultiTargetEffectResults[MultiTargetIndex].ApplyResults[EffectIndex]);
					
					//if (AbilityContext.ResultContext.MultiTargetEffectResults[MultiTargetIndex].ApplyResults[EffectIndex] == 'AA_Success')
					//{
						//`LEBMSG("Multi If4");

						Targets.AddItem(AbilityContext.InputContext.MultiTargets[MultiTargetIndex]);
						break;
					//}
				}
			}
		}

		foreach Targets(CurrentTarget)
		{
			History = `XCOMHISTORY;
				SourceItemStateObject = XComGameState_Item(History.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));
			if (SourceItemStateObject != None)
				//WeaponTemplate = X2WeaponTemplate(SourceItemStateObject.GetMyTemplate());

			//if (WeaponTemplate != none)
			//{
				//KnockbackDamage = WeaponTemplate.fKnockbackDamageAmount >= 0.0f ? WeaponTemplate.fKnockbackDamageAmount : DefaultDamage;
				//KnockbackRadius = WeaponTemplate.fKnockbackDamageRadius >= 0.0f ? WeaponTemplate.fKnockbackDamageRadius : DefaultRadius;
			//}
			//else
			//{
				KnockbackDamage = DefaultDamage;
				KnockbackRadius = DefaultRadius;
			//}

			kNewTargetState = NewGameState.GetGameStateForObjectID(CurrentTarget.ObjectID);
			TargetUnit = XComGameState_Unit(kNewTargetState);
			//TargetUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', TargetUnit.ObjectID));
			//`LEBMSG("Effect TargetUnit:" @TargetUnit.GetFullName());
	
			if(TargetUnit != none) //Only units can be knocked back
			{
				TilesEntered.Length = 0;
				GetTilesEnteredArray(AbilityContext, kNewTargetState, TilesEntered, AttackDirection, KnockbackDamage);

				//Only process the code below if the target went somewhere
				if(TilesEntered.Length > 0)
				{
					WorldData = `XWORLD;

					if(bKnockbackDestroysNonFragile)
					{
						for(Index = 0; Index < TilesEntered.Length; ++Index)
						{
							HitTile = TilesEntered[Index];
							HitTile.Z += 1;

							DamageEvent = XComGameState_EnvironmentDamage(NewGameState.CreateStateObject(class'XComGameState_EnvironmentDamage'));
							DamageEvent.DEBUG_SourceCodeLocation = "UC: X2Effect_Singularity_LEBPsi:ApplyEffectToWorld";
							DamageEvent.DamageAmount = KnockbackDamage;
							DamageEvent.DamageTypeTemplateName = 'Melee';
							DamageEvent.HitLocation = WorldData.GetPositionFromTileCoordinates(HitTile);
							DamageEvent.Momentum = AttackDirection;
							DamageEvent.DamageDirection = AttackDirection; //Limit environmental damage to the attack direction( ie. spare floors )
							DamageEvent.PhysImpulse = 100;
							DamageEvent.DamageRadius = KnockbackRadius;
							DamageEvent.DamageCause = ApplyEffectParameters.SourceStateObjectRef;
							DamageEvent.DamageSource = DamageEvent.DamageCause;
							DamageEvent.bRadialDamage = false;
							NewGameState.AddStateObject(DamageEvent);
						}
					}

					NewTileLocation = TilesEntered[TilesEntered.Length - 1];
					TargetUnit.SetVisibilityLocation(NewTileLocation);
					EndingLocation = `XWORLD.GetPositionFromTileCoordinates(NewTileLocation);
					OccupiedTiles.AddItem(""$NewTileLocation.X$NewTileLocation.Y$NewTileLocation.Z);
					//`LEBMSG("Occupiedtiles:" @OccupiedTiles[OccupiedTiles.Length - 1]);
					//`LEBMSG("TargetUnit EndLocation:" @TargetUnit.GetFullName() @NewTileLocation.X @NewTileLocation.Y @NewTileLocation.Z @EndingLocation);

					`XEVENTMGR.TriggerEvent('ObjectMoved', TargetUnit, TargetUnit, NewGameState);
					`XEVENTMGR.TriggerEvent('UnitMoveFinished', TargetUnit, TargetUnit, NewGameState);
					//NewGameState.AddStateObject(TargetUnit);

				}
			}			
		}
	}
}

simulated function int CalculateDamageAmount(const out EffectAppliedData ApplyEffectParameters, out int ArmorMitigation, out int NewShred)
{
	return 0;
}

simulated function bool PlusOneDamage(int Chance)
{
	return false;
}

simulated function bool IsExplosiveDamage() 
{ 
	return false; 
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata BuildTrack, name EffectApplyResult)
{
	local X2Action_Singularity_LEBPsi SingularityAction;
	local XComGameState_Unit TargetUnitState;
	local X2Action ParentAction;

	TargetUnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);

		if (BuildTrack.StateObject_NewState.IsA('XComGameState_Unit'))
		{
			if( (TargetUnitState != none) && (TargetUnitState.IsUnitApplyingEffectName('Suppression') || TargetUnitState.IsUnitApplyingEffectName('AreaSuppression')))
			{
				class'X2Action_StopSuppression'.static.AddToVisualizationTree(BuildTrack, VisualizeGameState.GetContext());
			}

			// Attach the ragdoll action as a sibling of the fire action (or whatever queued this visualization)
			// so that all affected targets animate concurrently instead of being chained one after another.
			ParentAction = BuildTrack.LastActionAdded;
			SingularityAction = X2Action_Singularity_LEBPsi(class'X2Action_Singularity_LEBPsi'.static.AddToVisualizationTree(BuildTrack, VisualizeGameState.GetContext(), false, ParentAction));
			SingularityAction.AnimationDelay = 0.01f;//1.0f + RandRange(0.0f, 1.0f); //wait a bit to be in sync with the particle effect
		}
		else if (BuildTrack.StateObject_NewState.IsA('XComGameState_EnvironmentDamage') || BuildTrack.StateObject_NewState.IsA('XComGameState_Destructible'))
		{
			//`LEBMSG("AddX2ActionsForVisualization World");
			
			//This can be added by other effects, so check to see whether this track already has one of these
			//if (!`XCOMVISUALIZATIONMGR.TrackHasActionOfType(BuildTrack, class'X2Action_ApplyWeaponDamageToTerrain'))
			//{
			class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTree(BuildTrack, VisualizeGameState.GetContext());
			//}
		}
	//}
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationActionMetadata BuildTrack, const int TickIndex, XComGameState_Effect EffectState)
{
	
}

defaultproperties
{
	IncrementalStepSize=8.0

	Begin Object Class=X2Condition_UnitProperty Name=UnitPropertyCondition
		ExcludeTurret = true
		ExcludeDead = true
	End Object

	TargetConditions.Add(UnitPropertyCondition)

	DamageTypes.Add("KnockbackDamage");

	ApplyChanceFn=WasTargetPreviouslyDead

	DefaultDamage=100.0
	DefaultRadius=64.0

	bKnockbackDestroysNonFragile=false

	bIsImpairingMomentarily=true
}
