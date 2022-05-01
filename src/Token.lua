-- OptimisticSide
-- 5/1/2022
-- Lexical token implementation

local Token = {}
Token.__index = Token

function Token.new(tokenKind, position, value)
	local self = {}
	setmetatable(self, Token)

	self.kind = tokenKind
	self.position = position
	self.value = value

	return self
end

return Token
