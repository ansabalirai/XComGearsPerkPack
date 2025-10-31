//---------------------------------------------------------------------------------------
//  FILE:    X2Action_Singularity_LEBPsi
//  AUTHOR:  LeaderEnemyBoss
//  PURPOSE: Does the whole Ragdoll + getup animation thingy
//			 Based mostly on X2Action_Knockback
//--------------------------------------------------------------------------------------- 

class X2Action_Singularity_LEBPsi extends X2Action;

var float AnimationDelay;

var private Vector Destination, ImpulseDirection;
var private Rotator OldRotation;
var private XComGameState_Unit NewUnitState;
var private StateObjectReference DmgObjectRef;
var private CustomAnimParams AnimParams;
var private XComGameStateContext_Ability AbilityContext;
var private Vector EndingLocation, Currentlocation;
var private float DistanceToTargetSquared, FattyMult, CloseEnoughDistance;
var private XComWorldData WorldData;	
var private int iTries, iFattyMult;
var private TTile UnitTileLocation;
var private XComGameStateHistory History;

function Init()
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;	
	local TTile UnitTileLocation;
	local float KnockbackDistance;	
	local XComGameState_Unit OldUnitState;

	super.Init();

	History = `XCOMHISTORY;
	WorldData = `XWORLD;

//
	NewUnitState = XComGameState_Unit(Metadata.StateObject_NewState);
	NewUnitState.GetKeystoneVisibilityLocation(UnitTileLocation);
	Destination = WorldData.GetPositionFromTileCoordinates(UnitTileLocation);
	Destination.Z = UnitPawn.GetDesiredZForLocation(Destination) ; //+ UnitPawn.CollisionHeight + class'XComWorldData'.const.Cover_BufferDistance;
	//Destination.Z = UnitPawn.CollisionHeight + class'XComWorldData'.const.Cover_BufferDistance;
//
	EndingLocation = Destination;
	//class'Helpers'.static.OutputMsg("Endinglocation Action" @EndingLocation);
}

function bool CheckInterrupted()
{
	return false;
}

function ResumeFromInterrupt(int HistoryIndex)
{
	super.ResumeFromInterrupt(HistoryIndex);
}

function StartRagdoll()
{
	UnitPawn.StartRagDoll(false, , , false);
}


simulated state Executing
{
	simulated event BeginState(name PrevStateName)
	{
		super.BeginState(PrevStateName);

		//`SHAPEMGR.DrawSphere(Destination, vect(5, 5, 80), MakeLinearColor(1, 0, 0, 1), true);
		Unit.BeginUpdatingVisibility();
	}

	simulated event EndState(name NextStateName)
	{
		//local XcomGameState NewGameState;
		
		super.EndState(NextStateName);
		if (!IsTimedOut()) 
		{
			Currentlocation = UnitPawn.Location;
		}
		Unit.EndUpdatingVisibility();
	}
	
	//function DelayedNotify()
	//{
		//VisualizationMgr.SendInterTrackMessage(DmgObjectRef);
	//}

	function CopyPose()
	{
		AnimParams.AnimName = 'Pose';
		AnimParams.Looping = true;
		AnimParams.BlendTime = 0.0f;
		AnimParams.HasPoseOverride = true;
		AnimParams.Pose = UnitPawn.Mesh.LocalAtoms;
		UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
	}

Begin:	
	sleep(AnimationDelay);

	UnitPawn.DeathRestingLocation = EndingLocation;
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(false);
	UnitPawn.SetFinalRagdoll(false);

	//class'Helpers'.static.OutputMsg("Before StartRagdoll:" @EndingLocation @UnitPawn.GetCollisionComponentLocation() @UnitPawn.Location @UnitPawn.Name @UnitPawn.Mesh.PhysicsAsset);
	//class'Helpers'.static.OutputMsg("Rotation:" @UnitPawn.Rotation @UnitPawn.Mesh.GetRotation());

	OldRotation = UnitPawn.Rotation;
	Unit.SetDiscState(eDS_None);
	StartRagdoll();
	UnitPawn.SetPhysics(PHYS_RigidBody);
	//UnitPawn.SetPhysics(PHYS_Flying);
	UnitPawn.Mesh.bSyncActorLocationToRootRigidBody = true;

	//Some units need a little extra nudge
	FattyMult = 1.0f;
	if (string(UnitPawn.Mesh.PhysicsAsset) == "PHYS_AdventMecII") FattyMult = 3.0f;
	if (string(UnitPawn.Mesh.PhysicsAsset) == "PHYS_Berserker") FattyMult = 3.0f;
	if (string(UnitPawn.Mesh.PhysicsAsset) == "PHYS_Andromedon") FattyMult = 1.5f;
	if (string(UnitPawn.Mesh.PhysicsAsset) == "PHYS_AndromedonRobot") FattyMult = 1.5f;
	if (string(UnitPawn.Mesh.PhysicsAsset) == "SM_AdventDrone_Physics") FattyMult = 0.3f;
	

	//do a little launch to allow for sucking over cover
	ImpulseDirection = vect(0,0,1000);
	UnitPawn.Mesh.AddImpulse(ImpulseDirection * FattyMult);
	Sleep( 0.1f );

	DistanceToTargetSquared = VSizeSq2D(EndingLocation - UnitPawn.Location);
	If (DistanceToTargetSquared > CloseEnoughDistance/2)
	{
		ImpulseDirection = EndingLocation - UnitPawn.Location;
		If (ImpulseDirection.Z >= -10) ImpulseDirection.Z += 150; //give a slight launching impulse if the targetlocation isnt beneath us
		ImpulseDirection = ImpulseDirection * 0.2;
		UnitPawn.SetRagdollLinearDriveToDestination(EndingLocation, ImpulseDirection, 0.5f, 2.0f);
		DistanceToTargetSquared = VSizeSq2D(EndingLocation - UnitPawn.Location);
	}
	sleep(0.001f);
	

	//Do additional impulses to get our target near the intended position
	iTries = 0;
	DistanceToTargetSquared = VSizeSq2D(EndingLocation - UnitPawn.Location);
	//class'Helpers'.static.OutputMsg("After Initial Impulse: " @DistanceToTargetSquared);
	While (DistanceToTargetSquared > CloseEnoughDistance && iTries < 50)
	{
		iTries += 1;
		ImpulseDirection = EndingLocation - UnitPawn.Location;
		If (ImpulseDirection.Z >= -50) ImpulseDirection.Z += 150; //give a slight launching impulse if the targetlocation isnt beneath us
		ImpulseDirection = ImpulseDirection * 0.4;

		UnitPawn.Mesh.AddImpulse(ImpulseDirection);
		sleep (0.001f);
		DistanceToTargetSquared = VSizeSq2D(EndingLocation - UnitPawn.Location);
		//class'Helpers'.static.OutputMsg("Squared Distance & Impulse:" @DistanceToTargetSquared @VSize(ImpulseDirection));
	}

	if(!NewUnitState.IsDead() && !NewUnitState.IsIncapacitated())
	{		
		//Reset visualizers for primary weapon, in case it was dropped
		Unit.GetInventory().GetPrimaryWeapon().Destroy(); //Aggressively get rid of the primary weapon, because dropping it can really screw things up
		Unit.ApplyLoadoutFromGameState(NewUnitState, None);

		UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);

		// Copy all the bone transforms so we match his pose
		CopyPose();

		UnitPawn.EndRagDoll();

		// Jwats: House keeping! Make sure we a re in a good animation state.
		UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
		UnitPawn.SetNoSkeletonUpdate(false);
		Unit.SetTimeDilation(1.0f);
		
		UnitPawn.EnableRMA(true, true);
		UnitPawn.EnableRMAInteractPhysics(true);
		UnitPawn.EnableFootIK(false);

		//Get Up!
		AnimParams = default.AnimParams;
		AnimParams.AnimName = 'HL_GetUp';
		AnimParams.BlendTime = 0.1f;
		AnimParams.DesiredEndingAtoms.Add(1);
		AnimParams.DesiredEndingAtoms[0].Translation = Destination;
		AnimParams.DesiredEndingAtoms[0].Rotation = QuatFromRotator(UnitPawn.Rotation);
		AnimParams.DesiredEndingAtoms[0].Scale = 1.0f;
		FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

		UnitPawn.EnableFootIK(true);
		UnitPawn.bSkipIK = false;
		UnitPawn.EnableRMA(false, false);
		UnitPawn.EnableRMAInteractPhysics(false);
		UnitPawn.LockDownFootIK(false);
		UnitPawn.fFootIKTimeLeft = 10.0f;

		Unit.ProcessNewPosition();
		Unit.IdleStateMachine.CheckForStanceUpdate();
		//UnitPawn.m_fDistanceMovedAlongPath = KnockbackDistance;
	}
	
	CompleteAction();	
}

function CompleteAction()
{	
	super.CompleteAction();
}

DefaultProperties
{
	CloseEnoughDistance = 2500.0f
}
