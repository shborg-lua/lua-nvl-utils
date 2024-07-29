local M = {}

--- Tests if `t` is an "array": a table indexed _only_ by integers
--- (potentially non-contiguous). If the indexes start from 1 and
--- are contiguous then the array is also a list.
--- @see M.islist()
---
--- Empty table `{}` is an array, too.
---
---@see https://github.com/openresty/luajit2#tableisarray
---
---@param t? table
---@return boolean `true` if array-like table, else `false`.
function M.isarray(t)
	if type(t) ~= "table" then
		return false
	end

	if M.islist(t) then
		return true
	end

	--- @cast t table<any,any>

	local count = 0

	for k, _ in pairs(t) do
		-- Check if the number k is an integer
		if type(k) == "number" and k == math.floor(k) then
			count = count + 1
		else
			return false
		end
	end

	if count > 0 then
		return true
	end
	return false
end

--- Tests if `t` is a "list": a table indexed _only_ by contiguous integers starting
--- from 1 (what lua-length calls a "regular array").
---
--- Empty table `{}` is a list, too.
---
---@see M.isarray()
---
---@param t? table
---@return boolean `true` if list-like table, else `false`.
function M.islist(t)
	if type(t) ~= "table" then
		return false
	end

	local j = 1
	for _ in
		pairs(t--[[@as table<any,any>]])
	do
		if t[j] == nil then
			return false
		end
		j = j + 1
	end

	return true
end

--- Returns true if object `f` can be called as a function.
---
---@param f any Any object
---@return boolean `true` if `f` is callable, else `false`
function M.iscallable(f)
	if type(f) == "function" then
		return true
	end
	local m = getmetatable(f)
	if m == nil then
		return false
	end
	return type(rawget(m, "__call")) == "function"
end

return M
