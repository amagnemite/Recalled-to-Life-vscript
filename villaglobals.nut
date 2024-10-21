//common stuff for all altmode vers
::MaxPlayers <- MaxClients().tointeger();

foreach (a,b in Constants)
	foreach (k,v in b)
		if (!(k in getroottable()))
			getroottable()[k] <- v;

IncludeScript("timerbot.nut")
IncludeScript("trace_filter", getroottable());
IncludeScript("timer.nut", getroottable())

PrecacheSound("weapons/drg_pomson_drain_01.wav");
PrecacheSound("mvm/mvm_tele_activate.wav");
PrecacheSound("ui/alarm_citizen_loop1.wav");

::teleSound <- "mvm/mvm_tele_activate.wav";
::alarmSound <- "ui/alarm_citizen_loop1.wav"

::MELEE_ONLY <- 1
::PRIMARY_ONLY <- 2
::SECONDARY_ONLY <- 4
::LIFE_ALIVE <- 0

Convars.SetValue("tf_bot_engineer_mvm_hint_min_distance_from_bomb", 600)

if(!("globalCallbacks" in getroottable())) {
	::globalCallbacks <- {
		OnGameEvent_post_inventory_application = function(params) {
			local player = GetPlayerFromUserID(params.userid)
			//if (player == null) return
			if(IsPlayerABot(player)) return
			
			player.ValidateScriptScope()
			local scope = player.GetScriptScope()
			if(!("thinkTable" in scope) || player.GetScriptThinkFunc() != "mainThink") {
				scope.thinkTable <- {}
				scope.timeCounter <- 0
				scope.DEFAULTTIME <- 6 //.015 * 7 = .105, close enough to .1
				
				scope.mainThink <- function() {
					foreach(name, func in thinkTable) {
						func()
					}
					if(timeCounter == 6) {
						timeCounter = 0
					}
					else {
						timeCounter++
					}
					return -1
				}
				AddThinkToEnt(player, "mainThink")
			}
		}
	}
	__CollectGameEventCallbacks(globalCallbacks)
}

::noTaunt <- function() {
	self.RemoveCondEx(TF_COND_TAUNTING, true)
	if(self.IsRageDraining()) {
		NetProps.SetPropFloat(self, "m_Shared.m_flRageMeter", 0)
		EmitSoundEx({
			sound_name = "weapons/drg_pomson_drain_01.wav"
			volume = 0.8
			origin = self.GetOrigin()
			filter_type = 4
			entity = self
		})
	}
}

::showAnnotation <- function(message, x, y, z) {
	local table = {
		worldPosX = x
		worldPosY = y
		worldPosZ = z
		//visibilityBitfield
		text = message
		show_distance = false
		play_sound = "misc/null.wav"
		lifetime = 4.5
	}
	SendGlobalGameEvent("show_annotation", table)
}

::showPermaDeathAnnotation <- function() {
	local table = {
		id = 2401
		worldPosX = -1280
		worldPosY = 7264
		worldPosZ = 288
		text = "If everyone dies during the wave, the wave is lost!"
		show_distance = false
		play_sound = "misc/null.wav"
		lifetime = -1
	}
	SendGlobalGameEvent("show_annotation", table)
}

::hidePermaDeathAnnotation <- function() {
	local table = {
		id = 2401
	}
	SendGlobalGameEvent("hide_annotation", table)
}

::teleportToRoof <- function() {
	local roofWarp = Entities.FindByName(null, "roof_player_destination")
	EntFire("gamerules", "runscriptcode", "ScreenFade(null, 255, 255, 255, 255, 0.5, 1, 1)", -1)

	for(local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i);
		if(player == null) continue;
		if(IsPlayerABot(player)) continue;
		
		if(player.InCond(TF_COND_HALLOWEEN_GHOST_MODE) || NetProps.GetPropInt(player, "m_lifeState") != 0) {
			player.ForceRespawn()
		}
		
		player.Teleport(true, roofWarp.GetOrigin(), true, roofWarp.GetAbsAngles(), true, Vector())
	}
}

::teleportToArena2 <- function() {
	local arenaWarp = Entities.FindByName(null, "w4_arena_teleport_destination")
	EntFire("gamerules", "runscriptcode", "ScreenFade(null, 25, 93, 14, 255, 0.5, 1, 1)", -1)
	
	for(local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i);
		if(player == null) continue;
		if(IsPlayerABot(player)) continue;
		
		if(player.InCond(TF_COND_HALLOWEEN_GHOST_MODE) || NetProps.GetPropInt(player, "m_lifeState") != 0) {
			player.ForceRespawn()
		}
		
		player.Teleport(true, arenaWarp.GetOrigin(), true, arenaWarp.GetAbsAngles(), true, Vector())
	}
}

::teleportToSpawn <- function() {
	EntFire("gamerules", "runscriptcode", "ScreenFade(null, 0, 0, 0, 255, 0.75, 1.5, 2)", -1)

	for(local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i);
		if(player == null) continue;
		if(IsPlayerABot(player)) continue;
		
		//need to delay because this runs before the fade starts
		EntFireByHandle(player, "CallScriptFunction", "actualTeleport", 1, null, null)
	}
}

::actualTeleport <- function() {
	local spawn = Entities.FindByName(null, "teamspawn_all")
	self.Teleport(true, spawn.GetOrigin(), true, spawn.GetAbsAngles(), false, Vector())
}

::desquad <- {
	reset = function() {
		delete ::desquad
    }
	
	OnGameEvent_recalculate_holidays = function(_) {if(GetRoundState() == 3) reset()}
	OnGameEvent_mvm_wave_complete = function(_) {reset()}
	
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid);
		if(!IsPlayerABot(player)) {
			return
		}
		
		EntFireByHandle(player, "RunScriptCode", "desquad.checkSquad()", -1, player, null)
	}
	
	checkSquad = function() {
		if(activator.HasBotTag("preservesquad")) {
			return
		}
		activator.DisbandCurrentSquad()
	}
}