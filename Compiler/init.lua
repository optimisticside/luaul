--[[
	Compiler for Luau.
]]

local MAX_REGISTER_COUNT = 255
local MAX_UPVALUE_COUNT = 200
local MAX_LOCAL_COUNT = 200

local ConstantFolding = require(script and script.Parent.ConstantFolding or "./ConstantFolding")
local RegisterScope = require(script and script.Parent.RegisterScope or "./RegisterScope")

local Opcodes = require(script and script.Parent.Parent.Common.Opcodes or "../Common/Opcodes")
local AstNode = require(script and script.Parent.Parent.AstNode or "../Ast/AstNode")

local Compiler = {}
Compiler.__index = Compiler

Compiler.DefaultOptions = {
	-- 0 - no optimization
    -- 1 - baseline optimization level that doesn't prevent debuggability
    -- 2 - includes optimizations that harm debuggability such as inlining
    optimizationLevel = 1,

    -- 0 - no debugging support
    -- 1 - line info & function names only; sufficient for backtraces
    -- 2 - full debug info with local & upvalue names; necessary for debugger
    debugLevel = 1,

    -- 0 - no code coverage support
    -- 1 - statement coverage
    -- 2 - statement and expression coverage (verbose)
    coverageLevel = 0,

    -- null-terminated array of globals that are mutable; disables the import
	-- optimization for fields accessed through these
    mutableGlobals = nil,
}

function Compiler.new(bytecodeBuilder, options)
	local self = {}
	setmetatable(self, Compiler)

	self._options = Compiler._parseOptions(options or {})
	self._bytecode = bytecodeBuilder

	self.functions = {}
	self.locals = {}
	self.globals = {}
	self.variables = {}
	self.constants = {}
	self.localConstants = {}
	self.tableShapes = {}
	self.builtins = {}

	self.regTop = 0
	self.stackSize = 0

	self._getfenvUsed = false
	self._setfenvUsed = false

	self._localStack = {}
	self._upvalues = {}
	self._loopJumps = {}
	self._loops = {}
	self._inlineFrames = {}
	self._captures = {}

	return self
end

--[[
	Parses the compiler's options and insertes defaults for keys that were not
	provided by the user.
]]
function Compiler._parseOptions(options)
	for option, default in pairs(Compiler.DefaultOptions) do
		options[option] = options[option] == nil and default or options[option]
	end

	return options
end

function Compiler:isConstantFalse(astNode)
	local constant = self.constants[astNode]
	return constant and not constant:isTruthful()
end

--[[
	Allocates the given number of registers.
]]
function Compiler:allocateRegister(astNode, count)
	local top = self.registerTop
	if top + count > MAX_REGISTER_COUNT then
		self:_error(
			"Out of registers when trying to allocate %d registers: exceeded limit %d",
			count,
			MAX_REGISTER_COUNT
		)
	end

	self.registerTop = self.registerTop + count
	self.stackSize = math.max(self.stackSize, self.registerTop)
	return top
end

--[[
	Push a local variable into the local-register.
]]
function Compiler:pushLocal(astNode, register)
	if #self._localStack > MAX_LOCAL_COUNT then
		self:_error(
			"Out of local registers when trying to allocate %s: exceeded limit %d",
			astNode.name.value,
			MAX_LOCAL_COUNT
		)
	end

	table.insert(self._localStack, astNode)
	local localVariable = self.locals[astNode]
	localVariable.register = register
	localVariable.allocated = true
end

--[[
	Closes all locals that are placed after the given start position (acts as
	a base-pointer of sorts).
]]
function Compiler:closeLocals(startPosition)
	local captureRegister = 255
	local isCaptured = false

	for i = startPosition, #self._localStack do
		local localVariable = self.locals[self._localStack[i]]
		if localVariable.captured then
			isCaptured = true
			captureRegister = math.min(captureRegister, localVariable.register)
		end
	end

	if isCaptured then
		self._bytecode:emitABC(Opcodes.CloseUpvalues, captureRegister, 0, 0)
	end
end

function Compiler:compileStat(astNode)
	if astNode.kind == AstNode.Kind.Block then
		local registerScope = RegisterScope.new(self)
		local oldStack = #self._localStack

		for _, statement in ipairs(astNode.children) do
			self:compileStat(statement)
		end
	
		-- TODO: Close and pop locals.
	elseif astNode.kind == AstNode.Kind.WhileLoop then
		-- Optimization: Ignore loop if the condition is always false.
		if self:isConstantFalse(astNode) then
			return
		end

		local oldJumps = #self._loopJumps
		local oldLocals = #self._localStack

		local label = self._bytecode:emitLabel()
		
	end
end

--[[
	Compiles a function. Used by the compiler's main entry point, to parse the
	source as a "main" function.
]]
function Compiler:compileFunction(func)
	local 
end

return Compiler