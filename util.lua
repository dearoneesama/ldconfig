--[[ 
	util.lua common utility functions
	refer to util.c for missing pieces

	eg:
	```
	> warnx('program [%s] warns', 'spam')
	lua53: program [spam] warns
	> warn('Permission denied', 13, 'program [%s] warns', 'spam')
	lua53: program [spam] warns: Permission denied: 13
	> errx(22, 'program [%s] cannot run', 'spam')
	lua53: program [spam] cannot run
	(exit with code 22)
	```
--]]

-- @export
local function fprintf(file, fmt, ...)
	file:write(string.format(fmt, ...))
end

-- @export
local function printf(fmt, ...)
	io.stdout:write(string.format(fmt, ...))
end

local function _warnx_partial(fmt, ...)
	fprintf(io.stderr, '%s: ', arg[0])
	if fmt ~= nil then
		fprintf(io.stderr, fmt, ...)
	end
end

-- @export
local function warnx(fmt, ...)
	_warnx_partial(fmt, ...)
	fprintf(io.stderr, '\n')
end

-- @export
local function warn(errmsg, errcode, fmt, ...)
	_warnx_partial(fmt, ...)
	fprintf(io.stderr, ': ')
	fprintf(io.stderr, '%s: %d\n', errmsg, errcode)
end

-- @export
local function errx(eval, fmt, ...)
	warnx(fmt, ...)
	os.exit(eval)
end

-- @export
local function err(eval, errmsg, errcode, fmt, ...)
	warn(errmsg, errcode, fmt, ...)
	os.exit(eval)
end

return {
	fprintf = fprintf,
	printf = printf,
	warnx = warnx,
	warn = warn,
	errx = errx,
	err = err
}

-- [[ end util.lua ]]
