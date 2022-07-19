--[[
	A register-scope just stores the last register-top. I'm not even sure
	why this is a class.
]]

local RegisterScope = {}
RegisterScope.__index = RegisterScope

function RegisterScope.new(compiler)
	local self = {}
	setmetatable(self, RegisterScope)

	self.compiler = compiler
	self.oldTop = self.compiler.regTop

	return self
end

return RegisterScope