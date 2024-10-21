function MimicPlayers()
	const TOTALHP = 21000
	local totalplayercount = 0
	local attackbotcount = 0
	local bots = {}
	local players = losecond.players
	
	foreach(player in players) {
		totalplayercount++
	}
	
	local perhp = TOTALHP / totalplayercount
	
	foreach(player in players) {
		local botname = 0
		local bot = 0
		local primaryattr = 0
		local meleeattr = 0
		
		local primary = null
		local secondary = null
		local melee = null
		
		for(local i = 0; i < 5; i++) {
			local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if(weapon == null) continue
			switch(weapon.GetSlot()) {
				case 0:
					primary = weapon;
					break;
				case 1:
					secondary = weapon
					break;
				case 2:
					melee = weapon
					break;
				default:
					break;
			}
		}
		
		primaryattr += checkIfAttrExists(player, "damage bonus")
		
		for attr, _ in pairs(primary:GetAllAttributeValues()) do
			primaryattr = primaryattr + 1
		end
		for attr, _ in pairs(melee:GetAllAttributeValues()) do
			meleeattr = meleeattr + 1
		end
		
		attackbotcount++
		botname = "attack" + attackbotcount
		bot = Entities.FindByName(null, botname)
		
		local botSecondary = bot.GenerateAndWearItem(secondary.GetName())
		NetProps.SetPropFloat(botSecondary, "m_flChargeLevel", 100)
		
		if primaryattr >= meleeattr then
			bot:WeaponStripSlot(LOADOUT_POSITION_MELEE)
			CopyPrimary(bot, primary)
		else 
			bot:WeaponStripSlot(LOADOUT_POSITION_PRIMARY)
			CopyMelee(bot, melee)
		end
		
		p:SetName(p:GetHandleIndex())
		
		if not p:InCond(TF_COND_HALLOWEEN_GHOST_MODE) and p:IsAlive() then --aggro lock only if player is alive
			SetBotAggroOnPlayer(p, bot:GetHandleIndex())
		end
		
		for _, item in pairs(p:GetAllItems()) do
			if item:IsWearable() then
				local botitem = bot:GiveItem(item:GetItemName())
				if botitem then --some items fail
					CopyAttribute("attach particle effect", item, botitem, true)
					CopyAttribute("set item tint RGB", item, botitem, true)
					CopyAttribute("set item tint RGB 2", item, botitem, true) --i think this is for team color paints?
					CopyAttribute("SPELL: set item tint RGB", item, botitem, true)
					CopyAttribute("SPELL: set Halloween footstep type", item, botitem, true)
					CopyAttribute("custom texture lo", item, botitem, true)
					CopyAttribute("custom texture hi", item, botitem, true)
					CopyAttribute("item style override", item, botitem, true)
				end
			end
		end
		
		bots[bot:GetHandleIndex()] = playerhandle
		--pair bot handle to player handle
		
		bot:SetAttributeValue("max health additive bonus", perhp)
		bot:SetAttributeValue("mod weapon blocks healing", 1)
		bot.m_bIsMiniBoss = true
	}
	
	--clean up extra bots 
	for i = attackbotcount + 1, 6 do
		local botname = "attack" .. i
		local bot = ents.FindByName(botname)
		--print("removed " .. botname)
		
		bot:Suicide()
	end
	
	return bots
end

function checkIfAttrExists(player, attr) {
	if(player.GetCustomAttribute(attr, 0) > 0) {
		return 1
	}
	return 0
}

--copy an attr + value from one wep to another
--does nothing if first wep doesn't have the attr
function CopyAttribute(name, copyfromwep, copytowep, checkdef)
	local value = copyfromwep:GetAttributeValue(name, checkdef)
	copytowep:SetAttributeValue(name, value)
end

--primarily user custom stuff (skins, festivizers, ks, names)
function CopyGeneric(copyfromwep, copytowep)
	CopyAttribute("paintkit_proto_def_index", copyfromwep, copytowep, true)
	CopyAttribute("set_item_texture_wear", copyfromwep, copytowep, true)
	CopyAttribute("custom_paintkit_seed_lo", copyfromwep, copytowep, true)
	CopyAttribute("custom_paintkit_seed_hi", copyfromwep, copytowep, true)
	CopyAttribute("is_festivized", copyfromwep, copytowep, true)
	CopyAttribute("killstreak tier", copyfromwep, copytowep, true)
	CopyAttribute("killstreak effect", copyfromwep, copytowep, true)
	CopyAttribute("killstreak idleeffect", copyfromwep, copytowep, true)
	CopyAttribute("attach particle effect", copyfromwep, copytowep, true)
	CopyAttribute("custom name attr", copyfromwep, copytowep, true)
end

function CopyPrimary(bot, copyfromwep)
	local copytowep = bot:GiveItem(copyfromwep:GetItemName())
	
	CopyAttribute("damage bonus", copyfromwep, copytowep)
	CopyAttribute("fire rate bonus", copyfromwep, copytowep)
	CopyAttribute("clip size bonus upgrade", copyfromwep, copytowep)
	CopyAttribute("clip size upgrade atomic", copyfromwep, copytowep)
	--CopyAttribute("heal on kill", copyfromwep, copytowep) --this is kinda useless
	CopyAttribute("projectile penetration", copyfromwep, copytowep)
	CopyAttribute("faster reload rate", copyfromwep, copytowep)
	--CopyAttribute("mad milk syringes", copyfromwep, copytowep)
	
	--aussie bluts
	CopyAttribute("item style override", copyfromwep, copytowep, true)
	CopyAttribute("is australium item", copyfromwep, copytowep, true)
	
	CopyGeneric(copyfromwep, copytowep)
end

function CopyMelee(bot, copyfromwep)
	local copytowep = bot:GiveItem(copyfromwep:GetItemName())

	--no dmg cause cok is strong enough
	CopyAttribute("melee attack rate bonus", copyfromwep, copytowep)
	CopyAttribute("critboost on kill", copyfromwep, copytowep)
	CopyAttribute("heal on kill", copyfromwep, copytowep)
	
	--objector
	CopyAttribute("custom texture lo", copyfromwep, copytowep, true)
	CopyAttribute("custom texture hi", copyfromwep, copytowep, true)
	
	CopyGeneric(copyfromwep, copytowep)
end
