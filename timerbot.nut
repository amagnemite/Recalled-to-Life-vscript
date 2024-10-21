::DEFAULTTIMERSEGMENT <- 5
::timer <- null

::findTimerBot <- function(segments = null, isChaosAltmode = false, funcToRun = null, startImmediately = true) {
	for(local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i);
		if(player == null) continue;
		if(!IsPlayerABot(player)) continue;
		
		//sometimes tags persist on bots, so need to look for one that's actually alive
		if(player.HasBotTag("timer") && NetProps.GetPropInt(player, "m_lifeState") == 0) {
			player.ValidateScriptScope();
			local scope = player.GetScriptScope()
			
			scope.actualTimer <- Timer()
			scope.actualTimer.Start(0.01) //mostly to make sure it's elapsed by the time think starts
			scope.timerSegment <- segments == null ? DEFAULTTIMERSEGMENT : segments
			scope.funcToRun <- funcToRun == null ? null : funcToRun
			scope.isChaosAltmode <- isChaosAltmode
			scope.TimerThink <- function() {
				if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
					//autokilled by wave end, remove think
					AddThinkToEnt(self, null);
					NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
					timer = null;
					return
				}
				else if(self.GetHealth() <= 0) { //sethealth to 0/negative number doesn't actually kill the bot
					//if health hits 0, bots win
					AddThinkToEnt(self, null);
					NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
					timer = null;
					
					if(isChaosAltmode) {
						EntFire("altmode_chaos_script", "runscriptcode", "setIsContainmentBreaker(true)")
					}
					
					if(funcToRun != null) { //allow 
						funcToRun()
					}
					else if(!isChaosAltmode) {
						EntFire("bots_win", "RoundWin")
					}
				}
				else if(actualTimer.Expired()) {
					self.SetHealth(self.GetHealth() - 1);
					actualTimer.Start(1)
				}
				return -1;
			}
			timer = player;
			if(startImmediately) {
				AddThinkToEnt(player, "TimerThink");
			}
			break;
		}
	}
}

::setTimerSegment <- function(val) { // refill timer with 1/timerSegment 
	timer.GetScriptScope().timerSegment = val
}

::addTime <- function() {
	local maxHealth = timer.GetMaxHealth()
	local modifiedHealth = timer.GetHealth() + maxHealth / timer.GetScriptScope().timerSegment
	
	local health = modifiedHealth > maxHealth ? maxHealth : modifiedHealth
	timer.SetHealth(health);
}

::setTimerFuncToRun <- function(func) {
	if(timer == null) return
	timer.GetScriptScope().funcToRun = func
}

::startTimer <- function() {
	AddThinkToEnt(timer, "TimerThink");
}