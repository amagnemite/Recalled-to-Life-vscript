local players = {};

function OnGameEvent_player_disconnect(params) {
	local player = GetPlayerFromUserID(params.userid);
	delete players[player];
}

function OnGameEvent_player_spawn(params) {
	local player = GetPlayerFromUserID(params.userid);
	
	if(IsPlayerABot(player)) {
	//add think to bot to force reaggro if they're looking at a barrier
		/*
		if(player.ValidateScriptScope()) {
			local playerScript = player.GetScriptScope();
			playerScript["CheckAggro"] <- function() {
				local traceTable = {
					start = player.GetOrigin(),
					end = player.GetOrigin() + Vector(500, 0, 0)
				};
			
				if(TraceLineEx(traceTable)) {
					if(traceTable.hit && traceTable.enthit.GetClassname() == "func_physbox_multiplayer") {
						local target = players[RandomInt(0, players.len() -1)];
						player.SetAttentionFocus(target);
					}
				}
			}
		}
		AddThinkToEnt(player, "CheckAggro");
		*/
	}
	else { 
		if(player in players) { //player got revived
			local datatable = players[player];
		
			if(datatable.reanimEntity) {
				datatable.reanimEntity.Kill();		
				datatable.reanimCount++;
			}
		
			datatable.reanimState = false;
			datatable.reanimEntity = null;
			//force long respawn
			//player.RemoveCustomAttribute("mod weapon blocks healing");
			//player.RemoveCustomAttribute("ignored by bots");
			EntFireByHandle(player, "RunScriptCode", "addSpawnConds()", -1, null, null);
		}
		else { //first connect
			print("activate");
			if(player.GetTeam() == TF_TEAM_RED) {
				players[player] <- { //handle
					reanimState = false
					reanimEntity = null
					reanimCount = 0
				};
				EntFireByHandle(player, "RunScriptCode", "addSpawnConds()", -1, null, null);
			}
		}
	}
}

::addSpawnConds <- function() { //player_spawned clears so need to delay
	self.AddCustomAttribute("min respawn time", 2401, -1);
	self.AddCond(TF_COND_HALLOWEEN_IN_HELL);
}

function OnGameEvent_player_turned_to_ghost(params) {
	local player = GetPlayerFromUserID(params.userid);
	
	CreateReanim(player);
	BecomeGhost(player);
}

function OnGameEvent_mvm_wave_failed(params) {
	Reset();

}

function OnGameEvent_mvm_wave_complete(params) {
	Reset();
}

//should catch mission restart / mission change 
function OnGameEvent_mvm_reset_stats(params) {
	Reset();
}

function Reset() {
	local callbacktable = getroottable()["GameEventCallbacks"];
	
	AddThinkToEnt(self, null);
	NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
	
	for(local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i);
		if(player == null) continue;
		if(IsPlayerABot(player)) continue;

		player.RemoveCustomAttribute("mod weapon blocks healing");
		player.RemoveCustomAttribute("ignored by bots");
		player.RemoveCustomAttribute("min respawn time");
	}
	
	/*
	callbacktable.player_activate = function() {
	}
	callbacktable.player_disconnect = function() {
	}
	callbacktable.player_spawn = function() {
	}
	callbacktable.player_turned_to_ghost = function() {
	}
	callbacktable.mvm_wave_failed = function() {
	}
	callbacktable.mvm_wave_complete = function() {
	}
	*/
	
	delete callbacktable.player_disconnect;
	delete callbacktable.player_spawn;
	delete callbacktable.player_turned_to_ghost;
	delete callbacktable.mvm_wave_failed;
	delete callbacktable.mvm_wave_complete;
	delete callbacktable.mvm_reset_stats;
	
}

function Precache() {
	PrecacheModel("models/props_halloween/ghost_no_hat_red.mdl");
	PrecacheSound("vo/halloween_boo1.mp3");
	PrecacheSound("vo/halloween_boo2.mp3");
	PrecacheSound("vo/halloween_boo3.mp3");
	PrecacheSound("vo/halloween_boo4.mp3");
	PrecacheSound("vo/halloween_boo5.mp3");
	PrecacheSound("vo/halloween_boo6.mp3");
	PrecacheSound("vo/halloween_boo7.mp3");
}

function CreateReanim(player) { //bootlegs a reanim since becoming a ghost doesn't count as dying
	local datatable = players[player];
	
	local reanim = SpawnEntityFromTable("entity_revive_marker", {
		teamnum = player.GetTeam()
		origin = player.EyePosition()
		max_health = 75 + datatable.reanimCount * 10
	});
	
	NetProps.SetPropEntity(reanim, "m_hOwner", player);
	//NetProps.SetPropInt(reanim, "m_nBody", 4);
	
	datatable.reanimState = true;
	datatable.reanimEntity = reanim;
}

function BecomeGhost(player) { //force disconnects any meds healing when the player dies
	foreach(medic, v in players) {
		if(medic == player) continue;
		
		if(medic.GetHealTarget() == player) {
			local weapon = medic.GetActiveWeapon();
			if(weapon.GetClassname() == "tf_weapon_medigun") {
				NetProps.SetPropEntity(weapon, "m_hHealingTarget", null);
			}
		}
	}
	
	//prevent bot aggro somehow
	player.AddCustomAttribute("ignored by bots", 1, 0);
	player.AddCustomAttribute("mod weapon blocks healing", 1, 0);
}

function WaveStart() {
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
		player.AddCustomAttribute("min respawn time", 2401, -1);
	}
	
	AddThinkToEnt(self, "LoseThink");
}

//check if everyone is "dead" and end round if so
function LoseThink() {
	local alive = 0;
	
	foreach(player, datatable in players) {
		if(datatable.reanimState && !datatable.reanimEntity) {
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