--[[
	ldconfig.lua
	main program
--]]

Util = require('util')
Paths = require('paths')
Elfhints = require('elfhints')

-- Note on aout/a.out support.
-- ldconfig's aout support is missing in this implementation. Right now,
-- attempts to provide -aout flag will result in an error message.
-- options -v and -s do not make a difference in elf

function main(args)
	local is_aout, is_32, is_soft = false, false, false
	local verbose, nostd, justread, merge, rescan, insecure
	    = false, false, false, false, false, false
	local hintsfile = ''
	-- arg[-1] => flua, arg[0] => ldconfig.lua, arg[1:] => arguments
	-- #arg => #arg[1:]
	local curridx = 1

	for i = 1, #args do
		if args[i] == '-aout' then
			is_aout = true
			curridx = i+1
		elseif args[i] == '-elf' then
			is_aout = false
			curridx = i+1
		elseif args[i] == '-32' then
			is_32 = true
			curridx = i+1
		elseif args[i] == '-soft' then
			is_soft = true
			curridx = i+1
		else
			break
		end
	end

	if is_aout then
		Util.fprintf(io.stderr, 'aout is not supported\n')
		os.exit(1)
	end

	if is_soft then
		hintsfile = Paths._PATH_ELFSOFT_HINTS
	elseif is_32 then
		hintsfile = Paths._PATH_ELF32_HINTS
	else
		hintsfile = Paths._PATH_ELF_HINTS
	end

	local rest
	if #arg == 0 then
		rescan = true
	else
		rest = unpack_arguments(args, curridx)
		local i = 1
		while i <= #rest do
			local v = rest[i]
			if v == '-R' then rescan = true
			elseif v == '-i' then insecure = true
			elseif v == '-m' then merge = true
			elseif v == '-r' then justread = true
			elseif v == '-s' then nostd = true
			elseif v == '-v' then verbose = true
			elseif v == '-f' then
				hintsfile = checkarg(rest[i+1])
				i = i + 1
			else usage() end
			i = i + 1
		end
	end

	local session = Elfhints.Elfhints(hintsfile, insecure)
	if justread then
		session.list_hints()
	else -- TODO insert appropriate list here
		session.update_hints({}, merge or rescan)
	end

local function main(args)
end

function usage()
	Util.fprintf(io.stderr, 
	'usage: ldconfig [-32] [-aout | -elf] [-Rimrsv] [-f hints_file] [directory | file ...]\n')
	os.exit(1)
end

function checkarg(item)
	if item == nil then
		Util.fprintf(io.stderr, '%s: option requires an argument\n', arg[0])
		usage()
	end
	return item
end

function unpack_arguments(args, offset)
	-- unpack args like {-Rrm, -f, so.hints}
	-- into {-R, -r, -m, -f, so.hints}
	local res = {}
	for i = offset, #args do
		local v = args[i]
		if v:match('^%-') then
			for op in v:gmatch('%a') do
				res[#res+1] = '-'..op
			end
		else
			res[#res+1] = v
		end
	end
	return res
end

main(arg)
--[[ end ldconfig.lua ]]
