--[[
	elfhints.lua
	copy of sbin/ldconfig/elfhints.c
--]]

local lfs = require('lfs')
local Util = require('util')

-- not relevant but necessary
local S_IWOTH = 2            -- 0002
local S_IWGRP = 16           -- 0020
local ENOENT = 2

-- [[ realm of elf-hints header ]]

-- @export
local ELFHINTS_MAGIC = 0x746e6845
-- @export
local _PATH_LD_HINTS = '/var/run/ld.so.hints'  -- comes from sys/sys/link_aout.h
-- @export
local _PATH_ELF_HINTS = '/var/run/ld-elf.so.hints'
-- @export
local _PATH_LD32_HINTS = '/var/run/ld32.so.hints'
-- @export
local _PATH_ELF32_HINTS = '/var/run/ld-elf32.so.hints'
-- @export
local _PATH_ELFSOFT_HINTS = '/var/run/ld-elf-soft.so.hints'

-- @export @class
local function ElfhintsHdr()
	-- the real data
	-- @public
	local body = {
	--[[C u_int32_t]] magic = 0,        -- magic number
	--[[C u_int32_t]] version = 0,      -- file version (1)
	--[[C u_int32_t]] strtab = 0,       -- offset of string table in file
	--[[C u_int32_t]] strsize = 0,      -- size of string table
	--[[C u_int32_t]] dirlist = 0,      -- off set of directory in string table
	--[[C u_int32_t]] dirlistlen = 0,   -- strlen(dirlist)
	--[[C u_int32_t[26] ]] spare = 0    -- room for expansion

	-- that's all. see elf-hints.h for details
	-- total size: 128

	-- followed by strings
	}
	local sizeof = 128

	-- @public @method
	local function to_binary()
		return ('I4I4I4I4I4I4'):pack(
			body.magic, body.version, body.strtab,
			body.strsize, body.dirlist, body.dirlistlen
		)..('\0'):rep(4 * 26)
	end

	-- @public @method
	local function from_binary(bytes)
		if #bytes ~= 128 then error() end
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
		local fp, errmsg, errcode = io.open(listfile, 'r')
		if fp == nil then
			Util.err(1, errmsg, errcode, '%s', listfile)
		end
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

	-- @private @method @unimpl
	local function read_hints(must_exist)
		local fp, errmsg, errcode = io.open(hintsfile, 'r')
		if fp == nil then
			-- no such file
			if errcode == ENOENT and not must_exist then return end
		Util.err(1, errmsg, errcode, 'Cannot open "%s"', hintsfile)
		end

		local fstat, errmsg, errcode = lfs.attributes(hintsfile)
		if fstat == nil then
			Util.err(1, errmsg, errcode, 'Cannot stat "%s"', hintsfile)
		end

	end

	-- @private @method @unimpl
	local function write_hints()
		-- get a temp file with random name
	end

end -- function Elfhints
Elfhints()

return {
	ELFHINTS_MAGIC = ELFHINTS_MAGIC,
	_PATH_LD_HINTS = _PATH_LD_HINTS,
	_PATH_ELF_HINTS = _PATH_ELF_HINTS,
	_PATH_LD32_HINTS = _PATH_LD32_HINTS,
	_PATH_ELF32_HINTS = _PATH_ELF32_HINTS,
	_PATH_ELFSOFT_HINTS = _PATH_ELFSOFT_HINTS,
	ElfhintsHdr = ElfhintsHdr,
	Elfhints = Elfhints
}

--[[ end elfhints.lua ]]
