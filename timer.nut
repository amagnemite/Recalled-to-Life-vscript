for(local i = 1; i <= Constants.Server.MAX_PLAYERS; i++) {
	local player = PlayerInstanceFromIndex(i);
	if(player == null) continue;
	if(!IsPlayerABot(player)) continue;
	
	//sometimes tags persist on bots, so need to look for one that's actually alive
	if(player.HasBotTag("timer") && NetProps.GetPropInt(player, "m_lifeState") == 0) {
		//i = Constants.Server.MAX_PLAYERS + 1;
		player.ValidateScriptScope();
		
		//use a counter and direct hp so nothing weird happens if bot is autokilled
		player.GetScriptScope().counter <- player.GetHealth();
		player.GetScriptScope().TimerThink <- function() {
			if(NetProps.GetPropInt(self, "m_lifeState") != 0 && self.GetScriptScope().counter > 0) {
				//autokilled by wave end, remove think
				printl("timer killed by populator")
				AddThinkToEnt(self, null);
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
				delete self.GetScriptScope().counter;
				::timer = null;
				return;
			}
			else if(self.GetHealth() != self.GetScriptScope().counter) {
				printl("added time")
				self.GetScriptScope().counter = self.GetHealth();
			}
			
			if(self.GetScriptScope().counter <= 0) {
				//if counter hits 0, bots win
				AddThinkToEnt(self, null);
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
				delete self.GetScriptScope().counter;
				::timer = null;
				//EntFire("bots_win", "RoundWin")
			}
			else {
				self.GetScriptScope().counter -= 10;
				self.SetHealth(player.GetHealth() - 10);
			}
			return 1;
		}
		AddThinkToEnt(player, "TimerThink");
		::timer <- player; //global
	}
}