--[[
	Helper function to create a strict interface that errors, when the user
	attempts to access something that it does not include.
]]
local function strict(name, inner)
	return setmetatable(inner, {
		__index = function(_, index)
			error(("%q is not a valid member of %q"):format(tostring(index), name))
		end,

		__newindex = function(_, index)
			error(("%q of %q is not assignable"):format(tostring(index), name))
		end,
	})
end

--[[
	Barebones implementation of custom enumerations in lua.
]]
local function enumerate(enumName, enumItems)
	local items = {}

	for _, name in ipairs(enumItems) do
		local item = newproxy(true)
		local metaTable = getmetatable(item)

		function metaTable.__tostring()
			return ("%s.%s"):format(enumName, name)
		end

		items[name] = item
	end

	return strict(enumName, items)
end

return enumerate