local allRooms = [1, 2, 3, 4, 5, 6, 7];
local assignedRooms = {} //key = tag, value = occupied room
local preassignedRooms = {} //rooms that aren't in the first 7 that want a specific room
local tagsThatNeedRooms = []
local listOfTags = {} //key = tag, value = list of bots with tag
local brokenRooms = []
local isContainmentBreaker = false
local timeCounter = 0
local soundPlaying = false

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

function addTags(max) { //last room, inclusive
	for(local i = 1; i <= max; i++) {
		local tag = "ws" + i
		listOfTags[tag] <- {}
		listOfTags[tag].botList <- []
		listOfTags[tag].timer <- Timer()
		listOfTags[tag].hasSpawned <- false
		listOfTags[tag].isEligibleToTeleport <- false

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
	allRooms.remove(allRooms.find(room));
}

function pickRoom(tag) { //assign a random room to a tag
	local index = RandomInt(0, allRooms.len() - 1);
	local room = allRooms[index];

	assignedRooms[tag] <- room;
	allRooms.remove(index);

	//printl(tag + " assigned to room " + room)
}

function teleportBotsToRoom(tag) { //enable teleporter once bots are ready to teleport in
	local room = assignedRooms[tag]
	StartRoom(tag)
	local dest = Entities.FindByName(null, "alt_destination_" + room)
	foreach(bot in listOfTags[tag].botList) {
		bot.Teleport(true, dest.GetOrigin(), false, QAngle(), true, Vector())
	}
	//delete listOfTags[tag]
	//printl(tag + " teleported")
}

function StartRoom(tag) { //turn on a room's effects
	local room = assignedRooms[tag];

	//push is separate to ensure players can't get stuck
	EntFire("push_" + room, "Enable", null, -1);
	EntFire("push_" + room, "Disable", null, 1.3);
	if(brokenRooms.find(room)) {
		return
	}

	EmitSoundEx({
		sound_name = teleSound
		filter = RECIPIENT_FILTER_GLOBAL
	});
	EntFire("blocker_" + room, "BlockNav")
	EntFire("light_" + room, "SetPattern", "m");
	EntFire("notaunt_" + room, "Enable")
	EntFire("physbox_" + room, "FireUser1");
	EntFire("physbox_" + room, "runscriptcode", "self.SetSolid(6)");
	EntFire("respawnvis_" + room, "Enable");
	//printl(room + " started")
}

function DoneRoom(tag) { //disable room, called by pop
	if(!(tag in assignedRooms)) {
		return
	} //in case of containment breaking, where doneroom could've been called before pop did

	local room = assignedRooms[tag];
	delete assignedRooms[tag];
	allRooms.append(room);

	EntFire("light_" + room, "SetPattern", "mmmmoooopppprrrrttttvvvvxxxxzzzz");
	EntFire("light_" + room, "Toggle", null, 3);
	EntFire("blocker_" + room, "UnblockNav")
	EntFire("notaunt_" + room, "Disable")
	EntFire("physbox_" + room, "AddOutput", "origin -9999 -9999 -9999");
	EntFire("physbox_" + room, "runscriptcode", "self.SetSolid(0)");
	EntFire("respawnvis_" + room, "Disable");

	if(!isContainmentBreaker) {
		if(timer != null) {
			timer.AcceptInput("CallScriptFunction", "addTime", null, null)
		}
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
	//printl(room + " done")
}

function startWave() {
	for(local i = 1; i < listOfTags.len(); i++) {
		local tag = "ws" + i
		listOfTags[tag].timer.Start((i - 1) * 15)
	}
	AddThinkToEnt(self, "checkThink")
}

function checkThink() {
	local tagsToRemove = []

	foreach(tag, data in listOfTags) {
		if(data.timer.Expired()) {
			data.isEligibleToTeleport = true
		}
		if(data.hasSpawned && data.isEligibleToTeleport && tag in assignedRooms) {
			teleportBotsToRoom(tag)
			tagsToRemove.append(tag)
		}
	}
	foreach(tag in tagsToRemove) {
		delete listOfTags[tag]
	}

	if(!isContainmentBreaker) return 0.1

	if(timeCounter == 0) {
		local tempTable = {}
		foreach(tag, room in assignedRooms) { //i hate this
			tempTable[tag] <- room
		}

		foreach(tag, room in tempTable) {
			//if(tag in listOfTags) continue //only break rooms that have actively spawned
			if(RandomInt(0, 9) == 0) {
				EmitSoundEx({
					sound_name = alarmSound
					filter = RECIPIENT_FILTER_GLOBAL
				});
				chaosCallbacks.alarmCount++
				soundPlaying = true
				DoneRoom(tag) //doneroom deletes from assignedRooms
				brokenRooms.append(room)
			}
		}
	}
	if(timeCounter == 3 && soundPlaying) {
		EmitSoundEx({
			sound_name = alarmSound
			filter = RECIPIENT_FILTER_GLOBAL
			flags = 4 //snd_stop
		})
		soundPlaying = false
		chaosCallbacks.alarmCount--
	}

	timeCounter = timeCounter + 1 > 3 ? 0 : timeCounter + 1
	return 1
}

function setIsContainmentBreaker(state) {
	isContainmentBreaker = state
}

function getRoom(tag) {
	if(tag in assignedRooms) {
		return assignedRooms[tag]
	}
	else {
		return null
	}
}