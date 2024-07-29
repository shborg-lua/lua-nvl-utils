---@class nvl.utils.Config: nvl.utils.ConfigOptions
local M = {}

local deepcopy = require("nvl.utils.modules.deepcopy").deepcopy
local tbl_deep_extend = require("nvl.utils.modules.table").tbl_deep_extend

M.version = "1.1.0" -- x-release-please-version

---@class nvl.utils.ConfigOptions
local defaults = {

	exports = {
		globals = {
			table = {

				keys = "tbl_keys",
				values = "tbl_values",
				map = "tbl_map",
				filter = "tbl_filter",
				contains = "tbl_contains",
				get = "tbl_get",
				--TODO
				set = "tbl_set",
				list_contains = "list_contains",
				list_extend = "list_extend",
				isempty = "tbl_isempty",
				extend = "tbl_extend",
				deep_equal = "deep_equal",
				deep_extend = "tbl_deep_extend",
				flatten = "tbl_flatten",
				spairs = "spairs",
			},
		},

		enable_global = true,
	},
}

---@type nvl.utils.ConfigOptions
local options

---@param opts? nvl.utils.ConfigOptions
function M.setup(opts)
	options = tbl_deep_extend("force", defaults, opts or {}) or {}
end

setmetatable(M, {
	__index = function(_, key)
		if options == nil then
			return deepcopy(defaults)[key]
		end
		---@cast options nvl.utils.Config
		return options[key]
	end,
})

return M
