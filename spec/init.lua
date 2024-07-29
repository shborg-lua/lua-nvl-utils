package.path = os.getenv("PWD") .. "/lua/?.lua;" .. package.path

local TestSuite = {}
_G.TestSuite = TestSuite
_G.inspect = require("spec.helpers.inspect")

function _G.P(v)
	print("============ test debug ===========")
	print(_G.inspect(v))
end

local uv = vim and vim.uv or require("luv")

local co = coroutine.create(function()
	require("busted.runner")({ standalone = false, output = "spec.helpers.outputHandler" })
	-- no errors for nvim
	if vim then
		vim.schedule(function()
			vim.cmd("cq 0")
		end)
	end
end)

_G.co = co

local compatibility = require("busted.compatibility")

if vim then
	compatibility.exit = function(code)
		vim.schedule(function()
			vim.cmd(("cq %d"):format(code))
		end)
	end
	_G.arg = vim.fn.argv()
	_G.print = function(...)
		local argv = { ... }
		for i = 1, #argv do
			argv[i] = tostring(argv[i])
		end
		table.insert(argv, "\n")
		io.write(unpack(argv))
	end
	coroutine.resume(co)
else
	local c = 0
	-- https://github.com/luvit/luv/issues/599
	compatibility.exit = function(code)
		c = code
	end
	local idle = uv.new_idle()
	idle:start(function()
		idle:stop()
		coroutine.resume(co)
	end)
	uv.run()
	os.exit(c)
end
