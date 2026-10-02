local plr = game.Players.LocalPlayer
local mf = plr.PlayerGui:WaitForChild("Main"):WaitForChild("MatchFrame")

local function fmt(v)
	if v == nil then return "nil" end
	return tostring(v)
end

local function scanNotes(side)
	local out = {}
	local ks = mf:FindFirstChild("KeySync" .. side)
	if not ks then return { ["ks"] = "NO_KS" } end
	for i = 1, 4 do
		local arrow = ks:FindFirstChild("Arrow" .. i)
		if arrow then
			local notes = arrow:FindFirstChild("Notes")
			if notes then
				local kids = notes:GetChildren()
				local first = nil
				for _, n in ipairs(kids) do
					if n.ClassName == "ImageLabel" then
						first = { name = n.Name, T = fmt(n:GetAttribute("T")), HH = fmt(n:GetAttribute("HoldHead")), Ty = fmt(n:GetAttribute("Type")), Y = string.format("%.3f", n.Position.Y.Scale) }
						break
					end
				end
				out[i] = { count = #kids, first = first }
			end
		end
	end
	return out
end

local logs = 0
for frame = 1, 400 do
	if mf.Visible and mf:FindFirstChild("KeySync1") then
		local s1 = scanNotes(1)
		local s2 = scanNotes(2)
		local howMany = 0
		for i = 1, 4 do if s1[i] then howMany = howMany + s1[i].count end if s2[i] then howMany = howMany + s2[i].count end end
		if howMany > 0 and logs < 8 then
			logs = logs + 1
			print("SIDE_DUMP " .. logs)
			print("  S1 A1=" .. (s1[1] and s1[1].count or "?") .. " A2=" .. (s1[2] and s1[2].count or "?") .. " A3=" .. (s1[3] and s1[3].count or "?") .. " A4=" .. (s1[4] and s1[4].count or "?"))
			print("  S2 A1=" .. (s2[1] and s2[1].count or "?") .. " A2=" .. (s2[2] and s2[2].count or "?") .. " A3=" .. (s2[3] and s2[3].count or "?") .. " A4=" .. (s2[4] and s2[4].count or "?"))
			local f1 = s1[1] and s1[1].first
			local f2 = s2[1] and s2[1].first
			print("  S1f=" .. (f1 and ("name=" .. f1.name .. " T=" .. f1.T .. " HH=" .. f1.HH .. " Type=" .. f1.Ty .. " Y=" .. f1.Y) or "none"))
			print("  S2f=" .. (f2 and ("name=" .. f2.name .. " T=" .. f2.T .. " HH=" .. f2.HH .. " Type=" .. f2.Ty .. " Y=" .. f2.Y) or "none"))
		end
	end
	task.wait(0.4)
end
print("SIDE_DONE")