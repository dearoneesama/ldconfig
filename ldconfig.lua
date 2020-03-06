--[[
	ldconfig.lua
	main program
--]]

local Util = require('util')

local function main(args)
end

local function usage()
	Util.fprintf(io.stderr, 
	'usage: ldconfig [-32] [-aout | -elf] [-Rimrsv] [-f hints_file] [directory | file ...]\n')
	os.exit(1)
end

--[[ end ldconfig.lua ]]
