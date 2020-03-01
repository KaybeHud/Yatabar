if select(2, UnitClass('player')) ~= "SHAMAN" then
	return
end

function Yata:InitTotemSets()
	if self.CurrentDb.Sets then
		for i,b in pairs(self.CurrentDb.Sets) do
			self.CurrentDb.Sets[i] = self:FixTotemSet(b)
		end
	else 
		self.CurrentDb.Sets = {}
		self.CurrentDb.Sets[TOTEM_SET_PRIMARY_DEFAULT] = self:FixTotemSet()
	end
end

function Yata:GetTotemSet(name)
	return self.CurrentDb.Sets[name or self.CurrentDb.CurrentTotemSet]
end

function Yata:SetTotemSet(name, set)	
	if not name then
		name = self.CurrentDb.CurrentTotemSet
	end
	if not set then
		set = {}
		set.GroupOrder = {}
		set.HiddenSpells = {}
		for k,v in ipairs(SpellGroups) do
			local header = Yata.Bar.Groups[v].Header		
			local pos = header:GetAttribute("position")
			set.GroupOrder[pos + 1] = v
			set[v] = {}
			for i, b in ipairs(Yata.Bar.Groups[v].Buttons) do
				set[v][b:GetAttribute("position")+1] = b.Totem.Name
				if b:GetAttribute("hidden") then
					table.insert(set.HiddenSpells, b.Totem.Name)
				end				
			end
		end
	end
	self.CurrentDb.Sets[name] = set
end


function Yata:FixTotemSet(set)
-- Creates an empty totem set or cleans up bad data
	
	if not set then
		-- no set passed in to fix, so create a new one
		set = { ["GroupOrder"] = {} }	
		for k,v in ipairs(SpellGroups) do
			set[v] = {}
			set.GroupOrder[k] = v	
		end
	elseif	#set.GroupOrder ~= #SpellGroups then -- if the set is missing some spell groups (perhaps due to an upgrade adding more), we should add them in
		set.GroupOrder = SpellGroups
	end
	
	-- removalTable
	local goodTable = {}
	
	-- create a section for each spell group
	for k,v in ipairs(SpellGroups) do
		goodTable[v] = {}
	end
	
	-- loop through all of the spells that are available
	-- and match the entries in the set to the totems
	for k,v in ipairs(Yata.TotemData) do
	
		local totem = Yata.TotemData[v]
		totem = totem[#totem]
		
		local found = 1 -- stores the index of the spell within the group
		
		if (goodTable[totem.SpellGroup]) then
			found = #goodTable[totem.SpellGroup] + 1
		end
		
		for m,n in ipairs(set[totem.SpellGroup] or {}) do
			if n == totem.Name then
				found = m
				break
			end
		end
		
		-- If we have a totem and it has a spellgroup, it's a good entry
		if (totem.SpellGroup) then
			table.insert(goodTable[totem.SpellGroup],found,totem.Name)
		end
	end	
	
	-- reset the set table so that it only contains good entries
	for k,v in ipairs(SpellGroups) do
		set[v] = {}
		for m,n in pairs(goodTable[v]) do -- pairs here because we can't guarantee that it actually has no gaps (in some error cases)
			table.insert(set[v], n)
		end
	end
	
	return set
end
