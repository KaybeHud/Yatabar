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
local LAB = LibStub("LibActionButton-1.0")
Yatabar.spellLoaded = false
Yatabar.totemCount = 0 
Yatabar.buttonSize = 36
Yatabar.scale = Yatabar.buttonSize / 36
Yatabar.statusbarHeight = 6
Yatabar.name = "Yatabar"
Yatabar.frameBorder = 12
Yatabar.statusbarGap = 2
Yatabar.availableTotems = {}
Yatabar.popupKey = "nokey"
Yatabar.isLocked = true
Yatabar.activateSpellOrder = {active = false, element = "", order = 1}
Yatabar.activeTotemTimer = {}
Yatabar.activeTotemStartTime = {}
Yatabar.orderElements = {}
Yatabar.hideMinimapIcon = false
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
local MSQ = LibStub("Masque", true)
local myGroup = {}

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
	char = {
		orderElements = {["EARTH"] = 1, ["WATER"] = 2, ["FIRE"] = 3, ["AIR"] = 4},
		orderTotemsInElement = {["EARTH"] = {}, ["WATER"] = {}, ["FIRE"] = {}, ["AIR"] = {}},
		orientation = "horzup",
		padding = 0,
		popupKey = "nokey",
		buttonSize = 36, 
		minimap = { hide = false, },
		hideTimerBars = false,
		MacroResetKey = "shift",
		hideMinimapIcon = false,
		ElementBinding = {
			["AIR"] = "",
			["FIRE"] = "",
			["WATER"] = "",
			["EARTH"] = "",
		},
	}
}

function Yatabar:InitOptions()
	local options = {
		name = Yatabar.name,
		desc = L["Totem with popup buttons"],
		icon = "Interface\\Icons\\inv_banner_01",
		type="group",
		args = {
			barVisible = {
				type = "toggle",
				name = L["Hide the bar"],
				desc = L["Hide the bar"],
				order = 4,
				get = function() if Yatabar.bar == nil then return Yatabar.bar:IsVisible() else return false end end,
				set = function() Yatabar:toggleBarVisibility() end, 
			},
			orientation = {
				type = "select",
				name = L["Orientation"],
				desc = L["Set the orientation of the bar."],
				order = 1,
				get = function() return Yatabar.config.orientation; end,
				set = function(info,value) Yatabar.config.orientation = value; self:SetLayout(); end,
				values = {
					["horzup"] = L["Horizontal, Grow Up"],
					["horzdown"] = L["Horizontal, Grow Down"],
					["vertright"] = L["Vertical, Grow Right"],
					["vertleft"] = L["Vertical, Grow Left"],
				},
			},
			buttonsize = {
				type = "range",
				name = L["buttonsize"],
				desc = L["buttonsize desc"],
				order = 2,
				min = 5,
				max = 100,
				step = 1,
				get = function() return Yatabar.buttonSize end ,
				set = function(frame, size) Yatabar:SetButtonSize(size) end,

			},
			lockBar = {
				type = "toggle",
				name = L["Lock the bar"],
				desc = L["Lock/Unlock the bar"],
				order =3,
				get = function() return Yatabar.isLocked end,
				set = function(tbl,value) Yatabar:toggleLock() end,
			},
			keybind = {
				type = "select",
				name = L["Set popup key"],
				desc = L["Set popup key desc"],
				order = 7,
				get = function() return Yatabar.popupKey end,
				set = function(info, value) Yatabar:SetPopupKey(value) end,
				values = {
					["nokey"] = L["no key"],
					["shift"] = L["Shift-key"],
					["alt"] = L["Alt-key"],
					["control"] = L["Control-key"],
				},
			}, 
			hideTimerBars = {
				name = L["Hide timer bars"],
				type = "toggle",
				order = 5,
				desc = L["Hide timer bars desc"],
				get = function() return Yatabar.hideTimerBars end,
				set = function(frame, value) Yatabar:HideTimerBars(value) end,
			},
			hideMinimapIcon = {
				name = L["Hide minimap icon"],
				type = "toggle",
				order = 6,
				desc = L["Hide minimap icon desc"],
				get = function() return Yatabar.config.minimap.hide end,
				set = function(frame, value) Yatabar:HideMinimapIcon(value) end,
			},
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

	
	-- self.optionsFrame:HookScript("OnHide", function()
	-- 	print("Close Option2")
	-- end)
	self:RegisterChatCommand("yb", "ChatCommand")
	self:RegisterChatCommand("yatabar", "ChatCommand")

	if MSQ then
		myGroup = MSQ:Group(self.name,nil, true)
	end
	if Yatabar.icon then
		Yatabar.icon:Register(Yatabar.name, ldb, not Yatabar.config.minimap)
	end
end

function Yatabar:SetConfigVars()
	self.db = LibStub("AceDB-3.0"):New("YatabarDB", defaults)
	self.config = self.db.char
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

function Yatabar:OnEnable()
	self.totemCount = self:GetTotemCount()
	--self:LoadPosition()
	self:CreateBar()
	self:GetTotemSpellsByElement()
	LibStub("AceConfig-3.0"):RegisterOptionsTable(Yatabar.name, self.options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, self.name)
	self.optionsFrameGui = LibStub("AceConfigDialog-3.0"):Open(self.name)
	self:LoadKeyBinding()
	--self:TestButton()
	
	--print("Enabled")
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

	button.pushedTexture = button:GetPushedTexture();
	button.highlightTexture = button:GetHighlightTexture();

	button.cooldown = _G[name.."Cooldown"];
	button.border = _G[name.."Border"];
	button.macroName = _G[name.."Name"];
	button.hotkey = _G[name.."HotKey"];
	button.count = _G[name.."Count"];
	button.flash = _G[name.."Flash"];
	button.flash:Hide();

	button:Show()
	button:RegisterForClicks("LeftButtonUp")
	button:SetScript("OnClick", function(...) Yatabar:TestEvent(...)end)
end

function Yatabar:TestEvent()
	print("TestEvent")
	Yatabar:EditMacro(true, nil,nil)
end

InterfaceOptionsFrame:HookScript("OnHide", function()
    print("Close Option")
end)


function Yatabar:CreateBar()
	--print("CreateBar") 
	Yatabar.bar = CreateFrame("Frame", "YatabarBar", UIParent)
	Yatabar.bar:SetPoint("CENTER",UIParent,"CENTER", self.db.char.xOfs, self.db.char.yOfs)
	Yatabar.bar.name = "Yatabar.bar"

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
	Yatabar.bar:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");
	Yatabar.bar:RegisterEvent("PLAYER_DEAD");
	--Yatabar.bar:RegisterEvent("MODIFIER_STATE_CHANGED")
	Yatabar.bar:SetScript("OnEvent", function(frame,event, ...) Yatabar:OnEventFunc(frame, event, ...); end);
	
	Yatabar.bar:Show()
end

function Yatabar:CreateTotemHeader(element)
	--print("CreateTotemHeader")
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


	-- w

	--prüfen ob Reihenfolge vorhanden ist
	if self.orderTotemsInElement[element] == nil then --wenn noch keine Reihenfolge vorhanden ist dann die Totemspells einfach durchgehen
		for idx, spell in pairs(self.availableTotems[element]) do
			if type(spell.id) == "number" then
				self:CreateSpellPopupButton(Yatabar["TotemHeader"..element], idx, spell.id, element)
			end
		end
	else	--sonst nach reihenfolge
		for idx, spell in pairs(self.orderTotemsInElement[element]) do
			if  type(spell.id) == "number" and idx ~= 0 then 
				--print("add spell", spell.name:gsub("%s+", ""), spell.id)
				self:CreateSpellPopupButton(Yatabar["TotemHeader"..element], idx, spell.id, element, spell.name:gsub("%s+", "")) --spell.name ohne leerzeichen
			end
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


function Yatabar:CreateSpellPopupButton(main,index, spellId, element, spellname)
	--print("CreatePopups")
	if index == 0 then
		return
	end
	
	--print("Spellid", spellname, spellId)
	local name = "popupButton"..element..spellname
	if main["popupButton"..element..spellname] == nil then
		main["popupButton"..element..spellname] = LAB:CreateButton(name, name , main)
	main["popupButton"..element..spellname].name = name
	end
	main["popupButton"..element..spellname]:ClearAllPoints()
	main["popupButton"..element..spellname].spellId = spellId
	main["popupButton"..element..spellname].index = index
	main["popupButton"..element..spellname].element = element
	main["popupButton"..element..spellname]:SetPoint("BOTTOMLEFT", main,"BOTTOMLEFT", 0,(index - 1) * Yatabar.buttonSize)
	main["popupButton"..element..spellname]:ClearStates()
	main["popupButton"..element..spellname]:SetAttribute('state', "spell1")
	main["popupButton"..element..spellname]:SetAttribute('index', index)
	--main["popupButton"..element..spellname]:SetAttribute("type", "spell");
	--spname = GetSpellInfo(spellId)
	--main["popupButton"..element..spellname]:SetAttribute("spell", spname);
	main["popupButton"..element..spellname]:SetState("spell1", nil, nil)
	main["popupButton"..element..spellname]:SetState("spell1", "spell", spellId)
	--print(main["popupButton"..element..spellname]:GetAction("spell1"))
	main["popupButton"..element..spellname]:ButtonContentsChanged("spell1", "spell", spellId)
	if MSQ then
		main["popupButton"..element..spellname]:AddToMasque(myGroup)
	end
	
	main["popupButton"..element..spellname]:DisableDragNDrop(true)
	--main["popupButton"..element..spellId]:SetScript("OnEvent", function(arg1,event) Yatabar:OnEventFunc(event, arg1, element, main["popupButton"..element..spellId]); end);
	SecureHandlerWrapScript(main["popupButton"..element..spellname],"OnLeave",main,[[return true, ""]], [[
		inHeader =  control:IsUnderMouse(true)
		if not inHeader then
			control:Run(close);
		end	    
	]])

	SecureHandlerWrapScript(main["popupButton"..element..spellname],"OnEnter",main, [[
		key = control:GetAttribute("key")
		if key == "nokey" or (key == "alt" and IsAltKeyDown()) or (key == "shift" and IsShiftKeyDown()) or (key == "control" and IsControlKeyDown()) then
			control:Run(show);
		end
		]]);

	-- main["popupButton"..element..spellId]:SetAttribute("_onstate-mouseover", [[ 
	-- 	print("mouseover")
	-- 	if self:GetAttribute("index") ~= 1 then
	-- 		return
	-- 	end
	-- 	key = control:GetAttribute("key")
	-- 	print(key)
	-- 	if self:IsUnderMouse(true) then
	-- 		if (key == "alt" and IsAltKeyDown()) or (key == "shift" and IsShiftKeyDown()) or (key == "control" and IsControlKeyDown()) then
	-- 			self:Run(show);
	-- 		end
	-- 	end 
	-- 	]]
	-- )
	-- RegisterStateDriver(main["popupButton"..element..spellId], "mouseover", "[modifier:shift/ctrl/alt] key; no")

	--main["popupButton"..element..spellId]:RegisterEvent("ACTIONBAR_SHOWGRID");
	--main["popupButton"..element..spellId]:RegisterEvent("ACTIONBAR_HIDEGRID");
	
	
end

function Yatabar:UpdatePopupButton(button, index, spellId, element)
	if index == 0 then
		return
	end
	button:ClearAllPoints()
	button.spellId = spellId
	button.index = index
	button.element = element
	button:SetPoint("BOTTOMLEFT", main,"BOTTOMLEFT", 0,(index - 1) * Yatabar.buttonSize)
	button:ClearStates()
	button:SetAttribute('state', "spell1")
	button:SetAttribute('index', index)
	button:SetState("spell1", nil, nil)
	button:SetState("spell1", "spell", spellId)
	--print(button:GetAction("spell1"))
	--button:ButtonContentsChanged("spell1", "spell", spellId)
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
		Yatabar:UpdateHeaderLayout(Yatabar["TotemHeader"..element], element,isVert, isRtorDn)
	end
end

function Yatabar:UpdateHeaderLayout(frame, element,isVert,isRtorDn)
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

	if self.orderTotemsInElement[element] == nil then --wenn noch keine Reihenfolge vorhanden ist dann die Totemspells einfach durchgehen
		for idx, spell in ipairs(self.availableTotems[element]) do
			if type(spell.id) == "number" then
				Yatabar:UpdateButtonLayout(frame, element,isVert,isRtorDn, idx)
			end
		end
	else	--sonst nach reihenfolge
		for idx, spell in pairs(self.orderTotemsInElement[element]) do
			if type(spell.id) == "number" and idx ~= 0 then
				--print("Reihenfolge",element,spellId, idx)
				Yatabar:UpdateButtonLayout(frame, element,isVert,isRtorDn, idx, spell.id)
			end
		end
	end
end

function Yatabar:UpdateButtonLayout(frame, element,isVert,isRtorDn, idx, spellId)
	if idx == 0 then
		return
	end
	spellname = GetSpellInfo(spellId)
	spellname = spellname:gsub("%s+", "")
	frame["popupButton"..element..spellname]:ClearAllPoints()
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
	frame["popupButton"..element..spellname]:SetSize(Yatabar.buttonSize,Yatabar.buttonSize)
	if MSQ then
		myGroup:ReSkin()
	end
end


function Yatabar:OnEventFunc(frame, event, arg1, ...)
	if event == "PLAYER_ENTERING_WORLD" or event == "LEARNED_SPELL_IN_TAB" or event == "PLAYER_ALIVE" or event == "PLAYER_LEVEL_UP"   then
		--print(event)
		spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(8071)
		--print(spellname, spellId)
		spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellname) 
		--print(spellname, spellId)
	end
	if event == "SPELLS_CHANGED" then
		--print(event)
		Yatabar.spellLoaded = true
		--if Yatabar.firstRun == false then
		self:GetTotemSpellsByElement()
		self:SetOrderTotemSpells()
		
		
		--self:GetTotemSpells()
		for element, spell in pairs(Yatabar.availableTotems) do
			self:CreateTotemHeader(element)
		end
		self:SetLayout()
		self:AddOptionsForTotems()
		Yatabar:HidePopups()
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
	elseif event == "PLAYER_REGEN_ENABLED" then
		--button:DisableDragNDrop(false)
	
	elseif event == "PLAYER_REGEN_DISABLED" then
		--button:DisableDragNDrop(true)
	
	elseif(event == "LEARNED_SPELL_IN_TAB") then
		print("Yatabar: ", L["new spell learned"])
		self:GetTotemSpellsByElement()
		--self:SetOrderTotemSpells()
		-- for element, spell in pairs(Yatabar.availableTotems) do
		-- 	self:CreateTotemHeader(element)
		-- end
		self:SetLayout()
		self:AddOptionsForTotems()
	
	elseif event == "MODIFIER_STATE_CHANGED" then
		if frame ~= nil and MouseIsOver(frame) then 
			print(event,arg1, frame:GetAttribute("element"))
		end
	end
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		--print(arg1)
		if arg1 == "player" then
			Yatabar:StartTimer(self, ...);
		end
	elseif event == "PLAYER_DEAD" then
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
	countSpells = 1
	for element, totem in pairs(YatabarConfig.totems) do
		Yatabar.availableTotems[element] = {}
		for idx, spell in pairs(totem) do
			if Yatabar:hasSpell(spell["id"]) then
				--print("---")
				spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spell["id"])
				--print(spellname,spell["id"], spellId)
				spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellname) --spellId hat jetzt den höchsten Rang
				--print(spellname, spellId)
				if spellname ~= nil then
					table.insert(Yatabar.availableTotems[element],{["id"] = spellId, ["name"] = spellname, ["duration"] = spell["duration"]} )  
					countSpells = countSpells + 1
				end
			end 
		end
		Yatabar.availableTotems[element].count = countSpells - 1
		countSpells = 1
	end
end

--Auflistung/Sortierung der Totems in Reihenfolge
function Yatabar:SetOrderTotemSpells()
	local firstFill = false

	for element, spells in pairs(Yatabar.availableTotems) do
		local count = 1
		if Yatabar.orderTotemsInElement[element][1] == nil then
			firstFill = true
		end
		if firstFill then
			for k, spell in pairs(spells) do
				if k ~= "count" then 	
					table.insert(Yatabar.orderTotemsInElement[element],spell)
				end
			end
		else 
			for k, spell in pairs(spells) do
				if k ~= "count" then 
					local found = false
					for idx, spellOrdered in pairs(Yatabar.orderTotemsInElement[element]) do
						if spellOrdered.name  == spell.name then	--update spell
							Yatabar.orderTotemsInElement[element][idx].id = spell.id
							found = true
							break
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


function Yatabar:GetTotemPosition(element, spellId)
	for idx, spell in ipairs (self.orderTotemsInElement[element]) do
		if spell.id == spellId then
			return idx
		end
	end
	return 0
end

function Yatabar:AddOptionsForTotems()
	for element, order in pairs(self.orderElements) do
		self.options.args.totems.args[element] = {
			type = "group",
			name = L[element],
			args = {}
		}
		self.options.args.totems.args[element].args =  {
			text = {
				type = "description",
				order = 1,
				name = L["Set the order of the element"],
				fontSize = "medium",
			},
			totem = {
				name = L[element],
				desc = element,
				type = "range",
				order = 2,
				step = 1,
				min = 1,
				max = Yatabar.totemCount,
				isPercent = false,
				get = function() return self.orderElements[element]; end,
				set = function(info,value) Yatabar:SetElementOrder(value, element); end
			},
			header = {
				name = L["Totem configuration"],
				type = "header", 
				fontSize = "medium",
				order = 3,
			},
			activateSpellOrder = {
				name = L["Set Order"],
				order = 4,
				desc = L["Click to change order"],
				type = "execute",
				func = function(tbl,click) Yatabar:ActivateTotemOrder(element, tbl) end,
			},
			totemKeyBind = {
				name = L["Set key binding"],
				desc = L["Set the key binding desc"],
				type = "keybinding",
				get = function() return Yatabar.ElementBinding[element] end,
				set = function(tbl, key) Yatabar:SetKeyBinding(element, key) end,
			}
		}

		for idx, spell in pairs(self.availableTotems[element]) do
			if idx ~= "count" then
				buttonGrp = Yatabar:AddOptionsForTotem(idx, element, spell.id, spell.name)
				if buttonGrp ~= nil then
					table.insert(self.options.args.totems.args[element].args, buttonGrp)
				end
			end
		end
	end

end

function Yatabar:AddOptionsForTotem(idx, element, spellId, spellname)
	local _, _, icon = GetSpellInfo(spellId)
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
					func = function(tbl,mousebutton) Yatabar:SetTotemOrder(tbl,mousebutton, element,spellId) end,
				},
				visible = {
					name = L["show"],
					order = 3,
					type = "toggle",
					tristate = true,
					set = function(tbl,value) Yatabar:SetTotemVisibility(tbl,value, element, spellId, spellname) end,
					get = function() if Yatabar.activateSpellOrder.active == true then return nil else return Yatabar:IsTotemVisible(element, spellId) end end,
				},
				text = {
					type = "description",
					order = 1,
					name = L["Position "]..Yatabar:GetTotemPosition(element, spellId) or 0,
				},
			},
		}
				
		return buttonGrp
	end
	return nil
end

function Yatabar:IsTotemVisible(element, spellId)
	for idx, spell in pairs(self.orderTotemsInElement[element]) do
		if spell.id == spellId then
			return true
		end
	end
	return false
end

function Yatabar:SetTotemVisibility(tbl, value, element, spellId, spellname)
	--print(spellId)
	--local spellname = GetSpellInfo(spellId)
	spllnm = spellname:gsub("%s+", "")
	if value == true then
		table.insert(self.orderTotemsInElement[element],{["id"] = spellId, ["name"] = spellname})
			self:CreateSpellPopupButton(Yatabar["TotemHeader"..element], #self.orderTotemsInElement[element], spellId, element, spllnm)
		for k,v in pairs (tbl.options.args.totems.args[element].args) do
			if v.name == spellname then
				v.args.text.name = "Position "..#self.orderTotemsInElement[element]
				break
			end
		end
	else
		--print("weg")
		local isFirst = false
		
		if Yatabar["TotemHeader"..element]["popupButton"..element..spllnm].index == 1 then
			isFirst = true
		end
		table.remove(self.orderTotemsInElement[element], Yatabar["TotemHeader"..element]["popupButton"..element..spllnm].index)
		Yatabar["TotemHeader"..element]["popupButton"..element..spllnm].index = 0
		Yatabar["TotemHeader"..element]["popupButton"..element..spllnm]:SetAttribute('index', 0)
		Yatabar["TotemHeader"..element]["popupButton"..element..spllnm]:Hide()
		Yatabar["TotemHeader"..element]["popupButton"..element..spllnm]:ClearStates()
		Yatabar["TotemHeader"..element]["popupButton"..element..spllnm] = nil
		for k,v in pairs (tbl.options.args.totems.args[element].args) do
			if v.name == spellname then
				v.args.text.name = "Position "..0
				break
			end
		end
		if isFirst then
			local spell = self.orderTotemsInElement[element][1]
			Yatabar["TotemHeader"..element]["popupButton"..element..spell.name:gsub("%s+", "")]:Show()
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
	local newPosition = Yatabar.activateSpellOrder.order
	--print("setOrder")
	local totemFound = false
	local currentPosition = 0
	--check if clicked totem is visible/active
	for idx, spell in ipairs (self.orderTotemsInElement[element]) do
		if spell.id == spellId then
			currentPosition = idx
			totemFound = true
		end
	end
	if not totemFound then
		print("Yatabar: ",L["Totem not active"])
		return
	end
	if newPosition == currentPosition then
		return
	end
	--print("oldpostion", currentPosition)
	
	Yatabar.activateSpellOrder.order = Yatabar.activateSpellOrder.order+1
	Yatabar["TotemHeader"..element]:Execute([[
			control:Run(show)
			]])
	--print("new Position", newPosition)
	
	
	 
	local spellToSwitch = 0 
	local findSpellToSwitch = false
	for order, spell in pairs(self.orderTotemsInElement[element]) do
		if type(spell.id) == "number" and order == newPosition then
			spellToSwitch = spell.id
			findSpellToSwitch = true
			break	
		end
	end

	if findSpellToSwitch == false then
		print("Yatatbar: ", L["no more spell to switch"])
		Yatabar:ActivateTotemOrder(element, tbl)
		return
	end
	spellname = GetSpellInfo(spellId)
	spellnameToSwitch = GetSpellInfo(spellToSwitch)
	self.orderTotemsInElement[element][newPosition] = {["id"] = spellId, ["name"] = spellname}
	self.orderTotemsInElement[element][currentPosition] = {["id"] = spellToSwitch, ["name"] = spellnameToSwitch}
	

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
	for elem, id in pairs(TotemItems) do 
		if (elem) then
			local totemItem = GetItemCount(id)
			haveTotem = (totemItem and totemItem > 0) and true or false
		end
		--haveTotem, totemName = GetTotemInfo(i)
		if haveTotem then
			--print(totemName)
			count = count + 1
		end
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
		print(value)
		Yatabar.icon:Hide()
	else
		print("_",value)
		Yatabar.icon:Show()
	end
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
		Yatabar.ElementBinding[element] = key
		spellname = GetSpellInfo(Yatabar.orderTotemsInElement[element][1].name)
		local success = SetBindingSpell(key, spellname)
	end
	self.config.ElementBinding[element] = Yatabar.ElementBinding[element]
end

function Yatabar:LoadKeyBinding()
	for element, key  in pairs(Yatabar.ElementBinding) do
		spellname = GetSpellInfo(Yatabar.orderTotemsInElement[element][1].name)
		SetBindingSpell(key, spellname)
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

function Yatabar:HideTimerBars(value) 
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
	self.db.char.xOfs = xOfs
	--print(self.db.char.xOfs)
	self.db.char.yOfs = yOfs
	--print(self.db.char.yOfs)
	self.db.char.scale = scale	
end

function Yatabar:SetButtonSize(size)
	Yatabar.buttonSize = size
	Yatabar.config.buttonSize = size 
	Yatabar.scale = size /36
	Yatabar:SetLayout()
end

-- function Yatabar:isTotemFor(element)
-- 	infoType, spell = GetCursorInfo()
-- 	skillType, spellID = GetSpellBookItemInfo(spell, BOOKTYPE_SPELL)
-- 	if infoType == "spell" then 
-- 		if Yatabar:hasSpell(spellID) then
-- 			for index, spell in pairs(Yatabar.orderTotemsInElement[element]) do
-- 				if spell.id == spellID then
-- 					return true
-- 				end
-- 			end
-- 		end
-- 	end
-- 	return false
-- 	--self:SaveTotemSpellOrder(element)
-- end

function Yatabar:LoadPosition()
	local scale = self.db.char.scale
	local xOfs, yOfs = self.db.char.xOfs, self.db.char.yOfs
	print(xOfs, yOfs)
	--Yatabar.bar:SetPoint("CENTER",UIParent, "CENTER", xOfs, yOfs);
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
	
	local founded = false;
	local name, startTime, duration, element;
	local countdown;
	local i;
	name = GetSpellInfo(spellId)

	for elmnt, spells in pairs(self.availableTotems) do
		for idx, spell in ipairs(spells) do
			if spell.name == name then
				founded = true
				duration =  GetTotemTimeLeft(Totems[elmnt])--spell.duration
				startTime = GetTime()
				element = elmnt
				break;
			end
		end
	end
	

	if founded then
		Yatabar["TotemHeader"..element].statusbar:SetMinMaxValues(0, duration);
		Yatabar.activeTotemTimer[element] = {["id"] = spellId, ["duration"] = duration, ["name"] = name};
		Yatabar.activeTotemStartTime[element] = startTime

	-- 	if countdown and not self.hideCooldowns then
	-- 		countdown:SetStatusBarColor(unpack(SCHOOL_COLORS));
	-- 	end
		OnUpdate()
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
	local name; --, spell;
	local element;
	local i;

	
	for element, spell in pairs(Yatabar.activeTotemTimer) do
			button = _G["popupButton"..element..spell.name:gsub("%s+", "")];
			if button == nil then
				--print("kein button:"..element..spell.id)
				return
			end

			isActive = false;
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
				print("isActive:",isActive)
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
		table.insert(set, Yatabar.orderTotemsInElement[element][1].name)
		print("TotemSet:",element, Yatabar.orderTotemsInElement[element][1].name)
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
