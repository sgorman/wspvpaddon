-----------------------------------------------------------------------------------------------
-- Client Lua Script for PvP_Engineer
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local PvP_Engineer = {}
local knEngineerPetGroupId = 298 -- TODO Hardcoded engineer pet grouping

local ktStanceToIcon = 
{
	[0] = "",
	[1] = "ClientSprites:Icon_ArchetypeUI_CRB_Tank",
	[2] = "ClientSprites:Icon_ArchetypeUI_CRB_Guard",
	[3] = "ClientSprites:Icon_ArchetypeUI_CRB_Vehicle",
	[4] = "ClientSprites:Icon_ArchetypeUI_CRB_OffensiveHealer",
	[5] = "ClientSprites:Icon_ArchetypeUI_CRB_Bruiser",
}

local ktStanceToString = 
{
	[0] = "",
	[1] = "Engineer_PetAggressive",
	[2] = "Engineer_PetDefensive",
	[3] = "Engineer_PetPassive",
	[4] = "Engineer_PetAssist",
	[5] = "Engineer_PetStay",
}

function PvP_Engineer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
	
	o.tLeftEngineerPet = nil
	o.tRightEngineerPet = nil
	
    return o
end

function PvP_Engineer:Init()
    Apollo.RegisterAddon(self)
end

function PvP_Engineer:OnLoad()
	Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	
	if GameLib:GetPlayerUnit() then
		self:OnCharacterCreated()
	end
end

function PvP_Engineer:OnCharacterCreated()
local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer then
		return
	elseif unitPlayer:GetClassId() ~= GameLib.CodeEnumClass.Engineer then
		if self.wndMain then
			self.wndMain:Destroy()
		end
		return
	end

	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnEnteredCombat", self)
	Apollo.RegisterEventHandler("VarChange_FrameCount", 		"OnFrameUpdate", self)
	Apollo.RegisterEventHandler("ShowActionBarShortcut", 		"OnShowActionBarShortcut", self)
	Apollo.RegisterTimerHandler("OutOfCombatFade", 				"OnOutOfCombatFade", self)
	Apollo.RegisterTimerHandler("CombatTimer",					"OnCombatTimer", self)
	Apollo.CreateTimer("OutOfCombatFade", 1.250, false)
	Apollo.CreateTimer("CombatTimer", 0.1, false)
	
	self.nFadeLevel = 0
	self.nCombatTimer = 0.0
    self.wndMain = Apollo.LoadForm("PvP_Engineer.xml", "PvP_EngineerForm", "FixedHudStratum", self)
	self.wndMain:FindChild("BaseProgressSliderText"):SetData(0)
	self.wndMain:FindChild("StanceMenuOpenerBtn"):AttachWindow(self.wndMain:FindChild("StanceMenuBG"))
	self.wndMain:ToFront()

	for nIdx = 1, 5 do
		self.wndMain:FindChild("Stance"..nIdx):SetData(nIdx)
	end

	local nFrameLeft,nFrameTop,nFrameRight,nFrameBottom = self.wndMain:FindChild("BaseProgressFrame"):GetAnchorOffsets()
	local nSliderLeft,nSliderTop,nSliderRight,nSliderBottom = self.wndMain:FindChild("BaseProgressSlider"):GetAnchorOffsets()

	self.nUseableProgWidth = nFrameRight-nFrameLeft - (nSliderRight-nSliderLeft)
	self.nSliderWidth = nSliderRight-nSliderLeft
	self.nHealthWarn = 0.4
	self.nHealthWarn2 = 0.6

	self:OnShowActionBarShortcut(1, IsActionBarSetVisible(1)) -- Show petbar if active from reloadui/load screen
end

function PvP_Engineer:OnFrameUpdate()
	if not self.wndMain:IsValid() then
		return
	end
	
	local unitPlayer = GameLib.GetPlayerUnit()
	
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetRect() -- legacy code
	--Apollo.SetGlobalAnchor("CastingBarBottom", 0.0, nTop - 15, true)
	
	-- Resource 1 (Volatility)
	local nResourceMax = unitPlayer:GetMaxResource(1)
	local nResourceCurrent = unitPlayer:GetResource(1)
	local nResourcePercent = nResourceCurrent/nResourceMax
	--local nOffset = nResourcePercent * self.nUseableProgWidth
	--self.wndMain:FindChild("BaseProgressSlider"):SetAnchorOffsets(nOffset, 0, nOffset + self.nSliderWidth, 0)
	self.wndMain:FindChild("BaseProgressWarning"):Show(nResourceCurrent == nResourceMax)
	
	if not self.bInCombat and nResourceCurrent == 0 then
		self.wndMain:FindChild("BaseProgressSliderText"):SetData(0)
		self.wndMain:FindChild("BaseProgressSliderText"):SetText("0%")
	else
		self.wndMain:FindChild("BaseProgressSliderText"):SetData(nResourcePercent)
		self.wndMain:FindChild("BaseProgressSliderText"):SetText(nResourcePercent * 100 .. "%")
		if self.bInCombat then
			self.wndMain:FindChild("BaseProgressSliderText"):SetTextColor(ApolloColor.new(1, 1, 1 - nResourcePercent, 1))
		end
	end
	
	-- Pets
	local tPetData = GameLib.GetPlayerPets()
	local wndCurrSide
	local ePetStance
	
	if not tPetData or #tPetData == 0 then
		self.wndMain:FindChild("PetContainerL"):Show(false)
		self.wndMain:FindChild("PetContainerR"):Show(false)
	else		
		for key, tPetUnit in pairs(tPetData) do
			if tPetUnit:GetUnitRaceId() == knEngineerPetGroupId then
				if (not self.tLeftEngineerPet or not self.tLeftEngineerPet:IsValid()) and tPetUnit ~= self.tRightEngineerPet then
					self.tLeftEngineerPet = tPetUnit
				elseif tPetUnit ~= self.tLeftEngineerPet and (not self.tRightEngineerPet or not self.tRightEngineerPet:IsValid()) then
					self.tRightEngineerPet = tPetUnit
				end
			end
		end
		
		wndCurrSide = self.wndMain:FindChild("PetContainerL")
		if self.tLeftEngineerPet and self.tLeftEngineerPet:IsValid() then
			wndCurrSide:Show(true)
			wndCurrSide:SetData(self.tLeftEngineerPet)
			self:DoHPAndShieldResizing(wndCurrSide:FindChild("PetVitals"), self.tLeftEngineerPet)
			
			ePetStance = Pet_GetStance(self.tLeftEngineerPet:GetId())
		else
			wndCurrSide:Show(false)
		end
		
		wndCurrSide = self.wndMain:FindChild("PetContainerR")
		if self.tRightEngineerPet and self.tRightEngineerPet:IsValid() then
			wndCurrSide:Show(true)
			wndCurrSide:SetData(self.tRightEngineerPet)
			self:DoHPAndShieldResizing(wndCurrSide:FindChild("PetVitals"), self.tRightEngineerPet)
			
			ePetStance = Pet_GetStance(self.tRightEngineerPet:GetId())
		else
			wndCurrSide:Show(false)
		end
		
		wndCurrSide = self.wndMain:FindChild("CurrentStanceIcon")
		if self.tLeftEngineerPet:IsValid() or self.tRightEngineerPet:IsValid() then
			wndCurrSide:SetSprite(ktStanceToIcon[ePetStance])
			wndCurrSide:SetTooltip(string.format("<P Font=\"CRB_InterfaceSmall\">%s</P><P Font=\"CRB_InterfaceSmall\">%s</P>", String_GetWeaselString(Apollo.GetString("Engineer_CurrentStance"), Apollo.GetString(ktStanceToString[ePetStance])), Apollo.GetString("Engineer_ClickToSelect")))
		end
	end
end

function PvP_Engineer:OnStanceBtn(wndHandler, wndControl)
	Pet_SetStance(0, tonumber(wndHandler:GetData())) -- First arg is for the pet ID, 0 means all engineer pets
	self.wndMain:FindChild("StanceMenuOpenerBtn"):SetCheck(false)
end

function PvP_Engineer:OnShowActionBarShortcut(nWhichBar, bIsVisible, nNumShortcuts)
	if nWhichBar ~= 1 or not self.wndMain or not self.wndMain:IsValid() then -- 1 is hardcoded to be the engineer pet bar
		return
	end
	self.wndMain:FindChild("PetBarContainer"):Show(bIsVisible)
	self.wndMain:FindChild("BaseBGAccents"):Show(not bIsVisible)
end

function PvP_Engineer:OnPetContainerMouseUp(wndHandler, wndControl) -- PetContainerL and PetContainerR
	GameLib.SetTargetUnit(wndHandler:GetData())
end

-----------------------------------------------------------------------------------------------
-- Combat Fading
-----------------------------------------------------------------------------------------------

function PvP_Engineer:OnEnteredCombat(unitPlayer, bInCombat)
	if unitPlayer ~= GameLib.GetPlayerUnit() or not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	self.bInCombat = bInCombat

	if bInCombat then
		local nResourcePercent = self.wndMain:FindChild("BaseProgressSliderText"):GetData()
		self.wndMain:FindChild("BaseProgressSliderText"):SetTextColor(ApolloColor.new(1, 1, 1 - nResourcePercent, 1))
		
		self.nFadeLevel = 0
		self.nCombatTimer = 5.0
		Apollo.StopTimer("OutOfCombatFade")
		Apollo.StopTimer("CombatTimer")
		self.wndMain:FindChild("CombatTimerText"):SetText("5.0")
		--self.wndMain:FindChild("CombatTimer"):SetTextColor(ApolloColor.new(1, 1, 1 - nResourcePercent, 1 - (0.25 * self.nFadeLevel)))
	else
		self.wndMain:FindChild("CombatTimerText"):SetText("5.0")

		Apollo.StartTimer("OutOfCombatFade")
		Apollo.StartTimer("CombatTimer")
		
				
		--for i=5,0,-1 do 
		--self.wndMain:FindChild("CombatTimerText"):SetText(i)
		--end

	end
end

function PvP_Engineer:OnOutOfCombatFade()
	if self.wndMain and self.wndMain:IsValid() then
		local nResourcePercent = self.wndMain:FindChild("BaseProgressSliderText"):GetData()
		self.nFadeLevel = self.nFadeLevel + 1
		self.wndMain:FindChild("BaseProgressSliderText"):SetTextColor(ApolloColor.new(1, 1, 1 - nResourcePercent, 1 - (0.25 * self.nFadeLevel)))
	end
	if self.nFadeLevel <= 3 then
		--Apollo.CreateTimer("OutOfCombatFade", 1.25, false)
	end
end


function PvP_Engineer:OnCombatTimer()
	self.wndMain:FindChild("CombatTimerText"):SetText(self.nCombatTimer)
	self.nCombatTimer = self.nCombatTimer - 0.1
	if (self.nCombatTimer > 0) then
		Apollo.CreateTimer("CombatTimer", 0.1, false)
	else 
		self.wndMain:FindChild("CombatTimerText"):SetText("0.0")
	end
end
-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function PvP_Engineer:DoHPAndShieldResizing(wndBtnParent, unitPet)
	if not unitPet then
		return
	end

	local nHealthCurr = unitPet:GetHealth()
	local nHealthMax = unitPet:GetMaxHealth()
	local nShieldCurr = unitPet:GetShieldCapacity()
	local nShieldMax = unitPet:GetShieldCapacityMax()
	local nAbsorbCurr = 0
	local nAbsorbMax = unitPet:GetAbsorptionMax()
	if nAbsorbMax > 0 then
		nAbsorbCurr = unitPet:GetAbsorptionValue() -- Since it doesn'nFrameTop clear when the buff drops off
	end
	local nTotalMax = nHealthMax + nShieldMax + nAbsorbMax

	-- Bars
	wndBtnParent:FindChild("HealthBar"):Show(nHealthCurr > 0 and nHealthMax > 0)
	wndBtnParent:FindChild("MaxAbsorbBar"):Show(nHealthCurr > 0 and nAbsorbMax > 0)
	wndBtnParent:FindChild("MaxShieldBar"):Show(nHealthCurr > 0 and nShieldMax > 0)
	wndBtnParent:FindChild("CurrShieldBar"):Show(nHealthCurr > 0 and nShieldMax > 0)

	wndBtnParent:FindChild("CurrShieldBar"):SetMax(nShieldMax)
	wndBtnParent:FindChild("CurrShieldBar"):SetProgress(nShieldCurr)
	wndBtnParent:FindChild("CurrShieldBar"):EnableGlow((wndBtnParent:FindChild("CurrShieldBar"):GetWidth() * nShieldCurr/nShieldMax) > 4)
	wndBtnParent:FindChild("CurrAbsorbBar"):SetMax(nAbsorbMax)
	wndBtnParent:FindChild("CurrAbsorbBar"):SetProgress(nAbsorbCurr)
	wndBtnParent:FindChild("CurrAbsorbBar"):EnableGlow((wndBtnParent:FindChild("CurrAbsorbBar"):GetWidth() * nAbsorbCurr/nAbsorbMax) > 4)
	wndBtnParent:FindChild("HealthBarEdgeGlow"):Show(nShieldMax <= 0)

	-- Health Bar Color
	if (nHealthCurr / nHealthMax) < self.nHealthWarn then
		wndBtnParent:FindChild("HealthBar"):SetSprite("sprRaid_HealthProgBar_Red")
		wndBtnParent:FindChild("HealthBar"):FindChild("HealthBarEdgeGlow"):SetSprite("sprRaid_HealthEdgeGlow_Red")
	elseif (nHealthCurr / nHealthMax) < self.nHealthWarn2 then
		wndBtnParent:FindChild("HealthBar"):SetSprite("sprRaid_HealthProgBar_Orange")
		wndBtnParent:FindChild("HealthBar"):FindChild("HealthBarEdgeGlow"):SetSprite("sprRaid_HealthEdgeGlow_Orange")
	else
		wndBtnParent:FindChild("HealthBar"):SetSprite("sprRaid_HealthProgBar_Green")
		wndBtnParent:FindChild("HealthBar"):FindChild("HealthBarEdgeGlow"):SetSprite("sprRaid_HealthEdgeGlow_Green")
	end

	-- Scaling
	
	local nWidth = self.wndMain:FindChild("PetVitals"):GetWidth() - 2
	local nArtOffset = 2
	local nPointHealthRight = nWidth * (nHealthCurr / nTotalMax)
	local nPointShieldRight = nWidth * ((nHealthCurr + nShieldMax) / nTotalMax)
	local nPointAbsorbRight = nWidth * ((nHealthCurr + nShieldMax + nAbsorbMax) / nTotalMax)

	local nFrameLeft,nFrameTop,nFrameRight,nFrameBottom = wndBtnParent:FindChild("HealthBar"):GetAnchorOffsets()
	wndBtnParent:FindChild("HealthBar"):SetAnchorOffsets(nFrameLeft, nFrameTop, nPointHealthRight, nFrameBottom)
	wndBtnParent:FindChild("MaxShieldBar"):SetAnchorOffsets(nPointHealthRight - nArtOffset, nFrameTop, nPointShieldRight, nFrameBottom)
	wndBtnParent:FindChild("MaxAbsorbBar"):SetAnchorOffsets(nPointShieldRight - nArtOffset, nFrameTop, nPointAbsorbRight, nFrameBottom)

	-- Engineer UI only
	wndBtnParent:FindChild("PetHealthBarText"):SetText(math.max(1, math.floor((nHealthCurr + nShieldCurr + nAbsorbCurr) / nTotalMax * 100)).."%")
	wndBtnParent:SetTooltip(string.format("<P Font=\"CRB_InterfaceSmall\">%s %s/%s (%s)</P>", unitPet:GetName(), nHealthCurr, nHealthMax, nShieldCurr + nAbsorbCurr))
end

function PvP_Engineer:OnGeneratePetCommandTooltip(wndControl, wndHandler, eType, arg1, arg2)
	local xml = nil
	if eType == Tooltip.TooltipGenerateType_PetCommand then
		xml = XmlDoc.new()
		xml:AddLine(arg2)
		wndControl:SetTooltipDoc(xml)
	end
end

local PvP_EngineerInst = PvP_Engineer:new()
PvP_EngineerInst:Init()
