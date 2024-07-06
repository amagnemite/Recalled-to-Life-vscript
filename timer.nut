for(local i = 1; i <= MaxPlayers; i++) {
	local player = PlayerInstanceFromIndex(i);
	if(player == null) continue;
	if(!IsPlayerABot(player)) continue;
	
	//sometimes tags persist on bots, so need to look for one that's actually alive
	if(player.HasBotTag("timer") && NetProps.GetPropInt(player, "m_lifeState") == 0) {
		player.ValidateScriptScope();
		
		player.GetScriptScope().TimerThink <- function() {
			if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
				//autokilled by wave end, remove think
				printl("timer killed by populator")
				AddThinkToEnt(self, null);
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
				timer = null;
			}
			else if(self.GetHealth() <= 0) { //sethealth to 0/negative number doesn't actually kill the bot
				//if health hits 0, bots win
				AddThinkToEnt(self, null);
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
				timer = null;
				//EntFire("bots_win", "RoundWin")
			}
			else {
				self.SetHealth(self.GetHealth() - 1);
			}
			return 1;
		}
		AddThinkToEnt(player, "TimerThink");
		::timer <- player; //global
		break;
	}
}