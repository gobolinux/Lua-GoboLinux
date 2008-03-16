-- vi: set foldmethod=marker foldlevel=0:
--
-- SChroot.lua
-- ---------------------------------------------------------------------------
--  - 2008
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 07/02/08 21:48:29 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

-- Create module
module("Flavours.SChroot", package.seeall)

-- Imports
require "GoboLinux.Program"
require "Flavours.Configures"
local Configures = Flavours.Configures
local Program = GoboLinux.Program

-- Exported Variables
Packages = {
--	{"Glibc"},
	{"Linux"},
--[[	{"GoboHide"},
	{"Scripts"},
	{"BootScripts"},
	{"Bash"},
	{"Zlib"},
	{"Gzip"},
	{"KBD"},
	{"GPM"},
	{"Grep"},
	{"Shadow"},
	{"Module-Init-Tools"},
	{"Ncurses"},
	{"Net-Tools"},
	{"Gawk"},
	{"PCRE"},
	{"Psmisc"},
	{"ReadLine"},
	{"Sed"},
	{"Sysklogd"},
	{"Manager"},
	{"Freshen"},
	{"Ruby"},
	{"Vim"},
	{"Udev","105"},
	{"Util-Linux"},
	{"CoreUtils"},
	{"E2FSProgs"},
	{"FindUtils"},
	{"SysVInit"}, 
	{"OpenSSH"},
	{"OpenSSL"},--]]
	{"Grub"},
--[[	{"Xorg"},
	{"DB"},
	{"FreeType"},
	{"Gettext"},
	{"LibXSLT"},
	{"LibPNG"},
	{"LibDRM"},
	{"Mesa"},
	{"QT"},
	{"PyQt"},-- For Manager--]]
}

-- local funct0ion init ()
Coroutine = coroutine.create(function()
		for i, p in ipairs(Packages) do
			local program=Program.new(p[1],p[2])
			local desc
			if not program then 
				desc = "Shriking "..p[1]
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
	{"Vim", Configures.Vim},

}
