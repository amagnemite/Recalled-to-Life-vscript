const HIGHEST_DOWNSTAIR_ROOM = 4;
local downstairsRooms = [1, 2, 3, 4];
local upstairsRooms = [5, 6, 7];
local currentRoom = null;

function WaveInit() { //on wave init teleport players to spawn
	//this is also used in roof 
	downstairsRooms = [1, 2, 3, 4];
	upstairsRooms = [5, 6, 7];
}

function WaveStart() { //called whenever an altmode wave starts
	local startingRooms = [1, 6, 7];
	local firstRoom = startingRooms[RandomInt(0, 2)];
	__CollectGameEventCallbacks(desquad);
	
	currentRoom = firstRoom;
	StartRoom();
	
	if(firstRoom <= HIGHEST_DOWNSTAIR_ROOM) { //downstairs
		showAnnotation("The robots are invading downstairs!", -1658, 4512,720);
	}
	else { //upstairs
		showAnnotation("The robots are invading upstairs!", -1600, 3904, 1104);
	}
}

function StartRoom() { //enable room
	EntFire("light_" + currentRoom, "SetPattern", "m");
	AddThinkToEnt(Entities.FindByName(null, "notaunt_" + currentRoom), "notauntThink")
	EntFire("blocker_" + currentRoom, "BlockNav")
	EntFire("physbox_" + currentRoom, "FireUser1");
	EntFire("physbox_" + currentRoom, "AddOutput", "solid 6");
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
	AddThinkToEnt(Entities.FindByName(null, "notaunt_" + currentRoom), null)
	EntFire("notaunt_" + currentRoom, "Disable", 0.1);
	EntFire("blocker_" + currentRoom, "UnblockNav")
	EntFire("physbox_" + currentRoom, "AddOutput", "origin -9999 -9999 -9999");
	EntFire("physbox_" + currentRoom, "AddOutput", "solid 0");
	EntFire("respawnvis_" + currentRoom, "Disable");
	EntFire("timer", "CallScriptFunction", "addTime")
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