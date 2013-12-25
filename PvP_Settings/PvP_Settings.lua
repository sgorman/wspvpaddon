-----------------------------------------------------------------------------------------------
-- Client Lua Script for PvP_Settings
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PvP_Settings Module Definition
-----------------------------------------------------------------------------------------------
local PvP_Settings = {} 

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
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
    --Apollo.RegisterSlashCommand("pvpsettingstest", "OnPvP_SettingsOn", self)    
	--Apollo.RegisterSlashCommand("pvpsettingstest2", "OnPvP_SettingsOn2", self)
	--PvP_Settings:RegisterModule("pvpsettings")
	Print("type: " .. type(self.pvpSettings))
	PvP_Settings:Set("Settings", "Debug", true)
	
	--self.debugMode = PvP_Settings:Get("Settings", "Debug")
	--if (self.debugMode == true) then
	--	Print("PvP_Settings Debug is Enabled")
	--end

	

		--Print(self.pvpSettings['pvpsettingstest']) --PvP_Settings:GetSetting("pvpsettings","test"))
end


function PvP_Settings:Get( module, setting )
		
	if (type(self.pvpSettings) ~= 'table') then
		self.pvpSettings = {}
	end
	if (type(self.pvpSettings[module]) ~= 'table') then
		self.pvpSettings[module] = {}
	end
	
	if (self.pvpSettings[module][setting] ~= nil) then
		return self.pvpSettings[module][setting]
	end
	
	return nil
end

function PvP_Settings:Set( module, setting, value )
	if (type(self.pvpSettings) ~= 'table') then
		self.pvpSettings = {}
	end	

	if (type(self.pvpSettings[module]) ~= 'table') then
		self.pvpSettings[module] = {}
	end
	
	self.pvpSettings[module][setting] = value
	
	return value
end

-----------------------------------------------------------------------------------------------
-- PvP_Settings Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

function PvP_Settings:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return nil end
    -- create a table to hold our data
   -- local tSave = {}
   -- for k,tItem in pairs(self.pvpSettings) do
        -- for each player in our list, create a table using the name as our key
    --    tSave[k] = {}
		
	--	tSave[k] = tItem
        -- save a table version of the color

	--	for y,tSetting in pairs(tItem) do
    --   	tSave[k][y] = tSetting:ToTable()
	--	end
    --end
	--tSave['testing'] = 'test'
    -- simply return this value and Apollo will save the file!
    return { "test" }-- self.pvpSettings:ToTable()
end

function PvP_Settings:OnRestore(eLevel, tData)
    -- just store this and use it later
    self.pvpSettings = tData
end

--------------------------------------------------------------------------------
-- PvP_Settings Instance
-----------------------------------------------------------------------------------------------
local PvP_SettingsInst = PvP_Settings:new()
PvP_SettingsInst:Init()
