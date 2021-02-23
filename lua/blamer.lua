-- in blamer.lua
local M = {}
local api = vim.api

-- Not Committed Yet
local not_committed_hash = '0000000000000000000000000000000000000000'

local config = {
    enable = false,
    prefix = '🐛 ',
    format = '%committer | %committer-time %committer-tz | %summary',
    auto_hide = false,
    hide_delay = 3000,
}

-- skip scratch buffer or unkown filetype, nvim's terminal window, and other known filetypes need to bypass
local bypass_ft = { '', 'bin', '.', 'vim-plug', 'NvimTree', 'startify', 'nerdtree' }

local time_units = {
    { name = ' second', value = 1, max = 60, single = 'a second' },
    { name = ' minute', value = 60, max = 60, single = 'a minute' },
    { name = ' hour', value = 3600, max = 23, single = 'an hour' },
    { name = ' day', value = 86400, max = 6, single = 'a day' },
    { name = ' week', value = 604800, max = 3.5, single = 'a week' },
    { name = ' month', value = 2592000, max = 11, single = 'a month' },
    { name = ' year', value = 31536000, max = -1, single = 'a year' },
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

function M.setup(user_opts)
    local opts = user_opts or {}
    config = vim.tbl_extend('force', config, opts)
end

function M.blameVirtText()
    if not config.enable then
        return
    end
    if vim.bo.buftype ~= '' then
        return
    end

    for _, v in ipairs(bypass_ft) do
        if vim.bo.filetype == v then
            return
        end
    end

    -- clear out virtual text from namespace 2 (the namespace we will set later)
    api.nvim_buf_clear_namespace(0, 2, 0, -1)

    local buf = vim.fn.bufnr('') or 0
    local line = api.nvim_win_get_cursor(0)
    local filename = vim.fn.expand('%')

    -- https://git-scm.com/docs/git-blame#Documentation/git-blame.txt--Lltstartgtltendgt
    local lines = vim.fn.system(string.format('git --no-pager blame -c --line-porcelain -L %d,+1 %s', line[1], filename))

    if lines:match('fatal: no such path .+ in HEAD') then -- if the whole file not committed
        -- vim.api.nvim_command('echomsg "the whole file not committed"')
        return
    end

    if lines:match(not_committed_hash) then
        -- vim.api.nvim_command('echomsg "this line not committed"')
        return
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

    if blame_info.hash == not_committed_hash then
        return
    end

    local text
    if lines:find("fatal") then -- if the call to git show fails
        text = 'nvim-blamer.lua err: ' .. lines
    elseif not blame_info.hash then
        text = 'nvim-blamer.lua err: failed to get hash'
    else
        text = config.prefix
        text = text .. string.gsub(config.format, "%%([a-z-]+)", function(field)
            return blame_info[field]
        end)
    end
    -- set virtual text for namespace 2 with the content from git and assign it to the higlight group 'GitLens'
    api.nvim_buf_set_virtual_text(buf, 2, line[1] - 1, { { text, 'GitLens' } }, {})
    if config.auto_hide then
        vim.fn.timer_start(config.hide_delay, function()
            api.nvim_buf_clear_namespace(buf, 2, 0, -1)
        end)
    end
end

function M.clearBlameVirtText() -- important for clearing out the text when our cursor moves
    if not config.enable then
        return
    end
    api.nvim_buf_clear_namespace(0, 2, 0, -1)
end

function M.enable() -- important for clearing out the text when our cursor moves
    config.enable = true
end

function M.disable() -- important for clearing out the text when our cursor moves
    config.enable = false
end

return M
