::mimicListeners <- {
	reset = function() {
		delete ::mimicListeners
    }
	
	OnGameEvent_recalculate_holidays = function(_) {if(GetRoundState() == 3) reset()}
	OnGameEvent_mvm_wave_complete = function(_) {reset()}
	
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid);
		
		if(IsPlayerABot(player)) {
			return
		}
		
		EntFire("popscript", "$StartInterrupt", player.GetEntityIndex())
	}
	
	OnGameEvent_player_turned_to_ghost = function(params) {
		local player = GetPlayerFromUserID(params.userid);
		
		//if(IsPlayerABot(player)) {
		//	return
		//}
		
		EntFire("popscript", "$StopInterrupt", player.GetEntityIndex())
	}
}
__CollectGameEventCallbacks(mimicListeners)