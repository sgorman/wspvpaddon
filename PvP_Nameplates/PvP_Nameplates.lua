-----------------------------------------------------------------------------------------------
-- Client Lua Script for Nameplates
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "ChallengesLib"
require "Unit"
require "GameLib"
require "Apollo"
require "PathMission"
require "Quest"
require "Episode"
require "math"
require "string"
require "DialogSys"
require "PublicEvent"
require "PublicEventObjective"
require "CommunicatorLib"
require "Tooltip"
require "GroupLib"
require "PlayerPathLib"
require "GuildLib"
require "GuildTypeLib"

local Nameplates = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local karDisposition = {}
karDisposition.TextColors =
{
	[Unit.CodeEnumDisposition.Hostile] 	= "White",
	[Unit.CodeEnumDisposition.Neutral] 	= "White",
	[Unit.CodeEnumDisposition.Friendly] = "White",
	--[Unit.CodeEnumDisposition.Hostile] 	= ApolloColor.new("DispositionHostile"),
	--[Unit.CodeEnumDisposition.Neutral] 	= ApolloColor.new("DispositionNeutral"),
	--[Unit.CodeEnumDisposition.Friendly] = ApolloColor.new("DispositionFriendly"),
}

karDisposition.TargetPrimary =
{
	[Unit.CodeEnumDisposition.Hostile] 	= "sprNp_Target_HostilePrimary",
	[Unit.CodeEnumDisposition.Neutral] 	= "sprNp_Target_NeutralPrimary",
	[Unit.CodeEnumDisposition.Friendly] = "sprNp_Target_FriendlyPrimary",
}

karDisposition.TargetSecondary =
{
	[Unit.CodeEnumDisposition.Hostile] 	= "sprNp_Target_HostileSecondary",
	[Unit.CodeEnumDisposition.Neutral] 	= "sprNp_Target_NeutralSecondary",
	[Unit.CodeEnumDisposition.Friendly] = "sprNp_Target_FriendlySecondary",
}

karDisposition.HealthBar =
{
	[Unit.CodeEnumDisposition.Hostile] 	= "CRB_Raid:sprRaid_HealthProgBar_Red",
	[Unit.CodeEnumDisposition.Neutral] 	= "CRB_Raid:sprRaid_HealthProgBar_Orange",
	[Unit.CodeEnumDisposition.Friendly] = "CRB_Raid:sprRaid_HealthProgBar_Green",
}

local ktHealthBarSprites =
{
	-- "sprNp_Health_FillGreen",
	-- "sprNp_Health_FillOrange",
	-- "sprNp_Health_FillRed"

	
	"CRB_Raid:sprRaid_HealthProgBar_Green",	
	"CRB_Raid:sprRaid_HealthProgBar_Orange",
	"CRB_Raid:sprRaid_HealthProgBar_Red"
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


local karConColors =  -- differential value, color
{
	{-4, ApolloColor.new("ConTrivial")},
	{-3, ApolloColor.new("ConInferior")},
	{-2, ApolloColor.new("ConMinor")},
	{-1, ApolloColor.new("ConEasy")},
	{0, ApolloColor.new("ConAverage")},
	{1, ApolloColor.new("ConModerate")},
	{2, ApolloColor.new("ConTough")},
	{3, ApolloColor.new("ConHard")},
	{4, ApolloColor.new("ConImpossible")}
}

local kcrScalingHex 	= "ffffbf80"
local kcrScalingCColor 	= CColor.new(1.0, 191/255, 128/255, 0.7)

local karPathSprite =
{
	[PlayerPathLib.PlayerPathType_Soldier] 		= "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSol",
	[PlayerPathLib.PlayerPathType_Settler] 		= "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSet",
	[PlayerPathLib.PlayerPathType_Scientist] 	= "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSci",
	[PlayerPathLib.PlayerPathType_Explorer] 	= "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathExp",
}

local knCharacterWidth 		= 8 -- the average width of a character in the font used. TODO: Not this.
local knRewardWidth 		= 23 -- the width of a reward icon + padding
local knTextHeight 			= 15 -- text window height
local knNameRewardWidth 	= 400 -- the width of the name/reward container
local knNameRewardHeight 	= 22 -- the width of the name/reward container
local knTargetRange 		= 40000 -- the distance^2 that normal nameplates should draw within (max targeting range)

-- Todo: break these out onto options
local kcrWarPartyTextColor 				= ApolloColor.new("crayBlizzardBlue")
local kcrFlaggedFriendlyTextColor 		= "FFFFFFAA"
local kcrDefaultGuildmemberTextColor 	= ApolloColor.new("DispositionFriendly")
local kcrAggressiveEnemyTextColor 		= ApolloColor.new("DispositionHostile")
local kcrNeutralEnemyTextColor 			= "FFFF6A6A"
local kcrDefaultUnflaggedAllyTextColor 	= "FFFFFFFF"
--local kcrFlaggedFriendlyTextColor = ApolloColor.new("crayPurpleHeart")
--local kcrAggressiveEnemyTextColor = ApolloColor.new("crayOrange")
--local kcrNeutralEnemyTextColor = ApolloColor.new("DispositionNeutral")
--local kcrDefaultUnflaggedAllyTextColor = ApolloColor.new("crayDenim")

local kcrDefaultTaggedColor = "WhiteFill"

local karSavedProperties =
{
	--General nameplate drawing
	"bShowMainAlways",
	"bShowMainObjectiveOnly",
	"bShowMainGroupOnly",
	"bShowMyNameplate",
	"tShowDispositionOnly",
	--Draw distance
	"nMaxRange",
	--Name and title
	"bShowNameMain",
	"bShowTitle",
	--Reward icons
	"bShowRewardsMain",
	"bShowRewardTypeQuest",
	"bShowRewardTypeMission",
	"bShowRewardTypeAchievement",
	"bShowRewardTypeChallenge",
	"bShowRewardTypeReputation",
	"bShowRewardTypePublicEvent",
	"bShowRivals",
	"bShowFriends",
	--Info panel
	"bShowHealthMain",
	"bShowHealthMainDamaged",
	--Guild name/emblem
	"bShowGuildNameMain",
	--Cast bar
	"bShowCastBarMain",
	--target components
	"bShowMarkerTarget",
	"bShowNameTarget",
	"bShowRewardsTarget",
	"bShowGuildNameTarget",
	"bShowHealthTarget",
	"bShowCastBarTarget",
	--Non-targeted nameplates in combat
	"bHideInCombat"
}

function Nameplates:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Nameplates:Init()
    Apollo.RegisterAddon(self, true)
end

-----------------------------------------------------------------------------------------------
-- Nameplates OnLoad
-----------------------------------------------------------------------------------------------

function Nameplates:OnLoad()
    -- Register handlers for events, slash commands and timer, etc.
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
	Apollo.LoadSprites("Sprites.xml")

	Apollo.RegisterSlashCommand("Nameplates", 					"OnNameplatesOn", self)
	Apollo.RegisterSlashCommand("nameplates", 					"OnNameplatesOn", self)
	Apollo.RegisterSlashCommand("Nameplates_OpenMenu", 			"OnNameplatesOn", self)

	Apollo.RegisterEventHandler("UnitCreated", 					"OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", 				"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitTextBubbleCreate", 		"OnUnitTextBubbleToggled", self)
	Apollo.RegisterEventHandler("UnitTextBubblesDestroyed", 	"OnUnitTextBubbleToggled", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", 			"OnTargetUnitChanged", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnEnteredCombat", self)
	Apollo.RegisterEventHandler("VarChange_FrameCount", 		"OnFrame", self)
	Apollo.RegisterEventHandler("UnitNameChanged", 				"OnUnitNameChanged", self)
	Apollo.RegisterEventHandler("KeyBindingKeyChanged", 		"OnKeyBindingUpdated", self)
	Apollo.RegisterEventHandler("UnitPvpFlagsChanged", 			"OnUnitPvpFlagsChanged", self)
	Apollo.RegisterEventHandler("UnitTitleChanged", 			"OnUnitTitleChanged", self)
	Apollo.RegisterEventHandler("PlayerTitleChange", 			"OnPlayerTitleChanged", self)
	Apollo.RegisterEventHandler("UnitGuildNameplateChanged", 	"OnUnitGuildNameplateChanged",self)
	Apollo.RegisterEventHandler("ApplyCCState", 				"OnApplyCCState", self)
	Apollo.RegisterEventHandler("RemoveCCState", 				"OnRemoveCCState", self)
	Apollo.RegisterEventHandler("UnitLevelChanged", 			"OnUnitLevelChanged", self)

	Apollo.RegisterEventHandler("UnitMemberOfGuildChange", 		"OnUnitMemberOfGuildChange", self)
	Apollo.RegisterEventHandler("GuildChange", 					"OnGuildChange", self)  -- notification that a guild was added / removed.
	Apollo.RegisterEventHandler("ChangeWorld", 					"OptionsChanged", self)
	
	Apollo.RegisterEventHandler("CharacterCreated", 			"OptionsChanged", self)

	-- These events update the reward icons/quest framing
	Apollo.RegisterEventHandler("QuestInit", 					"OnQuestInit", self)
	Apollo.RegisterEventHandler("QuestStateChanged", 			"OnQuestStateChanged", self)
	Apollo.RegisterEventHandler("UnitActivationTypeChanged", 	"OnUnitActivationTypeChanged", self)
	Apollo.RegisterEventHandler("QuestObjectiveUpdated", 		"OnQuestObjectiveUpdated", self)
	Apollo.RegisterEventHandler("PublicEventStart", 			"OnPublicEventStart", self)
	Apollo.RegisterEventHandler("PublicEventObjectiveUpdate", 	"OnPublicEventObjectiveUpdate", self)
	Apollo.RegisterEventHandler("PublicEventEnd", 				"OnPublicEventEnd", self)
	Apollo.RegisterEventHandler("ChallengeUnlocked", 			"OnChallengeUnlocked", self)
	Apollo.RegisterEventHandler("ChallengeFailArea", 			"OnChallengeFailArea", self)
    Apollo.RegisterEventHandler("ChallengeFailTime", 			"OnChallengeFailTime", self)
	Apollo.RegisterEventHandler("ChallengeActivate",			"OnChallengeActivate", self)
	Apollo.RegisterEventHandler("ChallengeCompleted", 			"OnChallengeCompleted", self)
	Apollo.RegisterEventHandler("ChallengeAbandon", 			"OnChallengeCompleted", self)
	Apollo.RegisterEventHandler("PlayerPathMissionUnlocked", 	"OnPlayerPathMissionChange", self)
	Apollo.RegisterEventHandler("PlayerPathMissionUpdate", 		"OnPlayerPathMissionChange", self)
	Apollo.RegisterEventHandler("PlayerPathMissionComplete", 	"OnPlayerPathMissionChange", self)
	Apollo.RegisterEventHandler("PlayerPathMissionDeactivate", 	"OnPlayerPathMissionChange", self)
	Apollo.RegisterEventHandler("PlayerPathMissionActivate", 	"OnPlayerPathMissionChange", self)
	
	Apollo.RegisterTimerHandler("InitialParseTimer", 			"OptionsChanged", self)
	print(GetClassId)

	Apollo.CreateTimer("InitialParseTimer", 1.0, false)
	Apollo.StopTimer("InitialParseTimer")

	-------form setup starts below----------
	self.xmlDoc = XmlDoc.CreateFromFile("PvP_Nameplates.xml")

    self.wndMain 				= Apollo.LoadForm(self.xmlDoc, "NameplatesForm", nil, self)
	self.wndOptionsMain 		= Apollo.LoadForm(self.xmlDoc, "StandardModule", self.wndMain:FindChild("ContentMain"), self)
	self.wndOptionsTargeted 	= Apollo.LoadForm(self.xmlDoc, "TargetedModule", self.wndMain:FindChild("ContentTarget"), self)
	self.wndMain:Show(false)
	self.wndMain:FindChild("ContentMain"):Show(true)
	self.wndMain:FindChild("ContentTarget"):Show(false)
	self.wndMain:FindChild("NormalViewCheck"):SetCheck(true)

	self.unitPlayerDisposComparisonTEMP 	= nil
	self.bInitialLoadAllClear 				= false -- delays drawing until everything's come in
	self.arDisplayedNameplates 				= {}
	self.arUnit2Nameplate 					= {}
	self.arFreeWindows 						= {}

	self.bPlayerInCombat 	= false
	self.bRewardInfoDirty 	= false

	-- display option set for main plates
	self.bShowMainAlways			= false
	self.bShowMainObjectiveOnly 	= true
	self.bShowMainGroupOnly 		= false
	self.bShowMyNameplate 			= false

	self.wndOptionsMain:FindChild("MainShowAlways"):SetCheck(self.bShowMainAlways)
	self.wndOptionsMain:FindChild("MainShowNever"):SetCheck(false)
	self.wndOptionsMain:FindChild("MainShowObjectives"):SetCheck(self.bShowMainObjectiveOnly)
	self.wndOptionsMain:FindChild("MainShowGroup"):SetCheck(self.bShowMainGroupOnly)
	self.wndOptionsMain:FindChild("MainShowMine"):SetCheck(self.bShowMyNameplate)

		
	self.tShowDispositionOnly =
	{
		true, -- hostile
		true, -- neutral
		false, -- friendly
	}

	for idx = 1, 3 do
		self.wndOptionsMain:FindChild("MainShowDisposition_" .. idx):SetCheck(self.tShowDispositionOnly[idx])
	end

	self.bShowHealthMain 			= false
	self.bShowHealthMainDamaged 	= true

	self.wndOptionsMain:FindChild("MainShowHealthBarDamaged"):SetCheck(true)
	self.wndOptionsMain:FindChild("MainShowHealthBarAlways"):SetData(1)
	self.wndOptionsMain:FindChild("MainShowHealthBarDamaged"):SetData(2)
	self.wndOptionsMain:FindChild("MainShowHealthBarNever"):SetData(3)

	self.bShowNameMain 					= true
	self.bShowTitle 					= true
	self.bShowRewardsMain 				= true
	self.bShowRewardTypeQuest 			= true
	self.bShowRewardTypeChallenge 		= true
	self.bShowRewardTypeAchievement 	= false
	self.bShowRewardTypeReputation 		= false
	self.bShowRewardTypeMission 		= true
	self.bShowRewardTypePublicEvent 	= true

	self.wndOptionsMain:FindChild("MainShowNameAlways"):SetCheck(self.bShowNameMain)
	self.wndOptionsMain:FindChild("MainShowRewards"):SetCheck(self.bShowRewardsMain)
	self.wndOptionsMain:FindChild("MainShowRewardsOff"):SetCheck(not self.bShowRewardsMain)
	self.wndOptionsMain:FindChild("ShowRewardTypeQuest"):SetCheck(self.bShowRewardTypeQuest)
	self.wndOptionsMain:FindChild("ShowRewardTypeChallenge"):SetCheck(self.bShowRewardTypeChallenge)
	self.wndOptionsMain:FindChild("ShowRewardTypeAchievement"):SetCheck(self.bShowRewardTypeAchievement)
	self.wndOptionsMain:FindChild("ShowRewardTypeReputation"):SetCheck(self.bShowRewardTypeReputation)
	self.wndOptionsMain:FindChild("ShowRewardTypeMission"):SetCheck(self.bShowRewardTypeMission)
	self.wndOptionsMain:FindChild("ShowRewardTypePublicEvent"):SetCheck(self.bShowRewardTypePublicEvent)

	--self.bShowVulnerableMain = false
	--self.wndOptionsMain:FindChild("MainShowVulnerable"):SetCheck(self.bShowVulnerableMain)
	--self.wndOptionsMain:FindChild("MainShowVulnerableOff"):SetCheck(not self.bShowVulnerableMain)
	self.bShowCastBarMain 		= false
	self.bShowGuildNameMain		= true

	self.wndOptionsMain:FindChild("MainShowCastBar"):SetCheck(self.bShowCastBarMain)
	self.wndOptionsMain:FindChild("MainShowCastBarOff"):SetCheck(not self.bShowCastBarMain)
	self.wndOptionsMain:FindChild("MainShowGuild"):SetCheck(self.bShowGuildNameMain)
	self.wndOptionsMain:FindChild("MainShowGuildOff"):SetCheck(not self.bShowGuildNameMain)

	-- display option set for target plates
	self.bShowMarkerTarget		= true
	self.bShowNameTarget 		= true
	self.bShowGuildNameTarget 	= true
	self.bShowHealthTarget 		= true
	self.bShowRewardsTarget 	= true
	self.bShowRangeTarget 		= false
	self.bShowCastBarTarget 	= true
	self.bHideInCombat 			= false

	self.wndOptionsTargeted:FindChild("TargetedShowMarker"):SetCheck(self.bShowMarkerTarget)
	self.wndOptionsTargeted:FindChild("TargetedShowMarkerOff"):SetCheck(not self.bShowMarkerTarget)
	self.wndOptionsTargeted:FindChild("TargetedShowName"):SetCheck(self.bShowNameTarget)
	self.wndOptionsTargeted:FindChild("TargetedShowNameOff"):SetCheck(not self.bShowNameTarget)
	self.wndOptionsTargeted:FindChild("TargetedShowGuild"):SetCheck(self.bShowGuildNameTarget)
	self.wndOptionsTargeted:FindChild("TargetedShowGuildOff"):SetCheck(not self.bShowGuildNameTarget)
	self.wndOptionsTargeted:FindChild("TargetedShowHealthBar"):SetCheck(self.bShowHealthTarget)
	self.wndOptionsTargeted:FindChild("TargetedShowHealthBarOff"):SetCheck(not self.bShowHealthTarget)
	self.wndOptionsTargeted:FindChild("TargetedShowRewards"):SetCheck(self.bShowRewardsTarget)
	self.wndOptionsTargeted:FindChild("TargetedShowRewardsOff"):SetCheck(not self.bShowRewardsTarget)
	self.wndOptionsTargeted:FindChild("TargetedShowRange"):SetCheck(self.bShowRangeTarget)
	self.wndOptionsTargeted:FindChild("TargetedShowRangeOff"):SetCheck(not self.bShowRangeTarget)
	--self.bShowVulnerableTarget = true
	--self.wndOptionsTargeted:FindChild("TargetedShowVulnerable"):SetCheck(self.bShowVulnerableTarget)
	--self.wndOptionsTargeted:FindChild("TargetedShowVulnerableOff"):SetCheck(not self.bShowVulnerableTarget)
	self.wndOptionsTargeted:FindChild("TargetedShowCastBar"):SetCheck(self.bShowCastBarTarget)
	self.wndOptionsTargeted:FindChild("TargetedShowCastBarOff"):SetCheck(not self.bShowCastBarTarget)
	self.wndOptionsTargeted:FindChild("MainHideInCombat"):SetCheck(self.bHideInCombat)
	self.wndOptionsTargeted:FindChild("MainHideInCombatOff"):SetCheck(not self.bHideInCombat)

	self.bBlinded = false

	self.nMaxRange = self.wndOptionsMain:FindChild("DrawDistanceSlider"):GetValue()
	self.wndOptionsMain:FindChild("DrawDistanceLabel"):SetText(String_GetWeaselString(Apollo.GetString("Nameplates_DrawDistance"), self.nMaxRange))

	self.strPathActionKeybind = GameLib.GetKeyBinding("PathAction")
	self.bPathActionUsesIcon = false
	if self.strPathActionKeybind == Apollo.GetString("HUDAlert_Unbound") or #self.strPathActionKeybind > 1 then -- Don't show interact
		self.bPathActionUsesIcon = true
	end

	self.strQuestActionKeybind = GameLib.GetKeyBinding("CastObjectiveAbility")
	self.bQuestActionUsesIcon = false
	if self.strQuestActionKeybind == Apollo.GetString("HUDAlert_Unbound") or #self.strQuestActionKeybind > 1 then -- Don't show interact
		self.bQuestActionUsesIcon = true
	end

	--Apollo.CreateTimer("InitialParseTimer", 10.0, false) -- gives everything a chance to load, then updates nameplates
	Apollo.CreateTimer("SecondaryParseTimer", 60.0, true) -- failsafe load; updates if things weren't. runs every minute to keep things clean

	local wndTemp = Apollo.LoadForm(self.xmlDoc, "GenericNameplate", nil, self)
	self.nFrameLeft, self.nFrameTop, self.nFrameRight, self.nFrameBottom = wndTemp:FindChild("MaxHealth"):GetAnchorOffsets()
	self.nHealthWidth = self.nFrameRight - self.nFrameLeft
	wndTemp:Destroy()
	
	if GameLib.GetPlayerUnit() then
		self:OptionsChanged()
	end
end

function Nameplates:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	local tSave = {}
	for idx,property in ipairs(karSavedProperties) do
		tSave[property] = self[property]
	end
	
	return tSave
end

function Nameplates:OnRestore(eType, t)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	
	for idx,property in ipairs(karSavedProperties) do
		if t[property] ~= nil then
			self[property] = t[property]
		end
	end
		
	self:OptionsChanged()
end

function Nameplates:OnConfigure()
	self:OnNameplatesOn()
end

-----------------------------------------------------------------------------------------------
-- Nameplates Functions
-----------------------------------------------------------------------------------------------
function Nameplates:CreateNameplateObject(unit)

	local tNameplate =
	{
		unitOwner 		= unit,
		idUnit 			= unit:GetId(),
		bOnScreen 		= false,
		bOccluded 		= false,
		bSpeechBubble 	= false,
		bIsTarget 		= false,
		bIsCluster 		= false,
		bIsCasting 		= false,
		strGuildColor	= nil,
		nVulnerableTime = 0,
		nFriendlyTargets = 0,
		nHostileTargets = 0,
		uLastTarget = nil,
		uLastDisposition = nil
	}

	self.arUnit2Nameplate[tNameplate.idUnit] = tNameplate
	self:ParseRewards(tNameplate)

	return tNameplate
end

function Nameplates:CreateNameplateWindow(tNameplate)
	if tNameplate.wndNameplate ~= nil then
		return
	end

	if tNameplate.unitOwner == nil then
		return
	end

	tNameplate.wndNameplate = table.remove(self.arFreeWindows)
	if tNameplate.wndNameplate == nil then
		tNameplate.wndNameplate = Apollo.LoadForm(self.xmlDoc, "GenericNameplate", "InWorldHudStratum", self)
	end

	tNameplate.wndNameplate:SetData(tNameplate.unitOwner)
	tNameplate.wndNameplate:FindChild("Name"):SetData(tNameplate.unitOwner)
	tNameplate.wndNameplate:SetUnit(tNameplate.unitOwner, 1)

	tNameplate.bOnScreen = tNameplate.wndNameplate:IsOnScreen()
	tNameplate.bOccluded = tNameplate.wndNameplate:IsOccluded()
	tNameplate.wndNameplate:Show(false,true)

	self.arDisplayedNameplates[tNameplate.wndNameplate:GetId()] = tNameplate

	self:SetNormalNameplate(tNameplate)
	tNameplate.wndNameplate:FindChild("Container"):ArrangeChildrenVert(2)

	return tNameplate.wndNameplate
end

function Nameplates:OnUnitCreated(unitNew) -- build main options here
	if not unitNew then
		return
	end

	local idUnit = unitNew:GetId()
	-- don't create unit if we already know about it
	local tNameplate = self.arUnit2Nameplate[idUnit]
	if tNameplate ~= nil then
		return
	end

	tNameplate = self:CreateNameplateObject(unitNew)
	tNameplate.bBrandNew = true
	if not self:HelperVerifyVisibilityOptions(tNameplate) then
		self.arUnit2Nameplate[idUnit] = nil
	end
end

function Nameplates:UnattachNameplateWindow(tNameplate)
	if tNameplate.wndNameplate ~= nil then
		local idWnd = tNameplate.wndNameplate:GetId()
		tNameplate.wndNameplate:SetNowhere()
		tNameplate.wndNameplate:Show(false)
		table.insert(self.arFreeWindows, tNameplate.wndNameplate)
		tNameplate.wndNameplate = nil
		self:UpdateTargetedInfo(tNameplate.unitOwner)
		self.arDisplayedNameplates[idWnd] = nil
	end
end

function Nameplates:OnUnitDestroyed(unitDead)
	local idUnit = unitDead:GetId()

	local tNameplate = self.arUnit2Nameplate[idUnit]
	if tNameplate == nil then
		return
	end

	self:UnattachNameplateWindow(tNameplate)
	self.arUnit2Nameplate[idUnit] = nil

end

function Nameplates:OnUnitTextBubbleToggled(tUnitArg, strText)
	local idUnit = tUnitArg:GetId()

	if not self.arUnit2Nameplate or not self.arUnit2Nameplate[idUnit] then
		return
	end

	if strText and strText ~= "" then
		self.arUnit2Nameplate[idUnit].bSpeechBubble = false
	else
		self.arUnit2Nameplate[idUnit].bSpeechBubble = false
	end
end

function Nameplates:OnWorldLocationOnScreen(wndHandler, wndControl, bOnScreen)
	if self.arDisplayedNameplates[wndHandler:GetId()] ~= nil then
		self.arDisplayedNameplates[wndHandler:GetId()].bOnScreen = bOnScreen
	end
end

function Nameplates:OnUnitOcclusionChanged(wndHandler, wndControl, bOccluded)
	if self.arDisplayedNameplates[wndHandler:GetId()] ~= nil then
		self.arDisplayedNameplates[wndHandler:GetId()].bOccluded = bOccluded
	end
end

function Nameplates:OnEnteredCombat(unitChecked, bInCombat)
	if unitChecked == GameLib.GetPlayerUnit() then
		self.bPlayerInCombat = bInCombat
	end
end

function Nameplates:OnApplyCCState(nState, unitChecking)
	self.bBlinded = (unitChecking == GameLib.GetPlayerUnit() and nState == Unit.CodeEnumCCState.Blind)
end

function Nameplates:OnRemoveCCState(nState, unitChecking)
	if unitChecking == GameLib.GetPlayerUnit() and nState == Unit.CodeEnumCCState.Blind then
		self.bBlinded = false
	end
end

function Nameplates:OnUnitLevelChanged(unitUpdating)
	local tNameplate = self.arUnit2Nameplate[unitUpdating:GetId()]
	if tNameplate == nil then
		return
	end
	local bHideMine = unitUpdating:IsThePlayer() and not self.bShowMyNameplate
	if bHideMine or unitUpdating:IsDead() or not unitUpdating:ShouldShowNamePlate() then
		self:UnattachNameplateWindow(tNameplate)
	elseif tNameplate.bIsTarget == true or tNameplate.bIsCluster == true then
		self:SetTargetedNameplate(tNameplate)
	else
		self:SetNormalNameplate(tNameplate)
	end
end

function Nameplates:OnNameplateNameClick(wndHandler, wndCtrl, nClick)
	local unitOwner = wndCtrl:GetData()

	if unitOwner ~= nil and GameLib.GetTargetUnit() ~= unitOwner and nClick == 0 then
		GameLib.SetTargetUnit(unitOwner)
		return true
	end
end

function Nameplates:OnTargetUnitChanged(unitOwner) -- build targeted options here; we get this event when a creature attacks, too

	local tNameplate = nil
	if unitOwner ~= nil then
		tNameplate = self.arUnit2Nameplate[unitOwner:GetId()]
	end
	if tNameplate ~= nil then
		if tNameplate.bIsTarget then
			return
		end
	elseif unitOwner ~= nil then
		self:CreateNameplateObject(unitOwner)
	end

	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		if tNameplate.bIsTarget == true or tNameplate.bIsCluster == true then
			tNameplate.bIsTarget = false
			tNameplate.bIsCluster = false
			self:ParseRewards(tNameplate)
			local unitCurr = tNameplate.unitOwner
			local bHideMine = unitCurr:IsThePlayer() and not self.bShowMyNameplate

			if bHideMine or unitCurr:IsDead() or not unitCurr:ShouldShowNamePlate() then
				self:UnattachNameplateWindow(tNameplate)
			else
				self:SetNormalNameplate(tNameplate)
			end
			if tNameplate.wndNameplate ~= nil then
				tNameplate.wndNameplate:FindChild("Container"):ArrangeChildrenVert(2)
			end
		end
	end

	if unitOwner == nil then
		return
	end

	local tCluster = unitOwner:GetClusterUnits()
	local tAdjustedNameplates = {} -- built a temp table for the nameplates that need adjustment

	for idx, tNameplate in pairs(self.arUnit2Nameplate) do  -- identify targets and cluster members
		local unitCurr = tNameplate.unitOwner
		if unitOwner == unitCurr then
			tNameplate.bIsTarget = true -- set target
			table.insert(tAdjustedNameplates, tNameplate) -- add that unit's nameplate
		end

		if tCluster ~= nil then
			for idx = 1, #tCluster do
				if tCluster[idx] == unitCurr then
					if tNameplate.bIsTarget ~= true then -- don't re-add the primary target
						tNameplate.bIsCluster = true -- set cluster
						table.insert(tAdjustedNameplates, tNameplate) -- add that nameplate
					end
				end
			end
		end
	end

	for idx = 1, #tAdjustedNameplates do -- format the nameplates that need adjusting
		local unitCurr = tAdjustedNameplates[idx].unitOwner
		self:ParseRewards(tAdjustedNameplates[idx])
		local bHideMine = unitCurr:IsThePlayer() and not self.bShowMyNameplate
		if bHideMine or unitCurr:IsDead() or not unitCurr:ShouldShowNamePlate() then
			if tAdjustedNameplates[idx].bIsTarget then
				self:UnattachNameplateWindow(tAdjustedNameplates[idx])
				tAdjustedNameplates[idx].bIsTarget = true -- reset (clearing the nameplate makes this false)
			else -- has to be the cluster to get on the table
				self:UnattachNameplateWindow(tAdjustedNameplates[idx])
				tAdjustedNameplates[idx].bIsCluster = true -- reset (clearing the nameplate makes this false)
			end
		else
			if tAdjustedNameplates[idx].wndNameplate == nil then
				self:CreateNameplateWindow(tAdjustedNameplates[idx])
			end
			self:SetTargetedNameplate(tAdjustedNameplates[idx])
		end
		if tAdjustedNameplates[idx].wndNameplate ~= nil then
			tAdjustedNameplates[idx].wndNameplate:FindChild("TargetMarker"):Show(self.bShowMarkerTarget)
			tAdjustedNameplates[idx].wndNameplate:FindChild("Container"):ArrangeChildrenVert(2)
		end
	end

	tAdjustedNameplates = nil
end

-- TODO: Refactor: The OnFrame can just deal with repositioning and health.
-- TODO: Refactor: Calculating visibility and etc. can be event driven either from code or from the options Window.
function Nameplates:OnFrame() -- on frame, toggle visibility, set health, set disposition, etc
	if Apollo.GetConsoleVariable("unit.nameplateShowCPPNameplates") then
		return
	end

	if self.bRewardInfoDirty then
		self:UpdateRewardInfo()
	end

	if not self.bInitialLoadAllClear then
		for idx, tNameplate in pairs(self.arDisplayedNameplates) do
			if tNameplate.wndNameplate ~= nil then
				tNameplate.wndNameplate:Show(false)
			end
		end
		return
	end

	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		local bShowNameplate = self:DrawNameplate(tNameplate)
	end

end

function Nameplates:DrawNameplate(tNameplate)
	local bShowNameplate = self:HelperVerifyVisibilityOptions(tNameplate) and self:CheckDrawDistance(tNameplate)

	if not bShowNameplate then
		self:UnattachNameplateWindow(tNameplate)
		return false
	end

	self:CreateNameplateWindow(tNameplate)

	local unitOwner = tNameplate.unitOwner

	if unitOwner == nil then
		return false
	end
	
	bShowNameplate = bShowNameplate
						and not self.bBlinded
						and tNameplate.bOnScreen
						and(not tNameplate.bOccluded or unitOwner:IsMounted())
						and not tNameplate.bSpeechBubble

	if not bShowNameplate then
		if tNameplate.wndNameplate ~= nil then
			tNameplate.wndNameplate:Show(false)
		end
		return false
	end
	
	if unitOwner:IsMounted() and tNameplate.wndNameplate:GetUnit() == unitOwner then
		tNameplate.wndNameplate:SetUnit(tNameplate.unitOwner, 1)
		--tNameplate.wndNameplate:SetUnit(tNameplate.unitOwner(), 1)
	end

	if not self.unitPlayerDisposComparisonTEMP then
		self.unitPlayerDisposComparisonTEMP = GameLib.GetPlayerUnit()
	end

	local bWndMain = not tNameplate.bIsTarget and not tNameplate.bIsCluster
	local eDisposition = unitOwner:GetDispositionTo(self.unitPlayerDisposComparisonTEMP)
	local bHiddenUnit = not unitOwner:ShouldShowNamePlate() or unitOwner:GetHealth() == nil or unitOwner:GetType() == "Collectible"
		or unitOwner:GetType() == "PinataLoot" or unitOwner:IsDead()

	self:OnUnitPvpFlagsChanged(unitOwner, tNameplate)

	if bHiddenUnit then
		tNameplate.wndNameplate:FindChild("Health"):Show(false)
	elseif bWndMain and self.bShowHealthMainDamaged then -- check for health on non-targets, only want to see the nameplates of damaged creatures
		local nHealthCurrent = unitOwner:GetHealth()
		local nHealthMax = unitOwner:GetMaxHealth()

		if tNameplate.wndNameplate:FindChild("Health"):IsShown() and nHealthCurrent == nHealthMax or bHiddenUnit then
			tNameplate.wndNameplate:FindChild("Health"):Show(false)
		elseif not tNameplate.wndNameplate:FindChild("Health"):IsShown() and nHealthCurrent ~= nHealthMax and not bHiddenUnit then
			tNameplate.wndNameplate:FindChild("Health"):Show(true)
		end
	elseif not bWndMain and self.bShowHealthTarget and not tNameplate.wndNameplate:FindChild("Health"):IsShown() then
		--tNameplate.wndNameplate:FindChild("Health"):Show(true) -- show it
	end

	local nCon = self:HelperCalculateConValue(unitOwner)

	if tNameplate.wndNameplate:FindChild("Health"):IsShown() then
		
		--tNameplate.nHostileTargets = self:CalculateHostileTargets(tNameplate.unitOwner)
		self:HelperDoHealthShieldBar(tNameplate.wndNameplate:FindChild("Health"), unitOwner, eDisposition)
		
		
		if tNameplate.wndNameplate:FindChild("TargetScalingMark"):IsShown() then
			tNameplate.wndNameplate:FindChild("Level"):SetTextColor(kcrScalingCColor)
		elseif unitOwner:GetLevel() == nil then
			tNameplate.wndNameplate:FindChild("Level"):SetTextColor(karConColors[1][2])
		else
			tNameplate.wndNameplate:FindChild("Level"):SetTextColor(karConColors[nCon][2])
		end
		
		if unitOwner:GetFaction() == GameLib.GetPlayerUnit():GetFaction() then
			tNameplate.wndNameplate:FindChild("Level"):SetTextColor(npClassColors[unitOwner:GetClassId()])
		end

	end

	tNameplate.wndNameplate:FindChild("CertainDeath"):Show(nCon == #karConColors and eDisposition ~= Unit.CodeEnumDisposition.Friendly
		and unitOwner:GetHealth() ~= nil and unitOwner:ShouldShowNamePlate() and not unitOwner:IsDead())

	-- Vulnerable; shown/hidden once but updated on frame
	local wndVulnerable = tNameplate.wndNameplate:FindChild("Vulnerable")
	if (bWndMain and self.bShowHealthMain or self.bShowHealthMainDamaged) or (not bWndMain and self.bShowHealthTarget) then
		local nVulnerable = unitOwner:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)
		if nVulnerable == nil then
			-- Do nothing
		elseif nVulnerable == 0 and nVulnerable ~= tNameplate.nVulnerableTime then
			tNameplate.nVulnerableTime = 0 -- casting done, set back to 0
			wndVulnerable:Show(false)
		elseif nVulnerable ~= 0 and nVulnerable > tNameplate.nVulnerableTime then
			tNameplate.nVulnerableTime = nVulnerable
			wndVulnerable:Show(true)
		elseif nVulnerable ~= 0 and nVulnerable < tNameplate.nVulnerableTime then
			wndVulnerable:FindChild("VulnFill"):SetMax(tNameplate.nVulnerableTime)
			wndVulnerable:FindChild("VulnFill"):SetProgress(nVulnerable)
		end
	end

	-- Casting; has some onDraw parameters we need to check
	if (bWndMain and self.bShowCastBarMain) or (not bWndMain and self.bShowCastBarTarget) then
		local bIsCasting = unitOwner:ShouldShowCastBar() and not bHiddenUnit
		if bIsCasting ~= tNameplate.bIsCasting then
			tNameplate.bIsCasting = bIsCasting
			tNameplate.wndNameplate:FindChild("CastBar"):Show(bIsCasting)-- redudancy to make sure the castbars aren't showing when not casti
		end
	end

	wndCastBar = tNameplate.wndNameplate:FindChild("CastBar")
	if wndCastBar:IsShown() then
	local bIsCasting = unitOwner:ShouldShowCastBar()
		wndCastBar:FindChild("Label"):SetText(unitOwner:GetCastName())
		wndCastBar:FindChild("CastFill"):SetMax(unitOwner:GetCastDuration())
		wndCastBar:FindChild("CastFill"):SetProgress(unitOwner:GetCastElapsed())
		wndCastBar:FindChild("CastBar"):ToFront(top)
		tNameplate.wndNameplate:FindChild("CastBar"):Show(bIsCasting)

	end

	-- Targeted set -------------------------------------------------------------
	if tNameplate.bIsTarget then
		if unitOwner:IsDead() then
			tNameplate.wndNameplate:FindChild("TargetMarker"):Show(false)
		else
			tNameplate.wndNameplate:FindChild("TargetMarker"):SetSprite(karDisposition.TargetPrimary[eDisposition]) -- primary marker
		end
	end

	if tNameplate.bIsCluster then
		if unitOwner:IsDead() then
			tNameplate.wndNameplate:FindChild("TargetMarker"):Show(false)
		else
			tNameplate.wndNameplate:FindChild("TargetMarker"):SetSprite(karDisposition.TargetSecondary[eDisposition]) -- secondary marker
		end
	end

	tNameplate.wndNameplate:FindChild("Container"):ArrangeChildrenVert(2)
	tNameplate.wndNameplate:Show(unitOwner:ShouldShowNamePlate())

	return bShowNameplate
end

function Nameplates:CalculateTargets(unitOwner)
	unitNameplate = self.arUnit2Nameplate[unitOwner:GetId()]
	unitNameplate.nFriendlyTargets = 0
	unitNameplate.nHostileTargets = 0
	--Print(unitOwner:GetName())
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		if (tNameplate.uLastTarget == unitOwner and tNameplate.uLastTarget ~= nil) then
			--Print(tNameplate.unitOwner:GetName() .. " Matching: " .. unitOwner:GetName())
			if (tNameplate.uLastDisposition == Unit.CodeEnumDisposition.Friendly) then
				unitNameplate.nFriendlyTargets = unitNameplate.nFriendlyTargets + 1
			else 
				unitNameplate.nHostileTargets = unitNameplate.nHostileTargets + 1
			end
		else 
			--Print(tNameplate.unitOwner:GetName() .. " not targeting " .. unitOwner:GetName())

		end
		
	end
	
	--Print("END")
	
	if (unitNameplate.wndNameplate ~= nil) then
		unitNameplate.wndNameplate:FindChild("FriendlyTargets"):SetText(unitNameplate.nFriendlyTargets)
		unitNameplate.wndNameplate:FindChild("HostileTargets"):SetText(unitNameplate.nHostileTargets)
	end
end

function Nameplates:HelperVerifyVisibilityOptions(tNameplate)

	if not self.unitPlayerDisposComparisonTEMP then
		self.unitPlayerDisposComparisonTEMP = GameLib.GetPlayerUnit()
	end

	local bShowNameplate = false
	local unitOwner = tNameplate.unitOwner
	local bWndMain = not tNameplate.bIsTarget and not tNameplate.bIsCluster
	local eDisposition = unitOwner:GetDispositionTo(self.unitPlayerDisposComparisonTEMP)

	local bHiddenUnit = not unitOwner:ShouldShowNamePlate() or unitOwner:GetHealth() == nil or unitOwner:GetType() == "Collectible"
			or unitOwner:GetType() == "PinataLoot" or unitOwner:IsDead()
	if bHiddenUnit and not tNameplate.bIsTarget then
		tNameplate.bBrandNew = false
		return false
	end

	if bWndMain then -- onDraw
		if self.bShowMainAlways == false then
			if self.bShowMainObjectiveOnly and tNameplate.bIsObjective then
				bShowNameplate = true
			end

			if self.bShowMainGroupOnly and unitOwner:IsInYourGroup() then
				bShowNameplate = true
			end

			for idx = 1, 3 do
				if self.tShowDispositionOnly[idx] and eDisposition + 1 == idx then -- 0-indexed
					bShowNameplate = true
				end
			end

			if not self.wndOptionsMain:FindChild("MainShowNever"):IsChecked() then -- things we always want drawn unless "Never" is on
				local tActivation = unitOwner:GetActivationState()
				if tActivation.Vendor ~= nil or tActivation.FlightPathSettler ~= nil or tActivation.FlightPath ~= nil or tActivation.FlightPathNew then
					bShowNameplate = true
				end

			-- QuestGivers too
				if tActivation.QuestReward ~= nil then
					bShowNameplate = true
				end
				if tActivation.QuestNew ~= nil or tActivation.QuestNewMain ~= nil then
					bShowNameplate = true
				end
				if tActivation.QuestReceiving ~= nil then
					bShowNameplate = true
				end
				if tActivation.TalkTo ~= nil then
					bShowNameplate = true
				end
			end

			if bShowNameplate == true then
				bShowNameplate = not (self.bPlayerInCombat and self.bHideInCombat)
			end
		else
			bShowNameplate = true
		end
	else
		bShowNameplate = not self.bBlinded
	end

	if unitOwner:IsThePlayer() then
		if self.bShowMyNameplate and not unitOwner:IsDead() then
			bShowNameplate = true
		else
			bShowNameplate = false
		end
	end

	tNameplate.bBrandNew = false
	return bShowNameplate
end

function Nameplates:OnUnitPvpFlagsChanged(unitUpdated, tNameplate)
	if tNameplate == nil then
		tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
		if tNameplate == nil then
			return
		end
	end

	if not self.unitPlayerDisposComparisonTEMP then
		self.unitPlayerDisposComparisonTEMP = GameLib.GetPlayerUnit()
	end
	
	unitController = unitUpdated:GetUnitOwner() or unitUpdated
		
	local eDisposition = unitController:GetDispositionTo(self.unitPlayerDisposComparisonTEMP)
	local crColorToUse = karDisposition.TextColors[eDisposition]

	local strUnitType = unitUpdated:GetType()

	if strUnitType == "Player" or strUnitType == "Pet" or strUnitType == "Esper Pet" then
		if eDisposition == Unit.CodeEnumDisposition.Friendly or unitUpdated:IsThePlayer() then
			if unitController:IsPvpFlagged() then
				crColorToUse = kcrFlaggedFriendlyTextColor
			elseif unitController:IsInYourGroup() then
				crColorToUse = kcrWarPartyTextColor
			else
				crColorToUse = kcrDefaultUnflaggedAllyTextColor
			end
		else
			local bIsUnitFlagged = unitController:IsPvpFlagged()
			local bAmIFlagged = GameLib.IsPvpFlagged()
			if not bAmIFlagged and not bIsUnitFlagged then
				crColorToUse = kcrNeutralEnemyTextColor
			elseif (bAmIFlagged and not bIsUnitFlagged) or (not bAmIFlagged and bIsUnitFlagged) then
				crColorToUse = kcrAggressiveEnemyTextColor
			end
		end
	end

	if unitUpdated:GetType() ~= "Player" and unitUpdated:IsTagged() and not unitUpdated:IsTaggedByMe() and not unitUpdated:IsSoftKill() then
		crColorToUse = kcrDefaultTaggedColor
	end

	if tNameplate.wndNameplate == nil then
		return
	end

	tNameplate.wndNameplate:FindChild("Name"):SetTextColor(crColorToUse)
	tNameplate.wndNameplate:FindChild("GuildContainer"):SetTextColor(crColorToUse)
end

function Nameplates:OnUnitNameChanged(unitUpdated, strNewName)
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate == nil or tNameplate.wndNameplate == nil then
		return
	end

	tNameplate.wndNameplate:FindChild("Name"):SetText(strNewName)
	local nNameWidth = Apollo.GetTextWidth("CRB_InterfaceMedium", strNewName .. "  ")
	tNameplate.wndNameplate:FindChild("Name"):SetAnchorOffsets(0, 0, nNameWidth, knNameRewardHeight)
	tNameplate.wndNameplate:FindChild("NameRewardContainer"):ArrangeChildrenHorz(1)
end

function Nameplates:OnUnitTitleChanged(unitUpdated)
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate == nil or tNameplate.wndNameplate == nil then
		return
	end
	local bHideMine = unitUpdated:IsThePlayer() and not self.bShowMyNameplate
	if bHideMine or unitUpdated:IsDead() or not unitUpdated:ShouldShowNamePlate() then
		self:UnattachNameplateWindow(tNameplate)
	elseif tNameplate.bIsTarget == true or tNameplate.bIsCluster == true then
		self:SetTargetedNameplate(tNameplate)
	else
		self:SetNormalNameplate(tNameplate)
	end
end

function Nameplates:OnPlayerTitleChanged()
	local unitUpdated = GameLib.GetPlayerUnit()
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate == nil or tNameplate.wndNameplate == nil then
		return
	end
	local bHideMine = unitUpdated:IsThePlayer() and not self.bShowMyNameplate
	if bHideMine or unitUpdated:IsDead() or not unitUpdated:ShouldShowNamePlate() then
		self:UnattachNameplateWindow(tNameplate)
	elseif tNameplate.bIsTarget == true or tNameplate.bIsCluster == true then
		self:SetTargetedNameplate(tNameplate)
	else
		self:SetNormalNameplate(tNameplate)
	end
end

function Nameplates:OnUnitGuildNameplateChanged(unitUpdated)
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate == nil or tNameplate.wndNameplate == nil then
		return
	end
	local bHideMine = unitUpdated:IsThePlayer() and not self.bShowMyNameplate
	if bHideMine or unitUpdated:IsDead() or not unitUpdated:ShouldShowNamePlate() then
		self:UnattachNameplateWindow(tNameplate)
	elseif tNameplate.bIsTarget == true or tNameplate.bIsCluster == true then
		self:SetTargetedNameplate(tNameplate)
	else
		self:SetNormalNameplate(tNameplate)
	end
end

function Nameplates:OnGuildDirty(unitOwner, tNameplate)
	if self.guildDisplayed then
		tNameplate.bIsGuildMember = self.guildDisplayed:IsUnitMember(unitOwner)
	else
		tNameplate.bIsGuildMember = false
	end

	if self.guildWarParty then
		tNameplate.bIsWarPartyMember = self.guildWarParty:IsUnitMember(unitOwner)
	else
		tNameplate.bIsWarPartyMember = false
	end
end

function Nameplates:OnUnitMemberOfGuildChange(unitOwner)
	if unitOwner == nil then
		return
	end

	local tNameplate = self.arUnit2Nameplate[unitOwner:GetId()]
	if tNameplate == nil or tNameplate.wndNameplate == nil then
		return
	end

	self:OnGuildDirty(unitOwner, tNameplate)

	self:OnUnitPvpFlagsChanged(unitOwner, tNameplate)
end

function Nameplates:OnGuildChange()
	self.guildDisplayed = nil
	self.guildWarParty = nil
	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		if guildCurr:GetType() == GuildLib.GuildType_Guild then
			self.guildDisplayed = guildCurr
		end
		if guildCurr:GetType() == GuildLib.GuildType_WarParty then
			self.guildWarParty = guildCurr
		end
	end

	for key, tNameplate in pairs(self.arUnit2Nameplate) do
		local unitOwner = tNameplate.unitOwner
		self:OnGuildDirty(unitOwner, tNameplate)
		self:OnUnitPvpFlagsChanged(unitOwner, tNameplate)
	end
end

function Nameplates:OnKeyBindingUpdated(strKeybind)
	if strKeybind ~= "Path Action" and strKeybind ~= "Cast Objective Ability" then
		return
	end

	self.strPathActionKeybind = GameLib.GetKeyBinding("PathAction")
	self.bPathActionUsesIcon = false
	if self.strPathActionKeybind == Apollo.GetString("HUDAlert_Unbound") or #self.strPathActionKeybind > 1 then -- Don't show interact
		self.bPathActionUsesIcon = true
	end

	self.strQuestActionKeybind = GameLib.GetKeyBinding("CastObjectiveAbility")
	self.bQuestActionUsesIcon = false
	if self.strQuestActionKeybind == Apollo.GetString("HUDAlert_Unbound") or #self.strQuestActionKeybind > 1 then -- Don't show interact
		self.bQuestActionUsesIcon = true
	end

	self:OptionsChanged()
end

function Nameplates:CheckDrawDistance(tNameplate)
	local unitOwner = tNameplate.unitOwner

	if not unitOwner then
	    return
	end

	local unitPlayer = GameLib.GetPlayerUnit()

	tPosTarget = unitOwner:GetPosition()
	tPosPlayer = unitPlayer:GetPosition()

	if tPosTarget == nil then
		return
	end

	local nDeltaX = tPosTarget.x - tPosPlayer.x
	local nDeltaY = tPosTarget.y - tPosPlayer.y
	local nDeltaZ = tPosTarget.z - tPosPlayer.z

	local nDistance = (nDeltaX * nDeltaX) + (nDeltaY * nDeltaY) + (nDeltaZ * nDeltaZ)

	if tNameplate.bIsTarget or tNameplate.bIsCluster == true then
		bInRange = nDistance < knTargetRange
		return bInRange
	else
		bInRange = nDistance < (self.nMaxRange * self.nMaxRange) -- squaring for quick maths
		return bInRange
	end
end

-----------------------------------------------------------------------------------------------
-- Nameplate Helper Functions
-----------------------------------------------------------------------------------------------
function Nameplates:OnNameplatesOn()
	local ePath = PlayerPathLib.GetPlayerPathType()
	self.wndOptionsMain:FindChild("ShowRewardTypeMission"):FindChild("Icon"):SetSprite(karPathSprite[ePath])
	self.wndMain:Show(true)
	self:RefreshNameplatesConfigure()
end

function Nameplates:RefreshNameplatesConfigure()
	--General nameplate drawing
	if self.bShowMainAlways ~= nil then self.wndMain:FindChild("MainShowAlways"):SetCheck(self.bShowMainAlways) end
	if self.bShowMainAlways ~= nil then self.wndMain:FindChild("MainShowNever"):SetCheck(not self.bShowMainAlways) end
	if self.bShowMainAlways ~= nil and self.bShowMainObjectiveOnly ~= nil then self.wndMain:FindChild("MainShowObjectives"):SetCheck(not self.bShowMainAlways and self.bShowMainObjectiveOnly) end
	if self.bShowMainAlways ~= nil and self.bShowMainGroupOnly ~= nil then self.wndMain:FindChild("MainShowGroup"):SetCheck(not self.bShowMainAlways and self.bShowMainGroupOnly) end
	if self.bShowMainAlways ~= nil and self.bShowMyNameplate ~= nil then self.wndMain:FindChild("MainShowMine"):SetCheck(not self.bShowMainAlways and self.bShowMyNameplate) end
	if self.bShowMainAlways ~= nil and self.tShowDispositionOnly ~= nil then
		for idx = 1,3 do
			self.wndMain:FindChild("MainShowDisposition_" .. idx):SetCheck(not self.bShowMainAlways and self.tShowDispositionOnly[idx])
		end
	end
	--Draw distance
	if self.nMaxRange ~= nil then self.wndMain:FindChild("DrawDistanceLabel"):SetText(String_GetWeaselString(Apollo.GetString("Nameplates_DrawDistance"), self.nMaxRange)) end
	--Name and title
	if self.bShowNameMain ~= nil and self.bShowTitle ~= nil then self.wndMain:FindChild("MainShowNameAlways"):SetCheck(self.bShowNameMain and self.bShowTitle) end
	if self.bShowNameMain ~= nil and self.bShowTitle ~= nil then self.wndMain:FindChild("MainShowNameOnly"):SetCheck(self.bShowNameMain and not self.bShowTitle) end
	if self.bShowNameMain ~= nil and self.bShowTitle ~= nil then self.wndMain:FindChild("MainShowNameNever"):SetCheck(not self.bShowNameMain and not self.bShowTitle) end
	--Reward icons
	if self.bShowRewardsMain ~= nil then self.wndMain:FindChild("ShowRewardTypeQuest"):Enable(self.bShowRewardsMain) end
	if self.bShowRewardTypeQuest ~= nil then self.wndMain:FindChild("ShowRewardTypeQuest"):SetCheck(self.bShowRewardTypeQuest) end
	if self.bShowRewardsMain ~= nil then self.wndMain:FindChild("ShowRewardTypeChallenge"):Enable(self.bShowRewardsMain) end
	if self.bShowRewardTypeChallenge ~= nil then self.wndMain:FindChild("ShowRewardTypeChallenge"):SetCheck(self.bShowRewardTypeChallenge) end
	if self.bShowRewardsMain ~= nil then self.wndMain:FindChild("ShowRewardTypeAchievement"):Enable(self.bShowRewardsMain) end
	if self.bShowRewardTypeAchievement ~= nil then self.wndMain:FindChild("ShowRewardTypeAchievement"):SetCheck(self.bShowRewardTypeAchievement) end
	if self.bShowRewardsMain ~= nil then self.wndMain:FindChild("ShowRewardTypeReputation"):Enable(self.bShowRewardsMain) end
	if self.bShowRewardTypeReputation ~= nil then self.wndMain:FindChild("ShowRewardTypeReputation"):SetCheck(self.bShowRewardTypeReputation) end
	if self.bShowRewardsMain ~= nil then self.wndMain:FindChild("ShowRewardTypeMission"):Enable(self.bShowRewardsMain) end
	if self.bShowRewardTypeMission ~= nil then self.wndMain:FindChild("ShowRewardTypeMission"):SetCheck(self.bShowRewardTypeMission) end
	if self.bShowRewardsMain ~= nil then self.wndMain:FindChild("ShowRewardTypePublicEvent"):Enable(self.bShowRewardsMain) end
	if self.bShowRewardTypePublicEvent ~= nil then self.wndMain:FindChild("ShowRewardTypePublicEvent"):SetCheck(self.bShowRewardTypePublicEvent) end
	if self.bShowRivals ~= nil then self.wndMain:FindChild("ShowRewardTypeRival"):SetCheck(self.bShowRivals) end
	if self.bShowFriends ~= nil then self.wndMain:FindChild("ShowRewardTypeFriend"):SetCheck(self.bShowFriends) end
	--Info panel
	if self.bShowHealthMain ~= nil and self.bShowHealthMainDamaged ~= nil then self.wndMain:FindChild("MainShowHealthBarAlways"):SetCheck(self.bShowHealthMain and not self.bShowHealthMainDamaged) end
	if self.bShowHealthMain ~= nil and self.bShowHealthMainDamaged ~= nil then self.wndMain:FindChild("MainShowHealthBarDamaged"):SetCheck(not self.bShowHealthMain and self.bShowHealthMainDamaged) end
	if self.bShowHealthMain ~= nil and self.bShowHealthMainDamaged ~= nil then self.wndMain:FindChild("MainShowHealthBarNever"):SetCheck(not self.bShowHealthMain and not self.bShowHealthMainDamaged) end
	--Guild name/emblem
	if self.bShowGuildNameMain ~= nil then self.wndMain:FindChild("MainShowGuild"):SetCheck(self.bShowGuildNameMain) end
	if self.bShowGuildNameMain ~= nil then self.wndMain:FindChild("MainShowGuildOff"):SetCheck(not self.bShowGuildNameMain) end
	--Cast bar
	if self.bShowCastBarMain ~= nil then self.wndMain:FindChild("MainShowCastBar"):SetCheck(self.bShowCastBarMain) end
	if self.bShowCastBarMain ~= nil then self.wndMain:FindChild("MainShowCastBarOff"):SetCheck(not self.bShowCastBarMain) end
	--target components
	if self.bShowMarkerTarget ~= nil then self.wndMain:FindChild("TargetedShowMarker"):SetCheck(self.bShowMarkerTarget) end
	if self.bShowMarkerTarget ~= nil then self.wndMain:FindChild("TargetedShowMarkerOff"):SetCheck(not self.bShowMarkerTarget) end
	if self.bShowNameTarget ~= nil then self.wndMain:FindChild("TargetedShowName"):SetCheck(self.bShowNameTarget) end
	if self.bShowNameTarget ~= nil then self.wndMain:FindChild("TargetedShowNameOff"):SetCheck(not self.bShowNameTarget) end
	if self.bShowRewardsTarget ~= nil then self.wndMain:FindChild("TargetedShowRewards"):SetCheck(self.bShowRewardsTarget) end
	if self.bShowRewardsTarget ~= nil then self.wndMain:FindChild("TargetedShowRewardsOff"):SetCheck(not self.bShowRewardsTarget) end
	if self.bShowGuildNameTarget ~= nil then self.wndMain:FindChild("TargetedShowGuild"):SetCheck(self.bShowGuildNameTarget) end
	if self.bShowGuildNameTarget ~= nil then self.wndMain:FindChild("TargetedShowGuildOff"):SetCheck(not self.bShowGuildNameTarget) end
	if self.bShowHealthTarget ~= nil then self.wndMain:FindChild("TargetedShowHealthBar"):SetCheck(self.bShowHealthTarget) end
	if self.bShowHealthTarget ~= nil then self.wndMain:FindChild("TargetedShowHealthBarOff"):SetCheck(not self.bShowHealthTarget) end
	if self.bShowCastBarTarget ~= nil then self.wndMain:FindChild("TargetedShowCastBar"):SetCheck(self.bShowCastBarTarget) end
	if self.bShowCastBarTarget ~= nil then self.wndMain:FindChild("TargetedShowCastBarOff"):SetCheck(not self.bShowCastBarTarget) end
	if self.bHideInCombat ~= nil then self.wndMain:FindChild("MainHideInCombat"):SetCheck(self.bHideInCombat) end
	if self.bShowMarkerTarget ~= nil then self.wndMain:FindChild("MainHideInCombatOff"):SetCheck(not self.bHideInCombat) end
end

function Nameplates:SetClearedNameplate(tNameplate)
	local wndNameplate = tNameplate.wndNameplate

	if wndNameplate == nil then
		return
	end

	wndNameplate:Show(false, true)
	wndNameplate:FindChild("TargetMarker"):Show(false)
	wndNameplate:FindChild("Name"):Show(false)
	wndNameplate:FindChild("GuildContainer"):Show(false)
	wndNameplate:FindChild("Health"):Show(false)
	wndNameplate:FindChild("QuestRewards"):Show(false)
	wndNameplate:FindChild("Vulnerable"):Show(false)
	wndNameplate:FindChild("CastBar"):Show(false)
	wndNameplate:FindChild("TargetScalingMark"):Show(false)

	tNameplate.bIsTarget = false
	tNameplate.bIsCluster = false
	tNameplate.bIsCasting = false
	tNameplate.strGuildColor = nil
	tNameplate.nVulnerableTime = 0
end

function Nameplates:SetNormalNameplate(tNameplate) -- happens when built and the creature is untargeted
	local wndNameplate = tNameplate.wndNameplate
	if wndNameplate == nil then
		return
	end
	local unitOwner = tNameplate.unitOwner
	local bHiddenUnit = not unitOwner:ShouldShowNamePlate() or unitOwner:GetHealth() == nil or unitOwner:GetType() == "Collectible"
				or unitOwner:GetType() == "PinataLoot" or unitOwner:IsDead()

	local strName = unitOwner:GetName()
	if self.bShowTitle == true then
		strName = unitOwner:GetTitleOrName()
	end

	wndNameplate:Show(false)

	wndNameplate:FindChild("Name"):SetText(strName)

	wndNameplate:FindChild("NameRewardContainer"):Show(true)
	wndNameplate:FindChild("TargetMarker"):Show(false)
	wndNameplate:FindChild("Name"):Show(self.bShowNameMain)
	wndNameplate:FindChild("Health"):Show(not bHiddenUnit and self.bShowHealthMain)

	local nLevel = unitOwner:GetLevel()
	if nLevel == nil then
		wndNameplate:FindChild("Level"):SetText("-")
	else
		wndNameplate:FindChild("Level"):SetText(unitOwner:GetLevel())
	end

	wndNameplate:FindChild("TargetScalingMark"):Show(unitOwner:IsScaled())

	tNameplate.strGuildColor = nil

	local strTagText = ""

	if unitOwner:GetType() == "Player" and unitOwner:GetGuildName() and string.len(unitOwner:GetGuildName()) > 0 and self.bShowGuildNameMain then
		wndNameplate:FindChild("GuildContainer"):Show(true)
		strTagText = String_GetWeaselString(Apollo.GetString("Nameplates_GuildDisplay"), unitOwner:GetGuildName())
	elseif unitOwner:GetType() ~= "Player" and unitOwner:GetAffiliationName() and string.len(unitOwner:GetAffiliationName()) > 0 then		
		strTagText = unitOwner:GetAffiliationName()
		wndNameplate:FindChild("GuildContainer"):Show(self.bShowNameMain) -- no reason to hide NPC tags unless name is hidden
	else
		wndNameplate:FindChild("GuildContainer"):Show(false)
	end

	if wndNameplate:FindChild("GuildContainer"):IsShown() then
		wndNameplate:FindChild("GuildContainer"):SetTextRaw(strTagText)
	end

	if wndNameplate:FindChild("CastBar"):IsShown() then -- check to see if this option is set for non-targets
		wndNameplate:FindChild("CastBar"):Show(self.bShowCastBarMain)
		if self.bShowCastBarMain == false then
			tNameplate.bIsCasting = false
		end
	end

	if wndNameplate:FindChild("Vulnerable"):IsShown() then -- check to see if this option is set for non-targets
		wndNameplate:FindChild("Vulnerable"):Show(wndNameplate:FindChild("Health"):IsShown())
		if not wndNameplate:FindChild("Health"):IsShown() then
			tNameplate.nVulnerableTime = 0
			wndNameplate:FindChild("Vulnerable"):FindChild("VulnFill"):SetProgress(0)
		end
	end

	if self.bShowRewardsMain then
		local bHasRewards = self:ShowRewardIcons(tNameplate) > 0
		wndNameplate:FindChild("QuestRewards"):Show(bHasRewards)
	end

	local nNameWidth = Apollo.GetTextWidth("CRB_InterfaceMedium", strName .. "  ")
	wndNameplate:FindChild("Name"):SetAnchorOffsets(0, 0, nNameWidth, knNameRewardHeight)
	wndNameplate:FindChild("NameRewardContainer"):ArrangeChildrenHorz(1)
end



function Nameplates:SetTargetedNameplate(tNameplate) -- happens when the creature is targeted
	local wndNameplate = tNameplate.wndNameplate
	if wndNameplate == nil then
		return
	end
	local unitOwner = tNameplate.unitOwner
	local bHiddenUnit = not unitOwner:ShouldShowNamePlate() or unitOwner:GetHealth() == nil or unitOwner:GetType() == "Collectible"
				or unitOwner:GetType() == "PinataLoot" or unitOwner:IsDead()

	local strName = unitOwner:GetName()
	if self.bShowTitle == true then
		strName = unitOwner:GetTitleOrName()
	end

	wndNameplate:Show(false)

	wndNameplate:FindChild("Name"):Show(self.bShowNameTarget)
	wndNameplate:FindChild("TargetScalingMark"):Show(unitOwner:IsScaled())
	wndNameplate:FindChild("QuestRewards"):Show(self.bShowRewardsTarget)
	wndNameplate:FindChild("NameRewardContainer"):Show(false)

	local nLevel = unitOwner:GetLevel()
	if nLevel == nil then
		wndNameplate:FindChild("Level"):SetText("-")
	else
		wndNameplate:FindChild("Level"):SetText(unitOwner:GetLevel())
	end


	tNameplate.strGuildColor = nil

	local strTagText = ""

	if unitOwner:GetType() == "Player" and unitOwner:GetGuildName() and string.len(unitOwner:GetGuildName()) > 0 and self.bShowGuildNameTarget then
		wndNameplate:FindChild("GuildContainer"):Show(true)
		strTagText = String_GetWeaselString(Apollo.GetString("Nameplates_GuildDisplay"), unitOwner:GetGuildName())
	elseif unitOwner:GetType() ~= "Player" and unitOwner:GetAffiliationName() and string.len(unitOwner:GetAffiliationName()) > 0 then
		strTagText = unitOwner:GetAffiliationName()
		wndNameplate:FindChild("GuildContainer"):Show(self.bShowNameTarget) -- don't want to hide affiliation on NPCs unless no name is shown
	else
		wndNameplate:FindChild("GuildContainer"):Show(false)
	end

	if wndNameplate:FindChild("GuildContainer"):IsShown() then
		wndNameplate:FindChild("GuildContainer"):SetTextRaw(strTagText)
	end

	if bHiddenUnit then
		wndNameplate:FindChild("Health"):Show(false)
	else
		wndNameplate:FindChild("Health"):Show(self.bShowHealthTarget)
	end

	if self.bShowNameTarget then
		wndNameplate:FindChild("NameRewardContainer"):Show(true)
	end

	if wndNameplate:FindChild("CastBar"):IsShown() then -- check to see if this option is set for non-targets
		wndNameplate:FindChild("CastBar"):Show(self.bShowCastBarTarget)
		if self.bShowCastBarTarget == false then
			tNameplate.bIsCasting = false
		end
	end

	if wndNameplate:FindChild("Vulnerable"):IsShown() then -- check to see if this option is set for non-targets
		wndNameplate:FindChild("Vulnerable"):Show(wndNameplate:FindChild("Health"):IsShown())
		if not wndNameplate:FindChild("Health"):IsShown() then
			tNameplate.nVulnerableTime = 0
			wndNameplate:FindChild("Vulnerable"):FindChild("VulnFill"):SetProgress(0)
		end
	end

	if self.bShowRewardsTarget then
		local bHasRewards = self:ShowRewardIcons(tNameplate) > 0
		wndNameplate:FindChild("QuestRewards"):Show(bHasRewards)
	end

	local nNameWidth = Apollo.GetTextWidth("CRB_InterfaceMedium", strName .. "  ")
	wndNameplate:FindChild("Name"):SetAnchorOffsets(0, 0, nNameWidth, knNameRewardHeight)
	wndNameplate:FindChild("NameRewardContainer"):ArrangeChildrenHorz(1)

end

function Nameplates:UpdateTargetedInfo(unitOwner)
	self:CalculateTargets(unitOwner)
	previousTarget = self.arUnit2Nameplate[unitOwner:GetId()].uLastTarget
	previousDisposition = self.arUnit2Nameplate[unitOwner:GetId()].uLastDisposition
	targetedUnit = unitOwner:GetTarget()
	if (targetedUnit) then
		targetedId = targetedUnit:GetId();
		targetedNameplate = self.arUnit2Nameplate[targetedId]
		targetedDisposition = unitOwner:GetDispositionTo(targetedUnit)
		--[[if (targetedNameplate and (previousTarget ~= targetedUnit or previousTarget == nil)) then
			if (targetedDisposition == Unit.CodeEnumDisposition.Friendly) then
				targetedNameplate.nFriendlyTargets = targetedNameplate.nFriendlyTargets + 1
				if (targetedNameplate.wndNameplate) then
					targetedNameplate.wndNameplate:FindChild("FriendlyTargets"):SetText(targetedNameplate.nFriendlyTargets)
				end
				--Print("Friendly" .. targetedNameplate.nFriendlyTargets);
			else
				targetedNameplate.nHostileTargets = targetedNameplate.nHostileTargets + 1 
				if (targetedNameplate.wndNameplate) then
					targetedNameplate.wndNameplate:FindChild("HostileTargets"):SetText(targetedNameplate.nHostileTargets)				--Print("Hostile" .. targetedNameplate.nHostileTargets);
				end
			end
		end]]--
		if (self.arUnit2Nameplate[unitOwner:GetId()].wndNameplate ~= nil) then
			self.arUnit2Nameplate[unitOwner:GetId()].uLastTarget = targetedUnit
			self.arUnit2Nameplate[unitOwner:GetId()].uLastDisposition = targetedDisposition
		else
			self.arUnit2Nameplate[unitOwner:GetId()].uLastTarget = nil
			self.arUnit2Nameplate[unitOwner:GetId()].uLastDisposition = nil
		end
			
	end
	
	if (unitOwner:IsDead() or previousTarget ~= nil and (previousTarget ~= self.arUnit2Nameplate[unitOwner:GetId()].uLastTarget or targetedUnit == nil)) then
		--[[if (previousTarget ~= nil) then
			previousNameplate = self.arUnit2Nameplate[previousTarget:GetId()]
			if (previousNameplate) then
				if (previousDisposition ==  Unit.CodeEnumDisposition.Friendly) then
					previousNameplate.nFriendlyTargets = previousNameplate.nFriendlyTargets - 1
					if (previousNameplate.wndNameplate) then
						previousNameplate.wndNameplate:FindChild("FriendlyTargets"):SetText(previousNameplate.nFriendlyTargets)
					end
					--Print("Friendly" .. previousNameplate.nFriendlyTargets)
				else
					previousNameplate.nHostileTargets = previousNameplate.nHostileTargets - 1
					if (previousNameplate.wndNameplate) then
						previousNameplate.wndNameplate:FindChild("HostileTargets"):SetText(previousNameplate.nHostileTargets)
					end
					--Print("Hostile" .. previousNameplate.nHostileTargets)
				end
			end
		end]]--
		
		if (targetedUnit == nil or unitOwner:IsDead() or self.arUnit2Nameplate[unitOwner:GetId()].wndNameplate == nil) then
			self.arUnit2Nameplate[unitOwner:GetId()].uLastTarget = nil
			self.arUnit2Nameplate[unitOwner:GetId()].uLastDisposition = nil		
		end
		
	end
end


function Nameplates:HelperDoHealthShieldBar(wndHealth, unitOwner, eDisposition)
	local nVulnerabilityTime = unitOwner:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)

	if unitOwner:GetType() == "Simple" or unitOwner:GetHealth() == nil then
		wndHealth:FindChild("MaxHealth"):SetAnchorOffsets(self.nFrameLeft, self.nFrameTop, self.nFrameRight, self.nFrameBottom)
		wndHealth:FindChild("HealthLabel"):SetText("")
		return
	end

	local nHealthCurr 	= unitOwner:GetHealth()
	local nHealthMax 	= unitOwner:GetMaxHealth()
	local nShieldCurr 	= unitOwner:GetShieldCapacity()
	local nShieldMax 	= unitOwner:GetShieldCapacityMax()
	local nAbsorbCurr 	= 0
	local nAbsorbMax 	= unitOwner:GetAbsorptionMax()
	if nAbsorbMax > 0 then
		nAbsorbCurr = unitOwner:GetAbsorptionValue() -- Since it doesn't clear when the buff drops off
	end
	local nTotalMax = nHealthMax-- + nShieldMax + nAbsorbMax

	-- Scaling
	--[[local nPointHealthRight = self.nFrameR * (nHealthCurr / nTotalMax) -
	local nPointShieldRight = self.nFrameR * ((nHealthCurr + nShieldMax) / nTotalMax)
	local nPointAbsorbRight = self.nFrameR * ((nHealthCurr + nShieldMax + nAbsorbMax) / nTotalMax)--]]

	local nPointHealthRight = self.nFrameLeft + (self.nHealthWidth * (nHealthCurr / nTotalMax)) -- applied to the difference between L and R
	local nPointShieldRight = self.nFrameLeft + (self.nHealthWidth * ((nHealthCurr + nShieldMax) / nTotalMax))
	--local nPointAbsorbRight = self.nFrameLeft + (self.nHealthWidth * ((nHealthCurr + nShieldMax + nAbsorbMax) / nTotalMax))


	if nShieldMax > 0 and nShieldMax / nTotalMax < 0.2 then
		local nMinShieldSize = 0.0 -- HARDCODE: Minimum shield bar length is 20% of total for formatting
		--nPointHealthRight = self.nFrameR * math.min(1-nMinShieldSize, nHealthCurr / nTotalMax) -- Health is normal, but caps at 80%
		--nPointShieldRight = self.nFrameR * math.min(1, (nHealthCurr / nTotalMax) + nMinShieldSize) -- If not 1, the size is thus healthbar + hard minimum

		--nPointHealthRight = self.nFrameLeft + (self.nHealthWidth*(math.min(1 - nMinShieldSize, nHealthCurr / nTotalMax)))
		--nPointShieldRight = self.nFrameLeft + (self.nHealthWidth*(math.min(1, (nHealthCurr / nTotalMax) + nMinShieldSize)))
	end

	-- Resize
	--wndHealth:FindChild("ShieldFill"):EnableGlow(nShieldCurr > 0)
	--self:SetBarValue(wndHealth:FindChild("ShieldFill"), 0, nShieldCurr, nShieldMax) -- Only the Curr Shield really progress fills
	--self:SetBarValue(wndHealth:FindChild("AbsorbFill"), 0, nAbsorbCurr, nAbsorbMax)
	wndHealth:FindChild("MaxHealth"):SetAnchorOffsets(self.nFrameLeft, self.nFrameTop, nPointHealthRight, self.nFrameBottom)
	--wndHealth:FindChild("MaxShield"):SetAnchorOffsets(nPointHealthRight + 80, self.nFrameTop, nPointShieldRight, self.nFrameBottom)
	--wndHealth:FindChild("MaxAbsorb"):SetAnchorOffsets(nPointShieldRight - 1, self.nFrameTop, nPointAbsorbRight, self.nFrameBottom)

	-- Bars
	--wndHealth:FindChild("ShieldFill"):Show(nHealthCurr > 0)
	wndHealth:FindChild("MaxHealth"):Show(nHealthCurr > 0)
	--wndHealth:FindChild("MaxShield"):Show(nHealthCurr > 0 and nShieldMax > 0)
	--wndHealth:FindChild("MaxAbsorb"):Show(nHealthCurr > 0 and nAbsorbMax > 0)

	-- Text
	local strHealthMax = self:HelperFormatBigNumber(nHealthMax)
	local strHealthCurr = self:HelperFormatBigNumber(nHealthCurr)
	local strShieldCurr = self:HelperFormatBigNumber(nShieldCurr)
	local strText = string.format("%s/%s", strHealthCurr, strHealthMax)
	
	--if nShieldMax > 0 and nShieldCurr > 0 then
		--strText = string.format("%s (%s)", strText, strShieldCurr)
	--end
	wndHealth:FindChild("HealthLabel"):SetText(strText)
	wndHealth:FindChild("ShieldLabel"):SetText(nShieldCurr)
	if nShieldCurr == nShieldMax then
		wndHealth:FindChild("ShieldLabel"):SetText(String_GetWeaselString("$1c", math.floor((nShieldCurr + nAbsorbCurr) / nShieldMax * 100)))
	else 
		wndHealth:FindChild("ShieldLabel"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Percent"), math.floor((nShieldCurr + nAbsorbCurr) / nShieldMax * 100)))
	end

	


	-- Sprite
	if nVulnerabilityTime and nVulnerabilityTime > 0 then
		wndHealth:FindChild("MaxHealth"):SetSprite("sprNp_Health_FillPurple")
	elseif nHealthCurr / nHealthMax < .3 then
		wndHealth:FindChild("MaxHealth"):SetSprite(ktHealthBarSprites[3])
	elseif 	nHealthCurr / nHealthMax < .5 then
		wndHealth:FindChild("MaxHealth"):SetSprite(ktHealthBarSprites[2])
	else
		wndHealth:FindChild("MaxHealth"):SetSprite(ktHealthBarSprites[1])
	end
-----------------------------------------------------------------------------------------------------------------
	if not self.unitPlayerDisposComparisonTEMP then
		self.unitPlayerDisposComparisonTEMP = GameLib.GetPlayerUnit()
	end

	local eDisposition = unitOwner:GetDispositionTo(self.unitPlayerDisposComparisonTEMP)
	 playerFaction = GameLib.GetPlayerUnit():GetFaction()
	 unitOwnerFaction = unitOwner:GetFaction()
	local class = -1

	if (GameLib.GetTargetUnit() ~= nil) then
		class = GameLib.GetTargetUnit():GetClassId()
	end

	if ((unitOwner:GetType() == "Player" or unitOwner:GetType() == "Pet") and playerFaction ~= unitOwnerFaction) then
	 	wndHealth:FindChild("MaxHealth"):SetSprite("WhiteFill")
		wndHealth:FindChild("MaxHealth"):SetBGColor(npClassColors[unitOwner:GetClassId()])
		wndHealth:FindChild("ShieldLabel"):Show(true)
		wndHealth:FindChild("WhiteSeperator"):Show(true)
		if unitOwner:GetType() == "Pet" then --nested if
			wndHealth:FindChild("MaxHealth"):SetBGColor("FFbed497")
		end
	elseif unitOwner:GetType() == "Player" and playerFaction == unitOwnerFaction then 
		--wndHealth:FindChild("MaxHealth"):SetSprite("PlayerPathContent_TEMP:spr_PathListItemProgressFill")
		wndHealth:FindChild("MaxHealth"):SetSprite("GreenCastBar")
		wndHealth:FindChild("ShieldLabel"):Show(true)
		wndHealth:FindChild("WhiteSeperator"):Show(true)
		
	elseif unitOwner:GetType() == "NonPlayer" then
		wndHealth:FindChild("MaxHealth"):SetSprite(karDisposition.HealthBar[eDisposition])
    end
		
	
	if (unitOwner:GetType() == "NonPlayer" and (nShieldCurr == 0 and nAbsorbCurr == 0)) then -- Hides shield % and shortens cast bar
		wndHealth:FindChild("ShieldLabel"):Show(false)
		wndHealth:FindChild("WhiteSeperator"):Show(false)
    	--wndCastBar:SetAnchorOffsets(51, 103, 223, 113)
	elseif (unitOwner:GetType() == "NonPlayer" and (nShieldCurr > 0 or nAbsorbCurr > 0)) then -- Shows shield % and lengthens cast bar
		wndHealth:FindChild("ShieldLabel"):Show(true)
		wndHealth:FindChild("WhiteSeperator"):Show(true)
	--elseif wndCastBar:IsShown() then
	--	wndCastBar:SetAnchorOffsets(0.20400, 0.66026, 0.89200, 0.72436)
	end
	
	if nAbsorbCurr > 0 then
		wndHealth:FindChild("ShieldLabel"):SetTextColor("yellow")
	elseif nAbsorbCurr == 0 then
		wndHealth:FindChild("ShieldLabel"):SetTextColor("cyan")
	end

	self:UpdateTargetedInfo(unitOwner)
	
	if 	(unitOwner:GetTarget() == nil) or (unitOwner:GetTarget():IsThePlayer() == false) then
			wndHealth:FindChild("RedBorder"):Show(false)
			wndHealth:FindChild("RedBorder1"):Show(false)
	elseif (unitOwner:GetTarget():IsThePlayer() == true) and (playerFaction == unitOwnerFaction) then
			wndHealth:FindChild("RedBorder"):Show(true)
			wndHealth:FindChild("RedBorder"):SetBGColor("green")
			wndHealth:FindChild("RedBorder1"):Show(true)
			wndHealth:FindChild("RedBorder1"):SetBGColor("green")
	elseif (unitOwner:GetTarget():IsThePlayer() == true) then
			wndHealth:FindChild("RedBorder"):Show(true)
			wndHealth:FindChild("RedBorder"):SetBGColor("red")
			wndHealth:FindChild("RedBorder1"):Show(true)
			wndHealth:FindChild("RedBorder1"):SetBGColor("red")
	end
	
	

	
	-- This isn't working!!! Supposed to change the color of the nameplates border if you are set as their focus
	--[[
	if 	(unitOwner:GetAlternateTarget() == nil) or (unitOwner:GetAlternateTarget():IsThePlayer() == false) then
			wndHealth:FindChild("RedBorder"):Show(false)
			wndHealth:FindChild("RedBorder1"):Show(false)
	elseif (unitOwner:GetAlternateTarget():IsThePlayer() == true) then
			wndHealth:FindChild("RedBorder"):Show(true)
			wndHealth:FindChild("RedBorder"):SetBGColor("cyan")
			wndHealth:FindChild("RedBorder1"):Show(true)
			wndHealth:FindChild("RedBorder1"):SetBGColor("cyan")
	end
	--]]


	
end

function Nameplates:HelperFormatBigNumber(nArg)
	-- Turns 99999 into 99.9k and 90000 into 90k
	local strResult
	if nArg < 1000 then
		strResult = nArg
	elseif math.floor(nArg%1000/100) == 0 then
		strResult = string.format("%sk", math.floor(nArg / 1000))
	else
		strResult = string.format("%s.%sk", math.floor(nArg / 1000), math.floor(nArg % 1000 / 100))
	end
	return strResult
end

function Nameplates:SetBarValue(wndBar, fMin, fValue, fMax)
	wndBar:SetMax(fMax)
	wndBar:SetFloor(fMin)
	wndBar:SetProgress(fValue)
end

function Nameplates:HelperCalculateConValue(unitTarget)
	if unitTarget == nil or GameLib.GetPlayerUnit() == nil then
		return 1
	end

	local nUnitCon = GameLib.GetPlayerUnit():GetLevelDifferential(unitTarget)

	local nCon = 1 --default setting

	if nUnitCon <= karConColors[1][1] then -- lower bound
		nCon = 1
	elseif nUnitCon >= karConColors[#karConColors][1] then -- upper bound
		nCon = #karConColors
	else
		for idx = 2, (#karConColors - 1) do -- everything in between
			if nUnitCon == karConColors[idx][1] then
				nCon = idx
			end
		end
	end

	return nCon
end

-----------------------------------------------------------------------------------------------
-- Reward update functions (in case you need to do something specific depending on the signal)
-----------------------------------------------------------------------------------------------
function Nameplates:OnQuestInit()
	if self.bShowRewardTypeQuest then
		self:OnRewardInfoUpdated()
	end
end

function Nameplates:OnQuestStateChanged()
	self:OnRewardInfoUpdated()
end

function Nameplates:OnQuestObjectiveUpdated()
	self:OnRewardInfoUpdated()
end

function Nameplates:OnUnitActivationTypeChanged()
	self:OnRewardInfoUpdated()
end

function Nameplates:OnPublicEventStart()
	if self.bShowRewardTypePublicEvent then
		self:OnRewardInfoUpdated()
	end
end

function Nameplates:OnPublicEventObjectiveUpdate()
	if self.bShowRewardTypePublicEvent then
		self:OnRewardInfoUpdated()
	end
end

function Nameplates:OnPublicEventEnd()
	if self.bShowRewardTypePublicEvent then
		self:OnRewardInfoUpdated()
	end
end

function Nameplates:OnChallengeUnlocked()
	if self.bShowRewardTypeChallenge then
		self:OnRewardInfoUpdated()
	end
end

function Nameplates:OnChallengeFailArea()
	if self.bShowRewardTypeChallenge then
		self:OnRewardInfoUpdated()
	end
end

function Nameplates:OnChallengeFailTime()
	if self.bShowRewardTypeChallenge then
		self:OnRewardInfoUpdated()
	end
end

function Nameplates:OnChallengeActivate()
	if self.bShowRewardTypeChallenge then
		self:OnRewardInfoUpdated()
	end
end

function Nameplates:OnChallengeCompleted() -- TODO: Hack because network traffic seems to delay the update to "completed"
	if self.bShowRewardTypeChallenge then
		Apollo.RegisterTimerHandler("ChallengeCompletedTimer", "OnRewardInfoUpdated", self)
		Apollo.CreateTimer("ChallengeCompletedTimer", 0.2, false)
		--self:OnRewardInfoUpdated()
	end
end

function Nameplates:OnPlayerPathMissionChange()
	if self.bShowRewardTypeMission then
		self:OnRewardInfoUpdated()
	end
end


-----------------------------------------------------------------------------------------------
function Nameplates:OnRewardInfoUpdated() -- we've recieved an external signal that reward stuff has been changed
	self.bRewardInfoDirty = true
end

function Nameplates:UpdateRewardInfo()
	if self.bInitialLoadAllClear == false then
		return
	end

	self.bRewardInfoDirty = false

	-- Quest backers first
	local tAdjustObjectives = {}
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		local bObjective = self:ParseRewards(tNameplate) -- get the new value
		if tNameplate.bIsObjective ~= bObjective then -- compare to old
			table.insert(tAdjustObjectives, tNameplate) -- add to list if they're not the same
		end
	end

	if tAdjustObjectives ~= nil then
		for idx, tNameplate in pairs(tAdjustObjectives) do
			local unitOwner = tNameplate.unitOwner
			local bHideMine = unitOwner:IsThePlayer() and not self.bShowMyNameplate
			if bHideMine or unitOwner:IsDead() or not unitOwner:ShouldShowNamePlate() then
				self:UnattachNameplateWindow(tNameplate)
			elseif tNameplate.bIsTarget == true or tNameplate.bIsCluster == true then
				self:SetTargetedNameplate(tNameplate)
			else
				self:SetNormalNameplate(tNameplate)
			end
			if tNameplate.wndNameplate ~= nil then
				tNameplate.wndNameplate:FindChild("Container"):ArrangeChildrenVert(2)
			end
		end
	end

	if self.bShowRewardsMain == false and self.bShowRewardsTarget == false then -- don't process rewards if they're not shown
		return
	end

	--There's no real efficient way to do this since the target may have the same number of rewards but have different info for them
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do -- run the list
		local unitOwner = tNameplate.unitOwner
		local bHideMine = unitOwner:IsThePlayer() and not self.bShowMyNameplate
		if bHideMine or unitOwner:IsDead() or not unitOwner:ShouldShowNamePlate() then -- the format functions update reward icons
			self:UnattachNameplateWindow(tNameplate)
		elseif tNameplate.bIsTarget == true or tNameplate.bIsCluster == true then
			self:SetTargetedNameplate(tNameplate)
		else
			self:SetNormalNameplate(tNameplate)
		end
		if tNameplate.wndNameplate ~= nil then
			tNameplate.wndNameplate:FindChild("Container"):ArrangeChildrenVert(2)
		end
	end
end

function Nameplates:ParseRewards(tNameplate)
	local unitOwner = tNameplate.unitOwner


	if unitOwner == nil then
		return
	end

	local tRewardInfo = {}
	tRewardInfo = unitOwner:GetRewardInfo()
	if tRewardInfo == nil or type(tRewardInfo) ~= "table" then
		tNameplate.bIsObjective = false
		return
	end

	local iRewards = 0

	local nRewardCount = #tRewardInfo
	if nRewardCount > 0 then
		for idx = 1, nRewardCount do
			local ePathId = PlayerPathLib.GetPlayerPathType()
			local strType = tRewardInfo[idx]["type"]
			if strType == "Quest" then
				iRewards = iRewards + 1
			--elseif strType == "Challenge" then -- NOTE: Challenges read as true even if you're not on the challenge
			--	iRewardCount = iRewardCount+1
			elseif strType == "Explorer" and ePathId == PlayerPathLib.PlayerPathType_Explorer then
				iRewards = iRewards + 1
			elseif strType == "Scientist" and ePathId == PlayerPathLib.PlayerPathType_Scientist then
				iRewards = iRewards + 1
			elseif strType == "Soldier" and ePathId == PlayerPathLib.PlayerPathType_Soldier then
				iRewards = iRewards + 1
			elseif strType == "Settler" and ePathId == PlayerPathLib.PlayerPathType_Settler then
				iRewards = iRewards + 1
			end
		end
	end

	--now do questgivers, etc

	local tActivation = unitOwner:GetActivationState()
	if tActivation.QuestTarget ~= nil then
		iRewards = iRewards + 1
	end
	if tActivation.QuestReward ~= nil then
		iRewards = iRewards + 1
	end
	if tActivation.QuestNew ~= nil or tActivation.QuestNewMain ~= nil then
		iRewards = iRewards + 1
	end
	if tActivation.QuestReceiving ~= nil then
		iRewards = iRewards + 1
	end
	if tActivation.TalkTo ~= nil then
		iRewards = iRewards + 1
	end

	tNameplate.bIsObjective = iRewards > 0
end

-----------------------------------------------------------------------------------------------
-- Reward Icon Helper Methods
-----------------------------------------------------------------------------------------------

function Nameplates:HelperDrawRewardTooltip(tRewardInfo, wndRewardIcon, strBracketText, strUnitName, tRewardString)
	if not tRewardInfo or not wndRewardIcon then return end
	-- TODO: set icon paths too

	local strMessage = tRewardInfo["title"]
	if tRewardInfo["mission"] and tRewardInfo["mission"]:GetName() then
		local pmMission = tRewardInfo["mission"]
		if tRewardInfo["isActivate"] and PlayerPathLib.GetPlayerPathType() ~= PlayerPathLib.PlayerPathType_Explorer then -- todo: see if we can remove this requirement
			strMessage = String_GetWeaselString(Apollo.GetString("Nameplates_ActivateForMission"), pmMission:GetName())
		else
			strMessage = string.format("%s %s/%s", pmMission:GetName(), pmMission:GetNumCompleted(), pmMission:GetNumNeeded())
		end
	end

	local strProgress = ""
	local strNeeded = tRewardInfo["needed"]
	local strCompleted = tRewardInfo["completed"]
	if strCompleted and strCompleted ~= "" and strNeeded and strNeeded ~= "" then
		strProgress = string.format(": %s/%s", strCompleted, strNeeded)
	end

	if wndRewardIcon:IsShown() then -- already have a tooltip
		tRewardString = string.format("%s<P Font=\"CRB_InterfaceMedium\" TextColor=\"ffffffff\">%s: %s%s</P>", tRewardString, strBracketText, strMessage, strProgress)
	else
		tRewardString = string.format("%s<P Font=\"CRB_InterfaceMedium\" TextColor=\"Yellow\">%s (%s)</P><P Font=\"CRB_InterfaceMedium\">%s%s</P>",
										tRewardString, strUnitName, strBracketText, strMessage, strProgress)
		wndRewardIcon:SetTooltip(tRewardString)
	end

	return tRewardString
end

function Nameplates:HelperLoadRewardIcon(wndRewardPanel, idx)
	if wndRewardPanel:FindChild(idx) then
		return wndRewardPanel:FindChild(idx)
	end

	local wndCurr = Apollo.LoadForm(self.xmlDoc, "RewardIcon", wndRewardPanel, self)
	wndCurr:SetName(idx)
	wndCurr:Show(false) -- Visibility is important

	local tRewardIcons =
	{
		"CRB_TargetFrameRewardPanelSprites:sprTargetFrame_ActiveQuest",
		"CRB_TargetFrameRewardPanelSprites:sprTargetFrame_Challenge",
		"CRB_TargetFrameRewardPanelSprites:sprTargetFrame_Achievement",
		"CRB_TargetFrameRewardPanelSprites:sprTargetFrame_Reputation",
		"CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSol",
		"CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSet",
		"CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSci",
		"CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathExp",
		"CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PublicEvent",
		"CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSciSpell",
	}


	local strSingle = tRewardIcons[idx] or ""

	wndCurr:FindChild("Single"):SetSprite(strSingle)

	if wndCurr:FindChild("Multi") then -- Note #4 doesn't have this child
		wndCurr:FindChild("Multi"):SetSprite(strSingle.."Multi") -- This is risky. It requires specific sprite naming.
	end

	return wndCurr
end

function Nameplates:HelperDrawRewardIcon(wndRewardIcon)
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

function Nameplates:HelperDrawSpellBind(wndIcon, idx)
	if idx ~= 1 then -- paths, not quest
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

function Nameplates:ShowRewardIcons(tNameplate)
	local unitOwner = tNameplate.unitOwner

	if unitOwner == nil then
		return 0
	end

	if tNameplate.wndNameplate == nil then
		return
	end

	local bIsFriend = unitOwner:IsFriend()
	local bIsRival = unitOwner:IsRival()
	local bIsAccountFriend = unitOwner:IsAccountFriend()
	local nFriendshipCount = (bIsFriend and 1 or 0) + (bIsRival and 1 or 0) + (bIsAccountFriend and 1 or 0)
	
	local tRewardInfo = {}
	tRewardInfo = unitOwner:GetRewardInfo()
	if (tRewardInfo == nil or type(tRewardInfo) ~= "table") and nFriendshipCount == 0 then
		return 0
	end

	local wndRewardPanel = tNameplate.wndNameplate:FindChild("QuestRewards")
	wndRewardPanel:DestroyChildren()
	wndRewardPanel:SetAnchorOffsets(0, 0, 0, 0)

	local tRewardString = {} -- temp table to store quest descriptions (builds multi-objective tooltips)
	for idx = 1, 9 do
		tRewardString[idx] = ""
	end

	local nRewardInfoListCount = tRewardInfo ~= nil and #tRewardInfo or 0
	if nRewardInfoListCount <= 0 and nFriendshipCount == 0 then
		return 0
	end

	local iRewardCount = 0
	for idx = 1, nRewardInfoListCount do
		local strType = tRewardInfo[idx]["type"]

		-- TODO Refactor: Replace this with a loop. There's a lot of copy pasted code.
		if strType == "Quest" and self.bShowRewardTypeQuest then
			local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, 1)
			iRewardCount = iRewardCount + self:HelperDrawRewardIcon(wndCurr)
			tRewardString[1] = self:HelperDrawRewardTooltip(tRewardInfo[idx], wndCurr, Apollo.GetString("CRB_Quest"), unitOwner:GetName(), tRewardString[1])
			wndCurr:SetTooltip(tRewardString[1])
			wndCurr:ToFront()

			if tRewardInfo[idx]["spell"] then
				self:HelperDrawSpellBind(wndCurr, 1)
			end
		elseif strType == "Challenge" and self.bShowRewardTypeChallenge and self.wndOptionsMain:FindChild("ShowRewardTypeChallenge"):IsEnabled() then
			local bActiveChallenge = false

			local tAllChallenges = ChallengesLib.GetActiveChallengeList()
			for index, clgCurr in pairs(tAllChallenges) do
				if tRewardInfo[idx]["id"] == clgCurr:GetId() and clgCurr:IsActivated() and not clgCurr:IsInCooldown() and not clgCurr:ShouldCollectReward() then
					bActiveChallenge = true
					break
				end
			end

			if bActiveChallenge then
				local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, 2)
				iRewardCount = iRewardCount + self:HelperDrawRewardIcon(wndCurr)
				tRewardString[2] = self:HelperDrawRewardTooltip(tRewardInfo[idx], wndCurr, Apollo.GetString("CBCrafting_Challenge"), unitOwner:GetName(), tRewardString[2])
				wndCurr:SetTooltip(tRewardString[2])
			end
		elseif strType == "Soldier" and PlayerPathLib.GetPlayerPathType() == PlayerPathLib.PlayerPathType_Soldier and self.bShowRewardTypeMission then
			local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, 5)
			iRewardCount = iRewardCount + self:HelperDrawRewardIcon(wndCurr)
			tRewardString[5] = self:HelperDrawRewardTooltip(tRewardInfo[idx], wndCurr, Apollo.GetString("Nameplates_Mission"), unitOwner:GetName(), tRewardString[5])
			wndCurr:SetTooltip(tRewardString[5])

			if tRewardInfo[idx]["spell"] then
				self:HelperDrawSpellBind(wndCurr, 5)
			end
		elseif strType == "Settler" and PlayerPathLib.GetPlayerPathType() == PlayerPathLib.PlayerPathType_Settler and self.bShowRewardTypeMission then
			local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, 6)
			iRewardCount = iRewardCount + self:HelperDrawRewardIcon(wndCurr)
			tRewardString[6] = self:HelperDrawRewardTooltip(tRewardInfo[idx], wndCurr, Apollo.GetString("Nameplates_Mission"), unitOwner:GetName(), tRewardString[6])
			wndCurr:SetTooltip(tRewardString[6])

			if tRewardInfo[idx]["spell"] then
				self:HelperDrawSpellBind(wndCurr, 6)
			end
		elseif strType == "Scientist" and PlayerPathLib.GetPlayerPathType() == PlayerPathLib.PlayerPathType_Scientist and self.bShowRewardTypeMission then
			if tRewardInfo[idx]["spell"] == nil then
				local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, 7)

				local pmMission = tRewardInfo[idx]["mission"]
				local strMission = ""
				if pmMission then
					if pmMission:GetMissionState() >= PathMission.PathMissionState_Unlocked then
						if pmMission:GetType() == PathMission.PathMissionType_Scientist_FieldStudy then
						strMission = string.format("%s %s/%s", pmMission:GetName(), pmMission:GetNumCompleted(), pmMission:GetNumNeeded())
							local tActions = pmMission:GetScientistFieldStudy()
							if tActions then
								for idx, tEntry in ipairs(tActions) do
									if not tEntry.completed then
										strMission = string.format("%s ... %s", strMission , tEntry.name)
									end
								end
							end
						else
							strMission = string.format("%s %s/%s", pmMission:GetName(), pmMission:GetNumCompleted(), pmMission:GetNumNeeded())
						end
					else
						strMission = "???"
					end
				end

				iRewardCount = iRewardCount + self:HelperDrawRewardIcon(wndCurr)

				local strProgress = "" -- specific to #7
				local strUnitName = unitOwner:GetName() -- specific to #7
				local strBracketText = Apollo.GetString("Nameplates_Missions") -- specific to #7
				if wndCurr:IsShown() then -- already have a tooltip
					tRewardString[7] = string.format("%s<P Font=\"CRB_InterfaceMedium\" TextColor=\"ffffffff\">%s%s</P>", tRewardString[7], strMission, strProgress)
				else
					tRewardString[7] = string.format("%s<P Font=\"CRB_InterfaceMedium\" TextColor=\"Yellow\">%s (%s)</P>"..
													 "<P Font=\"CRB_InterfaceMedium\">%s%s</P>", tRewardString[7], strUnitName, strBracketText, strMessage, strProgress)
				end
				-- ALL scientist stuff uses spells so this become redundant
				--[[if rewardInfoList[ix]["spell"] then
					self:HelperDrawSpellBind(wndCurr, 7)
				end--]]

				wndCurr:SetTooltip(tRewardString[7])
			end
			
			local splSpell = tRewardInfo[idx]["spell"]
			if splSpell then
				local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, 10)
				iRewardCount = iRewardCount + self:HelperDrawRewardIcon(wndCurr)
				Tooltip.GetSpellTooltipForm(self, wndCurr, splSpell)
			end

		elseif strType == "Explorer" and PlayerPathLib.GetPlayerPathType() == PlayerPathLib.PlayerPathType_Explorer and self.bShowRewardTypeMission then
			local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, 8)
			iRewardCount = iRewardCount + self:HelperDrawRewardIcon(wndCurr)
			tRewardString[8] = self:HelperDrawRewardTooltip(tRewardInfo[idx], wndCurr, "Mission", unitOwner:GetName(), tRewardString[8])
			wndCurr:SetTooltip(tRewardString[8])

			if tRewardInfo[idx]["spell"] then
				self:HelperDrawSpellBind(wndCurr, 8)
			end
		elseif strType == "PublicEvent" and self.bShowRewardTypePublicEvent then
			local wndCurr = self:HelperLoadRewardIcon(wndRewardPanel, 9)

			local peEvent = tRewardInfo[idx].objective
			local strTitle = peEvent:GetEvent():GetName()
			local nCompleted = peEvent:GetCount()
			local nNeeded = peEvent:GetRequiredCount()

			iRewardCount = iRewardCount + self:HelperDrawRewardIcon(wndCurr)

			if wndCurr:IsShown() then -- already have a tooltip
				-- Do nothing. It has been cut below
			else
				local strPublicEventMarker = String_GetWeaselString(Apollo.GetString("Nameplates_PublicEvents"), unitOwner:GetName())
				tRewardString[9] = string.format("<P Font=\"CRB_InterfaceMedium\" TextColor=\"Yellow\">%s</P>", strPublicEventMarker)
			end

			if peEvent:GetObjectiveType() == PublicEventObjective.PublicEventObjectiveType_Exterminate then
				strNumRemaining = String_GetWeaselString(Apollo.GetString("Nameplates_NumRemaining"), strTitle, nCompleted)
				tRewardString[9] = string.format("%s<P Font=\"CRB_InterfaceMedium\">%s</P>", tRewardString[9], strNumRemaining)
			elseif peEvent:ShowPercent() then
				strPercentCompleted = String_GetWeaselString(Apollo.GetString("Nameplates_PercentCompleted"), strTitle, nCompleted / nNeeded * 100)
				tRewardString[9] = string.format("%s<P Font=\"CRB_InterfaceMedium\">%s</P>", tRewardString[9], strPercentCompleted)
			else
				tRewardString[9] = string.format("%s<P Font=\"CRB_InterfaceMedium\">%s: %s/%s</P>", tRewardString[9], strTitle, nCompleted, nNeeded)
			end

			wndCurr:ToFront()
			wndCurr:SetTooltip(tRewardString[9])
		end
	end
	
	if bIsRival then
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "RewardIcon", wndRewardPanel, self)
		wndCurr:FindChild("Single"):SetSprite("ClientSprites:Icon_Windows_UI_CRB_Rival")
		wndCurr:SetTooltip("<P Font=\"CRB_InterfaceMedium\" TextColor=\"Yellow\">" .. Apollo.GetString("TargetFrame_Rival") .. "</P>")
		wndCurr:Show(false) -- Visibility is important
		wndCurr:ToFront()
		
		if self.bShowRivals then
			iRewardCount = iRewardCount + 1
			wndCurr:Show(true)
		end
	end
	
	if bIsFriend then
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "RewardIcon", wndRewardPanel, self)
		wndCurr:FindChild("Single"):SetSprite("ClientSprites:Icon_Windows_UI_CRB_Friend")
		wndCurr:SetTooltip("<P Font=\"CRB_InterfaceMedium\" TextColor=\"Yellow\">" .. Apollo.GetString("TargetFrame_Friend") .. "</P>")
		wndCurr:Show(false) -- Visibility is important
		wndCurr:ToFront()
		
		if self.bShowFriends then
			iRewardCount = iRewardCount + 1
			wndCurr:Show(true)
		end
	end
	
	if bIsAccountFriend then
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "RewardIcon", wndRewardPanel, self)
		wndCurr:FindChild("Single"):SetSprite("ClientSprites:Icon_Windows_UI_CRB_Friend")
		wndCurr:SetTooltip("<P Font=\"CRB_InterfaceMedium\" TextColor=\"Yellow\">" .. Apollo.GetString("TargetFrame_AccountFriend") .. "</P>")
		wndCurr:Show(false) -- Visibility is important
		wndCurr:ToFront()
		
		if self.bShowFriends then
			iRewardCount = iRewardCount + 1
			wndCurr:Show(true)
		end
	end

	if iRewardCount > 0 then
		wndRewardPanel:SetAnchorOffsets(0, 0, knRewardWidth * iRewardCount, knNameRewardHeight) -- set it (first number is a negative offset)
		wndRewardPanel:ArrangeChildrenHorz(1)
	end

	return iRewardCount
end

-----------------------------------------------------------------------------------------------
-- NameplatesForm Functions
-----------------------------------------------------------------------------------------------

function Nameplates:OnNormalViewCheck(wndHandler, wndCtrl)
	self.wndMain:FindChild("ContentMain"):Show(true)
	self.wndMain:FindChild("ContentTarget"):Show(false)
end

function Nameplates:OnTargetViewCheck(wndHandler, wndCtrl)
	self.wndMain:FindChild("ContentMain"):Show(false)
	self.wndMain:FindChild("ContentTarget"):Show(true)
end

-- when the OK button is clicked
function Nameplates:OnOK()
	self.wndMain:Show(false) -- hide the window
end

-- when the Cancel button is clicked
function Nameplates:OnCancel()
	self.wndMain:Show(false) -- hide the window
end

----------------------- Main: draw Options	-----------------------
function Nameplates:OnMainShowAlways(wndHandler, wndCtrl)
	local bDrawAlways = wndCtrl:IsChecked()

	self.wndOptionsMain:FindChild("MainShowGroup"):SetCheck(not bDrawAlways)
	self.wndOptionsMain:FindChild("MainShowObjectives"):SetCheck(not bDrawAlways)
	self.wndOptionsMain:FindChild("MainShowNever"):SetCheck(not bDrawAlways)
	self.wndOptionsMain:FindChild("MainShowMine"):SetCheck(not bDrawAlways)

	self.bShowMainAlways = bDrawAlways	-- onDraw
	self.bShowMainObjectiveOnly = not bDrawAlways -- onDraw
	self.bShowMyNameplate = bDrawAlways -- this happens outside most draw loops and has to be hand-treated
	for idx = 1, 3 do
		self.wndOptionsMain:FindChild("MainShowDisposition_" .. idx):SetCheck(not bDrawAlways)
		self.tShowDispositionOnly[idx] = not bDrawAlways -- onDraw
	end

	self:OptionsChanged()
end

function Nameplates:OnMainShowObjectives(wndHandler, wndCtrl)
	local bDrawObjectives = wndCtrl:IsChecked()
	self.bShowMainObjectiveOnly = bDrawObjectives -- onDraw
	self:UpdateFilterOptions()
end

function Nameplates:OnMainShowGroup(wndHandler, wndCtrl)
	local bDrawGroupMembers = wndCtrl:IsChecked()
	self.bShowMainGroupOnly = bDrawGroupMembers -- onDraw
	self:UpdateFilterOptions()
end

function Nameplates:OnMainShowMine(wndHandler, wndCtrl)
	local bDrawMine = wndCtrl:IsChecked()
	self.bShowMyNameplate = bDrawMine
	self:UpdateFilterOptions()
	self:OptionsChanged()
end

function Nameplates:OnMainShowHostiles(wndHandler, wndCtrl)
	local bDrawHostiles = wndCtrl:IsChecked()
	self.tShowDispositionOnly[1] = bDrawHostiles -- onDraw
	self:UpdateFilterOptions()
end

function Nameplates:OnMainShowNeutrals(wndHandler, wndCtrl)
	local bDrawHostiles = wndCtrl:IsChecked()
	self.tShowDispositionOnly[2] = bDrawHostiles -- onDraw
	self:UpdateFilterOptions()
end

function Nameplates:OnMainShowFriendlies(wndHandler, wndCtrl)
	local bDrawHostiles = wndCtrl:IsChecked()
	self.tShowDispositionOnly[3] = bDrawHostiles -- onDraw
	self:UpdateFilterOptions()
end

function Nameplates:UpdateFilterOptions() -- sets the buttons
	local iFiltersOn = 0

	for idx = 1, 3 do
		if self.wndOptionsMain:FindChild("MainShowDisposition_" .. idx):IsChecked() then
			iFiltersOn = iFiltersOn + 1
			self.tShowDispositionOnly[idx] = true
		else
			self.tShowDispositionOnly[idx] = false
		end
	end

	if self.wndOptionsMain:FindChild("MainShowObjectives"):IsChecked() then
		iFiltersOn = iFiltersOn + 1
	end

	if self.wndOptionsMain:FindChild("MainShowGroup"):IsChecked() then
		iFiltersOn = iFiltersOn + 1
	end

	-- this happens outside most draw loops and has to be hand-treated
	self.bShowMyNameplate = self.wndOptionsMain:FindChild("MainShowMine"):IsChecked()

	if self.wndOptionsMain:FindChild("MainShowMine"):IsChecked() then
		iFiltersOn = iFiltersOn + 1
	end

	if iFiltersOn == 0 then -- we've turned off the last filter
		self.wndOptionsMain:FindChild("MainShowNever"):SetCheck(false)
		self.wndOptionsMain:FindChild("MainShowAlways"):SetCheck(true)
		self.bShowMainAlways = true	-- onDraw
	else -- at least one filter on
		self.wndOptionsMain:FindChild("MainShowAlways"):SetCheck(false)
		self.wndOptionsMain:FindChild("MainShowNever"):SetCheck(false)
		self.bShowMainAlways = false
	end
end

function Nameplates:OnMainShowNever(wndHandler, wndCtrl)
	local bDrawNever = true

	self.wndOptionsMain:FindChild("MainShowObjectives"):SetCheck(not bDrawNever)
	self.wndOptionsMain:FindChild("MainShowAlways"):SetCheck(not bDrawNever)
	self.wndOptionsMain:FindChild("MainShowGroup"):SetCheck(not bDrawNever)
	self.wndOptionsMain:FindChild("MainShowMine"):SetCheck(not bDrawNever)
	self.bShowMainAlways = not bDrawNever	-- onDraw
	self.bShowMainObjectiveOnly = not bDrawNever -- onDraw
	self.bShowMainGroupOnly = not bDrawNever -- onDraw
	self.bShowMyNameplate = not bDrawNever -- onDraw

	for idx = 1,3 do
		self.wndOptionsMain:FindChild("MainShowDisposition_" .. idx):SetCheck(not bDrawNever)
		self.tShowDispositionOnly[idx] = not bDrawNever -- onDraw
	end
end

----------------------- Main: distance	-----------------------
function Nameplates:OnDrawDistanceSlider(wndNameplate, wndHandler, nValue, nOldvalue)
	self.wndOptionsMain:FindChild("DrawDistanceLabel"):SetText(String_GetWeaselString(Apollo.GetString("Nameplates_DrawDistance"), nValue))
	self.nMaxRange = nValue-- set new constant, apply math
end


----------------------- Main: settings	-----------------------
function Nameplates:OnMainShowNameAlways(wndHandler, wndCtrl)
	self.bShowNameMain = true
	self.bShowTitle = true

	self.wndOptionsMain:FindChild("MainShowNameAlways"):SetCheck(true)
	self.wndOptionsMain:FindChild("MainShowNameOnly"):SetCheck(false)
	self.wndOptionsMain:FindChild("MainShowNameNever"):SetCheck(false)

	self:OptionsChanged()
end

-- not actually part of the radio group since it modifies a few settings
function Nameplates:OnMainShowNameOnly(wndHandler, wndCtrl)
	self.bShowNameMain = true
	self.bShowTitle = false

	self.wndOptionsMain:FindChild("MainShowNameAlways"):SetCheck(false)
	self.wndOptionsMain:FindChild("MainShowNameOnly"):SetCheck(true)
	self.wndOptionsMain:FindChild("MainShowNameNever"):SetCheck(false)

	self:OptionsChanged()
end

function Nameplates:OnMainShowNameNever(wndHandler, wndCtrl)
	self.bShowNameMain = false
	self.bShowTitle = false

	self.wndOptionsMain:FindChild("MainShowNameAlways"):SetCheck(false)
	self.wndOptionsMain:FindChild("MainShowNameOnly"):SetCheck(false)
	self.wndOptionsMain:FindChild("MainShowNameNever"):SetCheck(true)

	self:OptionsChanged()
end

function Nameplates:OnMainShowHealthBar(wndHandler, wndCtrl)
	if wndHandler ~= wndCtrl then
		return
	end

	local eOption = wndCtrl:GetData()

	if eOption == 1 then -- always
		self.bShowHealthMain = true
		self.bShowHealthMainDamaged = false
	elseif eOption == 2 then -- when damaged
		self.bShowHealthMain = false
		self.bShowHealthMainDamaged = true
	elseif eOption == 3 then -- never
		self.bShowHealthMain = false
		self.bShowHealthMainDamaged = false
	else
	end

	self:OptionsChanged()
end

function Nameplates:OnMainShowRewards(wndHandler, wndCtrl)
	local bDrawRewardsMain = wndCtrl:IsChecked()
	self.bShowRewardsMain = bDrawRewardsMain	 -- tabled

	self.wndOptionsMain:FindChild("ShowRewardTypeQuest"):Enable(self.bShowRewardsMain)
	self.wndOptionsMain:FindChild("ShowRewardTypeChallenge"):Enable(self.bShowRewardsMain)
	self.wndOptionsMain:FindChild("ShowRewardTypeAchievement"):Enable(self.bShowRewardsMain)
	self.wndOptionsMain:FindChild("ShowRewardTypeReputation"):Enable(self.bShowRewardsMain)
	self.wndOptionsMain:FindChild("ShowRewardTypeMission"):Enable(self.bShowRewardsMain)
	self.wndOptionsMain:FindChild("ShowRewardTypePublicEvent"):Enable(self.bShowRewardsMain)

	self:OptionsChanged()
end

function Nameplates:OnMainShowRewardsOff(wndHandler, wndCtrl)
	local bDrawRewardsMain = not wndCtrl:IsChecked()
	self.bShowRewardsMain = bDrawRewardsMain	 -- tabled

	self.wndOptionsMain:FindChild("ShowRewardTypeQuest"):Enable(self.bShowRewardsMain)
	self.wndOptionsMain:FindChild("ShowRewardTypeChallenge"):Enable(self.bShowRewardsMain)
	self.wndOptionsMain:FindChild("ShowRewardTypeAchievement"):Enable(self.bShowRewardsMain)
	self.wndOptionsMain:FindChild("ShowRewardTypeReputation"):Enable(self.bShowRewardsMain)
	self.wndOptionsMain:FindChild("ShowRewardTypeMission"):Enable(self.bShowRewardsMain)
	self.wndOptionsMain:FindChild("ShowRewardTypePublicEvent"):Enable(self.bShowRewardsMain)

	self:OptionsChanged()
end
---------------------------------------------------------------
---------------------------------------------------------------

function Nameplates:OnShowRewardTypeQuest(wndHandler, wndCtrl)
	local bOptionChecked = wndCtrl:IsChecked()
	self.bShowRewardTypeQuest = bOptionChecked	 -- tabled
	self:OptionsChanged()
end

function Nameplates:OnShowRewardTypeMission(wndHandler, wndCtrl)
	local bOptionChecked = wndCtrl:IsChecked()
	self.bShowRewardTypeMission = bOptionChecked	 -- tabled
	self:OptionsChanged()
end

function Nameplates:OnShowRewardTypeAchievement(wndHandler, wndCtrl)
	local bOptionChecked = wndCtrl:IsChecked()
	self.bShowRewardTypeAchievement = bOptionChecked	 -- tabled
	self:OptionsChanged()
end

function Nameplates:OnShowRewardTypeChallenge(wndHandler, wndCtrl)
	local bOptionChecked = wndCtrl:IsChecked()
	self.bShowRewardTypeChallenge = bOptionChecked	 -- tabled
	self:OptionsChanged()
end

function Nameplates:OnShowRewardTypeReputation(wndHandler, wndCtrl)
	local bOptionChecked = wndCtrl:IsChecked()
	self.bShowRewardTypeReputation = bOptionChecked	 -- tabled
	self:OptionsChanged()
end

function Nameplates:OnShowRewardTypePublicEvent(wndHandler, wndCtrl)
	local bOptionChecked = wndCtrl:IsChecked()
	self.bShowRewardTypePublicEvent = bOptionChecked	 -- tabled
	self:OptionsChanged()
end

function Nameplates:OnShowRewardFriends(wndHandler, wndControl, eMouseButton)
	self.bShowFriends = wndControl:IsChecked()
	self:OptionsChanged()
end

function Nameplates:OnShowRewardTypeRivals(wndHandler, wndControl, eMouseButton)
	self.bShowRivals = wndControl:IsChecked()
	self:OptionsChanged()
end

---------------------------------------------------------------
---------------------------------------------------------------

function Nameplates:OnMainShowCastBar(wndHandler, wndCtrl)
	local bDrawCastBarMain = wndCtrl:IsChecked()
	self.bShowCastBarMain = bDrawCastBarMain -- ondraw
	self:OptionsChanged()
end

function Nameplates:OnMainShowCastBarOff(wndHandler, wndCtrl)
	local bDrawCastBarMain = not wndCtrl:IsChecked()
	self.bShowCastBarMain = bDrawCastBarMain -- ondraw
	self:OptionsChanged()
end

function Nameplates:OnMainShowGuildNameToggle(wndHandler, wndControl)
	self.bShowGuildNameMain = true
	self:OptionsChanged()
end

function Nameplates:OnMainShowGuildNameToggleOff(wndHandler, wndControl)
	self.bShowGuildNameMain = false
	self:OptionsChanged()
end

function Nameplates:OnTargetedShowGuildNameToggle(wndHandler, wndControl)
	self.bShowGuildNameTarget = self.wndOptionsTargeted:FindChild("TargetedShowGuild"):IsChecked()
	self:OptionsChanged()
end

function Nameplates:OnMainHideInCombat(wndHandler, wndCtrl)
	self.bHideInCombat = wndCtrl:IsChecked() -- onDraw
end

function Nameplates:OnMainHideInCombatOff(wndHandler, wndCtrl)
	self.bHideInCombat = not wndCtrl:IsChecked() -- onDraw
end

function Nameplates:OnTargetedShowName(wndHandler, wndCtrl)
	local bDrawNameTargeted = wndCtrl:IsChecked()
	self.bShowNameTarget = bDrawNameTargeted	 -- tabled
	self:OptionsChanged()
end

function Nameplates:OnTargetedShowNameOff(wndHandler, wndCtrl)
	local bDrawNameTargeted = not wndCtrl:IsChecked()
	self.bShowNameTarget = bDrawNameTargeted	 -- tabled
	self:OptionsChanged()
end

function Nameplates:OnTargetedShowHealthBar(wndHandler, wndCtrl)
	self.bShowHealthTarget = true  -- tabled
	self:OptionsChanged()
end

function Nameplates:OnTargetedShowHealthBarOff(wndHandler, wndCtrl)
	self.bShowHealthTarget = false  -- tabled
	self:OptionsChanged()
end

function Nameplates:OnTargetedShowRewards(wndHandler, wndCtrl)
	local bDrawRewardsTargeted = wndCtrl:IsChecked()
	self.bShowRewardsTarget = bDrawRewardsTargeted	 -- tabled
	self:OptionsChanged()
end

function Nameplates:OnTargetedShowRewardsOff(wndHandler, wndCtrl)
	local bDrawRewardsTargeted = not wndCtrl:IsChecked()
	self.bShowRewardsTarget = bDrawRewardsTargeted	 -- tabled
	self:OptionsChanged()
end

function Nameplates:OnTargetedShowCastBar(wndHandler, wndCtrl)
	self.bShowCastBarTarget = wndCtrl:IsChecked()	 -- onDraw
	self:OptionsChanged()
end

function Nameplates:OnTargetedShowCastBarOff(wndHandler, wndCtrl)
	self.bShowCastBarTarget = not wndCtrl:IsChecked()	 -- onDraw
	self:OptionsChanged()
end

function Nameplates:OnTargetedShowRange(wndHandler, wndCtrl)
	local bDrawRangeTargeted = wndCtrl:IsChecked()
	self.bShowRangeTarget = bDrawRangeTargeted -- tabled
	self:OptionsChanged()
end

function Nameplates:OnTargetedShowRangeOff(wndHandler, wndCtrl)
	local bDrawRangeTargeted = not wndCtrl:IsChecked()
	self.bShowRangeTarget = bDrawRangeTargeted -- tabled
	self:OptionsChanged()
end

function Nameplates:OnTargetedShowMarker(wndHandler, wndCtrl)
	local bDrawMarkerTargeted = wndCtrl:IsChecked()
	self.bShowMarkerTarget = bDrawMarkerTargeted -- tabled
	self:OptionsChanged()
end

function Nameplates:OnTargetedShowMarkerOff(wndHandler, wndCtrl)
	local bDrawMarkerTargeted = not wndCtrl:IsChecked()
	self.bShowMarkerTarget = bDrawMarkerTargeted -- tabled
	self:OptionsChanged()
end

function Nameplates:OptionsChanged()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil then
		Apollo.StartTimer("InitialParseTimer", 1.0, false) -- ensures the player is fully loaded
		return
	end

	self.unitPlayerDisposComparisonTEMP = unitPlayer
	self.bBlinded = unitPlayer:IsInCCState(Unit.CodeEnumCCState.Blind)

	self.bInitialLoadAllClear = true

	for idx, tNameplate in pairs(self.arDisplayedNameplates) do
		local unitOwner = tNameplate.unitOwner
		self:ParseRewards(tNameplate)

		-- reward icons get updated in the formatting functions below
		local bHideMine = unitOwner:IsThePlayer() and not self.bShowMyNameplate

		if bHideMine or unitOwner:IsDead() or not unitOwner:ShouldShowNamePlate() then
			self:UnattachNameplateWindow(tNameplate)
		elseif tNameplate.bIsTarget == true or tNameplate.bIsCluster == true then
			self:SetTargetedNameplate(tNameplate) -- no need to set target since it should be shown already
			tNameplate.wndNameplate:FindChild("TargetMarker"):Show(self.bShowMarkerTarget)
		else
			self:SetNormalNameplate(tNameplate)
		end
		if tNameplate.wndNameplate ~= nil then
			tNameplate.wndNameplate:FindChild("Container"):ArrangeChildrenVert(2)
		end
	end
	self:OnSecondaryParseTimer()
end

function Nameplates:OnSecondaryParseTimer() -- keeps everything clean
	if self.bInitialLoadAllClear == false then
		return
	end

	local nCount = 0
	local nWindows = 0
	local nVisible = 0
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		nCount = nCount + 1
		local unitOwner = tNameplate.unitOwner
		if tNameplate.wndNameplate ~= nil then
			nWindows = nWindows + 1
			self:ParseRewards(tNameplate)
			if tNameplate.wndNameplate:IsVisible() then
				nVisible = nVisible + 1

				-- reward icons get updated in the formatting functions below
				local bHideMine = unitOwner:IsThePlayer() and not self.bShowMyNameplate
				if bHideMine or unitOwner:IsDead() or not unitOwner:ShouldShowNamePlate() then
					self:UnattachNameplateWindow(tNameplate)
				elseif tNameplate.bIsTarget == true or tNameplate.bIsCluster == true then
					self:SetTargetedNameplate(tNameplate) -- no need to set target since it should be shown already
				else
					self:SetNormalNameplate(tNameplate)
				end
				if tNameplate.wndNameplate ~= nil then
					tNameplate.wndNameplate:FindChild("Container"):ArrangeChildrenVert(2)
				end
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Nameplates Instance
-----------------------------------------------------------------------------------------------
local NameplatesInst = Nameplates:new()
NameplatesInst:Init()
