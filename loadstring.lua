local URL = "https://raw.githubusercontent.com/justsadnyx-ux/ScriptSource/main/source.lua"

local function fetch(url)
    local methods = {
        function() return game:HttpGet(url, true) end,
        function() return game:HttpGet(url) end,
        function() return syn.request({Url = url, Method = "GET"}).Body end,
        function() return http_request({Url = url, Method = "GET"}).Body end,
        function() return request({Url = url, Method = "GET"}).Body end,
    }
    for _, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result and result ~= "" then
            return result
        end
    end
    return nil
end

local source = fetch(URL)
if source then
    local func = loadstring(source)
    if func then
        func()
    else
        warn("[Rayfield] loadstring compilation failed")
    end
else
    warn("[Rayfield] Failed to fetch source")
end
