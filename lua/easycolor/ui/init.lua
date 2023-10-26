local public = {}

---@type string[]
local highlight_groups = {}

public.picker_width = 20
public.picker_height = 10


-- Gets a highlight group for a color, creating it if it doesn't exist already.
--
---@param options { foreground?: string, background?: string }
---
---@return string name The name of the highlight group
local function get_highlight_group(options)
	local name = "EasyColor"
	if options.foreground then name = name .. "Fg" .. options.foreground:sub(2) end
	if options.background then name = name .. "Bg" .. options.background:sub(2) end

	if vim.tbl_contains(highlight_groups, name) then return name end

	local command = "hi " .. name .. " "
	if options.foreground then command = command .. "guifg=" .. options.foreground .. " " end
	if options.background then command = command .. "guibg=" .. options.background .. " " end

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
		text = (' '):rep(shift) .. text
	end

	local line = vim.api.nvim_buf_line_count(public.buffer)
	if is_first_draw_call then line = 0 end

	local start = -1
	if is_first_draw_call then start = 0 end
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

-- Pads a string to the left
--
---@param str string The string to pad
---@param length number The length to pad the string to
---@param char string The character to pad the string with
---
---@return string padded The padded string
local function pad_start(str, length, char)
	if #str >= length then return str end
	return (char:rep(length - #str)) .. str
end

local function hex_to_rgb(hex_color)
	local r = tonumber(hex_color:sub(2, 3), 16)
	local g = tonumber(hex_color:sub(4, 5), 16)
	local b = tonumber(hex_color:sub(6, 7), 16)
	return { red = r, green = g, blue = b }
end

local function rgb_to_hex(red, blue, green)
	return ("#%s%s%s"):format(pad_start(("%x"):format(red), 2, "0"), pad_start(("%x"):format(blue), 2, "0"), pad_start(("%x"):format(green), 2, "0"))
end

-- Converts a HSV color to a hex color
--
---@param hue number The hue of the color 
---@param saturation number The saturation of the color
---@param value number The value of the color
---
---@return string hex The hex color
local function hsv_to_hex(hue, saturation, value)
	hue = (hue % 360 + 360) % 360
	saturation = math.max(0, math.min(1, saturation))
	value = math.max(0, math.min(1, value))

	local chroma = value * saturation
	local x = chroma * (1 - math.abs((hue / 60) % 2 - 1))
	local min = value - chroma

	local red, green, blue

	if hue >= 0 and hue < 60 then
		red = chroma
		green = x
		blue = 0
	elseif hue >= 60 and hue < 120 then
		red = x
		green = chroma
		blue = 0
	elseif hue >= 120 and hue < 180 then
		red = 0
		green = chroma
		blue = x
	elseif hue >= 180 and hue < 240 then
		red = 0
		green = x
		blue = chroma
	elseif hue >= 240 and hue < 300 then
		red = x
		green = 0
		blue = chroma
	else
		red = chroma
		green = 0
		blue = x
	end

	red = math.floor((red + min) * 255 + 0.5)
	green = math.floor((green + min) * 255 + 0.5)
	blue = math.floor((blue + min) * 255 + 0.5)

	return rgb_to_hex(red, green, blue)
end

local function hex_to_hsv(hex_color)
	local rgb = hex_to_rgb(hex_color)

	local max = math.max(rgb.red, rgb.green, rgb.blue)
	local min = math.min(rgb.red, rgb.green, rgb.blue)

	local value = max
	local hue
	local saturation

	local difference = max - min
	if max == 0 then saturation = 0 else saturation = difference / max end

	if max == min then
		hue = 0
	else
		if max == rgb.red then
			hue = (rgb.green - rgb.blue) / difference
			if rgb.green < rgb.blue then
				hue = hue + 6
			end
		elseif max == rgb.green then
			hue = (rgb.blue - rgb.red) / difference + 2
		else
			hue = (rgb.red - rgb.green) / difference + 4
		end
		hue = hue * 60
	end

	return { hue = hue, saturation = saturation, value = value }
end

local function color_at_cursor()
	local row = public.cursor_row
	local column = public.cursor_column

	local value = 1 - row / (public.picker_height - 1)
	local saturation = column / (public.picker_width - 1)
	local hue = 0

	if value < 0 or value > 1 then return nil end
	if saturation < 0 or saturation > 1 then return nil end

	return hsv_to_hex(hue, saturation, value)
end

-- Draws the color picker
--
---@return nil
function public.refresh()
	vim.api.nvim_buf_set_option(public.buffer, "modifiable", true)
	is_first_draw_call = true
	local hue = 0

	-- write_line({})
	write_line({
		{ text = " EasyColor Picker                        (Press ? for help)" },
	})
	write_line({})

	local row = 0
	while row < public.picker_height do
		local column = 0
		local strings = Table {}
		strings:insert({ text = " " })
		while column < public.picker_width do
			local value = 1 - row / (public.picker_height - 1)
			local saturation = column / (public.picker_width - 1)
			local color = hsv_to_hex(hue, saturation, value)

			local char = " "
			if row == public.cursor_row and column == public.cursor_column then char = "󰆢" end

			strings:insert({ text = char, background = color, foreground = '#FFFFFF' })
			column = column + 1
		end
		strings:insert({ text = "    " })
		strings:insert({ text = "  ", background = hsv_to_hex(row / public.picker_height * 360, 1, 1) })

		if row == 0 then strings:insert({ text = " ◀"}) end

		local row_texts = {
			{
				{ text = "  RGB: " }
			},
			(function()
				local redline = Table { { text = "    " } }
				local color = hex_to_rgb(color_at_cursor() or "#FF0000")
				local red = 0
				while red < 256 do
					local char = " "
					if math.abs(red - color.red) < (128 / public.picker_width) then char = "󰆢" end
					redline:insert({ text = char, background = rgb_to_hex(red, color.green, color.blue), foreground = "#FFFFFF" })
					red = red + (255 / public.picker_width)
				end
				redline:insert({ text = " " .. tostring(hex_to_rgb(color_at_cursor() or "#FF0000").red) })
				return redline
			end)(),
			(function()
				local greenline = Table { { text = "    " } }
				local color = hex_to_rgb(color_at_cursor() or "#FF0000")
				local green = 0
				while green < 256 do
					local char = " "
					if math.abs(green - color.green) < (128 / public.picker_width) then char = "󰆢" end
					greenline:insert({ text = char, background = rgb_to_hex(color.red, green, color.blue), foreground = "#FFFFFF" })
					green = green + (255 / public.picker_width)
				end
				greenline:insert({ text = " " .. tostring(hex_to_rgb(color_at_cursor() or "#FF0000").green) })
				return greenline
			end)(),
			(function()
				local blueline = Table { { text = "    " } }
				local color = hex_to_rgb(color_at_cursor() or "#FF0000")
				local blue = 0
				while blue < 256 do
					local char = " "
					if math.abs(blue - color.blue) < (128 / public.picker_width) then char = "󰆢" end
					blueline:insert({ text = char, background = rgb_to_hex(color.red, color.green, blue), foreground = "#FFFFFF" })
					blue = blue + (255 / public.picker_width)
				end
				blueline:insert({ text = " " .. tostring(hex_to_rgb(color_at_cursor() or "#FF0000").blue) })
				return blueline
			end)(),
			{},
			{
				{ text = "    HSV: "}
			},
			(function()
				local hueline = Table { { text = "    " } }
				local color = hex_to_hsv(color_at_cursor() or "#FF0000")
				hue = 0
				while hue < 360 do
					local char = " "
					if math.abs(hue - color.hue) < (360 / public.picker_width) then char = "󰆢" end
					hueline:insert({ text = char, background = hsv_to_hex(hue, color.saturation, color.value), foreground = "#FFFFFF" })
					hue = hue + (360 / public.picker_width)
				end
				hueline:insert({ text = " " .. tostring(hex_to_hsv(color_at_cursor() or "#FF0000").hue) })
				return hueline
			end)(),
			(function()
				local saturation_line = Table { { text = "    " } }
				local color = hex_to_hsv(color_at_cursor() or "#FF0000")
				local saturation = 0
				while saturation < 1 do
					local char = " "
					if math.abs(saturation - color.saturation) < (0.5 / public.picker_width) then char = "󰆢" end
					saturation_line:insert({ text = char, background = hsv_to_hex(color.hue, saturation, color.value), foreground = "#FFFFFF" })
					saturation = saturation + (1 / public.picker_width)
				end
				saturation_line:insert({ text = " " .. tostring(math.floor(hex_to_hsv(color_at_cursor() or "#FF0000").saturation * 100)) .. "%" })
				return saturation_line
			end)(),
			(function()
				local value_line = Table { { text = "    " } }
				local color = hex_to_hsv(color_at_cursor() or "#FF0000")
				local value = 0
				while value < 1 do
					local char = " "
					if math.abs(value - color.value) < (0.5 / public.picker_width) then char = "󰆢" end
					value_line:insert({ text = char, background = hsv_to_hex(color.hue, color.saturation, value), foreground = "#FFFFFF" })
					value = value + (1 / public.picker_width)
				end
				value_line:insert({ text = " " .. tostring(hex_to_hsv(color_at_cursor() or "#FF0000").value) })
				return value_line
			end)(),
		}

		if row_texts[row + 1] then
			for _, text in ipairs(row_texts[row + 1]) do
				strings:insert(text)
			end
		end
		write_line(strings)

		row = row + 1
	end

	-- Preview
	row = 0
	write_line({})
	write_line({ { text = (" Preview:                              Hex: " .. (color_at_cursor() or "#FFFFFF"):upper()) } })
	write_line({})

	local color = color_at_cursor() or "#FF0000"
	while row < 2 do
		local strings = Table {}
		strings:insert({ text = " " })
		strings:insert({ text = (" "):rep(public.picker_width * 2 + 18), background = color })
		row = row + 1
		write_line(strings)
	end

	-- write_line({})

	vim.api.nvim_buf_set_option(public.buffer, "modifiable", false)
end

-- Opens the EasyColor window
--
---@return nil
function public.open_window()
	is_first_draw_call = true
	public.buffer = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(public.buffer, "bufhidden", "wipe")

	public.height = 17
	public.width = 60

	local vim_width = vim.api.nvim_get_option("columns")
	local vim_height = vim.api.nvim_get_option("lines")

	local window_options = {
		style = "minimal",
		relative = "editor",
		border = "rounded",
		width = public.width,
		height = public.height,
		row = math.ceil((vim_height - public.height) / 2),
		col = math.ceil((vim_width - public.width) / 2),
	}

	local mappings = {
		q = "close_window",
		j = "move_cursor_down",
		k = "move_cursor_up",
		h = "move_cursor_left",
		l = "move_cursor_right",
		["<Down>"] = "move_cursor_down",
		["<Up>"] = "move_cursor_up",
		["<Left>"] = "move_cursor_left",
		["<Right>"] = "move_cursor_right"
	}

	for key, action in pairs(mappings) do
		vim.api.nvim_buf_set_keymap(public.buffer, "n", key, (":lua require('easycolor.ui.actions').%s()<CR>"):format(action), { nowait = true, noremap = true, silent = true })
	end

	public.cursor_row = 1
	public.cursor_column = 1

	public.window = vim.api.nvim_open_win(public.buffer, true, window_options)
	public.refresh()
end

return public
