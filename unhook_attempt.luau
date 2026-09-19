local cur = shared.repfire
local out = {}
local ok1, e1 = pcall(restorefunction, cur)
out[#out+1] = "restore(shared.repfire): ok=" .. tostring(ok1) .. " err=" .. tostring(e1)
local check = getgenv().rfdumpCount
out[#out+1] = "rfdumpCount=" .. tostring(check)
return table.concat(out, "\n")