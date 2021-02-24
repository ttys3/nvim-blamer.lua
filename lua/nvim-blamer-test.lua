#!/usr/bin/env lua
local json = require('dkjson')
local util = require('util')

function test_outside_repo_err()
    err = "fatal: '/home/ttys3/.ideavimrc' is outside repository at '/home/xxxx'"
    print('test outside repo err match: ' .. err:match("^fatal: .* is outside repository at"))
end

test_outside_repo_err()

--------------------------------

local get_blame_info_emulate = function()
    local command = "LC_ALL=C git --no-pager blame -L 3,+1 --line-porcelain nvim-blamer.lua"
    -- local command = "git --no-pager blame -L 41,+1 --line-porcelain blamer.lua"
    local handle = io.popen(command)
    local lines = handle:read("*a")
    handle:close()
    print("\n[debug] got blame line info: -------- \n\n" .. lines .. "\n -------- \n\n")
    return lines
end

-- test show_date_relative
print(util.show_date_relative(os.time() - 3600 * 24 * 40))

--------------------------------

-- test git_blame_line_info
local blame_info, err = util.git_blame_line_info('nvim-blamer.lua', 3, get_blame_info_emulate)

if err ~= nil then
    print(err)
    os.exit(0)
end

print("\ngot blame info: \n" .. json.encode(blame_info))

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

print("\ngot result line mysql date: " .. text)

config.format = '%committer | %committer-time-human | %summary'
text = config.prefix
text = text .. string.gsub(config.format, "%%([a-z-]+)", function(field)
    return blame_info[field]
end)
print("\ngot result line human date: " .. text)
