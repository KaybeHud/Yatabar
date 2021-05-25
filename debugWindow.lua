if not (Yatabar) then return; end;

Yatabar.window = nil
Yatabar.textArea = nil
local count = 1

function Yatabar:CreateDebugWindow()
	local name = "YBDebugWindow"
	Yatabar.window = CreateFrame("Frame", name, UIParent)
	Yatabar.window:SetPoint("CENTER",UIParent,"CENTER",-60,60)
	Yatabar.window:SetWidth(500);
	Yatabar.window:SetHeight(800);
	
	Yatabar.window:SetMovable(true);
	Yatabar.window:SetClampedToScreen(true);
	Yatabar.window:EnableMouse(true)
	Yatabar.window:RegisterForDrag("LeftButton")
	Yatabar.window:SetScript("OnDragStart", Yatabar.window.StartMoving)
	Yatabar.window:SetScript("OnDragStop", Yatabar.window.StopMovingOrSizing)

	local titlebg = Yatabar.window:CreateTexture(nil, "BORDER")
	titlebg:SetTexture(251966) --"Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background"
	titlebg:SetPoint("TOPLEFT")
	titlebg:SetPoint("BOTTOMRIGHT", Yatabar.window, "TOPRIGHT", 0, -24)

	local windowbg = Yatabar.window:CreateTexture(nil, "BACKGROUND")
	windowbg:SetTexture(136548) --"Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-L1"
	windowbg:SetPoint("TOPLEFT", 0, 0)
	windowbg:SetPoint("BOTTOMRIGHT", 0,0)
	windowbg:SetTexCoord(0.255, 1, 0.29, 1)

	local close = CreateFrame("Button", nil, Yatabar.window, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 2, 1)
	close:SetScript("OnClick", Yatabar.CloseWindow)

	
	local scroll = CreateFrame("ScrollFrame", "YBDebugScroll", Yatabar.window, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", Yatabar.window, "TOPLEFT", 10, -30)
	scroll:SetPoint("BOTTOMRIGHT", Yatabar.window, "BOTTOMRIGHT", -30, 10)
	--scroll:SetAllPoints()

	Yatabar.textArea = CreateFrame("EditBox", "YBDebugScrollText", scroll)
	Yatabar.textArea:SetTextColor(1, 1, 1, 1)
	Yatabar.textArea:SetAutoFocus(false)
	Yatabar.textArea:SetMultiLine(true)
	Yatabar.textArea:SetFontObject( GameFontHighlightSmall)
	Yatabar.textArea:SetMaxLetters(99999)
	Yatabar.textArea:EnableMouse(true)
	Yatabar.textArea:SetScript("OnEscapePressed", Yatabar.textArea.ClearFocus)
	Yatabar.textArea:SetWidth(480)

	scroll:SetScrollChild(Yatabar.textArea)
	Yatabar.window:Hide()
end

function Yatabar:CloseWindow()
	Yatabar.window:Hide()
end

function Yatabar:ShowWindow()
    if Yatabar.window ~= nil then
        Yatabar.window:Show()
    else
        Yatabar:CreateDebugWindow()
        Yatabar.window:Show()
    end
end

function Yatabar:AddDebugText(text)
    if text ~= nil then
        Yatabar.textArea:Insert(count.." - "..text.."\n")
		count = count + 1
    end
end
