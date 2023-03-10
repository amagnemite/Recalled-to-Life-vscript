local downstairsRooms = [1, 2, 3, 4];
local upstairsRooms = [5, 6, 7];
local allRooms = [1, 2, 3, 4, 5, 6, 7];
const HIGHEST_DOWNSTAIR_ROOM = 4;
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
		local player = PlayerInstanceFromIndex(i)
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
	StartRoom(firstRoom, null);
	
	currentRoom = firstRoom;
	
	if(firstRoom <= HIGHEST_DOWNSTAIR_ROOM) { //downstairs
		EntFire("downstairs_initial_annotation", "Show");
	}
	else { //upstairs
		EntFire("upstairs_initial_annotation", "Show");
	}
}

function ChaosWaveStart() {
	local startingRooms = [1, 6, 7];
	local firstRoom = startingRooms[RandomInt(0, 2)];
	StartRoom(firstRoom);
	
	allRooms.remove(currentArray.find(firstRoom));

}

function StartRoom(room, teleport) { //enable room
	if(teleport != null) {
		//training annotation
	}
	else {
		teleport = 1;
	}
	//todo: fix above

	EntFire("light_" + room, "SetPattern", "m");
	EntFire("notaunt_" + room, "Enable");
	EntFire("notaunt_toggle_" + room + "_relay", "Enable");
	EntFire("physbox_" + room, "FireUser1");
	EntFire("physbox_" + room, "AddOutput", "solid 6");
	EntFire("pomson_" + room, "Enable");
	EntFire("push_" + room, "Enable");
	EntFire("push_" + room, "Disable", null, 1.3);
	EntFire("respawnvis_" + room, "Enable");
	EntFire("teleport_spawn_" + teleport, "Enable");
	EntFire("teleport_spawn_" + teleport, "AddOutput", "target alt_spawn_" + room);
}

function DoneRoom(room, teleport) { //room done, disable everything
	EntFire("teleport_spawn_1", "AddOutput", "target ``"); //check this
	
	EntFire("light_" + room, "SetPattern", "mmmmoooopppprrrrttttvvvvxxxxzzzz");
	EntFire("light_" + room, "Toggle", null, 3);
	EntFire("notaunt_*", "Disable");
	EntFire("physbox_" + room, "AddOutput", "origin -9999 -9999 -9999");
	EntFire("physbox_" + room, "AddOutput", "solid 0");
	EntFire("pomson_" + room, "Disable");
	EntFire("respawnvis_" + room, "Disable");
	EntFire("timer_script", "RunScriptCode", "AddTime(51)");
}

function PickNextRoom() { //pick next room, if floor is clear swap to other floor
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

function ChaosPickNextRoom() {
	//when room is done -> doneroom
	//when a new room is starting, irrespective if a diff room is running
}