--[[
    Rayfield Ultimate - Loadstring Entry Point
    This is what you run in your executor:
    
    loadstring(game:HttpGet("https://gitlab.com/justsadnyx/Rayfield-Ultimate/-/raw/main/loadstring.lua"))()
    
    It fetches the latest version from the repo automatically.
    Remote updates are handled by the library itself.
--]]

local REPO_URL = "https://gitlab.com/justsadnyx/Rayfield-Ultimate"
local RAW_URL = REPO_URL .. "/-/raw/main"
local LIBRARY_FILE = "source.lua"

local success, err = pcall(function()
    local source = game:HttpGet(RAW_URL .. "/" .. LIBRARY_FILE)
    if not source or source == "" then
        error("Failed to fetch Rayfield Ultimate source")
    end
    return loadstring(source)()
end)

if not success then
    warn("[Rayfield Ultimate] Load failed: " .. tostring(err))
    warn("[Rayfield Ultimate] Falling back to local cache...")
    
    pcall(function()
        local cached = readfile("RayfieldU_CachedLib.lua")
        if cached then
            loadstring(cached)()
        else
            error("No cached version available. Please check your connection.")
        end
    end)
end
