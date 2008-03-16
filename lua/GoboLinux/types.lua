-- vi: set foldmethod=marker foldlevel=0:
--
-- types.lua
-- ---------------------------------------------------------------------------
--  - 2007
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 30/10/07 11:58:30 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------
-- Create the module {{{1
module("GoboLinux.types",package.seeall)

-- Imports {{{1
require "GoboLinux.errors"
local errors = GoboLinux.errors

-- Local Variables {{{1
types = {}
-- Local Functions {{{1
-- check_STRING (str) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function check_STRING ( str )
	if type(str) == "string" then
		return true
	end
	errors.new_error("Argument is not a string")
	return false
end  ----------  end of function check_STRING  ----------

-- check_NUMBER (number) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function check_NUMBER ( number )
	if type(number) == "number" then
		return true
	end
	errors.new_error("Argument is not a number")
	return false
end  ----------  end of function check_NUMBER  ----------

-- check_NIL (null) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function check_NIL ( null )
	if not null then 
		return true
	end
	errors.new_error("Argument is not nil")
	return false 
end  ----------  end of function check_NIL  ----------

-- check_TABLE (table) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function check_TABLE ( table )
	if type(table) == "table" then
		return true
	end
	errors.new_error("Argument is not a table")
	return false
end  ----------  end of function check_TABLE  ----------

-- check_FUNCTION (func) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function check_FUNCTION ( func )
	if type(func) == "function" then
		return true
	end
	errors.new_error("Argument is not a function")
	return false
end  ----------  end of function check_FUNCTION  ----------

-- check_BOOLEAN (bool) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function check_BOOLEAN ( bool )
	if type(bool) == "boolean" then
		return true
	end
	errors.new_error("Argument is not a boolean value")
	return false
end  ----------  end of function check_boolean  ----------

-- Exported Functions {{{1
-- check_type (variable, t) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function check_type ( variable, ... )
	if not arg and variable then 
		return true
	end
	local is_type = false
	local types_str =""
	for _, t in ipairs(arg) do
		if not types[t] then
			errors.new_error("Unknow type "..t)
			return false
		end
		types_str=types_str..t..", "
		is_type = is_type or types[t](variable)
	end
	if not is_type then
		errors.new_error("Invalid type, expected "..types_str.." Got "..
			type(variable))
		return false
	end
	return true
end  ----------  end of function checkType  ----------


function check_arg ( funcname, argn, variable, ... )
	local is_type = check_type(variable, unpack(arg))
	if not is_type then
		local error_str = "Bad argument #"..tostring(argn).." to "..funcname
		if arg then
			error_str=error_str..", expected "..arg[1]
			local i = 2
			while arg[i] do
				error_str=error_str..", "..arg[i]
				i = i +1
			end
		end
		error_str=error_str..". Got "..type(variable)
		errors.new_error(error_str)
		return false
	end
	return true
end  ----------  end of function check_arg  ----------

-- add_type (t, f) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function add_type ( t, f )
	if types[t] then 
		errors.new_error("GoboLinux.types.add_type:type "..t.." is yet registered")
		return nil
	else
		if type(f) ~= "function" then
			errors.new_error("GoboLinux.types.add_type:second argument is not a function")
			return nil
		else
			types[t] = f
		end
	end
	return true
end  ----------  end of function add_type  ----------

-- Types {{{1
-- Type STRING  {{{2
add_type("STRING", check_STRING)
-- Type NUMBER {{{2
add_type("NUMBER", check_NUMBER)
-- Type TABLE {{{2
add_type("TABLE", check_TABLE)
-- Type NIL {{{2
add_type("NIL", check_NIL)
-- Type FUNCTION {{{2
add_type("FUNCTION", check_FUNCTION)
-- Type BOOLEAN {{{2
add_type("BOOLEAN", check_BOOLEAN)
