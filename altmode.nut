local downstairsRooms = [1, 2, 3, 4];
local upstairsRooms = [5, 6, 7];
local HIGHEST_DOWNSTAIR_ROOM = 4;
local currentRoom = null;

function WaveInit() { //on wave init teleport players to spawn
	self.TerminateScriptScope();
	self.ValidateScriptScope();
	
	//printl(self.ValidateScriptScope());
	PrecacheSound("weapons/drg_pomson_drain_01.wav");
	
	local spawn = Entities.FindByName(null, "teamspawn_all");
	
	local player = null;
	while(player = Entities.FindByClassname(player, "player")) {
	  if(!IsPlayerABot(player) && player.GetTeam() == 2) {
		player.Teleport(true, spawn.GetOrigin(), false, QAngle(0, 0, 0), false, Vector(0, 0, 0));
	  }
	}
}

function WaveStart() { //called whenever an altmode wave starts
	local startingRooms = [1, 6, 7];
	local firstRoom = startingRooms[RandomInt(0, 2)];
	StartRoom(firstRoom);
	
	currentRoom = firstRoom;
	
	if(firstRoom <= HIGHEST_DOWNSTAIR_ROOM) { //downstairs
		EntFire("downstairs_initial_annotation", "Show");
	}
	else { //upstairs
		EntFire("upstairs_initial_annotation", "Show");
	}
}

function StartRoom(room) { //enable room
	//local relayName = "altmode_start_" + room + "_relay";
	//EntFire(relayName, "Trigger");
	
	EntFire("light_" + room, "SetPattern", "m");
	EntFire("notaunt_" + room, "Enable");
	EntFire("notaunt_toggle_" + room + "_relay", "Enable");
	EntFire("physbox_" + room, "FireUser1");
	EntFire("physbox_" + room, "AddOutput", "solid 6");
	EntFire("pomson_" + room, "Enable");
	EntFire("push_" + room, "Enable");
	EntFire("push_" + room, "Disable", null, 1.3);
	EntFire("respawnvis_" + room, "Enable");
	EntFire("teleport_spawnbot_roof", "AddOutput", "target alt_spawn_" + room);
}

function DoneRoom() { //room done, disable everything
	//local relayName = "altmode_done_" + currentRoom + "_relay";

	EntFire("teleport_spawnbot_roof", "AddOutput", "target ``"); //check this
	//EntFire(relayName, "Trigger");
	
	EntFire("light_" + currentRoom, "SetPattern", "mmmmoooopppprrrrttttvvvvxxxxzzzz");
	EntFire("light_" + currentRoom, "Toggle", null, 3);
	EntFire("notaunt_*", "Disable");
	EntFire("physbox_" + currentRoom, "AddOutput", "origin -9999 -9999 -9999");
	EntFire("physbox_" + currentRoom, "AddOutput", "solid 0");
	EntFire("pomson_" + currentRoom, "Disable");
	EntFire("respawnvis_" + currentRoom, "Disable");
}

function PickNextRoom() { //pick next room, if floor is clear swap to other floor
	DoneRoom();
	
	printl(currentRoom)
	local currentArray = currentRoom <= HIGHEST_DOWNSTAIR_ROOM ? downstairsRooms : upstairsRooms;
	currentArray.remove(currentArray.find(currentRoom));
	
	if(currentArray.len() == 0) { //no more rooms, switch floors
		if(currentArray == downstairsRooms) { //compare by reference
			currentArray = [1, 2, 3, 4];
			currentArray = upstairsRooms;
			EntFire("upstairs_annotation", "Show");
		}
		else {
			currentArray = [5, 6, 7];
			currentArray = downstairsRooms;
			EntFire("downstairs_annotation", "Show");
		}
	}
	local newRoomIndex = RandomInt(0, currentArray.len() - 1);
	currentRoom = currentArray[newRoomIndex];

	StartRoom(currentRoom);
}