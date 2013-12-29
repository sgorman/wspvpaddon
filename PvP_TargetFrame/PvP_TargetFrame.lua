require "Window"
require "Unit"
require "GameLib"
require "Apollo"
require "PathMission"
require "P2PTrading"

local TargetFrame = {}
local knClusterFrameWidth 					= 68 -- MUST MATCH XML
local knClusterFrameHeight 					= 71 -- MUST MATCH XML
local knPrimaryFrameWidth 					= 344 -- MUST MATCH XML
local knPrimaryFrameHeight 					= 104 -- MUST MATCH XML
local knPrimaryFrameOffsetVert 				= 15
local knPrimaryFrameOffsetVertRewards 		= 39
local knClusterFrameVertOffset 				= 10 -- how far down to move the cluster members
local knClusterFrameHorzOffsetShort 		= 35 -- horzizontal cluster offset for short bar
local knClusterFrameHorzOffsetLong 			= 10 -- horizontal cluster offset for long bars
local knRewardAnchorVertOffset 				= 13 -- half the height plus spacing for reward icons
local knRankedFrameWithRewardsHorzOffset 	= 30

local kstrScalingHex = "ffffbf80"
local kcrScalingCColor = CColor.new(1.0, 191/255, 128/255, 0.7)

local karDispositionColors =
{
	--[Unit.CodeEnumDisposition.Neutral]  = ApolloColor.new("DispositionNeutral"),
	--[Unit.CodeEnumDisposition.Hostile]  = ApolloColor.new("DispositionHostile"),
	--[Unit.CodeEnumDisposition.Friendly] = ApolloColor.new("DispositionFriendly"), 
	[Unit.CodeEnumDisposition.Neutral]  = "White",
	[Unit.CodeEnumDisposition.Hostile]  = "White",
	[Unit.CodeEnumDisposition.Friendly] = "White", 

}



local kstrRaidMarkerToSprite =
{
	"Icon_Windows_UI_CRB_Marker_Bomb",
	"Icon_Windows_UI_CRB_Marker_Ghost",
	"Icon_Windows_UI_CRB_Marker_Mask",
	"Icon_Windows_UI_CRB_Marker_Octopus",
	"Icon_Windows_UI_CRB_Marker_Pig",
	"Icon_Windows_UI_CRB_Marker_Chicken",
	"Icon_Windows_UI_CRB_Marker_Toaster",
	"Icon_Windows_UI_CRB_Marker_UFO",
}

local karDispositionHealthBar =
{
	[Unit.CodeEnumDisposition.Hostile] 	= "CRB_Raid:sprRaid_HealthProgBar_Red",
	[Unit.CodeEnumDisposition.Neutral] 	= "CRB_Raid:sprRaid_HealthProgBar_Orange",
	[Unit.CodeEnumDisposition.Friendly] = "CRB_Raid:sprRaid_HealthProgBar_Green",
}

local npClassColors = 
{
	[GameLib.CodeEnumClass.Warrior]				= "ff654B30",
	[GameLib.CodeEnumClass.Engineer] 			= "ff96b361",
	[GameLib.CodeEnumClass.Esper]				= "ff7171C6",
	[GameLib.CodeEnumClass.Medic]				= "ffD2779E",
	[GameLib.CodeEnumClass.Stalker] 			= "ffCFC15E",
	[GameLib.CodeEnumClass.Spellslinger]	 	= "ff3579DC"
}

--local FactionCheck
--{
	--CodeEnumFaction.DominionPlayer =           --value = 166
	--CodeEnumFaction.ExilesPlayer = 			   --value = 167
--}


-- Todo: break these out onto options
--local kcrGroupTextColor					= ApolloColor.new("crayBlizzardBlue")
--local kcrFlaggedFriendlyTextColor 		= karDispositionColors[Unit.CodeEnumDisposition.Friendly]
--local kcrDefaultGuildmemberTextColor 	= karDispositionColors[Unit.CodeEnumDisposition.Friendly]
--local kcrHostileEnemyTextColor 			= karDispositionColors[Unit.CodeEnumDisposition.Hostile]
--local kcrAggressiveEnemyTextColor 		= karDispositionColors[Unit.CodeEnumDisposition.Neutral]
--local kcrNeutralEnemyTextColor 			= ApolloColor.new("crayDenim")
--local kcrDefaultUnflaggedAllyTextColor 	= karDispositionColors[Unit.CodeEnumDisposition.Friendly]

local kcrGroupTextColor					= ApolloColor.new("crayBlizzardBlue")
local kcrFlaggedFriendlyTextColor 		= "FFFFFFAA"
local kcrDefaultGuildmemberTextColor 	= ApolloColor.new("DispositionFriendly")
local kcrHostileEnemyTextColor 			= "FFFFFFFF"
local kcrAggressiveEnemyTextColor 		= ApolloColor.new("DispositionHostile")
local kcrNeutralEnemyTextColor 			= "FFFF6A6A"
local kcrDefaultUnflaggedAllyTextColor 	= "FFFFFFFF"

-- TODO:Localize all of these
-- differential value, color, title, description, title color (for tooltip)
local karConInfo =
{
	{-4, ApolloColor.new("ConTrivial"), 	Apollo.GetString("TargetFrame_Trivial"), 	Apollo.GetString("TargetFrame_NoXP"), 				"ff7d7d7d"},
	{-3, ApolloColor.new("ConInferior"), 	Apollo.GetString("TargetFrame_Inferior"), 	Apollo.GetString("TargetFrame_VeryReducedXP"), 		"ff01ff07"},
	{-2, ApolloColor.new("ConMinor"), 		Apollo.GetString("TargetFrame_Minor"), 		Apollo.GetString("TargetFrame_ReducedXP"), 			"ff01fcff"},
	{-1, ApolloColor.new("ConEasy"), 		Apollo.GetString("TargetFrame_Easy"), 		Apollo.GetString("TargetFrame_SlightlyReducedXP"), 	"ff597cff"},
	{ 0, ApolloColor.new("ConAverage"), 	Apollo.GetString("TargetFrame_Average"), 	Apollo.GetString("TargetFrame_StandardXP"), 		"ffffffff"},
	{ 1, ApolloColor.new("ConModerate"), 	Apollo.GetString("TargetFrame_Moderate"), 	Apollo.GetString("TargetFrame_SlightlyMoreXP"), 	"ffffff00"},
	{ 2, ApolloColor.new("ConTough"), 		Apollo.GetString("TargetFrame_Tough"), 		Apollo.GetString("TargetFrame_IncreasedXP"), 		"ffff8000"},
	{ 3, ApolloColor.new("ConHard"), 		Apollo.GetString("TargetFrame_Hard"), 		Apollo.GetString("TargetFrame_HighlyIncreasedXP"), 	"ffff0000"},
	{ 4, ApolloColor.new("ConImpossible"), 	Apollo.GetString("TargetFrame_Impossible"), Apollo.GetString("TargetFrame_GreatlyIncreasedXP"),	"ffff00ff"}
}

-- Todo: Localize
local ktRankDescriptions = 
{
	[Unit.CodeEnumRank.Fodder] 		= 	{Apollo.GetString("TargetFrame_Fodder"), 		Apollo.GetString("TargetFrame_VeryWeak")},
	[Unit.CodeEnumRank.Minion] 		= 	{Apollo.GetString("TargetFrame_Minion"), 		Apollo.GetString("TargetFrame_Weak")},
	[Unit.CodeEnumRank.Standard]	= 	{Apollo.GetString("TargetFrame_Grunt"), 		Apollo.GetString("TargetFrame_EasyAppend")},
	[Unit.CodeEnumRank.Champion] 	=	{Apollo.GetString("TargetFrame_Challenger"), 	Apollo.GetString("TargetFrame_AlmostEqual")},
	[Unit.CodeEnumRank.Superior] 	=  	{Apollo.GetString("TargetFrame_Superior"), 		Apollo.GetString("TargetFrame_Strong")},
	[Unit.CodeEnumRank.Elite] 		= 	{Apollo.GetString("TargetFrame_Prime"), 		Apollo.GetString("TargetFrame_VeryStrong")},
}

local kstrTooltipBodyColor = "ffc0c0c0"
local kstrTooltipTitleColor = "ffdadada"

local kstrFriendSprite 			= "ClientSprites:Icon_Windows_UI_CRB_Friend"
local kstrAccountFriendSprite 	= "ClientSprites:Icon_Windows_UI_CRB_Friend"
local kstrRivalSprite 			= "ClientSprites:Icon_Windows_UI_CRB_Rival"

local karRewardIcons =
{
	["Quest"] 			= { strSingle = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_ActiveQuest", 	strMulti = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_ActiveQuestMulti" },
	["Challenge"] 		= { strSingle = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_Challenge", 		strMulti = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_ChallengeMulti" },
	["Explorer"] 		= { strSingle = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathExp", 		strMulti = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathExpMulti" },
	["Scientist"] 		= { strSingle = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSci",			strMulti = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSciMulti" },
	["Soldier"] 		= { strSingle = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSol", 		strMulti = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSolMulti" },
	["Settler"] 		= { strSingle = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSet", 		strMulti = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSetMulti" },
	["PublicEvent"] 	= { strSingle = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PublicEvent", 	strMulti = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PublicEventMulti" },
	["Rival"] 			= { strSingle = "ClientSprites:Icon_Windows_UI_CRB_Rival", 							strMulti = "ClientSprites:Icon_Windows_UI_CRB_Rival" },
	["Friend"] 			= { strSingle = "ClientSprites:Icon_Windows_UI_CRB_Friend", 						strMulti = "ClientSprites:Icon_Windows_UI_CRB_Friend" },
	["ScientistSpell"]	= { strSingle = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSciSpell",	strMulti = "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSciSpell" }
}

function TargetFrame:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function TargetFrame:Init()
	Apollo.RegisterAddon(self)
end

function TargetFrame:OnLoad()
	Apollo.RegisterEventHandler("TargetUnitChanged", 						"OnTargetUnitChanged", self)
	Apollo.RegisterEventHandler("KeyBindingKeyChanged", 					"OnKeyBindingUpdated", self)
	Apollo.RegisterEventHandler("AlternateTargetUnitChanged", 				"OnAlternateTargetUnitChanged", self)
	Apollo.RegisterEventHandler("GenericEvent_ToggleNameplate_bDrawToT", 	"OnGenericEvent_ToggleNameplate_bDrawToT", self)
	Apollo.RegisterTimerHandler("TargetFrameUpdate", 						"OnUpdate", self)
	
	Apollo.CreateTimer("TargetFrameUpdate", 0.013, true)
	self.arClusterFrames =
	{
		Apollo.LoadForm("PvP_TargetFrame.xml", "ClusterTarget", 			"FixedHudStratum", self),
		Apollo.LoadForm("PvP_TargetFrame.xml", "ClusterTargetBottomRight", 	"FixedHudStratum", self),
		Apollo.LoadForm("PvP_TargetFrame.xml", "ClusterTargetBottomLeft", 	"FixedHudStratum", self),
		Apollo.LoadForm("PvP_TargetFrame.xml", "ClusterTargetTopRight", 	"FixedHudStratum", self),
		Apollo.LoadForm("PvP_TargetFrame.xml", "ClusterTargetTopLeft", 		"FixedHudStratum", self)
	}

	self.wndRankedFrame = self.arClusterFrames[1]:FindChild("LargeFrame")
	--self.frameLeft, self.frameTop, self.frameRight, self.frameBottom = self.ClusterFrames[1]:GetRect()
	self:ArrangeClusterMembers()

	self.bDrawToT 		= false
	self.wndToTFrame 	= self.arClusterFrames[1]:FindChild("TotFrame")
	self.wndToTFrame:Show(false)
	self.arClusterFrames[1]:ArrangeChildrenHorz(1)
	
	self.wndMountHealth = self.arClusterFrames[1]:FindChild("MountHealthFrame")
	self.wndMountHealth:Show(false)

	self.wndAssistFrame = Apollo.LoadForm("PvP_TargetFrame.xml", "AssistTarget", "FixedHudStratum", self)
	self.nAltHealthLeft, self.nAltHealthTop, self.nAltHealthRight, self.nAltHealthBottom = self.wndAssistFrame:FindChild("MaxHealth"):GetAnchorOffsets()
	self.nAltHealthWidth = self.nAltHealthRight - self.nAltHealthLeft

	self.wndSimpleFrame = Apollo.LoadForm("ui\\TargetFrame\\TargetFrame.xml", "SimpleTargetFrame", "FixedHudStratum", self)

	self.arRewardIconsList = -- TODO: This should be a local constant
	{
		"ActiveQuest",
		"EligibleQuest",
		"Challenge",
		"Path",
		"Achievement",
		"Reputation",
		"Frost",
		"Flame",
		"Bolt",
		"Soldier",
		"Scientist",
		"Explorer",
		"Settler",
		"PublicEvent",
		"ScientistSpell"
	}
	self.nRewardIconListCount = #self.arRewardIconsList

	self.nLFrameLeft, self.nLFrameTop, self.nLFrameRight, self.nLFrameBottom = self.wndRankedFrame:FindChild("MaxHealth"):GetAnchorOffsets()

	-- We apparently resize bars rather than set progress
	self:SetBarValue(self.wndRankedFrame:FindChild("ShieldCapacityTint"), 0, 100, 100)

	self.strPathActionKeybind = GameLib.GetKeyBinding("PathAction")
	self.bPathActionUsesIcon = false
	if self.strPathActionKeybind == "Unbound" or #self.strPathActionKeybind > 1 then -- Don't show interact
		self.bPathActionUsesIcon = true
	end

	self.strQuestActionKeybind = GameLib.GetKeyBinding("CastObjectiveAbility")
	self.bQuestActionUsesIcon = false
	if self.strQuestActionKeybind == "Unbound" or #self.strQuestActionKeybind > 1 then -- Don't show interact
		self.bQuestActionUsesIcon = true
	end
	

	self.nRaidMarkerLeft, self.nRaidMarkerTop, self.nRaidMarkerRight, self.nRaidMarkerBottom = self.wndRankedFrame:FindChild("RaidMarker"):GetAnchorOffsets()

	self.nLastCCArmorValue = 0
	self.unitLastTarget = nil
	self.unitAltTarget = nil
	self.bTargetDead = false
end

function TargetFrame:OnSave(eType)
	return nil
end

function TargetFrame:OnRestore(eType, t)
end

function TargetFrame:OnUpdate()
	
	local bTargetChanged = false
	local unitTarget = GameLib.GetTargetUnit()
	

	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer ~= nil then
		self.unitAltTarget = unitPlayer:GetAlternateTarget()
	end

	if self.unitTarget == nil then
		bTargetChanged = true
		self:HelperResetTooltips() -- these get redrawn with the unitToT info
	end

	if unitTarget ~= nil and self.unitTarget ~= unitTarget then
		self.unitTarget = unitTarget
		bTargetChanged = true
		self:HelperResetTooltips() -- these get redrawn with the unitToT info
	end

	if unitTarget ~= nil then
		
		-- Cluster info
		local tCluster = unitTarget:GetClusterUnits()
		if tCluster ~= nil and #tCluster > 1 then
			self:UpdateClusterFrame(tCluster)
		else
			self:HideClusterFrames()
		end

		-- Primary frame
		if unitTarget:GetHealth() ~= nil then
			self:UpdatePrimaryFrame(unitTarget, bTargetChanged)
		else
			self.wndSimpleFrame:Show(true, true)
			self.arClusterFrames[1]:Show(false)
			local strName = unitTarget:GetName()

			local nLeft, nTop, nRight, nBottom = self.wndSimpleFrame:GetRect()
			local nWidth = nRight - nLeft
			local nCenter = nLeft + nWidth / 2
			nWidth = 30 + string.len(strName) * 10
			nLeft = nCenter - nWidth / 2
			self.wndSimpleFrame:Move(nLeft, nTop, nWidth, nBottom - nTop)
			self.wndSimpleFrame:FindChild("TargetName"):SetText(unitTarget:GetName())
			
			self:HelperAddRewardsToTarget(self.wndSimpleFrame, unitTarget)
		end
	else
		self.arClusterFrames[1]:Show(false)
		self.wndSimpleFrame:Show(false)
		self:HideClusterFrames()
	end

	if self.unitAltTarget ~= nil then
		self.wndAssistFrame:Show(true)
		self:UpdateAlternateFrame(self.unitAltTarget)
	else
		self.wndAssistFrame:Show(false)
	end
end

-- todo: remove this, move functionality to draw or previous function, look about unhooking for movement
function TargetFrame:UpdatePrimaryFrame(unitTarget, bTargetChanged) --called from the onFrame; eliteness is frame, diff is rank
	self.wndSimpleFrame:Show(false)
	if unitTarget == nil then 
		return 
	end

	local eRank = unitTarget:GetRank()

	-- BG art is based on rank

	-- top to bottom
	if unitTarget:GetType() == "Player" then
		self.wndRankedFrame:FindChild("Backer"):SetSprite("CRB_TargetFrameSprites:sprTF_BaseStandard_Primary")
	elseif eRank == Unit.CodeEnumRank.Elite then
		self.wndRankedFrame:FindChild("Backer"):SetSprite("CRB_TargetFrameSprites:sprTF_BaseElite_Primary")
	elseif eRank == Unit.CodeEnumRank.Superior then
		self.wndRankedFrame:FindChild("Backer"):SetSprite("CRB_TargetFrameSprites:sprTF_BaseSuperior_Primary")
	elseif eRank == Unit.CodeEnumRank.Champion then
		self.wndRankedFrame:FindChild("Backer"):SetSprite("CRB_TargetFrameSprites:sprTF_BaseChampion_Primary")
	elseif eRank == Unit.CodeEnumRank.Standard then
		self.wndRankedFrame:FindChild("Backer"):SetSprite("CRB_TargetFrameSprites:sprTF_BaseStandard_Primary")
	elseif eRank == Unit.CodeEnumRank.Minion then
		self.wndRankedFrame:FindChild("Backer"):SetSprite("CRB_TargetFrameSprites:sprTF_BaseMinion_Primary")
	else -- invalid data or solo
		self.wndRankedFrame:FindChild("Backer"):SetSprite("CRB_TargetFrameSprites:sprTF_BaseFodder_Primary")
	end

	local strTooltipRank = ""
	if unitTarget:GetType() == "Player" then
		local strRank = Apollo.GetString("TargetFrame_IsPC")
		strTooltipRank = self:HelperBuildTooltip(strRank, "Player")
	elseif ktRankDescriptions[unitTarget:GetRank()] ~= nil then
		local strRank = String_GetWeaselString(Apollo.GetString("TargetFrame_CreatureRank"), ktRankDescriptions[unitTarget:GetRank()][2])
		strTooltipRank = self:HelperBuildTooltip(strRank, ktRankDescriptions[unitTarget:GetRank()][1])
	end

	self.wndRankedFrame:FindChild("TargetModel"):SetTooltip(strTooltipRank)
	self.wndRankedFrame:FindChild("TargetModel"):SetData(unitTarget)

	self:SetTargetForFrame(self.wndRankedFrame, unitTarget, bTargetChanged)

	-- ToT
	if self.bDrawToT == false and self.wndToTFrame:IsShown() then
		self.wndToTFrame:Show(false)
		self.arClusterFrames[1]:ArrangeChildrenHorz(1)
	elseif self.bDrawToT == true then
		if not self.wndToTFrame:IsShown() and unitTarget:GetTarget() ~= nil then
			self.wndToTFrame:Show(true)
			self.arClusterFrames[1]:ArrangeChildrenHorz(2)
		elseif self.wndToTFrame:IsShown() and unitTarget:GetTarget() == nil then
			self.wndToTFrame:Show(false)
			self.arClusterFrames[1]:ArrangeChildrenHorz(1)
		end
	end

	if self.wndToTFrame:IsShown() then
		self:UpdateToTFrame(unitTarget:GetTarget())
	end

	-- Mount Frame
	self.wndMountHealth:Show(unitTarget:IsMounted())
	if self.wndMountHealth:IsShown() then
		self.wndMountHealth:FindChild("MountHealth"):SetFloor(0)
		self.wndMountHealth:FindChild("MountHealth"):SetMax(unitTarget:GetMountMaxHealth())
		self.wndMountHealth:FindChild("MountHealth"):SetProgress(unitTarget:GetMountHealth())
		self.wndMountHealth:FindChild("MountHealthText"):SetText(String_GetWeaselString(Apollo.GetString("TargetFrame_MountHP"), unitTarget:GetMountHealth(), unitTarget:GetMountMaxHealth()))
	end

	self:HelperAddRewardsToTarget(self.wndRankedFrame, unitTarget)
	
	-- Raid Marker
	local wndRaidMarker = self.wndRankedFrame:FindChild("RaidMarker")
	if wndRaidMarker then
		wndRaidMarker:SetSprite("")
		local nMarkerId = unitTarget and unitTarget:GetTargetMarker() or 0
		if unitTarget and nMarkerId ~= 0 then
			wndRaidMarker:SetSprite(kstrRaidMarkerToSprite[nMarkerId])
		end
	end

	self.wndRankedFrame:FindChild("TargetModel"):SetCostume(self.unitTarget)
	self.arClusterFrames[1]:Show(true, true)
end


function TargetFrame:UpdateAlternateFrame(unitToT)
	if unitToT == nil then 
		return 
	end
	local wndFrame = self.wndAssistFrame
	local eDisposition = unitToT:GetDispositionTo(GameLib.GetPlayerUnit())
	local crColorToUse = nil

	if unitToT:IsDead() and (eDisposition ~= Unit.CodeEnumDisposition.Friendly or not unitToT:IsThePlayer()) then
		local unitPlayer = GameLib.GetPlayerUnit()
		unitPlayer:SetAlternateTarget(nil)
		return
	end

	wndFrame:FindChild("TargetName"):SetTextColor(karDispositionColors[eDisposition])
	if unitToT:GetType() == "Player" then
		if eDisposition == Unit.CodeEnumDisposition.Friendly or unitToT:IsThePlayer() then
			if unitToT:IsPvpFlagged() then
				crColorToUse = kcrFlaggedFriendlyTextColor
			elseif unitToT:IsInYourGroup() then
				crColorToUse = kcrGroupTextColor
			else
				crColorToUse = kcrDefaultUnflaggedAllyTextColor
			end
		else
			local bIsUnitFlagged = unitToT:IsPvpFlagged()
			local bAmIFlagged = GameLib.IsPvpFlagged()
			if not bAmIFlagged and not bIsUnitFlagged then
				crColorToUse = kcrNeutralEnemyTextColor
			elseif (bAmIFlagged and not bIsUnitFlagged) or (not bAmIFlagged and bIsUnitFlagged) then
				crColorToUse = kcrAggressiveEnemyTextColor
			elseif bAmIFlagged and bIsUnitFlagged then
				crColorToUse = kcrHostileEnemyTextColor
			end
		end

		wndFrame:FindChild("TargetName"):SetTextColor(crColorToUse)
	end

	wndFrame:FindChild("TargetModel"):SetCostume(unitToT)
	wndFrame:FindChild("TargetModel"):SetData(unitToT)
	wndFrame:SetData(unitToT)
	wndFrame:FindChild("TargetName"):SetText(unitToT:GetName())

	if eDisposition == Unit.CodeEnumDisposition.Friendly or unitToT:IsThePlayer() then
		wndFrame:FindChild("DispositionFrameFriendly"):Show(true)
		wndFrame:FindChild("DispositionFrameHostile"):Show(false)
	else
		wndFrame:FindChild("DispositionFrameFriendly"):Show(false)
		wndFrame:FindChild("DispositionFrameHostile"):Show(true)
	end

	local nHealthCurr = unitToT:GetHealth()
	local nHealthMax = unitToT:GetMaxHealth()
	local nShieldCurr = unitToT:GetShieldCapacity()
	local nShieldMax = unitToT:GetShieldCapacityMax()
	local nAbsorbCurr = 0
	local nAbsorbMax = unitToT:GetAbsorptionMax()
	if nAbsorbMax > 0 then
		nAbsorbCurr = unitToT:GetAbsorptionValue() -- Since it doesn't clear when the buff drops off
	end
	local nTotalMax = nHealthMax + nShieldMax + nAbsorbMax

	local nPointHealthRight = self.nAltHealthLeft + (self.nAltHealthWidth * (nHealthCurr / nHealthMax)) -- applied to the difference between L and R
	local nPointShieldRight = self.nAltHealthLeft + (self.nAltHealthWidth * ((nHealthCurr + nShieldMax) / nTotalMax))
	local nPointAbsorbRight = self.nAltHealthLeft + (self.nAltHealthWidth * ((nHealthCurr + nShieldMax + nAbsorbMax) / nTotalMax))

	if nShieldMax > 0 and nShieldMax / nTotalMax < 0.2 then
		local nMinShieldSize = 0.0 -- HARDCODE: Minimum shield bar length is 20% of total for formatting
		--nPointHealthRight = self.nAltHealthLeft + (self.nAltHealthWidth * (math.min (1 - nMinShieldSize, nHealthCurr / nTotalMax)))
		nPointShieldRight = self.nAltHealthLeft + (self.nAltHealthWidth * (math.min (1, (nHealthCurr / nTotalMax) + nMinShieldSize)))
	end

	-- Resize
	wndFrame:FindChild("ShieldFill"):EnableGlow(nShieldCurr > 0)
	self:SetBarValue(wndFrame:FindChild("ShieldFill"), 0, nShieldCurr, nShieldMax) -- Only the Curr Shield really progress fills
	self:SetBarValue(wndFrame:FindChild("AbsorbFill"), 0, nAbsorbCurr, nAbsorbMax)
	wndFrame:FindChild("MaxHealth"):SetAnchorOffsets(self.nAltHealthLeft, self.nAltHealthTop, nPointHealthRight, self.nAltHealthBottom)
	wndFrame:FindChild("MaxShield"):SetAnchorOffsets(nPointHealthRight - 1, self.nAltHealthTop, nPointShieldRight, self.nAltHealthBottom)
	wndFrame:FindChild("MaxAbsorb"):SetAnchorOffsets(nPointShieldRight - 1, self.nAltHealthTop, nPointAbsorbRight, self.nAltHealthBottom)

	-- Bars
	--wndFrame:FindChild("ShieldFill"):Show(nHealthCurr > 0)
	--wndFrame:FindChild("MaxHealth"):Show(nHealthCurr > 0)
	--wndFrame:FindChild("MaxShield"):Show(nHealthCurr > 0 and nShieldMax > 0)
	--wndFrame:FindChild("MaxAbsorb"):Show(nHealthCurr > 0 and nAbsorbMax > 0)

	-- Text
	local strHealthMax = self:HelperFormatBigNumber(nHealthMax)
	local strHealthCurr = self:HelperFormatBigNumber(nHealthCurr)
	local strShieldCurr = self:HelperFormatBigNumber(nShieldCurr)
	local strText = String_GetWeaselString(Apollo.GetString("TargetFrame_TextProgress"), strHealthCurr, strHealthMax)
	if nShieldMax > 0 and nShieldCurr > 0 then
		strText = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthShieldText"), strText, strShieldCurr)
	end
	
	wndFrame:FindChild("HealthText"):SetText(strHealthCurr)
	--wndFrame:FindChild("ShieldText"):SetText("hello")

		
	-- Sprite
	if nVulnerabilityTime and nVulnerabilityTime > 0 then
		wndFrame:FindChild("MaxHealth"):SetSprite("sprNp_Health_FillPurple")
	--elseif nHealthCurr / nHealthMax < .3 then
	--	wndFrame:FindChild("MaxHealth"):SetSprite("sprNp_Health_FillRed")
	--elseif 	nHealthCurr / nHealthMax < .5 then
	--	wndFrame:FindChild("MaxHealth"):SetSprite("sprNp_Health_FillOrange")
	--else
	--	wndFrame:FindChild("MaxHealth"):SetSprite("sprNp_Health_FillGreen")
	end

	-- Interrupt Armor
	---------------------------------------------------------------------------
	local nCCArmorValue = unitToT:GetInterruptArmorValue()
	local nCCArmorMax = unitToT:GetInterruptArmorMax()
	local wndCCArmor = wndFrame:FindChild("CCArmorContainer")

	if nCCArmorMax == 0 or nCCArmorValue == nil then
		wndCCArmor:Show(false)
	else
		wndCCArmor:Show(true)
		if nCCArmorMax == -1 then -- impervious
			wndCCArmor:FindChild("CCArmorValue"):SetText("")
			wndCCArmor:FindChild("CCArmorSprite"):SetSprite("CRB_ActionBarSprites:sprAb_IntArm_Invulnerable")
		elseif nCCArmorValue == 0 and nCCArmorMax > 0 then -- broken
			wndCCArmor:FindChild("CCArmorValue"):SetText("")
			wndCCArmor:FindChild("CCArmorSprite"):SetSprite("CRB_ActionBarSprites:sprAb_IntArm_Broken")
		elseif nCCArmorMax > 0 then -- has armor, has value
			wndCCArmor:FindChild("CCArmorValue"):SetText(nCCArmorValue)
			wndCCArmor:FindChild("CCArmorSprite"):SetSprite("CRB_ActionBarSprites:sprAb_IntArm_Regular")
		end

		if nCCArmorValue < self.nLastCCArmorValue and nCCArmorValue ~= 0 and nCCArmorValue ~= -1 then
			wndCCArmor:FindChild("CCArmorFlash"):SetSprite("CRB_ActionBarSprites:sprAb_IntArm_Flash")
		end
	end

	self:UpdateCastingBar(wndFrame, unitToT)
end


function TargetFrame:UpdateToTFrame(unitToT) -- called on frame
	if unitToT == nil then 
		return 
	end

	self.wndToTFrame:SetData(unitToT)
	self.wndToTFrame:FindChild("TargetModel"):SetCostume(unitToT)

	self:SetBarValue(self.wndToTFrame:FindChild("HealthTint"), 0, unitToT:GetHealth(), unitToT:GetMaxHealth())
	if unitToT:GetHealth() and unitToT:IsInCCState(Unit.CodeEnumCCState.Vulnerability) then
		self.wndToTFrame:FindChild("HealthTint"):SetFullSprite("CRB_TargetFrameSprites:sprTF_HealthFill_VulnRoundStretch")
	elseif unitToT:GetHealth() and (unitToT:GetHealth() / unitToT:GetMaxHealth()) <= .2 then
		self.wndToTFrame:FindChild("HealthTint"):SetFullSprite("CRB_TargetFrameSprites:sprTF_HealthFill_RedRoundStretch")
	elseif unitToT:GetHealth() and (unitToT:GetHealth() / unitToT:GetMaxHealth()) <= .4 then
		self.wndToTFrame:FindChild("HealthTint"):SetFullSprite("CRB_TargetFrameSprites:sprTF_HealthFill_YellowRoundStretch")
	else
		self.wndToTFrame:FindChild("HealthTint"):SetFullSprite("CRB_TargetFrameSprites:sprTF_HealthFill_GreenRoundStretch")
	end

	local eDisposition = unitToT:GetDispositionTo(GameLib.GetPlayerUnit())
	if eDisposition == Unit.CodeEnumDisposition.Friendly or unitToT:IsThePlayer() then
		self.wndToTFrame:FindChild("DispositionFrameFriendly"):Show(true)
		self.wndToTFrame:FindChild("DispositionFrameHostile"):Show(false)
	else
		self.wndToTFrame:FindChild("DispositionFrameFriendly"):Show(false)
		self.wndToTFrame:FindChild("DispositionFrameHostile"):Show(true)
	end

end


function TargetFrame:OnAlternateTargetUnitChanged(unitToT)
	self.unitAltTarget = unitToT -- nil is acceptable here
	self:OnUpdate()
end

function TargetFrame:UpdateClusterFrame(tCluster) -- called on frame
	if self.unitTarget:IsDead() then
		self:HideClusterFrames()
		return
	end

	self:ArrangeClusterMembers()

	local nCount = 2

	for idx = 1, #tCluster do
		if nCount <= 5 and tCluster[idx] ~= self.unitTarget then
			if not tCluster[idx]:IsDead() then
				self.arClusterFrames[nCount]:Show(true, true)
				self:SetTargetForClusterFrame(self.arClusterFrames[nCount], tCluster[idx], true)
				self.arClusterFrames[nCount]:FindChild("TargetModel"):SetCostume(tCluster[idx])
				
				self:HelperAddRewardsToTarget(self.arClusterFrames[nCount], tCluster[idx])
				
				-- TODO: This probably doesn't belong here
				local nHealth = tCluster[idx]:GetHealth()
				if nHealth ~= nil then
					if self.arClusterFrames[nCount]:FindChild("HealthTint") then
						self:SetBarValue(self.arClusterFrames[nCount]:FindChild("HealthTint"), 0, tCluster[idx]:GetHealth(), tCluster[idx]:GetMaxHealth())
						if tCluster[idx]:IsInCCState(Unit.CodeEnumCCState.Vulnerability) then
							self.arClusterFrames[nCount]:FindChild("HealthTint"):SetFullSprite("CRB_TargetFrameSprites:sprTF_HealthFill_VulnRound")
						elseif (tCluster[idx]:GetHealth() / tCluster[idx]:GetMaxHealth()) <= .2 then
							self.arClusterFrames[nCount]:FindChild("HealthTint"):SetFullSprite("CRB_TargetFrameSprites:sprTF_HealthFill_RedRound")
						elseif (tCluster[idx]:GetHealth() / tCluster[idx]:GetMaxHealth()) <= .4 then
							self.arClusterFrames[nCount]:FindChild("HealthTint"):SetFullSprite("CRB_TargetFrameSprites:sprTF_HealthFill_YellowRound")
						else
							self.arClusterFrames[nCount]:FindChild("HealthTint"):SetFullSprite("CRB_TargetFrameSprites:sprTF_HealthFill_GreenRound")
						end
					end
				end

				local nLevel = tCluster[idx]:GetLevel()
				if nLevel == nil then
					self.arClusterFrames[nCount]:FindChild("TargetLevel"):SetText("--")
					self.arClusterFrames[nCount]:FindChild("TargetLevel"):SetTextColor(karConInfo[1][2])
					self.arClusterFrames[nCount]:FindChild("TargetLevel"):SetTooltip("")				
				else
					local nCon = self:HelperCalculateConValue(tCluster[idx])
					self.arClusterFrames[nCount]:FindChild("TargetLevel"):SetText(tCluster[idx]:GetLevel())				
				
					if tCluster[idx]:IsScaled() then
						self.arClusterFrames[nCount]:FindChild("TargetScalingMark"):Show(true)
						self.arClusterFrames[nCount]:FindChild("TargetLevel"):SetTextColor(kcrScalingCColor)
						strRewardFormatted = String_GetWeaselString(Apollo.GetString("TargetFrame_CreatureScales"), tCluster[idx]:GetLevel())
						local strLevelTooltip = self:HelperBuildTooltip(strRewardFormatted, "Adaptive", kstrScalingHex)
						self.arClusterFrames[nCount]:FindChild("TargetLevel"):FindChild("TargetLevel"):SetTooltip(strLevelTooltip)
					else
						self.arClusterFrames[nCount]:FindChild("TargetLevel"):SetTextColor(karConInfo[nCon][2])
						local strRewardFormatted = String_GetWeaselString(Apollo.GetString("TargetFrame_TargetXPReward"), karConInfo[nCon][4])
						local strLevelTooltip = self:HelperBuildTooltip(strRewardFormatted, karConInfo[nCon][3], karConInfo[nCon][5])
						self.arClusterFrames[nCount]:FindChild("TargetLevel"):SetTooltip(strLevelTooltip)
					end						
				end

				nCount = nCount + 1
			end
		end
	end

	for idx = nCount, 5 do
		self.arClusterFrames[idx]:Show(false)
		self.arClusterFrames[idx]:SetData(nil)
	end
end

function TargetFrame:HideClusterFrames()
	for idx = 2, 5 do
		self.arClusterFrames[idx]:Show(false)
		self.arClusterFrames[idx]:SetData(nil)
	end
end

function TargetFrame:SetTargetForFrame(wndFrame, unitTarget, bTargetChanged)
	wndFrame:SetData(unitTarget)
	self:SetTargetHealthAndShields(wndFrame, unitTarget)

	if unitTarget then
		wndFrame:FindChild("TargetName"):SetText(unitTarget:GetName())

		--Disposition/flags
		local eDisposition = unitTarget:GetDispositionTo(GameLib.GetPlayerUnit())
		wndFrame:FindChild("TargetName"):SetTextColor(karDispositionColors[eDisposition])

		--todo: Tooltips
		local bSameFaction = GameLib.GetPlayerUnit():GetFaction() == unitTarget:GetFaction()
		local crColorToUse = karDispositionColors[eDisposition]

		-- Level / Diff
		local nLevel = unitTarget:GetLevel()
		if nLevel == nil then
			wndFrame:FindChild("TargetLevel"):SetText(Apollo.GetString("CRB__2"))
			wndFrame:FindChild("TargetLevel"):SetTextColor(karConInfo[1][2])
			wndFrame:FindChild("TargetLevel"):SetTooltip("")		
		else
			wndFrame:FindChild("TargetLevel"):SetText(unitTarget:GetLevel())
			
			if unitTarget:IsScaled() then
				wndFrame:FindChild("TargetScalingMark"):Show(true)
				wndFrame:FindChild("TargetLevel"):SetTextColor(kcrScalingCColor)
				strRewardFormatted = String_GetWeaselString(Apollo.GetString("TargetFrame_CreatureScales"), unitTarget:GetLevel())
				local strLevelTooltip = self:HelperBuildTooltip(strRewardFormatted, "Adaptive", kcrScalingHex)
				wndFrame:FindChild("TargetLevel"):FindChild("TargetLevel"):SetTooltip(strLevelTooltip)
			else
				wndFrame:FindChild("TargetScalingMark"):Show(false)
				local nCon = self:HelperCalculateConValue(unitTarget)
				wndFrame:FindChild("TargetLevel"):SetTextColor(karConInfo[nCon][2])
				strRewardFormatted = String_GetWeaselString(Apollo.GetString("TargetFrame_TargetXPReward"), karConInfo[nCon][4])
				local strLevelTooltip = self:HelperBuildTooltip(strRewardFormatted, karConInfo[nCon][3], karConInfo[nCon][5])
				wndFrame:FindChild("TargetLevel"):FindChild("TargetLevel"):SetTooltip(strLevelTooltip)
			end			
		end
		
		local strUnitType = unitTarget:GetType()
		if strUnitType == "Player" or strUnitType == "Pet" or strUnitType == "Esper Pet" then
			local unitPlayer = unitTarget:GetUnitOwner() or unitTarget
			if eDisposition == Unit.CodeEnumDisposition.Friendly or unitPlayer:IsThePlayer() then
				if unitPlayer:IsPvpFlagged() then
					crColorToUse = kcrFlaggedFriendlyTextColor
				elseif unitPlayer:IsInYourGroup() then
					crColorToUse = kcrGroupTextColor
				else
					crColorToUse = kcrDefaultUnflaggedAllyTextColor
				end
			else
				local bIsUnitFlagged = unitPlayer:IsPvpFlagged()
				local bAmIFlagged = GameLib.IsPvpFlagged()
				if not bAmIFlagged and not bIsUnitFlagged then
					crColorToUse = kcrNeutralEnemyTextColor
				elseif (bAmIFlagged and not bIsUnitFlagged) or (not bAmIFlagged and bIsUnitFlagged) then
					crColorToUse = kcrAggressiveEnemyTextColor
				end
			end
			wndFrame:FindChild("GroupSizeMark"):Show(false)
			wndFrame:FindChild("TargetName"):SetTextColor(crColorToUse)
		else -- NPC
			wndFrame:FindChild("GroupSizeMark"):Show(unitTarget:GetGroupValue() > 0)
			wndFrame:FindChild("GroupSizeMark"):SetText(unitTarget:GetGroupValue())

			local strGroupTooltip = self:HelperBuildTooltip(String_GetWeaselString(Apollo.GetString("TargetFrame_GroupSize"), unitTarget:GetGroupValue()), String_GetWeaselString(Apollo.GetString("TargetFrame_Man"), unitTarget:GetGroupValue()))
			wndFrame:FindChild("GroupSizeMark"):SetTooltip(strGroupTooltip)
		end

		if unitTarget:GetArchetype() and wndFrame:FindChild("TargetClassIcon") then
			wndFrame:FindChild("TargetClassIcon"):SetSprite(unitTarget:GetArchetype().icon)
		end

		-- Interrupt Armor
		---------------------------------------------------------------------------
		local nCCArmorValue = unitTarget:GetInterruptArmorValue()
		local nCCArmorMax = unitTarget:GetInterruptArmorMax()
		local wndCCArmor = wndFrame:FindChild("CCArmorContainer")

		if bTargetChanged then
			self.nLastCCArmorValue = nCCArmorValue
		end

		if nCCArmorMax == 0 or nCCArmorValue == nil then
			wndCCArmor:Show(false)
		else
			wndCCArmor:Show(true)
			if nCCArmorMax == -1 then -- impervious
				wndCCArmor:FindChild("CCArmorValue"):SetText("")
				wndCCArmor:FindChild("CCArmorSprite"):SetSprite("CRB_ActionBarSprites:sprAb_IntArm_Invulnerable")
			elseif nCCArmorValue == 0 and nCCArmorMax > 0 then -- broken
				wndCCArmor:FindChild("CCArmorValue"):SetText("")
				wndCCArmor:FindChild("CCArmorSprite"):SetSprite("CRB_ActionBarSprites:sprAb_IntArm_Broken")
			elseif nCCArmorMax > 0 then -- has armor, has value
				wndCCArmor:FindChild("CCArmorValue"):SetText(nCCArmorValue)
				wndCCArmor:FindChild("CCArmorSprite"):SetSprite("CRB_ActionBarSprites:sprAb_IntArm_Regular")
			end

			if nCCArmorValue < self.nLastCCArmorValue and nCCArmorValue ~= 0 and nCCArmorValue ~= -1 then
				wndCCArmor:FindChild("CCArmorFlash"):SetSprite("CRB_ActionBarSprites:sprAb_IntArm_Flash")
			end

			self.nLastCCArmorValue = nCCArmorValue
		end
	end

	if bTargetChanged then
		for idx = 1, 8 do
			wndFrame:FindChild("BeneBuffBar"):SetUnit(unitTarget)
			wndFrame:FindChild("HarmBuffBar"):SetUnit(unitTarget)
		end
	end

	self:UpdateCastingBar(wndFrame, unitTarget)
end

function TargetFrame:SetTargetForClusterFrame(wndFrame, unitTarget, bTargetChanged) -- this is the update; we can split here
	wndFrame:SetData(unitTarget)

	local eRank = unitTarget:GetRank()

	if unitTarget then
		if unitTarget:GetType() == "Player" then
			wndFrame:FindChild("ClusterTargetBG"):SetSprite("CRB_TargetFrameSprites:sprTF_BaseStandard_Secondary")
		elseif eRank == Unit.CodeEnumRank.Elite then
			wndFrame:FindChild("ClusterTargetBG"):SetSprite("CRB_TargetFrameSprites:sprTF_BaseElite_Secondary")
		elseif eRank == Unit.CodeEnumRank.Superior then
			wndFrame:FindChild("ClusterTargetBG"):SetSprite("CRB_TargetFrameSprites:sprTF_BaseSuperior_Secondary")
		elseif eRank == Unit.CodeEnumRank.Champion then
			wndFrame:FindChild("ClusterTargetBG"):SetSprite("CRB_TargetFrameSprites:sprTF_BaseChampion_Secondary")
		elseif eRank == Unit.CodeEnumRank.Standard then
			wndFrame:FindChild("ClusterTargetBG"):SetSprite("CRB_TargetFrameSprites:sprTF_BaseStandard_Secondary")
		elseif eRank == Unit.CodeEnumRank.Minion then
			wndFrame:FindChild("ClusterTargetBG"):SetSprite("CRB_TargetFrameSprites:sprTF_BaseMinion_Secondary")
		else -- invalid data or solo
			wndFrame:FindChild("ClusterTargetBG"):SetSprite("CRB_TargetFrameSprites:sprTF_BaseFodder_Secondary")
		end

		local strTooltipRank = ""
		if ktRankDescriptions[unitTarget:GetRank()] ~= nil then
			local strRank = String_GetWeaselString(Apollo.GetString("TargetFrame_CreatureRank"), ktRankDescriptions[unitTarget:GetRank()][2])
			strTooltipRank = self:HelperBuildTooltip(strRank, ktRankDescriptions[unitTarget:GetRank()][1])
		end

		wndFrame:FindChild("TargetModel"):SetTooltip(strTooltipRank)

		if unitTarget:GetArchetype() and wndFrame:FindChild("TargetClassIcon") then
			wndFrame:FindChild("TargetClassIcon"):SetSprite(unitTarget:GetArchetype().icon)
		end
	end

	self:UpdateCastingBar(wndFrame, unitTarget)
end

function TargetFrame:UpdateCastingBar(wndFrame, unitCaster)
	-- Casting Bar Update

	local bShowCasting = false
	local bEnableGlow = false
	local nZone = 0
	local nMaxZone = 0
	local nDuration = 0
	local nElapsed = 0
	local strSpellName = ""
	local nElapsed = 0
	local eType = Unit.CodeEnumCastBarType.None
	local strIcon = ""
	local strFillSprite = ""
	local strBaseSprite = ""
	local strGlowSprite = ""

	local wndCastFrame = wndFrame:FindChild("CastingFrame")
	local wndCastProgress = wndFrame:FindChild("CastingBar")
	local wndCastName = wndFrame:FindChild("CastingName")
	local wndCastIcon = wndFrame:FindChild("CastingIcon")
	local wndCastBase = wndFrame:FindChild("CastingBase")

	-- results for GetCastBarType can be:
	-- Unit.CodeEnumCastBarType.None
	-- Unit.CodeEnumCastBarType.Normal
	-- Unit.CodeEnumCastBarType.Telegraph_Backlash
	-- Unit.CodeEnumCastBarType.Telegraph_Evade
	if unitCaster:ShouldShowCastBar() then
		eType = unitCaster:GetCastBarType()

		if eType == Unit.CodeEnumCastBarType.Telegraph_Evade then
			strIcon = "CRB_TargetFrameSprites:sprTF_CastIconEvade"
			strFillSprite = "sprTF_CastMeterRed"
			strBaseSprite = "CRB_TargetFrameSprites:sprTF_CastBaseRed"
			strGlowSprite = "sprTF_CastMeterCapOrng"
		elseif eType == Unit.CodeEnumCastBarType.Telegraph_Backlash then
			strIcon = "CRB_TargetFrameSprites:sprTF_CastIconInterrupt"
			strFillSprite = "sprTF_CastMeterRed"
			strBaseSprite = "CRB_TargetFrameSprites:sprTF_CastBaseRed"
			strGlowSprite = "sprTF_CastMeterCapRed"
		else
			strIcon = ""
			strFillSprite = "CRB_Raid:sprRaidTear_BigAbsorbProgBar"
			strBaseSprite = "ClientSprites:BlackFill"
			strGlowSprite = "sprTF_CastMeterCapRed"
		end

		if eType ~= Unit.CodeEnumCastBarType.None then

			bShowCasting = true
			bEnableGlow = true
			nZone = 0
			nMaxZone = 1
			nDuration = unitCaster:GetCastDuration()
			nElapsed = unitCaster:GetCastElapsed()
			if wndCastProgress ~= nil then
				wndCastProgress:SetTickLocations(0, 100, 200, 300)
			end

			strSpellName = unitCaster:GetCastName()
		end
	end

	wndCastFrame:Show(bShowCasting)
	if wndCastProgress ~= nil then
		wndCastProgress:Show(bShowCasting)
		wndCastName:Show(bShowCasting)
	end

	if bShowCasting and nDuration > 0 and nMaxZone > 0 then
		wndCastIcon:SetSprite(nIcon)

		if wndCastProgress ~= nil then
			wndCastProgress:Show(bShowCasting)
			wndCastProgress:SetMax(nDuration)
			wndCastProgress:SetProgress(nElapsed)
			wndCastProgress:EnableGlow(bEnableGlow)
			wndCastProgress:SetFullSprite(strFillSprite)
			wndCastProgress:SetGlowSprite(strGlowSprite)
			wndCastName:SetText(strSpellName)
			wndCastBase:SetSprite(strBaseSprite)
		end
	end

end

-------------------------------------------------------------------------------
function TargetFrame:ArrangeClusterMembers()
	local nFrameLeft, nFrameTop, nFrameRight, nFrameBottom = self.arClusterFrames[1]:GetRect()

	if self.nFrameLeft == nil or nFrameLeft ~= self.nFrameLeft or nFrameTop ~= self.nFrameTop then -- if the frame has been moved since we last drew
		-- set new variables
		self.nFrameLeft = nFrameLeft
		self.nFrameTop = nFrameTop
		self.nFrameRight = nFrameRight
		self.nFrameBottom = nFrameBottom

		self.arClusterFrames[2]:Move(self.nFrameRight + knClusterFrameHorzOffsetLong, self.nFrameTop + knClusterFrameVertOffset, knClusterFrameWidth, knClusterFrameHeight)
		self.arClusterFrames[3]:Move(self.nFrameLeft - (knClusterFrameWidth + knClusterFrameHorzOffsetLong), self.nFrameTop + knClusterFrameVertOffset, knClusterFrameWidth, knClusterFrameHeight)

		local nFrame2Left, nFrame2Top, nFrame2Right, nFrame2Bottom = self.arClusterFrames[2]:GetRect()
		local nFrame3Left, nFrame3Top, nFrame3Right, nFrame3Bottom = self.arClusterFrames[3]:GetRect()
		self.arClusterFrames[4]:Move(15 + nFrame2Right, self.nFrameTop + knClusterFrameVertOffset, knClusterFrameWidth, knClusterFrameHeight)
		self.arClusterFrames[5]:Move(nFrame3Left - (knClusterFrameWidth + 15), self.nFrameTop + knClusterFrameVertOffset, knClusterFrameWidth, knClusterFrameHeight)
	end
end

function TargetFrame:HelperBuildTooltip(strBody, strTitle, crTitleColor)
	if strBody == nil then return end
	local strTooltip = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</T>", kstrTooltipBodyColor, strBody)
	if strTitle ~= nil then -- if a title has been passed, add it (optional)
		strTooltip = string.format("<P>%s</P>", strTooltip)
		local strTitle = string.format("<P Font=\"CRB_InterfaceMedium_B\" TextColor=\"%s\">%s</P>", crTitleColor or kstrTooltipTitleColor, strTitle)
		strTooltip = strTitle .. strTooltip
	end
	return strTooltip
end

function TargetFrame:HelperCalculateConValue(unitTarget)
	local nUnitCon = GameLib.GetPlayerUnit():GetLevelDifferential(unitTarget)
	local nCon = 1 --default setting

	if nUnitCon <= karConInfo[1][1] then -- lower bound
		nCon = 1
	elseif nUnitCon >= karConInfo[#karConInfo][1] then -- upper bound
		nCon = #karConInfo
	else
		for idx = 2, (#karConInfo-1) do -- everything in between
			if nUnitCon == karConInfo[idx][1] then
				nCon = idx
			end
		end
	end

	return nCon
end

function TargetFrame:HelperResetTooltips()
	self.wndRankedFrame:FindChild("TargetModel"):SetTooltip("")
	self.wndRankedFrame:FindChild("TargetLevel"):SetTooltip("")
	self.wndRankedFrame:FindChild("GroupSizeMark"):SetTooltip("")
end
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--REWARD PANEL
-------------------------------------------------------------------------------
function TargetFrame:OnTargetUnitChanged(unitNewTarget)
	if unitNewTarget == nil then
		self.unitLastTarget = nil
		--Apollo.StopTimer("TargetFrameUpdate")
		return
    end

	if self.unitLastTarget ~= nil and unitNewTarget == self.unitLastTarget then
		if self.bTargetDead ~= unitNewTarget:IsDead() then
			self.bTargetDead = unitNewTarget:IsDead()
			GameLib.SetTargetUnit(nil)
		end
		return -- early out if it's the same target
	end
	
	Apollo.StartTimer("TargetFrameUpdate")
	self.unitLastTarget = unitNewTarget
	self.bTargetDead = unitNewTarget:IsDead()
end

function TargetFrame:HelperAddRewardsToTarget(wndTarget, unitTarget)
	local wndRewardPanel = wndTarget:FindChild("TargetGoalPanel")
	local bIsFriend = unitTarget:IsFriend()
	local bIsRival = unitTarget:IsRival()
	--local bIsAccountFriend = unitTarget:IsAccountFriend()
	local nFriendshipCount = (bIsFriend and 1 or 0) + (bIsRival and 1 or 0) + (bIsAccountFriend and 1 or 0)

	local tRewardInfo = {}
	tRewardInfo = unitTarget:GetRewardInfo()
	if tRewardInfo == nil and nFriendshipCount == 0 then
		if next(wndRewardPanel:GetChildren()) ~= nil then
			wndRewardPanel:SetData({ oTarget = unitTarget, nIcons = 0 })
			wndRewardPanel:DestroyChildren()
		end
	
		return
	end

	if (tRewardInfo == nil or type(tRewardInfo) ~= "table") and nFriendshipCount == 0 then
		if next(wndRewardPanel:GetChildren()) ~= nil then
			wndRewardPanel:SetData({ oTarget = unitTarget, nIcons = 0 })
			wndRewardPanel:DestroyChildren()
		end
		
		return
	end
	
	local tRewardString = {} -- temp table to store quest descriptions (builds multi-objective tooltips)
	
	local nActiveRewardCount = 0
	local nRewardCount = tRewardInfo ~= nil and #tRewardInfo or 0
	local nExistingRewardCount = 0
	local oExistingTarget = nil
	if wndRewardPanel:GetData() ~= nil then
		nExistingRewardCount = wndRewardPanel:GetData().nIcons
		oExistingTarget = wndRewardPanel:GetData().oTarget
	end
	
	if (nRewardCount + nFriendshipCount) == nExistingRewardCount and oExistingTarget == unitTarget then
		return
	end
	
	wndRewardPanel:SetData({ oTarget = unitTarget, nIcons = nRewardCount + nFriendshipCount })
	wndRewardPanel:DestroyChildren()
	
	if nRewardCount > 0 then
		for idx = 1, nRewardCount do
			local strType = tRewardInfo[idx]["type"]
			
			if tRewardString[strType] == nil then
				tRewardString[strType] = ""
			end
			if strType == "Quest" then
				local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, strType)
				nActiveRewardCount = nActiveRewardCount + self:HelperDrawRewardIcon(wndCurr)
				tRewardString[strType] = self:HelperDrawRewardTooltip(tRewardInfo[idx], wndCurr, Apollo.GetString("CRB_Quest"), unitTarget:GetName(), tRewardString[strType])
				wndCurr:SetTooltip(tRewardString[strType])
				wndCurr:ToFront()
	
				if tRewardInfo[idx]["spell"] then
					self:HelperDrawSpellBind(wndCurr, 1)
				end
			elseif strType == "Challenge" then
				local bActiveChallenge = false
	
				local tAllChallenges = ChallengesLib.GetActiveChallengeList()
				for index, clgCurr in pairs(tAllChallenges) do
					if tRewardInfo[idx]["id"] == clgCurr:GetId() and clgCurr:IsActivated() and not clgCurr:IsInCooldown() and not clgCurr:ShouldCollectReward() then
						bActiveChallenge = true
						break
					end
				end
	
				if bActiveChallenge then
					local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, strType)
					nActiveRewardCount = nActiveRewardCount + self:HelperDrawRewardIcon(wndCurr)
					tRewardString[strType] = self:HelperDrawRewardTooltip(tRewardInfo[idx], wndCurr, Apollo.GetString("CBCrafting_Challenge"), unitTarget:GetName(), tRewardString[strType])
					wndCurr:SetTooltip(tRewardString[strType])
				end
			elseif strType == "Soldier" then
				local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, strType)
				nActiveRewardCount = nActiveRewardCount + self:HelperDrawRewardIcon(wndCurr)
				tRewardString[strType] = self:HelperDrawRewardTooltip(tRewardInfo[idx], wndCurr, Apollo.GetString("Nameplates_Mission"), unitTarget:GetName(), tRewardString[strType])
				wndCurr:SetTooltip(tRewardString[strType])
	
				if tRewardInfo[idx]["spell"] then
					self:HelperDrawSpellBind(wndCurr, strType)
				end
			elseif strType == "Settler" then
				local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, strType)
				nActiveRewardCount = nActiveRewardCount + self:HelperDrawRewardIcon(wndCurr)
				tRewardString[strType] = self:HelperDrawRewardTooltip(tRewardInfo[idx], wndCurr, Apollo.GetString("Nameplates_Mission"), unitTarget:GetName(), tRewardString[strType])
				wndCurr:SetTooltip(tRewardString[strType])
	
				if tRewardInfo[idx]["spell"] then
					self:HelperDrawSpellBind(wndCurr, strType)
				end
			elseif strType == "Scientist" then
				local pmMission = tRewardInfo[idx]["mission"]
				local splSpell = tRewardInfo[idx]["spell"]
				
				if pmMission then
					local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, strType)
				
					local strMission = ""
					if pmMission:GetMissionState() >= PathMission.PathMissionState_Unlocked then
						if pmMission:GetType() == PathMission.PathMissionType_Scientist_FieldStudy then
							strMission = String_GetWeaselString(Apollo.GetString("TargetFrame_MissionProgress"), pmMission:GetName(), pmMission:GetNumCompleted(), pmMission:GetNumNeeded())
							local tActions = pmMission:GetScientistFieldStudy()
							if tActions then
								for idx, tEntry in ipairs(tActions) do
									if not tEntry.completed then
										strMission = String_GetWeaselString(Apollo.GetString("TargetFrame_FieldStudyAction"), strMission , tEntry.name)
									end
								end
							end
						else
							strMission = String_GetWeaselString(Apollo.GetString("TargetFrame_MissionProgress"), pmMission:GetName(), pmMission:GetNumCompleted(), pmMission:GetNumNeeded())
						end
					else
						strMission = Apollo.GetString("TargetFrame_UnknownReward")
					end
					
					nActiveRewardCount = nActiveRewardCount + self:HelperDrawRewardIcon(wndCurr)
	
					local strProgress = "" -- specific to #7
					local strUnitName = unitTarget:GetName() -- specific to #7
					local strBracketText = Apollo.GetString("Nameplates_Missions") -- specific to #7
					if wndCurr:IsShown() then -- already have a tooltip
						tRewardString[strType] = string.format("%s<P Font=\"CRB_InterfaceMedium\" TextColor=\"ffffffff\">%s</P>", tRewardString[strType], strMission)
						
					else
						tRewardString[strType] = string.format("%s<P Font=\"CRB_InterfaceMedium\" TextColor=\"Yellow\">%s</P>"..
														 "<P Font=\"CRB_InterfaceMedium\">%s</P>", tRewardString[strType], String_GetWeaselString(Apollo.GetString("TargetFrame_HealthShieldText"), strUnitName, strBracketText), strMessage)
					end
	
					wndCurr:SetTooltip(tRewardString[strType])
				end

				if splSpell then
					local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, "ScientistSpell")
					nActiveRewardCount = nActiveRewardCount + self:HelperDrawRewardIcon(wndCurr)
					Tooltip.GetSpellTooltipForm(self, wndCurr, splSpell)
				end
			elseif strType == "Explorer" then
				local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, strType)
				nActiveRewardCount = nActiveRewardCount + self:HelperDrawRewardIcon(wndCurr)
				tRewardString[strType] = self:HelperDrawRewardTooltip(tRewardInfo[idx], wndCurr, "Mission", unitTarget:GetName(), tRewardString[strType])
				wndCurr:SetTooltip(tRewardString[strType])
	
				if tRewardInfo[idx]["spell"] then
					self:HelperDrawSpellBind(wndCurr, strType)
				end
			elseif strType == "PublicEvent" then
				local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, strType)
	
				local peEvent = tRewardInfo[idx].objective
				local strTitle = peEvent:GetEvent():GetName()
				local nCompleted = peEvent:GetCount()
				local nNeeded = peEvent:GetRequiredCount()
	
				nActiveRewardCount = nActiveRewardCount + self:HelperDrawRewardIcon(wndCurr)
	
				if wndCurr:IsShown() then -- already have a tooltip
					-- Do nothing. It has been cut below
				else
					local strPublicEventMarker = String_GetWeaselString(Apollo.GetString("Nameplates_PublicEvents"), unitTarget:GetName())
					tRewardString[strType] = string.format("<P Font=\"CRB_InterfaceMedium\" TextColor=\"Yellow\">%s</P>", strPublicEventMarker)
				end
	
				if peEvent:GetObjectiveType() == PublicEventObjective.PublicEventObjectiveType_Exterminate then
					strNumRemaining = String_GetWeaselString(Apollo.GetString("Nameplates_NumRemaining"), strTitle, nCompleted)
					tRewardString[strType] = string.format("%s<P Font=\"CRB_InterfaceMedium\">%s</P>", tRewardString[strType], strNumRemaining)
				elseif peEvent:ShowPercent() then
					strPercentCompleted = String_GetWeaselString(Apollo.GetString("Nameplates_PercentCompleted"), strTitle, nCompleted / nNeeded * 100)
					tRewardString[strType] = string.format("%s<P Font=\"CRB_InterfaceMedium\">%s</P>", tRewardString[strType], strPercentCompleted)
				else
					tRewardString[strType] = string.format("%s<P Font=\"CRB_InterfaceMedium\">%s</P>", tRewardString[strType], String_GetWeaselString(Apollo.GetString("BuildMap_CategoryProgress"), strTitle, nCompleted, nNeeded))
				end
	
				wndCurr:ToFront()
				wndCurr:SetTooltip(tRewardString[strType])
			end
		end
	end
	 
	if bIsRival then
		local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, "Rival")
		if (wndCurr) then
			nActiveRewardCount = nActiveRewardCount + self:HelperDrawRewardIcon(wndCurr)
			tRewardString["Rival"] = self:HelperDrawBasicRewardTooltip(wndCurr, Apollo.GetString("TargetFrame_Rival"), unitTarget:GetName(), tRewardString["Rival"])
			wndCurr:SetTooltip(tRewardString["Rival"])
		end
	end
	
	if bIsFriend then
		local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, "Friend")
		if (wndCurr) then
			nActiveRewardCount = nActiveRewardCount + self:HelperDrawRewardIcon(wndCurr)
			tRewardString["Friend"] = self:HelperDrawBasicRewardTooltip(wndCurr, Apollo.GetString("TargetFrame_Friend"), unitTarget:GetName(), tRewardString["Friend"])
			wndCurr:SetTooltip(tRewardString["Friend"])
		end
	end
	if bIsAccountFriend then
		local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, "Friend")
		if (wndCurr) then
			nActiveRewardCount = nActiveRewardCount + self:HelperDrawRewardIcon(wndCurr)
			tRewardString["Friend"] = self:HelperDrawBasicRewardTooltip(wndCurr, Apollo.GetString("TargetFrame_AccountFriend"), unitTarget:GetName(), tRewardString["Friend"])
			wndCurr:SetTooltip(tRewardString["Friend"])
		end
	end
	
	if nActiveRewardCount > 0 then
	
		local nLeft, nTop, nRight, nBottom = wndRewardPanel:GetAnchorOffsets()
		local nVertOffset = -5
		
		if wndTarget == self.wndSimpleFrame then
			nVertOffset = -8
		end
		
		local nOffsettedTop = knRewardAnchorVertOffset*nActiveRewardCount*-1+nVertOffset
		local nOffsettedBottom = knRewardAnchorVertOffset*nActiveRewardCount+nVertOffset
		
		wndRewardPanel:SetAnchorOffsets(nLeft, nOffsettedTop, nRight, nOffsettedBottom)
		
		wndRewardPanel:ArrangeChildrenVert(1)
	end
 

	wndRewardPanel:Show(nActiveRewardCount > 0)
end

function TargetFrame:HelperLoadRewardIcon(wndRewardPanel, strType)
	local wndCurr = wndRewardPanel:FindChild(strType)
	if wndCurr then
		return wndCurr
	end

	wndCurr = Apollo.LoadForm("ui\\TargetFrame\\TargetRewardPanel.xml", "RewardIcon", wndRewardPanel, self)
	
	wndCurr:SetName(strType)
	wndCurr:Show(false) -- Visibility is important
	
	wndCurr:FindChild("Single"):SetSprite(karRewardIcons[strType].strSingle)
	wndCurr:FindChild("Multi"):SetSprite(karRewardIcons[strType].strMulti)

	return wndCurr

end

function TargetFrame:HelperDrawRewardIcon(wndRewardIcon)
	if not wndRewardIcon then
		return 0
	end
	local nResult = 0

	if wndRewardIcon:FindChild("Multi") then -- Show multi if the Single icon if the window is already visible
		wndRewardIcon:FindChild("Multi"):Show(wndRewardIcon:IsShown())
		wndRewardIcon:FindChild("Multi"):ToFront()
	end

	if not wndRewardIcon:IsShown() then -- Plus one to the counter if this is the first instance
		nResult = 1
	end

	wndRewardIcon:Show(true) -- At the very end
	return nResult
end

function TargetFrame:HelperDrawRewardTooltip(tRewardInfo, wndRewardIcon, strBracketText, strUnitName, tRewardString)
	if not tRewardInfo or not wndRewardIcon then
		return
	end
	tRewardString = tRewardString or ""

	local strMessage = tRewardInfo["title"]
	if tRewardInfo["mission"] and tRewardInfo["mission"]:GetName() then
		local pmMission = tRewardInfo["mission"]
		if tRewardInfo["isActivate"] and PlayerPathLib.GetPlayerPathType() ~= PlayerPathLib.PlayerPathType_Explorer then -- todo: see if we can remove this requirement
			strMessage = String_GetWeaselString(Apollo.GetString("Nameplates_ActivateForMission"), pmMission:GetName())
		else
			strMessage = String_GetWeaselString(Apollo.GetString("TargetFrame_MissionProgress"), pmMission:GetName(), pmMission:GetNumCompleted(), pmMission:GetNumNeeded())
		end
	end

	local strProgress = ""
	local nNeeded = tRewardInfo["needed"]
	local nCompleted = tRewardInfo["completed"]
	if nCompleted and nNeeded then
		strProgress = String_GetWeaselString(Apollo.GetString("TargetFrame_Progress"), nCompleted, nNeeded)
	end

	local strNewEntry = ""
	if wndRewardIcon:IsShown() then -- already have a tooltip
		strNewEntry = string.format("<P Font=\"CRB_InterfaceMedium\" TextColor=\"ffffffff\">%s</P>", String_GetWeaselString(Apollo.GetString("TargetFrame_RewardProgressTooltip"), strBracketText, strMessage, strProgress))
		tRewardString = tRewardString .. strNewEntry
	else
		strNewEntry = string.format("<P Font=\"CRB_InterfaceMedium\" TextColor=\"Yellow\">%s</P><P Font=\"CRB_InterfaceMedium\">%s%s</P>", String_GetWeaselString(Apollo.GetString("TargetFrame_UnitText"), strUnitName, strBracketText), String_GetWeaselString(Apollo.GetString("TargetFrame_ShortProgress"), strMessage, strProgress))
		tRewardString = tRewardString .. strNewEntry
		wndRewardIcon:SetTooltip(tRewardString)
	end

	return tRewardString
end

function TargetFrame:HelperDrawBasicRewardTooltip(wndRewardIcon, strBracketText, strUnitName, tRewardString)
	if not wndRewardIcon then
		return
	end
	tRewardString = tRewardString or ""

	return string.format("%s<P Font=\"CRB_InterfaceMedium\" TextColor=\"ffffffff\">%s</P>", tRewardString, strBracketText)
end

function TargetFrame:HelperDrawSpellBind(wndIcon, strType)
	if strType ~= "Quest" then -- paths, not quest
		if self.bPathActionUsesIcon then
			wndIcon:FindChild("TargetMark"):Show(true)
			wndIcon:FindChild("Bind"):SetText("")
		else
			wndIcon:FindChild("TargetMark"):Show(false)
			wndIcon:FindChild("Bind"):SetText(self.strPathActionKeybind)
		end
	else -- quest
		if self.bQuestActionUsesIcon then
			wndIcon:FindChild("TargetMark"):Show(true)
			wndIcon:FindChild("Bind"):SetText("")
		else
			wndIcon:FindChild("TargetMark"):Show(false)
			wndIcon:FindChild("Bind"):SetText(self.strQuestActionKeybind)
		end
	end
end

function TargetFrame:SetTargetHealthAndShields(wndTargetFrame, unitTarget)
	if not unitTarget or unitTarget:GetHealth() == nil then
		return
	end

	if unitTarget:GetType() == "Simple" then -- String Comparison, should replace with an enum
		self.wndRankedFrame:FindChild("HealthText"):SetText("")
		self.wndRankedFrame:FindChild("MaxShield"):Show(false)
		self.wndRankedFrame:FindChild("MaxAbsorb"):Show(false)
		self.wndRankedFrame:FindChild("MaxHealth"):SetSprite("CRB_TargetFrameSprites:sprTF_HealthFill_Green")
		self.wndRankedFrame:FindChild("MaxHealth"):SetAnchorOffsets(self.nLFrameLeft, self.nLFrameTop, self.nLFrameRight, self.nLFrameBottom)
		return
	end

	local nHealthCurr = unitTarget:GetHealth()
	local nHealthMax = unitTarget:GetMaxHealth()
	local nShieldCurr = unitTarget:GetShieldCapacity()
	local nShieldMax = unitTarget:GetShieldCapacityMax()
	local nAbsorbCurr = 0
	local nAbsorbMax = unitTarget:GetAbsorptionMax()
	if nAbsorbMax > 0 then
		nAbsorbCurr = unitTarget:GetAbsorptionValue() -- Since it doesn't clear when the buff drops off
	end
	local nTotalMax = nHealthMax + nShieldMax + nAbsorbMax

	if unitTarget:IsInCCState(Unit.CodeEnumCCState.Vulnerability) then
		self.wndRankedFrame:FindChild("MaxHealth"):SetSprite("CRB_TargetFrameSprites:sprTF_HealthFill_Vulnerable")
	else
		self.wndRankedFrame:FindChild("MaxHealth"):SetSprite("CRB_NameplateSprites:sprNp_HealthBarFriendly")
	end
	
--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
	local eDisposition = unitTarget:GetDispositionTo(GameLib.GetPlayerUnit())
	local playerFaction = GameLib.GetPlayerUnit():GetFaction()
	local targetFaction = GameLib.GetTargetUnit():GetFaction()

	--if unitTarget:GetType() == "Player" and unitTarget:GetDispositionTo() ==  then
		--self.wndRankedFrame:FindChild("MaxHealth"):SetSprite("CRB_Raid:sprRaid_HealthProgBar_Green")
	if ((unitTarget:GetType() == "Player" or unitTarget:GetType() == "Pet") and playerFaction ~= targetFaction) then
	 	self.wndRankedFrame:FindChild("MaxHealth"):SetSprite("WhiteFill")
		self.wndRankedFrame:FindChild("MaxHealth"):SetBGColor(npClassColors[unitTarget:GetClassId()])
		if unitTarget:GetType() == "Pet" then
			wndHealth:FindChild("MaxHealth"):SetBGColor("FFbed497")
		end
	elseif unitTarget:GetType() == "Player" and playerFaction == targetFaction then
		self.wndRankedFrame:FindChild("MaxHealth"):SetSprite("GreenCastBar")
	elseif unitTarget:GetType() == "NonPlayer" then
		self.wndRankedFrame:FindChild("MaxHealth"):SetSprite(karDispositionHealthBar[eDisposition])
    end



--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------


	local nPointHealthRight = nil
	local nPointShieldRight = nil
	local nPointAbsorbRight = nil

	-- Scaling
	nPointHealthRight = self.nLFrameRight * (nHealthCurr / nHealthMax)
	nPointShieldRight = self.nLFrameRight * ((nHealthCurr + nShieldMax) / nTotalMax)
	nPointAbsorbRight = self.nLFrameRight * ((nHealthCurr + nShieldMax + nAbsorbMax) / nTotalMax)

	if nShieldMax > 0 and nShieldMax / nTotalMax < 0.2 then
		local nMinShieldSize = 0.0 -- HARDCODE: Minimum shield bar length is 20% of total for formatting
		--nPointHealthRight = self.nLFrameRight * math.min(1 - nMinShieldSize, nHealthCurr / nTotalMax) -- Health is normal, but caps at 80%
		nPointShieldRight = self.nLFrameRight * math.min(1, (nHealthCurr / nTotalMax) + nMinShieldSize) + (nShieldCurr / nTotalMax) -- If not 1, the size is thus healthbar + hard minimum
	end

	-- Resize
	self.wndRankedFrame:FindChild("ShieldCapacityTint"):EnableGlow(nShieldCurr > 0)
	self:SetBarValue(self.wndRankedFrame:FindChild("ShieldCapacityTint"), 0, nShieldCurr, nShieldMax) -- Only the Curr Shield really progress fills
	self:SetBarValue(self.wndRankedFrame:FindChild("AbsorbCapacityTint"), 0, nAbsorbCurr, nAbsorbMax)

	self.wndRankedFrame:FindChild("MaxHealth"):SetAnchorOffsets(self.nLFrameLeft, self.nLFrameTop, nPointHealthRight, self.nLFrameBottom)
	--self.wndRankedFrame:FindChild("MaxShield"):SetAnchorOffsets(nPointHealthRight, self.nLFrameTop, nPointShieldRight, self.nLFrameBottom)
	--self.wndRankedFrame:FindChild("MaxAbsorb"):SetAnchorOffsets(nPointShieldRight - 14, self.nLFrameTop, nPointAbsorbRight, self.nLFrameBottom)	
		
	if nShieldMax == 0 then
		self.wndRankedFrame:FindChild("MaxHealth"):SetAnchorOffsets(self.nAltHealthLeft, self.nAltHealthTop, nPointHealthRight, self.nAltHealthBottom)
	end

	-- Bars
	self.wndRankedFrame:FindChild("MaxHealth"):Show(nHealthCurr > 0)
	self.wndRankedFrame:FindChild("MaxShield"):Show(nHealthCurr > 0 and nShieldMax > 0)-- and unitTarget:ShouldShowShieldCapacityBar())
	self.wndRankedFrame:FindChild("MaxAbsorb"):Show(nHealthCurr > 0 and nAbsorbMax > 0)-- and unitTarget:ShouldShowShieldCapacityBar())

	-- String
	local strHealthMax = self:HelperFormatBigNumber(nHealthMax)
	local strHealthCurr = self:HelperFormatBigNumber(nHealthCurr)
	local strShieldCurr = self:HelperFormatBigNumber(nShieldCurr)
	local strAbsorbCurr = self:HelperFormatBigNumber(nAbsorbCurr)
	--local HealthBarPercentage 
	
	
	local strText = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthText"), strHealthCurr, strHealthMax)
	if nShieldMax > 0 and nShieldCurr > 0 then
		--strText = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthShieldText"), strText, strShieldCurr)
		strText = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthText"), strHealthCurr, strHealthMax)
	end
	self.wndRankedFrame:FindChild("HealthText"):SetText(strText)
	
	
	if nShieldCurr == 0 and nAbsorbCurr == 0 then
		self.wndRankedFrame:FindChild("ShieldText"):SetText("")
	end
	
	if nShieldCurr > 0 or nAbsorbCurr > 0 then
		self.wndRankedFrame:FindChild("ShieldText"):SetText(nShieldCurr + nAbsorbCurr)
	end
	
	if unitTarget:IsDead() then
		self.wndRankedFrame:FindChild("LargeBarContainer"):SetSprite("CRB_TooltipSprites:sprTT_HeaderGrey")
		self.wndRankedFrame:FindChild("HealthText"):SetText("Dead")
		self.wndRankedFrame:FindChild("HealthPercentage"):Show(false)
	elseif not unitTarget:IsDead() then
		self.wndRankedFrame:FindChild("LargeBarContainer"):SetSprite("")
		self.wndRankedFrame:FindChild("HealthPercentage"):Show(true)
	end
end


function TargetFrame:HelperFormatBigNumber(nArg)
	-- Turns 99999 into 99.9k and 90000 into 90k
	local strResult
	if nArg < 1000 then
		strResult = tostring(nArg)
	elseif math.floor(nArg%1000/100) == 0 then
		strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_ShortNumberWhole"), math.floor(nArg / 1000))
	else
		strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_ShortNumberFloat"), nArg / 1000)
	end
	return strResult
end

function TargetFrame:SetBarValue(wndBar, fMin, fValue, fMax)
	wndBar:SetMax(fMax)
	wndBar:SetFloor(fMin)
	wndBar:SetProgress(fValue)
end

function TargetFrame:OnGenerateBuffTooltip(wndHandler, wndControl, tType, splBuff)
	if wndHandler == wndControl then
		return
	end
	Tooltip.GetBuffTooltipForm(self, wndControl, splBuff, {bFutureSpell = false})
end

function TargetFrame:OnMouseButtonDown(wndHandler, wndControl, eButton, x, y, bDouble)
	local unitToT = wndHandler:GetData()
	if eButton == 0 and unitToT ~= nil then
		GameLib.SetTargetUnit(unitToT)
		return false
	end
	if eButton == 1 and unitToT ~= nil then
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", wndHandler, unitToT:GetName(), unitToT)
		return true
	end

	if IsDemo() then
		return true
	end

	return false
end

function TargetFrame:OnQueryDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, nValue)
	if wndHandler ~= wndControl then
		return Apollo.DragDropQueryResult.PassOn
	end

	local unitToT = GameLib.GetTargetUnit()
	if unitToT == nil then
		return Apollo.DragDropQueryResult.Invalid
	end
	if unitToT:IsACharacter() and not unitToT:IsThePlayer() and strType == "DDBagItem" then
		return Apollo.DragDropQueryResult.Accept
	end
	return Apollo.DragDropQueryResult.Invalid
end

function TargetFrame:OnDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, nValue)
	if wndHandler ~= wndControl then
		return false
	end

	local unitToT = GameLib.GetTargetUnit()
	if unitToT == nil then
		return false
	end
	if unitToT:IsACharacter() and not unitToT:IsThePlayer() and strType == "DDBagItem" then
		Event_FireGenericEvent("ItemDropOnTarget", unit, strType, nValue)
		return false
	end
end

function TargetFrame:OnKeyBindingUpdated(strKeybind)
	if strKeybind ~= "Path Action" and strKeybind ~= "Cast Objective Ability" then
		return
	end

	self.strPathActionKeybind = GameLib.GetKeyBinding("PathAction")
	self.bPathActionUsesIcon = false
	if self.strPathActionKeybind == "Unbound" or #self.strPathActionKeybind > 1 then -- Don't show interact
		self.bPathActionUsesIcon = true
	end

	self.strQuestActionKeybind = GameLib.GetKeyBinding("CastObjectiveAbility")
	self.bQuestActionUsesIcon = false
	if self.strQuestActionKeybind == "Unbound" or #self.strQuestActionKeybind > 1 then -- Don't show interact
		self.bQuestActionUsesIcon = true
	end
end

function TargetFrame:OnGenericEvent_ToggleNameplate_bDrawToT(bNewValue)
	self.bDrawToT = bNewValue
end

local TargetFrameInstance = TargetFrame:new()
TargetFrame:Init()

