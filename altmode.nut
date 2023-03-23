const HIGHEST_DOWNSTAIR_ROOM = 4;
local downstairsRooms = [1, 2, 3, 4];
local upstairsRooms = [5, 6, 7];
local currentRoom = null;

function WaveInit() { //on wave init teleport players to spawn
	
	foreach(val in downstairsRooms) {
		printl(val);
	}
	foreach(val in upstairsRooms) {
		printl(val);
	}
	if(!IsSoundPrecached("weapons/drg_pomson_drain_01.wav")) {
		PrecacheSound("weapons/drg_pomson_drain_01.wav");
	}
	
	local spawnOrigin = Entities.FindByName(null, "teamspawn_all").GetOrigin();
	
	for (local i = 1; i <= Constants.Server.MAX_PLAYERS; i++) {
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
	EntFire("light_" + room, "SetPattern", "m");
	EntFire("notaunt_" + room, "Enable");
	EntFire("notaunt_toggle_" + room + "_relay", "Enable");
	EntFire("physbox_" + room, "FireUser1");
	EntFire("physbox_" + room, "AddOutput", "solid 6");
	EntFire("pomson_" + room, "Enable");
	EntFire("push_" + room, "Enable");
	EntFire("push_" + room, "Disable", null, 1.3);
	EntFire("respawnvis_" + room, "Enable");
	EntFire("teleport_spawn_*", "Enable");
	EntFire("teleport_spawn_*", "AddOutput", "target alt_spawn_" + room);
	//for single room just enable/disable all the teleport spawns
}

function DoneRoom(room) { //room done, disable everything

	EntFire("teleport_spawn_*", "AddOutput", "target ``"); //check this
	
	EntFire("light_" + room, "SetPattern", "mmmmoooopppprrrrttttvvvvxxxxzzzz");
	EntFire("light_" + room, "Toggle", null, 3);
	EntFire("notaunt_" + room + "*", "Disable");
	EntFire("physbox_" + room, "AddOutput", "origin -9999 -9999 -9999");
	EntFire("physbox_" + room, "AddOutput", "solid 0");
	EntFire("pomson_" + room, "Disable");
	EntFire("respawnvis_" + room, "Disable");
	if(timer != null) {
		timer.SetHealth(timer.GetHealth() + timer.GetMaxHealth() / 5);
		//lazy calc for now
	}
}

function PickNextRoom(){ //pick next room, if floor is clear swap to other floor
	DoneRoom(currentRoom);
	
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