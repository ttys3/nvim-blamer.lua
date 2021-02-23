#!/usr/bin/env lua
local command = "git --no-pager blame -L 3,+1 --line-porcelain blamer.lua"
-- local command = "git --no-pager blame -L 41,+1 --line-porcelain blamer.lua"
local handle = io.popen(command)
local lines = handle:read("*a")
handle:close()

-- {
--   "filename": "lua/blamer.lua",
--   "hash": "db43ae622dbec1ba3fd8172c2d4fed1b2980c39c",
--   "summary": "fix: bypass ft list: rename LuaTree to NvimTree. do not show Not Committed Yet msg",
--
--   "committer": "荒野無燈",
--   "committer-mail": "<a@example.com>",
--   "committer-tz": "+0800",
--   "committer-time": "1610563580",
--
--   "author": "荒野無燈",
--   "author-mail": "<a@example.com>",
--   "author-time": "1610563580",
--   "author-tz": "+0800",
-- }

-- some constants
-- Not Committed Yet
local not_committed_hash = '0000000000000000000000000000000000000000'

local time_units = {
    { name = ' second', value = 1, max = 60, single = 'a second' },
    { name = ' minute', value = 60, max = 60, single = 'a minute' },
    { name = ' hour', value = 3600, max = 23, single = 'an hour' },
    { name = ' day', value = 86400, max = 6, single = 'a day' },
    { name = ' week', value = 604800, max = 3.5, single = 'a week' },
    { name = ' month', value = 2592000, max = 11, single = 'a month' },
    { name = ' year', value = 31536000, max = -1, single = 'a year' },
}

function time_to_human(ts)
    local diff = tonumber(ts) - os.time()

    local suffix = ' ago'

    for i = 1, #time_units, 1 do
        local unit = time_units[i]

        if (diff <= unit.max * unit.value) then
            local t = math.floor(diff / unit.value)
            if t == 1 then
                return unit.single .. suffix
            else
                return t .. unit.name .. 's' .. suffix
            end
        end
    end

    return "seconds ago"
end

print(time_to_human(os.time() + 3600 * 24 * 40))

if lines:match(not_committed_hash) then
    print("not committed")
    os.exit(0)
end

local blame_info = {}
for k, v in lines:gmatch("([a-z0-9-]+) ([^\n]+)\n?") do
    -- print(k .. ' -> ' .. v)
    local field = k:match('^([a-z0-9-]+)')
    if field then
        if field:len() == 40 then
            print('got hash |' .. field .. '|')
            blame_info.hash = field
        else
            if field:match('time') then
                blame_info[k] = os.date('%Y-%m-%d %H:%M:%S', tonumber(v))
                blame_info[k] = (os.time() - tonumber(v)) / (3600 * 24 * 7)
            else
                blame_info[k] = v
            end
        end
    end
end

local json = require('dkjson')
print(json.encode(blame_info))

local config = {
    enable = false,
    prefix = '🐛 ',
    format = '%summary | %committer %committer-mail | %committer-time %committer-tz',
    delay = 2000,
}

local text = config.prefix
text = text .. string.gsub(config.format, "%%([a-z-]+)", function(field)
    return blame_info[field]
end)

print(text)
