local allRooms = [1, 2, 3, 4, 5, 6, 7];
local occupiedRooms = {} //key = teleporter that was used, value = occupied room

function PickRoom(teleporter) { //assign a room to a tele, called by pop
	local index = RandomInt(0, allRooms.len() - 1);
	local room = allRooms[index];
	
	occupiedRooms[teleporter] <- room;
	allRooms.remove(index);
	
	printl("teleporter " + teleporter + "room " + room)
}

function EnableTeleporter(teleporter) { //enable teleporter, called by pop
	//EntFire("teleport_spawn_" + teleporter, "Enable");
	EntFire("teleport_spawn_" + teleporter, "AddOutput", "target alt_spawn_" + occupiedRooms[teleporter]);
}

function StartRoom(room) { //turn on a room's effects, called by triggerEnt

	EntFireByHandle(caller, "Disable", null, -1, null, null);
	
	EntFire("room_annotation_" + room, "Show");
	//particle
	EmitSoundEx({
		sound_name = teleSound
		origin = triggerEnt.GetOrigin()
		filter = RECIPIENT_FILTER_GLOBAL
	});
	EntFire("light_" + room, "SetPattern", "m");
	EntFire("notaunt_" + room, "Enable");
	EntFire("notaunt_toggle_" + room + "_relay", "Enable");
	EntFire("physbox_" + room, "FireUser1");
	EntFire("physbox_" + room, "AddOutput", "solid 6");
	EntFire("push_" + room, "Enable", null, -1);
	EntFire("push_" + room, "Disable", null, 1.3);
	EntFire("respawnvis_" + room, "Enable");
}

function DoneRoom(teleporter) { //disable room, called by pop
	local room = occupiedRooms[teleporter];
	
	delete occupiedRooms[teleporter];
	allRooms.append(room);
	
	EntFire("room_trigger_" + room, "Enable");
	EntFire("teleport_spawn_" + teleporter, "AddOutput", "target \"\""); //check this
	
	EntFire("light_" + room, "SetPattern", "mmmmoooopppprrrrttttvvvvxxxxzzzz");
	EntFire("light_" + room, "Toggle", null, 3);
	EntFire("notaunt_" + room + "*", "Disable");
	EntFire("physbox_" + room, "AddOutput", "origin -9999 -9999 -9999");
	EntFire("physbox_" + room, "AddOutput", "solid 0");
	EntFire("respawnvis_" + room, "Disable");
	if(timer != null) {
		local health = (timer.GetHealth() + timer.GetMaxHealth() / 5) > timer.GetMaxHealth() ? timer.GetMaxHealth() : 
			timer.GetHealth() + timer.GetMaxHealth() / 5;
	
		timer.SetHealth(health);
		//lazy calc for now
	}
}