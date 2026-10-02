local orig = shared.repfire
local seen = {}
local count = 0
shared.repfire = function(data)
    count = count + 1
    if type(data) == "table" and count <= 80 then
        local keys = {}
        for k, v in pairs(data) do
            local val
            if type(v) == "table" then
                local sub = {}
                for sk, sv in pairs(v) do
                    if type(sv) ~= "table" and type(sv) ~= "function" and type(sv) ~= "userdata" then
                        sub[#sub+1] = tostring(sk) .. "=" .. tostring(sv)
                    elseif sk == "Effect" or sk == "EventType" or sk == "uid" or sk == "Time" or sk == "Branch" then
                        sub[#sub+1] = tostring(sk) .. "=" .. tostring(sv)
                    end
                end
                table.sort(sub)
                val = "{" .. table.concat(sub:sub(1, 8), ", ") .. "}"
            elseif type(v) ~= "function" and type(v) ~= "userdata" then
                val = tostring(v)
            end
            if val then keys[#keys+1] = tostring(k) .. "=" .. val end
        end
        table.sort(keys)
        print("[repfire#" .. count .. "] " .. table.concat(keys, " | "))
    end
    return orig(data)
end
print("[repfire-dump] hooked, will log 80 events then restore")