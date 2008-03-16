-- vi: set foldmethod=marker foldlevel=0:
--
-- output.lua
-- ---------------------------------------------------------------------------
--  - 2007
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 29/10/07 11:57:39 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------
-- Create a new module {{{1
module("GoboLinux.output",package.seeall)

-- Import modules {{{1
require "posix"
require "GoboLinux"

-- Local Variables {{{1
local color = {
	Black="\27[30m",
    Red="\27[31m",
    Green="\27[32m",
	Yellow="\27[33m",
	Blue="\27[34m",
	Magenta="\27[35m",
	Cyan="\27[36m",
    White="\27[37m",
	BoldBlack="\27[1;30m",
    BoldRed="\27[1;31m",
    BoldGreen="\27[1;32m",
	BoldYellow="\27[1;33m",
	BoldBlue="\27[1;34m",
	BoldMagenta="\27[1;35m",
	BoldCyan="\27[1;36m",
    BoldWhite="\27[1;37m",
}

local settings_dir = "/System/Settings/Lua-GoboLinux/"

local config_file = "output.conf"

-- Exported Variables {{{1
Silent = false
Verbose = 0
Warnings = true
Colors = {
	Verbose = "BoldGreen",
	Error = "BoldRed",
	Warning = "BoldYellow",
	Terse = "BoldWhite",
	Prefix = "BoldBlue",
}

RegisteredFunctions = {}

-- Local Functions {{{1
-- get_function_name () {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function get_function_name (  )
	return RegisteredFunctions[#RegisteredFunctions]
end  ----------  end of function get_function_name  ----------

-- log_write (str, ident_level, mode) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function log_write ( str )
	io.write(str.."\n")
end  ----------  end of function log_write  ----------


-- ident_to_str (ident_level)
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function ident_to_str ( ident_level )
	local ident=""
	if ident_level and type(ident_level) == "number" then
		ident=string.rep("\t",ident_level)
	end
	return ident
end  ----------  end of function ident_to_str  ----------

-- prefix_str ()
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function prefix_str (  )
	return color[Colors.Prefix].."["..(get_function_name() or arg[0] or "")
		.."] "..color[Colors.Terse]
end  ----------  end of function prefix_str  ----------

-- Exported Functions {{{1
-- register_name (str) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
--  
function register_name ( str )
	if type(str) ~= "string" then
		return false
	end
	table.insert(RegisteredFunctions,str)
	return true
end  ----------  end of function registerFunction  ----------

-- unregister_name() {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function unregister_name (  )
	return table.remove(RegisteredFunctions)
end  ----------  end of function unregister_name  ----------

-- log_normal (str, ident_level) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function log_normal ( str, ident_level )
	local ident = ident_to_str(ident_level)
	local prefix = prefix_str()
	return log_write(prefix..ident..str)
end  ----------  end of function logNormal  ----------


-- log_verbose (str, verbose_level, ident_level) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function log_verbose ( str, verbose_level, ident_level )
	if Verbose < verbose_level then return true end
	local ident = ident_to_str(ident_level)
	local msg = prefix_str()..color[Colors.Verbose]..ident..str..color[Colors.Terse]
	return log_write(msg)
end  ----------  end of function logVerbose  ----------

-- log_error (str, ident_level) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function log_error ( str, ident_level )
	if Silent then return true end
	local prefix = prefix_str()
	local ident = ident_to_str(ident_level)
	local msg = color[Colors.Error] .. "[" .. prefix .. "]" .. color[Colors.Terse] .. "::"..str
	local msg = prefix..color[Colors.Error]..ident..str..color[Colors.Terse]
	return log_write(msg)
end  ----------  end of function log_error  ----------

-- log_warning (str, indent_level) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function log_warning ( str, indent_level )
	if not Warnings then return true end
	local prefix = prefix_str()
	local ident = ident_to_str(indent_level)
	local msg = prefix..color[Colors.Warning]..ident..str..color[Colors.Terse]
	return log_write(msg)
end  ----------  end of function log_warning  ----------

-- log_terse (str, ident_level) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function log_terse ( str, ident_level )
	local msg
	local ident = ident_to_str(ident_level)
	if str then
		msg = ident..str
	end
	return log_write(msg or "")
end  ----------  end of function log_terse  ----------

-- Initialize module {{{1
GoboLinux.source_config(config_file)
