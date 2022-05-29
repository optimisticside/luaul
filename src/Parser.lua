-- OptimisticSide
-- 5/1/2022
-- Luau parser

-- luacheck: push globals script
local AstNode = require(_VERSION == "Luau" and script.Parent.AstNode or "./AstNode.lua")
local Token = require(_VERSION == "Luau" and script.Parent.Token or "./Token.lua")
-- luacheck: pop

local Parser = {}
Parser.__index = Parser

Parser.SimpleTokens = {
	[Token.Kind.ReservedTrue] = AstNode.Kind.True,
	[Token.Kind.ReservedFalse] = AstNode.Kind.False,
	[Token.Kind.ReservedNil] = AstNode.Kind.Nil,
	[Token.Kind.Dot3] = AstNode.Kind.Dot3,
}

Parser.CompountOpers = {
	[Token.Kind.PlusEqual] = AstNode.Kind.Add,
	[Token.Kind.MinusEqual] = AstNode.Kind.Sub,
	[Token.Kind.StarEqual] = AstNode.Kind.Mul,
	[Token.Kind.SlashEqual] = AstNode.Kind.Div,
}

Parser.UnaryOpers = {
	[Token.Kind.Hashtag] = AstNode.Kind.Len,
	[Token.Kind.ReservedNot] = AstNode.Kind.Not,
	[Token.Kind.Minus] = AstNode.Kind.Neg,
}

Parser.BinaryOpers = {
	[Token.Kind.Plus] = AstNode.Kind.Add,
	[Token.Kind.Minus] = AstNode.Kind.Sub,
	[Token.Kind.Star] = AstNode.Kind.Mul,
	[Token.Kind.Slash] = AstNode.Kind.Div,
	[Token.Kind.Modulo] = AstNode.Kind.Mod,
	[Token.Kind.Caret] = AstNode.Kind.Pow,
	[Token.Kind.Dot2] = AstNode.Kind.Concat,
	[Token.Kind.NotEqual] = AstNode.Kind.CompareNe,
	[Token.Kind.EqualTo] = AstNode.Kind.CompareEq,
	[Token.Kind.LessThan] = AstNode.Kind.CompareLt,
	[Token.Kind.LessEqual] = AstNode.Kind.CompareLe,
	[Token.Kind.GreaterThan] = AstNode.Kind.CompareGt,
	[Token.Kind.GreaterEqual] = AstNode.Kind.CompareGe,
	[Token.Kind.ReservedAnd] = AstNode.Kind.And,
	[Token.Kind.ReservedOr] = AstNode.Kind.Or,
}

Parser.DefaultOptions = {
	allowTypeAnnotations = true,
	supportContinueStatement = true,
	captureComments = false,
}

function Parser.new(tokens, options, advancer)
	local self = {}
	setmetatable(self, Parser)

	local index = 0
	self._advancer = advancer or function()
		index = index + 1
		if index < #self._tokens then
			return self._tokens[index]
		end
	end

	self._tokens = tokens
	self._options = Parser._parseOptions(options or {})
	self._token = self._advancer()

	return self
end

function Parser.is(object)
	return type(object) == "table" and getmetatable(object) == Parser
end

--[[
	Creates an operator parsing routine, from a generic function.

	This is done to avoid repeating code, and will return a function that will
	parse the provided operators, and call the provided subparser to get the
	operands.
]]
function Parser.useGeneric(generic, subParser, ...)
	local operators = table.pack(...)

	return function(self)
		return generic(self, operators, subParser)
	end
end

--[[
	Parses the parser's options and insertes defaults for keys that were not
	provided by the user.
]]
function Parser._parseOptions(options)
	for option, default in pairs(Parser.DefaultOptions) do
		options[option] = options[option] == nil and default or options[option]
	end

	return options
end

--[[
	Determines whether a statement is the last statement of a block.

	This saves us time because we won't have to parse statements after
	it.
]]
function Parser.isLastStat(stat)
	return stat.kind == AstNode.Kind.Break or stat.Kind == AstNode.Kind.Continue or stat.kind == AstNode.Kind.Return
end

--[[
	Determins whether an expression is a valid L-value for an assignment.

	Used in both normal and compound and normal assignments.
]]
function Parser.isExprLValue(expr)
	return expr.kind == AstNode.Kind.Local
		or expr.kind == AstNode.Kind.Global
		or expr.kind == AstNode.Kind.IndexExpr
		or expr.kind == AstNode.Kind.IndexName
end

--[[
	Determines whether a statement is part of a block or not.

	Used by Parser::parseBlock to see when to stop the statement-paring loop.
]]
function Parser.isFollowingBlock(token)
	return token.Kind == Token.Kind.EndOfFile
		or token.kind == Token.Kind.ReservedElse
		or token.kind == Token.Kind.ReservedElseIf
		or token.kind == Token.Kind.ReservedEnd
		or token.kind == Token.Kind.ReservedUntil
end

--[[
	Throws an error generated by the parser.

	Note that this can be overriden by the user (since it's retrieved
	through the __index metamethod).
]]
-- luacheck: ignore self
function Parser:_error(formatString, ...)
	error(formatString:format(...))
end

--[[
	Advances to the next token.
]]
function Parser:_advance()
	self._token = self._advancer()
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
	Peeks for a token and returns it, but does not actually consume it.
]]
function Parser:_peek(tokenKind)
	local token = self._token
	if token and token.kind == tokenKind then
		return token
	end
end

--[[
	Expects to read a certain type of token. If this token is not found,
	then it will throw a parse-error.
]]
function Parser:_expect(tokenKind, context)
	local token = self._token

	if not token or token.kind ~= tokenKind then
		if context then
			self:_error(
				"Expected %s when parsing %s, got %s",
				tostring(tokenKind),
				context,
				tostring(token.kind)
			)
		else
			self:_error("Expected %s, got %s", tostring(tokenKind), tostring(token.kind))
		end
	end

	self:_advance()
	return token
end

--[[
	Helper function to parse things separate by a delimiter token.
	This is used for expression lists, and other things like that.
]]
function Parser:_parseList(subParser, delimiter)
	local values = {}

	repeat
		table.insert(values, subParser(self))
	until not self:_accept(delimiter)

	return values
end

function Parser:genericBinary(tokens, subParser)
	local left = subParser(self)

	if not self._token then
		return left
	end

	while true do
		local token = nil
		for _, possibleToken in ipairs(tokens) do
			if self:_accept(possibleToken) then
				token = possibleToken
			end
		end

		if not token then
			break
		end

		local right = subParser(self)
		local nodeKind = Parser.BinaryOpers[token]
		left = AstNode.new(nodeKind, left, right)
	end

	return left
end

function Parser:genericPrefix(tokens, subParser)
	local left = subParser(self)
	local stack = {}

	if not left then
		return
	end

	while true do
		local token = nil
		for _, possibleToken in ipairs(tokens) do
			if self:_accept(possibleToken) then
				token = possibleToken
			end
		end

		if not token then
			break
		end

		table.insert(stack, token)
	end

	-- We must use a numeric-for loop so that we can go backwards
	-- through the stack, starting at the top.
	for i = #stack, 1, -1 do
		local nodeKind = Parser.UnaryOpers[stack[i]]
		left = AstNode.new(nodeKind, left)
	end

	return left
end

function Parser:genericPostfix(tokens, subParser)
	local left = subParser(self)

	while true do
		local token = nil
		for _, possibleToken in ipairs(tokens) do
			if self:_accept(possibleToken) then
				token = possibleToken
			end
		end

		if not token then
			break
		end

		local nodeKind = Parser.UnaryOpers[token]
		left = AstNode.new(nodeKind, left)
	end

	return left
end

function Parser:parseAssertionExpr()
	local expr = self:parseSimpleExpr()

	if self._options.allowTypeAnnotations and self:_accept(Token.Kind.DoubleColon) then
		local annotation = self:parseTypeAnnotation()
		expr = AstNode.new(AstNode.Kind.TypeAssertion, expr, annotation)
	end

	return expr
end

-- Generic operator usage.
Parser.parsePow = Parser.useGeneric(Parser.genericBinary, Parser.parseAssertionExpr, Token.Kind.Caret)
Parser.parseUnary = Parser.useGeneric(
	Parser.genericPrefix,
	Parser.parsePow,
	Token.Kind.Minus,
	Token.Kind.ReservedNot
)

Parser.parseFactor = Parser.useGeneric(Parser.genericBinary, Parser.parseUnary, Token.Kind.Modulo)
Parser.parseMulExpr = Parser.useGeneric(
	Parser.genericBinary,
	Parser.parseFactor,
	Token.Kind.Star,
	Token.Kind.Slash,
	Token.Kind.Modulo
)

Parser.parseSumExpr = Parser.useGeneric(Parser.genericBinary, Parser.parseMulExpr, Token.Kind.Plus, Token.Kind.Minus)
Parser.parseConcatExpr = Parser.useGeneric(Parser.genericBinary, Parser.parseSumExpr, Token.Kind.Dot2)
Parser.parseCompareExpr = Parser.useGeneric(
	Parser.genericBinary,
	Parser.parseConcatExpr,
	Token.Kind.LessThan,
	Token.Kind.LessEqual,
	Token.Kind.GreaterThan,
	Token.Kind.GreaterEqual,
	Token.Kind.EqualTo,
	Token.Kind.NotEqual
)

Parser.parseAndExpr = Parser.useGeneric(Parser.genericBinary, Parser.parseCompareExpr, Token.Kind.ReservedAnd)
Parser.parseOrExpr = Parser.useGeneric(Parser.genericBinary, Parser.parseAndExpr, Token.Kind.ReservedOr)
Parser.parseExpr = Parser.parseOrExpr

-- Note that the `if` that starts the if-else expression must be consumed
-- prior to calling ths function.
function Parser:parseIfElseExpr()
	local condition = self:parseExpr()
	self:_expect(Token.Kind.ReservedThen)

	local thenExpr = self:parseExpr()
	local elseExpr

	if self:_accept(Token.Kind.ReservedElseIf) then
		elseExpr = self:parseIfElseExpr()
	else
		self:_expect(Token.Kind.ReservedElse)
		elseExpr = self:parseExpr()
	end

	return AstNode.new(Token.Kind.IfElseExpr, condition, thenExpr, elseExpr)
end

function Parser:parseTableConstructor()
	local canContinue = true
	local fields = {}

	while canContinue and not self:_accept(Token.Kind.RightBrace) do
		-- [expr] = expr
		if self:_accept(Token.Kind.LeftBracket) then
			local key = self:parseExpr()
			self:_expect(Token.Kind.RightBracket)

			self:_expect(Token.Kind.Equal)
			local value = self:parseExpr()
			table.insert(fields, { key, value })
		elseif self:_peek(Token.Kind.Name) then
			-- If we see a name, it could either be the key of a value
			-- in the table, or just be a variable.
			local name = self:_accept(Token.Kind.Name)

			-- name = expr
			if self:_accept(Token.Kind.Equal) then
				local value = self:parseExpr()
				table.insert(fields, { name, value })

			-- name
			else
				table.insert(fields, name)
			end
		end

		canContinue = self:_accept(Token.Kind.Comma) or self:_accept(Token.Kind.SemiColon)
	end

	return AstNode.fromArray(AstNode.Kind.TableConstructor, fields)
end

function Parser:parseSimpleExpr()
	-- Parser for simple tokens, where the corresponding node
	-- can be found through a table.
	local nodeKind = Parser.SimpleTokens[self._token.kind]
	if nodeKind then
		self:_advance()
		return AstNode.new(nodeKind)
	end

	-- Table constructor parser.
	if self:_peek(Token.Kind.LeftBrace) then
		return self:parseTableConstructor()
	end

	-- If-else expression parser.
	if self:_accept(Token.Kind.ReservedIf) then
		return self:parseIfElseExpr()
	end

	-- String parser.
	local str = self:_accept(Token.Kind.QuotedString) or self:_accept(Token.Kind.LongString)
	if str then
		return AstNode.new(AstNode.Kind.String, str)
	end

	-- Number parser.
	local number = self:_accept(Token.Kind.Number)
	if number then
		return AstNode.new(AstNode.Kind.Number, number)
	end

	return self:parsePrimaryExpr()
end

function Parser:parsePrefixExpr()
	if self:_accept(Token.Kind.LeftParen) then
		local expr = self:parseExpr()
		self:_expect(Token.Kind.RightParen)

		return expr
	end

	return self:parseName()
end

function Parser:parseBinding()
	local name = self:parseName()
	local typeAnnotation

	if self:_accept(Token.Kind.Colon) then
		typeAnnotation = self:parseTypeAnnotation()
	end

	return AstNode.new(AstNode.Kind.Binding, name, typeAnnotation)
end

function Parser:parseExprList()
	return self:_parseList(Parser.parseExpr, Token.Kind.Comma)
end

function Parser:parseBindingList()
	return self:_parseList(Parser.parseBinding, Token.Kind.Comma)
end

function Parser:parseTypeList()
	return self:_parseList(Parser.parseTypeAnnotation, Token.Kind.Comma)
end

function Parser:parseTypeParams()
	-- TODO: Implement this.
end

-- luacheck: ignore
function Parser:parseName(context)
	return self:_expect(Token.Kind.Name)
end

function Parser:parseGenericTypeList()
	if self:_accept(Token.Kind.LessThan) then
		-- TODO: Implement this later.
		
		self:_expect(Token.Kind.GreaterThan)
	end
end

function Parser:parseSimpleTypeAnnotation()
	-- We should have a better system for builin types that don't rely
	-- on the actual keywords, like `nil` and `true`.
	if self:_accept(Token.Kind.ReservedNil) then
		return AstNode.new(AstNode.Kind.TypeReference, AstNode.Kind.Nil)
	end

	if self:_accept(Token.Kind.ReservedTrue) then
		return AstNode.new(AstNode.Kind.SingletonBool, AstNode.Kind.True)
	end

	if self:_accept(Token.Kind.ReservedFalse) then
		return AstNode.new(AstNode.Kind.SingletonBool, AstNode.Kind.False)
	end

	local stringType = self:_accept(Token.Kind.QuotedString) or self:_accept(Token.Kind.LongString)
	if stringType then
		return AstNode.new(AstNode.Kind.SingletonString, stringType)
	end

	if self:_peek(Token.Kind.Name) then
		local name = self:parseName()
		local prefix

		-- Luau only supports one type-field indexing, not multiple.
		if self:_accept(Token.Kind.Dot) then
			prefix = name
			name = self:parseName()
		elseif name.value == "typeof" then
			self:_expect(Token.Kind.LeftParen)
			local expr = self:parseExpr()

			self:_expect(Token.Kind.RightParen)
			return AstNode.new(AstNode.Kind.TypeTypeOf, expr)
		end

		local hasParameters = false
		local parameters = {}

		-- We should rename these tokens to be something like:
		-- Token.Kind.AngleBracketLeft or something, to avoid confusion.
		if self:_peek(Token.Kind.LessThan) then
			hasParameters = true
			parameters = self:parseTypeParams()
		end

		return AstNode.new(AstNode.Kind.TypeReference, prefix, name, hasParameters, parameters)
	end

	-- Table type-annotation parser
	if self:_accept(Token.Kind.LeftBrace) then
		local canContinue = false
		local types = {}

		while canContinue and not self:_accept(Token.Kind.RightBrace) do
			-- [type]: type
			if self:_accept(Token.Kind.LeftBracket) then
				local indexType = self:parseTypeAnnotation()

				self:_expect(Token.Kind.RightBracket)
				self:_expect(Token.Kind.Colon)

				local valueType = self:parseTypeAnnotation()
				table.insert(types, AstNode.new(AstNode.Kind.TypeTableIndexer, indexType, valueType))

			-- name: type
			elseif self:_peek(Token.Kind.Name) then
				local name = self:parseName()
				table.insert(types, AstNode.new(AstNode.Kind.TypeTableProp, name, self:parseTypeAnnotation()))
			end

			canContinue = self:_accept(Token.Kind.Comma) or self:_accept(Token.Kind.SemiColon)
		end

		return AstNode.fromArray(AstNode.Kind.TypeTable, types)
	end

	-- Function type-annotation parser
	if self:_peek(Token.Kind.LessThan) or self:_peek(Token.Kind.LeftParen) then
		local generics = self:parseGenericTypeList()
		self:_expect(Token.Kind.LeftParen)

		local params = nil
		if self:_peek(Token.Kind.RightParen) then
			params = self:parseTypeList()
		end

		self:_expect(Token.Kind.RightParen)
		self:_expect(Token.Kind.SkinnyArrow)

		-- Return types can also be type lists wrapped in parentheses.
		if self:_accept(Token.Kind.LeftParen) then
			local returnType = self:parseTypeList()
			self:_expect(Token.Kind.RightParen)

			return AstNode.new(AstNode.Kind.TypeFunction, generics, params, returnType)
		end

		return AstNode.new(AstNode.Kind.TypeFunction, generics, params, self:parseTypeAnnotation())
	end
end

function Parser:parseTypeAnnotation()
	local parts = { self:parseSimpleTypeAnnotation() }
	local isIntersection = false
	local isUnion = false

	while true do
		if self:_accept(Token.Kind.Pipe) then
			table.insert(parts, self:parseSimpleTypeAnnotation())
			isUnion = true

		elseif self:_accept(Token.Kind.Ampersand) then
			table.insert(parts, self:parseSimpleTypeAnnotation())
			isIntersection = true

		elseif self:_accept(Token.Kind.QuestionMark) then
			table.insert(parts, AstNode.Kind.Nil)
			isUnion = true

		else
			break
		end
	end

	if isUnion and isIntersection then
		return self:_error("Cannot combine unions and intersections")
	end

	if isUnion then
		return AstNode.fromArray(AstNode.Kind.TypeUnion, parts)
	end

	if isIntersection then
		return AstNode.fromArray(AstNode.Kind.TypeIntersection, parts)
	end

	-- If we didn't have an intersection or a union, then we can assume we
	-- only had 1 element in the array.
	return parts[1]
end

function Parser:parseFunctionArgs(selfParameter)
	local args = {}

	if self:_peek(Token.Kind.LeftBrace) then
		args = { self:parseTableConstructor() }

	elseif self:_peek(Token.Kind.QuotedString) then
		args = { self:_accept(Token.Kind.QuotedString) }

	else
		-- Since we've already checked for all other forms of providing function
		-- arguments, we can expect the user to provide normal function arguments
		-- with parentheses.
		self:_expect(Token.Kind.LeftParen)
		if not self:_accept(Token.Kind.RightParen) then
			args = self:parseExprList()
			self:_expect(Token.Kind.RightParen)
		end
	end

	if selfParameter then
		table.insert(args, 1, selfParameter)
	end

	return args
end

function Parser:parsePrimaryExpr()
	local expr = self:parsePrefixExpr()

	while true do
		-- prefixexpr.name
		if self:_accept(Token.Kind.Dot) then
			expr = AstNode.new(AstNode.Kind.IndexName, expr, self:parseName())

		-- prefixexpr[expr]
		elseif self:_accept(Token.Kind.LeftBracket) then
			expr = AstNode.new(AstNode.Kind.IndexExpr, expr, self:parseExpr())
			self:_expect(Token.Kind.RightBracket)

		-- prefixexpr:name(functionargs)
		elseif self:_accept(Token.Kind.Colon) then
			local func = AstNode.new(AstNode.Kind.SelfIndexName, expr, self:parseName())
			expr = AstNode.new(AstNode.Kind.FunctionCall, func, self:parseFunctionArgs(expr))

		-- prefixexpr(functionargs) | prefixexpr{tableconstructor} | prefixexpr string
		elseif
			self:_peek(Token.Kind.LeftParen)
			or self:_peek(Token.Kind.LeftBrace)
			or self:_peek(Token.Kind.QuotedString)
		then
			expr = AstNode.new(AstNode.Kind.FunctionCall, expr, self:parseFunctionArgs())
		else
			break
		end
	end

	return expr
end

function Parser:parseDeclaration()
	return self:_error("Declarations are not supported yet")
end

function Parser:parseCompoundAssignment(left, oper)
	if not Parser.isExprLValue(left) then
		return self:_error("Assigned expression must be a variable or field")
	end

	local value = self:parseExpr()
	return AstNode.new(AstNode.Kind.CompoundAssign, left, oper, value)
end

function Parser:parseAssignment(left)
	if not Parser.isExprLValue(left) then
		return self:_error("Assigned expression must be a variable or field")
	end

	local values = { left }
	for _, value in ipairs(self:_parseList(Parser.parsePrimaryExpr, Token.Kind.Comma)) do
		table.insert(values, value)
	end

	return AstNode.new(AstNode.Kind.Assign, values, self:parseExprList())
end

function Parser:parseStat()
	-- Do-block parser.
	if self:_accept(Token.Kind.ReservedDo) then
		local body = self:parseBlock()
		self:_expect(Token.Kind.ReservedEnd)
		return AstNode.new(AstNode.Kind.DoBlock, body)
	end

	-- While-loop parser.
	if self:_accept(Token.Kind.ReservedWhile) then
		local condition = self:parseExpr()
		self:_expect(Token.Kind.ReservedDo)

		local body = self:parseBlock()
		self:_expect(Token.Kind.ReservedEnd)

		return AstNode.new(AstNode.Kind.WhileLoop, condition, body)
	end

	-- Repeat-until loop parser.
	-- Essentially the same as the while-loop parser, except it expects
	-- a `until` instead of `do`.
	if self:_accept(Token.Kind.ReservedRepeat) then
		local condition = self:parseExpr()
		self:_expect(Token.Kind.ReservedUntil)

		local body = self:parseBlock()
		self:_expect(Token.Kind.ReservedEnd)

		return AstNode.new(AstNode.Kind.RepeatLoop, condition, body)
	end

	-- If-block parser.
	if self:_accept(Token.Kind.ReservedIf) then
		local ifCondition = self:parseExpr()
		self:_expect(Token.Kind.ReservedThen)

		local thenBlock = self:parseBlock()
		local blocks = { { ifCondition, thenBlock } }

		while self:_accept(Token.Kind.ReservedElseIf) do
			local elseIfCondition = self:parseExpr()
			self:_expect(Token.Kind.ReservedThen)
			table.insert(blocks, { elseIfCondition, self:parseBlock() })
		end

		if self:_accept(Token.Kind.ReservedElse) then
			table.insert(blocks, self:parseBlock())
		end

		self:_accept(Token.Kind.ReservedEnd)
		-- Each block is in the block array (in order)
		-- `elseif` and `if` statements are stored as an array containing
		-- their condition and block. `then` statements are just stored
		-- as just their block.
		return AstNode.fromArray(AstNode.Kind.IfStat, blocks)
	end

	-- For-loop parser.
	if self:_accept(Token.Kind.ReservedFor) then
		local binding = self:parseBinding()

		-- Numeric for loop (doesn't have to be numeric, but yeah).
		-- for binding = expr, expr, expr do block end
		if self:_accept(Token.Kind.Equal) then
			local start = self:parseExpr()
			local finish, step

			if self:_accept(Token.Kind.Comma) then
				finish = self:parseExpr()

				if self:_accept(Token.Kind.Comma) then
					step = self:parseExpr()
				end
			end

			self:_expect(Token.Kind.ReservedDo)
			local block = self:parseBlock()

			self:_expect(Token.Kind.ReservedEnd)
			return AstNode.new(AstNode.Kind.ForLoop, binding, start, finish, step, block)

		-- For-in loop (this is what you do when you use the pairs function).
		-- for (binding)+ in (expr)+ do block end
		else
			local bindings = self:parseBindingList()

			self:_expect(Token.Kind.ReservedIn)
			local values = self:parseExprList()

			self:_expect(Token.Kind.ReservedDo)
			local block = self:parseBlock()

			self:_expect(Token.Kind.ReservedEnd)
			return AstNode.new(AstNode.Kind.ForInLoop, bindings, values, block)
		end
	end

	-- Function statement parser.
	-- name.name...name.name:name functionbody
	-- TODO: Make this, along with other statement parsers separate functions.
	if self:_accept(Token.Kind.ReservedFunction) then
		local expr = self:parseName()

		while self:_accept(Token.Kind.Dot) do
			expr = AstNode.new(AstNode.Kind.IndexName, expr, self:parseName())
		end

		if self:_accept(Token.Kind.Colon) then
			expr = AstNode.new(AstNode.Kind.SelfIndexName, expr, self:parseName())
		end

		local body = self:parseFunctionBody()
		return AstNode.new(AstNode.Kind.FunctionStat, expr, body)
	end

	if self:_accept(Token.Kind.ReservedLocal) then
		-- Local function defenition.
		if self:_accept(Token.Kind.ReservedFunction) then
			local name = self:parseName()
			local body = self:parseFunctionBody()

			self:_expect(Token.Kind.ReservedEnd)
			return AstNode.new(AstNode.Kind.LocalFunction, name, body)

		-- Local variable defenitions.
		else
			local bindings = self:parseBindingList()
			self:_expect(Token.Kind.Equal)

			local values = self:parseExprList()
			return AstNode.new(AstNode.Kind.Local, bindings, values)
		end
	end

	if self:_accept(Token.Kind.ReservedReturn) then
		local exprList = nil
		if not Parser.isFollowingBlock(self._token) and not self:_peek(Token.Kind.SemiColon) then
			self:parseExprList()
		end

		return AstNode.new(AstNode.Kind.Return, exprList)
	end

	if self:_accept(Token.Kind.ReservedBreak) then
		return AstNode.new(AstNode.Kind.Break)
	end

	local expr = self:parsePrimaryExpr()
	if expr.kind == AstNode.Kind.FunctionCall then
		return expr
	end

	if self:_peek(Token.Kind.Comma) or self:_peek(Token.Kind.Equal) then
		return self:parseAssignment(expr)
	end

	local compoundOper = Parser.CompountOpers[self._token.kind]
	if compoundOper then
		return self:parseCompoundAssignment()
	end

	-- Things like `type`, `export`, and `continue` are context-dependent
	-- keywords so we handle them as if they were identifiers.
	-- TODO: Take another look at this code. Identifiers should be same thing
	-- as names.
	if expr.kind == AstNode.Kind.Iden then
		if self._options.allowTypeAnnotations then
			-- I did not know that `type` was actually an operator until now.
			if expr.value == "type" then
				return self:parseTypeAlias(expr, false)
			elseif expr.value == "export" and self._token.kind == Token.Kind.Iden and self._token.value == "type" then
				return self:parseTypeAlias(expr, true)
			end
		end

		if self._options.supportContinueStatement and expr.value == "continue" then
			return AstNode.new(AstNode.Kind.Continue)
		end

		if self._options.allowTypeAnnotations and expr.value == "declare" then
			return self:parseDeclaration()
		end

		return self:_error("Incomplete statement: expected assignment or a function call")
	end
end

function Parser:parseBlock()
	local stats = {}
	local stat

	repeat
		stat = self:parseStat()
		table.insert(stats, stat)
		self:_accept(Token.Kind.SemiColon)
	until not stat or Parser.isLastStat(stat) or Parser.isFollowingBlock(self._token)

	return AstNode.fromArray(AstNode.Kind.Block, stats)
end

--[[
	Main parsing routine. Parses a chunk of luau code.
--]]
function Parser:parseChunk()
	local root = self:parseBlock()
	self.result = root
	return root
end

return Parser
