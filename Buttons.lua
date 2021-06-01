if not (Yatabar) then return; end;
local L = LibStub("AceLocale-3.0"):GetLocale(Yatabar.name, true)

--local LAB = LibStub("LibActionButton-1.0")
--MSQ = LibStub("Masque", true)
--myGroup = {}
-- if MSQ then
-- 	myGroup = MSQ:Group(Yatabar.name,nil, true)
-- end

function Yatabar:CreatePopupButton(main,index, spellId, element, spellname)
	--print("CreatePopups")
	--if index == 0 then
	--	return
	--end
	
	--print("Spellid", spellname, spellId)
	if Yatabar.config.debugOn then
		Yatabar:AddDebugText("CreatePopupButton: "..element.."::"..spellname) 
	end

	local name = "popupButton"..element..spellname:gsub("%s+", "")
	if main[name] == nil then
		main[name] = CreateFrame("CheckButton", name, main, "SecureHandlerStateTemplate, SecureHandlerEnterLeaveTemplate, SecureActionButtonTemplate,ActionButtonTemplate") --LAB:CreateButton(name, name , main)
	main[name].name = name
	end
	--print(name..spellId)
	main[name]:ClearAllPoints()
	main[name].spellId = spellId
	main[name].index = index
	main[name].element = element
	main[name]:SetPoint("BOTTOMLEFT", main,"BOTTOMLEFT", 0,(index - 1) * Yatabar.buttonSize)

	main[name]:SetAttribute('index', index)
	main[name]:SetAttribute("type1", "spell");
	_, _, icon = GetSpellInfo(spellname)
	main[name]:SetAttribute("spell", spellname);
	main[name]:SetAttribute("spellId", spellId);

	main[name]:SetScript("OnEnter", function() self:ShowTooltip(main[name]); end);
	main[name]:SetScript("OnLeave", function() self:HideTooltip(main[name]); end);
	--main[name]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");
	main[name]:RegisterEvent("UNIT_POWER_UPDATE")
	main[name]:RegisterForClicks("AnyUp")
	main[name]:SetScript("OnEvent", function(frame,event,...) self:OnButtonEvent(frame, event, main[name], ...); end);
	--main[name]:SetScript("OnEvent", Yatabar.OnButtonEvent);
	main[name]:SetScript("PostClick", Yatabar.ButtonClicked)
	main[name]:Show()
	main[name].icon:SetTexture(icon)
	main[name].icon:Show()
	--_G[name.."Icon"]:SetTexture(icon)
	--main[name].normalTexture = _G[name .. "NormalTexture"];
	--main[name].normalTexture:SetAllPoints(main[name])
	--main[name].normalTexture:SetVertexColor(1, 1, 1, 0.5);
	main[name]:SetNormalTexture("")
	
	
	--main[name].cooldown:SetEdgeTexture("Interface\\Cooldown\\edge");
	-- main[name].cooldown:SetSwipeColor(0, 0, 0);
	-- main[name].cooldown:SetHideCountdownNumbers(false);
	-- main[name].cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL;
	--main[name].cooldown:Show()
	
	
	--print(main["popupButton"..element..spellname]:GetAction("spell1"))
	
	if MSQ then
		if yatabarGroup then
			yatabarGroup:AddButton(main[name])
		end
	end
	
	SecureHandlerWrapScript(main[name],"OnLeave",main,[[return true, ""]], [[
		inHeader =  control:IsUnderMouse(true)
		if not inHeader then
			control:Run(close);
		end	    
	]])

	SecureHandlerWrapScript(main[name],"OnEnter",main, [[
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

function Yatabar:ShowTooltip(button)	
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		GameTooltip:SetSpellByID(button:GetAttribute("spellId"))
		--print(button:GetAttribute("spellId"))
end

function Yatabar:HideTooltip(button)
	--if GameTooltip:IsOwned(self.button) then
		GameTooltip:Hide();
	--end
end

function Yatabar:OnButtonEvent(self, event, button,...)
	--print("OnEvent", event, self)
	if ( event == "UNIT_SPELLCAST_SUCCEEDED" ) then
		--print(button:GetAttribute("spell"))
		--button.NormalTexture:Hide()
		
	end
	if(event == "UNIT_POWER_UPDATE") then
		usable, noMana = IsUsableSpell(button.spellId)
		if (not usable) then
			if (noMana) then
				button.icon:SetVertexColor(0.5, 0.5, 1.0);
			end
		else
			button.icon:SetVertexColor(1.0, 1.0, 1.0);
		end
	end
	
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

function Yatabar:ButtonClicked(arg1)
	if arg1 == "RightButton"  then 
		if InCombatLockdown() then
			print("Yatabar: ", L["function not available during combat"])
			self:SetChecked(false)
			return
		end
		if self.index ~= 1 then
			--print(arg1, self.element, self.index)
			local index = self.index
			local spellToSwitch = Yatabar.orderTotemsInElement[self.element][1]
			
			Yatabar.orderTotemsInElement[self.element][1] = Yatabar.orderTotemsInElement[self.element][index] 
			Yatabar.orderTotemsInElement[self.element][index] = spellToSwitch
		
		-- Set keybinding if first totem changed and create new macro
			local key = Yatabar.ElementBinding[self.element]
			Yatabar:SetKeyBinding(self.element, key) 
			Yatabar:EditMacro(true, nil,nil)
		end
		self:SetChecked(false)

		--Set position text in Config Dialog
		-- for k,v in pairs (tbl.options.args.totems.args[element].args) do
		-- 	if v.name == tbl.option.name then
		-- 		v.args.text.name = L["Position "]..newPosition
		-- 	elseif v.name == spellnameToSwitch then
		-- 		v.args.text.name = L["Position "]..currentPosition
		-- 	end
		-- end

		Yatabar:SetLayout()
		Yatabar:HidePopups()
	end
end