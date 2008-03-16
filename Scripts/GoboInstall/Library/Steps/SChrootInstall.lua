-- vi: set foldmethod=marker foldlevel=0:
--
-- SChrootInstall.lua
-- ---------------------------------------------------------------------------
--  - 2008
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 08/02/08 21:37:22 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

-- Create module {{{1
module("SChrootInstall", package.seeall)

-- Imports {{{1
require "Steps"
require "goboinstall"
require "GoboLinux.cui"
require "GoboLinux.errors"
require "GoboLinux.fs"
require "GoboLinux.system"

local cui = GoboLinux.cui
local errors = GoboLinux.errors
local fs = GoboLinux.fs
local system = GoboLinux.system

-- Local Variables {{{1
local modifiers = {
	"LevelPosition=Center",
	"Level=2",
}

-- Steps {{{1
local function AskDirectory ()
	local title = "GoboLinux SChroot Installation"
	local ask = "Where do you want to install your GoboLinux SChroot System?"
	local ask2 = "Do you want to create %s?"
	local ask3 = "Contents in %s will be removed, do you want to continue?"
	print()
	cui.title(title, "Color=BoldGreen", unpack(modifiers))
	print()
	local done = false
	while not done do
		dir=cui.ask(ask, "Color=White", unpack(modifiers))
		if not fs.is_path(dir) and string.len(dir) > 0 then
			print()
			if not cui.ask_yn(string.format(ask2,dir), "Color=White", 
						unpack(modifiers)) then
				return nil, "Installtion aborted"
			end
			if not fs.mkdir(dir) then
				return nil, errors.error()
			end
			done = true
		elseif string.len(dir) > 0 then 
			print()
			if cui.ask_yn(string.format(ask3, dir), "Color=Yellow",
						unpack(modifiers)) then
				done = true
				if not fs.rmdir(dir) then
					return nil, errors.error()
				end
				if not fs.mkdir(dir) then
					return nil, errors.error()
				end
			end
		end
	end
	Target = dir
	return "CreateGoboTree", dir
end

local function CreateGoboTree (dir)
	local text1 = "Creating GoboLinux SChroot Tree under %s"
	local text2 = "GoboLinux SChroot Created"
	if not fs.is_directory(dir) then
		return nil, "Destination directory "..dir.." does not exists"
	end
	print()
	cui.text(string.format(text1, dir), "Color=White", unpack(modifiers))
	print()
	if not system.create_tree(dir, true) then
		return nil, errors.error()
	end
	cui.text(text2, "Color=White", unpack(modifiers))
	return nil
end

local function Finish()
	local text = [[
Your SChroot GoboLinux system has been installed successful under %s.
Now you can use it as a normal GoboLinux System using schroot tool to create a jailed system.

Have fun with it.
]]
	return nil, nil, text

end

-- Exported Functions {{{1
function start ()
	local SChrootSteps = {
		AskDirectory = AskDirectory,
		CreateGoboTree = CreateGoboTree,
	}
	local steps = Steps.new(SChrootSteps)
	return steps:start("AskDirectory")
end

function finish ()
	local text = [[
Your SChroot GoboLinux system has been installed successful under %s.
Now you can use it as a normal GoboLinux System using schroot tool to create a jailed system.

Have fun with it.
]]
	return string.format(text,dir)
end
