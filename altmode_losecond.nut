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
	local player = GetPlayerFromUserID(params.userid);
	
	if(IsPlayerABot(player)) {
	//add think to bot to force reaggro if they're looking at a barrier
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
		player.AddCond(TF_COND_HALLOWEEN_IN_HELL);
		
		//reaggro bot
	}
}

function OnGameEvent_player_turned_to_ghost(params) {
	printl("ghost");
	local player = GetPlayerFromUserID(params.userid);
	
	CreateReanim(player, players[player]);
	BecomeGhost(player, players[player]);
}

function CreateReanim(player, datatable) {
	local reanim = SpawnEntityFromTable("entity_revive_marker", {
		teamnumber = 2,
		origin = player.EyePosition()
	});
	
	NetProps.SetPropInt(reanim, "m_iMaxHealth", 75 + (datatable.reanimCount * 10));
	NetProps.SetPropInt(reanim, "m_nBody", 4);
	
	reanim.SetOwner(player);
	
	datatable.reanimState = true;
	datatable.reanimEntity = reanim;
}

function BecomeGhost(player, datatable) {
	foreach(medic in players) {
		printl(medic.GetHealTarget());
		if(medic.GetHealTarget() == player) {
			local weapon = medic.GetActiveWeapon();
			if(weapon.GetClassname() == "tf_weapon_medigun") {
				NetProps.SetPropEntity(self, "m_hHealingTarget", null)
			}
		}
	}
	
	//deaggro mimics
	
	//prevent bot aggro somehow
	player.AddCustomAttribute("mod weapon blocks healing", 1)
	//accepts string, float, float, 2nd probably duration?
}

function OnGameEvent_mvm_wave_failed(params) {
	Reset();
}

function OnGameEvent_mvm_wave_complete(params) {
	Reset();
}

function Reset() {
	local timer = Entities.FindByName(null, "timer_script");
	local initrelay = Entities.FindByName(null, "altmode_init_relay");
	AddThinkToEnt(timer, null);
	AddThinkToEnt(initrelay, null);
	foreach(player in players) {
		player.RemoveCustomAttribute("mod weapon blocks healing");
	}
}

function WaveInit() {	
	if(!IsModelPrecached("models/props_halloween/ghost_no_hat_red.mdl")) {
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
	players.clear();

	local player = null;
	while(player = Entities.FindByClassname(player, "player")) {
		if(!IsPlayerABot(player) && player.GetTeam() == 2) {
			players[player] <- { //handle
				reanimState = false,
				reanimEntity = null,
				reanimCount = 0
			};
			player.AddCond(Constants.ETFCond.TF_COND_HALLOWEEN_IN_HELL);
		}
	}
	//AddThinkToEnt(self, "Think");
}

//check if everyone is "dead" and end round if so
function Think() {
	local alive = 0;
	
	foreach(player, datatable in players) {
		if(datatable.reanimState && !datatable.reanimEntity) {
			//reanim was somehow destroyed, force respawn
			player.ForceRespawn();
		}
		else if(!player.InCond(Constants.ETFCond.TF_COND_HALLOWEEN_GHOST_MODE) && 
			NetProps.GetPropInt(target, "m_lifeState") == 0) {
			alive++;
		}
	}
	
	if(alive == 0) {
		EntFire("bots_win", "RoundWin");
	}
}