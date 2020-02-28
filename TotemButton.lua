if select(2, UnitClass('player')) ~= "SHAMAN" then
	return
end

local _G = _G
local LibKeyBound = LibStub("LibKeyBound-1.0")
local AceEvent = LibStub("AceEvent-3.0")
local Button = CreateFrame("Button")
local Button_MT = {__index = Button}

Yata.Button = {}
Yata.Button.prototype = Button  
Yata.Button.db = Yata.db

function Yata.Button:CreateBase(id, parent)
	local name = "YataTotemButton" .. id
	name = gsub(name, " ", "_")
	local button = _G[name] or setmetatable(CreateFrame("Button", name, parent, "SecureHandlerEnterLeaveTemplate, SecureHandlerAttributeTemplate, SecureActionButtonTemplate"), Button_MT)
	button.Id = id
	button.Parent = parent
	button.Name = name
	button:SetWidth(36)
	button:SetHeight(36)	
	button:SetFrameStrata("MEDIUM")
	button:RegisterForClicks("LeftButtonUp","RightButtonUp")		
	
	button:HookScript("OnEnter", function() button:OnEnter(button) end)
	button:HookScript("OnLeave", function() button:OnLeave() end)
	
	button.Icon = button.Icon or button:CreateTexture(name.."Icon")   
	button.Icon:SetAllPoints()
	
	button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	button:GetHighlightTexture():SetBlendMode("ADD")
	
	button.Cooldown = button.Cooldown or CreateFrame("Cooldown", name.."Cooldown",button,"CooldownFrameTemplate")
	button.Cooldown:SetWidth(36)
	button.Cooldown:SetHeight(36)
	button.Cooldown:SetPoint("CENTER",0,-1)
	
	button.HotKey = button.HotKey or button:CreateFontString(name.."HotKey", "OVERLAY", "NumberFontNormalSmallGray")
	button.HotKey:SetWidth(36)
	button.HotKey:SetHeight(10)
	button.HotKey:SetJustifyH("RIGHT")
	button.HotKey:SetPoint("TOPLEFT",-2,-2)	
	
	button:SetNormalTexture("")	
	button.NormalTexture = button:GetNormalTexture()
	button.NormalTexture:SetWidth(66)
	button.NormalTexture:SetHeight(66)
	button.NormalTexture:ClearAllPoints()
	button.NormalTexture:SetPoint("CENTER", 0, -1)
	button.NormalTexture:Hide()

	button.Duration = button.Duration or button:CreateFontString(name.."Duration", "BACKGROUND", "GameFontNormalSmall")
	button.Duration:SetPoint("TOP",parent,"BOTTOM",0,0)	
		
	button:RegisterEvents()
	button:UpdateHotkey()	
	return button
end


function Yata.Button:Create(id, parent, totem)
	local button = Yata.Button:CreateBase(id,parent)
	
	button.Icon:SetTexture(totem.Texture)
	
	button.Totem = totem
	
	if(totem.ActionId) then
		button.CallFrame = button.CallFrame or CreateFrame("Frame", button.Name.."CallFrame", button)
		
		local callY, frameY
		
		if(Yata.CurrentDb.ButtonSkin == "Blizzard") then
			button.CallFrame:SetHeight(7)
			callY = 5
			frameY = 3
		else
			button.CallFrame:SetHeight(5)
			callY=5
			frameY= 4
		end
		
		button.CallFrame:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, frameY)
		button.CallFrame:SetWidth(32)
		
		if not (button.CallFrame.texture) then
			local t = button.CallFrame:CreateTexture(nil,"BACKGROUND")
			t:SetTexture(0,0,0, 0.8)
			t:SetAllPoints(button.CallFrame)
			t:SetBlendMode("BLEND")
			button.CallFrame.texture = t
		end
		button.CallFrame:Show()
		
		button.Call1 = button.Call1 or CreateFrame("Frame", button.Name.."Call1", button)
		button.Call1:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 5, callY)
		button.Call1:SetWidth(6)
		button.Call1:SetHeight(3)
		if not (button.Call1.texture) then
			local t = button.Call1:CreateTexture(nil,"OVERLAY")
			t:SetTexture(0.96,0.25,0.37,0.8)
			t:SetAllPoints(button.Call1)
			t:SetBlendMode("BLEND")
			button.Call1.texture = t
		end
		
		button.Call1:Show()

		button.Call2 = button.Call2 or CreateFrame("Frame", button.Name.."Call2", button)
		button.Call2:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 15, callY)
		button.Call2:SetWidth(6)
		button.Call2:SetHeight(3)
		if not (button.Call2.texture) then
			local t = button.Call2:CreateTexture(nil,"OVERLAY")
			t:SetTexture(0.2,0.79,0.89,1)
			t:SetAllPoints(button.Call2)
			t:SetBlendMode("BLEND")
			button.Call2.texture = t
		end
		
		button.Call2:Show()

		button.Call3 = button.Call3 or CreateFrame("Frame", button.Name.."Call3", button)
		button.Call3:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 25, callY)
		button.Call3:SetWidth(6)
		button.Call3:SetHeight(3)
		if not (button.Call3.texture) then
			local t = button.Call3:CreateTexture(nil,"OVERLAY")
			t:SetTexture(0.57,0.29,1,1)
			t:SetAllPoints(button.Call3)
			t:SetBlendMode("BLEND")
			button.Call3.texture = t
		end
		
		button.Call3:Show()
	end
	
	button:SetCallIndicators()
	
	button:SetParent(parent)

	button:SetFrameRef("header", parent)
	button:SetFrameRef("bar", parent:GetParent())
	button:Execute([[header = self:GetFrameRef("header")]])	
	button:Execute([[bar = self:GetFrameRef("bar")]])	
	
	button:SetAttribute("*type1", "spell")
	button:SetAttribute("*spell1", totem.Name)

	button:SetAttribute("globalid", totem.GlobalId)
	
	if totem.GlobalId and totem.ActionId and totem.Slot then
		button:SetAttribute("shift-type2", "spell")
		button:SetAttribute("shift-spell2", GetSpellInfo(36936)) -- Totemic Call

		local setcallbutton = Yata.CurrentDb.ButtonSetCallKey
		local prefix = ""
		if(setcallbutton ~= "none") then
			prefix = setcallbutton.."-"
		end

		button:SetAttribute(prefix.."type1", "multispell")
		button:SetAttribute("action", button.Totem.ActionId)
		button:SetAttribute(prefix.."spell1", totem.GlobalId)

		button:SetAttribute("type2", "macro")
		button:SetAttribute("macrotext2", "/script DestroyTotem("..totem.Slot..")")
		
		button:SetAttribute("element", totem.SpellGroup)
		button:SetAttribute("actionid", totem.ActionId)
	end
	
	if totem.SpellGroup == SPELL_GROUP_CALL then
		button:SetAttribute("*type1", "spell")
		button:SetAttribute("*spell1", totem.Name)
		
		local manualswaptocallkey = Yata.CurrentDb.ManualSwapToCallKey
		local prefix = ""
		if(manualswaptocallkey ~= "none") then
			prefix = manualswaptocallkey.."-"
		end
		
		button:SetAttribute(prefix.."type2", "attribute")
		button:SetAttribute(prefix.."attribute-name2", "manualcall")
		button:SetAttribute(prefix.."attribute-value2", totem.CallActionBase)
		button:SetAttribute(prefix.."attribute-frame2", parent:GetParent())
		
		button:SetAttribute("type2", "spell")
		button:SetAttribute("spell2", GetSpellInfo(36936)) -- Totemic Call
				
		button:SetAttribute("iscall", true)
		button:SetAttribute("callindex", totem.CallIndex)
		button:SetAttribute("callaction", totem.CallActionBase)
	end
	
	if totem.SpellGroup == SPELL_GROUP_IMBUE then
		button:SetAttribute("*type*", "spell")
		button:SetAttribute("*spell*", totem.Name)
	
		button:SetAttribute("alt-type1", "cancelaura")
		button:SetAttribute("alt-type2", "cancelaura")
		
		button:SetAttribute("alt-spell1", ATTRIBUTE_NOOP)
		button:SetAttribute("alt-spell2", ATTRIBUTE_NOOP)
		
		button:SetAttribute("*target-slot1", GetInventorySlotInfo("MainHandSlot"))
		button:SetAttribute("*target-slot2", GetInventorySlotInfo("SecondaryHandSlot"))
	end
	
	button:SetAttribute( "_onenter", [[  
		header:SetAttribute("show", true)
	]] )
	
	button:SetAttribute( "_onleave", [[  
		inHandler = header:IsUnderMouse(true)
		
		if not inHandler then
			header:SetAttribute("show", false)
		end	    
	]] )
	
	button:SetAttribute( "_onattributechanged", [[
		if name == "newposition" then
			self:ClearAllPoints()
			self:SetAttribute("position", value)
			local orientation = header:GetAttribute("orientation")
			local proxybinding = header:GetAttribute("proxybinding")
			
			local anchor, xpos, ypos
			if orientation == 1 then
				anchor = "BOTTOM"
				xpos = 0
				ypos = value*(36 + header:GetAttribute("buttongap") or 0)
			elseif orientation == 2 then
				anchor = "TOP"		
				xpos = 0
				ypos = -value*(36 + header:GetAttribute("buttongap") or 0)
			elseif orientation == 3 then
				anchor = "LEFT"
				ypos = 0
				xpos = value*(36 + header:GetAttribute("buttongap") or 0)
			elseif orientation == 4 then
				anchor = "RIGHT"		
				ypos = 0
				xpos = -value*(36 + header:GetAttribute("buttongap") or 0)
			end
			
			if value == 0 and proxybinding then
				self:SetBindingClick(1,proxybinding,self)
			else
				self:ClearBindings()
			end
			
			self:SetPoint( anchor , header, anchor, xpos, ypos)
			if self:GetAttribute("position") < header:GetAttribute("visiblebuttons") and self:GetAttribute("hidden") == false then
				self:Show()
				self:SetScale(1)
			else
				self:Hide()
			end

			if self:GetAttribute("iscall") == true and self:GetAttribute("position") == 0 then			
				bar:SetAttribute("currentcallindex", self:GetAttribute("callindex") - 1)
				bar:SetAttribute("updateindicators", true)
			end
		end
	]] )
	
	button:Execute([=[checkModifier = [[
		if (key == "shift" and IsShiftKeyDown())
		or (key == "alt" and IsAltKeyDown())
		or (key == "ctrl" and IsControlKeyDown()) then
			return true
		else
			return false
		end
		]]
	]=] )
	
	button:Execute([=[swapButton = [[
		pos = self:GetAttribute("position")
		if pos > 0 then
			local buttonSize = header:GetAttribute("buttongap") + 36
			children = newtable(header:GetChildren())
			for i,b in ipairs(children) do			
				local oldpos = b:GetAttribute("position")
				local newpos = oldpos
				if oldpos < pos then
					newpos = oldpos + 1
				elseif oldpos == pos then
					newpos = 0
				end
				b:SetAttribute("newposition",newpos)
			end
		end
		header:SetAttribute("show",false)	
		]]]=])
		
	button:SetAttribute("hidden", false)
	
	button:HookScript("PostClick", function(self) button:PostClick() end)
	
	return button		
end

function Button:PostClick()
	if self.Totem.SpellGroup ~= SPELL_GROUP_IMBUE and self.Totem.SpellGroup ~= SPELL_GROUP_CALL then -- Only bother with totems
		Yata.Bar:EditMacro(true,nil,nil)
		
		if IsModifiedClick(Yata.CurrentDb.ButtonSetCallKey) then
			Yata.Bar:UpdateCallIndicators()
		end
	elseif self.Totem.SpellGroup == SPELL_GROUP_CALL then
		Yata.Bar:UpdateCallIndicators()
	end	
end

function Yata.Button:CreateTotemProxy(id,parent)
	local name = "YataTotemProxy" .. id
	local button = Yata.Button:CreateBase(id,parent)
	button.Totem = {}
	button.Totem.Name = name
	button:SetAttribute("isproxy", true)
	button.Title = button.Title or button:CreateFontString(name.."Title", "OVERLAY", "NumberFontNormal")
	button.Title:SetWidth(36)
	button.Title:SetHeight(10)
	button.Title:SetText(id)
	button.Title:SetPoint("CENTER",0,-10)	
		
	return button
end

function Button:SetOnClickScript(autobutton)		
		self:UnwrapScript(self,"OnClick")
		
		self:WrapScript(self,"OnClick",[[
			if button == "LeftButton" then
				key = bar:GetAttribute("swapkey")
				if control:Run(checkModifier,key) then
					control:Run(swapButton)
					return false
				 end
				return nil, true
			end
		]],
		[[
			if button == "LeftButton" then
				key = bar:GetAttribute("setcallkey")
				if control:Run(checkModifier,key) then
					bar:SetAttribute("updateindicators", true)
				else
					key = bar:GetAttribute("noswapkey")
					if not control:Run(checkModifier,key) and bar:GetAttribute("autoswap") == true then
						control:Run(swapButton)
					end
				end
								
				if self:GetAttribute("iscall") == true then
					local base = self:GetAttribute("callaction")	
					bar:SetAttribute("autocall", base)
				end
			end
		]] )
end

function Button:RegisterEvents()
	AceEvent.RegisterEvent(self,"UPDATE_BINDINGS")
	AceEvent.RegisterEvent(self,"SPELL_UPDATE_USABLE")
end

function Button:UPDATE_BINDINGS()
	self:UpdateHotkey()
end

function Button:SPELL_UPDATE_USABLE()
	if not self.Totem then return end
	local usable, nomana = IsUsableSpell(self.Totem.Name)
	if(usable) then
		self.Icon:SetVertexColor(1.0,1.0,1.0)
	elseif(nomana) then
		self.Icon:SetVertexColor(0.1, 0.3, 1.0)
	else
		self.Icon:SetVertexColor(0.4,0.4,0.4)
	end

	self:SetCallIndicators()
end

function Button:SetCallIndicators()
	if self.Totem.GlobalId and self.Totem.ActionId and self.Totem.Slot then -- Only bother with totems
		if self.Call1 then self.Call1:Hide() end
		if self.Call2 then self.Call2:Hide() end
		if self.Call3 then self.Call3:Hide() end
		if self.CallFrame then self.CallFrame:Hide() end
		
		if Yata.CurrentDb.AdvancedEnabled and Yata.CurrentDb.AdvHideIndicators then
			return
		end		
		
		if (Yata.Bar) then
			local currentIndex = Yata.Bar:GetAttribute("currentcallindex")
										
			local bases = { 133, 137, 141}
				
			for k, base in ipairs(bases) do
				for i = base, base + 3 do
					local _, globalID, _ = GetActionInfo(i)
					
					if globalID  == self.Totem.GlobalId and self.Call1 then
						if k == 1 then self.Call1:Show()
						elseif k == 2 then self.Call2:Show()
						elseif k == 3 then self.Call3:Show()
						end
						self.CallFrame:Show()
					end
				end
			end
			
			local setcallbutton = Yata.CurrentDb.ButtonSetCallKey
			local prefix = ""
			if(setcallbutton ~= "none") then
				prefix = setcallbutton.."-"
			end
		end
	end
end

function Button:OnEnter(self)
	if Yata.CurrentDb.ShowTooltip then
		self:SetTooltip()
	end	
	LibKeyBound:Set(self)
end

function Button:OnLeave()
	GameTooltip:Hide()
end

function Button:GetHotkey()
	local key1 = GetBindingKey(format("CLICK %s:LeftButton", self.Name))
	local displayKey = LibKeyBound:ToShortKey(key1)
	return displayKey
end

function Button:UpdateHotkey()
	local key = self:GetHotkey()
	local hotkey = self.HotKey
	if key and Yata.CurrentDb.ShowKeybinds == true then
		hotkey:SetText(key)
		hotkey:Show()
	else
		hotkey:Hide()
	end
end

function Button:GetActionName()
	return self.Totem.Name
end


function Button:SetTooltip()
	if  GetCVar("UberTooltips") == "1"  then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
		
	if Yata.CurrentDb.Tooltip == 2 then
		GameTooltip:SetText(self.Totem.Name, 1.0, 1.0, 1.0)
	elseif Yata.CurrentDb.Tooltip == 3 and self.Totem.GlobalId then
		GameTooltip:SetHyperlink(GetSpellLink( self.Totem.GlobalId))
	end
	
	if self.Totem.SpellGroup == "CallSpell" and Yata.CurrentDb.MultiTooltip == true then
		
		GameTooltip:AddLine(" ", 0,0,0,false)
		
		local set = Yata:GetTotemSet(name)
		if set ~= nil then 
			set = set.GroupOrder 
		end
		
		if set == nil then 
			set = SpellGroups
		end
		
		for i, key in ipairs (set) do
			if (ElementsMap[key] ~= nil) then
				self:AddTotemToTooltip(key, self.Totem.CallActionBase + ElementsMap[key] - 1)
			end
		end
				
		GameTooltip:Show()
	end
end

function Button:AddTotemToTooltip(element, actionId)

	local globalID, name	
	
	_, globalID, _ = GetActionInfo(actionId)
			
	if globalID ~= nil then
		name, _, _, _, _, _, _, _, _ = GetSpellInfo(globalID)
	end
				
	if name == nil then
		name = "None"
	end
	
	if element == "Earth" then
		GameTooltip:AddDoubleLine("Earth:", name, 1, 1, 1, 0, 1, 0, false)
	elseif element == "Fire" then
		GameTooltip:AddDoubleLine("Fire:", name, 1, 1, 1, 1, 0.3,0.3, false)
	elseif element == "Water" then
		GameTooltip:AddDoubleLine("Water:", name, 1, 1, 1,0, 1.0, 1.0, false)
	elseif element == "Air" then
		GameTooltip:AddDoubleLine("Air:", name, 1, 1, 1,0.3, 0.3,1.0, false)
	end

end