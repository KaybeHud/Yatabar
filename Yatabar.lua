-- if select(2, UnitClass('player')) ~= "SHAMAN" then
-- 	return
-- end

Yatabar = LibStub("AceAddon-3.0"):NewAddon("Yatabar", "AceConsole-3.0")

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
	-- Create a Header to drive this
	Yatabar.frame = CreateFrame("Frame", "LABTestHeader", UIParent, "SecureHandlerStateTemplate")
RegisterStateDriver(Yatabar.frame, "page", "[mod:alt]2;1")
Yatabar.frame:SetAttribute("_onstate-page", [[
    self:SetAttribute("state", newstate)
    control:ChildUpdate("state", newstate)
]])

-- Create a button on the header
Yatabar.button = LibStub("LibActionButton-1.0"):CreateButton(2, "LABTest1", Yatabar.frame)
Yatabar.button:SetPoint("CENTER", UIParent,"CENTER",230,530)

	Yatabar.button:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true,
		tileSize = 1,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 0,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	Yatabar.button:SetBackdropColor(1, 1, 0, 1)
	Yatabar.button:SetBackdropBorderColor(0.5, 0.5, 0, 0)
	local texture = GetActionTexture(Yatabar.button.id);
print(Yatabar.button.id)

	if ( texture ) then
		Yatabar.button.icon:SetTexture(texture);
		Yatabar.button.icon:Show();
	end
	
	Yatabar.button:SetMovable(true)
	Yatabar.button:SetClampedToScreen(true)
Yatabar.button:SetState(1, "action", 1)
Yatabar.button:SetState(2, "action", 2)
print("Enabled")
print(Yatabar.button:GetHeight())
Yatabar.button:Show()
end