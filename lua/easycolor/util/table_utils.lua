function Table(value)
	return setmetatable(value, { __index = table })
end
