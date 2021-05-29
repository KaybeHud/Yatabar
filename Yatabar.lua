if select(2, UnitClass('player')) ~= "SHAMAN" then
	return
end


local Totems = {
	["AIR"] = 4,
	["FIRE"] = 1,
	["WATER"] = 3,
	["EARTH"] = 2,
}

local TotemItems = {
	[EARTH_TOTEM_SLOT] = 5175,
	[FIRE_TOTEM_SLOT] = 5176,
	[WATER_TOTEM_SLOT] = 5177,
	[AIR_TOTEM_SLOT] = 5178,
}

Yatabar = LibStub("AceAddon-3.0"):NewAddon("Yatabar", "AceConsole-3.0")

Yatabar.spellLoaded = false
Yatabar.totemCount = 0 
Yatabar.buttonSize = 36
Yatabar.scale = Yatabar.buttonSize / 36
Yatabar.statusbarHeight = 6
Yatabar.name = "Yatabar"
Yatabar.frameBorder = 12
Yatabar.statusbarGap = 2
Yatabar.availableTotems = {}
Yatabar.totemsFound = {
	["AIR"] = false,
	["FIRE"] = false,
	["WATER"] = false,
	["EARTH"] = false,
}
Yatabar.popupKey = "nokey"
Yatabar.isLocked = true
Yatabar.activateSpellOrder = {active = false, element = "", order = 1}
Yatabar.activeTotemTimer = {}
Yatabar.activeTotemStartTime = {}
Yatabar.orderElements = {}
--Yatabar.hideMinimapIcon = false
Yatabar.orderTotemsInElement = {["EARTH"] = {}, ["WATER"] = {}, ["FIRE"] = {}, ["AIR"] = {}}
Yatabar.hideTimerBars = false
Yatabar.MacroResetKey = "shift"
Yatabar.ElementBinding = {
	["AIR"] = "",
	["FIRE"] = "",
	["WATER"] = "",
	["EARTH"] = "",
}

local _G = getfenv(0)
local L = LibStub("AceLocale-3.0"):GetLocale(Yatabar.name, true)
MSQ = LibStub("Masque", true)
yatabarGroup = {}

--LDB
local ldb = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(Yatabar.name, {
    type = "launcher",
    icon = "Interface\\Icons\\inv_banner_01",
    OnClick = function(self, button)
		if (button == "RightButton") then
			Yatabar:toggleLock()
		elseif button == "LeftButton" then
			LibStub("AceConfigDialog-3.0"):Open(Yatabar.name)
		elseif button == "MiddleButton" then
			Yatabar:toggleBarVisibility()
		end
	end,
	OnTooltipShow = function(Tip)
		if not Tip or not Tip.AddLine then
			return
		end
		Tip:AddLine(Yatabar.name)
		Tip:AddLine("|cFFff4040"..L["Left Click|r to open configuration"], 1, 1, 1)
		Tip:AddLine("|cFFff4040"..L["Middle Click|r to show/hide the bar"], 1, 1, 1)
		Tip:AddLine("|cFFff4040"..L["Right Click|r to lock/unlock bar"], 1, 1, 1)
	end,
})

Yatabar.icon = LibStub("LibDBIcon-1.0")

local defaults = 
{
	profile = {
		orderElements = {["EARTH"] = 1, ["WATER"] = 2, ["FIRE"] = 3, ["AIR"] = 4},
		orderTotemsInElement = {["EARTH"] = {}, ["WATER"] = {}, ["FIRE"] = {}, ["AIR"] = {}},
		orientation = "horzup",
		padding = 0,
		popupKey = "nokey",
		buttonSize = 36, 
		minimap = { ["hide"] = false, },
		hideTimerBars = false,
		MacroResetKey = "shift",
		ElementBinding = {
			["AIR"] = "",
			["FIRE"] = "",
			["WATER"] = "",
			["EARTH"] = "",
		},
		xOfs = 0,
		yOfs = 0,
		activeSet = {},
		sets = {},
		point = "CENTER",
		relativePoint = "CENTER",
		debugOn = false

	}
}



function Yatabar:OnInitialize()
	frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_LOGIN")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD") 
	frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
	frame:RegisterEvent("PLAYER_ALIVE") 
	frame:RegisterEvent("PLAYER_LEVEL_UP") 
	frame:RegisterEvent("SPELL_UPDATE_USABLE") 
	frame:RegisterEvent("VARIABLES_LOADED")
	frame:RegisterEvent("SPELLS_CHANGED")
	frame:SetScript("OnEvent", function(frame,event, ...) Yatabar:OnEventFunc(frame, event, ...); end);
	--print("Initialize")
	
	self:SetConfigVars()
	self.options = self:InitOptions()
	if Yatabar.config.debugOn then
		Yatabar:CreateDebugWindow()
	end
	
	-- self.optionsFrame:HookScript("OnHide", function()
	-- 	print("Close Option2")
	-- end)
	self:RegisterChatCommand("yb", "ChatCommand")
	self:RegisterChatCommand("yatabar", "ChatCommand")

	if MSQ then
		yatabarGroup = MSQ:Group(self.name,nil, true)
	end
	if Yatabar.icon then
		Yatabar.icon:Register(Yatabar.name, ldb, Yatabar.config.minimap)
		Yatabar.minimapButton = Yatabar.icon:GetMinimapButton(Yatabar.name)
		print(Yatabar.minimapButton:GetPoint())
	end
end

function Yatabar:SetConfigVars()
	self.db = LibStub("AceDB-3.0"):New("YatabarDB", defaults,"profile")
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
	self.db.RegisterCallback(self, "OnNewProfile", "OnNewProfile")
	self.config = self.db.profile
	self.orderElements = self.config.orderElements
	self.orderTotemsInElement = self.config.orderTotemsInElement
	self.buttonSize = self.config.buttonSize
	self.popupKey = self.config.popupKey
	self.hideTimerBars = self.config.hideTimerBars
	self.MacroResetKey = self.config.MacroResetKey
	self.hideMinimapIcon = self.config.hideMinimapIcon
	self.ElementBinding = self.config.ElementBinding 
	-- print(self.db.char.xOfs)
	-- print(self.db.char.yOfs)
end

--With TBC some Totem names have changed
--you have to update the saved names to the new ones
function Yatabar:RefreshTotemNames()
	for eleName, element in pairs(self.orderTotemsInElement) do 
		for totemIndex, totem in pairs (element) do
			spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(totem.id)
			--welche Totems sind dem Spieler bekannt:
			spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellname)
			if spellname ~= totem.name then
				if element == nil then
					if Yatabar.config.debugOn then
						Yatabar:AddDebugText("Yatabar: Totem name migration - old name: ".. totem.name.." - new name: "..spellname)
					end
				end
				self.orderTotemsInElement[eleName][totemIndex].name = spellname
			end
		end
	end
end

function Yatabar:OnEnable()
	self.totemCount = self:GetTotemCount()
	self:RefreshTotemNames()
	--print(self.config.xOfs, self.config.yOfs)
	self:CreateBar()
	--self:GetTotemSpellsByElement()
	self.ac = LibStub("AceConfig-3.0"):RegisterOptionsTable(Yatabar.name, self.options)
	
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, self.name)
	self.optionsFrameGui = LibStub("AceConfigDialog-3.0"):Open(self.name)
	Yatabar.minimapButton = Yatabar.icon:GetMinimapButton(Yatabar.name)
	self:GetTotemSpellsByElement()
	self:SetOrderTotemSpells()
	self:LoadKeyBinding()
		
	for element, spell in pairs(Yatabar.availableTotems) do
		if Yatabar.config.debugOn then
			Yatabar:AddDebugText("Yatabar: create header for: "..element)
		end
		self:CreateTotemHeader(element)
	end
	self:SetLayout()
	self:AddOptionsForTotems()
	Yatabar:HidePopups()


	--self:TestButton()
	
	--print("Enabled")
end

function Yatabar:OnNewProfile(db, profile)
	--print("new Profile")
	-- Yatabar:SetOrderTotemSpells()
	-- for element, idx in pairs(Yatabar.orderElements) do
	-- 	Yatabar:CreateTotemHeader(element)
	-- 	Yatabar["TotemHeader"..element]:Execute([[control:Run(show)]])
	-- 	Yatabar["TotemHeader"..element]:Execute([[control:Run(close)]])
	-- end
	-- self:SetLayout()
end

function Yatabar:RefreshConfig(arg1, db)
	--print("Refresh")
	--print(arg1)
	self.config = self.db.profile
	self.orderElements = self.config.orderElements
	self.orderTotemsInElement = self.config.orderTotemsInElement
	self:RefreshTotemNames()
	self.buttonSize = self.config.buttonSize
	self.popupKey = self.config.popupKey
	self.hideTimerBars = self.config.hideTimerBars
	self.MacroResetKey = self.config.MacroResetKey
	self.hideMinimapIcon = self.config.hideMinimapIcon
	self.ElementBinding = self.config.ElementBinding 
	self.totemCount = self:GetTotemCount()
	Yatabar:SetOrderTotemSpells()
	for element, idx in pairs(Yatabar.orderElements) do
		Yatabar:CreateTotemHeader(element)
		Yatabar["TotemHeader"..element]:Execute([[control:Run(show)]])
		Yatabar["TotemHeader"..element]:Execute([[control:Run(close)]])
		-- for k,v in pairs (self.options.args.totems.args[element].args) do
		-- 	if type(k) == "number" then
		-- 		for order, spell in pairs(self.orderTotemsInElement[element]) do
		-- 			if v.name == spell.name then	
		-- 				v.args.text.name = L["Position "]..order
		-- 				break;
		-- 			else
		-- 				v.args.text.name = L["Position "]..0
		-- 			end	
		-- 		end
		-- 	end
		-- end
	end
	self:SetLayout()
end



InterfaceOptionsFrame:HookScript("OnHide", function()
    --print("Close Option")
end)

-- the main frame for the bar
function Yatabar:CreateBar()
	if Yatabar.config.debugOn then
		Yatabar:AddDebugText("Yatabar: CreateBar") 
	end
	Yatabar.bar = CreateFrame("Frame", "YatabarBar", UIParent)
	Yatabar.bar:SetPoint(self.config.point,UIParent,self.config.relativePoint, self.config.xOfs, self.config.yOfs)
	Yatabar.bar.name = "Yatabar.bar"

	Yatabar.bar:SetWidth(self.buttonSize * Yatabar.totemCount + (2*self.frameBorder));
	Yatabar.bar:SetHeight(self.buttonSize + (2*self.frameBorder));
	Yatabar.bar:SetMovable(true);
	Yatabar.bar:SetClampedToScreen(true);
	
	Yatabar.bar.overlay = CreateFrame("Frame", "YatabarBarOverlay", Yatabar.bar, BackdropTemplateMixin and "BackdropTemplate")
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

	--Yatabar.bar:RegisterEvent("LEARNED_SPELL_IN_TAB")
	Yatabar.bar:RegisterEvent("PLAYER_REGEN_DISABLED")
	Yatabar.bar:RegisterEvent("PLAYER_REGEN_ENABLED")
	Yatabar.bar:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");
	Yatabar.bar:RegisterEvent("PLAYER_DEAD");
	--Yatabar.bar:RegisterEvent("MODIFIER_STATE_CHANGED")
	Yatabar.bar:SetScript("OnEvent", function(frame,event, ...) Yatabar:OnEventFunc(frame, event, ...); end);
	
	Yatabar.bar:Show()
end

function Yatabar:CreateTotemHeader(element)
	if Yatabar.config.debugOn then
		Yatabar:AddDebugText("Yatabar: CreateTotemHeader: "..element)
	end

	if Yatabar.availableTotems[element] == nil or Yatabar.availableTotems[element].count <1 then
		if Yatabar.config.debugOn then
			Yatabar:AddDebugText("CreateTotemHeader: no element or spells found, skip "..element)
		end
		return
	end
	local frameBorder = Yatabar.frameBorder 
	if Yatabar["TotemHeader"..element] == nil then
		Yatabar["TotemHeader"..element] = CreateFrame("Frame", "TotemHeader"..element, Yatabar.bar, "SecureHandlerStateTemplate")
	end

	Yatabar["TotemHeader"..element]:ClearAllPoints()
	Yatabar["TotemHeader"..element].name = "TotemHeader"..element
	Yatabar["TotemHeader"..element]:SetAttribute("key", self.popupKey)
	Yatabar["TotemHeader"..element]:SetAttribute("element", element)
	Yatabar["TotemHeader"..element]:SetPoint("BOTTOMLEFT", Yatabar.bar,"BOTTOMLEFT",(self.orderElements[element]-1) * Yatabar.buttonSize + frameBorder, frameBorder)
	Yatabar["TotemHeader"..element]:SetSize(Yatabar.buttonSize, Yatabar.buttonSize * #self.orderTotemsInElement[element]) -- self.availableTotems[element].count)

	--Yatabar["TotemHeader"..element]:SetBackdrop({
		-- 	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		-- 		tile = true,
		-- 		tileSize = 1,
		-- 		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		-- 		edgeSize = 0,
		-- 		insets = {left = 0, right = 0, top = 0, bottom = 0}
		-- })
		
	-- Yatabar["TotemHeader"..element]:SetBackdropColor(0, 0, 1, 1)
	-- Yatabar["TotemHeader"..element]:SetBackdropBorderColor(0.5, 0.5, 0, 0)

	Yatabar["TotemHeader"..element]:Show()

	if Yatabar["TotemHeader"..element].statusbar == nil then
		Yatabar["TotemHeader"..element].statusbar = self:GetStatusbar(Yatabar["TotemHeader"..element],element)
		Yatabar["TotemHeader"..element].statusbar:SetFrameLevel(1000) 
	end
	if self.hideTimerBars == false then
		Yatabar["TotemHeader"..element].statusbar:Show()
	else
		Yatabar["TotemHeader"..element].statusbar:Hide()
	end
	--Yatabar["TotemHeader"..element]:RegisterEvent("MODIFIER_STATE_CHANGED")
	--Yatabar["TotemHeader"..element]:SetScript("OnEvent", function(frame,event, arg1, arg2) Yatabar:OnEventFunc(event, arg1, arg2, frame); end);

	Yatabar["TotemHeader"..element]:SetAttribute("_onstate-mouseover", [[ 
		key = self:GetAttribute("key")
		if self:IsUnderMouse(true) then
			if (key == "alt" and IsAltKeyDown()) or (key == "shift" and IsShiftKeyDown()) or (key == "control" and IsControlKeyDown()) then
				self:Run(show);
			end
		end 
		]]
	)
	RegisterStateDriver(Yatabar["TotemHeader"..element], "mouseover", "[modifier:shift/ctrl/alt] key; no")


	for idx, spell in pairs(self.orderTotemsInElement[element]) do
		if  type(spell.id) == "number" then --and idx ~= 0 then 
			--print("add spell", spell.name:gsub("%s+", ""), spell.id)
			self:CreatePopupButton(Yatabar["TotemHeader"..element], idx, spell.id, element, spell.name) --spell.name ohne leerzeichen
		end
	end
	

		Yatabar["TotemHeader"..element]:Execute ( [[show = [=[
			local popups = newtable(self:GetChildren())
			for i, button in ipairs(popups) do
				if button:GetAttribute("index") ~= 0 then
					button:Show()
				end
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






function Yatabar:SetLayout()
	local isVert, isRtorDn = false, false;
	local orientation = Yatabar.config.orientation;
	if (orientation == "horzdown") then
		isRtorDn = true;
	elseif (orientation == "vertleft") then
		isVert = true;
	elseif (orientation == "vertright") then
		isVert = true;
		isRtorDn = true;
	end
	if (isVert) then
		Yatabar.bar:SetHeight(Yatabar.buttonSize * Yatabar.totemCount + (2*Yatabar.frameBorder));
		Yatabar.bar:SetWidth(Yatabar.buttonSize + (2*Yatabar.frameBorder));
	else
		Yatabar.bar:SetWidth(Yatabar.buttonSize * Yatabar.totemCount + (2*Yatabar.frameBorder));
		Yatabar.bar:SetHeight(Yatabar.buttonSize + (2*Yatabar.frameBorder));
	end

	for element, spell in pairs(Yatabar.availableTotems) do
		if Yatabar["TotemHeader"..element] ~= nil then
			Yatabar:UpdateHeaderLayout(Yatabar["TotemHeader"..element], element,isVert, isRtorDn)
		end
	end
	if MSQ then
		if yatabarGroup then
			yatabarGroup:ReSkin()
		end
	end
end

function Yatabar:UpdateHeaderLayout(frame, element,isVert,isRtorDn)
	--frame:Execute([[control:Run(show)]])
	frame:ClearAllPoints();
	frame.statusbar:ClearAllPoints()
	frame.statusbar.value:ClearAllPoints()
	if (isVert and not isRtorDn) then
		frame:SetPoint("TOPRIGHT", Yatabar.bar,"TOPRIGHT", -Yatabar.frameBorder, -(Yatabar.orderElements[element]-1) * Yatabar.buttonSize - Yatabar.frameBorder)
		frame:SetSize( Yatabar.buttonSize * self.availableTotems[element].count, Yatabar.buttonSize)
		frame.statusbar:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0,-1)
		frame.statusbar:SetSize(Yatabar.statusbarHeight *Yatabar.scale, Yatabar.buttonSize - (Yatabar.statusbarGap*Yatabar.scale))
		frame.statusbar:SetOrientation("VERTICAL")
		frame.statusbar.value:SetPoint("LEFT", frame.statusbar, "RIGHT", 0, 0)
	elseif isVert and isRtorDn then
		frame:SetPoint("TOPLEFT", Yatabar.bar,"TOPLEFT", Yatabar.frameBorder, -(Yatabar.orderElements[element]-1) * Yatabar.buttonSize - Yatabar.frameBorder)
		frame:SetSize( Yatabar.buttonSize * self.availableTotems[element].count, Yatabar.buttonSize)
		frame.statusbar:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0,-1)
		frame.statusbar:SetSize(Yatabar.statusbarHeight*Yatabar.scale, Yatabar.buttonSize - (Yatabar.statusbarGap*Yatabar.scale))
		frame.statusbar:SetOrientation("VERTICAL")
		frame.statusbar.value:SetPoint("RIGHT", frame.statusbar, "LEFT", 0, 0)
	elseif not isVert and isRtorDn then
		frame:SetPoint("TOPLEFT", Yatabar.bar,"TOPLEFT",(Yatabar.orderElements[element]-1) * Yatabar.buttonSize + Yatabar.frameBorder, -Yatabar.frameBorder)
		frame:SetSize(Yatabar.buttonSize, (Yatabar.buttonSize * self.availableTotems[element].count))
		frame.statusbar:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 1, 0)
		frame.statusbar:SetSize(Yatabar.buttonSize - (Yatabar.statusbarGap*Yatabar.scale), Yatabar.statusbarHeight *Yatabar.scale)
		frame.statusbar:SetOrientation("HORIZONTAL")
		frame.statusbar.value:SetPoint("CENTER", frame.statusbar, "CENTER", 0, 0)
	else
		frame:SetPoint("BOTTOMLEFT", Yatabar.bar,"BOTTOMLEFT",(Yatabar.orderElements[element]-1) * Yatabar.buttonSize + Yatabar.frameBorder, Yatabar.frameBorder)
		frame:SetSize(Yatabar.buttonSize, Yatabar.buttonSize * self.availableTotems[element].count)
		frame.statusbar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 1, 0)
		frame.statusbar:SetSize( Yatabar.buttonSize - (Yatabar.statusbarGap*Yatabar.scale), Yatabar.statusbarHeight *Yatabar.scale)
		frame.statusbar:SetOrientation("HORIZONTAL")
		frame.statusbar.value:SetPoint("CENTER", frame.statusbar, "CENTER", 0, 0)
	end

	
	for idx, spell in pairs(self.orderTotemsInElement[element]) do
		if type(spell.id) == "number" and idx ~= 0 then
			--print("Reihenfolge",element,spellId, idx)
			Yatabar:UpdateButtonLayout(frame, element,isVert,isRtorDn, idx, spell.id)
		end
	end

	--frame:Execute([[control:Run(close)]])
end

function Yatabar:UpdateButtonLayout(frame, element,isVert,isRtorDn, idx, spellId)
	if idx == 0 then
		return
	end
	spellname = GetSpellInfo(spellId)
	spellname = spellname:gsub("%s+", "")
	if frame["popupButton"..element..spellname] ~= nil then
		frame["popupButton"..element..spellname]:ClearAllPoints()
	
	else 
		if Yatabar.config.debugOn then
			Yatabar:AddDebugText("Yatabar: popupButton"..element..spellname..spellId)
		end
		return
	end
	
	if (isVert and isRtorDn) then
		frame["popupButton"..element..spellname]:SetPoint("TOPLEFT", frame,"TOPLEFT",(idx - 1) * Yatabar.buttonSize, 0)
		frame["popupButton"..element..spellname].index = idx
		frame["popupButton"..element..spellname]:SetAttribute('index', idx)
	elseif isVert and not isRtorDn then
		frame["popupButton"..element..spellname]:SetPoint("TOPRIGHT", frame,"TOPRIGHT", -(idx - 1) * Yatabar.buttonSize, 0)
		frame["popupButton"..element..spellname].index = idx
		frame["popupButton"..element..spellname]:SetAttribute('index', idx)
	elseif not isVert and isRtorDn then
		frame["popupButton"..element..spellname]:SetPoint("TOPLEFT", frame,"TOPLEFT", 0,-(idx - 1) * Yatabar.buttonSize)
		frame["popupButton"..element..spellname].index = idx
		frame["popupButton"..element..spellname]:SetAttribute('index', idx)
	else
		frame["popupButton"..element..spellname]:SetPoint("BOTTOMLEFT", frame,"BOTTOMLEFT", 0,(idx - 1) * Yatabar.buttonSize)
		frame["popupButton"..element..spellname].index = idx
		frame["popupButton"..element..spellname]:SetAttribute('index', idx)
	end
	--frame["popupButton"..element..spellname]:SetScale(Yatabar.buttonSize/36)--SetSize(Yatabar.buttonSize,Yatabar.buttonSize)
	frame["popupButton"..element..spellname]:SetSize(Yatabar.buttonSize,Yatabar.buttonSize)
	--frame["popupButton"..element..spellname]:SetScale(1)--SetSize(Yatabar.buttonSize,Yatabar.buttonSize)
	--frame["popupButton"..element..spellname].NormalTexture:SetScale(Yatabar.buttonSize/36)
	
end


function Yatabar:OnEventFunc(frame, event, arg1,...)
	if event == "PLAYER_ENTERING_WORLD"  or event == "PLAYER_ALIVE" or event == "PLAYER_LEVEL_UP"   then
		--print(event)
	end
	if event == "SPELLS_CHANGED" then
		--print(event)
		if InCombatLockdown() then
			return
		end
		Yatabar.spellLoaded = true
		self:GetTotemSpellsByElement()
		self:SetOrderTotemSpells()
		for element, spell in pairs(Yatabar.availableTotems) do
			self:CreateTotemHeader(element)
		end
		self:SetLayout()
		self:AddOptionsForTotems()
		Yatabar:HidePopups()
		--if Yatabar.firstRun == false then

		-- self:GetTotemSpellsByElement()
		-- self:SetOrderTotemSpells()
		-- self:LoadKeyBinding()
		
		-- --self:GetTotemSpells()
		-- for element, spell in pairs(Yatabar.availableTotems) do
		-- 	self:CreateTotemHeader(element)
		-- end
		-- self:SetLayout()
		-- self:AddOptionsForTotems()
		-- Yatabar:HidePopups()

		--else
		--	Yatabar.firstRun = false
		--end
	end
	if event == "VARIABLES_LOADED" then
		--print(event)
	end
	if event == "SPELL_UPDATE_USABLE" then
		--print(event)
	end
	if event == "PLAYER_LOGIN" or event == "ADDON_LOADED" then
		--print(event)	
	end
	if event == "PLAYER_REGEN_ENABLED" then
		--button:DisableDragNDrop(false)
	
	end
	if event == "PLAYER_REGEN_DISABLED" then
		--button:DisableDragNDrop(true)
	
	end
	if(event == "LEARNED_SPELL_IN_TAB") then
		print("Yatabar: ", L["new spell learned"])
		self:GetTotemSpellsByElement()
		--self:SetOrderTotemSpells()
		-- for element, spell in pairs(Yatabar.availableTotems) do
		-- 	self:CreateTotemHeader(element)
		-- end
		self:SetLayout()
		self:AddOptionsForTotems()
	
	end
	if event == "MODIFIER_STATE_CHANGED" then
		if frame ~= nil and MouseIsOver(frame) then 
			print(event,arg1, frame:GetAttribute("element"))
		end
	end
	
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		spellUIID, spellId = ...
		if arg1 == "player" then
			Yatabar:StartTimer(self, ...);
		end
		if spellId == YatabarConfig.spells.TotemicCall then
			Yatabar:StopTimer()
		end
	elseif event == "PLAYER_DEAD" then
		Yatabar:StopTimer()
	end	
end

--welche Totems sind dem Spieler bekannt:
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

function Yatabar:GetTotemSpellsByElement()
	local totemcount = 0
	if Yatabar.config.debugOn then
		Yatabar:AddDebugText("Yatabar: GetTotemSpellsByElement:")
	end
	countSpells = 0
	for element, totem in pairs(YatabarConfig.totems) do
		if Yatabar.config.debugOn then
			Yatabar:AddDebugText("GetTotemSpellsByElement: Element:"..element)
		end
		if Yatabar.totemsFound[element] == false then
			if Yatabar.config.debugOn then
				Yatabar:AddDebugText("GetTotemSpellsByElement: skip element:"..element)
			end
			--print("GetTotemSpellsByElement: skip element:"..element)	
		else
			Yatabar.availableTotems[element] = {}
			for idx, spell in pairs(totem) do
				if Yatabar:hasSpell(spell["id"]) then
					--print("---")
					spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spell["id"])
					--print(spellname,spell["id"], spellId, rank)
					spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellname) --spellId hat jetzt den höchsten Rang
					--print(spellname, spellId, rank)
					if spellname ~= nil then
						table.insert(Yatabar.availableTotems[element],{["id"] = spellId, ["name"] = spellname, ["duration"] = spell["duration"]} )  
						countSpells = countSpells + 1
					else
						if Yatabar.config.debugOn then
							Yatabar:AddDebugText("GetTotemSpellsByElement: Spellname not found: "..GetSpellInfo(spell["id"]))
						end
					end
				else
					--debug
					if Yatabar.config.debugOn then
						Yatabar:AddDebugText("GetTotemSpellsByElement: Spell not found: "..GetSpellInfo(spell["id"]))
					end
				end
			end
			
			Yatabar.availableTotems[element].count = countSpells 
			if Yatabar.config.debugOn then
				Yatabar:AddDebugText("GetTotemSpellsByElement: count spells for element: "..element.."::"..Yatabar.availableTotems[element].count)
			end
		end
		countSpells = 0
	end
end

--Auflistung/Sortierung der Totems in Reihenfolge
function Yatabar:SetOrderTotemSpells()
	if Yatabar.config.debugOn then
		Yatabar:AddDebugText("Yatabar: SetOrderTotemSpells: ")
	end

	local firstFill = false

	for element, spells in pairs(Yatabar.availableTotems) do
		--local count = 1
		if Yatabar.orderTotemsInElement[element][1] == nil then
			firstFill = true
		end
		if firstFill then
			for k, spell in pairs(spells) do
				if k ~= "count" then 	
					table.insert(Yatabar.orderTotemsInElement[element],spell)
				end
			end
			firstFill = false
		else 
			for k, spell in pairs(spells) do
				if k ~= "count" then 
					--local found = false
					for idx, spellOrdered in pairs(Yatabar.orderTotemsInElement[element]) do
						if spellOrdered.name  == spell.name then	--update spell
							Yatabar.orderTotemsInElement[element][idx].id = spell.id
							if Yatabar.config.debugOn then
								Yatabar:AddDebugText("SetOrderTotemSpells: update spell ".. spell.id.."::"..spell.name)
							end
							--found = true
							break
						else
							if Yatabar.config.debugOn then
								local txt1 = ""
								local txt2 = ""
								if spellOrdered.name ~= nil then txt1 = spellOrdered.name  end
								if spell.name ~= nil then txt2 = spell.name end
								--Yatabar:AddDebugText("SetOrderTotemSpells: checked "..txt1.."::"..txt2)
							end
						end
					end
					-- if found ~= true and firstFill == true then   --add new  spell
					-- 	print("new spell")
					-- 	table.insert(Yatabar.orderTotemsInElement[element],spell)
					-- 	found = false
					-- end	
				end
				-- if Yatabar.orderTotemsInElement[element][count] == nil and k ~= "count" then
				-- 	table.insert(Yatabar.orderTotemsInElement[element],spell)
				-- 	count = count + 1
				-- end
				--firstFill = false
			end
		end
		
	end
end






function Yatabar:IsTotemVisible(element, spellId)
	for idx, spell in pairs(self.orderTotemsInElement[element]) do
		if spell.id == spellId then
			return true
		end
	end
	return false
end

function Yatabar:GetTotemPosition(element, spellId)
	for idx, spell in pairs (self.orderTotemsInElement[element]) do
		if spell.id == spellId then
			--print(spell.name, idx)
			return idx
		end
	end
	return 0
end

function Yatabar:SetTotemVisibility(tbl, value, element, spellId, spellname)
	--print(spellId)
	--local spellname = GetSpellInfo(spellId)
	spllnm = spellname:gsub("%s+", "")
	if element == nil then
		if Yatabar.config.debugOn then
			Yatabar:AddDebugText("Yatabar: SetTotemVisibility: element is missing")
		end
		return
	end
	if spellId == nil then
		if Yatabar.config.debugOn then
			Yatabar:AddDebugText("Yatabar: SetTotemVisibility: spellId is missing")
		end
		return
	end
	if spellname == nil then
		if Yatabar.config.debugOn then
			Yatabar:AddDebugText("Yatabar: SetTotemVisibility: spellname is missing")
		end
		return
	end

	if value == true then
		table.insert(self.orderTotemsInElement[element],{["id"] = spellId, ["name"] = spellname})
		self:CreatePopupButton(Yatabar["TotemHeader"..element], #self.orderTotemsInElement[element], spellId, element, spellname)
	else
		--print("weg")
		local isFirst = false
		
		if Yatabar["TotemHeader"..element]["popupButton"..element..spllnm].index == 1 then
			isFirst = true
		end
		table.remove(self.orderTotemsInElement[element], Yatabar["TotemHeader"..element]["popupButton"..element..spllnm].index)
		if MSQ then
			if yatabarGroup then
				yatabarGroup:RemoveButton(Yatabar["TotemHeader"..element]["popupButton"..element..spllnm])		
			end
		end
		Yatabar["TotemHeader"..element]["popupButton"..element..spllnm].index = 0
		Yatabar["TotemHeader"..element]["popupButton"..element..spllnm]:SetAttribute('index', 0)
		Yatabar["TotemHeader"..element]["popupButton"..element..spllnm]:Hide()
		--Yatabar["TotemHeader"..element]["popupButton"..element..spllnm]:ClearStates()
		Yatabar["TotemHeader"..element]["popupButton"..element..spllnm] = nil

		if isFirst then
			local spell = self.orderTotemsInElement[element][1]
			if Yatabar["TotemHeader"..element]["popupButton"..element..spell.name:gsub("%s+", "")] ~= nil then
				Yatabar["TotemHeader"..element]["popupButton"..element..spell.name:gsub("%s+", "")]:Show()
			end
		end
	end

	--aktualisiere den Eintrag in der Config mit der neuen Position
	for idx, spell in pairs(self.availableTotems[element]) do
		if idx ~= "count" then
			local spell = GetSpellInfo(spellId)
			for index, value in ipairs (self.options.args.totems.args[element].args) do
				if value.args.button.name == spell then
					value.args = Yatabar:AddOptionsForTotems(index, element, spell.id, spell.name)
				end
			end
		end
	end
	Yatabar:SetLayout()
end

function Yatabar:SetElementOrder(newValue, element)
	if InCombatLockdown() then
		print("Yatabar: ", L["function not available during combat"])
		return
	end
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

function Yatabar:ActivateTotemOrder(element, tbl)
	if InCombatLockdown() then
		print("Yatabar: ", L["function not available during combat"])
		return
	end
	Yatabar.activateSpellOrder.active = not Yatabar.activateSpellOrder.active
	if Yatabar.activateSpellOrder.active then
		Yatabar.activateSpellOrder.order = 1
		Yatabar.activateSpellOrder.element = element
		tbl.option.name = "Stop reorder"
	else
		Yatabar:HidePopups()
		self.options.args.totems.args[element].args.activateSpellOrder.name = "Set Order"
	end
end

function Yatabar:SetTotemOrder(tbl,mousebutton, element, spellId)
	if InCombatLockdown() then
		print("Yatabar: ", L["function not available during combat"])
		return
	end
	if not Yatabar.activateSpellOrder.active then
		return
	end
	
	local totemFound = false
	local currentPosition = 0
	local newPosition = Yatabar.activateSpellOrder.order
	--set position for next totem
	Yatabar["TotemHeader"..element]:Execute([[
			control:Run(show)
			]])
	--print("new Position", newPosition)

	--check if clicked totem is visible/active
	for idx, spell in ipairs (self.orderTotemsInElement[element]) do
		if spell.id == spellId then
			currentPosition = idx
			totemFound = true
			break;
		end
	end
	if not totemFound then
		print("Yatabar: ",L["Totem not active"])
		return
	end
	if newPosition == currentPosition then
		return
	end
	Yatabar.activateSpellOrder.order = Yatabar.activateSpellOrder.order+1
	--print("oldpostion", currentPosition)
	local spellToSwitch = 0 
	local findSpellToSwitch = false
	for order, spell in pairs(self.orderTotemsInElement[element]) do
		if type(spell.id) == "number" and order == newPosition then
			spellToSwitch = spell.id
			findSpellToSwitch = true
			break;	
		end
	end

	--remove old keybind
	-- if newPosition == 1 then
	-- 	self:SetKeyBinding(element, nil) 
	-- end
	

	if findSpellToSwitch == false then
		print("Yatatbar: ", L["no more spell to switch"])
		Yatabar:ActivateTotemOrder(element, tbl)
		return
	end
	spellname = GetSpellInfo(spellId)
	spellnameToSwitch = GetSpellInfo(spellToSwitch)
	self.orderTotemsInElement[element][newPosition] = {["id"] = spellId, ["name"] = spellname}
	self.orderTotemsInElement[element][currentPosition] = {["id"] = spellToSwitch, ["name"] = spellnameToSwitch}
	
	-- Set keybinding if first totem changed and create new macro
	if newPosition == 1 then
		local key = Yatabar.ElementBinding[element]
		self:SetKeyBinding(element, key) 
		Yatabar:EditMacro(true, nil,nil)
	end

	--Set position text in Config Dialog
	for k,v in pairs (tbl.options.args.totems.args[element].args) do
		if v.name == tbl.option.name then
			v.args.text.name = L["Position "]..newPosition
		elseif v.name == spellnameToSwitch then
			v.args.text.name = L["Position "]..currentPosition
		end
	end

	

	self:SetLayout()
end

function Yatabar:GetTotemCount()
	count = 0
	-- for elem, id in pairs(TotemItems) do 
	-- 	if (elem) then
	-- 		local totemItem = GetItemCount(id)
	-- 		haveTotem = (totemItem and totemItem > 0) and true or false
	-- 	else

	-- 	end
	-- 	--haveTotem, totemName = GetTotemInfo(i)
	-- 	if haveTotem then
	-- 		--print(totemName)
	-- 		count = count + 1
	-- 	end
	-- end
		--debug

		if GetItemCount(TotemItems[WATER_TOTEM_SLOT]) > 0 then
			Yatabar.totemsFound["WATER"] = true
			count = count + 1
			if Yatabar.config.debugOn then
				Yatabar:AddDebugText("GetTotemCount -  WATER totem found, count: "..count)
			end
			--print("GetTotemCount -  WATER totem found, count: "..count)
		else
			Yatabar.totemsFound["WATER"] = false
			if Yatabar.config.debugOn then
				Yatabar:AddDebugText("GetTotemCount -  WATER totem not found, count: "..count)
			end
			--print("GetTotemCount -  WATER totem not found, count: "..count)
		end
		if GetItemCount(TotemItems[EARTH_TOTEM_SLOT]) > 0 then
			Yatabar.totemsFound["EARTH"] = true
			count = count + 1
			if Yatabar.config.debugOn then
				Yatabar:AddDebugText("GetTotemCount -  EARTH totem found, count: "..count)
			end
			--print("GetTotemCount -  EARTH totem found, count: "..count)
		else
			Yatabar.totemsFound["EARTH"] = false
			if Yatabar.config.debugOn then
				Yatabar:AddDebugText("GetTotemCount -  EARTH totem not found, count: "..count)
			end
			--print(("GetTotemCount -  EARTH totem not found, count: "..count))
		end
		if GetItemCount(TotemItems[AIR_TOTEM_SLOT]) > 0 then
			Yatabar.totemsFound["AIR"] = true
			count = count + 1
			if Yatabar.config.debugOn then
				Yatabar:AddDebugText("GetTotemCount -  AIR totem found, count: "..count)
			end
			--print("GetTotemCount -  AIR totem found, count: "..count)
		else
			Yatabar.totemsFound["AIR"] = false
			if Yatabar.config.debugOn then
				Yatabar:AddDebugText("GetTotemCount -  AIR totem not found, count: "..count)
			end
			--print("GetTotemCount -  AIR totem not found, count: "..count)
		end
		if GetItemCount(TotemItems[FIRE_TOTEM_SLOT]) > 0 then
			Yatabar.totemsFound["FIRE"] = true
			count = count + 1
			if Yatabar.config.debugOn then
				Yatabar:AddDebugText("GetTotemCount -  FIRE totem found, count: "..count)
			end
			--print("GetTotemCount -  FIRE totem found, count: "..count)
		else
			Yatabar.totemsFound["FIRE"] = false
			if Yatabar.config.debugOn then
				Yatabar:AddDebugText("GetTotemCount -  FIRE totem not found, count: "..count)
			end
			--print("GetTotemCount -  FIRE totem not found, count: "..count)
		end


		-- for elem, id in pairs(TotemItems) do 
			
		-- 	if Yatabar.config.debugOn then
		-- 		Yatabar:AddDebugText("GetTotemCount -  look for: "..elem.."::"..id)
		-- 		Yatabar:AddDebugText("GetTotemCount -  result: "..GetItemCount(id))
		-- 	end
		-- 	count = count + GetItemCount(id)
		-- 	print(#elem)
		-- end
		if Yatabar.config.debugOn then
			Yatabar:AddDebugText("GetTotemCount -  Totems found: "..count)
		end
	return count
end

function Yatabar:toggleLock()
	if InCombatLockdown() then
		print("Yatabar: ", L["function not available during combat"])
		return
	end
	Yatabar.isLocked = not Yatabar.isLocked;
	if not Yatabar.isLocked then
		Yatabar.bar.overlay:SetScript("OnDragStart", function() Yatabar:StartDrag(); end);
		Yatabar.bar.overlay:SetScript("OnDragStop", function() Yatabar:StopDrag(); end);
		Yatabar.bar.overlay:Show();
	else
		Yatabar.bar.overlay:SetScript("OnDragStart", nil);
		Yatabar.bar.overlay:SetScript("OnDragStop", nil);
		Yatabar.bar.overlay:Hide();
	end
end

function Yatabar:toggleBarVisibility()
	if InCombatLockdown() then
		print("Yatabar: ", L["function not available during combat"])
		return
	end

	if Yatabar.bar:IsVisible() then
		Yatabar.bar:Hide()
	else
		Yatabar.bar:Show()
	end
end

function Yatabar:HideMinimapIcon(value)
	if InCombatLockdown() then
		print("Yatabar: ", L["function not available during combat"])
		return
	end
	Yatabar.config.minimap.hide = value
	if value == true then
		Yatabar.icon:Hide(Yatabar.name)
	else
		Yatabar.icon:Show(Yatabar.name)
	end
	--print(Yatabar.icon:GetPoint())
end

function Yatabar:SetPopupKey(key)
	if InCombatLockdown() then
		print("Yatabar: ", L["function not available during combat"])
		return
	end
	Yatabar.popupKey = key
	self.config.popupKey = key
	for element, spell in pairs(Yatabar.availableTotems) do
		Yatabar["TotemHeader"..element]:SetAttribute("key", key)
	end
end

function Yatabar:SetKeyBinding(element, key)
	if key == nil or key == "" then
		key = Yatabar.ElementBinding[element] 
		SetBinding(key,"")
		Yatabar.ElementBinding[element] = ""
	else
		--search for an other element already binded to that key and delete it
		for elmnt, k in pairs(Yatabar.ElementBinding) do
			if key == k and element ~= elmnt then
				Yatabar:SetKeyBinding(elmnt, nil)
				print("Yatabar: ", L["key already bind"]..L[elmnt])
			end
		end
		--remove old key
		SetBinding(Yatabar.ElementBinding[element],"")
		Yatabar.ElementBinding[element] = key
		spellname = GetSpellInfo(Yatabar.orderTotemsInElement[element][1].name)
		local success = SetBindingSpell(key, spellname)
	end
	self.config.ElementBinding[element] = Yatabar.ElementBinding[element]
end

function Yatabar:LoadKeyBinding()
	for element, key  in pairs(Yatabar.ElementBinding) do
		if Yatabar.orderTotemsInElement[element][1] ~= nil then
			spellname = GetSpellInfo(Yatabar.orderTotemsInElement[element][1].name)
			if spellname ~= nil then
				SetBindingSpell(key, spellname)
			end
		end
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
		if Yatabar["TotemHeader"..element] ~= nil then
			Yatabar["TotemHeader"..element]:Execute([[
			control:Run(close)
			]])
		end
	end
end

function Yatabar:HideTimerBars(value) 
	if InCombatLockdown() then
		print("Yatabar: ", L["function not available during combat"])
		return
	end
	Yatabar.hideTimerBars = value
	self.config.hideTimerBars = value
	if value == true then
		for element, spell in pairs(Yatabar.availableTotems) do
			Yatabar["TotemHeader"..element].statusbar:Hide()
		end
	else
		for element, spell in pairs(Yatabar.availableTotems) do
			Yatabar["TotemHeader"..element].statusbar:Show()
		end
	end
end

function Yatabar:SavePosition()
	local scale = Yatabar.bar:GetEffectiveScale();
	local point, relativeTo, relativePoint, xOfs, yOfs =  Yatabar.bar:GetPoint()
	self.config.xOfs = xOfs
	self.config.yOfs = yOfs
	self.config.scale = scale	
	self.config.point = point
	self.config.relativePoint = relativePoint
end

function Yatabar:SetButtonSize(size)
	Yatabar.buttonSize = size
	Yatabar.config.buttonSize = size 
	Yatabar.scale = size /36
	Yatabar:SetLayout()
end

function Yatabar:ChatCommand(input)
	if not input or input:trim() == "" then
	--InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
	LibStub("AceConfigDialog-3.0"):Open("Yatabar")
  else
    LibStub("AceConfigCmd-3.0").HandleCommand(Yatabar, "yb", "Options", input)
  end
end

function Yatabar:StartTimer(self, guid, spellId)
	if Yatabar.hideTimerBars == true then
		return
	end
	--print("StartTimer", guid, spellId)
	
	local found = false;
	local name, startTime, duration, element;
	local countdown;
	local i;
	name = GetSpellInfo(spellId)

	if Yatabar.activeTotemTimer ~= nil then
		for elem, spell in pairs(Yatabar.activeTotemTimer) do
			button = _G["popupButton"..elem..spell.name:gsub("%s+", "")];
			if button ~= nil then
				button:SetChecked(false)
			end
		end
	end
	for elmnt, spells in pairs(self.availableTotems) do
		for idx, spell in ipairs(spells) do
			if spell.name == name then
				found = true
				duration =  GetTotemTimeLeft(Totems[elmnt])--spell.duration
				startTime = GetTime()
				element = elmnt
				break;
			end
		end
	end
	

	if found then
		Yatabar["TotemHeader"..element].statusbar:SetMinMaxValues(0, duration);
		Yatabar.activeTotemTimer[element] = {["id"] = spellId, ["duration"] = duration, ["name"] = name};
		Yatabar.activeTotemStartTime[element] = startTime

	-- 	if countdown and not self.hideCooldowns then
	-- 		countdown:SetStatusBarColor(unpack(SCHOOL_COLORS));
	-- 	end
	-- war vorher ohne "self"
		OnUpdate()
	end
end

function Yatabar:StopTimer()
	for element, spell in pairs(Yatabar.activeTotemTimer) do
		button = _G["popupButton"..element..spell.name:gsub("%s+", "")];
		if button ~= nil then
			button:SetChecked(false);
		end
		if Yatabar.activeTotemStartTime[element] ~= nil then
			Yatabar.activeTotemStartTime[element] = nil;
			countdown = Yatabar["TotemHeader"..element].statusbar;
			if countdown then
				countdown:SetValue(0);
				countdown.value:SetText("")
			end
		end
	end
end


function Yatabar:GetStatusbar(parent, element)
	local statusbar = CreateFrame("StatusBar", "Statusbar"..element, Yatabar.bar)
	statusbar:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 1, 0)
	statusbar:SetWidth(Yatabar.buttonSize-2)
	statusbar:SetHeight(Yatabar.statusbarHeight)
	statusbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	statusbar:GetStatusBarTexture():SetHorizTile(false)
	statusbar:GetStatusBarTexture():SetVertTile(false)
	--statusbar:SetStatusBarColor(0, 0.65, 0)
	statusbar:SetStatusBarColor(1.0, 0.7, 0.0);
	statusbar:SetScript("OnUpdate", OnUpdate);
	statusbar:SetMinMaxValues(0, 100);
	statusbar:SetValue(0)
	

	statusbar.bg = statusbar:CreateTexture(nil, "BACKGROUND")
	statusbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
	statusbar.bg:SetAllPoints(true)
	statusbar.bg:SetVertexColor(0, 0.35, 0)
	
	
	statusbar.value = statusbar:CreateFontString(nil, "OVERLAY")
	statusbar.value:SetPoint("CENTER", statusbar, "CENTER", 0, 0)
	statusbar.value:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
	statusbar.value:SetJustifyH("LEFT")
	statusbar.value:SetShadowOffset(1, -1)
	statusbar.value:SetTextColor(0, 1, 0)
	statusbar.value:SetText("")
	return statusbar
end

function OnUpdate(arg1, elapsed)
	local isActive;
	local button;
	local countdown;
	local timeleft;
	local duration;
	--local name; --, spell;
	local element;
	local i;

	
	for element, spell in pairs(Yatabar.activeTotemTimer) do
			button = _G["popupButton"..element..spell.name:gsub("%s+", "")];
			if button == nil then
				--print("kein button:"..element..spell.id)
				return
			end
			local start, dur, enable, modRate = GetSpellCooldown(spell.name)
			CooldownFrame_Set(button.cooldown, start, dur, enable)

			isActive = false;
			--button:SetChecked(false);
		if Yatabar.activeTotemStartTime[element] ~= nil then

			countdown = Yatabar["TotemHeader"..element].statusbar;
			if countdown then
				
				timeleft = Yatabar.activeTotemStartTime[element]
				--if not self.hideCooldowns then
					_, duration = countdown:GetMinMaxValues();

					timeleft = timeleft + duration - GetTime();
				--end
				isActive = timeleft > 0;

				if (isActive) then
					countdown:SetValue(timeleft);
					countdown.value:SetText(math.floor(timeleft))
				else
					Yatabar.activeTotemStartTime[element] = nil;
					countdown:SetValue(0);
					countdown.value:SetText("")
				end
			else
				isActive = Yatabar.activeTotemStartTime[element] ~= 0;
				--print("isActive:",isActive)
			end

			if isActive then
				button:SetChecked(true);
			else
				button:SetChecked(false);
			end
		end
	end
end


function Yatabar:GetTotemSet()
	local set = {}
	for element, spells in pairs(Yatabar.orderTotemsInElement) do
		if Yatabar.orderTotemsInElement[element] ~= nil and Yatabar.orderTotemsInElement[element][1] ~= nil then
			table.insert(set, Yatabar.orderTotemsInElement[element][1].name)
		end
		--print("TotemSet:",element, Yatabar.orderTotemsInElement[element][1].name)
	end
	return set
end

function Yatabar:EditMacro(force, old,new)
	if InCombatLockdown() then
		print("Yatabar: ", L["function not available during combat"])
		return
	end
	local num = GetNumMacros()
	local macroindex = GetMacroIndexByName("YatabarTotem")
	local totems = Yatabar:GetTotemSet()
	if force or macroindex == 0 and num < 36 then
		local macro = "#showtooltip\n/castsequence reset=combat/"..self.MacroResetKey.." "
		for k,v in ipairs(totems) do
			if totems[k] and totems[k+1] then
				macro = string.format("%s%s, ",macro,v)
			else
				macro = string.format("%s%s",macro,v)
			end
		end
		local iconid = "inv_banner_01"
		if force and macroindex > 0 then		
			EditMacro(macroindex, "YatabarTotem", iconid, macro, true)
		else
			CreateMacro("YatabarTotem",iconid,macro,true)
		end
	elseif macroindex > 0 and old and new then
		local name, texture, macro, isLocal = GetMacroInfo(macroindex)
		macro = string.gsub(macro,old,new)
		EditMacro(macroindex, name, texture, macro, isLocal);
	end	
end


local button = nil
function Yatabar:TestButton()
	local name = "Testbutton"
	button = CreateFrame("CheckButton", name, UIParent, "SecureHandlerStateTemplate, SecureHandlerEnterLeaveTemplate, SecureActionButtonTemplate,ActionButtonTemplate")
	button:SetPoint("CENTER",UIParent,"CENTER",-250,-250)
	button:SetWidth(36);
	button:SetHeight(36);
	
	button.icon = _G[name .. "Icon"];
	button.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94);

	button.normalTexture = _G[name .. "NormalTexture"];
	button.normalTexture:SetVertexColor(1, 1, 1, 0.5);
	--button.normalTexture:Hide()

	button.pushedTexture = button:GetPushedTexture();
	button.highlightTexture = button:GetHighlightTexture();

	button.cooldown = _G[name.."Cooldown"];
	button.border = _G[name.."Border"];
	button.macroName = _G[name.."Name"];
	button.hotkey = _G[name.."HotKey"];
	button.count = _G[name.."Count"];
	button.flash = _G[name.."Flash"];
	button.flash:Hide();
	button.border:Hide();

	button:Show()
	button:RegisterForClicks("LeftButtonUp")
	button:SetScript("OnClick", function(...) Yatabar:TestEvent(...)end)
end

function Yatabar:TestEvent()
	print("TestEvent")
	--Yatabar:EditMacro(true, nil,nil)
end