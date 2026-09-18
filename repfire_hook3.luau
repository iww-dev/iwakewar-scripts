local orig = shared.repfire
if type(orig) ~= "function" then
    print("[ERR] repfire not a function: " .. type(orig))
    return
end
local count = 0
local replacement = function(data)
    count = count + 1
    if type(data) == "table" and count <= 60 then
        local out = {}
        for k, v in pairs(data) do
            if type(v) == "table" then
                local sub = {}
                for sk, sv in pairs(v) do
                    if type(sv) ~= "table" and type(sv) ~= "function" and type(sv) ~= "userdata" and type(sv) ~= "thread" then
                        sub[#sub+1] = tostring(sk) .. "=" .. tostring(sv)
                    end
                end
                if #sub > 10 then
                    local trimmed = {}
                    for i = 1, 10 do trimmed[i] = sub[i] end
                    out[#out+1] = tostring(k) .. "={" .. table.concat(trimmed, ",") .. ",..+" .. (#sub-10) .. "}"
                else
                    out[#out+1] = tostring(k) .. "={" .. table.concat(sub, ",") .. "}"
                end
            elseif type(v) ~= "function" and type(v) ~= "userdata" and type(v) ~= "thread" then
                out[#out+1] = tostring(k) .. "=" .. tostring(v)
            end
        end
        print("[RF#" .. count .. "] " .. table.concat(out, " | "))
    end
    return orig(data)
end
local ok, err = pcall(hookfunction, orig, replacement)
if ok then
    getgenv().rfdumpCount = 0
    print("[RF-HOOK] hookfunction OK. repfire now hooked.")
else
    print("[RF-HOOK] hookfunction err: " .. tostring(err))
end