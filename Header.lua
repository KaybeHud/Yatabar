if select(2, UnitClass('player')) ~= "SHAMAN" then
	return
end

Header = CreateFrame("Frame")
Header.__index = Header

function Header:Create(id, parent)
	local name = "YataElementHeader" .. id
	local header = _G[name] or CreateFrame("Frame", name, parent, "SecureHandlerAttributeTemplate, SecureHandlerEnterLeaveTemplate")
	
	header.Name = name
	header.Parent = parent;
	header:SetWidth(36)
	header:SetHeight(0)	
	
	header:SetAttribute("popoutscale", Yata.CurrentDb.PopOutScale)
	 
	header:SetAttribute("proxybinding",nil)
	
	header:SetAttribute("element",id)
	
	if id ~= SPELL_GROUP_CALL and id ~= SPELL_GROUP_IMBUE then
		header:SetAttribute("istotemgroup", true)
	end
	
	header:SetAttribute( "_onleave", [[  
		self:SetAttribute("show", false)
	]] )
	
	header:SetAttribute("_onattributechanged", [[
		local buttonGap = self:GetAttribute("buttongap") or 0
		local headerSize = 36
		local orientation = self:GetAttribute("orientation")
		local buttonSize = headerSize + buttonGap

		if name == "show" then
			local visibleButtons = self:GetAttribute("visiblebuttons") or 1
			buttons = newtable(self:GetChildren())
			
			if value == true then
				for k,v in ipairs(buttons) do 
					local pos = v:GetAttribute("position")
					if not v:GetAttribute("hidden") or pos == 0 then
						v:Show()
					else
						v:Hide()
					end
					
					local anchor, xpos, ypos
					local scale, offset
					
					if pos < visibleButtons then
						scale = 1
					else
						scale = self:GetAttribute("popoutscale")
					end
					
					if orientation == 1 then
						anchor = "BOTTOM"
						xpos = 0
						ypos = pos * (buttonSize) + visibleButtons * ((1 - scale) / scale * buttonSize)
					elseif orientation == 2 then
						anchor = "TOP"		
						xpos = 0
						ypos = -pos * (buttonSize) - visibleButtons * ((1 - scale) / scale  * buttonSize)
					elseif orientation == 3 then
						anchor = "LEFT"
						ypos = 0
						xpos = pos * (buttonSize) + visibleButtons * ((1 - scale) / scale  * buttonSize)
					elseif orientation == 4 then
						anchor = "RIGHT"		
						ypos = 0
						xpos = -pos * (buttonSize) - visibleButtons * ((1 - scale) / scale  * buttonSize)
					end
					
					v:SetScale(scale)
					v:SetPoint( anchor , self, anchor, xpos, ypos)	
				end
				headerSize = buttonSize * (#buttons - 1) + headerSize
						
				self:ClearAllPoints()
			
				if orientation == 1 then
					self:SetPoint("BOTTOMLEFT", self:GetParent(),"BOTTOMLEFT",self:GetAttribute("position")*buttonSize,0)
				elseif orientation == 2 then
					self:SetPoint("TOPLEFT", self:GetParent(),"TOPLEFT",self:GetAttribute("position")*buttonSize,0)
				elseif orientation == 3 then
					self:SetPoint("TOPLEFT", self:GetParent(),"TOPLEFT",0, -self:GetAttribute("position")*buttonSize)
				elseif orientation == 4 then
					self:SetPoint("TOPRIGHT", self:GetParent(),"TOPRIGHT",0, -self:GetAttribute("position")*buttonSize)
				end
			else
				for k,v in ipairs(buttons) do 
					if v:GetAttribute("position") < visibleButtons and v:GetAttribute("hidden") == false then
						v:Show()
					else
						v:Hide()
					end
				end
			end

			if orientation <= 2 then
				self:SetHeight(headerSize)
			else
				self:SetWidth(headerSize)
			end
		elseif name == "position" then
			local orientation = self:GetAttribute("orientation")
			local anchor = nil
			if orientation <= 2 then
				anchor = "BOTTOMLEFT"
			else
				anchor = "TOPLEFT"
			end
			self:ClearAllPoints()
			
			if orientation <= 2 then
				self:SetPoint(anchor, self:GetParent(),anchor,value*buttonSize,0)
			else
				self:SetPoint(anchor, self:GetParent(),anchor,0, -value*buttonSize)
			end
		end
	]] )
	return header
end