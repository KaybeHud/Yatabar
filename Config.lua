if not (Yatabar) then return; end;
local L = LibStub("AceLocale-3.0"):GetLocale(Yatabar.name, true)
local AceGUI = LibStub("AceGUI-3.0")
local newSetName = ""

function Yatabar:InitOptions()
	local options = {
		name = Yatabar.name,
		desc = L["Totem with popup buttons"],
		icon = "Interface\\Icons\\inv_banner_01",
		type="group",
		args = {
			hideBar = {
				type = "toggle",
				name = L["Hide the bar"],
				desc = L["Hide the bar"],
				order = 4,
				get = function() if Yatabar.bar ~= nil then return not Yatabar.bar:IsVisible() else return true end end,
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
			hideTimerBar = {
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
			segment = {
				type = "header",
				name = "",
				order = 8,
			},
			sets = {
				type = "select",
				name = L["Select set"],
				desc = L["Select set desc"],
				order = 9,
				get = function() if Yatabar.config.activeSet == nil then return "" end; return Yatabar.config.activeSet end,
				set = function(info, value) Yatabar.LoadSet(value) end,
				values = Yatabar:GetSets(),
			},
			saveSet = {
				type = "execute",
				name = L["Save set"],
				func = function(arg1) print(arg1) end,
			},
			createNewSet = {
				type = "execute",
				name = L["Create new set"],
				func = function() Yatabar:ShowSaveSetFrame() end,
			}, 
			deleteSet = {
				type = "execute",
				name = L["Delete set"],
				func = function(arg1) print(arg1) end,
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

function Yatabar:ShowSaveSetFrame()
	local f = AceGUI:Create("Frame")
	f:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
	f:SetWidth(300)
	f:SetHeight(120)
	f:SetTitle("Save Set")
	f:SetStatusText("Set to save")
	f:SetLayout("Flow")
	-- Create a button
	local btn = AceGUI:Create("Button")
	local edtBox = AceGUI:Create("EditBox")
	edtBox:DisableButton(true) 
	edtBox:SetMaxLetters(120)
	edtBox:SetFocus()
	btn:SetRelativeWidth(0.3)
	btn:SetText("Save")
	btn:SetCallback("OnClick", function() f:SetStatusText("Set "..edtBox:GetText().." saved");Yatabar:OnClickSave(edtBox:GetText()) end)

	edtBox:SetRelativeWidth(0.7)
	f:AddChild(edtBox)
	-- Add the button to the container
	f:AddChild(btn)
	
end

function Yatabar:GetSets() 
	local sets = {}
	for set, val in pairs(Yatabar.config.sets) do 
		table.insert(sets, set)
	end
	return sets
end

function Yatabar:LoadSet(setToLoad)
	local set = Yatabar.config.sets[setToLoad]
	Yatabar.orderElements = set.orderElements
	Yatabar.orderTotemsInElement = set.orderTotemsInElement
	Yatabar.ElementBinding = set.ElementBinding
end

function Yatabar:OnClickSave(arg1)
	Yatabar.config.activeSet = arg1
	local set = {orderElements = Yatabar.orderElements,
	orderTotemsInElement = Yatabar.orderTotemsInElement, ElementBinding = Yatabar.ElementBinding}
	Yatabar.config.sets[arg1] = set
end