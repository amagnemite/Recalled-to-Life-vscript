const HIGHEST_DOWNSTAIR_ROOM = 4;
local downstairsRooms = [1, 2, 3, 4];
local upstairsRooms = [5, 6, 7];
local currentRoom = null;

function WaveInit() { //on wave init teleport players to spawn
	
	/*
	foreach(val in downstairsRooms) {
		printl(val);
	}
	foreach(val in upstairsRooms) {
		printl(val);
	} */
	
	local spawnOrigin = Entities.FindByName(null, "teamspawn_all").GetOrigin();
	
	for (local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i);
		if(player == null) continue;
		if(IsPlayerABot(player)) continue;
		
		if(player.GetTeam() == 2) {
			player.Teleport(true, spawnOrigin, false, QAngle(0, 0, 0), false, Vector(0, 0, 0));
		}
	}
}

function WaveStart() { //called whenever an altmode wave starts
	local startingRooms = [1, 6, 7];
	local firstRoom = startingRooms[RandomInt(0, 2)];
	
	currentRoom = firstRoom;
	StartRoom();
	
	if(firstRoom <= HIGHEST_DOWNSTAIR_ROOM) { //downstairs
		EntFire("downstairs_initial_annotation", "Show");
	}
	else { //upstairs
		EntFire("upstairs_initial_annotation", "Show");
	}
}

function StartRoom() { //enable room
	EntFire("light_" + currentRoom, "SetPattern", "m");
	EntFire("notaunt_" + currentRoom, "Enable");
	EntFire("notaunt_toggle_" + currentRoom + "_relay", "Enable");
	EntFire("physbox_" + currentRoom, "FireUser1");
	EntFire("physbox_" + currentRoom, "AddOutput", "solid 6");
	EntFire("pomson_" + currentRoom, "Enable");
	EntFire("push_" + currentRoom, "Enable");
	EntFire("push_" + currentRoom, "Disable", null, 1.3);
	EntFire("respawnvis_" + currentRoom, "Enable");
	EntFire("teleport_spawn_*", "Enable");
	EntFire("teleport_spawn_*", "AddOutput", "target alt_spawn_" + currentRoom);
	//for single room just enable/disable all the teleport spawns
}

function DoneRoom() { //room done, disable everything

	EntFire("teleport_spawn_*", "AddOutput", "target \"\""); //check this
	
	EntFire("light_" + currentRoom, "SetPattern", "mmmmoooopppprrrrttttvvvvxxxxzzzz");
	EntFire("light_" + currentRoom, "Toggle", null, 3);
	EntFire("notaunt_" + currentRoom + "*", "Disable");
	EntFire("physbox_" + currentRoom, "AddOutput", "origin -9999 -9999 -9999");
	EntFire("physbox_" + currentRoom, "AddOutput", "solid 0");
	EntFire("pomson_" + currentRoom, "Disable");
	EntFire("respawnvis_" + currentRoom, "Disable");
	if(timer != null) {
		local health = (timer.GetHealth() + timer.GetMaxHealth() / 5) > timer.GetMaxHealth() ? timer.GetMaxHealth() : 
			timer.GetHealth() + timer.GetMaxHealth() / 5;
	
		timer.SetHealth(health);
		//lazy calc for now
	}
}

function PickNextRoom(){ //pick next room, if floor is clear swap to other floor
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

	StartRoom();
}