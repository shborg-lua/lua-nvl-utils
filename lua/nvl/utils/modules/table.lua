local M = {}

local isarray = require("nvl.utils.modules.types").isarray

--- Return a list of all keys used in a table.
--- However, the order of the return table of keys is not guaranteed.
---
---@see From https://github.com/premake/premake-core/blob/master/src/base/table.lua
---
---@generic T
---@param t table<T, any> (table) Table
---@return T[] : List of keys
function M.tbl_keys(t)
	assert(type(t) == "table", "M.tbl_keys: expected t as table")
	--- @cast t table<any,any>

	local keys = {}
	for k in pairs(t) do
		table.insert(keys, k)
	end
	return keys
end

--- Return a list of all values used in a table.
--- However, the order of the return table of values is not guaranteed.
---
---@generic T
---@param t table<any, T> (table) Table
---@return T[] : List of values
function M.tbl_values(t)
	assert(type(t) == "table", "M.tbl_values: expected t as table")

	local values = {}
	for _, v in
		pairs(t --[[@as table<any,any>]])
	do
		table.insert(values, v)
	end
	return values
end

--- Apply a function to all values of a table.
---
---@generic T
---@param func fun(value: T): any Function
---@param t table<any, T> Table
---@return table : Table of transformed values
function M.tbl_map(func, t)
	assert(type(func) == "function", "M.tbl_map: expected func as function")
	assert(type(t) == "table", "M.tbl_values: expected t as table")
	--- @cast t table<any,any>

	local rettab = {} --- @type table<any,any>
	for k, v in pairs(t) do
		rettab[k] = func(v)
	end
	return rettab
end

--- Filter a table using a predicate function
---
---@generic T
---@param func fun(value: T): boolean (function) Function
---@param t table<any, T> (table) Table
---@return T[] : Table of filtered values
function M.tbl_filter(func, t)
	assert(type(func) == "function", "M.tbl_filter: expected func as function")
	assert(type(t) == "table", "M.tbl_filter: expected t as table")
	--- @cast t table<any,any>

	local rettab = {} --- @type table<any,any>
	for _, entry in pairs(t) do
		if func(entry) then
			rettab[#rettab + 1] = entry
		end
	end
	return rettab
end

--- @class M.tbl_contains.Opts
--- @inlinedoc
---
--- `value` is a function reference to be checked (default false)
--- field predicate? boolean

--- Checks if a table contains a given value, specified either directly or via
--- a predicate that is checked for each value.
---
--- Example:
---
--- ```lua
--- M.tbl_contains({ 'a', { 'b', 'c' } }, function(v)
---   return M.deep_equal(v, { 'b', 'c' })
--- end, { predicate = true })
--- -- true
--- ```
---
---@see M.list_contains() for checking values in list-like tables
---
---@param t table Table to check
---@param value any Value to compare or predicate function reference
---@param opts? M.tbl_contains.Opts Keyword arguments |kwargs|:
---@return boolean `true` if `t` contains `value`
function M.tbl_contains(t, value, opts)
	assert(type(t) == "table", "M.tbl_contains: expected t as table")
	--- @cast t table<any,any>

	local pred --- @type fun(v: any): boolean?
	if opts and opts.predicate then
		-- M.validate({ value = { value, "c" } })
		pred = value
	else
		pred = function(v)
			return v == value
		end
	end

	for _, v in pairs(t) do
		if pred(v) then
			return true
		end
	end
	return false
end

--- Checks if a list-like table (integer keys without gaps) contains `value`.
---
---@see M.tbl_contains() for checking values in general tables
---
---@param t table Table to check (must be list-like, not validated)
---@param value any Value to compare
---@return boolean `true` if `t` contains `value`
function M.list_contains(t, value)
	assert(type(t) == "table", "M.list_contains: expected t as table")
	--- @cast t table<any,any>

	for _, v in ipairs(t) do
		if v == value then
			return true
		end
	end
	return false
end

--- Checks if a table is empty.
---
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---
---@param t table Table to check
---@return boolean `true` if `t` is empty
function M.tbl_isempty(t)
	assert(type(t) == "table", "M.tbl_isempty: expected t as table")
	return next(t) == nil
end

--- We only merge empty tables or tables that are not an array (indexed by integers)
local function can_merge(v)
	return type(v) == "table" and (M.tbl_isempty(v) or not isarray(v))
end

local function tbl_extend(behavior, deep_extend, ...)
	if behavior ~= "error" and behavior ~= "keep" and behavior ~= "force" then
		error('invalid "behavior": ' .. tostring(behavior))
	end

	if select("#", ...) < 2 then
		error("wrong number of arguments (given " .. tostring(1 + select("#", ...)) .. ", expected at least 3)")
	end

	local ret = {} --- @type table<any,any>

	for i = 1, select("#", ...) do
		local tbl = select(i, ...)
		assert(type(tbl) == "table", "M.tbl_extend: expected tbl as table")
		--- @cast tbl table<any,any>
		if tbl then
			for k, v in pairs(tbl) do
				if deep_extend and can_merge(v) and can_merge(ret[k]) then
					ret[k] = tbl_extend(behavior, true, ret[k], v)
				elseif behavior ~= "force" and ret[k] ~= nil then
					if behavior == "error" then
						error("key found in more than one map: " .. k)
					end -- Else behavior is "keep".
				else
					ret[k] = v
				end
			end
		end
	end
	return ret
end

--- Merges two or more tables.
---
---@see extend()
---
---@param behavior 'error'|'keep'|'force' Decides what to do if a key is found in more than one map:
---      - "error": raise an error
---      - "keep":  use value from the leftmost map
---      - "force": use value from the rightmost map
---@param ... table Two or more tables
---@return table : Merged table
function M.tbl_extend(behavior, ...)
	return tbl_extend(behavior, false, ...)
end

--- Merges recursively two or more tables.
---
---@see M.tbl_extend()
---
---@generic T1: table
---@generic T2: table
---@param behavior 'error'|'keep'|'force' Decides what to do if a key is found in more than one map:
---      - "error": raise an error
---      - "keep":  use value from the leftmost map
---      - "force": use value from the rightmost map
---@param ... T2 Two or more tables
---@return T1|T2 (table) Merged table
function M.tbl_deep_extend(behavior, ...)
	return tbl_extend(behavior, true, ...)
end

--- Deep compare values for equality
---
--- Tables are compared recursively unless they both provide the `eq` metamethod.
--- All other types are compared using the equality `==` operator.
---@param a any First value
---@param b any Second value
---@return boolean `true` if values are equals, else `false`
function M.deep_equal(a, b)
	if a == b then
		return true
	end
	if type(a) ~= type(b) then
		return false
	end
	if type(a) == "table" then
		--- @cast a table<any,any>
		--- @cast b table<any,any>
		for k, v in pairs(a) do
			if not M.deep_equal(v, b[k]) then
				return false
			end
		end
		for k in pairs(b) do
			if a[k] == nil then
				return false
			end
		end
		return true
	end
	return false
end

--- Index into a table (first argument) via string keys passed as subsequent arguments.
--- Return `nil` if the key does not exist.
---
--- Examples:
---
--- ```lua
--- M.tbl_get({ key = { nested_key = true }}, 'key', 'nested_key') == true
--- M.tbl_get({ key = {}}, 'key', 'nested_key') == nil
--- ```
---
---@param o table Table to index
---@param ... any Optional keys (0 or more, variadic) via which to index the table
---@return any # Nested value indexed by key (if it exists), else nil
function M.tbl_get(o, ...)
	local keys = { ... }
	if #keys == 0 then
		return nil
	end
	for i, k in ipairs(keys) do
		o = o[k] --- @type any
		if o == nil then
			return nil
		elseif type(o) ~= "table" and next(keys, i) then
			return nil
		end
	end
	return o
end

--- Extends a list-like table with the values of another list-like table.
---
--- NOTE: This mutates dst!
---
---@see M.tbl_extend()
---
---@generic T: table
---@param dst T List which will be modified and appended to
---@param src table List from which values will be inserted
---@param start integer? Start index on src. Defaults to 1
---@param finish integer? Final index on src. Defaults to `#src`
---@return T dst
function M.list_extend(dst, src, start, finish)
	assert(type(dst) == "table", "M.list_extend: expected dst as table")
	assert(type(src) == "table", "M.list_extend: expected src as table")
	assert((not start) or (start and type(start) == "number"), "M.list_extend: expected start as number")
	assert((not finish) or (finish and type(finish) == "number"), "M.list_extend: expected start as number")

	for i = start or 1, finish or #src do
		table.insert(dst, src[i])
	end
	return dst
end

-- --- @deprecated
-- --- Creates a copy of a list-like table such that any nested tables are
-- --- "unrolled" and appended to the result.
-- ---
-- ---@see From https://github.com/premake/premake-core/blob/master/src/base/table.lua
-- ---
-- ---@param t table List-like table
-- ---@return table Flattened copy of the given list-like table
-- function M.tbl_flatten(t)
-- 	M.deprecate("M.tbl_flatten", "M.iter(…):flatten():totable()", "0.13")
--
-- 	local result = {}
-- 	--- @param _t table<any,any>
-- 	local function _tbl_flatten(_t)
-- 		local n = #_t
-- 		for i = 1, n do
-- 			local v = _t[i]
-- 			if type(v) == "table" then
-- 				_tbl_flatten(v)
-- 			elseif v then
-- 				table.insert(result, v)
-- 			end
-- 		end
-- 	end
-- 	_tbl_flatten(t)
-- 	return result
-- end
--
--- Enumerates key-value pairs of a table, ordered by key.
---
---@see Based on https://github.com/premake/premake-core/blob/master/src/base/table.lua
---
---@generic T: table, K, V
---@param t T Dict-like table
---@return fun(table: table<K, V>, index?: K):K, V # |for-in| iterator over sorted keys and their values
---@return T
function M.spairs(t)
	assert(type(t) == "table", "M.spairs: expected t as table")
	--- @cast t table<any,any>

	-- collect the keys
	local keys = {}
	for k in pairs(t) do
		table.insert(keys, k)
	end
	table.sort(keys)

	-- Return the iterator function.
	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end, t
end

--- Counts the number of non-nil values in table `t`.
---
--- ```lua
--- M.tbl_count({ a=1, b=2 })  --> 2
--- M.tbl_count({ 1, 2 })      --> 2
--- ```
---
---@see https://github.com/Tieske/Penlight/blob/master/lua/pl/tablex.lua
---@param t table Table
---@return integer : Number of non-nil values in table
function M.tbl_count(t)
	assert(type(t) == "table", "M.tbl_count: expected t as table")
	--- @cast t table<any,any>

	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

--- Creates a copy of a table containing only elements from start to end (inclusive)
---
---@generic T
---@param list T[] Table
---@param start integer|nil Start range of slice
---@param finish integer|nil End range of slice
---@return T[] Copy of table sliced from start to finish (inclusive)
function M.list_slice(list, start, finish)
	local new_list = {} --- @type `T`[]
	for i = start or 1, finish or #list do
		new_list[#new_list + 1] = list[i]
	end
	return new_list
end

return M
