-- if select(2, UnitClass('player')) ~= "SHAMAN" then
-- 	return
-- end

Yatabar = LibStub("AceAddon-3.0"):NewAddon("Yatabar", "AceConsole-3.0")
local LAB = LibStub("LibActionButton-1.0")
Yatabar.totemCount = 2  --nur zum Testen, sonst 0 und dann ermitteln wie viele Totems vorhanden
Yatabar.buttonSize = 36
local name = "Yatabar"
local _G = getfenv(0)
--local L = LibStub("AceLocale-3.0"):GetLocale(name)

--LDB
local ldb = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(name, {
    type = "launcher",
    icon = "Interface\\Icons\\inv_banner_01",
    OnClick = function(self, button)
		if (button == "RightButton") then
			--for idx, bar in pairs(Klappa2.bars) do
			--	bar:ToggleLock()
			--end
		else
			LibStub("AceConfigDialog-3.0"):Open(name)
		end
	end,
	OnTooltipShow = function(Tip)
		if not Tip or not Tip.AddLine then
			return
		end
		Tip:AddLine(name)
		--Tip:AddLine("|cFFff4040"..L["Left Click|r to open configuration"], 1, 1, 1)
		--mTip:AddLine("|cFFff4040"..L["Right Click|r to lock/unlock bar"], 1, 1, 1)
	end,
})

local defaults = 
{
	
}

function Yatabar:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("YatabarDB", defaults)
end

function Yatabar:OnEnable()
	Yatabar:CreateBar()
	Yatabar:CreateButtons()
	
	
	--RegisterStateDriver(Yatabar.frame, "page", "[mod:alt]2;1")
	
	-- Yatabar.frame:SetAttribute("_onstate-page", [[
	-- self:SetAttribute("state", newstate)
	-- control:ChildUpdate("state", newstate)
	-- print(newstate)
	-- ]])
	--Yatabar.frame:Show()
	--Yatabar.frame:SetAttribute("statehidden", nil)

-- Create a button on the header


	-- Yatabar.button:SetBackdrop({
	-- 	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	-- 	tile = true,
	-- 	tileSize = 1,
	-- 	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	-- 	edgeSize = 0,
	-- 	insets = {left = 0, right = 0, top = 0, bottom = 0}
	-- })
	-- Yatabar.button:SetBackdropColor(1, 1, 0, 1)
	-- Yatabar.button:SetBackdropBorderColor(0.5, 0.5, 0, 0)
	-- local texture = GetActionTexture(Yatabar.button.id);

	-- print(Yatabar.button.id)

	-- if ( texture ) then
	-- 	Yatabar.button.icon:SetTexture(texture);
	-- 	--Yatabar.button.texture:SetAllPoints(Yatabar.frame)
	-- 	Yatabar.button.icon:Show();
	-- end
	
	--Yatabar.button:SetMovable(true)
	--Yatabar.button:SetClampedToScreen(true)
	--Yatabar.button:SetState(1, "action", 1)
	--Yatabar.button:SetState(2, "action", 2)

	print("Enabled")
--print(Yatabar.button:GetHeight())
--Yatabar.button:Show()
--Yatabar.button:SetAttribute("statehidden", nil)
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

	-- RegisterStateDriver(Yatabar.bar, "page", "[mod:alt]2;1")
	
	-- Yatabar.bar:SetAttribute("_onstate-page", [[
	-- 	self:SetAttribute("state", newstate)
	-- 	control:ChildUpdate("state", newstate)
	-- 	print(newstate)
	-- 	]])

end

function Yatabar:CreateButtons()
	print("CreateButtons") 
	
	 for i = 1,Yatabar.totemCount do
		print(i)
		name = "YatabarButton"..i
		Yatabar.bar["button"..i] = LAB:CreateButton(i, name , Yatabar.bar)
		--Yatabar.bar["button"..i]:ClearAllPoints()
		Yatabar.bar["button"..i]:SetPoint("TOPLEFT", Yatabar.bar,"TOPLEFT", (i-1) * Yatabar.buttonSize,0)
		Yatabar.bar["button"..i]:SetAttribute('type', 'action')
		Yatabar.bar["button"..i]:SetAttribute('action', i)
		Yatabar.bar["button"..i]:SetState(1, "action", i)
		Yatabar.bar["button"..i].icon = _G[name .. "Icon"];
		Yatabar.bar["button"..i].icon:SetTexCoord(0.06, 0.94, 0.06, 0.94);

		Yatabar.bar["button"..i].normalTexture = _G[name .. "NormalTexture"];
		Yatabar.bar["button"..i].normalTexture:SetVertexColor(1, 1, 1, 0.5);
		--Yatabar.bar["button"..i]:SetState(2, "state", i)
		--Yatabar.bar["button"..i]:SetAttribute("statehidden", nil)
		--Yatabar.bar["button"..i]:UpdateAction()
		--Yatabar.bar["button"..i]:ApplyStyle()
		
		Yatabar.bar["button"..i]:Show()
	 end 
end