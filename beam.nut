local scope = self.GetScriptScope();

scope.autoheal <- 0;
//scope["target"] <- null;
scope.player <- null;
scope.upgradeMultiplier <- 0;
scope.qfMultiplier <- 0;
scope.enemyTeam <- self.GetTeam() == 2 ? 3 : 2;

//printl("running beam in scope")
//printl(self)

function Setup(player) {
	this.player = player;
	autoheal = Convars.GetClientConvarValue("tf_medigun_autoheal", player.entindex());
	
	/*
	for(local i = 0; i < NetProps.GetPropArraySize(player, "m_hMyWeapons"); i++) {
		if(NetProps.GetPropEntityArray(player, "m_hMyWeapons", i).GetClassname() == "tf_weapon_medigun") {
			medigun = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i);
			i = NetProps.GetPropArraySize(player, "m_hMyWeapons");
		}
	}
	*/
	
	AddThinkToEnt(self, "FindTargetThink");
}

function RefundMain() {
	//stop think
	//terminate scope 
}

function RefundQF() {
	qfMultiplier = 0;
}

function FindTargetThink() { //if not damaging bot, look for one
	local buttonPress = NetProps.GetPropInt(player, "m_nButtons");
	local fired = false;
	printl("think")
	
	if(buttonPress & Constants.FButtons.IN_ATTACK) {
		fired = true;
	}
	
	//if not attacking or in a state we can't/shouldn't drain
	if(!fired || player.IsRageDraining() || player.InCond(Constants.ETFCond.TF_COND_TAUNTING)) { 
		return;
	}
	else if(NetProps.GetPropBool(self, "m_bHolstered")) {
		return;
	}

	if(!NetProps.GetPropBool(self, "m_bHealing")) { //not already healing someone
		if(NetProps.GetPropBool(self, "m_bAttacking")) {
			//no target, can look for a new one
			
			local enthit = FindTargetTrace();
			if(enthit && enthit.IsPlayer() && enthit.GetTeam() == enemyTeam) {
				//hit blu player
				
				//target = enthit;
				NetProps.SetPropEntity(self, "m_hHealingTarget", enthit);
				NetProps.SetPropEntity(self, "m_hLastHealingTarget", null);
				AddThinkToEnt(self, "HaveTargetThink");
			}
		}
	}
}

function HaveTargetThink() { //we have a target, damage it
	//outside of shield activation, disconnects handled by actual game
	if(!player.IsRageDraining() && player.GetHealTarget() && player.GetHealTarget().GetTeam() == enemyTeam) {
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

	if(NetProps.GetPropBool(player, "m_bUsingActionSlot")) { //maybe check if can spec
		target.RemoveCond(Constants.ETFCond.TF_COND_INVULNERABLE_USER_BUFF)
		target.RemoveCond(Constants.ETFCond.TF_COND_CRITBOOSTED_USER_BUFF)
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
	else if(player.InCond(Constants.ETFCond.TF_COND_TAUNTING)) {
		isValid = false;
	}
	else if(player.GetHealTarget() != target) {
		isValid = false;
	}
	
	local dist = (target.GetCenter() - player.Weapon_ShootPosition()).Length();
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
	local MASK_SHOT = Constants.FContents.CONTENTS_SOLID | Constants.FContents.CONTENTS_MOVEABLE 
		| Constants.FContents.CONTENTS_MONSTER | Constants.FContents.CONTENTS_WINDOW 
			| Constants.FContents.CONTENTS_DEBRIS;
	//so masks aren't in constants by default
	//filter out shield here?
	
	local traceTable = {};
	traceTable.start <- player.Weapon_ShootPosition();
	traceTable.end <- traceTable.start + player.EyeAngles().Forward() * MEDIRANGE;
	traceTable.mask <- MASK_SHOT;
	traceTable.ignore <- player;
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
	//anything not those 3 is stock/reskin
	
	const DAMAGE = 10;
	const ATTRIBUTENAME = "mod see enemy health"
	local target = player.GetHealTarget();
	local targetOrigin = target.GetOrigin();
	//local fullDamage = DAMAGE * (1 + medigun:GetAttributeValueByClass("healing_mastery", 0) * .25)
	local fullDamage = DAMAGE; //can't look for attrs in vscript right now
	
	local type = NetProps.GetPropInt(self, "m_AttributeManager.m_Item.m_iItemDefinitionIndex");
	
	if(NetProps.GetPropBool(self, "m_bChargeRelease")) {
		if(type == QUICKFIX) {
			fullDamage = fullDamage * qfMultiplier;
			//damageInfo.Damage = damageInfo.Damage * (.75 + .25 * medigun:GetAttributeValue(ATTRIBUTENAME))
			//if target.GetConditionProvider(TF_COND_MEGAHEAL) == player then --occasionally no kb gets applied to bot
			//	targetedEntity:RemoveCond(TF_COND_MEGAHEAL)
			//end
		}
		else if(type == KRITZKRIEG) {
			fullDamage = fullDamage * 2;
		}
	}
	
	if(type == QUICKFIX) {
		fullDamage = fullDamage * QFBONUS;
	}
	
	target.TakeDamageCustom(player, null, self, 
		Vector(0, 0, 0), targetOrigin, fullDamage, Constants.FDmgType.DMG_ENERGYBEAM, Constants.ETFDmgCustom.TF_DMG_CUSTOM_MERASMUS_ZAP);
}