local ElitistGroup = select(2, ...)
local Report = ElitistGroup:NewModule("Report", "AceEvent-3.0")
local L = ElitistGroup.L

function Report:Show()
	
end

--[[
local self = ElitistGroup.modules.Report
local frame = self.frame

frame:SetHeight(325)
frame:SetWidth(351)

local function createButton(parent, text)
   local check = CreateFrame("CheckButton", nil, parent)
   check:SetSize(20, 20)
   check:SetHitRectInsets(0, -100, 0, 0)
   check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
   check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
   check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
   check:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
   check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
   
   check.text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   check.text:SetPoint("LEFT", check, "RIGHT", 0, 1)
   check.text:SetText(text)
   check.text:SetWidth(parent:GetWidth() - 26)
   check.text:SetHeight(11)
   check.text:SetJustifyH("LEFT")
   return check 
end

if( self.generalFrame ) then self.generalFrame:Hide() end

local backdrop = {bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1}
local generalFrame = CreateFrame("Frame", nil, frame)   
generalFrame:SetBackdrop(backdrop)
generalFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
generalFrame:SetBackdropColor(0, 0, 0, 0)
generalFrame:SetWidth(185)
generalFrame:SetHeight(193)
generalFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -42)
self.generalFrame = generalFrame

generalFrame.headerText = generalFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
generalFrame.headerText:SetPoint("BOTTOMLEFT", generalFrame, "TOPLEFT", 0, 5)
generalFrame.headerText:SetText("General")

if( self.roleFrame ) then self.roleFrame:Hide() end
local roleFrame = CreateFrame("Frame", nil, frame)   
roleFrame:SetBackdrop(backdrop)
roleFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
roleFrame:SetBackdropColor(0, 0, 0, 0)
roleFrame:SetWidth(185)
roleFrame:SetHeight(60)
roleFrame:SetPoint("TOPLEFT", self.generalFrame, "BOTTOMLEFT", 0, -20)
self.roleFrame = roleFrame

local roles = {"healer", "tank", "damage"}
roleFrame.checks = {}
for id, role in pairs(roles) do
   local check = createButton(roleFrame, string.format("Show %ss", role))
   
   if( id > 1 ) then
      check:SetPoint("TOPLEFT", roleFrame.checks[id - 1], "BOTTOMLEFT", 0, 0)
   else
      check:SetPoint("TOPLEFT", roleFrame, "TOPLEFT", 4, -1)
   end
   roleFrame.checks[id] = check
end


roleFrame.headerText = roleFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
roleFrame.headerText:SetPoint("BOTTOMLEFT", roleFrame, "TOPLEFT", 0, 5)
roleFrame.headerText:SetText("Role")

if( self.classFrame ) then self.classFrame:Hide() end
local classFrame = CreateFrame("Frame", nil, frame)   
classFrame:SetBackdrop(backdrop)
classFrame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
classFrame:SetBackdropColor(0, 0, 0, 0)
classFrame:SetWidth(130)
classFrame:SetHeight(273)
classFrame:SetPoint("TOPLEFT", self.generalFrame, "TOPRIGHT", 12, 0)
self.classFrame = classFrame

classFrame.headerText = classFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
classFrame.headerText:SetPoint("BOTTOMLEFT", classFrame, "TOPLEFT", 0, 5)
classFrame.headerText:SetText("Classes")


classFrame.selectAll = createButton(classFrame, "Select all")
classFrame.selectAll:SetPoint("TOPLEFT", classFrame, "TOPLEFT", 2, -4)

classFrame.checks = {}
for id, classToken in pairs(CLASS_SORT_ORDER) do
   local check = createButton(classFrame, LOCALIZED_CLASS_NAMES_MALE[classToken])
   local classColor = RAID_CLASS_COLORS[classToken]
   check.text:SetTextColor(classColor.r, classColor.g, classColor.b)
   
   if( id > 1 ) then
      check:SetPoint("TOPLEFT", classFrame.checks[id - 1], "BOTTOMLEFT", 0, -5)
   else
      check:SetPoint("TOPLEFT", classFrame.selectAll, "BOTTOMLEFT", 0, -3)   
   end
   classFrame.checks[id] = check
end


if( self.sendFrame ) then self.sendFrame:Hide() end
]]

function Report:CreateUI()
	if( self.frame ) then
		self.frame:Show()
		return
	end
	
	local function OnEnter(self)
		if( self.tooltip ) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, not self.disableWrap)
			GameTooltip:Show()
		end
	end

	local function OnLeave(self)
		GameTooltip:Hide()
	end
	
	-- Main container
	local frame = CreateFrame("Frame", "ElitistGroupGroupRatingFrame", UIParent)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton", "RightButton")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetToplevel(true)
	frame:SetHeight(300)
	frame:SetWidth(545)
	frame:SetScript("OnDragStart", function(self, mouseButton)
		if( mouseButton == "RightButton" ) then
			frame:ClearAllPoints()
			frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			ElitistGroup.db.profile.positions.notes = nil
			return
		end
		
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		
		local scale = self:GetEffectiveScale()
		ElitistGroup.db.profile.positions.notes = {x = self:GetLeft() * scale, y = self:GetTop() * scale}
	end)
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 26,
		insets = {left = 9, right = 9, top = 9, bottom = 9},
	})
	frame:SetBackdropColor(0, 0, 0, 0.90)
	
	table.insert(UISpecialFrames, "ElitistGroupReportFrame")
		
	--local function OnClick(self) PlaySound(self:GetChecked() and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff") end
    
	if( ElitistGroup.db.profile.positions.report ) then
		local scale = frame:GetEffectiveScale()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ElitistGroup.db.profile.positions.report.x / scale, ElitistGroup.db.profile.positions.report.y / scale)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end

	frame.titleBar = frame:CreateTexture(nil, "ARTWORK")
	frame.titleBar:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	frame.titleBar:SetPoint("TOP", 0, 8)
	frame.titleBar:SetWidth(200)
	frame.titleBar:SetHeight(45)

	frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.title:SetPoint("TOP", 0, 0)
	frame.title:SetText("Elitist Group")

	-- Close button
	local button = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", -3, -3)
	button:SetHeight(28)
	button:SetWidth(28)
	button:SetScript("OnClick", function() frame:Hide() end)
	
	self.frame = frame
end
