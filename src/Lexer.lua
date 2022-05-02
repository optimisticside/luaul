-- OptimisticSide
-- 5/2/2022
-- Lexical scanner

-- luacheck: push globals script
local Token = require(_VERSION == "Luau" and script.Parent.Token or "./Token.lua")
-- luacheck: pop


local Lexer = {}
Lexer.__index = Lexer

Lexer.Reserved = {
	["and"] = Token.Kind.ReservedAnd,
	["break"] = Token.Kind.ReservedBreak,
	["do"] = Token.Kind.ReservedDo,
	["else"] = Token.Kind.ReservedElse,
	["elseif"] = Token.Kind.ReservedElseIf,
	["end"] = Token.Kind.ReservedEnd,
	["false"] = Token.Kind.ReservedFalse,
	["for"] = Token.Kind.ReservedFor,
	["function"] = Token.Kind.ReservedFunction,
	["if"] = Token.Kind.ReservedIf,
	["in"] = Token.Kind.ReservedIn,
	["local"] = Token.Kind.ReservedLocal,
	["nil"] = Token.Kind.ReservedNil,
	["not"] = Token.Kind.ReservedNot,
	["or"] = Token.Kind.ReservedOr,
	["repeat"] = Token.Kind.ReservedRepeat,
	["return"] = Token.Kind.ReservedReturn,
	["then"] = Token.Kind.ReservedThen,
	["true"] = Token.Kind.ReservedTrue,
	["until"] = Token.Kind.ReservedUntil,
	["while"] = Token.Kind.ReservedWhile,
}

function Lexer.new(source)
	local self = {}
	setmetatable(self, Lexer)

	self._source = source
	self._tokens = {}

	return self
end

function Lexer.is(object)
	return type(object) == "table" and getmetatable(object) == Lexer
end

return Lexer