local enumerate = require(script and script.Parent.enumerate or "./enumerate")

local Opcodes = enumerate("Opcodes", {
	-- No-operation
	"Nop",

	-- Debugger break
	"Break",

	-- Sets the regsiter to nil
	-- A: Target register
	"LoadNil",

	-- Sets the register to a boolean and jumps to a given short offset. Used
	-- to compile comparisons into a boolean.
	-- A: Target register
	-- B: Boolean value (0 or 1)
	-- C: Jump offset
	"LoadB",

	-- Sets the register to a number literal.
	-- A: Target register
	-- B: Number value (between -32768 and 32767)
	"LoadN",

	-- Move (copy) a register to another register.
	-- A: Destination register
	-- B: Source register
	"Move",
})

return Opcodes