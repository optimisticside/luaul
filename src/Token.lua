-- OptimisticSide
-- 5/1/2022
-- Lexical token implementation

-- luacheck: push globals script
local enumerate = require(_VERSION == "Luau" and script.Parent.enumerate or "./enumerate.lua")
-- luacheck: pop

local Token = {}
Token.__index = Token

Token.Kind = enumerate("Token.Kind", {
	-- Reserved
	"ReservedAnd", "ReservedBreak", "ReservedDo", "ReservedElse", "ReservedElseIf", "ReservedEnd", "ReservedFalse",
	"ReservedFor", "ReservedFunction", "ReservedIf", "ReservedIn", "ReservedLocal", "ReservedNil", "ReservedNot",
	"ReservedOr", "ReservedRepeat", "ReservedReturn", "ReservedThen", "ReservedTrue", "ReservedUntil", "ReservedWhile",

	-- Operators
	"Plus", "Minus", "Star", "Slash", "Modulo", "Hashtag", "QuestionMark",
	"Caret", "SemiColon", "Colon", "Dot", "Dot2", "Dot3", "SkinnyArrow",
	"NotEqual", "Equal", "LessThan", "LessEqual", "GreaterThan", "GreaterEqual",
	"LeftParen", "RightParen", "LeftBracket", "RightBracket", "LeftBrace", "RightBrace",

	-- Compound operators
	"PlusEqual", "MinusEqual", "StarEqual", "SlashEqual",

	-- Other things
	"QuotedString", "Comment", "Name",
})

function Token.new(tokenKind, startPosition, endPosition, value)
	local self = {}
	setmetatable(self, Token)

	self.startPosition = startPosition
	self.endPosition = endPosition
	self.kind = tokenKind
	self.value = value

	return self
end

function Token.is(object)
	return type(object) == "table" and getmetatable(object) == Token
end

return Token
