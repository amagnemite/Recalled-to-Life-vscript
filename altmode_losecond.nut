//if(!IsSoundPrecached("vo/halloween_boo1.mp3")) {
	PrecacheModel("models/props_halloween/ghost_no_hat_red.mdl");
	PrecacheSound("vo/halloween_boo1.mp3");
	PrecacheSound("vo/halloween_boo2.mp3");
	PrecacheSound("vo/halloween_boo3.mp3");
	PrecacheSound("vo/halloween_boo4.mp3");
	PrecacheSound("vo/halloween_boo5.mp3");
	PrecacheSound("vo/halloween_boo6.mp3");
	PrecacheSound("vo/halloween_boo7.mp3");
//}

::losecond <- {
	players = {}

	reset = function() {
		AddThinkToEnt(Entities.FindByName(null, "altmode_losecond_script"), null); //only matters for wave win
		local override = Entities.FindByName(null, "respawn_override")
		
		foreach(player, datatable in players) {
			player.RemoveCustomAttribute("mod weapon blocks healing");
			player.RemoveCustomAttribute("ignored by bots");
			override.AcceptInput("EndTouch", null, null, player)
			player.RemoveCond(TF_COND_HALLOWEEN_IN_HELL);
			player.RemoveCond(TF_COND_HALLOWEEN_GHOST_MODE)
			//may just want to forcerespawn + delete reanims
			
			if(datatable.reanimEntity && datatable.reanimEntity.IsValid()) {
				datatable.reanimEntity.Kill()
			}
		}
		delete ::losecond;
    }
	
	OnGameEvent_recalculate_holidays = function(_) {if(GetRoundState() == 3) reset()}
	OnGameEvent_mvm_wave_complete = function(_) {reset()}
	
	OnGameEvent_player_disconnect = function(params) {
		local player = GetPlayerFromUserID(params.userid);
		if(player != null && player in players) {
			delete players[player];
		}
	}
	
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid);
	
		if(IsPlayerABot(player)) {
		//add think to bot to force reaggro if they're looking at a barrier
			/*
			if(player.ValidateScriptScope()) {
				local playerScript = player.GetScriptScope();
				playerScript.checkAggro <- function() {
					local traceTable = {
						start = self.GetOrigin(),
						end = self.GetOrigin() + Vector(500, 0, 0)
					};
				
					if(TraceLineEx(traceTable)) {
						if(traceTable.hit && traceTable.enthit.GetClassname() == "func_physbox_multiplayer") {
							local target = players[RandomInt(0, players.len() - 1)];
							self.SetAttentionFocus(target);
						}
					}
				}
			}
			AddThinkToEnt(player, "checkAggro");
			*/
		}
		else { 
			if(player in players) { //player got revived
				local datatable = players[player];
			
				if(datatable.reanimEntity && datatable.reanimEntity.IsValid()) {
					datatable.reanimEntity.Kill();		
					datatable.reanimCount++;
				}
			
				datatable.reanimState = false;
				datatable.reanimEntity = null;
				
				//player.RemoveCustomAttribute("mod weapon blocks healing");
				//player.RemoveCustomAttribute("ignored by bots");
				EntFireByHandle(player, "RunScriptCode", "losecond.addSpawnConds()", -1, player, null);
			}
			else { //first connect
				if(player.GetTeam() == TF_TEAM_RED) {
					players[player] <- { //handle
						reanimState = false
						reanimEntity = null
						reanimCount = 0
					};
					EntFireByHandle(player, "RunScriptCode", "losecond.addSpawnConds()", -1, player, null);
				}
			}
		}
	}
	
	/*
	OnGameEvent_player_death = function(params) {
		local player = GetPlayerFromUserID(params.userid);
		
		if(IsPlayerABot(player)) {
			if(player.GetScriptThinkFunc() == "checkAggro") {
				AddThinkToEnt(player, null)
			}
		}
	}
	*/
	
	addSpawnConds = function() { //player_spawned clears so need to delay
		Entities.FindByName(null, "respawn_override").AcceptInput("StartTouch", null, null, activator)
		activator.AddCond(TF_COND_HALLOWEEN_IN_HELL);
	}
	
	OnGameEvent_player_turned_to_ghost = function(params) {
		local player = GetPlayerFromUserID(params.userid);
		
		fakeDeath(player)
	}
	
	fakeDeath = function(player) { //bootlegs a reanim since becoming a ghost doesn't count as dying
		local datatable = players[player];
		
		local reanim = SpawnEntityFromTable("entity_revive_marker", {
			teamnum = player.GetTeam()
			origin = player.EyePosition()
			max_health = 75 + datatable.reanimCount * 10
		});
		
		NetProps.SetPropEntity(reanim, "m_hOwner", player);
		NetProps.SetPropInt(reanim, "m_nBody", 4);
		
		datatable.reanimState = true;
		datatable.reanimEntity = reanim;
		
		foreach(medic, v in players) { 		//force disconnects any meds healing when the player dies
			if(medic == player) continue;
			
			if(medic.GetHealTarget() == player) {
				local weapon = medic.GetActiveWeapon();
				if(weapon.GetClassname() == "tf_weapon_medigun") {
					NetProps.SetPropEntity(weapon, "m_hHealingTarget", null);
				}
			}
		}
		
		//prevent bot aggro somehow
		player.AddCustomAttribute("ignored by bots", 1, -1);
		player.AddCustomAttribute("mod weapon blocks healing", 1, -1);
	}
	
	WaveStart = function() {
		__CollectGameEventCallbacks(losecond)
		hidePermaDeathAnnotation()
		local override = Entities.FindByName(null, "respawn_override")
		
		players = {};

		for(local i = 1; i <= MaxPlayers; i++) {
			local player = PlayerInstanceFromIndex(i);
			if(player == null) continue;
			if(player.GetTeam() != 2) continue; //filters out specs
			if(IsPlayerABot(player)) continue;

			players[player] <- {};
			players[player].reanimState <- false;
			players[player].reanimEntity <- null;
			players[player].reanimCount <- 0;
			player.AddCond(TF_COND_HALLOWEEN_IN_HELL);
			override.AcceptInput("StartTouch", null, null, player)
		}
		
		AddThinkToEnt(Entities.FindByName(null, "altmode_losecond_script"), "LoseThink");
	}
}

//check if everyone is "dead" and end round if so
function LoseThink() {
	local alive = 0;
	
	foreach(player, datatable in losecond.players) {
		if(datatable.reanimState && !datatable.reanimEntity.IsValid()) {
			//reanim was somehow destroyed, force respawn
			player.ForceRespawn();
		}
		else if(!player.InCond(TF_COND_HALLOWEEN_GHOST_MODE) && NetProps.GetPropInt(player, "m_lifeState") == 0) {
			alive++;
		}
	}
	
	if(alive == 0) {
		EntFire("bots_win", "RoundWin");
	}
	
	return 1;
}