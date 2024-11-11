const EMPTY = 0
const OCCUPIED = 1
const BROKEN = 2

local allRooms = {}
allRooms[1] <- EMPTY
allRooms[2] <- EMPTY
allRooms[3] <- EMPTY
allRooms[4] <- EMPTY
allRooms[5] <- EMPTY
allRooms[6] <- EMPTY
allRooms[7] <- EMPTY

local assignedRooms = {} //key = tag, value = occupied room
local preassignedRooms = {} //rooms that aren't in the first 7 that want a specific room
local tagsThatNeedRooms = []
local listOfTags = {} //key = tag, value = list of bots with tag
local isContainmentBreaker = false
local timeCounter = 0
local lastDoneRoom = null

if("chaosCallbacks" in getroottable()) { //entities appear to get recreated before recalc holiday fires
	chaosCallbacks.cleanup()
}
::chaosCallbacks <- {
	alarmCount = 0

	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return

		EntFire("altmode_chaos_script", "callscriptfunction", "checkTags", -1, player)
	}

	cleanup = function() {
		AddThinkToEnt(Entities.FindByName(null, "altmode_chaos_script"), null)

		for(local i = 0; i < alarmCount; i++) {
			EmitSoundEx({
				sound_name = alarmSound
				filter = RECIPIENT_FILTER_GLOBAL
				flags = 4 //snd_stop
			})
		}
		delete ::chaosCallbacks
	}

	OnGameEvent_recalculate_holidays = function(_) {
		if(GetRoundState() == 3) {
			cleanup()
		}
	}

	OnGameEvent_mvm_wave_complete = function(_) {
		cleanup()
	}
}

function checkTags() {
	local tags = {}
	activator.GetAllBotTags(tags)
	foreach(i, tag in tags) {
		if(tag in listOfTags) {
			listOfTags[tag].botList.append(activator)
			listOfTags[tag].hasSpawned = true
			break
		}
	}
}

function addTags(max, preassignTable = {}) { //last room, inclusive
	for(local i = 1; i <= max; i++) {
		local tag = "ws" + i
		listOfTags[tag] <- {}
		listOfTags[tag].botList <- []
		listOfTags[tag].timer <- Timer()
		listOfTags[tag].hasSpawned <- false
		listOfTags[tag].isEligibleToTeleport <- false
		listOfTags[tag].hasTeleported <- false
		listOfTags[tag].assignedRoom <- null

		if(tag in assignedRooms) continue
		if(i <= 7) { //preload the first 7 wavespawns
			pickRoom(tag)
		}
		else {
			if(!(tag in preassignedRooms)) {
				tagsThatNeedRooms.append(tag)
			}
		}
	}
}

function preassignRoom(tag, room) {
	preassignedRooms[tag] <- room
}

function lockRoom(tag, room) { //assign preselected room to tag
	assignedRooms[tag] <- room;
	allRooms[room] = OCCUPIED
}

function pickRoom(tag) { //assign a random room to a tag
	local openRooms = allRooms.filter(@(key, val) val == EMPTY).keys()

	local index = RandomInt(0, openRooms.len() - 1);
	local room = openRooms[index];
	//printl(tag + " assigned to room " + room)

	assignedRooms[tag] <- room;
	allRooms[room] = OCCUPIED
}

function teleportBotsToRoom(tag) { //enable teleporter once bots are ready to teleport in
	local room = assignedRooms[tag]
	StartRoom(tag)
	local dest = Entities.FindByName(null, "alt_destination_" + room)
	foreach(bot in listOfTags[tag].botList) {
		bot.Teleport(true, dest.GetOrigin(), false, QAngle(), true, Vector())
	}
	//printl(tag + " teleported")
}

function getAdjacentRoom(room) {
	local adjacentRoom = -1
	switch(room) {
		case 1:
			adjacentRoom = 4
			break;
		case 2:
			adjacentRoom = 3
			break;
		case 3:
			adjacentRoom = 2
			break;
		case 4:
			adjacentRoom = 1;
			break;
		case 6:
			adjacentRoom = 7;
			break;
		case 7:
			adjacentRoom = 6;
			break;
		default:
			break;
	}
	return adjacentRoom
}

function StartRoom(tag) { //turn on a room's effects
	local room = assignedRooms[tag];

	//push is separate to ensure players can't get stuck
	EntFire("push_" + room, "Enable", null, -1);
	EntFire("push_" + room, "Disable", null, 1.3);
	if(allRooms[room] == BROKEN) {
		return
	}

	EmitSoundEx({
		sound_name = teleSound
		filter = RECIPIENT_FILTER_GLOBAL
	});
	EntFire("blocker_" + room, "BlockNav")
	EntFire("light_" + room, "SetPattern", "m");
	EntFire("notaunt_" + room + "*", "Enable")
	EntFire("physbox_" + room, "FireUser1");
	EntFire("physbox_" + room, "runscriptcode", "self.SetSolid(6)");
	EntFire("respawnvis_" + room, "Enable");
	
	/*
	local adjacentRoom = getAdjacentRoom(room)
	if(adjacentRoom != -1 && allRooms[adjacentRoom] == OCCUPIED) {
		EntFire("notaunt_" + room + "_overlapping", "Disable")
		EntFire("notaunt_" + adjacentRoom + "_overlapping", "Disable")
	}
	*/
}

function DoneRoom(tag, wasCalledByPop = false) { //disable room, called by pop
	if(wasCalledByPop) { //we are done with this room
		delete listOfTags[tag]
	}

	if(!(tag in assignedRooms)) {
		return
	} //in case of containment breaking, where doneroom could've been called before pop did or the same room broken multiple times
	
	local room = assignedRooms[tag];
	delete assignedRooms[tag];
	allRooms[room] = EMPTY

	EntFire("light_" + room, "SetPattern", "mmmmoooopppprrrrttttvvvvxxxxzzzz");
	EntFire("light_" + room, "Toggle", null, 3);
	EntFire("blocker_" + room, "UnblockNav")
	EntFire("notaunt_" + room + "*", "Disable")
	EntFire("respawnvis_" + room, "Disable");
	EntFire("physbox_" + room, "runscriptcode", "self.SetSolid(0)", -1);
	EntFire("physbox_" + room, "RunScriptCode", "self.Teleport(true, Vector(-9999, -9999, -9999), false, QAngle(), false, Vector())", 0.1);
	
	if(!isContainmentBreaker) {
		if(timer != null) {
			timer.AcceptInput("CallScriptFunction", "addTime", null, null)
		}
		/*
		local adjacentRoom = getAdjacentRoom(room)
		if(adjacentRoom != -1 && allRooms[adjacentRoom] == OCCUPIED) {
			EntFire("notaunt_" + adjacentRoom + "_overlapping", "Enable")
		}
		*/
	}
	else { //this runs pretty slowly, so reduce the amount of times it's called
		EntFire("nav_interface", "RecomputeBlockers") //apparently bots respect block without a recompute, but need to recompute for unblock?
	}

	local filtered = preassignedRooms.filter(@(key, val) val == room)
	if(filtered.len() > 0) {
		local key = filtered.keys()[0]
		lockRoom(key, room)
		delete preassignedRooms[key]
	}
	else if(tagsThatNeedRooms.len() > 0) {
		local index = RandomInt(0, tagsThatNeedRooms.len() - 1)
		local newTag = tagsThatNeedRooms.remove(index)
		lockRoom(newTag, room)
	}

	local nextTagInt = tag.slice(2).tointeger() + 1
	local nextTag = "ws" + nextTagInt
	if(nextTag in listOfTags) { //if next room hasn't started yet, mark it as ready
		listOfTags[nextTag].isEligibleToTeleport = true
	}
}

function startWave() {
	for(local i = 1; i < listOfTags.len(); i++) {
		local tag = "ws" + i
		listOfTags[tag].timer.Start((i - 1) * 15)
	}
	AddThinkToEnt(self, "checkThink")
}

function checkThink() {
	foreach(tag, data in listOfTags) {
		if(data.hasTeleported) continue
		if(data.timer.Expired()) {
			data.isEligibleToTeleport = true
		}
		if(data.hasSpawned && data.isEligibleToTeleport && tag in assignedRooms) {
			teleportBotsToRoom(tag)
			data.hasTeleported = true
		}
	}
}

function breakerThink() {
	if(timeCounter % 3 == 0) { //0, 3, 6
		foreach(tag, data in listOfTags) {
			local room = tag in assignedRooms ? assignedRooms[tag] : null
		
			if(!data.hasTeleported) {
				if(data.timer.Expired()) { //similar to the above but doesn't do the visual stuff
					data.isEligibleToTeleport = true
				}
				if(data.hasSpawned && data.isEligibleToTeleport && tag in assignedRooms) {
					allRooms[room] = BROKEN
					teleportBotsToRoom(tag)
					data.hasTeleported = true
					delete assignedRooms[tag]
				}
			}
			else {
				if(RandomInt(0, 9) == 0) {
					EmitSoundEx({
						sound_name = alarmSound
						filter = RECIPIENT_FILTER_GLOBAL
					});
					EmitSoundEx({
						sound_name = alarmSound
						filter = RECIPIENT_FILTER_GLOBAL
					});
					chaosCallbacks.alarmCount += 2
					DoneRoom(tag) //doneroom deletes from assignedRooms
					allRooms[room] = BROKEN
					foreach(bot in listOfTags[tag].botList) {
						if("onContainmentBreach" in bot.GetScriptScope()) {
							bot.GetScriptScope().onContainmentBreach()
						}
					}
				}
			}
		}
	}
	if(timeCounter == 6 && chaosCallbacks.alarmCount > 0) {
		EmitSoundEx({
			sound_name = alarmSound
			filter = RECIPIENT_FILTER_GLOBAL
			flags = 4 //snd_stop
		})
		EmitSoundEx({
			sound_name = alarmSound
			filter = RECIPIENT_FILTER_GLOBAL
			flags = 4 //snd_stop
		})
		chaosCallbacks.alarmCount -= 2
	}

	timeCounter = timeCounter + 1 > 7 ? 0 : timeCounter + 1
	return 0.9
}

function setIsContainmentBreaker(state) {
	isContainmentBreaker = state
	if(state) {
		EntFire("pop_interface", "ChangeBotAttributes", "SwitchToMobber", -1)
		EntFire("pop_interface", "ChangeDefaultEventAttributes", "SwitchToMobber", -1)
		AddThinkToEnt(self, "breakerThink")
	}
}

function getContainmentBreakerState() {
	return isContainmentBreaker
}

function getRoom(tag) {
	if(tag in assignedRooms) {
		return assignedRooms[tag]
	}
	else {
		return null
	}
}