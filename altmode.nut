const HIGHEST_DOWNSTAIR_ROOM = 4;
local downstairsRooms = [1, 2, 3, 4];
local upstairsRooms = [5, 6, 7];
local currentRoom = null;

::regularCallbacks <- {
	cleanup = function() {
		delete ::regularCallbacks
	}

	OnGameEvent_recalculate_holidays = function(_) {
		if(GetRoundState() == 3) {
			cleanup()
		}
	}

	OnGameEvent_mvm_wave_complete = function(_) {
		cleanup()
	}
	
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return

		EntFire("altmode_script", "callscriptfunction", "teleportBot", -1, player)
	}
}

function teleportBot() {
	local dest = Entities.FindByName(null, "alt_destination_" + currentRoom)
	activator.SetAbsOrigin(dest.GetOrigin())
}

function WaveInit() {
	downstairsRooms = [1, 2, 3, 4];
	upstairsRooms = [5, 6, 7];
}

function WaveStart() { //called whenever an altmode wave starts
	local startingRooms = [1, 6, 7];
	local firstRoom = startingRooms[RandomInt(0, 2)];
	__CollectGameEventCallbacks(desquad);
	
	currentRoom = firstRoom;
	StartRoom();
	__CollectGameEventCallbacks(regularCallbacks)
	
	if(firstRoom <= HIGHEST_DOWNSTAIR_ROOM) { //downstairs
		showAnnotation("The robots are invading downstairs!", -1658, 4512, 720);
	}
	else { //upstairs
		showAnnotation("The robots are invading upstairs!", -1600, 3904, 1104);
	}
}

function StartRoom() { //enable room
	EntFire("light_" + currentRoom, "SetPattern", "m");
	EntFire("notaunt_" + currentRoom + "*", "Enable")
	EntFire("blocker_" + currentRoom, "BlockNav")
	EntFire("physbox_" + currentRoom, "FireUser1");
	EntFire("physbox_" + currentRoom, "RunScriptCode", "self.SetSolid(6)");
	EntFire("push_" + currentRoom, "Enable");
	EntFire("push_" + currentRoom, "Disable", null, 1.3);
	EntFire("respawnvis_" + currentRoom, "Enable");
}

function DoneRoom() { //room done, disable everything
	EntFire("light_" + currentRoom, "SetPattern", "mmmmoooopppprrrrttttvvvvxxxxzzzz");
	EntFire("light_" + currentRoom, "Toggle", null, 3);
	EntFire("notaunt_" + currentRoom + "*", "Disable", 0.1);
	EntFire("blocker_" + currentRoom, "UnblockNav")
	EntFire("physbox_" + currentRoom, "runscriptcode", "self.SetSolid(0)", -1);
	EntFire("physbox_" + currentRoom, "RunScriptCode", "self.Teleport(true, Vector(-9999, -9999, -9999), false, QAngle(), false, Vector())", 0.1);
	EntFire("respawnvis_" + currentRoom, "Disable");
	if(timer != null) {
		timer.AcceptInput("CallScriptFunction", "addTime", null, null)
	}
}

function PickNextRoom(){ //pick next room, if floor is clear swap to other floor
	DoneRoom();
	
	local currentArray = currentRoom <= HIGHEST_DOWNSTAIR_ROOM ? downstairsRooms : upstairsRooms;
	currentArray.remove(currentArray.find(currentRoom));
	
	if(currentArray.len() == 0) { //no more rooms, switch floors
		if(currentArray == downstairsRooms) { //compare by reference
			currentArray = [1, 2, 3, 4];
			currentArray = upstairsRooms;
			showAnnotation("The robots are invading upstairs!", -1600, 3904, 1104);
		}
		else {
			currentArray = [5, 6, 7];
			currentArray = downstairsRooms;
			showAnnotation("The robots are invading downstairs!", -1658, 4512, 720);
		}
	}
	local newRoomIndex = RandomInt(0, currentArray.len() - 1);
	currentRoom = currentArray[newRoomIndex];

	StartRoom();
}