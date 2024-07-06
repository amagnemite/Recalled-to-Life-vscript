::medicOnly <- {
	missionName = null;

	OnGameEvent_player_changeclass = function(params) {
		local player = GetPlayerFromUserID(params.userid)
	
		if(player.GetTeam() == TF_TEAM_RED && params["class"] != TF_CLASS_MEDIC) {
			//while(Time() < player.GetNextChangeClassTime()) {
			//	printl(Time())
			//}
			
			player.SetPlayerClass(TF_CLASS_MEDIC)
			NetProps.SetPropInt(player, "m_Shared.m_iDesiredPlayerClass", TF_CLASS_MEDIC);
			player.ForceRegenerateAndRespawn()
		}
	}
	
	reset = function() {
		if(missionName != NetProps.GetPropString(Entities.FindByClassname(null, "tf_objective_resource")) {
			delete ::altmode
		}
    }
	
	OnGameEvent_recalculate_holidays = function(_) {if(GetRoundState() == 3) reset()}
}
medicOnly.missionName <- NetProps.GetPropString(Entities.FindByClassname(null, "tf_objective_resource"), "m_iszMvMPopfileName")
__CollectGameEventCallbacks(medicOnly)