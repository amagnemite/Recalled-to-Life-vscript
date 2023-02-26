for(local i = 1; i <= Constants.Server.MAX_PLAYERS; i++) {
	local player = PlayerInstanceFromIndex(i);
	if(player == null) continue;
	if(!IsPlayerABot(player)) continue;
	
	//sometimes tags persist on bots, so need to look for one that's actually alive
	if(player.HasBotTag("timer") && player.GetHealth() > 1) {
		//i = Constants.Server.MAX_PLAYERS + 1;
		player.ValidateScriptScope()
		
		player.GetScriptScope()["Counter"] <- player.GetHealth();
		player.GetScriptScope()["Think"] <- function() {
			if(self.GetHealth() <= 1 && self.GetScriptScope()["Counter"] > 0) {
				//autokilled by wave end, remove think
				printl("timer killed by populator")
				AddThinkToEnt(self, null);
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
				self.GetScriptScope()["Counter"] = null;
			}
			else if(self.GetHealth() != self.GetScriptScope()["Counter"]) {
				printl("added time")
				self.GetScriptScope()["Counter"] = self.GetHealth();
			}
			
			if(self.GetScriptScope()["Counter"] <= 0) {
				//if counter hits 0, bots win
				AddThinkToEnt(self, null);
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
				//EntFire("bots_win", "RoundWin")
			}
			else {
				self.GetScriptScope()["Counter"]-= 10;
				self.SetHealth(player.GetHealth() - 10);
			}
			return 1;
		}
		AddThinkToEnt(player, "Think");
	}
}