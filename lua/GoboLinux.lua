-- vi: set foldmethod=marker foldlevel=0:
--
-- GoboLinux.lua
-- ---------------------------------------------------------------------------
--  - 2007
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 04/12/07 18:53:05 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------



-- Create module {{{1 
module("GoboLinux", package.seeall)

-- Imports {{{1
require "posix"

-- Local Variables {{{1
local config_file = "GoboLinux.conf"
local GOBO_SETTINGS = "Lua-GoboLinux"

-- Exported Variables {{{1
SETTINGS = "/System/Settings"
PROGRAMS = "/Programs"
HEADERS = "/System/Links/Headers"
LIBRARIES = "/System/Links/Libraries"
PACKAGES = "/Depot/Packages"

-- Local Functions {{{1

-- Exported Functions {{{1

function source ( file )
	local path = file
	if not posix.stat(path) then
		return nil, "Cannot open "..path
	end
	dofile(path)
	return true
end  ----------  end of function source  ----------


function source_config ( config )
	local path = SETTINGS.."/"..GOBO_SETTINGS.."/"..config
	return source(path)
end  ----------  end of function source_config  ----------

-- Initialize module {{{1
source_config(config_file)
