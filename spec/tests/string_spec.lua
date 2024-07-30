local assert = assert
---@cast assert -function,+nvl.test.luassert
-- require("luacov")

local t = require("spec.helpers.testutil")
local matches = t.matches
local pcall_err = t.pcall_err

local str = require("nvl.utils.modules.string")

describe("#unit #nvl.utils.string", function()
	it("str.pesc", function()
		assert.equal("foo%-bar", str.pesc("foo-bar"))
		assert.equal("foo%%%-bar", str.pesc(str.pesc("foo-bar")))
		-- pesc() returns one result. #20751
		assert.same({ "x" }, { str.pesc("x") })

		-- Validates args.
		matches(
			"s: expected string, got number",
			pcall_err(function()
				return str.pesc(2) ---@diagnostic disable-line:param-type-mismatch
			end)
		)
	end)
	it("str.startswith", function()
		assert.True(str.startswith("123", "1"))
		assert.True(str.startswith("123", ""))
		assert.True(str.startswith("123", "123"))
		assert.True(str.startswith("", ""))

		assert.False(str.startswith("123", " "))
		assert.False(str.startswith("123", "2"))
		assert.False(str.startswith("123", "1234"))

		matches(
			"prefix: expected string, got nil",
			pcall_err(function()
				return str.startswith("123", nil) ---@diagnostic disable-line:param-type-mismatch
			end)
		)
		matches(
			"s: expected string, got nil",
			pcall_err(function()
				return str.startswith(nil, "123") ---@diagnostic disable-line:param-type-mismatch
			end)
		)
	end)

	it("str.endswith", function()
		assert.True(str.endswith("123", "3"))
		assert.True(str.endswith("123", ""))
		assert.True(str.endswith("123", "123"))
		assert.True(str.endswith("", ""))

		assert.False(str.endswith("123", " "))
		assert.False(str.endswith("123", "2"))
		assert.False(str.endswith("123", "1234"))

		matches(
			"suffix: expected string, got nil",
			pcall_err(function()
				return str.endswith("123", nil) ---@diagnostic disable-line:param-type-mismatch
			end)
		)
		matches(
			"s: expected string, got nil",
			pcall_err(function()
				return str.endswith(nil, "123") ---@diagnostic disable-line:param-type-mismatch
			end)
		)
	end)
end)
