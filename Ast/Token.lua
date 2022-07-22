--[[
	Lexical token implementation. Each token contains a value and a kind,
	as well as debugging information such as where the token begins and ends.
]]

local enumerate = require(script and script.Parent.Parent.enumerate or "../Common/enumerate.lua")

local Token = {}
Token.__index = Token

Token.Kind = enumerate("Token.Kind", {
	-- Reserved
	"ReservedAnd", "ReservedBreak", "ReservedDo", "ReservedElse", "ReservedElseIf", "ReservedEnd", "ReservedFalse",
	"ReservedFor", "ReservedFunction", "ReservedIf", "ReservedIn", "ReservedLocal", "ReservedNil", "ReservedNot",
	"ReservedOr", "ReservedRepeat", "ReservedReturn", "ReservedThen", "ReservedTrue", "ReservedUntil", "ReservedWhile",

	-- Operators
	"Plus", "Minus", "Star", "Slash", "Modulo", "Hashtag", "Caret", "SemiColon", "Colon", "Dot", "Dot2", "Dot3", "Equal",
	"NotEqual", "EqualTo", "LessThan", "LessEqual", "GreaterThan", "GreaterEqual",
	"LeftParen", "RightParen", "LeftBracket", "RightBracket", "LeftBrace", "RightBrace",

	-- Delimiters
	"Comma", "SemiColon",

	-- Type-related operators
	"DoubleColon", "Pipe", "Ampersand", "SkinnyArrow", "QuestionMark",

	-- Compound operators
	"PlusEqual", "MinusEqual", "StarEqual", "SlashEqual",

	-- Other things
	"QuotedString", "LongString", "Comment", "Number", "Name", "EndOfFile",
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
