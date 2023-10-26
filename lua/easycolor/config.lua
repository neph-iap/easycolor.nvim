local public = {}

---@class Config
local default_config = {
	ui = {
		border = "rounded"
	}
}

public.options = default_config

function public.set_config(options)
	public.options = vim.tbl_deep_extend("force", default_config, options)
end

return public
