local ui = require("easycolor.ui")
local formatter = require("easycolor.format")

local public = {}

function public.move_cursor_down()
	ui.cursor_row = math.min(ui.cursor_row + 1, ui.picker_height - 1)
	ui.refresh()
end

function public.move_cursor_up()
	ui.cursor_row = math.max(0, ui.cursor_row - 1)
	ui.refresh()
end

function public.move_cursor_left()
	ui.cursor_column = math.max(0, ui.cursor_column - 1)
	ui.refresh()
end

function public.move_cursor_right()
	ui.cursor_column = math.min(ui.cursor_column + 1, ui.picker_width - 1)
	ui.refresh()
end

function public.hue_down()
	local original_row = ui.hue / 360 * ui.picker_height
	local new_hue = (original_row + 1) / ui.picker_height * 360
	ui.hue = new_hue % 360
	ui.refresh()
end

function public.hue_up()
	local original_row = ui.hue / 360 * ui.picker_height
	local new_hue = (original_row - 1) / ui.picker_height * 360
	ui.hue = new_hue % 360
	ui.refresh()
end

function public.close_window()
	vim.api.nvim_win_close(ui.window, true)
end

function public.insert_color()
	public.close_window()
	vim.api.nvim_put({ formatter.format_color(ui.color_at_cursor(), ui.format) }, "", false, true)
end

return public
