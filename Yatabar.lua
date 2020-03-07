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
			print("Linksklick, noch keine Funktion")
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
			showUI = {
				name = "Hide mainbar",
				desc = "Hides the default mainbar",
				type = "toggle",
				order = 1,
				get = function() return true end,
				set = function(info,value)  end,
			},

		-- 	add = {
		-- 		name = L["Add Bar"],
		-- 		desc = L["Add a new bar"],
		-- 		type = "execute",
		-- 		order = 3,
		-- 		func = function() self:AddBar() end,
		-- 	},
		-- 	del = {
		-- 		name = L["Delete Bar"],
		-- 		desc = L["Delete the last bar"],
		-- 		type = "execute",
		-- 		order = 6,
		-- 		func = function() self:DeleteBar() end,
		-- 	},
		-- 	ids = {
		-- 		name = L["Show all buttonids"],
		-- 		desc = L["Shows all buttons with their ids"],
		-- 		type = "execute",
		-- 		order = 9,
		-- 		func = function() self:ShowIDs() end,
		-- 	},
		}
	}

	return options;
end

function Yatabar:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("YatabarDB", defaults)
	self.config = self.db.char
	self.orderElements = self.db.char.orderElements
	self.orderTotemsInElement = self.db.char.orderTotemsInElement
	self:GetTotemSpellsByElement()
	self:CheckOrderTotemSpells()

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
	Yatabar.totemCount = Yatabar:GetTotemCount()
	self:CreateBar(Yatabar.totemCount)
	self:LoadPosition()
	--self:GetTotemSpells()
	for element, spell in pairs(Yatabar.availableTotems) do
		self:CreateTotemHeader(element)
	end
	--self:CreateMainButtons()

	--RegisterStateDriver(Yatabar.frame, "page", "[mod:alt]2;1")
	
	-- Yatabar.frame:SetAttribute("_onstate-page", [[
	-- self:SetAttribute("state", newstate)
	-- control:ChildUpdate("state", newstate)
	-- ]])
	--Yatabar.frame:Show()
	--Yatabar.frame:SetAttribute("statehidden", nil)

	Yatabar:HidePopups()
	print("Enabled")
end

function Yatabar:CreateBar(count)
	print("CreateBar") 
	Yatabar.bar = CreateFrame("Frame", "YatabarBar", UIParent)
	Yatabar.bar:SetPoint("CENTER", -300,0)

	Yatabar.bar:SetWidth(self.buttonSize * count + (2*self.frameBorder));
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
	
	Yatabar.bar:Show()
end

function Yatabar:CreateTotemHeader(element)
	--print("CreateTotemHeader")
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
	
	-- Yatabar["TotemHeader"..element]:SetBackdropColor(0, 1, 1, 1)
	-- Yatabar["TotemHeader"..element]:SetBackdropBorderColor(0.5, 0.5, 0, 0)

	Yatabar["TotemHeader"..element]:Show()

	--prüfen ob Reihenfolge vorhanden ist
	if self.orderTotemsInElement[element] == nil then --wenn noch keine Reihenfolge vorhanden ist dann die Totemspells einfach durchgehen
		for idx, spellId in ipairs(self.availableTotems[element]) do
			if type(spellId) == "number" then
				self:CreateSpellPopupButton(Yatabar["TotemHeader"..element], idx, spellId, element)
			end
		end
	else	--sonst nach reihenfolge
		for spellId, idx in pairs(self.orderTotemsInElement[element]) do
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
	local name = "YatabarButton"..element..index
	main["popupButton"..element..index] = LAB:CreateButton(spellId, name , main)
	main["popupButton"..element..index].name = "popupButton"..element..index
	main["popupButton"..element..index].spellId = spellId
	main["popupButton"..element..index].index = index
	main["popupButton"..element..index].element = element
	main["popupButton"..element..index]:SetPoint("BOTTOMLEFT", main,"BOTTOMLEFT", 0,(index - 1) * Yatabar.buttonSize)
	main["popupButton"..element..index]:SetAttribute('state', "spell1")
	main["popupButton"..element..index]:SetAttribute('index', index)
	main["popupButton"..element..index]:SetState("spell1", "spell", spellId)
	main["popupButton"..element..index]:AddToMasque(myGroup)
	--main["popupButton"..element..index]:SetScript("OnDragStart", nil);
	--main["popupButton"..element..index]:SetScript("OnReceiveDrag", function() Yatabar:isTotemFor(element); end );
	main["popupButton"..element..index]:SetScript("OnEvent", function(arg1,event) Yatabar:OnEventFunc(event, arg1, element, main["popupButton"..element..index]); end);
	SecureHandlerWrapScript(main["popupButton"..element..index],"OnLeave",main,[[return true, ""]], [[
		inHeader =  control:IsUnderMouse(true)
		if not inHeader then
			control:Run(close);
		end	    
	]])

	SecureHandlerWrapScript(main["popupButton"..element..index],"OnEnter",main, [[
		control:Run(show);
		]]);

	main["popupButton"..element..index]:RegisterEvent("ACTIONBAR_SHOWGRID");
	main["popupButton"..element..index]:RegisterEvent("ACTIONBAR_HIDEGRID");
	main["popupButton"..element..index]:RegisterEvent("PLAYER_REGEN_DISABLED");
	main["popupButton"..element..index]:RegisterEvent("PLAYER_REGEN_ENABLED");
	
	main["popupButton"..element..index]:Execute ( [[show = [=[
			self:Show()
		]=] ]])
	main["popupButton"..element..index]:Execute ( [[hide = [=[
			self:Hide()
		]=] ]])
	
end

function Yatabar:NewLayout()
	local rootx, rooty = 0, 0;
	local isVert, isRtDn = false, false;
	local size = Yatabar.buttonSize;
	local orientation = self.config.orientation;
	if (orientation == "horzdown") then
		isRtDn = true;
	elseif (orientation == "vertleft") then
		isVert = true;
	elseif (orientation == "vertright") then
		isVert = true;
		isRtDn = true;
	end
	if (isVert) then
		rootx = size;
	else
		rooty = size;
	end
end

function Yatabar:UpdateLayout(frame, x,y,isVert,isRtDn)
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

function Yatabar:GetTotemSpells()
	countSpells = 1
	for idx, totem in pairs(YatabarConfig.allTotems) do
		spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(totem["RankOneSpellID"])
		--welche Totems sind dem Spieler bekannt:
		spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellname)
		--print(spellname)
		if spellname ~= nil then
			Yatabar.availableTotems[countSpells] = {["SpellName"] = spellname, ["SpellId"] = spellId, ["ElementID"] = totem["ElementID"]}
			countSpells = countSpells +1
		end
	end
end

function Yatabar:GetTotemSpellsByElement()
	countSpells = 1
	for element, totem in pairs(YatabarConfig.totems) do
		Yatabar.availableTotems[element] = {}
		for idx, spell in pairs(totem) do
			local spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spell["id"])
			--welche Totems sind dem Spieler bekannt:
			spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellname)
			if spellname ~= nil then
				table.insert(Yatabar.availableTotems[element],spellId)
				if Yatabar.orderTotemsInElement[element] ~= nil then
					Yatabar.orderTotemsInElement[element][spellId] = countSpells
				end
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
		for i=1, Yatabar.availableTotems[element].count do
			--print(#Yatabar.orderTotemsInElement[element])
			if Yatabar.orderTotemsInElement[element][spell] == nil then
				Yatabar.orderTotemsInElement[element][spell] = #Yatabar.orderTotemsInElement[element]+1
			end
		end
	end
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
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
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
