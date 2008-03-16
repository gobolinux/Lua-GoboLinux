-- vi: set foldmethod=marker foldlevel=0:
--
-- GoboPBXBusyBox.lua
-- ---------------------------------------------------------------------------
--  - 2008
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 06/02/08 21:22:56 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

-- Create module
module("Flavours.GoboPBXBusyBox",package.seeall)

-- Imports
require "GoboLinux.Program"
require "GoboLinux.Package"
require "Flavours.Configures"
require "GoboLinux.fs"
require "GoboLinux.errors"

local errors = GoboLinux.errors
local Configures = Flavours.Configures
local fs = GoboLinux.fs
local Program = GoboLinux.Program
local Package = GoboLinux.Package

-- Local Variables
local GCC= coroutine.create(function ()
	local gcc = Program.new("GCC")
	if not gcc then
		return false, errors.error()
	end
	coroutine.yield("Preparing GCC Libraries", function ()
		gcc:disableExecutables()
		gcc:disableManuals()
		gcc:disableHeaders()
		gcc:disableShared()
		local gcc_path = gcc.Prefix..gcc.Programs..gcc.Name.."/"
				..gcc.Version.."/"
		for _, path in ipairs({"bin","doc","include","info","man",
						"Resources","Shared"}) do
			fs.rmdir(gcc_path..path)
		end
		return true
	end)
end)

-- Installs vimrc file and tries to shrink vim
local VIM_Configure = coroutine.create(function ()
	local vim_skel = system.prefix().."/System/Settings/skel/.vimrc"
	coroutine.yield("Copying vimrc file", function ()
		if not fs.cp("Resources/GoboPBX/vimrc", vim_skel) then
			return false, errors.error()
		end
	end)
end)

-- Exported Variables
Packages = {
	{"Glibc"},
	{"GCC"},
	{"Linux", "2.6.24.2-c3"},
	{"BusyBox", "1.6.0-c3"},
	{"GoboHide"},
	{"Scripts"},
	{"BootScripts"},
	{"Zlib"},
	{"KBD"},
	{"Ncurses"},
	{"PCRE"},
	{"ReadLine"},
	{"OpenSSH"},
	{"OpenSSL"},
	{"Grub"},
	{"Asterisk"},
	{"Curl"},
	{"ALSA-Lib"},
	{"LibVorbis"},
	{"LibOGG"},
	{"Popt"},
	{"GPM"},
	{"Zaptel"},
}

Coroutine = coroutine.create(function()
	for i, p in ipairs(Packages) do
		local program=Program.new(p[1],p[2])
		local desc 
		if not program then
			desc = "Shrinking " ..p[1]
--			coroutine.yield(true, desc, function ()
--				return nil, "Program "..p[1].." "..p[2].." not found."
--			end)
			return false, desc, 
				"Unable to found program "..p[1].." "..p[2]
		else
			desc = "Shrinking "..program.Name.." "..program.Version
		end
		coroutine.yield(true, desc, function ()
			return shrink_program(program)
		end)
	end
	return true, "Packages Shrinked"
end)
Items = #Packages


Function = {
	{"GLibc", Configures.GLibc},
	{"GCC", GCC},
	{"SSH", Configures.SSH},
}
