-----------------------------------------------------------------------------------------------
-- Client Lua Script for PvP_PublicEventStats
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "PublicEvent"
require "MatchingGame"

local PvP_PublicEventStats = {}

function PvP_PublicEventStats:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function PvP_PublicEventStats:Init()
    Apollo.RegisterAddon(self)
end

local knMaxWndMainWidth = 950


local ktParticipantKeys = -- Can swap to event type id's, but this just saves space
{
	["Arena"] =
	{
		"strName",
		"nKills",
		"nDeaths",
		"nAssists",
		"nDamage",
		"nHealed",
		"nDamageReceived",
		"nHealingReceived",
		"nSaves"
	},

	["WarPlot"] =
	{
		"strName",
		"nKills",
		"nDeaths",
		"nAssists",
		"nDamage",
		"nHealed",
		"nDamageReceived",
		"nHealingReceived",
		"nSaves",
		"nKillStreak"
	},

	["HoldTheLine"] =
	{
		"strName",
		"nKills",
		"nDeaths",
		"nAssists",
		"nCustomNodesCaptured",
		"nDamage",
		"nHealed",
		"nDamageReceived",
		"nHealingReceived",
		"nSaves",
		"nKillStreak"
	},
	["CTF"] =
	{
		"strName",
		"nKills",
		"nDeaths",
		"nAssists",
		"nCustomFlagsPlaced",
		"bCustomFlagsStolen",
		"nDamage",
		"nHealed",
		"nDamageReceived",
		"nHealingReceived",
		"nSaves",
		"nKillStreak"
	},
	["Sabotage"] =
	{
		"strName",
		"nKills",
		"nDeaths",
		"nAssists",
		"nDamage",
		"nHealed",
		"nDamageReceived",
		"nHealingReceived",
		"nSaves",
		"nKillStreak"
	}
}

local kstrClassToMLIcon =
{
	[GameLib.CodeEnumClass.Warrior] 		= "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Warrior\"></T> ",
	[GameLib.CodeEnumClass.Engineer] 		= "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Engineer\"></T> ",
	[GameLib.CodeEnumClass.Esper] 			= "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Esper\"></T> ",
	[GameLib.CodeEnumClass.Medic] 			= "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Medic\"></T> ",
	[GameLib.CodeEnumClass.Stalker] 		= "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Stalker\"></T> ",
	[GameLib.CodeEnumClass.Spellslinger] 	= "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Spellslinger\"></T> ",
}

local ktPvPEvents =
{
	[PublicEvent.PublicEventType_PVP_Arena] 					= true,
	[PublicEvent.PublicEventType_PVP_Warplot] 					= true,
	[PublicEvent.PublicEventType_PVP_Battleground_Vortex] 		= true,
	[PublicEvent.PublicEventType_PVP_Battleground_Cannon] 		= true,
	[PublicEvent.PublicEventType_PVP_Battleground_Sabotage]		= true,
	[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine] 	= true,
}

local ktEventTypeToWindowName =
{
	[PublicEvent.PublicEventType_PVP_Arena] 					= "PvPArenaContainer",
	[PublicEvent.PublicEventType_PVP_Warplot] 					= "PvPWarPlotContainer",
	[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine] 	= "PvPHoldContainer",
	[PublicEvent.PublicEventType_PVP_Battleground_Vortex] 		= "PvPCTFContainer",
	[PublicEvent.PublicEventType_PVP_Battleground_Sabotage] 	= "PvPSaboContainer",
	[PublicEvent.PublicEventType_WorldEvent] 					= "PublicEventGrid", -- TODO
	[PublicEvent.PublicEventType_Dungeon] 						= "PublicEventGrid", -- TODO
}

-- necessary until we can either get column names for a compare/swap or a way to set localized strings in XML for columns
local ktEventTypeToColumnNameList =
{
	[PublicEvent.PublicEventType_PVP_Arena] =
	{
		"PublicEventStats_Name",
		"PublicEventStats_Kills",
		"PublicEventStats_Deaths",
		"PublicEventStats_Assists",
		"PublicEventStats_DamageDone",
		"PublicEventStats_HealingDone",
		"PublicEventStats_DamageTaken",
		"PublicEventStats_HealingTaken",
		"PublicEventStats_Saves"
	},
	[PublicEvent.PublicEventType_PVP_Warplot] =
	{
		"PublicEventStats_Name",
		"PublicEventStats_Kills",
		"PublicEventStats_Deaths",
		"PublicEventStats_Assists",
		"PublicEventStats_DamageDone",
		"PublicEventStats_HealingDone",
		"PublicEventStats_DamageTaken",
		"PublicEventStats_HealingTaken",
		"PublicEventStats_Saves",
		"PublicEventStats_KillStreak"
	},
	[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine] =
	{
		"PublicEventStats_Name",
		"PublicEventStats_Kills",
		"PublicEventStats_Deaths",
		"PublicEventStats_Assists",
		"PublicEventStats_Captures",
		"PublicEventStats_DamageDone",
		"PublicEventStats_HealingDone",
		"PublicEventStats_DamageTaken",
		"PublicEventStats_HealingTaken",
		"PublicEventStats_Saves",
		"PublicEventStats_KillStreak"
	},
	[PublicEvent.PublicEventType_PVP_Battleground_Vortex] =
	{
		"PublicEventStats_Name",
		"PublicEventStats_Kills",
		"PublicEventStats_Deaths",
		"PublicEventStats_Assists",
		"PublicEventStats_Captures",
		"PublicEventStats_Stolen",
		"PublicEventStats_DamageDone",
		"PublicEventStats_HealingDone",
		"PublicEventStats_DamageTaken",
		"PublicEventStats_HealingTaken",
		"PublicEventStats_Saves",
		"PublicEventStats_KillStreak"
	},
	[PublicEvent.PublicEventType_PVP_Battleground_Sabotage] =
	{
		"PublicEventStats_Name",
		"PublicEventStats_Kills",
		"PublicEventStats_Deaths",
		"PublicEventStats_Assists",
		"PublicEventStats_DamageDone",
		"PublicEventStats_HealingDone",
		"PublicEventStats_DamageTaken",
		"PublicEventStats_HealingTaken",
		"PublicEventStats_Saves",
		"PublicEventStats_KillStreak"
	},
	[PublicEvent.PublicEventType_WorldEvent] =
	{
		"PublicEventStats_Name",
		"PublicEventStats_Contribution",
		"PublicEventStats_DamageDone",
		"PublicEventStats_DamageTaken",
		"PublicEventStats_HealingDone",
		"PublicEventStats_HealingTaken"
	},
	[PublicEvent.PublicEventType_Dungeon] =
	{
		"PublicEventStats_Name",
		"PublicEventStats_Contribution",
		"PublicEventStats_DamageDone",
		"PublicEventStats_DamageTaken",
		"PublicEventStats_HealingDone",
		"PublicEventStats_HealingTaken"
	},
}

local ktAdventureListStrIndexToIconSprite =  -- Default: ClientSprites:Icon_SkillMind_UI_espr_moverb
{
	["nKills"] 		= "ClientSprites:Icon_SkillMisc_UI_ss_srsht",
	["nDeaths"] 	= "ClientSprites:Icon_ShieldSlice",
	["nDamage"] 	= "ClientSprites:Icon_ItemWeaponSword_UI_Item_Greatsword_001",
	["nHealed"] 	= "ClientSprites:Icon_Recover",
}

local ktRewardTierInfo =
{
	[PublicEvent.PublicEventRewardTier_None] 	= {Apollo.GetString("PublicEventStats_NoMedal"), 		""},
	[PublicEvent.PublicEventRewardTier_Bronze] 	= {Apollo.GetString("PublicEventStats_BronzeMedal"), 	"CRB_CurrencySprites:sprCashCopper"},
	[PublicEvent.PublicEventRewardTier_Silver] 	= {Apollo.GetString("PublicEventStats_SilverMedal"), 	"CRB_CurrencySprites:sprCashSilver"},
	[PublicEvent.PublicEventRewardTier_Gold] 	= {Apollo.GetString("PublicEventStats_GoldMedal"), 		"CRB_CurrencySprites:sprCashGold"},
}

function PvP_PublicEventStats:OnLoad()
    Apollo.RegisterEventHandler("GenericEvent_OpenEventStats", 			"Initialize", self)
    Apollo.RegisterEventHandler("GenericEvent_OpenEventStatsZombie", 	"InitializeZombie", self)
	Apollo.RegisterEventHandler("ResolutionChanged", 					"OnResolutionChanged", self)
	Apollo.RegisterEventHandler("WarPartyMatchResults", 				"OnWarPartyMatchResults", self)
	Apollo.RegisterEventHandler("PVPMatchFinished", 					"OnPVPMatchFinished", self)
	Apollo.RegisterEventHandler("PublicEventEnd", 						"OnPublicEventEnd", self)
	Apollo.RegisterEventHandler("ChangeWorld", 							"OnClose", self)
	Apollo.RegisterEventHandler("GuildWarCoinsChanged",					"OnGuildWarCoinsChanged", self)

	Apollo.RegisterTimerHandler("UpdateTimer", 							"OnOneSecTimer", self)
	Apollo.CreateTimer("UpdateTimer", 1, true)
	Apollo.StopTimer("UpdateTimer")

	self.wndMain = nil
	self.wndAdventure = nil
end

function PvP_PublicEventStats:OnResolutionChanged()
	self.bResolutionChanged = true -- Delay so we can get the new value
end

function PvP_PublicEventStats:OnPublicEventEnd(peEnding, eReason, tStats)
	if eReason == PublicEvent.PublicEventParticipantRemoveReason_LeftArea then
		Apollo.StopTimer("UpdateTimer")
		return -- Won't have stats
	end

	Apollo.StopTimer("UpdateTimer")
	self.bIsOver = true

	local eEventType = peEnding:GetEventType()

	if ktPvPEvents[eEventType] then
		self:OnClose() -- Destroy self.wndMain
		self:Initialize(peEnding, tStats.arPersonalStats, tStats.arTeamStats, tStats.arParticipantStats)
		self.tZombieStats = tStats -- After Initialize (initialize will wipe zombie stats)
	elseif eEventType == PublicEvent.PublicEventType_SubEvent or eEventType == PublicEvent.PublicEventType_WorldEvent then
		-- TODO; currently handled from Quest Tracker toggle
	else -- Adventures
		self:OnClose() -- Destroy self.wndMain
		self.tZombieStats = tStats -- Needs to be before BuildAdventuresSummary
		self:BuildAdventuresSummary(self:HelperBuildCombinedList(tStats.arPersonalStats, tStats.arTeamStats, tStats.arParticipantStats), peEnding)
	end
end

function PvP_PublicEventStats:InitializeZombie(tZombieEvent)
	self:Initialize(tZombieEvent.peEvent, tZombieEvent.tStats, tZombieEvent.tStats.arTeamStats, tZombieEvent.tStats.arParticipantStats)
	self.tZombieStats = tZombieEvent.tStats -- After Initialize (initialize will wipe zombie stats)

	Apollo.StartTimer("UpdateTimer")
end

function PvP_PublicEventStats:Initialize(peEvent, tStatsSelf, tStatsTeam, tStatsParticipants)
	if not self.wndMain or not self.wndMain:IsValid() then
		self.wndMain = Apollo.LoadForm("PvP_PublicEventStats.xml", "PvP_PublicEventStatsForm", nil, self)
	end

	local eEventType = peEvent:GetEventType()
	local wndParent = self.wndMain:FindChild(ktEventTypeToWindowName[eEventType])
	local wndGrid = wndParent

	if wndGrid:GetName() ~= "PublicEventGrid" then
		wndGrid = wndParent:FindChild("PvPTeamGridBot")

		for idx = 1, wndGrid:GetColumnCount() do
			wndGrid:SetColumnText(idx, Apollo.GetString(ktEventTypeToColumnNameList[eEventType][idx]))
		end

		wndGrid = wndParent:FindChild("PvPTeamGridTop")
	end

	for idx = 1, wndGrid:GetColumnCount() do
		wndGrid:SetColumnText(idx, Apollo.GetString(ktEventTypeToColumnNameList[eEventType][idx]))
	end

	self.wndMain:SetData({peEvent, tStatsSelf or {}, tStatsTeam or {}, tStatsParticipants or {}})
	self.wndMain:SetSizingMinimum(500, 500)
	self.wndMain:SetSizingMaximum(knMaxWndMainWidth, 800)
	self.wndMain:Show(true)
	self.tZombieStats = nil

	if not self.bIsOver == true then
		Apollo.StartTimer("UpdateTimer")
	else
		self:OnOneSecTimer()
	end
end

-----------------------------------------------------------------------------------------------
-- Main Draw Method
-----------------------------------------------------------------------------------------------

function PvP_PublicEventStats:OnOneSecTimer()
	if not self.wndMain or not self.wndMain:IsValid() or not self.wndMain:IsShown() then
		Apollo.StopTimer("UpdateTimer")
		return
	end

	local peCurrent = self.wndMain:GetData()[1]
	local tLiveStats = peCurrent:GetLiveStats()
	local eEventType = peCurrent:GetEventType()
	if tLiveStats and peCurrent:IsActive() then
		self.wndMain:SetData({peCurrent, peCurrent:GetMyStats(), tLiveStats.arTeamStats, tLiveStats.arParticipantStats})
		self:Redraw()
	elseif self.tZombieStats and ktPvPEvents[eEventType] or eEventType == PublicEvent.PublicEventType_WorldEvent then
		self:Redraw()
	end

	if self.bResolutionChanged then
		self.bResolutionChanged = false
		local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
		if Apollo.GetDisplaySize().nWidth <= 1400 then
			self.wndMain:SetAnchorOffsets(nLeft, nTop, nLeft + 750, nBottom)
		else
			self.wndMain:SetAnchorOffsets(nLeft, nTop, nLeft + 950, nBottom)
		end
	end
end

function PvP_PublicEventStats:Redraw() -- self.wndMain guaranteed valid and visible
	local peCurrent = self.wndMain:GetData()[1]
	local tStatsSelf = self.wndMain:GetData()[2]
	local tStatsTeam = self.wndMain:GetData()[3]
	local tStatsParticipants = self.wndMain:GetData()[4]
	local tMegaList = self:HelperBuildCombinedList(tStatsSelf, tStatsTeam, tStatsParticipants)

	for key, wndCurr in pairs(self.wndMain:FindChild("MainGridContainer"):GetChildren()) do
		wndCurr:Show(false)
	end

	local eEventType = peCurrent:GetEventType()
	local wndGrid = self.wndMain:FindChild(ktEventTypeToWindowName[eEventType])

	if eEventType == PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine then
		self:HelperBuildPvPSharedGrids(wndGrid, tMegaList, "HoldTheLine")
	elseif eEventType == PublicEvent.PublicEventType_PVP_Battleground_Vortex then
		self:HelperBuildPvPSharedGrids(wndGrid, tMegaList, "CTF")
	elseif eEventType == PublicEvent.PublicEventType_PVP_Warplot then
		self:HelperBuildPvPSharedGrids(wndGrid, tMegaList, "WarPlot")
	elseif eEventType == PublicEvent.PublicEventType_PVP_Arena then
		self:HelperBuildPvPSharedGrids(wndGrid, tMegaList, "Arena")
	elseif eEventType == PublicEvent.PublicEventType_PVP_Battleground_Sabotage then
		self:HelperBuildPvPSharedGrids(wndGrid, tMegaList, "Sabotage")
	elseif eEventType == PublicEvent.PublicEventType_WorldEvent then
		self:BuildPublicEventGrid(wndGrid, tMegaList) -- TODO (polish)
	elseif eEventType == PublicEvent.PublicEventType_Dungeon then
		self:BuildPublicEventGrid(wndGrid, tMegaList) -- TODO
	end

	-- Title Text (including timer)
	local strTitleText = ""
	if peCurrent:IsActive() and peCurrent:GetElapsedTime() then
		strTitleText = String_GetWeaselString(Apollo.GetString("PublicEventStats_TimerHeader"), peCurrent:GetName(), self:HelperConvertTimeToString(peCurrent:GetElapsedTime()))
	elseif self.tZombieStats and self.tZombieStats.nElapsedTime then
		strTitleText = String_GetWeaselString(Apollo.GetString("PublicEventStats_FinishTime"), peCurrent:GetName(), self:HelperConvertTimeToString(self.tZombieStats.nElapsedTime))
	end
	self.wndMain:FindChild("EventTitleText"):SetText(strTitleText)

	-- Rewards (on zombie only)
	if not peCurrent:IsActive() and self.tZombieStats and self.tZombieStats.eRewardTier and
	peCurrent:GetEventType() == PublicEvent.PublicEventType_WorldEvent and self.tZombieStats.eRewardType ~= 0  then -- TODO: ENUM!!
		self.wndMain:FindChild("BGRewardTierFrame"):SetText(ktRewardTierInfo[self.tZombieStats.eRewardTier][1])
		self.wndMain:FindChild("BGRewardTierIcon"):SetSprite(ktRewardTierInfo[self.tZombieStats.eRewardTier][2])
	else
		self.wndMain:FindChild("BGRewardTierFrame"):SetText("")
	end

	if wndGrid then
		wndGrid:Show(true)
	end
end

-----------------------------------------------------------------------------------------------
-- Grid Building
-----------------------------------------------------------------------------------------------

function PvP_PublicEventStats:HelperBuildPvPSharedGrids(wndParent, tMegaList, eEventType)
	local wndGridTop 	= wndParent:FindChild("PvPTeamGridTop")
	local wndGridBot 	= wndParent:FindChild("PvPTeamGridBot")
	local wndHeaderTop 	= wndParent:FindChild("PvPTeamHeaderTop")
	local wndHeaderBot 	= wndParent:FindChild("PvPTeamHeaderBot")

	local nVScrollPosTop 	= wndGridTop:GetVScrollPos()
	local nVScrollPosBot 	= wndGridBot:GetVScrollPos()
	local nSortedColumnTop 	= wndGridTop:GetSortColumn() or 1
	local nSortedColumnBot 	= wndGridBot:GetSortColumn() or 1
	local bAscendingTop 	= wndGridTop:IsSortAscending()
	local bAscendingBot 	= wndGridBot:IsSortAscending()

	local tMatchState 	= MatchingGame:GetPVPMatchState()
	local strMyTeamName = ""

	for key, tCurr in pairs(tMegaList.tStatsTeam) do
		local wndHeader = nil
		if not wndHeaderTop:GetData() or wndHeaderTop:GetData() == tCurr.strTeamName then
			wndHeader = wndHeaderTop
			wndGridTop:SetData(tCurr.strTeamName)
			wndHeaderTop:SetData(tCurr.strTeamName)
		elseif not wndHeaderBot:GetData() or wndHeaderBot:GetData() == tCurr.strTeamName then
			wndHeader = wndHeaderBot
			wndGridBot:SetData(tCurr.strTeamName)
			wndHeaderBot:SetData(tCurr.strTeamName)
		end

		local strHeaderText = wndHeader:FindChild("PvPHeaderText"):GetData() or ""
		local crTitleColor = ApolloColor.new("ff7fffb9")
		local strDamage	= String_GetWeaselString(Apollo.GetString("PublicEventStats_Damage"), self:HelperFormatNumber(tCurr.nDamage))
		local strHealed	= String_GetWeaselString(Apollo.GetString("PublicEventStats_Healing"), self:HelperFormatNumber(tCurr.nHealed))

		if eEventType == "CTF" or eEventType == "HoldTheLine" or eEventType == "Sabotage" then
			if tCurr.strTeamName == "Exiles" then
				crTitleColor = ApolloColor.new("ff31fcf6")
			elseif tCurr.strTeamName == "Dominion" then
				crTitleColor = ApolloColor.new("ffb80000")
			end
			local strKDA = String_GetWeaselString(Apollo.GetString("PublicEventStats_KDA"), tCurr.nKills, tCurr.nDeaths, tCurr.nAssists)

			strHeaderText = String_GetWeaselString(Apollo.GetString("PublicEventStats_PvPHeader"), strKDA, strDamage, strHealed)
		elseif eEventType == "Arena" then
			strHeaderText = String_GetWeaselString(Apollo.GetString("PublicEventStats_ArenaHeader"), strDamage, strHealed) -- TODO, Rating Change when support is added
			if tCurr.bIsMyTeam then
				strMyTeamName = tCurr.strTeamName
			end
		elseif eEventType == "Warplot" then
			strHeaderText = wndHeader:FindChild("PvPHeaderText"):GetData() or ""
		end

		wndHeader:FindChild("PvPHeaderText"):SetText(strHeaderText)
		wndHeader:FindChild("PvPHeaderTitle"):SetTextColor(crTitleColor)
		wndHeader:FindChild("PvPHeaderTitle"):SetText(tCurr.strTeamName)
	end

	-- Special Arena Team renaming
	if tMatchState and eEventType == "Arena" and tMatchState.arTeams then
		local strMyArenaTeamName = ""
		local strOtherArenaTeamName = ""
		for idx, tCurr in pairs(tMatchState.arTeams) do
			local strDelta = ""
			if tCurr.fDelta < 0 then
				strDelta = String_GetWeaselString(Apollo.GetString("PublicEventStats_NegDelta"), math.abs(tCurr.fDelta))
			elseif tCurr.fDelta > 0 then
				strDelta = String_GetWeaselString(Apollo.GetString("PublicEventStats_PosDelta"), math.abs(tCurr.fDelta))
			end

			if tMatchState.eMyTeam == tCurr.eTeam then
				strMyArenaTeamName = String_GetWeaselString(Apollo.GetString("PublicEventStats_RatingChange"), tCurr.strName, tCurr.nRating, strDelta)
			else
				strOtherArenaTeamName = String_GetWeaselString(Apollo.GetString("PublicEventStats_RatingChange"), tCurr.strName, tCurr.nRating, strDelta)
			end
		end
		if wndHeaderTop:GetData() == strMyTeamName then
			wndHeaderTop:FindChild("PvPHeaderTitle"):SetText(strMyArenaTeamName)
			wndHeaderBot:FindChild("PvPHeaderTitle"):SetText(strOtherArenaTeamName)
		elseif wndHeaderBot:GetData() == strMyTeamName then
			wndHeaderTop:FindChild("PvPHeaderTitle"):SetText(strOtherArenaTeamName)
			wndHeaderBot:FindChild("PvPHeaderTitle"):SetText(strMyArenaTeamName)
		end
	end

	for key, tParticipant in pairs(tMegaList.tStatsParticipant) do
		local wndGrid = wndGridBot
		if wndGridTop:GetData() == tParticipant.strTeamName then
			wndGrid = wndGridTop
		end

		-- Custom Stats
		if eEventType == "HoldTheLine" then
			for idx, tCustomTable in pairs(tParticipant.arCustomStats) do
				if tCustomTable.strName == Apollo.GetString("PublicEventStats_SecondaryPointCaptured") then
					tParticipant.nCustomNodesCaptured = tCustomTable.nValue or 0
				end
			end
		elseif eEventType == "CTF" then
			for idx, tCustomTable in pairs(tParticipant.arCustomStats) do
				if idx == 1 then
					tParticipant.nCustomFlagsPlaced = tCustomTable.nValue or 0
				else
					tParticipant.bCustomFlagsStolen = tCustomTable.nValue or 0
				end
			end
		end

		--wndGrid:DeleteAll()
		local wndCurrRow = self:HelperGridFactoryProduce(wndGrid, tParticipant.strName) -- GOTCHA: This is an integer
		wndGrid:SetCellLuaData(wndCurrRow, 1, tParticipant.strName)

		for idx, strParticipantKey in pairs(ktParticipantKeys[eEventType]) do
			local value = tParticipant[strParticipantKey]
			if type(value) == "number" then
				wndGrid:SetCellSortText(wndCurrRow, idx, string.format("%8d", value))
			else
				wndGrid:SetCellSortText(wndCurrRow, idx, value or 0)
			end

			local strClassIcon = idx == 1 and kstrClassToMLIcon[tParticipant.eClass] or ""
			wndGrid:SetCellDoc(wndCurrRow, idx, string.format("<T Font=\"CRB_InterfaceMedium\">%s%s</T>", strClassIcon, self:HelperFormatNumber(value)))
		end
	end

	wndGridTop:SetVScrollPos(nVScrollPosTop)
	wndGridBot:SetVScrollPos(nVScrollPosBot)
	wndGridTop:SetSortColumn(nSortedColumnTop, bAscendingTop)
	wndGridBot:SetSortColumn(nSortedColumnBot, bAscendingBot)
	self.wndMain:FindChild("PvPLeaveMatchBtn"):Show(self.tZombieStats)
	self.wndMain:FindChild("PvPSurrenderMatchBtn"):Show(not self.tZombieStats and eEventType == "WarPlot")
end

function PvP_PublicEventStats:BuildPublicEventGrid(wndGrid, tMegaList)
	local nVScrollPos = wndGrid:GetVScrollPos()
	local nSortedColumn = wndGrid:GetSortColumn() or 1
	local bAscending = wndGrid:IsSortAscending()
	wndGrid:DeleteAll() -- TODO remove this for better performance eventually

	for strKey, tCurrTable in pairs(tMegaList) do
		for key, tCurr in pairs(tCurrTable) do
			local wndCurrRow = self:HelperGridFactoryProduce(wndGrid, tCurr.strName) -- GOTCHA: This is an integer
			wndGrid:SetCellLuaData(wndCurrRow, 1, tCurr.strName)

			local tAttributes = {tCurr.strName, tCurr.nContributions, tCurr.nDamage, tCurr.nDamageReceived, tCurr.nHealed, tCurr.nHealingReceived}
			for idx, oValue in pairs(tAttributes) do
				if type(value) == "number" then
					wndGrid:SetCellSortText(wndCurrRow, idx, string.format("%8d", oValue))
				else
					wndGrid:SetCellSortText(wndCurrRow, idx, oValue)
				end
				wndGrid:SetCellDoc(wndCurrRow, idx, "<T Font=\"CRB_InterfaceMedium\">" .. self:HelperFormatNumber(oValue) .. "</T>")
			end
		end
	end

	wndGrid:SetVScrollPos(nVScrollPos)
	wndGrid:SetSortColumn(nSortedColumn, bAscending)
	self.wndMain:FindChild("PvPLeaveMatchBtn"):Show(false)
	self.wndMain:FindChild("PvPSurrenderMatchBtn"):Show(false)
end

-----------------------------------------------------------------------------------------------
-- Event Finished
-----------------------------------------------------------------------------------------------

function PvP_PublicEventStats:OnWarPartyMatchResults(tWarplotResults)
	if self.wndMain and self.wndMain:IsValid() then
		for idx, tTeamStats in pairs(tWarplotResults or {}) do
			local strStats = String_GetWeaselString(Apollo.GetString("PEStats_WarPartyTeamStats"), tTeamStats.nRating, tTeamStats.nDestroyedPlugs, tTeamStats.nRepairCost, tTeamStats.nWarCoinsEarned)
			self.wndMain:FindChild("PvPWarPlotContainer"):FindChild(idx == 1 and "PvPTeamHeaderTop" or "PvPTeamHeaderBot"):FindChild("PvPHeaderText"):SetData(strStats)
		end
	end
end

function PvP_PublicEventStats:OnPVPMatchFinished(eWinner, eReason)
	if not self.wndMain or not self.wndMain:IsValid() or not self.wndMain:IsShown() then
		return
	end

	local peMatch = self.wndMain:GetData()[1]
	local eEventType = peMatch:GetEventType()
	if not ktPvPEvents[eEventType] or eEventType == PublicEvent.PublicEventType_PVP_Arena or eEventType == PublicEvent.PublicEventType_PVP_Warplot then
		return
	end

	local tMatchState = MatchingGame:GetPVPMatchState()
	local eMyTeam = nil
	if tMatchState then
		eMyTeam = tMatchState.eMyTeam
	end

	local strMessage = Apollo.GetString("PublicEventStats_MatchEnd")
	local strColor = ApolloColor.new("ff7fffb9")
	local bIsExile = GameLib.GetPlayerUnit():GetFaction() == 391 -- TODO SUPER HARDCODED, need enum
	if eWinner == MatchingGame.Winner.Draw then
		strColor = ApolloColor.new("ff9aaea3")
		strMessage = Apollo.GetString("PublicEventStats_Draw")
	elseif eMyTeam == eWinner and bIsExile then
		strColor = ApolloColor.new("ff31fcf6")
		strMessage = Apollo.GetString("PublicEventStats_ExileWins")
	elseif eMyTeam == eWinner and not bIsExile then
		strColor = ApolloColor.new("ffb80000")
		strMessage = Apollo.GetString("PublicEventStats_DominionWins")
	elseif eMyTeam ~= eWinner and bIsExile then
		strColor = ApolloColor.new("ffb80000")
		strMessage = Apollo.GetString("PublicEventStats_ExileLoses")
	elseif eMyTeam ~= eWinner and not bIsExile then
		strColor = ApolloColor.new("ff31fcf6")
		strMessage = Apollo.GetString("PublicEventStats_DominionLoses")
	end
	self.wndMain:FindChild("BGPvPWinnerTopBar"):Show(true) -- Hidden when wndMain is destroyed from OnClose
	self.wndMain:FindChild("BGPvPWinnerTopBarArtText"):SetText(strMessage)
	self.wndMain:FindChild("BGPvPWinnerTopBarArtText"):SetTextColor(strColor)
end

function PvP_PublicEventStats:OnGuildWarCoinsChanged(guildOwner, nAmountGained)
	if nAmountGained > 0 then
		local strResult = String_GetWeaselString(Apollo.GetString("PEStats_WarcoinsGained"), nAmountGained)
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Loot, strResult, "")
	end
end

-----------------------------------------------------------------------------------------------
-- Match Ending and Closing methods
-----------------------------------------------------------------------------------------------

function PvP_PublicEventStats:OnClose(wndHandler, wndControl) -- Also LeaveAdventureBtn, AdventureCloseBtn
	self.tZombieStats = nil
	if self.wndMain then
		self.wndMain:Destroy()
	end
	if self.wndAdventure then
		self.wndAdventure:Destroy()
	end
end

function PvP_PublicEventStats:OnPvPLeaveMatchBtn(wndHandler, wndControl)
	if MatchingGame.IsInMatchingGame() then
		MatchingGame.LeaveMatchingGame()
	end
end

function PvP_PublicEventStats:OnPvPSurrenderMatchBtn( wndHandler, wndControl, eMouseButton )
	if not MatchingGame.IsVoteSurrenderActive() then
		MatchingGame.InitiateVoteToSurrender()
	end
end

-----------------------------------------------------------------------------------------------
-- Adventures Summary
-----------------------------------------------------------------------------------------------

function PvP_PublicEventStats:BuildAdventuresSummary(tMegaList, peAdventure)
	self.wndAdventure = Apollo.LoadForm("PvP_PublicEventStats.xml", "AdventureEventStatsForm", nil, self)
	local wndCurr = self.wndAdventure
	local tSelf = tMegaList.tStatsSelf[1]
	local tScore = {["nKills"] = 0, ["nDamage"] = 0, ["nHealed"] = 0, ["nDeaths"] = 0}

	-- Add Custom to score tracker
	for idx, tTable in pairs(tSelf.arCustomStats) do
		if tTable.nValue and tTable.nValue > 0 then
			tScore[tTable.strName] = 0
			tSelf[tTable.strName] = tTable.nValue
		end
	end

	-- Count times beaten by other participants
	for strKey, tCurrTable in pairs(tMegaList) do
		for key, tCurr in pairs(tCurrTable) do
			if strKey == "StatsParticipant" then
				tScore = self:HelperCompareAdventureScores(tSelf, tCurr, tScore)
			end
		end
	end

	-- Convert to an interim table for sorting
	local tSortedTable = self:HelperSortTableForAdventuresSummary(tScore)
	wndCurr:FindChild("AwardsContainer"):DestroyChildren()
	for key, tData in pairs(tSortedTable) do
		local strIndex = tData.strKey
		local nValue = tData.nValue
		if #wndCurr:FindChild("AwardsContainer"):GetChildren() < 3 then
			local nValueForString = math.abs(0 - nValue) + 1
			local wndListItem = Apollo.LoadForm("PvP_PublicEventStats.xml", "AdventureListItem", wndCurr:FindChild("AwardsContainer"), self)
			local strDisplayText = ""
			if strIndex == "nDeaths" then
				wndListItem:FindChild("AdventureListTitle"):SetText(String_GetWeaselString(Apollo.GetString("PublicEventStats_AwardLiving"), nValueForString))
				strDisplayText = "Deaths"
			elseif strIndex == "nHealed" then
				wndListItem:FindChild("AdventureListTitle"):SetText(String_GetWeaselString(Apollo.GetString("PublicEventStats_AwardOther"), nValueForString, Apollo.GetString("PublicEventStats_Heals")))
				strDisplayText = "Healed"
			else
				wndListItem:FindChild("AdventureListTitle"):SetText(String_GetWeaselString(Apollo.GetString("PublicEventStats_AwardOther"), nValueForString, strIndex))
			end
			wndListItem:FindChild("AdventureListDetails"):SetText((tSelf[strIndex] or 0) .. " " .. strDisplayText)
			wndListItem:FindChild("AdventureListIcon"):SetSprite(ktAdventureListStrIndexToIconSprite[strIndex] or "Icon_SkillMind_UI_espr_moverb") -- TODO hardcoded formatting
		end
	end
	wndCurr:FindChild("AwardsContainer"):ArrangeChildrenVert(0)

	-- Reward Tier
	if self.tZombieStats and self.tZombieStats.eRewardTier and self.tZombieStats.eRewardType ~= 0 then -- TODO: ENUM!!
		wndCurr:FindChild("BGRewardTierFrame"):SetText(ktRewardTierInfo[self.tZombieStats.eRewardTier][1])
		wndCurr:FindChild("BGRewardTierIcon"):SetSprite(ktRewardTierInfo[self.tZombieStats.eRewardTier][2])
	else
		wndCurr:FindChild("BGRewardTierFrame"):SetText("")
	end

	if self.tZombieStats then
		local strTime = String_GetWeaselString(Apollo.GetString("CRB_ProgressSimple"), self:HelperConvertTimeToString(self.tZombieStats.nElapsedTime))
		wndCurr:FindChild("BGTop"):SetText(String_GetWeaselString(Apollo.GetString("PublicEventStats_PlayerStats"), peAdventure:GetName()) .. strTime)
	else
		wndCurr:FindChild("BGTop"):SetText(String_GetWeaselString(Apollo.GetString("PublicEventStats_PlayerStats"), peAdventure:GetName()))
	end
end

function PvP_PublicEventStats:HelperCompareAdventureScores(tSelf, tCurr, tScore)
	if tCurr.nKills > tSelf.nKills then
		tScore.nKills = tScore.nKills + 1
	end
	if tCurr.nDeaths < tSelf.nDeaths then
		tScore.nDeaths = tScore.nDeaths + 1
	end
	if tCurr.nDamage > tSelf.nDamage then
		tScore.nDamage = tScore.nDamage + 1
	end
	if tCurr.nHealed > tSelf.nHealed then
		tScore.nHealed = tScore.nHealed + 1
	end

	for nStatsIdx, tTable in pairs(tCurr.arCustomStats) do
		for nStatsSelfIdx, tSelfTable in pairs(tSelf.arCustomStats) do
			local bValid = (nStatsIdx == nStatsSelfIdx) and (tTable.nValue> tSelfTable.nValue)
			if bValid then
				if not tScore[tTable.strName] then
					tScore[tTable.strName] = 0
				end
				tScore[tTable.strName] = tScore[tTable.strName] + 1
			end
		end
	end

	return tScore
end

-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function PvP_PublicEventStats:HelperBuildCombinedList(tStatsSelf, tStatsTeam, tStatsParticipants)
	local tMegaList = {}
	tMegaList.tStatsSelf = {tStatsSelf}

	if tStatsTeam then
		for key, tCurr in pairs(tStatsTeam) do
			if not tMegaList.tStatsTeam then
				tMegaList.tStatsTeam = {}
			end
			table.insert(tMegaList.tStatsTeam, tCurr)
		end
	end

	if tStatsParticipants then
		for key, tCurr in pairs(tStatsParticipants) do
			if not tMegaList.tStatsParticipant then
				tMegaList.tStatsParticipant = {}
			end
			table.insert(tMegaList.tStatsParticipant, tCurr)
		end
	end
	return tMegaList
end

function PvP_PublicEventStats:HelperFormatNumber(nArg)
	if tonumber(nArg) and tonumber(nArg) > 10000 then
		nArg = String_GetWeaselString(Apollo.GetString("PublicEventStats_Thousands"), math.floor(nArg/1000))
	else
		nArg = tostring(nArg)
	end
	return nArg
	-- TODO: Consider trimming huge numbers into a more readable format
end

function PvP_PublicEventStats:HelperSortTableForAdventuresSummary(tScore)
	local tNewTable = {}
	for key, nValue in pairs(tScore) do
		table.insert(tNewTable, {strKey = key, nValue = nValue})
	end
	table.sort(tNewTable, function(a,b) return a.value < b.value end)
	return tNewTable
end

function PvP_PublicEventStats:HelperConvertTimeToString(fTime)
	fTime = math.floor(fTime / 1000) -- TODO convert to full seconds

	return string.format("%d:%02d", math.floor(fTime / 60), math.floor(fTime % 60))
end

function PvP_PublicEventStats:HelperGridFactoryProduce(wndGrid, tTargetComparison)
	for nRow = 1, wndGrid:GetRowCount() do
		if wndGrid:GetCellLuaData(nRow, 1) == tTargetComparison then -- GetCellLuaData args are row, col
			return nRow
		end
	end

	return wndGrid:AddRow("") -- GOTCHA: This is a row number
end

local PvP_PublicEventStatsInst = PvP_PublicEventStats:new()
PvP_PublicEventStatsInst:Init()
