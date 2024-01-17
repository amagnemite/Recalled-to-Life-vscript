//common stuff for all altmode vers
::MaxPlayers <- MaxClients().tointeger();

foreach (a,b in Constants)
	foreach (k,v in b)
		if (!(k in getroottable()))
			getroottable()[k] <- v;
			
PrecacheSound("weapons/drg_pomson_drain_01.wav");
PrecacheSound("mvm/mvm_tele_activate.wav");

::teleSound <- "mvm/mvm_tele_activate.wav";