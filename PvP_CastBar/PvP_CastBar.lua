-----------------------------------------------------------------------------------------------
-- Client Lua Script for CastBar
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Sound"
require "GameLib"
require "Spell"

local CastBar 				= {}
local kstrOpSpellCircleFont = "CRB_HeaderLarge_O"
local kcrOpSpellCurrent 	= "ffffffff"
local kcrOpSpellMax 		= "ffa0a0a0"
local knMaxTiers 			= 5 --max tiers a charge-up spell can have

function CastBar:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.bIsShown = false
	return o
end

function CastBar:Init()
	Apollo.RegisterAddon(self)
end

function CastBar:OnLoad()
	

	-- Spell Threshold events
	Apollo.RegisterEventHandler("StartSpellThreshold", 	"OnStartSpellThreshold", self)
	Apollo.RegisterEventHandler("ClearSpellThreshold", 	"OnClearSpellThreshold", self)
	Apollo.RegisterEventHandler("UpdateSpellThreshold", "OnUpdateSpellThreshold", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 	"OnTutorial_RequestUIAnchor", self)
	
	Apollo.RegisterTimerHandler("UpdateCastBarTimer", 	"OnUpdate", self)
	
	self.wndCastFrame 		= Apollo.LoadForm("PvP_CastBar.xml", "CastBarFrame", "InWorldHudStratum", self)
	self.wndOppFrame 		= Apollo.LoadForm("PvP_CastBar.xml", "WindowOfOppFrame", "InWorldHudStratum", self)
	self.wndOppBar 			= self.wndOppFrame:FindChild("SingleBar")
	self.wndOppBarCircle 	= self.wndOppFrame:FindChild("CircleBar")
	self.wndOppBarTiered 	= self.wndOppFrame:FindChild("SingleBarTiered")
	
	self.wndOppFrame:FindChild("Fill"):SetMax(1)
	self.tCurrentOpSpell = nil

	self.arTierSprites 	= {}
	self.tTierMarks 	= {}
	for idx = 1, knMaxTiers do
		local tSprites = 
		{
			strFillSprite 	= "CRB_NameplateSprites:sprNp_HealthBarFriendly" .. idx,
			strCapSprite 	= "CRB_CastBarSprites:sprCB_Cap_PHR_" .. idx,
			strMarkEmpty 	= "CRB_CastBarSprites:sprCB_PHRMarkerEmpty_" .. idx,
			strMarkFull 	= "CRB_CastBarSprites:sprCB_PHRMarkerFull_" .. idx,
		}
		table.insert(self.arTierSprites, idx, tSprites)

		local wndTierItem = Apollo.LoadForm("PvP_CastBar.xml", "TierItem", self.wndOppBarTiered:FindChild("TierMarkContainer"), self)
		wndTierItem:Show(false)
		table.insert(self.tTierMarks, idx, wndTierItem)
	end

	-- Buff and Debuff Bar
	self.wndBeneBuffBar = Apollo.LoadForm("PvP_CastBar.xml", "BeneBuffBar", "InWorldHudStratum", self)
	self.wndHarmBuffBar = Apollo.LoadForm("PvP_CastBar.xml", "HarmBuffBar", "InWorldHudStratum", self)
	
	self.nCastLeft, self.nCastTop, self.nCastRight, self.nCastBottom = self.wndCastFrame:GetAnchorOffsets()
	self.nOppLeft, self.nOppTop, self.nOppRight, self.nOppBottom = self.wndOppFrame:GetAnchorOffsets()
	
	Apollo.CreateTimer("UpdateCastBarTimer", 0.033, true)
	Apollo.StartTimer("UpdateCastBarTimer")
end

function CastBar:OnUpdate()
	local unitPlayer = GameLib.GetPlayerUnit()
	local nRectLeft, nRectTop, nRectRight, nRectBottom = self.wndCastFrame:GetRect()

	if not unitPlayer then
		return
	end

	if self.tCurrentOpSpell ~= nil then
		if self.tCurrentOpSpell.eCastMethod == Spell.CodeEnumCastMethod.RapidTap then
			self:DrawSingleBarFrameCircle(self.wndOppBarCircle)
		elseif self.tCurrentOpSpell.eCastMethod == Spell.CodeEnumCastMethod.PressHold then
			self:DrawSingleBarFrame(self.wndOppBar)
		elseif self.tCurrentOpSpell.eCastMethod == Spell.CodeEnumCastMethod.ChargeRelease then
			self:DrawSingleBarFrameTiered(self.wndOppBarTiered)
		end
	end

	-- Casting Bar Update
	local bShowCasting = false
	local bEnableGlow = false
	local nZone = 0
	local nMaxZone = 0
	local fDuration = 0
	local fElapsed = 0
	local strSpellName = ""
	local nElapsed = 0
	local eType = Unit.CodeEnumCastBarType.None

	if unitPlayer:ShouldShowCastBar() then
		self.bIsShown = true
		eType = unitPlayer:GetCastBarType()
		if eType == Unit.CodeEnumCastBarType.Normal then
			self.wndCastFrame:FindChild("CastingProgress"):SetFullSprite("CRB_NameplateSprites:sprNp_HealthBarFriendly")

			bShowCasting = true
			bEnableGlow = true
			nZone = 0
			nMaxZone = 1
			fDuration = unitPlayer:GetCastDuration()
			fElapsed = unitPlayer:GetCastElapsed()

			self.wndCastFrame:FindChild("CastingProgress"):SetTickLocations(0, 100, 200, 300)

			strSpellName = unitPlayer:GetCastName()
		end
		Apollo.SetGlobalAnchor("CenterTextBottom", 0.0, nRectTop, true)
	else
		self.bIsShown = false
		self.wndCastFrame:Show(false)
		Apollo.SetGlobalAnchor("CenterTextBottom", 0.0, nRectBottom, true)
	end

	if bShowCasting and fDuration > 0 and nMaxZone > 0 then
		self.wndCastFrame:Show(bShowCasting)

		self.wndCastFrame:FindChild("CastingProgress"):SetMax(fDuration)
		self.wndCastFrame:FindChild("CastingProgress"):SetProgress(fElapsed)
		self.wndCastFrame:FindChild("CastingProgress"):EnableGlow(bEnableGlow)
		self.wndCastFrame:FindChild("CastingProgressText"):SetText(strSpellName)
	end

	-- reposition if needed
	if self.wndCastFrame:IsShown() and self.wndOppFrame:IsShown() then
		local nLeft, nTop, nRight, nBottom = self.wndOppFrame:GetAnchorOffsets()
		if nBottom ~= self.nCastTop then
			self.wndOppFrame:SetAnchorOffsets(self.nOppLeft, self.nOppTop + self.nCastTop, self.nOppRight, self.nOppBottom + self.nCastTop)
		end
	elseif self.wndOppFrame:IsShown() then
		local nLeft,nTop,nRight,nBottom = self.wndOppFrame:GetAnchorOffsets()
		if nBottom ~= self.nOppBottom then
			self.wndOppFrame:SetAnchorOffsets(self.nOppLeft, self.nOppTop, self.nOppRight, self.nOppBottom)
		end	
	
	end

	-- Buff Icons
	if unitPlayer ~= nil then
		self:SetUnitForBuffIcons(unitPlayer)
	end
end

function CastBar:DrawSingleBarFrame(wnd)
	local fPercentDone = GameLib.GetSpellThresholdTimePrcntDone(self.tCurrentOpSpell.id)
	wnd:FindChild("Fill"):SetMax(1)	
	wnd:FindChild("Fill"):SetProgress(fPercentDone)
	
	local strExtra = Apollo.GetString("CastBar_Press")
	if Apollo.GetConsoleVariable("spell.useButtonDownForAbilities") then
		strExtra = Apollo.GetString("CastBar_Hold")
	end
	
	wnd:FindChild("Label"):SetText(String_GetWeaselString(Apollo.GetString("CastBar_ComplexLabel"), self.tCurrentOpSpell.strName, strExtra))
end

function CastBar:DrawSingleBarFrameCircle(wnd)
	local fPercentDone = GameLib.GetSpellThresholdTimePrcntDone(self.tCurrentOpSpell.id)
	wnd:FindChild("Fill"):SetMax(1)
	wnd:FindChild("Fill"):SetProgress(1 - fPercentDone)
	local strTier = string.format("<T Font=\"%s\" TextColor=\"%s\">%s</T>", kstrOpSpellCircleFont, kcrOpSpellCurrent, self.tCurrentOpSpell.nCurrentTier)
	local strMax = string.format("<T Font=\"%s\" TextColor=\"%s\">%s</T>", kstrOpSpellCircleFont, kcrOpSpellMax, self.tCurrentOpSpell.nMaxTier)
	wnd:FindChild("Label"):SetText(string.format("<P Align=\"Center\">%s/%s</P>", strTier, strMax))
	wnd:FindChild("NameLabel"):SetText(self.tCurrentOpSpell.strName)
end

function CastBar:DrawSingleBarFrameTiered(wnd)
	local fPercentDone = GameLib.GetSpellThresholdTimePrcntDone(self.tCurrentOpSpell.id)
	wnd:FindChild("Fill"):SetFillSprite("CRB_NameplateSprites:sprNp_HealthBarFriendly")
	wnd:FindChild("Fill"):SetGlowSprite("")

	if self.tCurrentOpSpell.nCurrentTier > 1 then
		wnd:FindChild("FillBacker"):SetSprite("ClientSprites:BlackFill")
	else
		wnd:FindChild("FillBacker"):SetSprite("ClientSprites:BlackFill")
	end

	wnd:FindChild("Fill"):SetMax(1)

	if self.tCurrentOpSpell.nCurrentTier == self.tCurrentOpSpell.nMaxTier then
		wnd:FindChild("Fill"):SetProgress(.99) -- last tier would read as empty; this fixes it
		wnd:FindChild("Fill"):SetGlowSprite("")
	else
		wnd:FindChild("Fill"):SetProgress(fPercentDone)
	end
	
	local strExtra = Apollo.GetString("CastBar_Press")
	if Apollo.GetConsoleVariable("spell.useButtonDownForAbilities") then
		strExtra = Apollo.GetString("CastBar_Hold")
	end

	wnd:FindChild("AlertFlash"):Show(self.tCurrentOpSpell.nCurrentTier == self.tCurrentOpSpell.nMaxTier)
	wnd:FindChild("Label"):SetText(String_GetWeaselString(Apollo.GetString("CastBar_ComplexLabel"), self.tCurrentOpSpell.strName, strExtra)) -- todo: Set the name once we have a function for it
end

------------------------------------------------------------------------
-- New Buff and Debuff Lua Code
------------------------------------------------------------------------

function CastBar:OnGenerateTooltip(wndHandler, wndControl, eType, spl)
	if wndControl == wndHandler then
		return nil
	end
	Tooltip.GetBuffTooltipForm(self, wndControl, spl)
end

function CastBar:SetUnitForBuffIcons(unit)
	self.wndBeneBuffBar:SetUnit(unit)
	self.wndHarmBuffBar:SetUnit(unit)
end

------------------------------------------------------------------------
-- Spell Threshold Lua Code
------------------------------------------------------------------------

function CastBar:OnStartSpellThreshold(idSpell, nMaxThresholds, eCastMethod) -- also fires on tier change
	if self.tCurrentOpSpell ~= nil and idSpell == self.tCurrentOpSpell.id then return end -- we're getting an update event, ignore this one

	self.tCurrentOpSpell = {}
	local splObject = GameLib.GetSpell(idSpell)

	self.tCurrentOpSpell.id = idSpell
	self.tCurrentOpSpell.nCurrentTier = 1
	self.tCurrentOpSpell.nMaxTier = nMaxThresholds
	self.tCurrentOpSpell.eCastMethod = eCastMethod
	self.tCurrentOpSpell.strName = splObject:GetName()

	-- hide all UI elements
	self.wndOppBarCircle:Show(false)
	self.wndOppBar:Show(false)
	for idx = 1, self.tCurrentOpSpell.nMaxTier do
		self.tTierMarks[idx]:Show(false)
		self.tTierMarks[idx]:FindChild("MarkerBacker"):SetSprite(self.arTierSprites[idx].strMarkEmpty)
		self.tTierMarks[idx]:FindChild("Marker"):SetSprite("")
	end
	self.wndOppBarTiered:Show(false)

	-- restart the progress bar; we'll have to add enum types as they come online
	if self.tCurrentOpSpell.eCastMethod == Spell.CodeEnumCastMethod.RapidTap then
		self.wndOppBarCircle:Show(true)
	elseif self.tCurrentOpSpell.eCastMethod == Spell.CodeEnumCastMethod.PressHold then
		self.wndOppBar:Show(true)
	elseif self.tCurrentOpSpell.eCastMethod == Spell.CodeEnumCastMethod.ChargeRelease then
		-- set up the tier marks
		for idx = 1, self.tCurrentOpSpell.nMaxTier do
			self.tTierMarks[idx]:Show(true)
			self.tTierMarks[idx]:FindChild("MarkerBacker"):SetSprite(self.arTierSprites[idx].strMarkEmpty)
			self.tTierMarks[idx]:FindChild("Marker"):SetSprite("")
		end

		self.wndOppBarTiered:FindChild("TierMarkContainer"):ArrangeChildrenHorz(1)

		self.wndOppBarTiered:Show(true)
	end

	self.wndOppFrame:Show(true)

	-- Do the initial update so the first tier is lit up correctly
	self:OnUpdateSpellThreshold(idSpell, self.tCurrentOpSpell.nCurrentTier)
end

function CastBar:OnUpdateSpellThreshold(idSpell, nNewThreshold) -- Updates when P/H/R changes tier or RT tap is performed
	if self.tCurrentOpSpell == nil or idSpell ~= self.tCurrentOpSpell.id then return end

	self.tCurrentOpSpell.nCurrentTier = nNewThreshold
	self.tTierMarks[nNewThreshold]:FindChild("Marker"):SetSprite("CRB_NameplateSprites:sprNp_HealthBarFriendly")
	self.tTierMarks[nNewThreshold]:FindChild("Flash"):SetSprite("CRB_CastBarSprites:sprCB_PHRMarkerFlash")
	self.wndOppBarTiered:FindChild("AlertFlash2"):SetSprite("")
	self.wndOppBarCircle:FindChild("AlertFlash"):SetSprite("ClientSprites:BlackFill")
end

function CastBar:OnClearSpellThreshold(idSpell)
	if self.tCurrentOpSpell ~= nil and idSpell ~= self.tCurrentOpSpell.id then return end -- different spell got loaded up before the previous was cleared. this is valid.

	self.wndOppFrame:Show(false)
	self.wndOppBar:Show(false)
	self.wndOppBarCircle:Show(false)
	self.wndOppBarTiered:Show(false)
	self.wndOppBarTiered:FindChild("AlertFlash2"):SetSprite("")
	self.wndOppBarCircle:FindChild("AlertFlash"):SetSprite("")
	self.tCurrentOpSpell = nil
	for i = 1, knMaxTiers do
		self.tTierMarks[i]:Show(false)
	end
end

function CastBar:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	if eAnchor == GameLib.CodeEnumTutorialAnchor.BuffFrame then
		local tRect = {}
		tRect.l, tRect.t, tRect.r, tRect.b = self.wndBeneBuffBar:GetRect()
		Event_FireGenericEvent("Tutorial_RequestUIAnchorResponse", eAnchor, idTutorial, strPopupText, tRect)
	end
end

local CastBarInstance = CastBar:new()
CastBarInstance:Init()
