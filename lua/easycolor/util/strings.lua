local public = {}

-- Pads a string to the left
--
---@param str string The string to pad
---@param length number The length to pad the string to
---@param char string The character to pad the string with
---
---@return string padded The padded string
function public.pad_start(str, length, char)
	if #str >= length then
		return str
	end
	return (char:rep(length - #str)) .. str
end

return public
