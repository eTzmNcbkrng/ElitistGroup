local ElitistGroup = select(2, ...)
local Inspect = ElitistGroup:NewModule("Inspect", "AceEvent-3.0")
local L = ElitistGroup.L
local buttonList = {"talentInfo", "gearInfo", "enchantInfo", "gemInfo"}

function Inspect:OnInitialize()
	if( ElitistGroup.db.profile.inspect.window or ElitistGroup.db.profile.inspect.tooltips ) then
		if( not IsAddOnLoaded("Blizzard_InspectUI") ) then
			self:RegisterEvent("ADDON_LOADED")
		else
			self:ADDON_LOADED(nil, "Blizzard_InspectUI")
		end
	end
end

function Inspect:ADDON_LOADED(event, addon)
	if( addon ~= "Blizzard_InspectUI" ) then return end
	self:UnregisterEvent("ADDON_LOADED")
	
	local function OnShow()
		local self = Inspect
		
		if( InspectFrame.unit and UnitIsFriend(InspectFrame.unit, "player") and CanInspect(InspectFrame.unit) ) then
			self.inspectID = ElitistGroup:GetPlayerID(InspectFrame.unit)
			self:RegisterMessage("SG_DATA_UPDATED")
			
			-- Setup the summary window for the inspect if it's enabled and we can inspect them
			if( ElitistGroup.db.profile.inspect.window ) then
				self:SetupSummary()
			elseif( self.frame ) then
				self.frame:Hide()
			end
			
			if( ElitistGroup.db.profile.inspect.tooltips ) then
				self:SetupTooltips()
			end
		else
			if( self.frame ) then self.frame:Hide() end
			ElitistGroup.tooltip:Hide()
		end
	end
	
	InspectFrame:HookScript("OnShow", OnShow)
	InspectFrame:HookScript("OnHide", function() Inspect:UnregisterMessage("SG_DATA_UPDATED") end)
	hooksecurefunc("InspectFrame_UnitChanged", OnShow)
	if( InspectFrame:IsVisible() ) then OnShow() end
end

function Inspect:SG_DATA_UPDATED(event, type, playerID)
	if( self.inspectID == playerID ) then
		if( ElitistGroup.db.profile.inspect.window ) then
			self:SetupSummary()
		end
		
		if( ElitistGroup.db.profile.inspect.tooltips ) then
			self:SetupTooltips()
		end
	end
end

function Inspect:SetupTooltips()
	local userData = self.inspectID and ElitistGroup.userData[self.inspectID]
	if( not userData ) then return end
	
	local equipmentData, enchantData, gemData = ElitistGroup:GetGearSummary(userData)
	local enchantTooltips, gemTooltips = ElitistGroup:GetGearSummaryTooltip(userData.equipment, enchantData, gemData)
	
	for inventoryID, inventoryKey in pairs(ElitistGroup.Items.validInventorySlots) do
		local button = self[inventoryKey] or _G["Inspect" .. inventoryKey]
		local itemLink = userData.equipment[inventoryID]
		if( itemLink ) then
			local baseItemLink = ElitistGroup:GetBaseItemLink(itemLink)
			button.gemTooltip = gemTooltips[itemLink]
			button.enchantTooltip = enchantTooltips[itemLink]
			button.isBadType = equipmentData[itemLink] and "|cffff2020[!]|r " or ""
			button.itemTalentType = ElitistGroup.Items.itemRoleText[ElitistGroup.ITEM_TALENTTYPE[baseItemLink]] or ElitistGroup.ITEM_TALENTTYPE[baseItemLink]
			button.hasData = true
		else
			button.hasData = nil
		end

		-- Force tooltip update so if data was found the tooltip reflects it without having to remouseover
		if( GameTooltip:IsOwned(button) ) then
			button:GetScript("OnEnter")(button)
		end
		
		self[inventoryKey] = button
	end
	
	ElitistGroup:ReleaseTables(equipmentData, enchantData, gemData, enchantTooltips, gemTooltips)
	
	if( not self.hooked ) then
		local function OnEnter(self)
			if( not self.hasData or not ElitistGroup.db.profile.inspect.tooltips ) then return end
			
			ElitistGroup.tooltip:SetOwner(GameTooltip, "ANCHOR_NONE")
			ElitistGroup.tooltip:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 0, -5)
			if( self.itemTalentType ) then
				ElitistGroup.tooltip:SetText(string.format(L["|cfffed000Item Type:|r %s%s"], self.isBadType, self.itemTalentType), 1, 1, 1)
			end
			if( self.enchantTooltip ) then
				ElitistGroup.tooltip:AddLine(self.enchantTooltip)
			end
			if( self.gemTooltip ) then
				ElitistGroup.tooltip:AddLine(self.gemTooltip)
			end
			ElitistGroup.tooltip:Show()
		end
		
		local function OnLeave(self)
			ElitistGroup.tooltip:Hide()
		end
		
		for inventoryKey in pairs(ElitistGroup.Items.inventoryToID) do
			local button = self[inventoryKey]
			button:HookScript("OnLeave", OnLeave)
			button:HookScript("OnEnter", OnEnter)
		end
		
		self.hooked = true
	end
end

function Inspect:SetupSummary()
	self:CreateSummary()
	
	local userData = self.inspectID and ElitistGroup.userData[self.inspectID]
	if( not userData ) then
		for _, key in pairs(buttonList) do
			self.frame[key]:SetText(nil)
			self.frame[key].tooltip = nil
		end

		self.frame.enchantInfo:SetText(L["Loading"])
		self.frame.enchantInfo:GetFontString():SetTextColor(GameFontHighlight:GetTextColor())
		self.frame.enchantInfo.tooltip = L["Data is loading, please wait."]
		self.frame.enchantInfo.disableWrap = nil
	else
		-- Make sure they are talented enough
		local specType, specName, specIcon = ElitistGroup:GetPlayerSpec(userData)
		if( not userData.unspentPoints ) then
			self.frame.talentInfo:SetFormattedText("%d/%d/%d", userData.talentTree1, userData.talentTree2, userData.talentTree3)
			self.frame.talentInfo.tooltip = string.format(L["%s, %s role."], specName, ElitistGroup.Talents.talentText[specType])
		else
			self.frame.talentInfo:SetFormattedText(L["%d unspent |4point:points;"], userData.unspentPoints)
			self.frame.talentInfo.tooltip = string.format(L["%s, %s role.\n\nThis player has not spent all of their talent points!"], specName, ElitistGroup.Talents.talentText[specType])
		end
		
		local equipmentData, enchantData, gemData = ElitistGroup:GetGearSummary(userData)
		local gemTooltip, enchantTooltip = ElitistGroup:GetGeneralSummaryTooltip(gemData, enchantData)
		
		-- People probably want us to build the gear info, I'd imagine
		if( equipmentData.totalBad == 0 ) then
			self.frame.gearInfo:SetFormattedText(L["(%s%d|r) Gear"], ElitistGroup:GetItemColor(equipmentData.totalScore), equipmentData.totalScore)
			self.frame.gearInfo:GetFontString():SetTextColor(GameFontHighlight:GetTextColor())
			self.frame.gearInfo.tooltip = L["Equipment: |cffffffffAll good|r"]
			self.frame.gearInfo.disableWrap = true
		else
			local gearTooltip = string.format(L["Equipment: |cffffffff%d bad items found|r"], equipmentData.totalBad)
			for _, itemLink in pairs(userData.equipment) do
				local fullItemLink = select(2, GetItemInfo(itemLink))
				if( fullItemLink and equipmentData[itemLink] ) then
					gearTooltip = gearTooltip .. "\n" .. string.format(L["%s - %s item"], fullItemLink, ElitistGroup.Items.itemRoleText[equipmentData[itemLink]] or equipmentData[itemLink])
				end
			end

			self.frame.gearInfo:SetFormattedText(L["(%s%d|r) Gear"], ElitistGroup:GetItemColor(equipmentData.totalScore), equipmentData.totalScore)
			self.frame.gearInfo:GetFontString():SetTextColor(1, 0.15, 0.15, 1)
			self.frame.gearInfo.tooltip = gearTooltip
			self.frame.gearInfo.disableWrap = true
		end
		
		-- Build enchants
		if( enchantData.pass and not enchantData.noData ) then
			self.frame.enchantInfo:GetFontString():SetTextColor(GameFontHighlight:GetTextColor())
		else
			self.frame.enchantInfo:GetFontString():SetTextColor(1.0, 0.15, 0.15, 1)
		end
		
		if( not enchantData.noData ) then
			self.frame.enchantInfo:SetText(L["Enchants"])
			self.frame.enchantInfo.tooltip = enchantTooltip
			self.frame.enchantInfo.disableWrap = not enchantData.noData
		else
			self.frame.enchantInfo:SetText(L["Enchants"])
			self.frame.enchantInfo.icon:SetTexture(READY_CHECK_WAITING_TEXTURE)
			self.frame.enchantInfo.tooltip = L["No enchants found."]
			self.frame.enchantInfo.disableWrap = nil
		end

		-- Build gems
		if( gemData.pass and not gemData.noData ) then
			self.frame.gemInfo:GetFontString():SetTextColor(GameFontHighlight:GetTextColor())
		else
			self.frame.gemInfo:GetFontString():SetTextColor(1.0, 0.15, 0.15, 1)
		end

		if( not gemData.noData ) then
			self.frame.gemInfo:SetText(L["Gems"])
			self.frame.gemInfo.tooltip = gemTooltip
			self.frame.gemInfo.disableWrap = not gemData.noData
		else
			self.frame.gemInfo:SetText(L["Gems"])
			self.frame.gemInfo.tooltip = L["No gems found."]
			self.frame.gemInfo.disableWrap = nil
		end		
		
		ElitistGroup:ReleaseTables(equipmentData, enchantData, gemData)
	end
end

function Inspect:CreateSummary()
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
	
	local frame = CreateFrame("Frame", nil, InspectFrame)
	frame:SetFrameLevel(100)
	frame:SetSize(1, 1)
	frame:Hide()
	
	local font, size = GameFontHighlight:GetFont()
	for i, key in pairs(buttonList) do
		local button = CreateFrame("Button", nil, frame)
		button:SetNormalFontObject(GameFontHighlight)
		button:SetText("*")
		button:SetHeight(15)
		button:SetWidth(125)
		button:SetScript("OnEnter", OnEnter)
		button:SetScript("OnLeave", OnLeave)
		button:SetPushedTextOffset(0, 0)	
		local fontString = button:GetFontString()
		fontString:SetFont(font, size, "OUTLINE")
		fontString:SetPoint("RIGHT", button, "RIGHT", -2, 0)
		fontString:SetJustifyH("RIGHT")
		fontString:SetJustifyV("CENTER")
		fontString:SetWidth(button:GetWidth())
		fontString:SetHeight(15)
		
		if( i > 1 ) then
			button:SetPoint("TOPRIGHT", frame[buttonList[i - 1]], "BOTTOMRIGHT", 0, -4)
		else
			button:SetPoint("TOPRIGHT", InspectTrinket0Slot, "TOPLEFT", -10, -1)
		end
		
		frame[key] = button
	end	
	
	self.frame = frame
	self.frame:Show()
end