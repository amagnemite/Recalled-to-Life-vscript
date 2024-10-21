local scope = self.GetScriptScope();

//scope.autoheal <- 0;
scope.medigun <- null;
scope.upgradeMultiplier <- 0;
scope.enemyTeam <- self.GetTeam() == 2 ? 3 : 2;
scope.type <- 0;
scope.charge <- 0;
scope.damageForce <- 0
scope.MEDIRANGE <- 450;
scope.MASK_SHOT <- CONTENTS_SOLID | CONTENTS_MOVEABLE 
	| CONTENTS_MONSTER | CONTENTS_WINDOW 
		| CONTENTS_DEBRIS;
//masks aren't in constants by default
/*
foreach(a,b in Constants){foreach(k,v in b){if(!(k in getroottable())){getroottable()[k]<-v;}}} //takes all constant keyvals and puts them in global
IncludeScript("trace_filter");
*/

function levelCheck() {
	//so on wave loss weapon entities get refreshed
	//autoheal = Convars.GetClientConvarValue("tf_medigun_autoheal", self.entindex());
	
	for(local i = 0; i < NetProps.GetPropArraySize(self, "m_hMyWeapons"); i++) {
		if(NetProps.GetPropEntityArray(self, "m_hMyWeapons", i).GetClassname() == "tf_weapon_medigun") {
			medigun = NetProps.GetPropEntityArray(self, "m_hMyWeapons", i);
			break;
		}
	}
	type = NetProps.GetPropInt(medigun, "m_AttributeManager.m_Item.m_iItemDefinitionIndex");
	local level = medigun.GetAttribute("mod see enemy health", 0)
	//local level = 1
	
	if(level > 0) {
		thinkTable.FindTargetThink <- FindTargetThink
		//AddThinkToEnt(self, "FindTargetThink")
	}
	else {
		RefundMain();
	}
}

function RefundMain() {
	//AddThinkToEnt(self, null);
	if("FindTargetThink" in thinkTable) {
		delete thinkTable.FindTargetThink
	}
}

function FindTargetThink() { //if not damaging bot, look for one
	//if not attacking or in a state we can't/shouldn't drain
	if(!NetProps.GetPropBool(medigun, "m_bAttacking") || self.IsRageDraining() || self.InCond(TF_COND_TAUNTING)) { 
		return;
	}
	else if(NetProps.GetPropBool(medigun, "m_bHolstered")) { //this may be redundant
		return;
	}

	if(!NetProps.GetPropBool(medigun, "m_bHealing")) { //not already healing someone
		//no target, can look for a new one
		
		local enthit = FindTargetTrace();
		if(enthit && enthit.IsPlayer() && enthit.GetTeam() == enemyTeam) {
			//hit enemy player
			
			NetProps.SetPropEntity(medigun, "m_hHealingTarget", enthit);
			NetProps.SetPropEntity(medigun, "m_hLastHealingTarget", null);
			
			upgradeMultiplier = medigun.GetAttribute("healing mastery", 0) //get it here since it shouldn't change often
			damageForce = enthit.GetCustomAttribute("damage force reduction", 1)
			charge = NetProps.GetPropFloat(medigun, "m_flChargeLevel");
			//AddThinkToEnt(self, "HaveTargetThink");
			delete thinkTable.FindTargetThink
			thinkTable.HaveTargetThink <- HaveTargetThink
		}
	}
}

function FindTargetTrace() {
	local traceTable = {
		start = self.Weapon_ShootPosition()
		end = self.Weapon_ShootPosition() + self.EyeAngles().Forward() * MEDIRANGE
		mask = MASK_SHOT
		ignore = self
		filter = function(entity) {
			if(entity.GetClassname() == "func_physbox_multiplayer") {
				return TRACE_STOP
			}
		
			if(entity.IsPlayer()) {
				return TRACE_STOP;
			}
		
			if(entity.GetClassname() == "entity_medigun_shield" && entity.GetTeam() == TF_TEAM_RED) {
				return TRACE_CONTINUE;
			}
		}
	};
	//DebugDrawClear()
	//DebugDrawLine(traceTable.start, traceTable.end, 0, 255, 0, false, 7)
	
	TraceLineFilter(traceTable);
	
	if(traceTable.hit) {
		return traceTable.enthit;
	}
}

function HaveTargetThink() { //we have a target, damage it
	if(timeCounter < DEFAULTTIME) { //may change this later
		return
	}
	
	//outside of shield activation, disconnects handled by game
	if(self.IsRageDraining()) {
		NetProps.SetPropEntity(medigun, "m_hHealingTarget", null);
		//AddThinkToEnt(self, "FindTargetThink");
		delete thinkTable.HaveTargetThink
		thinkTable.FindTargetThink <- FindTargetThink
	}
	else if(self.GetHealTarget() && self.GetHealTarget().GetTeam() == enemyTeam) {
		local traceTable = {
			start = self.EyeAngles().Forward()
			end = self.GetHealTarget().GetCenter()
			mask = MASK_SHOT
			ignore = self
			filter = function(entity) {
				if(entity.GetClassname() == "func_physbox_multiplayer") {
					return TRACE_STOP
				}
			
				if(entity.IsPlayer()) {
					return TRACE_STOP;
				}
			
				if(entity.GetClassname() == "entity_medigun_shield" && entity.GetTeam() == TF_TEAM_RED) {
					return TRACE_CONTINUE;
				}
			}
		};
		TraceLineFilter(traceTable)
		local enthit = traceTable.enthit
	
		if(enthit && enthit.GetClassname() == "func_physbox_multiplayer") {
			NetProps.SetPropEntity(medigun, "m_hHealingTarget", null);
			delete thinkTable.HaveTargetThink
			thinkTable.FindTargetThink <- FindTargetThink
		}
		else {
			DamageBot();
		}
	}
	else {
		//AddThinkToEnt(self, "FindTargetThink");
		delete thinkTable.HaveTargetThink
		thinkTable.FindTargetThink <- FindTargetThink
	}
}

function DamageBot() {
	const KRITZKRIEG = 35;
	const QUICKFIX = 411;
	const VACCINATOR = 998;
	const QFBONUS = 1.4;
	local UBER = TF_COND_INVULNERABLE_USER_BUFF;
	local CRIT = TF_COND_CRITBOOSTED_USER_BUFF;
	//anything not those 3 is stock/reskin
	
	const DAMAGE = 7;
	local target = self.GetHealTarget();
	local fullDamage = DAMAGE * (1 + upgradeMultiplier * 0.25)
	
	if(type == VACCINATOR) { 
		if(NetProps.GetPropInt(self, "m_nButtons") & IN_RELOAD) { //remove passive vaccinator resists on target
			local cond = TF_COND_MEDIGUN_SMALL_BULLET_RESIST + NetProps.GetPropInt(medigun, "m_nChargeResistType");
			target.RemoveCond(cond);
		}
		
		if(charge > NetProps.GetPropFloat(medigun, "m_flChargeLevel")) { //also remove vaccinator ubers
			//p sure this removes bot applied vaccinator ubers too
			//unfortunately can't do anything about that right now
			target.RemoveCond(TF_COND_MEDIGUN_UBER_BULLET_RESIST + NetProps.GetPropInt(medigun, "m_nChargeResistType"));
		}
		charge = NetProps.GetPropFloat(medigun, "m_flChargeLevel");
	}
	
	//remove cans, can't check if we have can spec right now
	if(self.InCond(UBER) && target.InCond(UBER)) {
		target.RemoveCond(UBER);
	}
	else if(self.InCond(CRIT) && !target.HasBotAttribute(ALWAYS_CRIT) && target.InCond(CRIT)) {
		//there are probably niche cases where this is fulfilled without can spec
		target.RemoveCond(CRIT);
	}
	
	if(NetProps.GetPropBool(medigun, "m_bChargeRelease")) {
		if(type == QUICKFIX) {
			//fullDamage = fullDamage * (1 + qfMultiplier * 0.25);
			fullDamage = fullDamage * 3;
			//if target.GetConditionProvider(TF_COND_MEGAHEAL) == self then --occasionally no kb gets applied to bot
			target.RemoveCond(TF_COND_MEGAHEAL);
		}
		else if(type == KRITZKRIEG) {
			fullDamage = fullDamage * 3;
		}
	}
	
	local enemyMultiplier = damageForce * 2 > 1 ? damageForce * 2 : 1	
	fullDamage *= enemyMultiplier
	
	if(type == QUICKFIX) {
		fullDamage = fullDamage * QFBONUS;
	}
	
	target.TakeDamageCustom(self, null, medigun, 
		Vector(0, 0, 0), target.GetCenter(), fullDamage, DMG_ENERGYBEAM, TF_DMG_CUSTOM_MERASMUS_ZAP);
}