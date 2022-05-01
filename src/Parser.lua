-- OptimisticSIde
-- 5/1/2022
-- Luau parser

local AstNode = require(_VERSION == "Luau" and script.Parent.AstNode or "./AstNode.lua")
local Token = require(_VERSION == "Luau" and script.Parent.Token or "./Token.lua")

local Parser = {}
Parser.__index = Parser

function Parser.new(tokens)
	local self = {}
	setmetatable(self, Parser)

	self._tokens = tokens
	self._token = self._tokens[1]
	self._position = 1

	return self
end

--[[
	Accepts a token if valid, and returns nil otherwise.
]]
function Parser:_accept(tokenKind)
	local token = self._token
	if token and token.kind == tokenKind then
		self:_advance()
		return token
	end
end

--[[
	Expects to read a certain type of token. If this token is not found,
	then it will throw a parse-error.
]]
function Parser:_expect(tokenKind)
	local token = self:_accept(tokenKind)
	if not token or token.kind ~= tokenKind then
		self:_error(
			"Expected %s, got %s at %s",
			tokstr(tokenKind), tokstr(token.kind), token.position
		)
		return
	end
	return token
end

function Parser:parseStmt()
	-- Do-block parser.
	if self:_accept(TokenKind.DO) then
		local body = self:parseBlock()
		self:_expect(TokenKind.END)
		return AstNode.new(AstNode.Kind.DO_BLOCK, body)
	end

	-- While-loop parser.
	if self:_accept(TokenKind.WHILE) then
		local condition = self:parseExpr()
		self:_expect(TokenKind.DO)

		local body = self:parseBlock()
		self:_expect(TokenKind.END)

		return AstNode.new(AstNode.Kind.WHILE_LOOP condition, body)
	end

	-- Repeat-until loop parser.
	-- Essentially the same as the while-loop parser, except it expects
	-- a `until` instead of `do`.
	if self:_accept(Token.Kind.REPEAT) then
		local condition = self:parseExpr()
		self:_expect(TokenKind.UNTIL)

		local body = self:parseBlock()
		self:_expect(TokenKind.END)

		return AstNode.new(AstNode.Kind.REPEAT_LOOP condition, body)
	end

	-- If-block parser.
	if self:_accept(Token.Kind.IF) then
		local condition = self:parseExpr()
		self:_expect(TokenKind.THEN)

		local thenBlock = self:parseBlock()
		local elseIfBlocks = {}

		while self:_peekAccept(Token.Kind.ELSEIF) do
			local elseIfCondition = self:parseExpr()
			self:_expect(TokenKind.THEN)
			table.insert(elseIfBlocks, elseIfCondition, self:parseBlock())
		end

		-- TODO: How do we store a chain of if-elseif statements in the ast?
		self:_accept(Token.Kind.END)
	end
end

--[[
	Main parsing routine. Parses a chunk of luau code.
--]]
function Parser:parseChunk()
	return self:parseBlock()
end

return Parser
