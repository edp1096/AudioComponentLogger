print("[AudioComponentLogger] Loaded\n")

-- local is_debug = false
local is_debug = true

local polling_interval = 120 -- in milliseconds
local fname_log = "AudioComponentLogger.log"
local ymdFormat = "%Y-%m-%d %H:%M:%S"

local actor = nil


if io.open(fname_log, "r") then os.remove(fname_log) end
local fw = io.open(fname_log, "w")
if fw then
    fw:write("Start AudioComponentLogger: " .. os.date(ymdFormat) .. "\n")
    fw:close()
end

local function dprint(msg)
    local full_msg = "[AudioComponentLogger] " .. msg .. "\n"
    if is_debug then print(full_msg) end
    fw = io.open(fname_log, "a")
    if fw then
        fw:write(full_msg)
        fw:close()
    end
end

local function bprint(msg)
    local full_msg = "[AudioComponentLogger] " .. msg
    if actor and actor:IsValid() then
        actor:AppendLogToScreen(full_msg)
    end
end

function GetMapName()
    local map_name = "Unknown Map"

    local eve = FindFirstOf("CH_P_EVE_01_Blueprint_C")
    if eve and eve:IsValid() then
        map_name = eve:GetFullName()
    end

    return map_name
end

NotifyOnNewObject("/Script/Engine.AudioComponent", function(ctx)
    if not ctx.Sound then return end

    local cname = ctx:GetFullName()
    if not string.find(cname, ":AudioComponent_") then return end

    local is_playing = false

    LoopAsync(polling_interval, function()
        if not ctx or not ctx:IsValid() then return true end

        if ctx:IsPlaying() then
            if ctx:IsPlaying() ~= is_playing then
                local sound_cue = ctx.Sound
                local sound_cue_name = sound_cue and sound_cue:GetClass():GetFullName() and sound_cue:GetFullName() or
                    "Unknown Cue"
                local first_node = sound_cue.FirstNode
                local sound_wave = first_node and first_node.SoundWave or nil
                local sound_wave_name = sound_wave and sound_wave:GetFullName() or "Unknown SoundWave"
                if sound_wave_name ~= "Unknown SoundWave" then
                    -- Single SoundWave
                    dprint("SoundWave: " .. sound_wave_name)
                    bprint("SoundWave: " .. sound_wave_name)
                else
                    -- Multiple SoundWaves or VendingMachine or SoundNodeSwitch or Mixer or others
                    dprint("Wav/Cue: " .. sound_cue_name)
                    if first_node:GetFullName() then
                        dprint("Node name: " .. tostring(first_node:GetFullName()))
                        bprint("Node name: " .. tostring(first_node:GetFullName()))
                    end
                end
                is_playing = ctx:IsPlaying()
            end
        else
            if ctx:IsPlaying() ~= is_playing then
                -- dprint("Stop: " .. cname .. " / " .. tostring(ctx:IsPlaying()))
                is_playing = ctx:IsPlaying()
            end
        end

        return false
    end)
end)

-- Simple player restart with level info
RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
    actor = nil
    dprint("PlayerController:ClientRestart: " .. os.date(ymdFormat))
    dprint("Current Map: " .. GetMapName())
end)

function SetupMod(modActor)
    actor = modActor:get()
    dprint("AudioComponentLogger_Setup: Mod actor is set")

    if not actor or not actor:IsValid() then
        dprint("AudioComponentLogger_Setup: Invalid modActor")
        return
    end

    bprint("AudioComponentLogger connected")
end

RegisterCustomEvent("AudioComponentLogger_Setup", SetupMod)
