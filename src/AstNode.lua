-- OptimisticSide
-- 5/1/2022
-- Abstract-syntax-tree node implementation

local AstNode = {}
AstNode.__index = AstNode

function AstNode.fromArray(nodeKind, children)
	local self = {}
	setmetatable(self, AstNode)

	self.kind = nodeKind
	self.children = children

	return self
end

function AstNode.new(nodeKind, ...)
	return AstNode.fromArray(nodeKind, table.pack(...))
end

function AstNode.is(object)
	return type(object) == "table" and getmetatable(object) == AstNode
end

return AstNode
