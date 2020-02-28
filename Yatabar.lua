Yatabar = LibStub("AceAddon-3.0"):NewAddon("Yatabar", "AceConsole-3.0")

local name = "Yatabar"
local _G = getfenv(0)
local L = LibStub("AceLocale-3.0"):GetLocale(name)

--LDB
local ldb = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(name, {
    type = "launcher",
    icon = "Interface\\Icons\\INV_Weapon_ShortBlade_17",
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
		--mTip:AddLine("|cFFff4040"..L["Right Click|r to lock/unlock bars"], 1, 1, 1)
	end,
})

local defaults = 
{
	
}