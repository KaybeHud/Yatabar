if select(2, UnitClass('player')) ~= "SHAMAN" then
	return
end

Yata = LibStub("AceAddon-3.0"):NewAddon("Yata", "AceConsole-3.0", "AceEvent-3.0", "LibBars-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Yata")
local LibKeyBound = LibStub("LibKeyBound-1.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

TOTEM_SET_PRIMARY_DEFAULT = "Default"
TOTEM_SET_SECONDARY_DEFAULT = "Secondary Default"
SPELL_GROUP_CALL = "CallSpell"
SPELL_GROUP_IMBUE = "Imbue"

SpellGroups = {"Earth", "Air", "Water", "Fire", SPELL_GROUP_CALL, SPELL_GROUP_IMBUE}
ElementsMap = {["Fire"] = 1, ["Earth"] = 2, ["Water"] = 3, ["Air"] = 4}

local defaults = {
	profile = {
		AdvancedEnabled = false,
		AdvHideBar = false,
		AdvHideIndicators = false,
		AdvShowBlizzBar = false,
		Alpha = 1,
		ShowKeybinds = true,
		BarScale = 1.0,
		PopOutScale = 0.85,
		BarOrientation = 1,		
		ButtonGap = 0,
		VisibleButtons = 1,
		AutoButtonSwap = true,
		Locked = true,
		ShowTooltip = true,
		Tooltip = 3,
		TimerEnabled = true,
		TimerType = 1,
		TimerScale = 1.0,
		TimerOrientation = 1,
		TimerThickness = 10,
		TimerLength = 100,
		TimerFontSize = 8,
		TimerFont = "Friz Quadrata TT",
		TimerSpacing = 0,
		TimerGrowUp = true,
		TimerStrata = "LOW",
		ButtonSkin = "Blizzard",
		TimerBarSkin = "Blizzard",
		MacroResetKey = "none",
		ButtonSetCallKey = "alt",
		ButtonSwapKey = "ctrl",
		ButtonNoSwapKey = "shift",
		ManualSwapToCallKey = "alt",
		AutoSwapToCall = false,
		MultiTooltip = true,
		CurrentTotemSet = TOTEM_SET_PRIMARY_DEFAULT,
		InitialSpec = nil,
		MacroEnabled = true,
		BarPosition = { 
			x = 110,
			y = 115
		},
		alternativespec = {
			AdvancedEnabled = false,
			AdvHideBar = false,
			AdvHideIndicators = false,
			AdvShowBlizzBar = false,
			Alpha = 1,
			ShowKeybinds = true,
			BarScale = 1.0,
			PopOutScale = 0.85,
			BarOrientation = 1,		
			ButtonGap = 0,
			VisibleButtons = 1,
			AutoButtonSwap = true,
			Locked = true,
			ShowTooltip = true,
			MacroEnabled = true,
			Tooltip = 3,
			TimerEnabled = true,
			TimerType = 1,
			TimerScale = 1.0,		
			TimerOrientation = 1,
			TimerThickness = 10,
			TimerLength = 100,
			TimerFontSize = 8,
			TimerFont = "Friz Quadrata TT",
			TimerSpacing = 0,
			TimerGrowUp = true,
			TimerStrata = "LOW",
			ButtonSkin = "Blizzard",
			MultiTooltip = true,
			TimerBarSkin = "Blizzard",
			MacroResetKey = "none",
			ButtonSetCallKey = "alt",
			ButtonSwapKey = "ctrl",
			ButtonNoSwapKey = "shift",
			ManualSwapToCallKey = "alt",
			AutoSwapToCall = false,
			CurrentTotemSet = TOTEM_SET_PRIMARY_DEFAULT,
			BarPosition = { 
				x = 110,
				y = 115
			},
			FirstUse = true
		}
	},
};

function Yata:OnInitialize()
    -- Called when the addon is loaded
	self.db = LibStub("AceDB-3.0"):New("YataDB", defaults)
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Yata", self:PopulateOptions(), {"yatacmd"})
	
	self:RegisterChatCommand("yata", function() AceConfigDialog:Open("Yata") end)	
	self.optionsFrame = AceConfigDialog:AddToBlizOptions("Yata", nil, nil)
	
	self:Print("Loaded")
	
	LibKeyBound.RegisterCallback(self, "LIBKEYBOUND_ENABLED")
	LibKeyBound.RegisterCallback(self, "LIBKEYBOUND_DISABLED")
	LibKeyBound.RegisterCallback(self, "LIBKEYBOUND_MODE_COLOR_CHANGED")
end

function Yata:OnEnable()
	
	if self.Bar then
		self.Bar:Destroy()
	end

	local firstUse = self:SetActiveTalentProfile()
	
	self.Bar = TotemBar:Create() 
	self.Bar:UpdateCallIndicators()

	self:RegisterEvent("LEARNED_SPELL_IN_TAB", "SpellLearned")
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "Reload") -- just to be sure
	
	if self.CurrentDb.AdvancedEnabled == false or self.CurrentDb.AdvShowBlizzBar == false then
		RegisterStateDriver(MultiCastActionBarFrame, "visibility", "hide");
	else
		RegisterStateDriver(MultiCastActionBarFrame, "visibility", "show");
	end

	-- if firstUse == true then
		-- self:Print ("First time in this spec: copying yata profile and reloading")
		-- self:Reload()
	-- end
		
	self:ResetTimers()
end

function Yata:OnDisable()
	if self.Bar then
		self.Bar:Destroy()
	end
end

function Yata:SpellLearned(event, spellId, tabId)
	local isGuild, name
	_,_,_,_,isGuild = GetSpellTabInfo(tabId)
	
	name, _, _, _, _, _, _, _, _ = GetSpellInfo(spellId)
	
	if(isGuild == false and name ~= "Fast Track") then -- Don't reload when we get new guild spells (these won't affect the totem bar).  Special case Fast Track as it's broken for some reason
		Yata:Print("Detected new spell: "..name)
		Yata:Reload()
	end
end

function Yata:Reload()

	self:Print("Reloading")

	self:UnregisterAllEvents()

	self:OnDisable()
	
	self:OnEnable()
end

function Yata:Reset()
	self.db:ResetProfile()
	self:Reload()
end

function Yata:SetActiveTalentProfile()
	local specIndex = 1 --GetActiveSpecGroup();
	local firstUse = false
	
	if self.db.profile.InitialSpec == nil then
		self.db.profile.InitialSpec = specIndex
	end

	if specIndex == self.db.profile.InitialSpec then
		self.CurrentDb = self.db.profile
	else
		self.CurrentDb = self.db.profile.alternativespec
		if self.db.profile.alternativespec.FirstUse == true then
			self.db.profile.alternativespec = Yata:deepcopy(self.db.profile)
			
			self.db.profile.alternativespec.alternativespec = nil
			
			self.db.profile.alternativespec.FirstUse = false
			
			firstUse = true
		end
	end
	
	return firstUse	
end

function Yata:deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end