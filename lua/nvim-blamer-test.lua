#!/usr/bin/env lua
local json = require('dkjson')
local util = require('util')

local get_blame_info_emulate = function()
    local command = "git --no-pager blame -L 3,+1 --line-porcelain blamer.lua"
    -- local command = "git --no-pager blame -L 41,+1 --line-porcelain blamer.lua"
    local handle = io.popen(command)
    local lines = handle:read("*a")
    handle:close()
    return lines
end

-- test time_to_human
print(util.time_to_human(os.time() + 3600 * 24 * 40))

-- test git_blame_line_info
local blame_info, err = util.git_blame_line_info('blamer.lua', 3, get_blame_info_emulate)

if err ~= nil then
    print(err)
    os.exit(0)
end

print(json.encode(blame_info))

local config = {
    enable = false,
    prefix = '🐛 ',
    format = '%committer | %committer-time %committer-tz | %summary',
    delay = 3000,
}

local text = config.prefix
text = text .. string.gsub(config.format, "%%([a-z-]+)", function(field)
    return blame_info[field]
end)

print(text)
