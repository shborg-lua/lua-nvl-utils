---
--- @see plenary.nvim/lua/plenary/reload.lua
---

local _string = require("nvl.utils.modules.string")
local reload = {}

---comment
---@param matcher fun(pack:string) Predicate to match a package name
---@param f fun(pack:string):boolean
---@return table
reload.del_module = function(matcher, f)
	-- Handle impatient.nvim automatically.
	local luacache = (_G.__luacache or {}).cache ---@diagnostic disable-line:undefined-field
	f = f or function(p)
		package.loaded[p] = nil

		if luacache then
			luacache[p] = nil
		end
		return true
	end
	local module_reloaded = {}
	for pack, _ in pairs(package.loaded) do
		-- print("del_module: trying " .. tostring(pack))
		if matcher(pack) then
			print("MATCH module " .. tostring(pack))
			module_reloaded[#module_reloaded + 1] = pack
			f(pack)
		end
	end
	return module_reloaded
end

---comment
---@param module_name string
---@param starts_with_only boolean
---@return function
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

---comment
---@param module_name string
---@param starts_with_only boolean
---@param f fun(pack:string):boolean
---@return table
reload.unload = function(module_name, starts_with_only, f)
	-- Default to starts with only
	if starts_with_only == nil then
		starts_with_only = true
	end

	-- TODO: Might need to handle cpath / compiled lua packages? Not sure.
	local matcher = reload.matcher_fact(module_name, starts_with_only)

	local modules_reloaded = reload.del_module(matcher, f)
	return modules_reloaded
end

---comment
---@param msg string
---@param modules string[]
reload.notify = function(msg, modules)
	local chunks = {
		{ msg .. "\n", "Special" },
	}
	for _, mod_name in ipairs(modules) do
		chunks[#chunks + 1] = { mod_name .. "\n", "WarningMsg" }
	end
	vim.api.nvim_echo(chunks, false, {})
end

---@alias nvl.utils.modules.reloader.ReloadOptions {silent:boolean, module_unloader:fun(pack:string):boolean}

---comment
---@param module_name string
---@param starts_with_only boolean
---@param opts? nvl.utils.modules.reloader.ReloadOptions
reload.reload = function(module_name, starts_with_only, opts)
	local silent = true
	local module_unloader
	if type(opts) == "table" then
		module_unloader = opts.module_unloader
		if type(opts.silent) == "boolean" then
			silent = opts.silent
		end
	end

	local modules_reloaded = reload.unload(module_name, starts_with_only, module_unloader)
	if not silent then
		reload.notify("reloaded modules", modules_reloaded)
	end
	if type(modules_reloaded) == "table" then
		for _, mod_name in ipairs(modules_reloaded) do
			return require(mod_name)
		end
	end
end
return reload
