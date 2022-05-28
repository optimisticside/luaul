-- OptimisticSide
-- 5/1/2022
-- Abstract-syntax-tree node implementation

-- luacheck: push globals script
local enumerate = require(_VERSION == "Luau" and script.Parent.enumerate or "./enumerate.lua")
-- luacheck: pop

local AstNode = {}
AstNode.__index = AstNode

AstNode.Kind = enumerate({
	-- Simple types
	"True", "False", "Nil", "Dot3",

	-- Operators
	"Add", "Sub", "Mul", "Div", "Pow", "Concat",
	"CompareNe", "CompareEq", "CompareLt", "CompareLe", "CompareGt", "CompareGe",
	"And", "Or", "Not",

	-- Control-related operators
	"Continue", "Break", "Return",

	-- Expression related things
	"IndexName", "IndexExpr", "SelfIndexName", "FunctionCall", "TableConstructor", "Binding",

	-- Statements
	"IfStat", "FunctionStat", "CompoundAssign", "Assign",

	-- Control structures
	"DoBlock", "WhileLoop", "RepeatLoop", "ForLoop", "ForInLoop", "LocalFunction", "Local", "Block", "Global",

	-- Type-related things
	"TypeUnion", "TypeIntersection", "TypeAssertion", "TypeReference", "TypeTypeOf", "TypeFunction",
	"TypeTableIndexer", "TypeTableProp", "TypeTable",
	"SingletonBool", "SingletonString", "Singleton",
})

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
