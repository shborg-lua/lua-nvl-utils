local assert = assert
---@cast assert -function,+nvl.test.luassert
-- require("luacov")

local t = require("spec.helpers.testutil")
local matches = t.matches
local ok = t.ok
local pcall_err = t.pcall_err

local tbl = require("nvl.utils.modules.table")
local types = require("nvl.utils.modules.types")

--TODO: what todo with this?
-- local NIL = vim and vim.NIL or nil
local NIL = nil

describe("#unit #nvl.utils.table", function()
	it("tbl.list_contains", function()
		assert.True(tbl.list_contains({ "a", "b", "c" }, "c"))
		assert.True(tbl.list_contains({ "a", "b", "c" }, "c"))
		assert.False(tbl.list_contains({ "a", "b", "c" }, "d"))
	end)

	it("tbl.tbl_contains", function()
		assert.True(tbl.tbl_contains({ "a", "b", "c" }, "c"))
		assert.False(tbl.tbl_contains({ "a", "b", "c" }, "d"))
		assert.True(tbl.tbl_contains({ [2] = "a", foo = "b", [5] = "c" }, "c"))

		assert.same(
			true,
			(function()
				return tbl.tbl_contains({ "a", { "b", "c" } }, function(v)
					return tbl.deep_equal(v, { "b", "c" })
				end, { predicate = true })
			end)()
		)
	end)

	it("tbl.tbl_keys", function()
		assert.same({}, tbl.tbl_keys({}))
		for _, v in pairs(tbl.tbl_keys({ "a", "b", "c" })) do
			assert.True(tbl.tbl_contains({ 1, 2, 3 }, v))
		end
		for _, v in pairs(tbl.tbl_keys({ a = 1, b = 2, c = 3 })) do
			assert.True(tbl.tbl_contains({ "a", "b", "c" }, v))
		end
	end)

	it("tbl.tbl_values", function()
		assert.same({}, tbl.tbl_values({}))
		for _, v in pairs(tbl.tbl_values({ "a", "b", "c" })) do
			assert.True(tbl.tbl_contains({ "a", "b", "c" }, v))
		end
		for _, v in pairs(tbl.tbl_values({ a = 1, b = 2, c = 3 })) do
			assert.True(tbl.tbl_contains({ 1, 2, 3 }, v))
		end
	end)

	it("tbl.tbl_map", function()
		assert.same(
			{},
			tbl.tbl_map(function(v)
				return v * 2
			end, {})
		)
		assert.same(
			{ 2, 4, 6 },
			tbl.tbl_map(function(v)
				return v * 2
			end, { 1, 2, 3 })
		)
		assert.same(
			{ { i = 2 }, { i = 4 }, { i = 6 } },
			tbl.tbl_map(function(v)
				return { i = v.i * 2 }
			end, { { i = 1 }, { i = 2 }, { i = 3 } })
		)
	end)

	it("tbl.tbl_filter", function()
		assert.same(
			{},
			tbl.tbl_filter(function(v)
				return (v % 2) == 0
			end, {})
		)
		assert.same(
			{ 2 },
			tbl.tbl_filter(function(v)
				return (v % 2) == 0
			end, { 1, 2, 3 })
		)
		assert.same(
			{ { i = 2 } },
			tbl.tbl_filter(function(v)
				return (v.i % 2) == 0
			end, { { i = 1 }, { i = 2 }, { i = 3 } })
		)
	end)
	it("tbl.tbl_isempty", function()
		assert.True(tbl.tbl_isempty({}))
		assert.False(tbl.tbl_isempty({ 1, 2, 3 }))
		assert.False(tbl.tbl_isempty({ a = 1, b = 2, c = 3 }))
	end)

	it("tbl.tbl_get", function()
		assert.True(tbl.tbl_get({ test = { nested_test = true } }, "test", "nested_test"))
		assert.same(NIL, tbl.tbl_get({ unindexable = true }, "unindexable", "missing_key"))
		assert.same(NIL, tbl.tbl_get({ unindexable = 1 }, "unindexable", "missing_key"))
		assert.same(NIL, tbl.tbl_get({ unindexable = coroutine.create(function() end) }, "unindexable", "missing_key"))
		-- assert.same(NIL, tbl.tbl_get({ unindexable = function() end }, "unindexable", "missing_key"))
		assert.same(NIL, tbl.tbl_get({}, "missing_key"))
		assert.same(NIL, tbl.tbl_get({}))
		assert.same(1, select("#", tbl.tbl_get({})))
		assert.same(1, select("#", tbl.tbl_get({ nested = {} }, "nested", "missing_key")))
	end)

	it("tbl.tbl_extend", function()
		ok((function()
			local a = { x = 1 }
			local b = { y = 2 }
			local c = tbl.tbl_extend("keep", a, b)
			return c.x == 1 and b.y == 2 and tbl.tbl_count(c) == 2
		end)())

		ok((function()
			local a = { x = 1 }
			local b = { y = 2 }
			local c = { z = 3 }
			local d = tbl.tbl_extend("keep", a, b, c)

			return d.x == 1 and d.y == 2 and d.z == 3 and tbl.tbl_count(d) == 3
		end)())

		ok((function()
			local a = { x = 1 }
			local b = { x = 3 }
			local c = tbl.tbl_extend("keep", a, b)

			return c.x == 1 and tbl.tbl_count(c) == 1
		end)())

		ok((function()
			local a = { x = 1 }
			local b = { x = 3 }
			local c = tbl.tbl_extend("force", a, b)

			return c.x == 3 and tbl.tbl_count(c) == 1
		end)())

		ok((function()
			local a = {}
			local b = {}
			local c = tbl.tbl_extend("keep", a, b)

			return types.islist(c) and tbl.tbl_count(c) == 0
		end)())

		ok((function()
			local a = { x = { a = 1, b = 2 } }
			local b = { x = { a = 2, c = { y = 3 } } }
			local c = tbl.tbl_extend("keep", a, b)

			local count = 0
			for _ in pairs(c) do
				count = count + 1
			end

			return c.x.a == 1 and c.x.b == 2 and c.x.c == nil and count == 1
		end)())

		matches(
			'invalid "behavior": nil',
			pcall_err(function()
				return tbl.tbl_extend() ---@diagnostic disable-line:missing-parameter
			end)
		)

		matches(
			"wrong number of arguments %(given 1, expected at least 3%)",
			pcall_err(function()
				return tbl.tbl_extend("keep")
			end)
		)

		matches(
			"wrong number of arguments %(given 2, expected at least 3%)",
			pcall_err(function()
				return tbl.tbl_extend("keep", {})
			end)
		)
	end)

	it("tbl.tbl_deep_extend", function()
		ok((function()
			local a = { x = { a = 1, b = 2 } }
			local b = { x = { a = 2, c = { y = 3 } } }
			local c = tbl.tbl_deep_extend("keep", a, b)

			local count = 0
			for _ in pairs(c) do
				count = count + 1
			end

			return c.x.a == 1 and c.x.b == 2 and c.x.c.y == 3 and count == 1
		end)())

		ok((function()
			local a = { x = { a = 1, b = 2 } }
			local b = { x = { a = 2, c = { y = 3 } } }
			local c = tbl.tbl_deep_extend("force", a, b)

			local count = 0
			for _ in pairs(c) do
				count = count + 1
			end

			return c.x.a == 2 and c.x.b == 2 and c.x.c.y == 3 and count == 1
		end)())

		ok((function()
			local a = { x = { a = 1, b = 2 } }
			local b = { x = { a = 2, c = { y = 3 } } }
			local c = { x = { c = 4, d = { y = 4 } } }
			local d = tbl.tbl_deep_extend("keep", a, b, c)

			local count = 0
			for _ in pairs(c) do
				count = count + 1
			end

			return d.x.a == 1 and d.x.b == 2 and d.x.c.y == 3 and d.x.d.y == 4 and count == 1
		end)())

		ok((function()
			local a = { x = { a = 1, b = 2 } }
			local b = { x = { a = 2, c = { y = 3 } } }
			local c = { x = { c = 4, d = { y = 4 } } }
			local d = tbl.tbl_deep_extend("force", a, b, c)

			local count = 0
			for _ in pairs(c) do
				count = count + 1
			end

			return d.x.a == 2 and d.x.b == 2 and d.x.c == 4 and d.x.d.y == 4 and count == 1
		end)())

		ok((function()
			local a = {}
			local b = {}
			local c = tbl.tbl_deep_extend("keep", a, b)

			local count = 0
			for _ in pairs(c) do
				count = count + 1
			end

			return types.islist(c) and count == 0
		end)())

		assert.same(
			{ a = { b = 1 } },
			(function()
				local a = { a = { b = 1 } }
				local b = { a = {} }
				return tbl.tbl_deep_extend("force", a, b)
			end)()
		)

		assert.same(
			{ a = { b = 1 } },
			(function()
				local a = { a = 123 }
				local b = { a = { b = 1 } }
				return tbl.tbl_deep_extend("force", a, b)
			end)()
		)

		ok((function()
			local a = { a = { [2] = 3 } }
			local b = { a = { [3] = 3 } }
			local c = tbl.tbl_deep_extend("force", a, b)
			return tbl.deep_equal(c, { a = { [3] = 3 } })
		end)())

		assert.same(
			{ a = 123 },
			(function()
				local a = { a = { b = 1 } }
				local b = { a = 123 }
				return tbl.tbl_deep_extend("force", a, b)
			end)()
		)

		matches(
			'invalid "behavior": nil',
			pcall_err(function()
				return tbl.tbl_deep_extend() ---@diagnostic disable-line:missing-parameter
			end)
		)

		matches(
			"wrong number of arguments %(given 1, expected at least 3%)",
			pcall_err(function()
				return tbl.tbl_deep_extend("keep")
			end)
		)

		matches(
			"wrong number of arguments %(given 2, expected at least 3%)",
			pcall_err(function()
				return tbl.tbl_deep_extend("keep", {})
			end)
		)
	end)

	it("tbl.tbl_count", function()
		assert.same(0, tbl.tbl_count({}))
		assert.same(0, tbl.tbl_count({ nil }))
		assert.same(0, tbl.tbl_count({ a = nil }))
		assert.same(1, tbl.tbl_count({ 1 }))
		assert.same(2, tbl.tbl_count({ 1, 2 }))
		assert.same(2, tbl.tbl_count({ 1, nil, 3 }))
		assert.same(1, tbl.tbl_count({ a = 1 }))
		assert.same(2, tbl.tbl_count({ a = 1, b = 2 }))
		assert.same(2, tbl.tbl_count({ a = 1, b = nil, c = 3 }))
	end)
	--
	it("tbl.deep_equal", function()
		assert.True(tbl.deep_equal({ a = 1 }, { a = 1 }))
		assert.True(tbl.deep_equal({ a = { b = 1 } }, { a = { b = 1 } }))
		assert.True(tbl.deep_equal({ a = { b = { nil } } }, { a = { b = {} } }))
		assert.True(tbl.deep_equal({ a = 1, [5] = 5 }, { nil, nil, nil, nil, 5, a = 1 }))
		assert.False(tbl.deep_equal(1, { nil, nil, nil, nil, 5, a = 1 }))
		assert.False(tbl.deep_equal(1, 3))
		assert.False(tbl.deep_equal(nil, 3))
		assert.False(tbl.deep_equal({ a = 1 }, { a = 2 }))
	end)
	--
	it("tbl.list_extend", function()
		assert.same({ 1, 2, 3 }, tbl.list_extend({ 1 }, { 2, 3 }))
		matches(
			"M.list_extend: expected src as table",
			pcall_err(function()
				tbl.list_extend({ 1 }, nil) ---@diagnostic disable-line:param-type-mismatch
			end)
		)
		assert.same({ 1, 2 }, tbl.list_extend({ 1 }, { 2, a = 1 }))
		-- assert.True({ a = { 1 } }, tbl.list_extend(a, { 2, a = 1 }) == a)
		assert.same({ 2 }, tbl.list_extend({}, { 2, a = 1 }, 1))
		assert.same({}, tbl.list_extend({}, { 2, a = 1 }, 2))
		assert.same({}, tbl.list_extend({}, { 2, a = 1 }, 1, -1))
		assert.same({ 2 }, tbl.list_extend({}, { 2, a = 1 }, -1, 2))
	end)
	--
	-- it("tbl.tbl_add_reverse_lookup", function()
	-- 	assert.same(
	-- 		true,
	-- 		exec_lua([[
	--    local a = { A = 1 }
	--    tbl.tbl_add_reverse_lookup(a)
	--    return tbl.deep_equal(a, { A = 1; [1] = 'A'; })
	--    ]])
	-- 	)
	-- 	-- Throw an error for trying to do it twice (run into an existing key)
	-- 	local code = [[
	--    local res = {}
	--    local a = { A = 1 }
	--    tbl.tbl_add_reverse_lookup(a)
	--    assert(tbl.deep_equal(a, { A = 1; [1] = 'A'; }))
	--    tbl.tbl_add_reverse_lookup(a)
	--    ]]
	-- 	matches(
	-- 		'The reverse lookup found an existing value for "[1A]" while processing key "[1A]"$',
	-- 		pcall_err(exec_lua, code)
	-- 	)
	-- end)
	--
	it("tbl.spairs", function()
		local res = ""
		local table = {
			ccc = 1,
			bbb = 2,
			ddd = 3,
			aaa = 4,
		}
		for key, _ in tbl.spairs(table) do
			res = res .. key
		end
		matches("aaabbbcccddd", res)
	end)
end)
