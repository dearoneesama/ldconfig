--[[
	paths.lua
	paths to hintsfiles
]]

-- @export
local _PATH_LD_HINTS = '/var/run/ld.so.hints'	-- comes from sys/sys/link_aout.h
-- @export
local _PATH_ELF_HINTS = '/var/run/ld-elf.so.hints'
-- @export
local _PATH_LD32_HINTS = '/var/run/ld32.so.hints'
-- @export
local _PATH_ELF32_HINTS = '/var/run/ld-elf32.so.hints'
-- @export
local _PATH_ELFSOFT_HINTS = '/var/run/ld-elf-soft.so.hints'

return {
	_PATH_LD_HINTS = _PATH_LD_HINTS,
	_PATH_ELF_HINTS = _PATH_ELF_HINTS,
	_PATH_LD32_HINTS = _PATH_LD32_HINTS,
	_PATH_ELF32_HINTS = _PATH_ELF32_HINTS,
	_PATH_ELFSOFT_HINTS = _PATH_ELFSOFT_HINTS,
}

--[[ end paths.lua ]]
