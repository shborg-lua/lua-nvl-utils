-- @see neovim/runtime/lua/shared.lua

---@nodoc
---@diagnostic disable-next-line: lowercase-global
local M = {}

M.NIL = "\0"

---@generic T
---@param orig T
---@param cache? table<any,any>
---@return T
local function deepcopy(orig, cache)
	if orig == M.NIL then
		return M.NIL
	elseif type(orig) == "userdata" or type(orig) == "thread" then
		error("Cannot deepcopy object of type " .. type(orig))
	elseif type(orig) ~= "table" then
		return orig
	end

	--- @cast orig table<any,any>

	if cache and cache[orig] then
		return cache[orig]
	end

	local copy = {} --- @type table<any,any>

	if cache then
		cache[orig] = copy
	end

	for k, v in pairs(orig) do
		copy[deepcopy(k, cache)] = deepcopy(v, cache)
	end

	return setmetatable(copy, getmetatable(orig))
end

--- Returns a deep copy of the given object. Non-table objects are copied as
--- in a typical Lua assignment, whereas table objects are copied recursively.
--- Functions are naively copied, so functions in the copied table point to the
--- same functions as those in the input table. Userdata and threads are not
--- copied and will throw an error.
---
--- Note: `noref=true` is much more performant on tables with unique table
--- fields, while `noref=false` is more performant on tables that reuse table
--- fields.
---
---@generic T: table
---@param orig T Table to copy
---@param noref? boolean
--- When `false` (default) a contained table is only copied once and all
--- references point to this single copy. When `true` every occurrence of a
--- table results in a new copy. This also means that a cyclic reference can
--- cause `deepcopy()` to fail.
---@return T Table of copied keys and (nested) values.
function M.deepcopy(orig, noref)
	return deepcopy(orig, not noref and {} or nil)
end

return M
