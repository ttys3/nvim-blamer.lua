#!/usr/bin/env lua
local time_units = {
    { name = ' second', value = 1, max = 60, single = 'a second' },
    { name = ' minute', value = 60, max = 60, single = 'a minute' },
    { name = ' hour', value = 3600, max = 23, single = 'an hour' },
    { name = ' day', value = 86400, max = 6, single = 'a day' },
    { name = ' week', value = 604800, max = 3.5, single = 'a week' },
    { name = ' month', value = 2592000, max = 11, single = 'a month' },
    { name = ' year', value = 31536000, max = 0xfffffffffffffff, single = 'a year' },
}

local time_to_human = function(ts)
    local diff = os.time() - tonumber(ts)

    if diff <= 0 then
        return 'in the future' .. tonumber(ts) .. '|' .. os.time()
    end

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

-- Not Committed Yet
local git_not_committed_hash = '0000000000000000000000000000000000000000'

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

local get_blame_info_impl = function(filename, line_num)
    return vim.fn.system(string.format('git --no-pager blame --line-porcelain -L %d,+1 %s', line_num, filename))
end

-- git_blame_line_info returns (blame_info, error)
local git_blame_line_info = function(filename, line_num, get_blame_info)
    -- https://git-scm.com/docs/git-blame#Documentation/git-blame.txt--Lltstartgtltendgt
    -- git --no-pager blame -c --line-porcelain -L <start>,<end> [--] <file>
    -- If <start> or <end> is a number, it specifies an absolute line number (lines count from 1).
    if get_blame_info == nil then
        get_blame_info = get_blame_info_impl
    end
    local lines = get_blame_info(filename, line_num)

    local err = nil

    -- errors that should ignored
    if lines:match('^fatal: no such path .+ in HEAD') or lines:match('^fatal: cannot stat path') or lines:match('^fatal: Not a git repository') then
        -- vim.api.nvim_command('echomsg "the whole file not committed or not git repo"')
        return nil, err
    end

    -- errors that should ignored
    if lines:match(git_not_committed_hash) then
        -- vim.api.nvim_command('echomsg "this line not committed"')
        return nil, err
    end

    local blame_info = {}
    for k, v in lines:gmatch("([a-z0-9-]+) ([^\n]+)\n?") do
        -- print(k .. ' -> ' .. v)
        local field = k:match('^([a-z0-9-]+)')
        if field then
            if field:len() == 40 then
                blame_info.hash = field
            else
                if field:match('time') then
                    blame_info[k .. '-human'] = time_to_human(v)
                    blame_info[k] = os.date('%Y-%m-%d %H:%M:%S', v)
                else
                    blame_info[k] = v
                end

            end
        end
    end

    -- uncaught or unexpected error
    if lines:find("fatal") then -- if the call to git show fails
        err = 'nvim-blamer.lua unexpected err: ' .. lines
    elseif not blame_info.hash then
        err = 'nvim-blamer.lua unexpected err: failed to get hash'
    end

    return blame_info, err
end

local M = {
    git_blame_line_info = git_blame_line_info,
    time_to_human = time_to_human,
}

return M
