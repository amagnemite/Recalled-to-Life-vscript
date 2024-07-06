//w6 boss fight vscript
local gmed = null;
local text = "{blue}The King of the Robot Ghosts{reset}"
	+ " has used their {9BBF4D}RECALL{reset} Power Up Canteen!"
local spawnbot = Entities.FindByName(null, "spawnbot_roof").GetOrigin()
const HEALTHSTAGE = 10000
local bots = {}

bossFight <- {
	reset = function() {
		delete ::bossFight
	}
	
	//may need to collect on a delay
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid);
		if(!IsPlayerABot(player) return
		
		EntFireByHandle(player, "callscriptfunction", "bossFight.checkTag", -1, player, null)
	}

	checkTag = function() {
		if(activator.HasBotTag("gmed")) {
			gmed = activator
		}
		
		if(activator.HasBotTag("attack1") {
			activator.SetName("attack1")
		}
		else if(activator.HasBotTag("attack2") {
			activator.SetName("attack2")
		}
		else if(activator.HasBotTag("attack3") {
			activator.SetName("attack3")
		}
		else if(activator.HasBotTag("attack4") {
			activator.SetName("attack4")
		}
		else if(activator.HasBotTag("attack5") {
			activator.SetName("attack5")
		}
		else if(activator.HasBotTag("attack6") {
			activator.SetName("attack6")
		}
	}

	OnScriptHook_OnTakeDamage = function(params) {
		if(params.const_entity != gmed) || recallStage > 3) {
			return
		}
		
		if(gmed.GetHealth() - (params.damage * 3.1 + 1) <= 0) {
			gmed.AddCondEX(TF_COND_PREVENT_DEATH, -1)
			ClientPrint(null, HUD_PRINTTALK, text)
		
			foreach(player in players) {
				EmitSoundEx({
					sound_name = "mvm/mvm_used_powerup.wav""
					volume = 0.35
					origin = player.GetOrigin()
					filter_type = 4
					entity = player
				})
			}
			
			gmed.Teleport(true, spawnbot, false, QAngle(0, 0, 0), false, Vector(0, 0, 0))
			recallStage++
			gmed.SetHealth(HEALTHSTAGE)
			
			switch(recallStage) {
				case 1:
					EntFire("pop_interface", "ChangeBotAttributes", "shotgun")
					break
				case 2:
					EntFire("pop_interface", "ChangeBotAttributes", "crossbow")
					break
				case 3:
					gmed.RemoveCond(TF_COND_SODAPOPPER_HYPE)
					EntFire("pop_interface", "ChangeBotAttributes", "vita2")
					delete bossFight.OnScriptHook_OnTakeDamage
					break
			}
			params.damage = 0
		}
	}
	
	OnGameEvent_recalculate_holidays = function(_) {if(GetRoundState() == 3) reset()}
	OnGameEvent_mvm_wave_complete = function(_) {reset()}
}

function StartBossFight() {
	local roofDestination = Entities.FindByName(null, "roof_player_destination").GetOrigin();
	
	foreach(player in altmode.players) {
		//1s delay
		ScreenFade(player, 255, 255, 255, 255, .5, 1);
		
			//1s delay
			player.Teleport(true, roofDestination, false, QAngle(0, 0, 0), false, Vector(0, 0, 0));
	}
	
	Assert(gmed != null);
	
	__CollectGameEventCallBacks(bossFight)
}

function RegisterGmed(tag) {
	for(local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i);
		if(player == null) continue;
		if(!IsPlayerABot(player)) continue;
		
		if(player.HasBotTag(tag) && NetProps.GetPropInt(player, "m_lifeState") == 0) {
			gmed = player;
		}
	}
}

function PrecacheParticle(name) {
    PrecacheEntityFromTable({classname = "info_particle_system", 
		effect_name = name})
}

function SummonMimics() { //commons cleared, set up the player mimics
	PrecacheParticle("utaunt_hellswirl_flames")
	PrecacheParticle("utaunt_hellswirl_smoke")
	PrecacheParticle("utaunt_hellswirl_smoke_land")

	gmed.AddCondEx(TF_COND_INVULNERABLE, 4);
	gmed.AddBotAttribute(SUPPRESS_FIRE)
	gmed.Taunt(TAUNT_BASE_WEAPON, MP_CONCEPT_PLAYER_TAUNT)
	//MP_CONCEPT_TAUNT_HEROIC_POSE
	
	local origin = gmed.GetOrigin()
	local angles = gmed.GetAbsAngles()
	
	//this likely has the same issue of being infinite, fix later
	DispatchParticleEffect("utaunt_hellswirl_flames", origin, angles)
	DispatchParticleEffect("utaunt_hellswirl_smoke", origin, angles)
	DispatchParticleEffect("utaunt_hellswirl_smoke_land", origin, angles)
	
	MimicPlayers()
	EntFire(gmed, "runscriptcode", "teleportBots(self.GetOrigin(), self.GetAbsAngles())", 3)
}

function teleportBots(origin, angles) {
	foreach(bot in bots) {
		bot.Teleport(true, origin + Vector(0, 40, 0), true, angles, false, Vector(0, 0, 0))
	}
}

function MimicPlayers() { //copy player weapon/hat attributes to bots
	local totalPlayerCount = players.len();
	const TOTALHP = 21000;
	local bothp = TOTALHP / totalPlayerCount;
	local attackBotCount = 0;
	
	foreach(player in players) {
		local botName = null
		local bot = null
		local primaryAttr = null
		local meleeAttr = null
	
		local primary = null
		local secondary = null
		local melee = null
		
		for (local i = 0; i < 5; i++) {
			local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i);
			if (weapon == null) {
				continue;
			}
			switch(weapon.GetSlot()) {
				case 0:
					primary = weapon;
					break;
				case 1:
					secondary = weapon;
					break;
				case 2:
					melee = weapon;
					break;
			}
		}
		
		//count the number of primary and melee attributes here
		
		attackBotCount++;
		botName = "attack" + attackBotCount;
		bot = Entities.FindByName(null, botName)
		//force respawn the bots here
		
		bot.GenerateAndWearItem(secondary.GetName())
		
		
		for(local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer()) {
			if(wearable.GetClassname() != "tf_wearable")
				continue;
			//bot.GenerateAndWearItem(
			//need to make an item list
		}
		
		//set uber here
	}

	//kill extra bots that don't need to exist
}

function FindMimickingBot(player) {
	//check table to see if player has a paired bot

}

function SetBotAggroOnPlayer(player, bot) {
	//see if setattentionfocus works here
	//make bot aggro/focus player
}



//copying attrs

function SetTargetNames() {

}