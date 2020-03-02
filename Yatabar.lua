-- if select(2, UnitClass('player')) ~= "SHAMAN" then
-- 	return
-- end

Yatabar = LibStub("AceAddon-3.0"):NewAddon("Yatabar", "AceConsole-3.0")
local LAB = LibStub("LibActionButton-1.0")
Yatabar.totemCount = 4  --nur zum Testen, sonst 0 und dann ermitteln wie viele Totems vorhanden
Yatabar.buttonSize = 36
Yatabar.name = "Yatabar"
local _G = getfenv(0)
--local L = LibStub("AceLocale-3.0"):GetLocale(name)

--LDB
local ldb = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(Yatabar.name, {
    type = "launcher",
    icon = "Interface\\Icons\\inv_banner_01",
    OnClick = function(self, button)
		if (button == "RightButton") then
			--for idx, bar in pairs(Klappa2.bars) do
			--	bar:ToggleLock()
			--end
			print("Rechtsklick:noch keine Funktion")
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
	self:CreateBar()
	self:CreateMainButtons()
	--RegisterStateDriver(Yatabar.frame, "page", "[mod:alt]2;1")
	
	-- Yatabar.frame:SetAttribute("_onstate-page", [[
	-- self:SetAttribute("state", newstate)
	-- control:ChildUpdate("state", newstate)
	-- print(newstate)
	-- ]])
	--Yatabar.frame:Show()
	--Yatabar.frame:SetAttribute("statehidden", nil)
	print("Enabled")
end

function Yatabar:CreateBar()
	print("CreateBar") 
	Yatabar.bar = CreateFrame("Frame", "YatabarBar", UIParent, "SecureHandlerStateTemplate")
	Yatabar.bar:SetPoint("CENTER")

	Yatabar.bar:SetWidth(36);
	Yatabar.bar:SetHeight(36);
	--Um die Bar zu sehen:
	Yatabar.bar:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true,
		tileSize = 1,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 0,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	Yatabar.bar:SetBackdropColor(1, 1, 1, 1)
	Yatabar.bar:SetBackdropBorderColor(0.5, 0.5, 0, 0)
	----
	Yatabar.bar.texture = Yatabar.bar:CreateTexture();
	Yatabar.bar.texture:SetTexture(0,0,0.5,0);
	Yatabar.bar.texture:SetAllPoints(Yatabar.bar);
	Yatabar.bar:Show()
end

function Yatabar:CreateMainButtons()
	print("CreateButtons") 
	
	 for i = 1,Yatabar.totemCount do
		print("Mainbutton:"..i)
		local name = "YatabarButton"..i
		Yatabar.bar["button"..i] = LAB:CreateButton(i, name , Yatabar.bar)
		Yatabar.bar["button"..i]:SetPoint("TOPLEFT", Yatabar.bar,"TOPLEFT", (i-1) * Yatabar.buttonSize,0)
		--Yatabar.bar["button"..i]:SetAttribute('type', 'action')
		--Yatabar.bar["button"..i]:SetAttribute('action', i)

		Yatabar.bar["button"..i]:SetAttribute('state', 1)
		Yatabar.bar["button"..i]:SetState(1, "action", i)

		--Yatabar.bar["button"..i]:SetState(2, "state", i)
		--Yatabar.bar["button"..i]:SetAttribute("statehidden", true)
		self:CreatePopupButtons(Yatabar.bar["button"..i])
	 end 
end

function Yatabar:CreatePopupButtons(main)
	local id = main.id + self.totemCount
	print("mainID:"..main.id)
	print("Popupid:"..id)
	local name = "YatabarButton"..id
	main["popupButton"..id] = LAB:CreateButton(id, name , Yatabar.bar)
	print(id - 1 - self.totemCount)
	main["popupButton"..id]:SetPoint("BOTTOMLEFT", main,"TOPLEFT", 0,0) --(id - 1 - self.totemCount) * Yatabar.buttonSize
	main["popupButton"..id]:SetAttribute('state', 1)
	main["popupButton"..id]:SetState(1, "action", id)
end