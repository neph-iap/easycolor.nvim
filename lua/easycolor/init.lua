require("easycolor.util.table_utils")
local config = require("easycolor.config")

local public = {}

-- Sets up the EasyColor plugin
--
---@param options Config the configuration options
---
---@return nil
function public.setup(options)
	print("WARNING: easycolor.nvim is moving to a new account. Please change your configuration to vi013t/easycolor.nvim. This repo will be deleted soon.")
	config.set_config(options)
	local ui = require("easycolor.ui")
	vim.api.nvim_create_user_command("EasyColor", function()
		ui.open_window()
	end, {})
end

return public
