//w6 boss fight vscript
local players = {};
local gmed = null;

function StartBossFight() {
	local roofDestination = Entities.FindByName(null, "roof_player_destination").GetOrigin();
	
	for(local i = 1; i <= Constants.Server.MAX_PLAYERS; i++) {
		local player = PlayerInstanceFromIndex(i);
		if(player == null) continue;
		if(IsPlayerABot(player)) continue;
		
		//1s delay
		ScreenFade(player, 255, 255, 255, 255, .5, 1);
		
		if(player.GetTeam() == 2) {
			//1s delay
			player.Teleport(true, roofDestination, false, QAngle(0, 0, 0), false, Vector(0, 0, 0));
		}
	}
	
	Assert(gmed != null);
	
	gmed.ValidateScriptScope();
	gmed.GetScriptScope().recallStage <- 0;
	gmed.GetScriptScope().spawnOrigin <- Entities.FindByName(null, "spawnbot_roof").GetOrigin();
	gmed.GetScriptScope()["Think"] <- function() { //adaption of royal logic
		//boss damage callback exists here, but vscript ver doesn't work?
		const THRESHOLD = 500; //crit max dmg xbow?
		
		self.AddCond(Constants.ETFCond.TF_COND_PREVENT_DEATH);
		
		if(self.GetHealth() < THRESHOLD) {
			foreach(player in players) {
				//show text
				//player sound
			}
			
			self.Teleport(true, spawnOrigin, false, QAngle(0, 0, 0), false, Vector(0, 0, 0));
			self.GetScriptScope().recallStage++;
			self.SetHealth(self.GetMaxHealth());
			
			switch(self.GetScriptScope().recallStage) {
				case 1:
					EntFire("pop_interface", "ChangeBotAttributes", "shotgun");
					break;
				case 2:
					EntFire("pop_interface", "ChangeBotAttributes", "crossbow");
					break;
				case 3:
					self.RemoveCond(Constants.ETFCond.TF_COND_SODAPOPPER_HYPE);
					EntFire("pop_interface", "ChangeBotAttributes", "vita2");
					AddThinkToEnt(self, null);
					NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
					delete self.GetScriptScope().recallStage;
					delete self.GetScriptScope().spawnOrigin;
					break;
			}
		}
	}
}

function RegisterGmed(tag) {
	for(local i = 1; i <= Constants.Server.MAX_PLAYERS; i++) {
		local player = PlayerInstanceFromIndex(i);
		if(player == null) continue;
		if(!IsPlayerABot(player)) continue;
		
		if(player.HasBotTag(tag)) {
			gmed = player;
		}
	}
}

function SummonMimics() { //commons cleared, set up the player mimics
	gmed.AddCondEx(Constants.ETFCond.TF_COND_INVULNERABLE, 4);
	//prevent gmed from attacking
	//taunt
	
	//DispatchParticleEffect
	
	//stun medic, dispatch particles, teleport mimics up
	
	//3s delay
	
	
}

function MimicPlayers() { //copy player weapon/hat attributes to bots
	local totalPlayerCount = players.len();
	const TOTALHP = 21000;
	local bothp = TOTALHP / totalPlayerCount;
	
	foreach(player in players) {
	
	
	
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