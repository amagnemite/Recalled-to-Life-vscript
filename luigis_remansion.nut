local scope = self.GetScriptScope();

scope.autoheal <- 0;
//scope["target"] <- null;
//scope.player <- null;
scope.medigun <- null;
scope.upgradeMultiplier <- 0;
scope.qfMultiplier <- 0;
scope.enemyTeam <- self.GetTeam() == 2 ? 3 : 2;
scope.type <- 0;
scope.charge <- 0;

foreach(a,b in Constants){foreach(k,v in b){if(!(k in getroottable())){getroottable()[k]<-v;}}} //takes all constant keyvals and puts them in global

function levelCheck(level) {
	//so on wave loss weapon entities get refreshed
	//ClientPrint(null, 3, "levelcheck " + level)
	if(level == 1) {
		autoheal = Convars.GetClientConvarValue("tf_medigun_autoheal", self.entindex());
		
		for(local i = 0; i < NetProps.GetPropArraySize(self, "m_hMyWeapons"); i++) {
			if(NetProps.GetPropEntityArray(self, "m_hMyWeapons", i).GetClassname() == "tf_weapon_medigun") {
				medigun = NetProps.GetPropEntityArray(self, "m_hMyWeapons", i);
				i = NetProps.GetPropArraySize(self, "m_hMyWeapons");
			}
		}
		
		type = NetProps.GetPropInt(medigun, "m_AttributeManager.m_Item.m_iItemDefinitionIndex");
		
		AddThinkToEnt(self, "FindTargetThink");
	}
	else if(level == 0) {
		RefundMain()
	}
}

function RefundMain() {
	AddThinkToEnt(self, null);
	self.TerminateScriptScope();
}

function SetQFTicks(ticks) {
	qfMultiplier = ticks;
}

function FindTargetThink() { //if not damaging bot, look for one
	local buttonPress = NetProps.GetPropInt(self, "m_nButtons");
	local fired = false;
	//printl("think")
	
	//if(buttonPress & IN_ATTACK) {
	//	fired = true;
	//}
	
	//if not attacking or in a state we can't/shouldn't drain
	//if(!fired || self.IsRageDraining() || self.InCond(TF_COND_TAUNTING)) { 
	if(!NetProps.GetPropBool(medigun, "m_bAttacking") || self.IsRageDraining() || self.InCond(TF_COND_TAUNTING)) { 
		return;
	}
	else if(NetProps.GetPropBool(medigun, "m_bHolstered")) {
		return;
	}

	if(!NetProps.GetPropBool(medigun, "m_bHealing")) { //not already healing someone
		if(NetProps.GetPropBool(medigun, "m_bAttacking")) {
			//no target, can look for a new one
			
			local enthit = FindTargetTrace();
			if(enthit && enthit.IsPlayer() && enthit.GetTeam() == enemyTeam) {
				//hit enemy player
				
				//target = enthit;
				NetProps.SetPropEntity(medigun, "m_hHealingTarget", enthit);
				NetProps.SetPropEntity(medigun, "m_hLastHealingTarget", null);
				
				charge = NetProps.GetPropFloat(medigun, "m_flChargeLevel");
				AddThinkToEnt(self, "HaveTargetThink");
			}
		}
	}
}

function HaveTargetThink() { //we have a target, damage it
	//outside of shield activation, disconnects handled by actual game
	if(self.IsRageDraining()) {
		NetProps.SetPropEntity(medigun, "m_hHealingTarget", null);
		AddThinkToEnt(self, "FindTargetThink");
	}
	else if(self.GetHealTarget() && self.GetHealTarget().GetTeam() == enemyTeam) {
		DamageBot();
	}
	else {
		AddThinkToEnt(self, "FindTargetThink");
	}
}

/*
function HaveTargetThink() { //we have a target, now check if we're still valid
	//if autoheal -> can change target, stop healing and set changetarget to false, else set changetarget to true
	//if wep not active, stop healing, otherwise start healing
	//if not autoheal -> heal while attacking, stop when not
	
	//.1s per think
	//aim 100 dps
	
	const MAX_RANGE = 540;
	local isValid = true;

	if(NetProps.GetPropBool(self, "m_bUsingActionSlot")) { //maybe check if can spec
		target.RemoveCond(TF_COND_INVULNERABLE_USER_BUFF)
		target.RemoveCond(TF_COND_CRITBOOSTED_USER_BUFF)
	}
	
	if(NetProps.GetPropInt(target, "m_lifeState") == 2) { //0 if alive, 2 dead
		isValid = false;
	}
	else if(!NetProps.GetPropBool(self, "m_bAttacking")) {
		isValid = false;
	}
	else if(NetProps.GetPropBool(self, "m_bHolstered")) {
		isValid = false;
	}
	else if(self.InCond(TF_COND_TAUNTING)) {
		isValid = false;
	}
	else if(self.GetHealTarget() != target) {
		isValid = false;
	}
	
	local dist = (target.GetCenter() - self.Weapon_ShootPosition()).Length();
	printl(dist)
	
	
	if(dist < MAX_RANGE) {
		//test to make sure this doesn't have previous inconsistency issues
		
	}
	else {
		printl("out of range")
		isValid = false;
	}

	if(isValid) {
		//"NetProps.SetPropEntity(self, `m_hHealingTarget`, null)"
		damageTimer++;
		
		//if(damageTimer == DAMAGE_TIME) {
			damageTimer = 0;
			DamageBot();
		//}
	}
	else {
		//target = null;
		AddThinkToEnt(self, "FindTargetThink"); 
		//no more target, switch back to finding one
	}
}
*/

function FindTargetTrace() {
	const MEDIRANGE = 450;
	local MASK_SHOT = CONTENTS_SOLID | CONTENTS_MOVEABLE 
		| CONTENTS_MONSTER | CONTENTS_WINDOW 
			| CONTENTS_DEBRIS;
	//so masks aren't in constants by default
	//filter out shield here?
	
	local traceTable = {};
	traceTable.start <- self.Weapon_ShootPosition();
	traceTable.end <- traceTable.start + self.EyeAngles().Forward() * MEDIRANGE;
	traceTable.mask <- MASK_SHOT;
	traceTable.ignore <- self;
	//see if shield is rejectable
	
	//DebugDrawClear()
	//DebugDrawLine(traceTable.start, traceTable.end, 0, 255, 0, false, 7)
	
	TraceLineEx(traceTable);
	
	if(traceTable.hit) {
		return traceTable.enthit;
	}
}

function DamageBot() {
	const KRITZKRIEG = 35;
	const QUICKFIX = 411;
	const VACCINATOR = 998;
	const QFBONUS = 1.4;
	const UBER = TF_COND_INVULNERABLE_USER_BUFF;
	const CRIT = TF_COND_CRITBOOSTED_USER_BUFF;
	//anything not those 3 is stock/reskin
	
	const DAMAGE = 10;
	//const ATTRIBUTENAME = "mod see enemy health"
	local target = self.GetHealTarget();
	//local fullDamage = DAMAGE * (1 + medigun:GetAttributeValueByClass("healing_mastery", 0) * .25)
	local fullDamage = DAMAGE; //can't look for attrs in vscript right now
	
	if(type == 998) { 
		if(NetProps.GetPropInt(self, "m_nButtons") & IN_RELOAD) { //remove passive vacc resists on target
			local cond = TF_COND_MEDIGUN_SMALL_BULLET_RESIST + NetProps.GetPropInt(medigun, "m_nChargeResistType");
		
			target.RemoveCond(cond);
		}
		if(charge > NetProps.GetPropFloat(medigun, "m_flChargeLevel")) { //also remove vacc ubers
			//p sure this removes bot applied vacc ubers too
			//unfortunately can't do anything about that right now
			target.RemoveCond(TF_COND_MEDIGUN_UBER_BULLET_RESIST + NetProps.GetPropInt(medigun, "m_nChargeResistType"));
		}
		charge = NetProps.GetPropFloat(medigun, "m_flChargeLevel");
	}
	
	//remove cans, can't check if we have can spec right now
	if(self.InCond(UBER) && target.InCond(UBER)) {
		target.RemoveCond(UBER);
	}
	else if(self.InCond(CRIT) && target.InCond(CRIT)) {
		//there are probably niche cases where this is fulfilled without can spec
		target.RemoveCond(CRIT);
	}
	
	if(NetProps.GetPropBool(medigun, "m_bChargeRelease")) {
		if(type == QUICKFIX) {
			fullDamage = fullDamage * (1 + qfMultiplier * 0.25);
			//damageInfo.Damage = damageInfo.Damage * (.75 + .25 * medigun:GetAttributeValue(ATTRIBUTENAME))
			//if target.GetConditionProvider(TF_COND_MEGAHEAL) == self then --occasionally no kb gets applied to bot
			target.RemoveCond(TF_COND_MEGAHEAL);
		}
		else if(type == KRITZKRIEG) {
			fullDamage = fullDamage * 2;
		}
	}
	
	if(type == QUICKFIX) {
		fullDamage = fullDamage * QFBONUS;
	}
	
	target.TakeDamageCustom(self, null, medigun, 
		Vector(0, 0, 0), target.GetOrigin(), fullDamage, DMG_ENERGYBEAM, TF_DMG_CUSTOM_MERASMUS_ZAP);
}