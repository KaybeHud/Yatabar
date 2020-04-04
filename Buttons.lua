if not (Yatabar) then return; end;

local LAB = LibStub("LibActionButton-1.0")

function Yatabar:CreatePopupButton(main,index, spellId, element, spellname)
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