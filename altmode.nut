local downstairsRooms = [1, 2, 3, 4];
local upstairsRooms = [5, 6, 7];
local HIGHEST_DOWNSTAIR_ROOM = 4;
local currentRoom = null;

function WaveInit() { //on wave init teleport players to spawn
	self.ValidateScriptScope();
	local spawn = Entities.FindByName(null, "teamspawn_all");
	
	while(player = Entities.FindByClassname(player, "player")) {
	  if(!IsPlayerABot(player) && player.GetTeam() == 2) {
		player:Teleport(true, spawn.GetOrigin());
	  }
	}
}

function WaveStart() { //called whenever an altmode wave starts
	//self.TerminateScriptScope(); //make sure a fresh instance is running every time it's called
	
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
	EntFire("notaunt_" + room + "*", "Enable");
	EntFire("physbox_" + room, "FireUser1");
	EntFire("physbox_" + room, "AddOutput", "solid 6");
	EntFire("pomson_" + room, "Enable");
	EntFire("push_" + room, "Enable");
	EntFire("push_" + room, "Disable", null, 1.3);
	EntFire("respawnvis_" + room, "Enable");
	EntFire("teleport_spawnbot_roof" + room, "AddOutput", "target alt_spawn_" + room);
}

function DoneRoom() { //room done, disable everything
	//local relayName = "altmode_done_" + currentRoom + "_relay";

	EntFire("teleport_spawnbot_roof", "AddOutput", "target ``"); //check this
	//EntFire(relayName, "Trigger");
	
	EntFire("light_" + room, "SetPattern", "mmmmoooopppprrrrttttvvvvxxxxzzzz");
	EntFire("light_" + room, "Toggle", null, 3);
	EntFire("notaunt_" + room + "*", "Disable");
	EntFire("physbox_" + room, "AddOutput", "origin -9999 -9999 -9999");
	EntFire("physbox_" + room, "AddOutput", "solid 0");
	EntFire("pomson_" + room, "Disable");
	EntFire("respawnvis_" + room, "Disable");
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