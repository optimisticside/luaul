--[[
	Compiler for Luau.
]]

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

	self._functions = {}
	self._locals = {}
	self._globals = {}
	self._variables = {}
	self._constants = {}
	self._localConstants = {}
	self._tableShapes = {}
	self._builtins = {}

	self._regTop = 0
	self._stackSize = 0

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

function Compiler:compileStat(stat)
	
end

--[[
	Compiles a function. Used by the compiler's main entry point, to parse the
	source as a "main" function.
]]
function Compiler:compileFunction(func)
	
end

return Compiler