-- if select(2, UnitClass('player')) ~= "SHAMAN" then
-- 	return
-- end

Yatabar = LibStub("AceAddon-3.0"):NewAddon("Yatabar", "AceConsole-3.0")
local LAB = LibStub("LibActionButton-1.0")
Yatabar.totemCount = 4  --nur zum Testen, sonst 0 und dann ermitteln wie viele Totems vorhanden
Yatabar.buttonSize = 36
Yatabar.name = "Yatabar"
Yatabar.frameBorder = 8
Yatabar.availableTotems = {}
Yatabar.countAvailableTotemspells = 0
Yatabar.isLocked = true
local _G = getfenv(0)
--local L = LibStub("AceLocale-3.0"):GetLocale(name)
local GetTotemInfo = LibStub("LibTotemInfo-1.0").GetTotemInfo

--LDB
local ldb = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(Yatabar.name, {
    type = "launcher",
    icon = "Interface\\Icons\\inv_banner_01",
    OnClick = function(self, button)
		if (button == "RightButton") then
			Yatabar.isLocked = !Yatabar.isLocked
			Yatabar:toggleLock(Yatabar.isLocked)
			--print("Rechtsklick:noch keine Funktion")

		--test GetTotemInfo test
	for i =1, 4 do 
		print(GetTotemInfo(i)) 
		print(GetTotemTimeLeft(i)) 
	end
		else
			print("Linksklick, noch keine Funktion")
			--LibStub("AceConfigDialog-3.0"):Open(name)
		end
	end,
	OnTooltipShow = function(Tip)
		if not Tip or not Tip.AddLine then
			return
		end
		Tip:AddLine(Yatabar.name)
		--Tip:AddLine("|cFFff4040"..L["Left Click|r to open configuration"], 1, 1, 1)
		--Tip:AddLine("|cFFff4040"..L["Right Click|r to lock/unlock bar"], 1, 1, 1)
	end,
})

local defaults = 
{
	
}

function Yatabar:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("YatabarDB", defaults)
end

function Yatabar:OnEnable()
	self:CreateBar(Yatabar.totemCount)
	self:GetTotemSpells()
	self:CreateTotemHeader(Yatabar.totemCount)
	--self:CreateMainButtons()

	--RegisterStateDriver(Yatabar.frame, "page", "[mod:alt]2;1")
	
	-- Yatabar.frame:SetAttribute("_onstate-page", [[
	-- self:SetAttribute("state", newstate)
	-- control:ChildUpdate("state", newstate)
	-- ]])
	--Yatabar.frame:Show()
	--Yatabar.frame:SetAttribute("statehidden", nil)

	self.testframe = CreateFrame("Frame", "TestHeader", Yatabar.bar, "SecureHandlerStateTemplate")
	self.testframe:SetPoint("TOPLEFT", Yatabar.bar,"TOPLEFT",0,-150)
	self.testframe:Show()
	--self:CreatePopupButtonsSpell(self.testframe)
	
	print("Enabled")
end

function Yatabar:CreateBar(count)
	print("CreateBar") 
	Yatabar.bar = CreateFrame("Frame", "YatabarBar", UIParent)
	Yatabar.bar:SetPoint("CENTER", -300,0)

	Yatabar.bar:SetWidth(self.buttonSize * count + (2*self.frameBorder));
	Yatabar.bar:SetHeight(self.buttonSize + (2*self.frameBorder));
	
	Yatabar.bar.overlay = CreateFrame("Frame", "YatabarBar", Yatabar.bar)
	Yatabar.bar.overlay:SetAllPoints()
	Yatabar.bar.overlay:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true,
		tileSize = 1,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 0,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})

	Yatabar.bar:SetMovable(true);

	Yatabar.bar.overlay:SetBackdropColor(1, 1, 1, 1)
	Yatabar.bar.overlay:SetBackdropBorderColor(0.5, 0.5, 0, 0)
	Yatabar.bar.overlay:Hide()
	
	Yatabar.bar:Show()
end

function Yatabar:CreateTotemHeader(count)
	--print("CreateTotemHeader")
	local frameBorder = Yatabar.frameBorder 
	local totemSpellCount = 2
	for i=1, count do
		print("crete header")
		Yatabar["TotemHeader"..i] = CreateFrame("Frame", "TotemHeader"..i, Yatabar.bar, "SecureHandlerStateTemplate")
		Yatabar["TotemHeader"..i]:SetPoint("TOPLEFT", Yatabar.bar,"TOPLEFT",(i-1) * Yatabar.buttonSize + frameBorder,-frameBorder)
		Yatabar["TotemHeader"..i]:SetSize(Yatabar.buttonSize, Yatabar.buttonSize* totemSpellCount)
		Yatabar["TotemHeader"..i]:Show()
		index = 1
		for idx = 1, Yatabar.countAvailableTotemspells do
				if Yatabar.availableTotems[idx]["ElementID"] == i then
					--self:CreatePopupButtons(Yatabar["TotemHeader"..i],totemSpellCount, count)
					self:CreatePopupButtonsSpell2(Yatabar["TotemHeader"..i], index, Yatabar.availableTotems[idx]["SpellId"])
					index = index + 1
				end	
		end

		Yatabar["TotemHeader"..i]:Execute ( [[show = [=[
			local popups = newtable(self:GetChildren())
			for i, button in ipairs(popups) do
				isDel = button:GetAttribute("deleted")
				if not (isDel) then
					button:Show()
				end
			end
		]=] ]])

		Yatabar["TotemHeader"..i]:Execute( [[close = [=[
		local popups = newtable(self:GetChildren())
			for i, button in ipairs(popups) do
				if not (i == 1) then
					button:Hide()
				end
			end
		]=] ]])
	end
end

-- [[function Yatabar:CreateMainButtons()
-- 	print("CreateButtons") 
	
-- 	 for i = 1,Yatabar.totemCount do
-- 		print("Mainbutton:"..i)
-- 		local name = "YatabarButton"..i
-- 		Yatabar.bar["button"..i] = LAB:CreateButton(i, name , Yatabar.bar)
-- 		Yatabar.bar["button"..i]:SetPoint("TOPLEFT", Yatabar.bar,"TOPLEFT", (i-1) * Yatabar.buttonSize,0)
-- 		--Yatabar.bar["button"..i]:SetAttribute('type', 'action')
-- 		--Yatabar.bar["button"..i]:SetAttribute('action', i)

-- 		Yatabar.bar["button"..i]:SetAttribute('state', 1)
-- 		Yatabar.bar["button"..i]:SetState(1, "action", i)

-- 		--Yatabar.bar["button"..i]:SetState(2, "state", i)
-- 		--Yatabar.bar["button"..i]:SetAttribute("statehidden", true)
-- 		self:CreatePopupButtons(Yatabar.bar["button"..i])
-- 	 end 
-- end]]

function Yatabar:CreatePopupButtons(main, spellCount, id)
	--local id = main.id + spellCount--self.totemCount
	--print("mainID:"..main.id)
	print("Popupid:"..id)
	local name = "YatabarButton"..id
	main["popupButton"..id] = LAB:CreateButton(id, name , main)
	print(id - spellCount) --self.totemCount)
	main["popupButton"..id]:SetPoint("BOTTOMLEFT", main,"TOPLEFT", 0,(id - spellCount - 1) * Yatabar.buttonSize) --(id - 1 - self.totemCount) * Yatabar.buttonSize
	main["popupButton"..id]:SetAttribute('state', 1)
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

function Yatabar:CreatePopupButtonsSpell2(main,index, spellId)
	--print("PopupSpellid:"..spellId)
	local name = "YatabarButton"..spellId
	main["popupButton"..spellId] = LAB:CreateButton(spellId, name , main)
	--print(index) --self.totemCount)
	main["popupButton"..spellId]:SetPoint("BOTTOMLEFT", main,"TOPLEFT", 0,(index - 1) * Yatabar.buttonSize) --(index - 1 - self.totemCount) * Yatabar.buttonSize
	main["popupButton"..spellId]:SetAttribute('state', "spell1")
	main["popupButton"..spellId]:SetState("spell1", "spell", spellId)
	SecureHandlerWrapScript(main["popupButton"..spellId],"OnLeave",main,[[return true, ""]], [[
		inHeader =  control:IsUnderMouse(true)
		if not inHeader then
			control:Run(close);
		end	    
	]])

	SecureHandlerWrapScript(main["popupButton"..spellId],"OnEnter",main, [[
		control:Run(show);
		]]);
end

function Yatabar:CreatePopupButtonsSpell(main)
	--local id = main.id + spellCount--self.totemCount
	--print("mainID:"..main.id)
	--print("Popupid:"..id)
	--local spellId = 15274
	local name = "YatabarTest"
	main[name] = LAB:CreateButton(100, name , main)
	--print(id - 1 - spellCount) --self.totemCount)
	main[name]:SetPoint("BOTTOMLEFT", main,"TOPLEFT", 0,0) 
	main[name]:SetAttribute('state', "spell1")
	
	spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo("Verblassen")
	main[name]:SetState("spell1", "spell", spellId)
	-- local GetTotemInfo = LibStub("LibTotemInfo-1.0").GetTotemInfo
	-- for i =1, 4 do 
	-- 	print(GetTotemInfo(i)) 
	-- 	print(GetTotemTimeLeft(i)) 
	-- end
	print(spellId)
end

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

function Yatabar:GetTotemSpells()
	countSpells = 1
	for idx, totem in pairs(YatabarConfig.allTotems) do
		spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(totem["RankOneSpellID"])
		--welche Totems sind dem Spieler bekannt:
		spellname, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellname)
		--print(spellname)
		if spellname ~= nil then
			Yatabar.availableTotems[countSpells] = {["SpellName"] = spellname, ["SpellId"] = spellId, ["ElementID"] = totem["ElementID"]}
			countSpells = countSpells +1
		end
	end
	Yatabar.countAvailableTotemspells = countSpells-1
	print("Anzahl Spells", Yatabar.countAvailableTotemspells)
end

function Yatabar:toggleLock(lock)
	if InCombatLockdown() then
		print("function not available during combat")
		return
	end
	if not lock then
		Yatabar.bar.overlay:SetScript("OnDragStart", function() self:StartDrag(); end);
		Yatabar.bar.overlay:SetScript("OnDragStop", function() self:StopDrag(); end);
		Yatabar.bar.overlay:Show();
	else
		Yatabar.bar.overlay:SetScript("OnDragStart", nil);
		Yatabar.bar.overlay:SetScript("OnDragStop", nil);
		Yatabar.bar.overlay:Hide();
	end
end