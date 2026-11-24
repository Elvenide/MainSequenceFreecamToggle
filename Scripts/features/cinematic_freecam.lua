-- Eqol Feature: Cinematic Freecam Toggle
-- Configurable keybind (default C) that toggles built-in Spectator Mode and Hide HUD simultaneously.

local Core = require("core")

local Feature = {
    Name        = "CinematicFreecam",
    DisplayName = "Cinematic Freecam",
    Description = "Hotkey (default C) to toggle Spectator Mode and hide HUD simultaneously.",
}

local FreecamActive = false
local ToggleSeq = 0

local function GetSpectatorModeState(pc)
    if not Core.IsValidObj(pc) then return nil end
    local ok, val = pcall(function()
        return pc.PlayerObject.SpectatorView.bSpectatorMode
    end)
    if ok and type(val) == "boolean" then
        return val
    end
    return nil
end

local function ToggleCinematicFreecam()
    if not Core.IsFeatureEnabled("CinematicFreecam") then return end
    local pc = Core.GetLocalPlayerController()
    if not Core.IsValidObj(pc) then return end

    ToggleSeq = ToggleSeq + 1
    local mySeq = ToggleSeq

    local okSpec = pcall(function() pc:ToggleSpectatorMode() end)
    if not okSpec then
        Core.Log("Cinematic Freecam: ToggleSpectatorMode unavailable")
        return
    end

    local isSpec = GetSpectatorModeState(pc)
    if isSpec == nil then
        isSpec = not FreecamActive
    end
    FreecamActive = isSpec

    pcall(function() pc:SetHUDHidden(isSpec) end)
    ExecuteInGameThreadWithDelay(50, function()
        if ToggleSeq ~= mySeq then return end
        if Core.IsValidObj(pc) then
            local updatedSpec = GetSpectatorModeState(pc)
            if updatedSpec ~= nil then
                FreecamActive = updatedSpec
                pcall(function() pc:SetHUDHidden(updatedSpec) end)
            else
                pcall(function() pc:SetHUDHidden(isSpec) end)
            end
        end
    end)

    Core.Log("Cinematic Freecam: " .. (isSpec and "ON" or "OFF"))
end

local function ResetFreecamState()
    ToggleSeq = ToggleSeq + 1
    if FreecamActive then
        local pc = Core.GetLocalPlayerController()
        if Core.IsValidObj(pc) then
            local isSpec = GetSpectatorModeState(pc)
            if isSpec == true then
                pcall(function() pc:ToggleSpectatorMode() end)
            end
            pcall(function() pc:SetHUDHidden(false) end)
        end
        FreecamActive = false
    end
end

function Feature.Init()
    Core.RegisterConfigurableKeybind({
        ConfigKey   = "CinematicFreecamKey",
        DefaultKey  = "C",
        MappingName = "Eqol_CinematicFreecam",
        Label       = "Cinematic Freecam",
        OnPress     = ToggleCinematicFreecam,
    })
end

function Feature.OnClientRestart()
    ResetFreecamState()
end

function Feature.OnToggle(enabled)
    if not enabled then
        ResetFreecamState()
    end
end

function Feature.OnMapLoad()
    ResetFreecamState()
end

return Feature
