local AceGUI = LibStub("AceGUI-3.0")
do 
	local widgetType = "Yata_TotemButtonLayoutEditor"
	local widgetVersion = 1
	local startIcon = 0
	local stopIcon = 0
	local icons = {}
	local sets = {}
	
	local function Frame_OnEnter(this)
		local self = this.obj
		self:Fire("OnEnter")
	end

	local function Frame_OnLeave(this)
		local self = this.obj
		self:Fire("OnLeave")		
	end

	local function OnAcquire(self)
	end
	
	local function OnRelease(self)
		self:Hide()
	end
	
	local function Show(self)
		UpdateIcons(self.main.frame)
		self.main:Show()
	end

	local function Hide(self)
		ClearCursor()
		self.main:Hide()
	end
	
	local function UpdateIcons()
		for m,n in ipairs(icons) do
			local header = Yata.Bar.Groups[n.Button.Totem.SpellGroup].Header
			local id = (header:GetAttribute("position") + 1) * 10 + n.Button:GetAttribute("position")
			n.id = id
			n:SetPoint("BOTTOMLEFT",n.Parent,"BOTTOMLEFT",50+(math.floor(id/10)-1)*36,50+math.fmod(id,10)*36)		
		end
	end
	
	local function IconDrag(self, start)		
		if start then
			PickupSpell( self.Button.Totem.Name );
			startIcon = self
		else 
			ClearCursor()
			stopIcon = self
			if startIcon and stopIcon then
				if math.floor(startIcon.id/10) == math.floor(stopIcon.id/10) then
					local idbackup = stopIcon.id
					stopIcon.id = startIcon.id
					startIcon.id = idbackup
					startIcon.Button:SetAttribute("newposition",math.fmod(startIcon.id,10))
					stopIcon.Button:SetAttribute("newposition",math.fmod(stopIcon.id,10))
				elseif math.fmod(startIcon.id,10)  == math.fmod(stopIcon.id,10) then
					local backup = stopIcon.Button.Totem.SpellGroup
					local oldindex = math.floor(startIcon.id/10)
					local newindex = math.floor(stopIcon.id/10)
					local startHeader = Yata.Bar.Groups[startIcon.Button.Totem.SpellGroup].Header
					local stopHeader = Yata.Bar.Groups[backup].Header
					startHeader:SetAttribute("position",newindex-1)
					stopHeader:SetAttribute("position",oldindex-1)
					for m,n in ipairs(icons) do
						local nid = math.floor(n.id/10)
						if nid == oldindex then
							nid = newindex
						elseif nid == newindex then							
							nid = oldindex
						end
						n.id = nid * 10 + math.fmod(n.id,10)
					end
				end
				UpdateIcons()
			end
			startIcon = nil
			stopIcon = nil			
		end
	end
	
	local function TotemClick(self)
		if not self.Button:GetAttribute("hidden") then
			self.Visibility:SetVertexColor(1.0, 0.0, 0, 0.75)
			self.Visibility:SetText("Hide")
			self.Button:SetAttribute("hidden", true)
		else
			self.Visibility:SetVertexColor(0.0, 1.0, 0, 0.75)
			self.Visibility:SetText("Show")
			self.Button:SetAttribute("hidden", false)
		end
	end
	
	local function Dropdown_Changed(self, event, value)
		Yata.Bar:ApplyTotemSet(value)
		Yata.CurrentDb.CurrentTotemSet = value
		UpdateIcons()
	end	
		
	local function SetDropDown(self)
		self.loadsetdropdown:SetList({})
		sets = {}
		for i,b in pairs(Yata.CurrentDb.Sets) do
			self.loadsetdropdown:AddItem(i,i)
			table.insert(sets,i);
		end
		self.loadsetdropdown:SetValue(Yata.CurrentDb.CurrentTotemSet)	
	end
	
	local function AddSet(self,name)
		if name then
			Yata:SetTotemSet(name,nil)
			Yata.CurrentDb.CurrentTotemSet = name
			SetDropDown(self)
		end
	end
	
	local function DelSet(self,name)
		if name and name ~= TOTEM_SET_PRIMARY_DEFAULT then
			if name == Yata.CurrentDb.CurrentTotemSet then
				Yata.CurrentDb.CurrentTotemSet = TOTEM_SET_PRIMARY_DEFAULT
				Yata.Bar:ApplyTotemSet()
			end
			if Yata.CurrentDb.Sets[name] then
				Yata.CurrentDb.Sets[name] = nil
			end
			SetDropDown(self)
			UpdateIcons()
		end
	end
	
	local function CreateTotemIcon(button, id, parent)
		local name = "YataOption"..button.Totem.Name
		local totemFrame = CreateFrame("Button", name, parent)
		totemFrame.id = id
		totemFrame.Parent = parent
		totemFrame:RegisterForClicks("LeftButtonUp","RightButtonUp")
		totemFrame.Button = button
		totemFrame:EnableMouse(true)
		totemFrame:RegisterForDrag("LeftButton")
		totemFrame:SetScript("OnClick", function() TotemClick(totemFrame) end)
		totemFrame:SetScript("OnDragStart", function() IconDrag(totemFrame, true) end)
		totemFrame:SetScript("OnReceiveDrag", function() IconDrag(totemFrame, nil) end)
		totemFrame:SetWidth(36)
		totemFrame:SetHeight(36)
		totemFrame:SetFrameLevel(parent:GetFrameLevel() + 2)
		totemFrame.Icon = totemFrame:CreateTexture(name.."Icon")   
		totemFrame.Icon:SetTexture(button.Totem.Texture)			
		totemFrame.Icon:SetAllPoints(totemFrame)
		totemFrame.Visibility = totemFrame:CreateFontString(name.."Visibility", "Overlay", "GameFontNormalSmall")	
		totemFrame.Visibility:SetWidth(36)
		totemFrame.Visibility:SetHeight(10)
		if button:GetAttribute("hidden") then
			totemFrame.Visibility:SetText("Hide")
			totemFrame.Visibility:SetVertexColor(1.0, 0.0, 0, 0.75)
		else
			totemFrame.Visibility:SetText("Show")
			totemFrame.Visibility:SetVertexColor(0.0, 1.0, 0, 0.75)
		end
		totemFrame.Visibility:SetPoint("CENTER",0,-10)			
		return totemFrame
	end
	
	
	local function Constructor()
		local self = {}
		self.main = AceGUI:Create("Frame")
		self.type = widgetType
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire		
		self.main.frame:SetWidth(400)
		self.main.frame:SetHeight(400)
		self.main.frame:SetFrameLevel(8)
		self.main.frame:SetScript("OnEnter", Frame_OnEnter)
		self.main.frame:SetScript("OnLeave", Frame_OnLeave)
		self.main.titletext:SetText("Layout Editor")
		
		self.Show = Show
		self.Hide = Hide
		self.AddSet = function(_, name) AddSet(self,name) end
		self.DelSet = function(_, name) DelSet(self,name) end
		
		self.loadsetdropdown = AceGUI:Create("Dropdown")
		self.main:AddChild(self.loadsetdropdown)
		self.loadsetdropdown:SetWidth(300)
		self.loadsetdropdown:SetLabel("Totemset")
		self.loadsetdropdown:SetCallback("OnValueChanged",function(self, event, value) Dropdown_Changed(self, event, value) end)
		self.loadsetdropdown.frame:SetPoint("TOPLEFT",self.main.closebutton,"TOPLEFT",0,250)		
		
		self.addsetbutton = AceGUI:Create("Button")
		self.main:AddChild(self.addsetbutton)
		self.addsetbutton.text:SetText("Add Set")
		self.addsetbutton:SetWidth(100)		
		self.addsetbutton.frame:SetPoint("TOPLEFT",self.loadsetdropdown.frame,"BOTTOMLEFT",0,0)
		self.addsetbutton.frame:HookScript("OnClick", function() local show = StaticPopup_Show("Yata_AddSet") show:SetParent(self.main.frame) show.data = self end)
		
		self.delsetbutton = AceGUI:Create("Button")
		self.main:AddChild(self.delsetbutton)
		self.delsetbutton.text:SetText("Delete Set")
		self.delsetbutton:SetWidth(100)
		self.delsetbutton.frame:SetPoint("TOPLEFT",self.addsetbutton.frame,"BOTTOMLEFT",0,0)
		self.delsetbutton.frame:HookScript("OnClick", function() local show = StaticPopup_Show("Yata_DelSet") show:SetParent(self.main.frame) show.data = self end)
		
		SetDropDown(self)
		
		for m,n in ipairs(Yata.Bar.Groups.All) do
			local totem = n.Totem
			local id = (Yata.Bar.Groups[totem.SpellGroup].Header:GetAttribute("position") +1 )*10+n:GetAttribute("position")
			local tIcon = CreateTotemIcon(n,id,self.main.frame)				
			table.insert(icons,tIcon)
		end
		UpdateIcons()
		
		self.closebutton = AceGUI:Create("Button")
		self.main:AddChild(self.closebutton)
		self.closebutton:SetText("Save")
		self.closebutton:SetWidth(300)
		self.closebutton.frame:HookScript("OnClick",function() Yata:SetTotemSet(nil, nil) end)
		return self
	end

			
	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
end