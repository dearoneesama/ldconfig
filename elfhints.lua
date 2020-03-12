--[[
	elfhints.lua
	copy of sbin/ldconfig/elfhints.c
--]]

local lfs = require('lfs')
local sysstat = require('posix.sys.stat')
local Util = require('util')

-- not relevant but necessary
local S_IWOTH = 2			-- 0002
local S_IWGRP = 16			-- 0020
local ENOENT = 2

-- [[ realm of elf-hints header ]]

local ELFHINTS_MAGIC = 0x746e6845

-- @class
local function ElfhintsHdr()
	-- @public
	local sizeof = 128

	-- the real data
	-- @public
	local body = {
	--[[u_int32_t]] magic = ELFHINTS_MAGIC,			-- magic number
	--[[u_int32_t]] version = 1,			-- file version (1)
	--[[u_int32_t]] strtab = sizeof,			-- offset of string table in file
	--[[u_int32_t]] strsize = 0,			-- size of string table
	--[[u_int32_t]] dirlist = 0,			-- off set of directory in string table
	--[[u_int32_t]] dirlistlen = 0,			-- strlen(dirlist)
	--[[u_int32_t[26] ]] spare = 0			-- room for expansion

	-- that's all. see elf-hints.h for details
	-- total size: 128

	-- followed by strings
	}

	-- @public @method
	local function to_binary()
		return ('I4I4I4I4I4I4'):pack(
			body.magic, body.version, body.strtab,
			body.strsize, body.dirlist, body.dirlistlen
		)..('\0'):rep(4 * 26)
	end

	-- @public @method
	local function from_binary(bytes)
		if #bytes < 128 then error() end
		body.magic = ('I4'):unpack(bytes:sub(1, 4))
		body.version = ('I4'):unpack(bytes:sub(5, 8))
		body.strtab = ('I4'):unpack(bytes:sub(9, 12))
		body.strsize = ('I4'):unpack(bytes:sub(13, 16))
		body.dirlist = ('I4'):unpack(bytes:sub(17, 20))
		body.dirlistlen = ('I4'):unpack(bytes:sub(21, 24))
		body.spare = 0
	end

	return {
		body = body,
		sizeof = sizeof,
		to_binary = to_binary,
		from_binary = from_binary
	}
end

-- [[ end realm of elf-hints header ]]

-- @export @class
local function Elfhints(hintsfile, insecure)
	-- @private
	local dirs = {}

	-- @private @method
	local function add_dir(name, trusted)
		if not trusted and not insecure then
			local fstat, errmsg, errcode = lfs.attributes(name)
			if fstat == nil then
				Util.warn(errmsg, errcode, '%s', name)
				return
			end
			if fstat.uid ~= 0 then
				Util.warnx('%s: ignoring directory not owned by root', name)
				return
			end
			local fperm = tonumber(fstat.permissions, 8)
			if (fperm & S_IWOTH) ~= 0 then
				Util.warnx('%s: ignoring world-writable directory', name)
				return
			end
			if (fperm & S_IWGRP) ~= 0 then
				Util.warnx('%s: ignoring group-writable directory', name)
				return
			end
		end

		for i = 1, #dirs do
			if dirs[i] == name then return end
		end
		dirs[#dirs + 1] = name
	end

	-- @private @method
	local function read_dirs_from_file(listfile)
		local fp = Util.callerr(Util.bind(io.open, listfile, 'r'),
		    '%s', listfile)
		local linenum = 0
		for line in fp:lines() do
			linenum = linenum + 1
			-- skip comments starting with #
			if string.match(line, '^%s*#') then goto continue end
			local name, trailing = string.match(line, '^%s*(%S+)%s*(%S*)')
			-- matched dir name
			if name ~= nil then add_dir(name, false) end
			-- has trailing characters after dir name 
			if trailing ~= nil and trailing ~= '' then
				Util.warnx('%s:%d: trailing characters ignored', listfile, linenum)
			end
			-- it is sure that lines with only whitespaces won't trigger any of the above
			::continue::
		end
		fp:close()
	end

	-- @private @method
	local function read_hints(must_exist)
		local fp, errmsg, errcode = io.open(hintsfile, 'rb')
		if fp == nil then
			-- no such file
			if errcode == ENOENT and not must_exist then return end
			Util.err(1, errmsg, errcode, 'Cannot open "%s"', hintsfile)
		end
		-- why stat?
		local fstat = Util.callerr(Util.bind(lfs.attributes, hintsfile),
		    'Cannot stat "%s"', hintsfile)

		local bytes = fp:read('a')
		fp:close()
		local hdr = ElfhintsHdr()
		hdr.from_binary(bytes)
		if hdr.body.magic ~= ELFHINTS_MAGIC then
			Util.errx(1, '"%s": invalid file format', hintsfile)
		end
		if hdr.body.version ~= 1 then
			Util.errx(1, '"%s": unrecognized file version (%d)', hintsfile,
			    hdr.body.version)
		end

		local strtab = hdr.body.strtab + 1
		local dirlist = strtab + hdr.body.dirlist
		-- get substring from position dirlist to the end
		local dirsubstring = bytes:sub(dirlist)
		-- split string by : . this loop is skipped if it is empty
		for name in dirsubstring:gmatch('[^:]+') do
			add_dir(name, true)
		end
	end

	-- @private @method
	local function write_hints()
		local stringbuilder = {}
		local hdr = ElfhintsHdr()

		-- count up the size of the string table
		if #dirs > 0 then
			hdr.body.strsize = hdr.body.strsize + #dirs[1]
			for i = 2, #dirs do
				hdr.body.strsize = hdr.body.strsize + 1 + #dirs[i]
			end
		end
		hdr.body.dirlistlen = hdr.body.strsize
		hdr.body.strsize = hdr.body.strsize + 1 -- null terminator

		-- write header
		table.insert(stringbuilder, hdr.to_binary())
		-- write strings
		table.insert(stringbuilder, table.concat(dirs, ':'))
		table.insert(stringbuilder, '\0')

		local fp = Util.callerr(Util.bind(io.open, hintsfile, 'w+b'),
		    'Cannot open %s', hintsfile)
		Util.callerr(
			function() return fp:write(table.concat(stringbuilder, '')) end,
		    '%s: write error', hintsfile)
		fp:close()

		Util.callerr(Util.bind(sysstat.chmod, hintsfile, 292), -- 0444
		    'chmod(%s)', hintsfile)
	end

	-- acts like a main function where arglist is _G.arg
	-- @public @method
	local function update_hints(arglist, merge)

	end

end -- function Elfhints
Elfhints('ldconfig/ld-elf.so.hintshaha')

return {
	Elfhints = Elfhints
}

--[[ end elfhints.lua ]]
