-----------------------------------------------------------------------------------------------
-- Client Lua Script for EsperResource
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local EsperResource = {}

function EsperResource:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function EsperResource:Init()
    Apollo.RegisterAddon(self)
end

function EsperResource:OnLoad()
	Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	
	if GameLib.GetPlayerUnit() then
		self:OnCharacterCreated()
	end
end

function EsperResource:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil then
		return
	elseif unitPlayer:GetClassId() ~= GameLib.CodeEnumClass.Esper then
		if self.wndMain then
			self.wndMain:Destroy()
		end
		return
	end
	
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrameUpdate", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 	"OnEnteredCombat", self)
	Apollo.RegisterTimerHandler("EsperResource_FadeTimer", "OnFadeTimer", self)
	Apollo.RegisterTimerHandler("CombatTimer", "OnCombatTimer", self)
	
	Apollo.CreateTimer("EsperResource_FadeTimer", 2.000, false)
	Apollo.CreateTimer("CombatTimer", 0.1, false)
	
	self.nFadeLevel = 0
	self.nCombatTimer = 0.0

    self.wndMain = Apollo.LoadForm("PvP_EsperResource.xml", "EsperResourceForm", "FixedHudStratum", self)
	self.tComboPieces =
	{
		self.wndMain:FindChild("ComboSolid1"),
		self.wndMain:FindChild("ComboSolid2"),
		self.wndMain:FindChild("ComboSolid3"),
		self.wndMain:FindChild("ComboSolid4"),
		self.wndMain:FindChild("ComboSolid5")
	}
	
	self.wndMain:FindChild("ComboNumber"):SetTooltip(string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", Apollo.GetString("CRB_EsperResource")))
	self.wndMain:FindChild("EsperResource"):SetTooltip(string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", Apollo.GetString("CRB_EsperResource")))
end

function EsperResource:OnFrameUpdate()
	if not self.wndMain:IsValid() then
		return
	end
	
	local unitPlayer = GameLib.GetPlayerUnit()
	
	-- TODO REMOVE and replace
	local nLeft0, nTop0, nRight0, nBottom0 = self.wndMain:GetRect()
	Apollo.SetGlobalAnchor("CastingBarBottom", 0.0, nTop0 - 15, true)

	-- Mana
	local nManaMax = math.floor(unitPlayer:GetMaxMana())
	local nManaCurrent = math.floor(unitPlayer:GetMana())
	self.wndMain:FindChild("ManaProgressBar"):SetMax(nManaMax)
	self.wndMain:FindChild("ManaProgressBar"):SetProgress(nManaCurrent)
	self.wndMain:FindChild("ManaProgressBar"):SetTooltip(string.format("Focus: %s/%s", nManaCurrent, nManaMax)) -- TODO String for Translation
	self.wndMain:FindChild("ManaProgressText"):SetText(math.floor(nManaCurrent / nManaMax * 100).."%")
	self.wndMain:FindChild("ManaProgressText1"):SetText(math.floor(nManaCurrent / nManaMax * 100).."%")

	-- Animation
	local nComboMax = unitPlayer:GetMaxResource(1)
	local nComboCurrent = unitPlayer:GetResource(1)
	for idx = 5, 1, -1 do
		-- Death animation
		if nComboCurrent == 0 and self.wndMain:FindChild("ComboSolid"..idx):IsVisible() then
			self.wndMain:FindChild("ComboGlowFlash"):SetSprite("CRB_Esper:sprEsperResource_CompFade"..idx)
			break
		end
		
		-- Birth Animation
		if nComboCurrent >= idx and not self.wndMain:FindChild("ComboSolid"..idx):IsVisible() then
			self.wndMain:FindChild("ComboGlowFlash"):SetSprite("CRB_Esper:sprEsperResource_Glow"..idx)
			break
		end
	end
	
	-- Combo Points
	self.wndMain:FindChild("ComboSolid1"):Show(nComboCurrent >= 1)
	self.wndMain:FindChild("ComboSolid2"):Show(nComboCurrent >= 2)
	self.wndMain:FindChild("ComboSolid3"):Show(nComboCurrent >= 3)
	self.wndMain:FindChild("ComboSolid4"):Show(nComboCurrent >= 4)
	self.wndMain:FindChild("ComboSolid5"):Show(nComboCurrent >= 5)
	self.wndMain:FindChild("ComboNumber"):SetSprite("CRB_Esper:sprEsperResource_Number"..nComboCurrent)
	self.wndMain:FindChild("ComboBG"):SetSprite(nComboCurrent == 0 and "CRB_Esper:sprEsperResource_BG0" or "CRB_Esper:sprEsperResource_BG1")

	
	if nComboCurrent == 5 then
		self.wndMain:FindChild("EsperResource"):SetTextColor("green")
		self.wndMain:FindChild("EsperResource"):SetText("5")
	elseif nComboCurrent == 4 then
		self.wndMain:FindChild("EsperResource"):SetTextColor("green")
		self.wndMain:FindChild("EsperResource"):SetText("4")
	elseif nComboCurrent == 3 then
		self.wndMain:FindChild("EsperResource"):SetTextColor("green")
		self.wndMain:FindChild("EsperResource"):SetText("3")
	elseif nComboCurrent == 2 then
		self.wndMain:FindChild("EsperResource"):SetTextColor("green")
		self.wndMain:FindChild("EsperResource"):SetText("2")
	elseif nComboCurrent == 1 then
		self.wndMain:FindChild("EsperResource"):SetTextColor("green")
		self.wndMain:FindChild("EsperResource"):SetText("1")
	elseif nComboCurrent == 0 then
		self.wndMain:FindChild("EsperResource"):SetTextColor("red")
		self.wndMain:FindChild("EsperResource"):SetText("0")
	end
	
end




function EsperResource:OnEnteredCombat(unit, bInCombat)
	--if self.wndMain and self.wndMain:IsValid() and unit == GameLib.GetPlayerUnit() then
		self.wndMain:FindChild("CombatIndicatorL"):Show(bInCombat)
		self.wndMain:FindChild("CombatIndicatorR"):Show(bInCombat)
		
		self.bInCombat = bInCombat
		
		if bInCombat then
			self.nCombatTimer = 10.0
			self.nFadeLevel = 0
			
			Apollo.StopTimer("EsperResource_FadeTimer")
			Apollo.StopTimer("CombatTimer")
			
			self.wndMain:FindChild("CombatTimerText"):SetText("10.0")
			
			for idx, wndCurr in pairs(self.tComboPieces) do
				wndCurr:SetBGColor(CColor.new(1, 1, 1, 1))
			end
		else
			Apollo.StartTimer("EsperResource_FadeTimer")
			Apollo.StartTimer("CombatTimer")
	
			self.nFadeLevel = 1
			for idx, wndCurr in pairs(self.tComboPieces) do
				wndCurr:SetBGColor(CColor.new(1, 1, 1, 1 - (0.165 * self.nFadeLevel)))
			end
		end
	--end
end

function EsperResource:OnCombatTimer()
self.wndMain:FindChild("CombatTimerText"):SetText(self.nCombatTimer)
self.nCombatTimer = self.nCombatTimer - 0.1
	if (self.nCombatTimer > 0) then
		Apollo.StartTimer("CombatTimer", 0.1, false)
	else
		self.wndMain:FindChild("CombatTimerText"):SetText("0.0")
	end
end

function EsperResource:OnFadeTimer()
	self.nFadeLevel = self.nFadeLevel + 1
	for idx, wndCurr in pairs(self.tComboPieces) do
		wndCurr:SetBGColor(CColor.new(1, 1, 1, 1 - (0.165 * self.nFadeLevel)))
	end
	
	if self.nFadeLevel < 5 then
		Apollo.StartTimer("EsperResource_FadeTimer")
	end
end

local EsperResourceInst = EsperResource:new()
EsperResourceInst:Init()
