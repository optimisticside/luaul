-- OptimisticSide
-- 5/1/2022
-- Abstract-syntax-tree node implementation

local AstNode = {}
AstNode.__index = AstNode

function AstNode.new(nodeKind, ...)
	local self = {}
	setmetatable(self, AstNode)

	self.kind = nodeKind
	self.children = table.pack(...)

	return self
end

function AstNode.is(object)
	return type(object) == "table" and getmetatable(object) == AstNode
end

return AstNode
