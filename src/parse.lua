-- OptimisticSIde
-- 5/1/2022
-- Luau parser

local Parser = {}
Parser.__index = Parser

function Parser.new(tokens)
	local self = {}
	setmetatable(self, Parser)

	self._tokens = tokens
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
	if self:_peekAccept(TokenKind.DO) then
		local node = self:parseBlock()
		self:_expect(TokenKind.END)
		return AstNode.new(AstNode.Kind.DO, node)
	end

	-- While-loop parser.
	if self:_peekAccept(TokenKind.WHILE) then
		local left = self:parseExpr()
		self:_expect(TokenKind.DO)
		local right = self:parseBlock()
		self:_expect(TokenKind.END)
		return AstNode.new(AstNode.Kind.WHILE_LOOP left, right)
	end

	-- Repeat-until loop parser.
	-- Essentially the same as the while-loop parser, except it expects
	-- a `until` instead of `do`.
	if self:_peekAccept(Token.Kind.REPEAT) then
		local left = self:parseExpr()
		self:_expect(TokenKind.UNTIL)
		local right = self:parseBlock()
		self:_expect(TokenKind.END)
		return AstNode.new(AstNode.Kind.REPEAT_LOOP left, right)
	end

	-- If-block parser.
	if self:_peekAccept(Token.Kind.IF) then
		
	end
end

--[[
	Main parsing routine. Parses a chunk of luau code.
--]]
function Parser:parseChunk()
	return self:parseBlock()
end

return Parser
