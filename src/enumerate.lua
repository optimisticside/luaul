--[[
	Barebones implementation of custom enumerations in lua.
]]
local function enumerate(enumName, enumItems)
	local items = {}

	for _, name in ipairs(enumItems) do
		local item = newproxy(true)
		local metaTable = getmetatable(item)

		function metaTable.__tostring()
			return ("%s:%s"):format(enumName, name)
		end

		items[name] = item
	end

	return items
end

return enumerate