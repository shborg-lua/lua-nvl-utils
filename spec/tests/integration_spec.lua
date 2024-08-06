local assert = assert
---@cast assert -function,+nvl.test.luassert

describe("#unit #nvl.utils", function()
	before_each(function() end)
	local nvl_utils = require("nvl.utils")
	describe("exports", function()
		it("exports reload", function()
			assert.Table(nvl_utils.reloader)
			assert.Callable(nvl_utils.reloader)
		end)
	end)
end)
