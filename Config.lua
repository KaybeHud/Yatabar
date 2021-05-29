if not (Yatabar) then return; end;
local L = LibStub("AceLocale-3.0"):GetLocale(Yatabar.name, true)
local AceGUI = LibStub("AceGUI-3.0")
local newSetName = ""
local _G = _G;

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
				get = function() if Yatabar.bar ~= nil then return not Yatabar.bar.overlay:IsVisible() else return true end end,
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
				get = function() if Yatabar.config.minimap then return Yatabar.config.minimap.hide else return false end end,
				set = function(frame, value) Yatabar:HideMinimapIcon(value) end,
			},
			segment = {
				type = "header",
				name = "",
				order = 10,
			},
			debugOn = {
				type = "toggle",
				name = "Debug output",
				order = 8,	
				desc = L["Actvate debug output"],
				get = function() return Yatabar.config.debugOn end,
				set = function(frame, value) Yatabar.config.debugOn = value end,
			},
			showDebugMsg = {
				type = "execute",
				order = 9,
				name = "Show debug messages",
				func = Yatabar.ShowWindow,
			},
			sets = {
				type = "select",
				name = L["Select set"],
				desc = L["Select set desc"],
				order = 11,
				get    = function() return Yatabar.db:GetCurrentProfile() end,
				set    = function(tbl, v) Yatabar:LoadProfile(v, false) end,
				validate = function() return not InCombatLockdown() or L["Profile cannot be changed in combat"] end,
				disabled = InCombatLockdown,
				values = function() return Yatabar:GetAllProfiles() end,
			},
			createNewSet = {
				type = "input",
				name = L["Create new set"],
				get = false,
				set = function(_, v) Yatabar:LoadProfile(v, true) end,
			}, 
			deleteSet = {
				type = "execute",
				order = 12,
				name = L["Delete set"],
				func = function(arg1) Yatabar:DeleteProfile(Yatabar.db:GetCurrentProfile()) end,
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
				order = 5,
				get = function() return Yatabar.ElementBinding[element] end,
				set = function(tbl, key) Yatabar:SetKeyBinding(element, key) end,
			}
		}
		if self.availableTotems[element] ~= nil then
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
					name = function() return L["Position "]..Yatabar:GetTotemPosition(element, spellId) end ,
				},
			},
		}
				
		return buttonGrp
	end
	return nil
end

-- function Yatabar:ShowSaveSetFrame()
-- 	local f = AceGUI:Create("Frame")
-- 	f:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
-- 	f:SetWidth(300)
-- 	f:SetHeight(120)
-- 	f:SetTitle("Save Set")
-- 	f:SetStatusText("Set to save")
-- 	f:SetLayout("Flow")
-- 	-- Create a button
-- 	local btn = AceGUI:Create("Button")
-- 	local edtBox = AceGUI:Create("EditBox")
-- 	edtBox:DisableButton(true) 
-- 	edtBox:SetMaxLetters(120)
-- 	edtBox:SetFocus()
-- 	btn:SetRelativeWidth(0.3)
-- 	btn:SetText("Save")
-- 	btn:SetCallback("OnClick", function() f:SetStatusText("Set "..edtBox:GetText().." saved");Yatabar:OnClickSave(edtBox:GetText()) end)

-- 	edtBox:SetRelativeWidth(0.7)
-- 	f:AddChild(edtBox)
-- 	-- Add the button to the container
-- 	f:AddChild(btn)
	
-- end

function Yatabar:GetAllProfiles() 
	local profiles = {}
	for _, name in pairs(Yatabar.db:GetProfiles()) do 
		profiles[name] = name
	end
	return profiles
end

function Yatabar:LoadProfile(profile, newProfile)
	for element, idx in pairs(Yatabar.orderElements) do
		if self.availableTotems[element] ~= nil then
			for idx, spell in pairs(self.availableTotems[element]) do
				if type(spell) ~= "number" and type(spell.name) == "string" then
					if Yatabar["TotemHeader"..element]["popupButton"..element..spell.name:gsub("%s+", "")] ~= nil then
						--print(spell.name:gsub("%s+", ""), "vorhanden")
						Yatabar["TotemHeader"..element]["popupButton"..element..spell.name:gsub("%s+", "")]:SetAttribute('index', 0)
						Yatabar["TotemHeader"..element]["popupButton"..element..spell.name:gsub("%s+", "")]:Hide()
					end
				end
			end
		end
		--Yatabar["TotemHeader"..element]:Hide()
	end
	
	Yatabar.db:SetProfile(profile)
end

function Yatabar:DeleteProfile(name)
	local index = 1
	local delete = false
	local setToProfile = nil
	--for dem Löschen muss zuerst ein anderes Profil ausgewählt werden
	--prüfen ob das ausgewählte Profil nicht das zu löschende ist
	for _, profileName in pairs(Yatabar:GetAllProfiles()) do
		setToProfile = profileName 
		if name ~= setToProfile then
			delete = true
			break
		end
	end
	if delete then
		--bevor es gelöscht werden kann, muss zuerst das neue gesetzt werden
		Yatabar:LoadProfile(setToProfile)
		Yatabar.db:DeleteProfile(name, true)
		print("Yatabar: "..L["Delete profile - "]..name)
	else
		print("Yatabar: "..L["Cannot delete profile"])
	end
end

-- function Yatabar:OnClickSave(arg1)
-- 	Yatabar.config.activeSet = arg1
-- 	local set = {orderElements = Yatabar.orderElements,
-- 	orderTotemsInElement = Yatabar.orderTotemsInElement, ElementBinding = Yatabar.ElementBinding}
-- 	Yatabar.config.sets[arg1] = set
-- end