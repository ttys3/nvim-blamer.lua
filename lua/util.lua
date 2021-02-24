#!/usr/bin/env lua
-- show_date_relative port from git blame.c
function show_date_relative(timestamp)
    local diff
    local now = os.time()

    if (now < timestamp) then
        return "in the future"
    end

    diff = now - timestamp

    if (diff < 90) then
        return diff .. " seconds ago"
    end
    -- /* Turn it into minutes */
    diff = (diff + 30) / 60
    if (diff < 90) then
        return diff .. " minutes ago"
    end

    -- /* Turn it into hours */
    diff = (diff + 30) / 60
    if (diff < 36) then
        return diff .. " hours ago"
    end
    -- /* We deal with number of days from here on */
    diff = (diff + 12) / 24
    if (diff < 14) then
        return diff .. " days ago"
    end
    -- /* Say weeks for the past 10 weeks or so */
    if (diff < 70) then
        return ((diff + 3) / 7) .. " weeks ago"
    end

    -- /* Say months for the past 12 months or so */
    if (diff < 365) then
        return ((diff + 15) / 30) .. " months ago"
    end

    -- /* Give years and months for 5 years or so */
    if (diff < 1825) then
        local totalmonths = (diff * 12 * 2 + 365) / (365 * 2)
        local years = totalmonths / 12
        local months = totalmonths % 12
        if (months) then
            local sb = years .. " years, " .. months(" months ago")
            return sb
        else
            local sb = years .. " years ago"
            return sb
        end
    end
    -- /* Otherwise, just years. Centuries is probably overkill. */
    return ((diff + 183) / 365) .. " years ago"
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
    return vim.fn.system(string.format('LC_ALL=C git --no-pager blame --line-porcelain -L %d,+1 %s', line_num, filename))
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
    local lower_lines = lines:lower()
    if lower_lines:match("^fatal: no such path") or lower_lines:match("^fatal: cannot stat path") or lower_lines:match("^fatal: not a git repository") or lower_lines:match("^fatal: .* is outside repository at") then
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
                    blame_info[k .. '-human'] = show_date_relative(v)
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
    show_date_relative = show_date_relative,
}

return M
