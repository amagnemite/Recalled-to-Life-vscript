local players = {};

function OnGameEvent_player_activate(params) { //when player connects and loaded in
	local player = GetPlayerFromUserID(params.userid);
	players[player] <- { //handle
		reanimState = false,
		reanimEntity = null,
		reanimCount = 0
	};
}

function OnGameEvent_player_disconnect(params) {
	local player = GetPlayerFromUserID(params.userid);
	players.rawdelete(player);
}

function OnGameEvent_player_spawned(params) {
	//add think to bot to force reaggro if they're looking at a barrier
	local player = GetPlayerFromUserID(params.userid);
	
	if(IsPlayerABot(player)) { //is bot
		if(player.ValidateScriptScope()) {
			local playerScript = player.GetScriptScope();
			playerScript["CheckAggro"] <- function() {
				local traceTable = {
					start = player.GetOrigin(),
					end = player.GetOrigin() + Vector(500, 0, 0);
				};
			
				if(TraceLineEx(traceTable)) {
					if(traceTable.hit && traceTable.enthit.GetClassname() == "func_physbox_multiplayer") {
					
					}
				
				}
			
			
			
			}
		}
	}
	else { //not bot (player got revived) 
		local datatable = players[player];
		
		if(datatable.reanimEntity) {
			datatable.reanimEntity.Kill();		
			datatable.reanimCount = datatable.reanimCount + 1;
		}
	
		datatable.reanimState = false;
		datatable.reanimEntity = null;
		//force long respawn
		player.RemoveCustomAttribute("mod weapon blocks healing");
		
		//reaggro bot
	}
}

function OnGameEvent_player_turned_to_ghost(params) {
	local player = GetPlayerFromUserID(params.userid);
	
	CreateReanim(player, players[player]);
	BecomeGhost(player, players[player]);
}

function CreateReanim(player, datatable) {
	local reanim = SpawnEntityFromTable("entity_revive_marker", {
		teamnumber = 2,
		origin = player.EyePosition()
	});
	
	NetProps.SetPropInt(reanim, "m_iMaxHealth", 75 + (datatable.reanimCount * 10);
	NetProps.SetPropInt(reanim, "m_nBody", 4);
	
	reanim:.SetOwner(player);
	
	datatable.reanimState = true;
	datatable.reanimEntity = reanim;
}

function BecomeGhost(player, datatable) {
	foreach(medic in players) {
		if(medic.GetHealTarget() == player) {
			local weapon = medic.GetActiveWeapon();
			if(weapon.GetClassname() == "tf_weapon_medigun") {
				NetProps.SetPropEntity(weapon, "m_hHealingTarget", null);
			}
		}
	}
	
	//reaggro mimics
	
	//prevent bot aggro somehow
	player:AddCustomAttribute("mod weapon blocks healing", 1)
	//accepts string, float, float, 2nd probably duration?
}

function WaveInit() {
	self.ValidateScriptScope();
	if(!IsModelPrecached("models/props_halloween/ghost_no_hat_red.mdl") {
		PrecacheModel("models/props_halloween/ghost_no_hat_red.mdl");
		PrecacheSound("vo/halloween_boo1.mp3");
		PrecacheSound("vo/halloween_boo2.mp3");
		PrecacheSound("vo/halloween_boo3.mp3");
		PrecacheSound("vo/halloween_boo4.mp3");
		PrecacheSound("vo/halloween_boo5.mp3");
		PrecacheSound("vo/halloween_boo6.mp3");
		PrecacheSound("vo/halloween_boo7.mp3");
	}
}

function WaveStart() {
	local player = null;
	while(player = Entities.FindByClassname(player, "player")) {
	  if(!IsPlayerABot(player) && player.GetTeam() == 2) {
		players[player] <- { //handle
			reanimState = false,
			reanimEntity = null,
			reanimCount = 0
		};
	  }
	}
	
	//display_game_events 1
	__CollectGameEventCallbacks(this);
}

function Think() {
	local alive = 0;
	
	foreach(player in players) {
		if(players[player].reanimState && !players[player].reanimEntity.IsValid()) {
			player.ForceRespawn();
		}
		else if(!player.InCond(TF_COND_HALLOWEEN_GHOST_MODE)) {
			alive++;
		}
	}
	
	if(alive == 0) {
		EntFire("bots_win", "RoundWin");
	}
}
