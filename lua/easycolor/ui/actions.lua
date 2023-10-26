local ui = require("easycolor.ui")

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

function public.close_window()
	vim.api.nvim_win_close(ui.window, true)
end

return public
