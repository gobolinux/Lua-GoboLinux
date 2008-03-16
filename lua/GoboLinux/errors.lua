-- vi:set foldmethod=marker foldlevel=0:
--
-- errors.lua
-- ---------------------------------------------------------------------------
--  - 2007
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 30/10/07 11:34:06 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

-- Create a new module {{{1
module("GoboLinux.errors",package.seeall)

-- Imports {{{1
require "GoboLinux.output"
local output=GoboLinux.output
 
-- Local Variables {{{1
local last_error="No string error"

-- Local Functions {{{1
-- do_error (msg, exit_on_error, error_code) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function do_error ( msg, exit_on_error, error_code )
	local msg = (last_error .. ": " .. msg):gsub(":%W*$","")
	output.log_error(msg)
	if exit_on_error then
		return os.exit(error_code or 1)
	end
	return true
end  ----------  end of function do_error  ----------

-- Exported Functions {{{1
-- -------- ---------
-- perror (str) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function perror ( str )
	return do_error(str or "")
end  ----------  end of function perror  ----------

-- peerror (str, error_code) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function peerror ( str, error_code )
	return do_error(str or "" , true, error_code)
end  ----------  end of function eerror  ----------


-- new_error (str) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function new_error ( str, func_name )
	if type(str) ~= "string" then
		last_error="new_error"
		return perror("str argument is not a string")
	end
	if func_name then
		func_name = func_name..":"
	else
		func_name = ""
	end
	last_error = func_name..str
	return true
end  ----------  end of function new_error  ----------


-- last_error () {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function error ( )
	return last_error
end  ----------  end of function last_error  ----------

-- die (error_code) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function die ( error_code )
	os.exit(error_code or 1)
end  ----------  end of function die  ----------
