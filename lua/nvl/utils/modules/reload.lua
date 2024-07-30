---
--- @see plenary.nvim/lua/plenary/reload.lua
---

local _string = require("nvl.utils.modules.string")
local reload = {}
reload.del_module = function(matcher, f)
	-- Handle impatient.nvim automatically.
	local luacache = (_G.__luacache or {}).cache ---@diagnostic disable-line:undefined-field
	f = f or function(p)
		package.loaded[p] = nil

		if luacache then
			luacache[p] = nil
		end
	end
	for pack, _ in pairs(package.loaded) do
		if matcher(pack) then
			f(pack)
		end
	end
end

reload.matcher_fact = function(module_name, starts_with_only)
	local matcher
	if not starts_with_only then
		matcher = function(pack)
			return string.find(pack, module_name, 1, true)
		end
	else
		local module_name_pattern = _string.pesc(module_name)
		matcher = function(pack)
			return string.find(pack, "^" .. module_name_pattern)
		end
	end
	return matcher
end

reload.unload_module = function(module_name, starts_with_only, f)
	-- Default to starts with only
	if starts_with_only == nil then
		starts_with_only = true
	end

	-- TODO: Might need to handle cpath / compiled lua packages? Not sure.
	local matcher = reload.matcher_fact(module_name, starts_with_only)

	reload.del_module(matcher, f)
	-- Handle impatient.nvim automatically.
	-- local luacache = (_G.__luacache or {}).cache ---@diagnostic disable-line:undefined-field
	--
	-- for pack, _ in pairs(package.loaded) do
	-- 	if matcher(pack) then
	-- 		package.loaded[pack] = nil
	--
	-- 		if luacache then
	-- 			luacache[pack] = nil
	-- 		end
	-- 	end
	-- end
end

reload.reload_module = function(module_name, starts_with_only)
	reload.unload_module(module_name, starts_with_only)
	return require(module_name)
end
return reload
