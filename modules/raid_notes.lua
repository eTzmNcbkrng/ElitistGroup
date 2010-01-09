local ElitistGroup = select(2, ...)
local History = ElitistGroup:NewModule("RaidHistory", "AceEvent-3.0")
local L = ElitistGroup.L
--[[
local self = ElitistGroup.modules.Users
local frame = self.frame


if( frame.manageNote ) then frame.manageNote:Hide() end
local backdrop = {bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1}

frame.manageNote = CreateFrame("Frame", nil, frame)
frame.manageNote:SetFrameLevel(40)
frame.manageNote:SetBackdrop(backdrop)
frame.manageNote:SetBackdropBorderColor(0.60, 0.60, 0.60, 1)
frame.manageNote:SetBackdropColor(0, 0, 0)
frame.manageNote:SetHeight(251)
frame.manageNote:SetWidth(175)
frame.manageNote:SetPoint("TOPLEFT", frame.userFrame.manageNote or TestLog, "BOTTOMLEFT", -3, -1)

frame.manageNote.role = frame.manageNote:CreateFontString(nil, "ARTWORK", "GameFontNormal")
frame.manageNote.role:SetPoint("TOPLEFT", frame.manageNote, "TOPLEFT", 4, -14)
frame.manageNote.role:SetText("Role")

frame.manageNote.roleTank = CreateFrame("Button", nil, frame.manageNote)
frame.manageNote.roleTank:SetSize(18, 18)
frame.manageNote.roleTank:SetNormalTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
frame.manageNote.roleTank:GetNormalTexture():SetTexCoord(0, 19/64, 22/64, 41/64)
frame.manageNote.roleTank:SetPoint("LEFT", frame.manageNote.role, "RIGHT", 24, 0)

frame.manageNote.roleHealer = CreateFrame("Button", nil, frame.manageNote)
frame.manageNote.roleHealer:SetSize(18, 18)
frame.manageNote.roleHealer:SetNormalTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
frame.manageNote.roleHealer:GetNormalTexture():SetTexCoord(20/64, 39/64, 1/64, 20/64)
frame.manageNote.roleHealer:SetPoint("LEFT", frame.manageNote.roleTank, "RIGHT", 6, 0)

frame.manageNote.roleDamage = CreateFrame("Button", nil, frame.manageNote)
frame.manageNote.roleDamage:SetSize(18, 18)
frame.manageNote.roleDamage:SetNormalTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
frame.manageNote.roleDamage:GetNormalTexture():SetTexCoord(20/64, 39/64, 22/64, 41/64)
frame.manageNote.roleDamage:SetPoint("LEFT", frame.manageNote.roleHealer, "RIGHT", 6, 0)

frame.manageNote.rating = CreateFrame("Slider", nil, frame.manageNote)
frame.manageNote.rating:SetBackdrop({bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
      edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
      tile = true, tileSize = 8, edgeSize = 8,
      insets = { left = 3, right = 3, top = 6, bottom = 6 }
})
frame.manageNote.rating:SetPoint("TOPLEFT", frame.manageNote.role, "BOTTOMLEFT", 1, -34)
frame.manageNote.rating:SetHeight(15)
frame.manageNote.rating:SetWidth(165)
frame.manageNote.rating:SetOrientation("HORIZONTAL")
frame.manageNote.rating:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
frame.manageNote.rating:SetMinMaxValues(1, 5)
frame.manageNote.rating:SetValue(3)
frame.manageNote.rating:SetValueStep(1)
frame.manageNote.rating:SetScript("OnValueChanged", nil)

local rating = frame.manageNote:CreateFontString(nil, "ARTWORK", "GameFontNormal")
rating:SetPoint("BOTTOMLEFT", frame.manageNote.rating, "TOPLEFT", 0, 3)
rating:SetPoint("BOTTOMRIGHT", frame.manageNote.rating, "TOPRIGHT", 0, 3)
rating:SetText("Rating")

local min = frame.manageNote:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
min:SetText("Terrible")
min:SetPoint("TOPLEFT", frame.manageNote.rating, "BOTTOMLEFT", 0, -2)

local max = frame.manageNote:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
max:SetText("Great")
max:SetPoint("TOPRIGHT", frame.manageNote.rating, "BOTTOMRIGHT", 0, -2)







]]
--[[
local textures = {
"inv_jewelcrafting_gem_37",
"inv_jewelcrafting_gem_39",
"inv_jewelcrafting_dragonseye03",
"inv_jewelcrafting_gem_42",
"inv_jewelcrafting_gem_41",
}

local textures = {
   "inv_jewelcrafting_gem_37",
   "inv_jewelcrafting_gem_39",
   "inv_jewelcrafting_gem_38",
   "inv_jewelcrafting_gem_42",
   "inv_jewelcrafting_gem_41",
}

local buttons = {}
for i=1, 5 do
   local button = CreateFrame("Button", nil, frame.manageNote)
   button:SetSize(20, 20)
   button:SetNormalTexture("Interface\\Icons\\" .. textures[i])
   
   if( i > 1 ) then
      button:SetPoint("LEFT", buttons[i - 1], "RIGHT", 1, 0) 
   else
      button:SetPoint("LEFT", frame.manageNote.rating, "RIGHT", 23, 0)
   end
   buttons[i] = button
   
end








]]

