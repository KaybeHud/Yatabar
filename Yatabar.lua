if select(2, UnitClass('player')) ~= "SHAMAN" then
	return
end

Yatabar = LibStub("AceAddon-3.0"):NewAddon("Yatabar", "AceConsole-3.0")
local LAB = LibStub("LibActionButton-1.0")
Yatabar.totemCount = 0 
Yatabar.buttonSize = 36
Yatabar.name = "Yatabar"
Yatabar.frameBorder = 8
Yatabar.availableTotems = {}
Yatabar.isLocked = true
Yatabar.activateSpellOrder = {active = false, element = "", order = 1}
Yatabar.orderElements = {}
Yatabar.orderTotemsInElement = {["EARTH"] = {}, ["WATER"] = {}, ["FIRE"] = {}, ["AIR"] = {}}
local _G = getfenv(0)
local L = LibStub("AceLocale-3.0"):GetLocale(Yatabar.name, true)
local GetTotemInfo = LibStub("LibTotemInfo-1.0").GetTotemInfo
local MSQ = LibStub("Masque", true)
local myGroup = {}

--LDB
local ldb = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(Yatabar.name, {
    type = "launcher",
    icon = "Interface\\Icons\\inv_banner_01",
    OnClick = function(self, button)
		if (button == "RightButton") then
			Yatabar.isLocked = not Yatabar.isLocked
			Yatabar:toggleLock(Yatabar.isLocked)
		else
			LibStub("AceConfigDialog-3.0"):Open(Yatabar.name)
		end
	end,
	OnTooltipShow = function(Tip)
		if not Tip or not Tip.AddLine then
			return
		end
		Tip:AddLine(Yatabar.name)
		Tip:AddLine("|cFFff4040"..L["Left Click|r to open configuration"], 1, 1, 1)
		Tip:AddLine("|cFFff4040"..L["Right Click|r to lock/unlock bar"], 1, 1, 1)
	end,
})

local defaults = 
{
	char = {
		orderElements = {["EARTH"] = 1, ["WATER"] = 2, ["FIRE"] = 3, ["AIR"] = 4},
		orderTotemsInElement = {["EARTH"] = {}, ["WATER"] = {}, ["FIRE"] = {}, ["AIR"] = {}},
		orientation = "horzup",
		padding = 0,
	}
}

function Yatabar:InitOptions()
	local options = {
		name = Yatabar.name,
		desc = "Totem with popup buttons",
		icon = "Interface\\Icons\\inv_banner_01",
		type="group",
		args = {
			totems = {
				type = "group",
				name = "Totems",
				args = {
					
				},
			},
		}
	}

	return options;
end

function Yatabar:OnInitialize()
	print("Initialize")
	self.db = LibStub("AceDB-3.0"):New("YatabarDB", defaults)
	self.config = self.db.char
	self.orderElements = self.config.orderElements
	self.orderTotemsInElement = self.config.orderTotemsInElement

	self.options = self:InitOptions()

	LibStub("AceConfig-3.0"):RegisterOptionsTable(Yatabar.name, self.options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, self.name)
	self.optionsFrameGui = LibStub("AceConfigDialog-3.0"):Open(self.name)
	self:RegisterChatCommand("yb", "ChatCommand")
	self:RegisterChatCommand("yatabar", "ChatCommand")

	if MSQ then
		myGroup = MSQ:Group(self.name,nil, true)
	end
end

function Yatabar:OnEnable()
	self:GetTotemSpellsByElement()
	self:CheckOrderTotemSpells()
	self.totemCount = self:GetTotemCount()
	self:CreateBar()
	self:LoadPosition()
	--self:GetTotemSpells()
	for element, spell in pairs(Yatabar.availableTotems) do
		self:CreateTotemHeader(element)
	end
	self:SetLayout()
	self:AddOptionsForTotems()
	Yatabar:HidePopups()
	--print("Enabled")
end

function Yatabar:CreateBar()
	--print("CreateBar") 
	Yatabar.bar = CreateFrame("Frame", "YatabarBar", UIParent)
	Yatabar.bar:SetPoint("CENTER", -300,0)

	Yatabar.bar:SetWidth(self.buttonSize * Yatabar.totemCount + (2*self.frameBorder));
	Yatabar.bar:SetHeight(self.buttonSize + (2*self.frameBorder));
	Yatabar.bar:SetMovable(true);
	Yatabar.bar:SetClampedToScreen(true);
	
	Yatabar.bar.overlay = CreateFrame("Frame", "YatabarBarOverlay", Yatabar.bar)
	Yatabar.bar.overlay:SetAllPoints()
	Yatabar.bar.overlay:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true,
		tileSize = 1,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 0,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	Yatabar.bar.overlay:SetBackdropColor(0, 1, 1, 1)
	Yatabar.bar.overlay:SetBackdropBorderColor(0.5, 0.5, 0, 0)
	Yatabar.bar.overlay:EnableMouse(true)
	Yatabar.bar.overlay:RegisterForDrag("LeftButton")
	Yatabar.bar.overlay:Hide()

	Yatabar.bar:RegisterEvent("LEARNED_SPELL_IN_TAB")
	Yatabar.bar:RegisterEvent("PLAYER_REGEN_DISABLED")
	Yatabar.bar:RegisterEvent("PLAYER_REGEN_ENABLED")
	
	Yatabar.bar:Show()
end

function Yatabar:CreateTotemHeader(element)
	print("CreateTotemHeader")
	local frameBorder = Yatabar.frameBorder 
	Yatabar["TotemHeader"..element] = CreateFrame("Frame", "TotemHeader"..element, Yatabar.bar, "SecureHandlerStateTemplate")
	Yatabar["TotemHeader"..element]:SetPoint("BOTTOMLEFT", Yatabar.bar,"BOTTOMLEFT",(self.orderElements[element]-1) * Yatabar.buttonSize + frameBorder, frameBorder)
	Yatabar["TotemHeader"..element]:SetSize(Yatabar.buttonSize, Yatabar.buttonSize * self.availableTotems[element].count)

	-- Yatabar["TotemHeader"..element]:SetBackdrop({
	-- 	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	-- 		tile = true,
	-- 		tileSize = 1,
	-- 		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	-- 		edgeSize = 0,
	-- 		insets = {left = 0, right = 0, top = 0, bottom = 0}
	-- })
	
	-- Yatabar["TotemHeader"..element]:SetBackdropColor(0, 0, 1, 1)
	-- Yatabar["TotemHeader"..element]:SetBackdropBorderColor(0.5, 0.5, 0, 0)

	-- Yatabar["TotemHeader"..element]:Show()

	--prüfen ob Reihenfolge vorhanden ist
	if self.orderTotemsInElement[element] == nil then --wenn noch keine Reihenfolge vorhanden ist dann die Totemspells einfach durchgehen
		for idx, spellId in ipairs(self.availableTotems[element]) do
			if type(spellId) == "number" then
				self:CreateSpellPopupButton(Yatabar["TotemHeader"..element], idx, spellId, element)
			end
		end
	else	--sonst nach reihenfolge
		for spellId, idx in pairs(self.orderTotemsInElement[element]) do
			print("in reihenfolge..", spellId, idx)
			if type(spellId) == "number" then
				self:CreateSpellPopupButton(Yatabar["TotemHeader"..element], idx, spellId, element)
			end
		end
	end

		Yatabar["TotemHeader"..element]:Execute ( [[show = [=[
			local popups = newtable(self:GetChildren())
			for i, button in ipairs(popups) do
				button:Show()
			end
		]=] ]])

		Yatabar["TotemHeader"..element]:Execute( [[close = [=[
		local popups = newtable(self:GetChildren())
			for i, button in pairs(popups) do
				if not (button:GetAttribute("index") == 1) then
					button:Hide()
				end				
			end
		]=] ]])
end


function Yatabar:CreateSpellPopupButton(main,index, spellId, element)
	--print("CreatePopups")
	local name = "YatabarButton"..element..spellId
	main["popupButton"..element..spellId] = LAB:CreateButton(spellId, name , main)
	main["popupButton"..element..spellId].name = "popupButton"..element..spellId
	main["popupButton"..element..spellId].spellId = spellId
	main["popupButton"..element..spellId].index = index
	main["popupButton"..element..spellId].element = element
	main["popupButton"..element..spellId]:SetPoint("BOTTOMLEFT", main,"BOTTOMLEFT", 0,(index - 1) * Yatabar.buttonSize)
	main["popupButton"..element..spellId]:SetAttribute('state', "spell1")
	main["popupButton"..element..spellId]:SetAttribute('index', index)
	main["popupButton"..element..spellId]:SetState("spell1", "spell", spellId)
	if MSQ then
		main["popupButton"..element..spellId]:AddToMasque(myGroup)
	end
	main["popupButton"..element..spellId]:SetScript("OnDragStart", nil);
	--main["popupButton"..element..spellId]:SetScript("OnReceiveDrag", function() Yatabar:isTotemFor(element); end );
	main["popupButton"..element..spellId]:SetScript("OnEvent", function(arg1,event) Yatabar:OnEventFunc(event, arg1, element, main["popupButton"..element..spellId]); end);
	SecureHandlerWrapScript(main["popupButton"..element..spellId],"OnLeave",main,[[return true, ""]], [[
		inHeader =  control:IsUnderMouse(true)
		if not inHeader then
			control:Run(close);
		end	    
	]])

	SecureHandlerWrapScript(main["popupButton"..element..spellId],"OnEnter",main, [[
		control:Run(show);
		]]);

	main["popupButton"..element..spellId]:RegisterEvent("ACTIONBAR_SHOWGRID");
	main["popupButton"..element..spellId]:RegisterEvent("ACTIONBAR_HIDEGRID");
	
	
	-- main["popupButton"..element..index]:Execute( [[show = [=[
	-- 		self:Show()
	-- 	]=] ]])
	-- main["popupButton"..element..index]:Execute( [[hide = [=[
	-- 		self:Hide()
	-- 	]=] ]])
	
end

function Yatabar:SetLayout()
	local isVert, isRtorDn = false, false;
	local orientation = self.config.orientation;
	if (orientation == "horzdown") then
		isRtorDn = true;
	elseif (orientation == "vertleft") then
		isVert = true;
	elseif (orientation == "vertright") then
		isVert = true;
		isRtorDn = true;
	end
	if (isVert) then
		Yatabar.bar:SetHeight(self.buttonSize * Yatabar.totemCount + (2*self.frameBorder));
		Yatabar.bar:SetWidth(self.buttonSize + (2*self.frameBorder));
	else
		Yatabar.bar:SetWidth(self.buttonSize * Yatabar.totemCount + (2*self.frameBorder));
		Yatabar.bar:SetHeight(self.buttonSize + (2*self.frameBorder));
	end

	for element, spell in pairs(Yatabar.availableTotems) do
		Yatabar:UpdateLayout(Yatabar["TotemHeader"..element], element,isVert, isRtorDn)
	end
end

function Yatabar:UpdateLayout(frame, element,isVert,isRtorDn)
	frame:ClearAllPoints();
	if (isVert and not isRtorDn) then
		frame:SetPoint("TOPRIGHT", Yatabar.bar,"TOPRIGHT", -Yatabar.frameBorder, -(Yatabar.orderElements[element]-1) * Yatabar.buttonSize - Yatabar.frameBorder)
		frame:SetSize( Yatabar.buttonSize * self.availableTotems[element].count, Yatabar.buttonSize)
	elseif isVert and isRtorDn then
		frame:SetPoint("TOPLEFT", Yatabar.bar,"TOPLEFT", Yatabar.frameBorder, -(Yatabar.orderElements[element]-1) * Yatabar.buttonSize - Yatabar.frameBorder)
		frame:SetSize( Yatabar.buttonSize * self.availableTotems[element].count, Yatabar.buttonSize)
	elseif not isVert and isRtorDn then
		frame:SetPoint("TOPLEFT", Yatabar.bar,"TOPLEFT",(Yatabar.orderElements[element]-1) * Yatabar.buttonSize + Yatabar.frameBorder, -Yatabar.frameBorder)
		frame:SetSize(Yatabar.buttonSize, (Yatabar.buttonSize * self.availableTotems[element].count))
	else
		frame:SetPoint("BOTTOMLEFT", Yatabar.bar,"BOTTOMLEFT",(Yatabar.orderElements[element]-1) * Yatabar.buttonSize + Yatabar.frameBorder, Yatabar.frameBorder)
		frame:SetSize(Yatabar.buttonSize, Yatabar.buttonSize * self.availableTotems[element].count)
	end

	if self.orderTotemsInElement[element] == nil then --wenn noch keine Reihenfolge vorhanden ist dann die Totemspells einfach durchgehen
		for idx, spellId in ipairs(self.availableTotems[element]) do
			if type(spellId) == "number" then
				Yatabar:UpdateButtonLayout(frame, element,isVert,isRtorDn, idx)
			end
		end
	else	--sonst nach reihenfolge
		for spellId, idx in pairs(self.orderTotemsInElement[element]) do
			if type(spellId) == "number" then
				--print("Reihenfolge",element,spellId, idx)
				Yatabar:UpdateButtonLayout(frame, element,isVert,isRtorDn, idx, spellId)
			end
		end
	end
end

function Yatabar:UpdateButtonLayout(frame, element,isVert,isRtorDn, idx, spellId)
	frame["popupButton"..element..spellId]:ClearAllPoints()
	if (isVert and isRtorDn) then
		frame["popupButton"..element..spellId]:SetPoint("TOPLEFT", frame,"TOPLEFT",(idx - 1) * Yatabar.buttonSize, 0)
		frame["popupButton"..element..spellId].index = idx
		frame["popupButton"..element..spellId]:SetAttribute('index', idx)
	elseif isVert and not isRtorDn then
		frame["popupButton"..element..spellId]:SetPoint("TOPRIGHT", frame,"TOPRIGHT", -(idx - 1) * Yatabar.buttonSize, 0)
		frame["popupButton"..element..spellId].index = idx
		frame["popupButton"..element..spellId]:SetAttribute('index', idx)
	elseif not isVert and isRtorDn then
		frame["popupButton"..element..spellId]:SetPoint("TOPLEFT", frame,"TOPLEFT", 0,-(idx - 1) * Yatabar.buttonSize)
		frame["popupButton"..element..spellId].index = idx
		frame["popupButton"..element..spellId]:SetAttribute('index', idx)
	else
		frame["popupButton"..element..spellId]:SetPoint("BOTTOMLEFT", frame,"BOTTOMLEFT", 0,(idx - 1) * Yatabar.buttonSize)
		frame["popupButton"..element..spellId].index = idx
		frame["popupButton"..element..spellId]:SetAttribute('index', idx)
	end
end


function Yatabar:OnEventFunc(event, arg, element, button)
	if ( event == "ACTIONBAR_SHOWGRID" ) then
		if InCombatLockdown() then return end
		if not Yatabar:isTotemFor(element) then
			button:DisableDragNDrop(true)
		else
			--button:Show()
			Yatabar["TotemHeader"..element]:Execute([[
			control:Run(show)
			]])
		end
	end
	if ( event == "ACTIONBAR_HIDEGRID" ) then
		if InCombatLockdown() then return end
		button:DisableDragNDrop(false)
		Yatabar:HidePopups()
	end

	if event == "PLAYER_REGEN_ENABLED" then
		button:DisableDragNDrop(false)
	end
	if event == "PLAYER_REGEN_DISABLED" then
		button:DisableDragNDrop(true)
	end
	if(event == "LEARNED_SPELL_IN_TAB") then
		print("new spell learned")
		self:GetTotemSpellsByElement()
		self:CheckOrderTotemSpells()
		self:SetLayout()
		self:AddOptionsForTotems()
	end
	
end

function Yatabar:hasSpell(spellId)
	spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellId)
		--welche Totems sind dem Spieler bekannt:
	spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellname)
	if spellname ~= nil then
		return true
	else
		return false
	end

end

-- function Yatabar:GetTotemSpells()
-- 	countSpells = 1
-- 	for idx, totem in pairs(YatabarConfig.allTotems) do
-- 		spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(totem["RankOneSpellID"])
-- 		--welche Totems sind dem Spieler bekannt:
-- 		spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellname)
-- 		if spellname ~= nil then
-- 			Yatabar.availableTotems[countSpells] = {["SpellName"] = spellname, ["SpellId"] = spellId, ["ElementID"] = totem["ElementID"]}
-- 			countSpells = countSpells +1
-- 		end
-- 	end
-- end

function Yatabar:GetTotemSpellsByElement()
	countSpells = 1
	for element, totem in pairs(YatabarConfig.totems) do
		Yatabar.availableTotems[element] = {}
		for idx, spell in pairs(totem) do
			local name = GetSpellInfo(spell["id"])
			--welche Totems sind dem Spieler bekannt:
			spellname = GetSpellInfo(name)
			if spellname ~= nil then
				table.insert(Yatabar.availableTotems[element],spell["id"])
				-- if Yatabar.orderTotemsInElement[element] ~= nil then
				-- 	--print("SpellId,countSpells", name, spellname,spell["id"], countSpells)
				-- 	Yatabar.orderTotemsInElement[element][spell["id"]] = countSpells
				-- end
				countSpells = countSpells + 1
			end
		end
		Yatabar.availableTotems[element].count = countSpells - 1
		countSpells = 1
	end
end

--sortieren und wenn neue Spells verfügbar sind, diese neu hinzufügen
function Yatabar:CheckOrderTotemSpells()
	for element, spell in pairs(Yatabar.availableTotems) do
		for k, id in pairs(spell) do
			if Yatabar.orderTotemsInElement[element][id] == nil and k ~= "count" then
				Yatabar.orderTotemsInElement[element][id] = #Yatabar.orderTotemsInElement[element]+1
			end
		end
	end
end

function Yatabar:AddOptionsForTotems()
	for element, order in pairs(self.orderElements) do
		self.options.args.totems.args[element] = {
			type = "group",
			name = element,
			args = {}
		}
		self.options.args.totems.args[element].args =  {
			text = {
				type = "description",
				order = 1,
				name = "Set the order of the element:",
				fontSize = "medium",
			},
			totem = {
				name = element,
				desc = element,
				type = "range",
				order = 2,
				step = 1,
				min = 1,
				max = Yatabar.totemCount,
				isPercent = false,
				get = function() return self.orderElements[element]; end,
				set = function(info,value) Yatabar:SetTotemOrder(value, element); end
			},
			header = {
				name = "Totem configuration",
				type = "header", 
				fontSize = "mdeium",
				order = 3,
			},
			activateSpellOrder = {
				name = "Set Order",
				order = 4,
				desc = "Klicke um die Reihenfolge zu setzen",
				type = "execute",
				func = function(tbl,click) Yatabar:ActivateSetSpellOrder(element, tbl) end,
			}
		}

		for spellId, idx in pairs(self.orderTotemsInElement[element]) do
			local spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellId)
			if spellname ~= nil then
				buttonGrp = {
					type = "group",
					inline = true,
					name = spellname,
					args = {
						button = {
							name = spellname,
							order = 2,
							image = icon,
							type = "execute",
							func = function(tbl,mousebutton) Yatabar:SetSpellOrder(tbl,mousebutton, element) end,
						},
						checkbox = {
							name = "show",
							order = 3,
							type = "toggle",
							set = function(a,b) end,
							get = function()return true end
						},
						text = {
							type = "description",
							order = 1,
							name = "Position "..idx,
						},
					},
				}
						
				table.insert(self.options.args.totems.args[element].args, buttonGrp)
			end
		end
	end

end

function Yatabar:GetTotemOrder(value)
	return true
end

function Yatabar:SetTotemOrder(newValue, element)
	local postionToSwitch = self.orderElements[element]
	local elementToSwitch = "" 
	for element, order in pairs(self.orderElements) do
		if order == newValue then
			elementToSwitch = element
			break
		end
	end
	self.orderElements[element] = newValue
	self.orderElements[elementToSwitch] = postionToSwitch
	self:SetLayout()
end

function Yatabar:ActivateSetSpellOrder(element, tbl)
	Yatabar.activateSpellOrder.active = not Yatabar.activateSpellOrder.active
	if Yatabar.activateSpellOrder.active then
		Yatabar.activateSpellOrder.order = 1
		Yatabar.activateSpellOrder.element = element
		tbl.option.name = "Stop reorder"
	else
		Yatabar:HidePopups()
		tbl.option.name = "Set Order"
	end
end

function Yatabar:SetSpellOrder(tbl,mousebutton, element)
	if not Yatabar.activateSpellOrder.active then
		return
	end
	--print("setOrder")
	local spellname = tbl.option.name
	spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellname)
	--print(spellname)
	

	local currentPosition = self.orderTotemsInElement[element][spellId]
	print("oldpostion", currentPosition)
	local newPosition = Yatabar.activateSpellOrder.order
	print("new Position", newPosition)
	local spellToSwitch = 0 
	for spell, order in pairs(self.orderTotemsInElement[element]) do

		if type(spell) == "number" and order == newPosition then
			spellToSwitch = spell
			break
		end
	end
	print("selectedSpell", spellId)
	print("switchedSpell", spellToSwitch)
	self.orderTotemsInElement[element][spellId] = newPosition
	self.orderTotemsInElement[element][spellToSwitch] = currentPosition
	Yatabar.activateSpellOrder.order = Yatabar.activateSpellOrder.order+1
	Yatabar["TotemHeader"..element]:Execute([[
			control:Run(show)
			]])

	--Set Position in text in Config Dialog
	local oldSpellname = GetSpellInfo(spellToSwitch)
	for k,v in pairs (tbl.options.args.totems.args[element].args) do
		if v.name == tbl.option.name then
			v.args.text.name = "Position "..newPosition
		elseif v.name == oldSpellname then
			v.args.text.name = "Position "..currentPosition
		end
	end

	self:SetLayout()
end

function Yatabar:GetTotemCount()
	count = 0
	for i =1, 4 do 
		haveTotem, totemName = GetTotemInfo(i)
		if haveTotem then
			print(totemName)
			count = count + 1
		end
	end
	return count
end

function Yatabar:toggleLock(lock)
	if InCombatLockdown() then
		print("function not available during combat")
		return
	end
	if not lock then
		Yatabar.bar.overlay:SetScript("OnDragStart", function() Yatabar:StartDrag(); end);
		Yatabar.bar.overlay:SetScript("OnDragStop", function() Yatabar:StopDrag(); end);
		Yatabar.bar.overlay:Show();
	else
		Yatabar.bar.overlay:SetScript("OnDragStart", nil);
		Yatabar.bar.overlay:SetScript("OnDragStop", nil);
		Yatabar.bar.overlay:Hide();
	end
end

function Yatabar:StartDrag()
	Yatabar.bar:StartMoving();
end

function Yatabar:StopDrag()
	Yatabar.bar:StopMovingOrSizing();
	Yatabar:SavePosition();
end

function Yatabar:ShowPopups()
	for element, idx in pairs(Yatabar.orderElements) do
		Yatabar["TotemHeader"..element]:Execute([[
			control:Run(show)
			]])
	end
end

function Yatabar:HidePopups()
	for element, idx in pairs(Yatabar.orderElements) do
		Yatabar["TotemHeader"..element]:Execute([[
			control:Run(close)
			]])
	end
end

function Yatabar:SavePosition()
	local scale = Yatabar.bar:GetEffectiveScale();
	local point, relativeTo, relativePoint, xOfs, yOfs =  Yatabar.bar:GetPoint()
	self.db.char.xOfs = xOfs
	self.db.char.yOfs = yOfs
	self.db.char.scale = scale	
end

-- function Yatabar.SaveTotemSpellOrder(element)
-- 	self.db.char.orderTotemsInElement[element] = Yatabar.orderTotemsInElement[element]
-- end

function Yatabar:isTotemFor(element)
	infoType, spell = GetCursorInfo()
	skillType, spellID = GetSpellBookItemInfo(spell, BOOKTYPE_SPELL)
	if infoType == "spell" then 
		if Yatabar:hasSpell(spellID) then
			for spell, index in pairs(Yatabar.orderTotemsInElement[element]) do
				if spell == spellID then
					return true
				end
			end
		end
	end
	return false
	--self:SaveTotemSpellOrder(element)
end

function Yatabar:LoadPosition()
	local scale = self.db.char.scale
	local xOfs, yOfs = self.db.char.xOfs, self.db.char.yOfs
	Yatabar.bar:SetPoint("CENTER",UIParent, "CENTER", xOfs, yOfs);
end

function Yatabar:ChatCommand(input)
	if not input or input:trim() == "" then
	--InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
	LibStub("AceConfigDialog-3.0"):Open("Yatabar")
  else
    print("console")
    LibStub("AceConfigCmd-3.0").HandleCommand(Yatabar, "yb", "Options", input)
  end
end



function Yatabar:CreateActionPopupButton(main, spellCount, id)
	--local id = main.id + spellCount--self.totemCount
	--print("mainID:"..main.id)
	--print("Popupid:"..id)
	local name = "YatabarButton"..id
	main["popupButton"..id] = LAB:CreateButton(id, name , main)
	main["popupButton"..id].name = "popupButton"..id
	print(id - spellCount) --self.totemCount)
	main["popupButton"..id]:SetPoint("BOTTOMLEFT", main,"BOTTOMLEFT", 0,(id - spellCount - 1) * Yatabar.buttonSize) --(id - 1 - self.totemCount) * Yatabar.buttonSize
	main["popupButton"..id]:SetAttribute('state', 1)
	main["popupButton"..id]:SetAttribute('index', index)
	main["popupButton"..id]:SetState(1, "action", id)
	SecureHandlerWrapScript(main["popupButton"..id],"OnLeave",main,[[return true, ""]], [[
		inHeader =  control:IsUnderMouse(true)
		if not inHeader then
			control:Run(close);
		end	    
	]])

	SecureHandlerWrapScript(main["popupButton"..id],"OnEnter",main, [[
		control:Run(show);
		]]);
end
