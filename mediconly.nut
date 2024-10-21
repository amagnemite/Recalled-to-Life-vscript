::medicOnly <- {
	missionName = null

	OnGameEvent_player_changeclass = function(params) {
		local player = GetPlayerFromUserID(params.userid)
	
		if(player.GetTeam() == TF_TEAM_RED && params["class"] != TF_CLASS_MEDIC) {
			player.SetPlayerClass(TF_CLASS_MEDIC)
			NetProps.SetPropInt(player, "m_Shared.m_iDesiredPlayerClass", TF_CLASS_MEDIC);
			player.ForceRegenerateAndRespawn()
		}
	}
	
	OnGameEvent_recalculate_holidays = function(_) {if(GetRoundState() == 3) reset()}
	
	reset = function() {
		if(missionName != NetProps.GetPropString(Entities.FindByClassname(null, "tf_objective_resource"), "m_iszMvMPopfileName")) {
			delete ::medicOnly
		}
    }
}
medicOnly.missionName <- NetProps.GetPropString(Entities.FindByClassname(null, "tf_objective_resource"), "m_iszMvMPopfileName")
for(local i = 1; i <= MaxPlayers; i++) {
	local player = PlayerInstanceFromIndex(i);
	if(player == null) continue;
	if(IsPlayerABot(player)) continue;
	
	if(player.GetTeam() == TF_TEAM_RED) {
		player.SetPlayerClass(TF_CLASS_MEDIC)
		NetProps.SetPropInt(player, "m_Shared.m_iDesiredPlayerClass", TF_CLASS_MEDIC);
		player.ForceRegenerateAndRespawn()
	}
}
__CollectGameEventCallbacks(medicOnly)