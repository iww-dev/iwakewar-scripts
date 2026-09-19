local st = game.ReplicatedStorage.Shared.States
local t0 = os.clock()
while os.clock() - t0 < 90 do
  if st.RoundState.Value == "RoundInProgress" then
    task.wait(3)
    local obj = workspace:FindFirstChild("RoundMap")
    obj = obj and obj:FindFirstChild("Objectives")
    local names = {}
    if obj then
      for _, o in ipairs(obj:GetChildren()) do table.insert(names, o.Name) end
    end
    return "LIVE objectives: " .. table.concat(names, ",")
  end
  task.wait(2)
end
return "timeout waiting round"