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

-- @export
local ELFHINTS_MAGIC = 0x746e6845
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
	return {
		magic = 0,        -- magic number
		version = 0,      -- file version
		-- refer to elf-hints.h for unnecessary fields
	}
end

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
	_PATH_ELF_HINTS = _PATH_ELF_HINTS,
	_PATH_LD32_HINTS = _PATH_LD32_HINTS,
	_PATH_ELF32_HINTS = _PATH_ELF32_HINTS,
	_PATH_ELFSOFT_HINTS = _PATH_ELFSOFT_HINTS,
	ElfhintsHdr = ElfhintsHdr,
	Elfhints = Elfhints
}

--[[ end elfhints.lua ]]
