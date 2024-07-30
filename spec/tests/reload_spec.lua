local assert = assert
---@cast assert -function,+nvl.test.luassert

local luacache = (_G.__luacache or {}).cache ---@diagnostic disable-line:undefined-field
describe("#unit #nvl.utils.reload", function()
	before_each(function()
		package.loaded["nvl.utils.modules.types"] = nil
		if luacache then
			luacache["nvl.utils.modules.types"] = nil
		end
	end)
	insulate("reload.unload_module", function()
		it("unloads a loaded module", function()
			local reload = require("nvl.utils.modules.reload")
			assert.Nil(package.loaded["nvl.utils.modules.types"])

			if luacache then
				assert.Nil(luacache["nvl.utils.modules.types"])
			end

			require("nvl.utils.modules.types")
			assert(package.loaded["nvl.utils.modules.types"])
			reload.unload_module("nvl.utils.modules.types")
			assert.Nil(package.loaded["nvl.utils.modules.types"])

			if luacache then
				assert.Nil(luacache["nvl.utils.modules.types"])
			end
		end)
		it("calls reload.matcher_fact", function()
			local reload = require("nvl.utils.modules.reload")
			-- stub(reload, "matcher_fact")
			local spy_matcher_fact = spy.on(reload, "matcher_fact")

			reload.unload_module("nvl.utils.modules.types")
			assert.spy(spy_matcher_fact).was.called_with("nvl.utils.modules.types", true)
			spy_matcher_fact:clear()

			reload.unload_module("nvl.utils.modules.types", true)
			assert.spy(spy_matcher_fact).was.called_with("nvl.utils.modules.types", true)
			spy_matcher_fact:clear()

			reload.unload_module("nvl.utils.modules.types", false)
			assert.spy(spy_matcher_fact).was.called_with("nvl.utils.modules.types", false)
		end)

		it("calls _string.pesc", function()
			local reload = require("nvl.utils.modules.reload")
			local _string = require("nvl.utils.modules.string")
			local spy_pesc = spy.on(_string, "pesc")

			reload.unload_module("nvl.utils.modules", true)
			assert.spy(spy_pesc).was.called_with("nvl.utils.modules")
		end)

		it("calls reload.del_module", function()
			local reload = require("nvl.utils.modules.reload")
			local spy_matcher_fact = spy.on(reload, "matcher_fact")
			local spy_del_module = spy.on(reload, "del_module")

			-- local matcher = reload.matcher_fact("nvl.utils.modules", true)
			reload.unload_module("nvl.utils.modules", true)
			local returnvals = spy_matcher_fact.returnvals
			local matcher = returnvals[1].refs[1]
			assert.spy(spy_del_module).was.called_with(matcher, nil)
		end)
	end)

	describe("reload.reload_module", function()
		before_each(function()
			package.loaded["nvl.utils.modules.types"] = nil
			if luacache then
				luacache["nvl.utils.modules.types"] = nil
			end
		end)
		it("reload.reload_module", function()
			-- P(package.loaded["nvl.utils.modules.types"])
			assert.Nil(package.loaded["nvl.utils.modules.types"])
			local reload = require("nvl.utils.modules.reload")
			require("nvl.utils.modules.types")
			assert(package.loaded["nvl.utils.modules.types"])
			package.loaded["nvl.utils.modules.types"].PATCHED = 1
			assert(package.loaded["nvl.utils.modules.types"].PATCHED)
			reload.reload_module("nvl.utils.modules.types")
			assert(package.loaded["nvl.utils.modules.types"])
			assert.Nil(package.loaded["nvl.utils.modules.types"].PATCHED)
		end)
	end)
end)
