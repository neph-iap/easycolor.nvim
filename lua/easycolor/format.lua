local color_utils = require("easycolor.util.colors")
local public = {}

-- Formats a color for insertion.
--
---@param hex_color string The color to format in hex format
---@param format_string string
---
---@return string formatted The formatted string
function public.format_color(hex_color, format_string)
	local rgb = color_utils.hex_to_rgb(hex_color)
	local hsv = color_utils.hex_to_hsv(hex_color)
	local formatted, _ = format_string
		:gsub("$X", hex_color:upper())
		:gsub("$x", hex_color)
		:gsub("$r", rgb.red)
		:gsub("$g", rgb.green)
		:gsub("$b", rgb.blue)
		:gsub("$h", hsv.hue)
		:gsub("$s", hsv.saturation)
		:gsub("$v", hsv.value)
	return formatted
end

return public
