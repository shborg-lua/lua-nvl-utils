local M = {}
--- Escapes magic chars in lua-patterns.
---
---@see https://github.com/rxi/lume
---@param s string String to escape
---@return string %-escaped pattern string
function M.pesc(s)
	assert(type(s) == "string", "s: expected string, got " .. type(s))
	return (s:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1"))
end

--- Tests if `s` starts with `prefix`.
---
---@param s string String
---@param prefix string Prefix to match
---@return boolean `true` if `prefix` is a prefix of `s`
function M.startswith(s, prefix)
	assert(type(s) == "string", "s: expected string, got " .. type(s))
	assert(type(prefix) == "string", "prefix: expected string, got " .. type(prefix))
	return s:sub(1, #prefix) == prefix
end

--- Tests if `s` ends with `suffix`.
---
---@param s string String
---@param suffix string Suffix to match
---@return boolean `true` if `suffix` is a suffix of `s`
function M.endswith(s, suffix)
	assert(type(s) == "string", "s: expected string, got " .. type(s))
	assert(type(suffix) == "string", "suffix: expected string, got " .. type(suffix))
	return #suffix == 0 or s:sub(-#suffix) == suffix
end

return M
