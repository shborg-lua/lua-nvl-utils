---@diagnostic disable:lowercase-global
local MODREV, SPECREV = "scm", "-1"
rockspec_format = "3.0"
package = "lua-nvl-utils"
version = MODREV .. SPECREV

source = {
	url = "https://github.com/shborg-lua/lua-nvl.utils/archive/v" .. MODREV .. ".zip",
}
description = {
	summary = "A library for Lua and Neovim",
	detailed = [[
`nvl.utils` is a utils library]],
	homepage = "http://github.com/shborg-lua/nvl.utils",
	license = "MIT",
}
dependencies = {
	"lua >= 5.1",
	-- "promise-async",
	-- "tableshape",
	-- "lpeg",
	-- "lua-cjson",
	-- "tableshape",
	-- "luasocket",
	-- "luasec",
}

test_dependencies = {
	"busted",
	"busted-htest",
	"luacov",
	"luacov-html",
	"luacov-multiple",
	"luacov-console",
}
test = {
	type = "busted",
}

build = {
	type = "builtin",
	modules = {

		["nvl.utils"] = "lua/nvl/utils/init.lua",
		["nvl.utils.config"] = "lua/nvl/utils/config.lua",
		["nvl.utils.modules.table"] = "lua/nvl/utils/modules/table.lua",
		["nvl.utils.modules.types"] = "lua/nvl/utils/modules/types.lua",
		["nvl.utils.modules.string"] = "lua/nvl/utils/modules/string.lua",
		["nvl.utils.modules.deepcopy"] = "lua/nvl/utils/modules/deepcopy.lua",
	},
	platforms = {},
	copy_directories = {},
}
