-- Project Echo Sandbox Loader 1.0.0  |  Project Zomboid B42 MP
-- Dedicated-server only. No modifications to game or Server/ files.
-- Canonical config: ProjectEchoSandboxLoader/42/SandboxPreset.lua

if not isServer or not isServer() then
    return
end

local MOD_ID = "ProjectEchoSandboxLoader"
local PRESET_FILE = "SandboxPreset.lua"
local TAG = "[ProjectEchoSandboxLoader] "

-- Keep the hook idempotent if Lua is reloaded from debug tools.
ProjectEchoSandboxLoader = ProjectEchoSandboxLoader or {}
local state = ProjectEchoSandboxLoader
if state.handlers then
    if state.handlers.started and Events.OnServerStarted then
        Events.OnServerStarted.Remove(state.handlers.started)
    end
    if state.handlers.check and Events.EveryTenMinutes then
        Events.EveryTenMinutes.Remove(state.handlers.check)
    end
    if state.handlers.saving and Events.OnServerStartSaving then
        Events.OnServerStartSaving.Remove(state.handlers.saving)
    end
end
state.handlers = {}

local function log(s)
    print(TAG .. tostring(s))
end

local function readPreset()
    local ok, result = pcall(function()
        -- getModFileReader reads relative to this mod's active 42/ directory.
        local reader = getModFileReader(MOD_ID, PRESET_FILE, false)
        if not reader then return nil end
        local lines = {}
        local success, err = pcall(function()
            while true do
                local line = reader:readLine()
                if line == nil then break end
                lines[#lines + 1] = line
            end
        end)
        reader:close()
        if not success then error(err) end
        return table.concat(lines, "\n")
    end)
    if not ok then
        log("ERROR reading " .. PRESET_FILE .. ": " .. tostring(result))
        return nil
    end
    if not result or #result == 0 then
        log("ERROR: preset not found or empty: 42/" .. PRESET_FILE)
        return nil
    end

    -- The user's original server file contains `SandboxVars = { ... }`.
    -- The local shadow keeps evaluation from replacing the live global table.
    local okCompile, chunk, compileErr = pcall(loadstring, "local SandboxVars\n" .. result .. "\nreturn SandboxVars")
    if not okCompile then
        log("ERROR compiling preset: " .. tostring(chunk))
        return nil
    end
    if not chunk then
        log("ERROR: invalid Lua preset: " .. tostring(compileErr))
        return nil
    end
    local okRun, values = pcall(chunk)
    if not okRun or type(values) ~= "table" then
        log("ERROR: preset must define a SandboxVars table: " .. tostring(values))
        return nil
    end
    return values
end

local function isEqual(actual, wanted)
    if actual == wanted then return true end
    if actual == nil or wanted == nil then return false end
    if type(wanted) == "number" then
        return tonumber(actual) == wanted
    end
    if type(wanted) == "boolean" then
        return tostring(actual):lower() == tostring(wanted)
    end
    return tostring(actual) == tostring(wanted)
end

local function getRegisteredOptions()
    if not getSandboxOptions then return nil end
    local ok, options = pcall(getSandboxOptions)
    if ok then return options end
    return nil
end

-- Values have to be written both to the shared Lua SandboxVars table AND
-- to Java SandboxOptions. Updating just one is insufficient in multiplayer.
local function applyPreset(phase)
    if not state.preset then
        state.preset = readPreset()
        if not state.preset then return end
        log("preset loaded from this mod (42/" .. PRESET_FILE .. ")")
    end

    if type(SandboxVars) ~= "table" then
        SandboxVars = {}
    end

    local options = getRegisteredOptions()
    local globalChanged = 0
    local javaChanged = 0
    local javaErrors = 0
    local examples = {}

    local function merge(current, wanted, prefix)
        for k, v in pairs(wanted) do
            if k ~= "VERSION" then
                if type(v) == "table" then
                    if type(current[k]) ~= "table" then
                        current[k] = {}
                        globalChanged = globalChanged + 1
                    end
                    local child = current[k]
                    local nextPrefix = prefix
                    if type(k) == "string" then
                        nextPrefix = (prefix == "" and k) or (prefix .. "." .. k)
                    end
                    merge(child, v, nextPrefix)
                else
                    local path = nil
                    if type(k) == "string" then
                        path = (prefix == "" and k) or (prefix .. "." .. k)
                    end
                    if not isEqual(current[k], v) then
                        current[k] = v
                        globalChanged = globalChanged + 1
                        if #examples < 5 and path then
                            examples[#examples + 1] = path
                        end
                    end
                    if path and options then
                        local okOption, option = pcall(function()
                            return options:getOptionByName(path)
                        end)
                        if okOption and option then
                            local okRead, actual = pcall(function()
                                return option:getValueAsObject()
                            end)
                            if not okRead or not isEqual(actual, v) then
                                local okSet, errSet = pcall(function()
                                    options:set(path, v)
                                end)
                                if okSet then
                                    javaChanged = javaChanged + 1
                                else
                                    javaErrors = javaErrors + 1
                                    if javaErrors <= 3 then
                                        log("WARN option " .. path .. ": " .. tostring(errSet))
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local ok, err = pcall(function() merge(SandboxVars, state.preset, "") end)
    if not ok then
        log("ERROR applying preset (" .. phase .. "): " .. tostring(err))
        return
    end

    if globalChanged > 0 or javaChanged > 0 or javaErrors > 0 or phase ~= "periodic" then
        log(phase .. ": Lua changed=" .. globalChanged ..
            ", Java options changed=" .. javaChanged ..
            ", errors=" .. javaErrors ..
            ", MultiHitZombies=" .. tostring(SandboxVars.MultiHitZombies))
        if globalChanged > 0 and #examples > 0 then
            log("restored: " .. table.concat(examples, ", "))
        end
    end
end

local function onStarted()
    -- Re-apply after the engine and other mods finish reading sandbox settings.
    applyPreset("OnServerStarted")
end
local function onCheck()
    -- Every ten in-game minutes; only writes values that drifted.
    applyPreset("periodic")
end
local function onSaving()
    -- Server saves can trigger other mods' config synchronization.
    applyPreset("before server save")
end

state.handlers.started = onStarted
state.handlers.check = onCheck
state.handlers.saving = onSaving

if Events.OnServerStarted then Events.OnServerStarted.Add(onStarted) end
if Events.EveryTenMinutes then Events.EveryTenMinutes.Add(onCheck) end
if Events.OnServerStartSaving then Events.OnServerStartSaving.Add(onSaving) end

-- Initial application as soon as this server-side Lua has loaded.
applyPreset("mod load")
