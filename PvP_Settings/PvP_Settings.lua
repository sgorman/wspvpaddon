-----------------------------------------------------------------------------------------------
-- Client Lua Script for PvP_Settings
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PvP_Settings Module Definition
-----------------------------------------------------------------------------------------------
local PvP_Settings = {} 
local GeminiInterfaceLib = nil
local Settings = {}
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PvP_Settings:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	
	self.pvpSettings = {}	
	
    return o
end

function PvP_Settings:Init()
    Apollo.RegisterAddon(self)
end
 

-----------------------------------------------------------------------------------------------
-- PvP_Settings OnLoad
-----------------------------------------------------------------------------------------------
function PvP_Settings:OnLoad()
    -- Register handlers for events, slash commands and timer, etc.
    Apollo.RegisterSlashCommand("settingstest", "OnPvP_SettingsOn", self)    
end

function PvP_Settings:OnPvP_SettingsOn()
--	GeminiInterfaceLib.AddLine("Hello")
PvP_Settings:Set("Settings", "Debug", true)
PvP_Settings:Set("Settings", "Hello", "Hello")
PvP_Settings:Set("Settings", "Table", { "TableData1", "TableData2", { "SubTable1", "SubTable2" } })

end

function PvP_Settings:Get( module, setting )
		
	if (type(Settings) ~= 'table') then
		Settings = {}
	end
	if (type(Settings[module]) ~= 'table') then
		Settings[module] = {}
	end
	
	if (Settings[module][setting] ~= nil) then
		return Settings[module][setting]
	end
	
	return nil
end

function PvP_Settings:Set( module, setting, value )
	if (type(Settings) ~= 'table') then
		Settings = {}
	end	

	if (type(Settings[module]) ~= 'table') then
		Settings[module] = {}
	end
	
	Settings[module][setting] = value
	
	local tSave = {}
	for k,tItem in pairs(Settings) do
        -- for each player in our list, create a table using the name as our key
        tSave[k] = {}
		--GeminiInterfaceLib.AddLine("Hello")
				--tSave[k] = tItem
        -- save a table version of the color
		Print(k)
		if (type(tItem) == 'table') then
			for y,tSetting in pairs(tItem) do
				Print(y .. " " .. type(tSetting))
	      	 	tSave[k][y] = tSetting
			end
		else
			tSave[k] = tItem
		end
    end

	return value
end

-----------------------------------------------------------------------------------------------
-- PvP_Settings Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

function PvP_Settings:OnSave(eLevel)
	--if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return nil end
    -- create a table to hold our data
	local tSave = {}
	for k,tItem in pairs(Settings) do
        -- for each player in our list, create a table using the name as our key
        tSave[k] = {}
        -- save a table version of the color
		if (type(tItem) == 'table') then
			for y,tSetting in pairs(tItem) do
	      	 	tSave[k][y] = tSetting
			end
		else
			tSave[k] = tItem
		end
    end
    -- simply return this value and Apollo will save the file!
    return tSave-- self.pvpSettings:ToTable()
end

function PvP_Settings:OnRestore(eLevel, tData)
    -- just store this and use it later
    Settings = tData
end

--------------------------------------------------------------------------------
-- PvP_Settings Instance
-----------------------------------------------------------------------------------------------
local PvP_SettingsInst = PvP_Settings:new()
PvP_SettingsInst:Init()
