local assert = assert
---@cast assert -function,+nvl.test.luassert
-- require("luacov")

local types = require("nvl.utils.modules.types")

describe("#unit #nvl.utils.types", function()
	it("types.isarray", function()
		assert.True(types.isarray({}))
		assert.True(types.isarray({ "a", "b", "c" }))
		assert.False(types.isarray({ "a", "32", a = "hello", b = "baz" }))
		assert.False(types.isarray({ 1, a = "hello", b = "baz" }))
		assert.False(types.isarray({ a = "hello", b = "baz", 1 }))
		assert.False(types.isarray({ 1, 2, nil, a = "hello" }))
		assert.True(types.isarray({ 1, 2, nil, 4 }))
		assert.True(types.isarray({ nil, 2, 3, 4 }))
		assert.False(types.isarray({ 1, [1.5] = 2, [3] = 3 }))
	end)

	it("types.islist", function()
		assert.True(types.islist({}))
		assert.True(types.islist({ "a", "b", "c" }))
		assert.False(types.islist({ "a", "32", a = "hello", b = "baz" }))
		assert.False(types.islist({ 1, a = "hello", b = "baz" }))
		assert.False(types.islist({ a = "hello", b = "baz", 1 }))
		assert.False(types.islist({ 1, 2, nil, a = "hello" }))
		assert.False(types.islist({ 1, 2, nil, 4 }))
		assert.False(types.islist({ nil, 2, 3, 4 }))
		assert.False(types.islist({ 1, [1.5] = 2, [3] = 3 }))
	end)

	it("types.iscallable", function()
		assert.True(types.iscallable(function() end))
		assert.True((function()
			local meta = { __call = function() end }
			local function new_callable()
				return setmetatable({}, meta)
			end
			local callable = new_callable()
			return types.iscallable(callable)
		end)())

		assert.same(
			{ false, false },
			(function()
				local meta = { __call = {} }
				assert(meta.__call)
				local function new()
					return setmetatable({}, meta)
				end
				local not_callable = new()
				return { pcall(function()
					not_callable()
				end), types.iscallable(not_callable) }
			end)()
		)

		assert.same(
			{ false, false },
			(function()
				local function new()
					return { __call = function() end }
				end
				local not_callable = new()
				assert(not_callable.__call)
				return { pcall(function()
					not_callable()
				end), types.iscallable(not_callable) }
			end)()
		)
		assert.same(
			{ false, false },
			(function()
				local meta = setmetatable(
					{ __index = { __call = function() end } },
					{ __index = { __call = function() end } }
				)
				assert(meta.__call)
				local not_callable = setmetatable({}, meta)
				assert(not_callable.__call)
				return { pcall(function()
					not_callable()
				end), types.iscallable(not_callable) }
			end)()
		)
		assert.same(
			{ false, false },
			(function()
				local meta = setmetatable({
					__index = function()
						return function() end
					end,
				}, {
					__index = function()
						return function() end
					end,
				})
				assert(meta.__call)
				local not_callable = setmetatable({}, meta)
				assert(not_callable.__call)
				return { pcall(function()
					not_callable()
				end), types.iscallable(not_callable) }
			end)()
		)
		assert.False(types.iscallable(1))
		assert.False(types.iscallable("foo"))
		assert.False(types.iscallable({}))
	end)
end)
