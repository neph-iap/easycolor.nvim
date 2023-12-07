local config = require("easycolor.config")
local color_utils = require("easycolor.util.colors")
local format = require("easycolor.format")

local public = {}

---@type string[]
local highlight_groups = {}

public.picker_width = 20
public.picker_height = 10

public.hue = 0

public.format = config.options.formatting.default_format

-- Gets a highlight group for a color, creating it if it doesn't exist already.
--
---@param options { foreground?: string, background?: string }
---
---@return string name The name of the highlight group
local function get_highlight_group(options)
	if vim.fn.hlexists(options.foreground) == 1 then
		return options.foreground
	end

	local name = "EasyColor"
	if options.foreground then
		name = name .. "Fg" .. options.foreground:sub(2)
	end
	if options.background then
		name = name .. "Bg" .. options.background:sub(2)
	end

	if vim.tbl_contains(highlight_groups, name) then
		return name
	end

	local command = "hi " .. name .. " "
	if options.foreground then
		command = command .. "guifg=" .. options.foreground .. " "
	end
	if options.background then
		command = command .. "guibg=" .. options.background .. " "
	end

	table.insert(highlight_groups, name)
	vim.cmd(command)
	return name
end

local is_first_draw_call = true

-- Writes a line at the end of the buffer
--
---@param option_list { text: string, foreground?: string, background?: string }[]
---@param is_centered? boolean
--
---@return nil
local function write_line(option_list, is_centered)
	local text = ""
	for _, options in ipairs(option_list) do
		text = text .. options.text
	end

	local shift = 0
	if is_centered then
		shift = math.floor(public.width / 2) - math.floor(text:len() / 2)
		text = (" "):rep(shift) .. text
	end

	local line = vim.api.nvim_buf_line_count(public.buffer)
	if is_first_draw_call then
		line = 0
	end

	local start = -1
	if is_first_draw_call then
		start = 0
	end
	is_first_draw_call = false
	vim.api.nvim_buf_set_lines(public.buffer, start, -1, false, { text })

	text = ""
	for _, options in ipairs(option_list) do
		text = text .. options.text
		if options.foreground or options.background then
			local highlight_group = get_highlight_group(options)
			vim.api.nvim_buf_add_highlight(public.buffer, -1, highlight_group, line, #text - #options.text + shift, #text + shift)
		end
	end
end

-- Gets the color at the cursor in the main color picker
--
---@return string
function public.color_at_cursor()
	local row = public.cursor_row
	local column = public.cursor_column

	local value = 1 - row / (public.picker_height - 1)
	local saturation = column / (public.picker_width - 1)
	local hue = public.hue

	return color_utils.hsv_to_hex(hue, saturation, value)
end

-- Draws the color picker
--
---@return nil
function public.refresh()
	vim.api.nvim_buf_set_option(public.buffer, "modifiable", true)
	is_first_draw_call = true

	-- Header
	write_line({
		{ text = " EasyColor Picker" },
	})
	write_line({})

	local hue_slider_length = public.picker_height

	-- Color picker
	local row = 0
	while row < public.picker_height do
		local column = 0
		local strings = Table({})
		strings:insert({ text = " " })
		while column < public.picker_width do
			local value = 1 - row / (public.picker_height - 1)
			local saturation = column / (public.picker_width - 1)
			local color = color_utils.hsv_to_hex(public.hue, saturation, value)

			local char = " "
			local foreground = "#FFFFFF"
			if row == public.cursor_row and column == public.cursor_column then
				if value / saturation > 2 and value > 0.4 then
					foreground = "#000000"
				end
				char = config.options.ui.symbols.selection
			end

			strings:insert({ text = char, background = color, foreground = foreground })
			column = column + 1
		end

		-- Hue Slider
		strings:insert({ text = "    " })
		strings:insert({ text = "  ", background = color_utils.hsv_to_hex(row / hue_slider_length * 360, 1, 1) })

		if row / public.picker_height * 360 == public.hue then
			strings:insert({ text = " " .. config.options.ui.symbols.hue_arrow })
		end

		write_line(strings)

		row = row + 1
	end

	-- Preview
	row = 0
	write_line({})
	write_line({ { text = " Preview:" } })
	write_line({})

	local color = public.color_at_cursor() or "#FF0000"
	while row < 2 do
		local strings = Table({})
		strings:insert({ text = " " })
		strings:insert({ text = (" "):rep(public.picker_width + 6), background = color })
		row = row + 1
		write_line(strings)
	end

	write_line({ { text = "" } })

	-- Template
	local template = Table({})
	local function pattern_split(input, pattern)
		local result = {}
		local finish = 1

		repeat
			local next_start, next_finish, match = input:find("(" .. pattern .. ")", finish + 1)

			if next_start then
				local segment = input:sub(finish, next_start - 1)
				if #segment > 0 then
					table.insert(result, segment)
				end

				table.insert(result, match)
				finish = next_finish + 1
			else
				local segment = input:sub(finish)
				if #segment > 0 then
					table.insert(result, segment)
				end
			end
		until not next_start

		return result
	end

	template:insert({ text = " Template: " })
	for _, part in ipairs(pattern_split(public.format, "%$%w")) do
		if part:sub(1, 1) == "$" then
			template:insert({ text = part, foreground = "@variable" })
		else
			template:insert({ text = part })
		end
	end

	write_line(template)
	write_line({ { text = " Result:   " }, { text = format.format_color(color, public.format), foreground = "#FFFFFF" } })

	vim.api.nvim_buf_set_option(public.buffer, "modifiable", false)
end

-- Opens the EasyColor window
--
---@return nil
function public.open_window()
	is_first_draw_call = true
	public.buffer = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(public.buffer, "bufhidden", "wipe")

	public.height = 20
	public.width = 30

	local vim_width = vim.api.nvim_get_option("columns")
	local vim_height = vim.api.nvim_get_option("lines")

	local window_options = {
		style = "minimal",
		relative = "editor",
		border = config.options.ui.border,
		width = public.width,
		height = public.height,
		row = math.ceil((vim_height - public.height) / 2),
		col = math.ceil((vim_width - public.width) / 2),
	}

	for key, action in pairs(config.options.ui.mappings) do
		vim.api.nvim_buf_set_keymap(
			public.buffer,
			"n",
			key,
			(":lua require('easycolor.ui.actions').%s()<CR>"):format(action),
			{ nowait = true, noremap = true, silent = true }
		)
	end

	public.cursor_row = 1
	public.cursor_column = 1

	public.window = vim.api.nvim_open_win(public.buffer, true, window_options)
	public.refresh()
end
return public
