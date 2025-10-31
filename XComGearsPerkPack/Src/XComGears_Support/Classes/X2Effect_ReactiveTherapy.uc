class X2Effect_ReactiveTherapy extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;

	EventMgr.RegisterForEvent(EffectObj, 'UnitDied',ReactiveTherapyCooldownCheck, ELD_OnStateSubmitted);
}

static function EventListenerReturn ReactiveTherapyCooldownCheck(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object Callback)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_HeadquartersXCom XComHQ;
    local XComGameStateHistory	History;
    local XComGameState_Ability AbilityState;
	local XComGameState_Unit DeadUnit, SourceUnit, UnitState;
    local X2SoldierClassTemplate SoldierClassTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState NewGameState;
	local UnitValue UnitVal;
    local int i, j;


    History = `XCOMHISTORY;
    XComHQ = `XCOMHQ;
    AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	DeadUnit = XComGameState_Unit(EventData);
    SourceUnit = XComGameState_Unit(EventSource);

    `log("The dead unit is " $ DeadUnit.GetFullName() $ " and the source unit is : " $ SourceUnit.GetFullName());

    if (DeadUnit.GetTeam() == eTeam_XCom)
    {
        // Get all support class soldiers who currently have the restoration protocol ability
        for (i = 0; i < XComHQ.Squad.Length; i++)
		{
			if (XComHQ.Squad[i].ObjectID != 0)
			{
				UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Squad[i].ObjectID));
                //SoldierClassTemplate = UnitState.GetSoldierClassTemplate();
                //`log("Evaluating abilities for " $ UnitState.GetFullName());
                if (UnitState.AffectedByEffectNames.Find('ReactiveTherapy') != -1)
                {
                    //`log("Unit Affected by Reactive Therapy Effect?");
                    for (j = 0; j < UnitState.Abilities.Length; ++j)
                    {
                        AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitState.Abilities[j].ObjectID));
                        if (AbilityState != none && AbilityState.GetMyTemplateName() == 'RestorativeMist'  && AbilityState.iCooldown > 0)
                        {
                            //AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
                            AbilityState.iCooldown = 0;
                            `log("Ability cooldown reset for: " $ AbilityState.Name);
                        }
                    }
                }


            }
        }
    }


    return ELR_NoInterrupt;

}