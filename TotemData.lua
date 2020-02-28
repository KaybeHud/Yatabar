if select(2, UnitClass('player')) ~= "SHAMAN" then
	return
end

local BlizzardCallSpells = TOTEM_MULTI_CAST_SUMMON_SPELLS

local WeaponImbues = 
{	
	8017,  --"Rockbiter Weapon"
	8024,  --"Flametongue Weapon"
	8033,  --"Frostbrand Weapon"
	8232,  -- "Windfury Weapon"
	51730, -- "Earthliving Weapon"	
}

function Yata:InitTotems()
	self:GatherTotemData()
	if(#self.TotemData == 0) then 
		self:Print("No totems found, level too low?")
		return false
	end
	return true
end

function Yata:GetTotem(name)
	local result = nil
	for k,v in ipairs(Yata.TotemData) do
		local totem = Yata.TotemData[v]
		totem = totem[#totem]
		if totem.Name == name then		
			result = totem
			break
		end
	end
	return result
end

function Yata:GatherTotemData()
	if self.TotemData then
		table.wipe(self.TotemData)
	end
	
    self.TotemData = {}
    
    local multicastActions = { 133, 134, 135, 136 }
    local totem1, totem2, totem3, totem4, totem5, totem6, totem7 
    local name, rank, icon, cost
	local count = 0
	
    for k, actionId in ipairs(multicastActions) do
		totem1, totem2, totem3, totem4, totem5, totem6, totem7 = GetMultiCastTotemSpells(actionId)
		
		local globalIds = { totem1, totem2, totem3, totem4, totem5, totem6, totem7 }
		
		for l, globalId in ipairs(globalIds) do
		    count = count + 1

			name, rank, icon, cost, _, _, _, _, _ = GetSpellInfo(globalId)
			
			local totem = {}
			totem.GlobalId = globalId
			totem.Name = name
			totem.Texture = icon
			totem.Mana = cost
			totem.ActionId = actionId
			
			if actionId == 133 then totem.SpellGroup = "Fire"; totem.Slot = ElementsMap["Fire"]
			elseif actionId == 134 then totem.SpellGroup = "Earth"; totem.Slot = ElementsMap["Earth"]
			elseif actionId == 135 then totem.SpellGroup = "Water"; totem.Slot = ElementsMap["Water"] 
			elseif actionId == 136 then totem.SpellGroup = "Air"; totem.Slot = ElementsMap["Air"]
			end
			
			if (not self.TotemData[name]) then
				self.TotemData[name] = {}
				table.insert(self.TotemData, name)
			end

			table.insert(self.TotemData[name],totem)
		end
    end
    
    local multicastbase = 133
    for k, spellId in ipairs(BlizzardCallSpells) do
    	local totem = {}
		totem.GlobalId = spellId
	    
		name, _, icon, cost, _, _, _, _, _ = GetSpellInfo(totem.GlobalId)
		
		-- Get again by name to make sure this character knows the spell
		name, _, _, _, _, _, _, _, _ = GetSpellInfo(name)

		if (name) then
			totem.Name = name
			totem.Texture = icon
			totem.Mana = cost
			totem.SpellGroup = SPELL_GROUP_CALL
			totem.CallIndex = k
			totem.CallActionBase = multicastbase + ((k - 1) * 4)
			
			if not self.TotemData[totem.Name] then
				self.TotemData[totem.Name] = {}
				table.insert(self.TotemData, totem.Name)
			end
			
			table.insert(self.TotemData[totem.Name], totem)
					
			count = count + 1
		end
	end
		
	for k, spellId in ipairs(WeaponImbues) do
    	local totem = {}
		totem.GlobalId = spellId
	    
		name, _, icon, cost, _, _, _, _, _ = GetSpellInfo(spellId)

		-- Get again by name to make sure this character knows the spell
		name, _, _, _, _, _, _, _, _ = GetSpellInfo(name)

		if(name) then
			totem.Name = name
			totem.Texture = icon
			totem.Mana = cost
			totem.SpellGroup = SPELL_GROUP_IMBUE
			
			if not self.TotemData[totem.Name] then
				self.TotemData[totem.Name] = {}
				table.insert(self.TotemData, totem.Name)
			end
			
			table.insert(self.TotemData[totem.Name], totem)
					
			count = count + 1
		end
	end
	
    self.TotemData.Count = count
end
