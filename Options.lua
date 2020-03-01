if select(2, UnitClass('player')) ~= "SHAMAN" then
	return
end

local LBF = LibStub("LibButtonFacade",true)
local LSM = LibStub("LibSharedMedia-3.0",true)
local AceGUI = LibStub("AceGUI-3.0",true)
local LDB = LibStub("LibDataBroker-1.1", true)
local L = LibStub("AceLocale-3.0"):GetLocale("Yata")
local resetkeys = {"shift", "ctrl", "alt", "none"}
local stratum = {"LOW", "MEDIUM", "HIGH"}
function Yata:PopulateOptions()
	local options = {
	    name = "Yata",
	    handler = Yata,
	    type = 'group', 
	    args = {
			lock = {
				name = L["Lock"],
				desc = L["LockDesc"],
				type = "toggle",
				get = function() return self.CurrentDb.Locked end,
				set = function(info, value)
					if(value) then
						Yata.Bar:Lock()
					else
						Yata.Bar:Unlock()
					end		
					
					self.CurrentDb.Locked = value		
				end,
				width= "normal",
				disabled = function() return InCombatLockdown() end,
				},
			reset = {
					name = L["Reset"],
					desc = L["ResetDesc"],
					type = "execute",
					func = function() self:Reset() end,
					disabled = function() return InCombatLockdown() end,
					confirm = true,
					confirmText = "Are you sure you want to reset your Yata settings to their default values?",
					width = "double",
				},
			positionx = { 
						name = "X", 
						desc = L["XDesc"],
						type = "range", 
						get = function() return self.CurrentDb.BarPosition.x end,
						set = function(info, value) self.CurrentDb.BarPosition.x = value; Yata.Bar:SetPoint("BOTTOMLEFT", UIParent,"BOTTOMLEFT", self.CurrentDb.BarPosition.x, self.CurrentDb.BarPosition.y) end,
						width = "normal",
						min = 0,
						max = 2550,
						step = 0.01,
						bigStep = 50,
						disabled = function() return InCombatLockdown() end,
						},
			positiony = { 
						name = "Y",
						desc = L["YDesc"], 
						type = "range", 
						get = function() return self.CurrentDb.BarPosition.y end,
						set = function(info, value) self.CurrentDb.BarPosition.y = value; Yata.Bar:SetPoint("BOTTOMLEFT", UIParent,"BOTTOMLEFT", self.CurrentDb.BarPosition.x, self.CurrentDb.BarPosition.y) end,
						width = "normal",
						min = 0,
						max = 2550,
						step = 0.01,
						bigStep = 50,
						disabled = function() return InCombatLockdown() end,
						},
			totembuttons = {
				name = L["Bindings"],
				desc = L["BindingsDesc"],
				type = "group",
				args = {
					spells = { 
						name = L["Spells"], 
						type="header", 
						order = 0,
					},
					autobuttonswap = {
						name = L["EnableAutoSwap"],
						desc = L["EnableAutoSwapDesc"],
						type = "toggle",
						get = function() return self.CurrentDb.AutoButtonSwap end,
						set = function(info, value) Yata.CurrentDb.AutoButtonSwap = value; Yata.Bar:SetAttribute("autoswap", Yata.CurrentDb.AutoButtonSwap) end,
						disabled = function() return InCombatLockdown() end,
						order = 1,
						width = "full",
					},
					buttonswapkey = {
						name = L["SwapButton"],
						desc = L["SwapButtonDesc"],
						type = "select",
						values = resetkeys,
						get = function() for k,v in ipairs(resetkeys) do if v == self.CurrentDb.ButtonSwapKey then return k end end end,
						set = function(info, value) Yata.CurrentDb.ButtonSwapKey = resetkeys[value]; Yata.Bar:SetAttribute("swapkey", Yata.CurrentDb.ButtonSwapKey) end,
						disabled = function() return InCombatLockdown() end,
						order = 2,
					},
					buttonnoswapkey = {
						name = L["CastOnly"],
						desc = L["CastOnlyDesc"],
						type = "select",
						values = resetkeys,
						get = function() for k,v in ipairs(resetkeys) do if v == self.CurrentDb.ButtonNoSwapKey then return k end end end,
						set = function(info, value) Yata.CurrentDb.ButtonNoSwapKey = resetkeys[value]; SetAttribute("noswapkey",Yata.CurrentDb.ButtonNoSwapKey) end,
						disabled = function() return (InCombatLockdown() or self.CurrentDb.AutoButtonSwap == false) end,				
						order = 3,
					},
					multicast = { 
						name = L["Multicast"], 
						type="header", 
						order = 4,
					},
					autoswaptocall = {
						name = L["EnableCallSwap"],
						desc = L["EnableCallSwapDesc"],
						type = "toggle",
						get = function() return self.CurrentDb.AutoSwapToCall end,
						set = function(info, value) Yata.CurrentDb.AutoSwapToCall = value; Yata.Bar:SetAttribute("autoswaptocall", Yata.CurrentDb.AutoSwapToCall) end,
						disabled = function() return InCombatLockdown() end,
						order = 5,
						width = "full"
					},
					manualswaptocallkey = {
						name = L["ShowCall"],
						desc = L["ShowCallDesc"],
						type = "select",
						values = resetkeys,
						get = function() for k,v in ipairs(resetkeys) do if v == self.CurrentDb.ManualSwapToCallKey then return k end end end,
						set = function(info, value) self.CurrentDb.ManualSwapToCallKey = resetkeys[value]; Yata.Bar:SetManualSwapToCallKey() end,
						disabled = function() return InCombatLockdown() end,				
						order = 7,
					},
					buttonsetcallkey = {
						name = L["AssignToCall"],
						desc = L["AssignToCallDesc"],
						type = "select",
						values = resetkeys,
						get = function() for k,v in ipairs(resetkeys) do if v == self.CurrentDb.ButtonSetCallKey then return k end end end,
						set = function(info, value) Yata.CurrentDb.ButtonSetCallKey = resetkeys[value]; Yata.Bar:SetAttribute("setcallkey", Yata.CurrentDb.ButtonSetCallKey) end,
						disabled = function() return InCombatLockdown() end,
						order = 6,
					},	
				},
				order = 1,
			},
			totembar = {
				name = L["Appearance"],
				desc = L["AppearanceDesc"],
				type = "group",
				args = {
					barorientation = {
						name = L["Orientation"],
						desc = L["OrientationDesc"],
						type = "select",
						width = "double",
						values = {L["HU"], L["HD"], L["VR"], L["VL"] },
						get = function() return self.CurrentDb.BarOrientation end,
						set = function(info, value) Yata.Bar:ConfigureBarDisplay(self.CurrentDb.ButtonGap, value, self.CurrentDb.VisibleButtons); end,
						disabled = function() return InCombatLockdown() end,
						order = 0,
					},
					barscale = 	{
						name = L["Scale"],
						desc = L["ScaleDesc"],
						type = "range",
						get = function() return self.CurrentDb.BarScale end,
						set = function(info, value)
							self.CurrentDb.BarScale = value 
							self.Bar:SetScale(self.CurrentDb.BarScale)
						end,
						min = 0.5,
						max = 2.5,
						step = 0.01,
						bigStep = 0.05,
						disabled = function() return InCombatLockdown() end,
						width = "normal",
						order = 1,
					},
					popoutscale = 	{
						name = L["PopScale"],
						desc = L["PopScaleDesc"],
						type = "range",
						get = function() return self.CurrentDb.PopOutScale end,
						set = function(info, value)
							self.CurrentDb.PopOutScale = value 
							Yata.Bar:SetPopOutScale(value)
						end,
						min = 0.5,
						max = 1.5,
						step = 0.05,
						bigStep = 0.05,
						disabled = function() return InCombatLockdown() end,
						width = "normal",
						order = 2,
					},
					baralpha = 	{
						name = L["Alpha"],
						desc = L["AlphaDesc"],
						type = "range",
						get = function() return self.CurrentDb.Alpha end,
						set = function(info, value)
							self.CurrentDb.Alpha = value 
							self.Bar:SetAlpha(self.CurrentDb.Alpha)
						end,
						min = 0,
						max = 1,
						step = 0.01,
						bigStep = 0.05,
						disabled = function() return InCombatLockdown() end,
						width = "double",
						order = 3,
					},
					buttongap = {
						name = L["Gap"],
						desc = L["GapDesc"],
						type = "range",
						get = function() return self.CurrentDb.ButtonGap end,
						set = function(info, value) Yata.Bar:ConfigureBarDisplay(value, self.CurrentDb.BarOrientation, self.CurrentDb.VisibleButtons) end,
						min = -4,
						max = 8,
						step = 1,
						disabled = function() return InCombatLockdown() end,
						width = "double",
						order = 4,
					},					
					visiblebuttons = {
						name = L["SpellCount"],
						desc = L["SpellCountDesc"],
						type = "range",
						get = function() return self.CurrentDb.VisibleButtons end,
						set = function(info, value) Yata.Bar:ConfigureBarDisplay(self.CurrentDb.ButtonGap, self.CurrentDb.BarOrientation, value) end,
						min = 1,
						max = 10,
						step = 1,
						disabled = function() return InCombatLockdown() end,	
						width = "double",
						order = 3,
					},
					shorttooltip = {
						name = L["Tooltip"],
						desc = L["TooltipDesc"],
						type = "select",
						width = "double",
						values = {L["TooltipNone"], L["TooltipShort"], L["TooltipFull"] },
						get = function() return self.CurrentDb.Tooltip end,
						set = function(info, value) self.CurrentDb.Tooltip = value end,
						disabled = function() return InCombatLockdown() end,
						order = 5,
					},
					multitooltip = {
						name = L["MultiTooltip"],
						desc = L["MultiTooltipDesc"],
						type = "toggle",
						width = "full",
						get = function() return self.CurrentDb.MultiTooltip end,
						set = function(info, value) self.CurrentDb.MultiTooltip = value end,
						disabled = function() return (InCombatLockdown() or self.CurrentDb.Tooltip == 1) end,
						order = 6,
					},
					showkeybinds = {
						name = L["ShowKeybind"],
						desc = L["ShowKeybindDesc"],
						type = "toggle",
						width = "full",
						get = function() return self.CurrentDb.ShowKeybinds end,
						set = function(info, value) self.CurrentDb.ShowKeybinds = value; Yata.Bar:UpdateKeyBinds() end,
						disabled = function() return InCombatLockdown() end,
						order = 6,
					},
				},
				order = 0,				
			},
			totemtimers = {
				name = L["Timers"],
				desc = L["TimersDesc"],
				type = "group",
				args = {
					enabletimers = {
						name = L["EnableTimers"],
						desc = L["EnableTimersDesc"],
						type = "toggle",
						get = function() return self.CurrentDb.TimerEnabled end,
						set = function(info, value) self.CurrentDb.TimerEnabled = value; Yata:ResetTimers() end,
						disabled = function() return InCombatLockdown() end,
						order = 0,
						width = "full",
					},
					timertype = {
						name = L["TimerType"],
						desc = L["TimerTypeDesc"],
						type = "select",
						values = {L["TimerBars"], L["TimerSelf"], L["TimerBoth"]},
						get = function() return self.CurrentDb.TimerType end,
						set = function(info, value) self.CurrentDb.TimerType = value; Yata:ResetTimers() end,
						disabled = function() return (InCombatLockdown() or self.CurrentDb.TimerEnabled == false) end,
						order = 1,
						width = "double",
					},
					timerbar = { 
						name = L["TimerBar"], 
						type="header", 
						order = 2,
					},
					timerbarorientation = {
						name = L["TimerOrientation"],
						desc = L["TimerOrientationDesc"],
						type = "select",
						width = "double",
						values = { L["TLTR"], L["TBTT"], L["TRTL"], L["TTTB"] },
						get = function() return self.CurrentDb.TimerOrientation end,
						set = function(info, value) self.CurrentDb.TimerOrientation = value; Yata:ResetTimers() end,
						disabled = function() return (InCombatLockdown() or self.CurrentDb.TimerEnabled == false or self.CurrentDb.TimerType == 2) end,
						order = 3,
					},
					timerscale = 	{
						name = L["TimerScale"],
						desc = L["TimerScaleDesc"],
						type = "range",
						get = function() return self.CurrentDb.TimerScale end,
						set = function(info, value)
							self.CurrentDb.TimerScale = value 
							self:SetTimerScale(self.CurrentDb.TimerScale)
							Yata:ResetTimers()
						end,
						min = 0.5,
						max = 2.5,
						step = 0.01,
						bigStep = 0.05,
						width = "double",
						disabled = function() return (InCombatLockdown() or self.CurrentDb.TimerEnabled == false or self.CurrentDb.TimerType == 2) end,
						order = 5,
					},				
					timerspacing = {
						name = L["TimerSpacing"],
						desc = L["TimerSpacingDesc"],
						type = "range",
						width = "normal",
						min = 0.0,
						max = 20,
						get = function() return self.CurrentDb.TimerSpacing end,
						set = function(info, value) self.CurrentDb.TimerSpacing = value; Yata:ResetTimers() end,
						step = 1,
						bigStep = 1,
						disabled = function() return (InCombatLockdown() or self.CurrentDb.TimerEnabled == false or self.CurrentDb.TimerType == 2) end,
						order = 6
					},	
					timerfontsize = {
						name = L["TimerFontSize"],
						desc = L["TimerFontSizeDesc"],
						type = "range",
						width = "normal",
						min = 4,
						max = 25,
						step = 1,
						bigStep = 1,
						get = function() return self.CurrentDb.TimerFontSize end,
						set = function(info, value) self.CurrentDb.TimerFontSize = value; Yata:ResetTimers() end,
						disabled = function() return (InCombatLockdown() or self.CurrentDb.TimerEnabled == false or self.CurrentDb.TimerType == 2) end,
						order = 7
					},	
					timerbarthickness = {
						name = L["TimerThickness"],
						desc = L["TimerThicknessDesc"],
						type = "range",
						width = "normal",
						min = 5,
						max = 100,
						step = 1,
						bigStep = 5,
						get = function() return self.CurrentDb.TimerThickness end,
						set = function(info, value) self.CurrentDb.TimerThickness = value; Yata:ResetTimers() end,
						disabled = function() return (InCombatLockdown() or self.CurrentDb.TimerEnabled == false or self.CurrentDb.TimerType == 2) end,
						order = 8
					},		
					timerbarlength = {
						name = L["TimerLength"],
						desc = L["TimerLengthDesc"],
						type = "range",
						width = "normal",
						min = 5,
						max = 500,
						step = 1,
						bigStep = 5,
						get = function() return self.CurrentDb.TimerLength end,
						set = function(info, value) self.CurrentDb.TimerLength = value; Yata:ResetTimers() end,
						disabled = function() return (InCombatLockdown() or self.CurrentDb.TimerEnabled == false or self.CurrentDb.TimerType == 2) end,
						order = 9
					},	
					timergrowup = {
						name = L["TimerGrowUp"],
						desc = L["TimerGrowUpDesc"],
						type = "toggle",
						get = function() return self.CurrentDb.TimerGrowUp end,
						set = function(info, value) self.CurrentDb.TimerGrowUp = value; Yata:ResetTimers() end,
						disabled = function() return (InCombatLockdown() or self.CurrentDb.TimerEnabled == false or self.CurrentDb.TimerType == 2) end,
						order = 10,
						width = "full",
					},	
					timerstrata = {
						name = L["TimerStrata"],
						desc = L["TimerStrataDesc"],
						type = "select",
						width = "double",
						values = stratum,
						get = function() for k,v in ipairs(stratum) do if v == self.CurrentDb.TimerStrata then return k end end end,
						set = function(info, value) Yata.CurrentDb.TimerStrata = stratum[value]; Yata:ResetTimers() end,
						disabled = function() return (InCombatLockdown() or self.CurrentDb.TimerEnabled == false or self.CurrentDb.TimerType == 2) end,
						order = 11,
					},				
				},
				order = 2,
			},
			totemmacro = {
				name = L["Macro"],
				desc = L["MacroDesc"],
				type = "group",
				args = {
					enabletimers = {
						name = L["EnableMacro"],
						desc = L["EnableMacroDesc"],
						type = "toggle",
						get = function() return self.CurrentDb.MacroEnabled end,
						set = function(info, value) self.CurrentDb.MacroEnabled = value end,
						disabled = function() return InCombatLockdown() end,
						order = 0,
						width = "full",
					},
					resetkey = {
						name = L["MacroReset"],
						desc = L["MacroResetDesc"],
						type = "select",
						values = resetkeys,
						get = function() for k,v in ipairs(resetkeys) do if v == self.CurrentDb.MacroResetKey then return k end end end,
						set = function(info, value) local oldKey = self.CurrentDb.MacroResetKey self.CurrentDb.MacroResetKey = resetkeys[value] Yata.Bar:EditMacro(oldKey, self.CurrentDb.MacroResetKey) end,
						disabled = function() return (InCombatLockdown() or self.CurrentDb.MacroEnabled == false) end,
						order = 1,
					},
				},
				order = 3,
			},
			totemsets = {
				name = L["TotemSets"],
				desc = L["TotemSetsDesc"],
				type = "group",
				args = {
					totemlayout = {
						name = L["TotemSetsButton"],
						desc = L["TotemSetsButtonDesc"],
						type = "execute",
						func = function() local editor = AceGUI:Create("Yata_TotemButtonLayoutEditor") end,
						disabled = function() return InCombatLockdown() end,
					},				},
				order = 4,
			},
			advanced = {
				name = L["Advanced"],
				desc = L["AdvancedDesc"],
				type = "group",
				args = {
					advancedHeader = { 
						name = L["AdvancedHeader"], 
						type="header", 
						order = 0,
					},
					enableadvanced = {
						name = L["EnableAdvanced"],
						desc = L["EnableAdvancedDesc"],
						type = "toggle",
						get = function() return self.CurrentDb.AdvancedEnabled end,
						set = function(info, value) Yata.CurrentDb.AdvancedEnabled = value; Yata.Bar:ConfigureBarDisplay(self.CurrentDb.ButtonGap, self.CurrentDb.BarOrientation, self.CurrentDb.VisibleButtons); Yata.Bar:UpdateCallIndicators(); end,
						disabled = function() return InCombatLockdown() end,
						order = 1,
						width = "full"
					},
					hidebar = {
						name = L["HideBar"],
						desc = L["HideBarDesc"],
						type = "toggle",
						get = function() return self.CurrentDb.AdvHideBar end,
						set = function(info, value) Yata.CurrentDb.AdvHideBar = value; if(value and self.CurrentDb.AdvancedEnabled) then Yata.Bar:Hide() else Yata.Bar:Show() end end,
						disabled = function() return (InCombatLockdown() or self.CurrentDb.AdvancedEnabled == false) end,
						order = 1,
						width = "full"
					},
					hideindicators = {
						name = L["HideIndicators"],
						desc = L["HideIndicatorsDesc"],
						type = "toggle",
						get = function() return self.CurrentDb.AdvHideIndicators end,
						set = function(info, value) Yata.CurrentDb.AdvHideIndicators = value; Yata.Bar:UpdateCallIndicators() end,
						disabled = function() return (InCombatLockdown() or self.CurrentDb.AdvancedEnabled == false) end,
						order = 1,
						width = "full"
					},
					showblizzbar = {
						name = L["ShowBlizzBar"],
						desc = L["ShowBlizzBarDesc"],
						type = "toggle",
						get = function() return self.CurrentDb.AdvShowBlizzBar end,
						set = function(info, value) Yata.CurrentDb.AdvShowBlizzBar = value; end,
						disabled = function() return (InCombatLockdown() or self.CurrentDb.AdvancedEnabled == false) end,
						order = 2,
						width = "full"
					},
				},
				order = 5,
			},
		},
	}
	if LBF then
		buttonskin = {
			name = L["Skin"],
			desc = L["SkinDesc"],
			type = "select",
			values = function() return LBF:ListSkins() end,
			get = function() return self.CurrentDb.ButtonSkin  end,
			set = function(info, value) Yata.Bar:SkinButtons(value) end,
			disabled = function() return InCombatLockdown() end,
			width = "double",
			order = 2,
		}
		options.args.totembar.args["buttonskin"] = buttonskin
	end
	if LSM then
		timerbarskin = {
			name = L["TimerTexture"],
			desc = L["TimerTextureDesc"],
			type = "select",
			values = function() return LSM:List("statusbar") end,
			get = function() for k,v in ipairs(LSM:List("statusbar")) do if v == self.CurrentDb.TimerBarSkin then return k end end end,
			set = function(info, value) self.CurrentDb.TimerBarSkin = LSM:List("statusbar")[value] self:LoadTimerConfig() end,
			disabled = function() return (InCombatLockdown() or self.CurrentDb.TimerEnabled == false or self.CurrentDb.TimerType == 2) end,
			order = 4,
		}
		timerbarfont = {
			name = L["TimerFont"],
			desc = L["TimerFontDesc"],
			type = "select",
			values = function() return LSM:List("font") end,
			get = function() for k,v in ipairs(LSM:List("font")) do if v == self.CurrentDb.TimerFont then return k end end end,
			set = function(info, value) self.CurrentDb.TimerFont = LSM:List("font")[value] self:LoadTimerConfig() end,
			disabled = function() return (InCombatLockdown() or self.CurrentDb.TimerEnabled == false or self.CurrentDb.TimerType == 2) end,
			order = 4,
		}
		options.args.totemtimers.args["timerbarskin"] = timerbarskin
		options.args.totemtimers.args["timerbarfont"] = timerbarfont
	end
	return options
end 

-- Adapted from Nevcairiel's Bartender4
if LDB then
	LibStub("LibDataBroker-1.1"):NewDataObject("Yata", {
		type = "launcher",
		text = "Yata",
		label = "Yata",
		OnClick = function(_, msg)
			if msg == "LeftButton" then
				if InCombatLockdown() ~= 1 then -- Only toggle the lock if we're out of combat
					if Yata.CurrentDb.Locked then
						Yata.Bar:Unlock()
					else
						Yata.Bar:Lock()
					end
				end
			elseif msg == "RightButton" then
				if LibStub("AceConfigDialog-3.0").OpenFrames["Yata"] then
					LibStub("AceConfigDialog-3.0"):Close("Yata")
				else
					LibStub("AceConfigDialog-3.0"):Open("Yata")
				end
			end
		end,
		icon = "Interface\\Icons\\Spell_Nature_EarthBindTotem",
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end
			tooltip:AddLine("Yata")
			tooltip:AddLine(L["BrokerLock"])
			tooltip:AddLine(L["BrokerOptions"])
		end,
	})
end

	StaticPopupDialogs["Yata_AddSet"] = {
		text = L["NewSetName"],
		button1 = ACCEPT,
		button2 = CANCEL,
		timeout = 0,
		hasEditBox = 1,
		whileDead = 1,
		hideOnEscape = 1,
		OnAccept = function(self,data) data:AddSet(_G[self:GetName().."EditBox"]:GetText()) end,
		OnCancel = function() end,
	}
	
	StaticPopupDialogs["Yata_DelSet"] = {
		text = L["DeleteSetName"],
		button1 = ACCEPT,
		button2 = CANCEL,
		timeout = 0,
		hasEditBox = 1,
		whileDead = 1,
		hideOnEscape = 1,
		OnAccept = function(self,data) data:DelSet(_G[self:GetName().."EditBox"]:GetText()) end,
		OnCancel = function() end,
	}