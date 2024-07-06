//common stuff for all altmode vers
::MaxPlayers <- MaxClients().tointeger();

foreach (a,b in Constants)
	foreach (k,v in b)
		if (!(k in getroottable()))
			getroottable()[k] <- v;
			
PrecacheSound("weapons/drg_pomson_drain_01.wav");
PrecacheSound("mvm/mvm_tele_activate.wav");

::teleSound <- "mvm/mvm_tele_activate.wav";

::checkRage <- function() {
	if(activator.IsRageDraining()) {
		NetProps.SetPropFloat(activator, "m_Shared.m_flRageMeter", 0)
		pomsonSound(activator)
	}
}

::pomsonSound <- function(player) {
	EmitSoundEx({
		sound_name = "weapons/drg_pomson_drain_01.wav"
		volume = 0.6
		origin = player.GetOrigin()
		filter_type = 4
		entity = player
	})
}
