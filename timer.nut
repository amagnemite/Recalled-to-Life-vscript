local healthBar = Entities.FindByClassname(null, "monster_resource")
local TOTAL_TIME = 150; //2.5
local LOW_TIME = 255 * .2;
local REFIRE_TIME = TOTAL_TIME / 255;
local counter = 255;

function Start() {
	NetProps.SetPropInt(healthBar, "m_iBossHealthPercentageByte", 255);
	AddThinkToEnt(self, "Think");
}

function Think() {
	counter--;
	NetProps.SetPropInt(healthBar, "m_iBossHealthPercentageByte", counter);
	
	if(counter == 0) {
		EntFire("bots_win", "RoundWin");
	}

	return REFIRE_TIME;
}

function AddTime(time) {
	counter = counter + time > 255 ? 255 : counter + time
	CheckTime();
}

//if 1/5 time left, change bar to green ver
function CheckTime() {
	if(counter < LOW_TIME) {
		NetProps.SetPropInt(healthBar, "m_iBossState", 1);
	}
	else {
		NetProps.SetPropInt(healthBar, "m_iBossState", 0);
	}
}

function OnGameEvent_mvm_wave_failed() {
	AddThinkToEnt(self, null);
	self.TerminateScriptScope();
}

function OnGameEvent_mvm_wave_complete() {
	AddThinkToEnt(self, null);
	self.TerminateScriptScope();
}