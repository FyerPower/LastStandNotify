-----------------------------------------------------------------------------------------------
-- LastStandNotify
-- Slash Command: /lsn
-----------------------------------------------------------------------------------------------

require "Apollo"
require "GameLib"

-----------------------------------------------------------------------------------------------
-- Performance Boost: Redefine global functions locally
-----------------------------------------------------------------------------------------------

local Apollo = Apollo
local XmlDoc = XmlDoc
local GameLib = GameLib

-----------------------------------------------------------------------------------------------
-- Initalize Addon Object
-----------------------------------------------------------------------------------------------

local LastStandNotify = {}

local tSpellCooldown = {}
tSpellCooldown[GameLib.CodeEnumClass.Stalker] = 123
tSpellCooldown[GameLib.CodeEnumClass.Spellslinger] = 64

-----------------------------------------------------------------------------------------------
-- Constructor and Initialization
-----------------------------------------------------------------------------------------------

-- Create a new instance of our addon
function LastStandNotify:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

-- Initialize our addon
function LastStandNotify:Init()
  Apollo.RegisterAddon(self)
end

-- Once our addon is loaded
function LastStandNotify:OnLoad()
  Apollo.RegisterSlashCommand("lsn", "SlashCommand", self)
  self.xmlDoc = XmlDoc.CreateFromFile("LastStandNotify.xml")
  self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

-- Once our document has loaded (after the game is loaded)
function LastStandNotify:OnDocumentReady()
  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "LastStandNotify", nil, self)
    self.cooldownBar  = self.wndMain:FindChild("ProgressBar")
    self.cooldownTime = self.wndMain:FindChild("CastTime")

    self:SetDefaults()
    self:SetWindowPlacement()
    self.wndMain:Show(false)

    Apollo.RegisterEventHandler("CombatLogDelayDeath", "OnCombatLogDelayDeath", self)
  end
end

function LastStandNotify:SlashCommand()
  self:OnCombatLogDelayDeath({unitCaster = GameLib.GetPlayerUnit()})
end

-----------------------------------------------------------------------------------------------
-- Settings / Data Management
-----------------------------------------------------------------------------------------------

-- Save addon config per character. Called by engine when performing a controlled game shutdown.
function LastStandNotify:OnSave(eType)
  if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

  local settings = {}
  settings.left   = self.settings.left
  settings.top    = self.settings.top
  settings.height = self.settings.height
  settings.width  = self.settings.width

  return settings
end

-- Restore addon config per character. Called by engine when loading UI.
function LastStandNotify:OnRestore(eType, settings)
  if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

  self:SetDefaults()
  self.settings = mergeTables(self.settings, settings)
end

function LastStandNotify:SetDefaults()
  if self.settings ~= nil then return end
  self.settings = {}
  self.settings.left = 600
  self.settings.top = 100
  self.settings.height = 30
  self.settings.width = 300
end

-----------------------------------------------------------------------------------------------
-- Events
-----------------------------------------------------------------------------------------------

function LastStandNotify:OnCombatLogDelayDeath(tEventArgs)
  if tEventArgs.unitCaster and tEventArgs.unitCaster == GameLib.GetPlayerUnit() then
    self:Start()
  end
end

function LastStandNotify:OnProgressBarMove()
  self.settings.left, self.settings.top = self.wndMain:GetAnchorOffsets()
end

function LastStandNotify:OnProgressBarResize()
  self.settings.height = self.wndMain:GetHeight()
  self.settings.width = self.wndMain:GetWidth()
end

-----------------------------------------------------------------------------------------------
-- Functions
-----------------------------------------------------------------------------------------------

function LastStandNotify:SetWindowPlacement()
  self.wndMain:SetAnchorOffsets(self.settings.left, self.settings.top, (self.settings.left+self.settings.width), (self.settings.top+self.settings.height)) -- l, t, r, b
end

function LastStandNotify:Start()
  local nClassId = GameLib.GetPlayerUnit():GetClassId()

  -- If we dont track anything for this class, exit out
  if not tSpellCooldown[nClassId] then return; end

  self.time = GameLib.GetGameTime()
  self.cooldown = tSpellCooldown[nClassId]
  Sound.Play(211)
  self.wndMain:Show(true)

  -- Start Timer
  self.timer = ApolloTimer.Create(0.1, true, "Update", self)
  self.timer:Start()

  Print("Your last stand has been triggered.")
end

function LastStandNotify:Update()
  local elapsed = (GameLib.GetGameTime() - self.time)
  local remaining = self.cooldown - elapsed

  if remaining > 0 then
    self.cooldownBar:SetProgress(elapsed / self.cooldown)
    self.cooldownTime:SetText( string.format("%.1f", remaining) )
  else
    self:Stop()
  end
end

function LastStandNotify:Stop()
  Sound.Play(211)
  self.timer:Stop()
  self.wndMain:Show(false)

  Print("Your last stand is now available")
end

-----------------------------------------------------------------------------------------------
-- Addon Object Creation & Initialization
-----------------------------------------------------------------------------------------------

LastStandNotifyInstance = LastStandNotify:new()
LastStandNotifyInstance:Init()





local function mergeTables(t1, t2)
  for k, v in pairs(t2) do
    if type(v) == "table" then
    if t1[k] then
        if type(t1[k] or false) == "table" then
          mergeTables(t1[k] or {}, t2[k] or {})
        else
          t1[k] = v
        end
    else
      t1[k] = {}
        mergeTables(t1[k] or {}, t2[k] or {})
    end
    else
      t1[k] = v
    end
  end
  return t1
end