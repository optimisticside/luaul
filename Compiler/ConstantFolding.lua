local AstNode = require(script and script.Parent.AstNode or "Ast/AstNode")

local ConstantFolding = {}

function ConstantFolding.foldUnary(oper, child)
	if oper == AstNode.Kind.Not then
		if child.kind == AstNode.Kind.True then
			return AstNode.fromValue(AstNode.Kind.False)
		elseif child.kind == AstNode.Kind.False then
			return AstNode.fromValue(AstNode.Kind.True)
		end

	elseif oper == AstNode.Kind.Neg then
		if child.kind == AstNode.Kind.Number then
			return AstNode.fromValue(AstNode.Kind.Number, -child.value)
		end

	elseif oper == AstNode.Kind.Len then
		if child.kind == AstNode.Kind.String then
			return AstNode.fromValue(AstNode.Kind.Number, #child.value)
		end
	end

	return nil
end

function ConstantFolding.foldBinary(oper, left, right)
	-- GitHub Copilot helped me create most of this, and I have yet to test it.
	if oper == AstNode.Kind.Add then
		if left.kind == AstNode.Kind.Number and right.kind == AstNode.Kind.Number then
			return AstNode.fromValue(AstNode.Kind.Number, left.value + right.value)
		end

	elseif oper == AstNode.Kind.Sub then
		if left.kind == AstNode.Kind.Number and right.kind == AstNode.Kind.Number then
			return AstNode.fromValue(AstNode.Kind.Number, left.value - right.value)
		end

	elseif oper == AstNode.Kind.Mul then
		if left.kind == AstNode.Kind.Number and right.kind == AstNode.Kind.Number then
			return AstNode.fromValue(AstNode.Kind.Number, left.value * right.value)
		end

	elseif oper == AstNode.Kind.Div then
		if left.kind == AstNode.Kind.Number and right.kind == AstNode.Kind.Number then
			return AstNode.fromValue(AstNode.Kind.Number, left.value / right.value)
		end

	elseif oper == AstNode.Kind.Pow then
		if left.kind == AstNode.Kind.Number and right.kind == AstNode.Kind.Number then
			return AstNode.fromValue(AstNode.Kind.Number, left.value ^ right.value)
		end

	elseif oper == AstNode.Kind.Concat then
		if left.kind == AstNode.Kind.String and right.kind == AstNode.Kind.String then
			return AstNode.fromValue(AstNode.Kind.String, left.value .. right.value)
		end

	elseif oper == AstNode.Kind.Mod then
		if left.kind == AstNode.Kind.Number and right.kind == AstNode.Kind.Number then
			return AstNode.fromValue(AstNode.Kind.Number, left.value % right.value)
		end

	elseif oper == AstNode.Kind.CompareNe then
		if left.kind == AstNode.Kind.Number and right.kind == AstNode.Kind.Number then
			return AstNode.fromValue(AstNode.Kind.Bool, left.value ~= right.value)
		end

	elseif oper == AstNode.Kind.CompareEq then
		if left.kind == AstNode.Kind.Number and right.kind == AstNode.Kind.Number then
			return AstNode.fromValue(AstNode.Kind.Bool, left.value == right.value)
		end

	elseif oper == AstNode.Kind.CompareLt then
		if left.kind == AstNode.Kind.Number and right.kind == AstNode.Kind.Number then
			return AstNode.fromValue(AstNode.Kind.Bool, left.value < right.value)
		end

	elseif oper == AstNode.Kind.CompareLe then
		if left.kind == AstNode.Kind.Number and right.kind == AstNode.Kind.Number then
			return AstNode.fromValue(AstNode.Kind.Bool, left.value <= right.value)
		end

	elseif oper == AstNode.Kind.CompareGt then
		if left.kind == AstNode.Kind.Number and right.kind == AstNode.Kind.Number then
			return AstNode.fromValue(AstNode.Kind.Bool, left.value > right.value)
		end

	elseif oper == AstNode.Kind.CompareGe then
		if left.kind == AstNode.Kind.Number and right.kind == AstNode.Kind.Number then
			return AstNode.fromValue(AstNode.Kind.Bool, left.value >= right.value)
		end
	
	elseif oper == AstNode.Kind.And then
		if left.kind == AstNode.Kind.Bool and right.kind == AstNode.Kind.Bool then
			return AstNode.fromValue(AstNode.Kind.Bool, left.value and right.value)
		end

	elseif oper == AstNode.Kind.Or then
		if left.kind == AstNode.Kind.Bool and right.kind == AstNode.Kind.Bool then
			return AstNode.fromValue(AstNode.Kind.Bool, left.value or right.value)
		end
	end

	return nil
end

return ConstantFolding