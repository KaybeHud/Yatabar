if not (Yatabar) then return; end;
local L = LibStub("AceLocale-3.0"):GetLocale(Yatabar.name, true)

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