local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local genv0 = getgenv and getgenv() or {}
genv0.__afGen = (genv0.__afGen or 0) + 1
local myGen = genv0.__afGen

local function noCollide(model)
    if not model then return 0 end
    local n = 0
    for _, v in ipairs(model:GetDescendants()) do
    if v:IsA("BasePart") and v.CanCollide then
    pcall(function() v.CanCollide = false end)
     n = n + 1
    end
    end
    return n
end

task.spawn(function()
    print("antifling")
    while genv0.__afGen == myGen do
        for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
        noCollide(p.Character)
        end
        end
        task.wait(0.2)
    end
    print("antifling")
end)
