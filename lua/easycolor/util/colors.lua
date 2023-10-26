local string_utils = require("easycolor.util.strings")

local public = {}

-- Converts a hex color to an RGB color
--
---@param hex_color string The hex color
---
---@return { red: integer, green: integer, blue: integer } rgb The RGB color
function public.hex_to_rgb(hex_color)
	local r = tonumber(hex_color:sub(2, 3), 16)
	local g = tonumber(hex_color:sub(4, 5), 16)
	local b = tonumber(hex_color:sub(6, 7), 16)
	return { red = r, green = g, blue = b }
end

-- Converts an RGB color to a hex color
--
---@param red integer The red value of the color
---@param blue integer The blue value of the color
---@param green integer The green value of the color
---
---@return string hex The hex color
function public.rgb_to_hex(red, blue, green)
	return ("#%s%s%s"):format(string_utils.pad_start(("%x"):format(red), 2, "0"), string_utils.pad_start(("%x"):format(blue), 2, "0"), string_utils.pad_start(("%x"):format(green), 2, "0"))
end

-- Converts a HSV color to a hex color
--
---@param hue integer The hue of the color 
---@param saturation number The saturation of the color
---@param value number The value of the color
---
---@return string hex The hex color
function public.hsv_to_hex(hue, saturation, value)
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

	return public.rgb_to_hex(red, green, blue)
end

-- Converts a hex color to a HSV color
--
---@param hex_color string The hex color
---
---@return { hue: number, saturation: number, value: number } hsv The HSV color
function public.hex_to_hsv(hex_color)
	local rgb = public.hex_to_rgb(hex_color)

	local max = math.max(rgb.red, rgb.green, rgb.blue)
	local min = math.min(rgb.red, rgb.green, rgb.blue)

	local value = max / 255
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

return public
