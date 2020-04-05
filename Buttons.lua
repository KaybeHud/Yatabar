if not (Yatabar) then return; end;

--local LAB = LibStub("LibActionButton-1.0")
MSQ = LibStub("Masque", true)
myGroup = {}
if MSQ then
	myGroup = MSQ:Group(Yatabar.name,nil, true)
end

function Yatabar:CreatePopupButton(main,index, spellId, element, spellname)
	--print("CreatePopups")
	--if index == 0 then
	--	return
	--end
	
	--print("Spellid", spellname, spellId)
	local name = "popupButton"..element..spellname
	if main["popupButton"..element..spellname] == nil then
		main["popupButton"..element..spellname] = CreateFrame("CheckButton", name, main, "SecureHandlerStateTemplate, SecureHandlerEnterLeaveTemplate, SecureActionButtonTemplate,ActionButtonTemplate") --LAB:CreateButton(name, name , main)
	main["popupButton"..element..spellname].name = name
	end
	main["popupButton"..element..spellname]:ClearAllPoints()
	main["popupButton"..element..spellname].spellId = spellId
	main["popupButton"..element..spellname].index = index
	main["popupButton"..element..spellname].element = element
	main["popupButton"..element..spellname]:SetPoint("BOTTOMLEFT", main,"BOTTOMLEFT", 0,(index - 1) * Yatabar.buttonSize)

	main["popupButton"..element..spellname]:SetAttribute('index', index)
	main["popupButton"..element..spellname]:SetAttribute("type1", "spell");
	spname, _, icon = GetSpellInfo(spellId)
	main["popupButton"..element..spellname]:SetAttribute("spell", spname);
	main["popupButton"..element..spellname]:SetAttribute("spellId", spellId);

	main["popupButton"..element..spellname]:SetScript("OnEnter", function() self:ShowTooltip(main["popupButton"..element..spellname]); end);
	main["popupButton"..element..spellname]:SetScript("OnLeave", function() self:HideTooltip(main["popupButton"..element..spellname]); end);
	
	_G[name.."Icon"]:SetTexture(icon)
	main["popupButton"..element..spellname].cooldown = _G[name.."Cooldown"];
	
	main["popupButton"..element..spellname].cooldown:SetEdgeTexture("Interface\\Cooldown\\edge");
	main["popupButton"..element..spellname].cooldown:SetSwipeColor(0, 0, 0);
	main["popupButton"..element..spellname].cooldown:SetHideCountdownNumbers(false);
	main["popupButton"..element..spellname].cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL;
	main["popupButton"..element..spellname].cooldown:Show()
	
	
	--print(main["popupButton"..element..spellname]:GetAction("spell1"))
	
	if MSQ then
		if myGroup then
			myGroup:AddButton(main["popupButton"..element..spellname])		
		end
	end
	
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

function Yatabar:ShowTooltip(button)
	--if(Klappa2.config.bars[self.barid].tooltip) then
		--GameTooltip:SetOwner(self.button);
		GameTooltip:SetSpellByID(button:GetAttribute("spellId"))
		--GameTooltip:SetAction(self.button.id);
	--end
end

function Yatabar:HideTooltip(button)
	--if GameTooltip:IsOwned(self.button) then
		GameTooltip:Hide();
	--end
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