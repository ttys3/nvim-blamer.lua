-- nvim-blamer.lua

local M = {}
local api = vim.api

local util = require("util")

local hi_name = "NvimBlamerInfo"

-- virtual text namespace id
local ns_id = 0

local config = {
	enable = false,
	prefix = "  ",
	format = "%committer │ %committer-time %committer-tz │ %summary",
	auto_hide = false,
	hide_delay = 3000,
	show_error = false,
}

-- skip scratch buffer or unkown filetype, nvim's terminal window, and other known filetypes need to bypass
local bypass_ft = { "", "bin", ".", "vim-plug", "NvimTree", "startify", "nerdtree" }

function M.setup(user_opts)
	local opts = user_opts or {}
	config = vim.tbl_extend("force", config, opts)
	-- config.format = string.gsub("-", "_")
end

function M.show()
	if not config.enable then
		return
	end
	if vim.bo.buftype ~= "" then
		return
	end

	for _, v in ipairs(bypass_ft) do
		if vim.bo.filetype == v then
			return
		end
	end

	-- clear out virtual text from namespace ns_id (the namespace we will set later)
	M.clear()

	local buf = vim.fn.bufnr("") or 0
	local line = api.nvim_win_get_cursor(0)
	local filename = vim.fn.expand("%")

	local blame_info, err = util.git_blame_line_info(filename, line[1])

	if err ~= nil then
		if not config.show_error then
			return
		else
			text = err
		end
	elseif blame_info ~= nil then
		text = config.prefix
		text = text .. string.gsub(config.format, "%%([a-z-_]+)", function(field)
			return blame_info[field]
		end)
	else
		-- no need to display blame info, just return
		return
	end
	-- set virtual text for namespace 2 with the content from git and assign it to the higlight group 'GitLens'
	-- https://neovim.io/doc/user/api.html#nvim_buf_set_virtual_text()
	ns_id = api.nvim_create_namespace("NvimBlamer")
	api.nvim_buf_set_virtual_text(buf, ns_id, line[1] - 1, { { text, hi_name } }, {})
	if config.auto_hide then
		vim.fn.timer_start(config.hide_delay, M.clear)
	end
end

function M.clear() -- important for clearing out the text when our cursor moves
	if ns_id > 0 then
		api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
		ns_id = 0
	end
end

function M.enable()
	config.enable = true
end

function M.disable()
	config.enable = false
end

function M.toggle()
	config.enable = not config.enable
end

return M
