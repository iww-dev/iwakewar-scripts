-- iwakewar-scripts | main loader
-- Load and run the right game script by checking the game universe/place id.
-- Paste this into any executor:
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/main.luau"))()

local BASE = "https://raw.githubusercontent.com/iww-dev/iwakewar-scripts/refs/heads/main/"

local SCRIPTS = {
    -- [{ {gameId, placeId}, "file.luau" }]
    bfnfr = {
        { "2443177453", "6520999642" },
        "BFNFR Auto-Play.luau",
    },
}

local function escapeUrl(path: string): string
    return (path:gsub(" ", "%%20"))
end

local function fetch(url: string): string?
    local src = nil
    if typeof(game.HttpGet) == "function" then
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and typeof(res) == "string" then
            src = res
        end
    end
    if not src then
        local ok, res = pcall(function()
            return game:GetService("HttpService"):GetAsync(url)
        end)
        if ok and typeof(res) == "string" then
            src = res
        end
    end
    return src
end

local function run(src: string, name: string)
    if not loadstring then
        warn("[iwakewar-scripts] no loadstring on this executor")
        return
    end
    local fn, err = loadstring(src)
    if not fn then
        warn("[iwakewar-scripts] compile error in " .. name .. ": " .. tostring(err))
        return
    end
    local ok, rerr = pcall(fn)
    if not ok then
        warn("[iwakewar-scripts] runtime error in " .. name .. ": " .. tostring(rerr))
    end
end

local curGame = tostring(game.GameId or "")
local curPlace = tostring(game.PlaceId or "")

for _, entry in pairs(SCRIPTS) do
    local ids = entry[1]
    local hit = false
    for _, id in ipairs(ids) do
        if id == curGame or id == curPlace then
            hit = true
        end
    end
    if hit then
        local fileName = entry[2]
        local url = BASE .. escapeUrl(fileName)
        print("[iwakewar-scripts] loading " .. fileName .. " (game " .. curGame .. " / place " .. curPlace .. ")")
        local src = fetch(url)
        if src then
            run(src, fileName)
        else
            warn("[iwakewar-scripts] could not fetch " .. url)
        end
        break
    end
end