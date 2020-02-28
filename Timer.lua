if select(2, UnitClass('player')) ~= "SHAMAN" then
	return
end

local LSM = LibStub("LibSharedMedia-3.0",true)
local activeTotems = {}

function Yata:InitTimer()

	self:RegisterEvent("PLAYER_DEAD")
	-- Watch for damage done to our totems

    self:RegisterEvent("PLAYER_TOTEM_UPDATE")

	self.DurationGroup = self:GetBarGroup("Totem Uptime") or self:NewBarGroup("Totem Uptime", nil, 150, 12)
	self.DurationGroup:SetFrameStrata("LOW")
	self.DurationGroup:SetFont(nil, 8)
	self.DurationGroup:SetColorAt(1.00, 0.0, 1.0, 0.0, 1)
	self.DurationGroup:SetColorAt(0.66, 1.0, 1.0, 0.0, 1)
	self.DurationGroup:SetColorAt(0.33, 1.0, 0.65, 0.0, 1)
	self.DurationGroup:SetColorAt(0.00, 1.0, 0.0, 0.0, 1)
	self.DurationGroup:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 200, 200)

	self.CooldownGroup = self:GetBarGroup("Totem Cooldown") or self:NewBarGroup("Totem Cooldown", nil, 150, 12)
	self.CooldownGroup:SetFrameStrata("LOW")
	self.CooldownGroup:SetFont(nil, 8)
	self.CooldownGroup:SetColorAt(1.00, 1.0, 0.0, 0.0, 1)
	self.CooldownGroup:SetColorAt(0.66, 1.0, 0.65, 0.0, 1)
	self.CooldownGroup:SetColorAt(0.33, 1.0, 1.0, 0.0, 1)
	self.CooldownGroup:SetColorAt(0.00, 0.0, 1.0, 0.0, 1)
	self.CooldownGroup:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 300, 300)

	self:LoadTimerConfig()
end

function Yata:UpdateTimer(button)
	local seconds = GetTotemTimeLeft(ElementsMap[button.Totem.SpellGroup])
	AuraButton_UpdateDuration(button,seconds)
end

function Yata:SaveTimerConfig()
	local x, y
	if not self.CurrentDb.DurationGroupPosition then 
		self.CurrentDb.DurationGroupPosition = {}
	end
	x = self.DurationGroup:GetLeft()
	y = self.DurationGroup:GetBottom()
	self.CurrentDb.DurationGroupPosition.x = x
	self.CurrentDb.DurationGroupPosition.y = y
	
	if not self.CurrentDb.CooldownGroupPosition then 
		self.CurrentDb.CooldownGroupPosition = {}
	end
	x = self.CooldownGroup:GetLeft()
	y = self.CooldownGroup:GetBottom()
	self.CurrentDb.CooldownGroupPosition.x = x
	self.CurrentDb.CooldownGroupPosition.y = y	
end

function Yata:SetTimerScale(scale)
	self.DurationGroup:SetScale(scale)
	self.CooldownGroup:SetScale(scale)
end

function Yata:LoadTimerConfig()
	local x, y
	if self.CurrentDb.DurationGroupPosition then 
		x = self.CurrentDb.DurationGroupPosition.x
		y = self.CurrentDb.DurationGroupPosition.y
		self.DurationGroup:ClearAllPoints()
		self.DurationGroup:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
	end
	if self.CurrentDb.CooldownGroupPosition then 
		x = self.CurrentDb.CooldownGroupPosition.x
		y = self.CurrentDb.CooldownGroupPosition.y
		self.CooldownGroup:ClearAllPoints()
		self.CooldownGroup:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
	end
	if self.CurrentDb.Locked then
		self.DurationGroup:HideAnchor()
		self.CooldownGroup:HideAnchor()	
	end
	self.DurationGroup:SetScale(self.CurrentDb.TimerScale)
	self.DurationGroup:SetTexture(LSM:Fetch("statusbar", self.CurrentDb.TimerBarSkin))
	self.DurationGroup.orientation = Yata.CurrentDb.TimerOrientation
	self.DurationGroup.spacing = Yata.CurrentDb.TimerSpacing
	self.DurationGroup.thickness = Yata.CurrentDb.TimerThickness
	self.DurationGroup:SetLength(Yata.CurrentDb.TimerLength)
	self.DurationGroup.growup = Yata.CurrentDb.TimerGrowUp
	self.DurationGroup:SetFont(LSM:Fetch("font", Yata.CurrentDb.TimerFont), Yata.CurrentDb.TimerFontSize)
	self.DurationGroup:SetFrameStrata(Yata.CurrentDb.TimerStrata)
	
	self.CooldownGroup:SetScale(self.CurrentDb.TimerScale)
	self.CooldownGroup:SetTexture(LSM:Fetch("statusbar", self.CurrentDb.TimerBarSkin))
	self.CooldownGroup.orientation = Yata.CurrentDb.TimerOrientation
	self.CooldownGroup.spacing = Yata.CurrentDb.TimerSpacing
	self.CooldownGroup.thickness = Yata.CurrentDb.TimerThickness
	self.CooldownGroup:SetLength(Yata.CurrentDb.TimerLength)
	self.CooldownGroup.growup = Yata.CurrentDb.TimerGrowUp
	self.CooldownGroup:SetFont(LSM:Fetch("font", Yata.CurrentDb.TimerFont), Yata.CurrentDb.TimerFontSize)
	self.CooldownGroup:SetFrameStrata(Yata.CurrentDb.TimerStrata)
end

function Yata:ShowTimerAnchors()
	self.DurationGroup:ShowAnchor()
	self.CooldownGroup:ShowAnchor()
end

function Yata:HideTimerAnchors()	
	self.DurationGroup:HideAnchor()
	self.CooldownGroup:HideAnchor()	
	self:SaveTimerConfig()
end

function Yata:PLAYER_DEAD()
	if self.CurrentDb.TimerEnabled then
		for k,b in pairs(activeTotems) do			
		    self:StopTimer(b)
		    activeTotems[k] = nil
		end
	end
end

function Yata:ResetTimers()
	self:SaveTimerConfig()
	self:LoadTimerConfig()	

	for k,b in pairs(activeTotems) do			
	    self:StopTimer(b)
	    activeTotems[k] = nil
	end

	for slot = 1,4 do
		self:PLAYER_TOTEM_UPDATE(nil, slot)
	end
end

function Yata:PLAYER_TOTEM_UPDATE(event, slot)
	local haveTotem, name, startTime, duration, icon = GetTotemInfo(slot)
	if self.CurrentDb.TimerEnabled then
		if haveTotem and string.len(name) > 0 then
			for k,b in pairs(Yata.Bar.Groups.All) do
				if  string.find(string.lower(name), string.lower(b.Totem.Name))  then
					if activeTotems[slot] then
						self:StopTimer(activeTotems[slot])
					end
					self:StartTimer(b,startTime, duration)
					activeTotems[slot] = b
					break
				end
			end
		else
			if activeTotems[slot] then
				self:StopTimer(activeTotems[slot])
				activeTotems[slot] = nil
			end
		end
	end
end


function Yata:StartTimer(button, startTime, duration)
	local totem = button.Totem
	
	if self.CurrentDb.TimerType == 1 or self.CurrentDb.TimerType == 3 then
		self.DurationGroup:NewTimerBar(totem.SpellGroup.."Duration", totem.Name, duration - (GetTime() - startTime), duration, totem.Texture)
	end
	
	if self.CurrentDb.TimerType == 2 or self.CurrentDb.TimerType == 3 then
		CooldownFrame_SetTimer(button.Cooldown, startTime, duration, 1)
	end
end

function Yata:StopTimer(button)
	local totem = button.Totem
	
	local bar = self.DurationGroup:GetBar(totem.SpellGroup.."Duration")
	if (bar ~= nil) then
		self.DurationGroup:RemoveBar(bar)		
	end
	
	button:SetScript("OnUpdate", nil)		
	button.Duration:Hide()
	
	self:Cooldown(button)								
end

function Yata:Cooldown(button)
	local totem = button.Totem
    local start, duration, enabled = GetSpellCooldown(totem.Name)
    local count = (start + duration - GetTime())
	if count > 0 then	
		if self.CurrentDb.TimerType == 1 or self.CurrentDb.TimerType == 3 then
			self.CooldownGroup:NewTimerBar(totem.Name.."Cooldown", totem.Name, count, count, totem.Texture)
		end
		
		if self.CurrentDb.TimerType == 2 or self.CurrentDb.TimerType == 3 then
			CooldownFrame_SetTimer(button.Cooldown, start, duration, enabled)
			button:SetScript("OnUpdate", nil)
		end
	else
		button.Cooldown:Hide()
	end
end