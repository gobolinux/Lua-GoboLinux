-- vi: set foldmethod=marker foldlevel=0:
--
-- Configures.lua
-- ---------------------------------------------------------------------------
--  - 2008
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 10/02/08 11:17:53 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

-- Create module {{{1
module("Flavours.Configures", package.seeall)

-- Imports
require "GoboLinux.Program"
require "GoboLinux.errors"
require "GoboLinux.system"
require "GoboLinux.fs"

local errors = GoboLinux.errors
local Program = GoboLinux.Program
local system = GoboLinux.system
local fs = GoboLinux.fs

-- Local Variables
-- GLibc_Configure Coroutine {{{2
local GLibc_Configure = coroutine.create(
function()
	local program = Program.new("GLibc")
	local glibc_path
	if program then
		glibc_path = program.Prefix..program.Programs..program.Name
			.."/Settings/ld.so.cache"
	else
		return false, errors.error()
	end
	coroutine.yield("Updating ld.so.cache...", function ()
		if not fs.cp("Resources/ld.so.cache", glibc_path) then
			return false, errors.error()
		end
		local cmd = "chroot " .. program.Prefix .. " ldconfig"
		if not os.execute(cmd) then
			return false, "Error when updating ld.so.cache"
		end
		return true
	end)
end)

local Vim_Configure = coroutine.create(
function ()
	local program = Program.new("Vim")
	local vim_path
	if program then
		vim_path = program.Prefix..program.Programs..program.Name.."/"
			..program.Version.."/"
	else
		return false, errors.error()
	end
	local skel = system.prefix().."System/Settings/skel"
	coroutine.yield("Adding vim rc files...", function ()
		local orig = vim_path.."Shared/vim/vim70/vimrc_example.vim"
		local dest = skel.."/.vimrc"
		if not fs.cp(orig, dest) then
			return false, errors.error()
		end
	end)
end)

local SSH_Configure = coroutine.create(function ()
	local rsa = system.prefix().."/System/Settings/ssh/ssh_host_rsa_key"
	local dsa = system.prefix().."/System/Settings/ssh/ssh_host_dsa_key"
	local sshd_user = {"sshd","22","104","OpenSSH daemon","/var/empty",
						"/var/false"}
	local sshd_group = {"sshd","104"}
	coroutine.yield("Generating RSA Keys", function ()
		local cmd = "ssh-keygen -t rsa -f "..rsa.." >/dev/null 2>&1" 
		if not os.execute(cmd) then
			return false, "Unable to create RSA keys"
		end
	end)
	coroutine.yield("Generating DSA Keys", function ()
		local cmd = "ssh-keygen -t dsa -f "..dsa.." >/dev/null 2>&1" 
		if not os.execute(cmd) then
			return false, "Unable to create DSA keys"
		end
	end)
	coroutine.yield("Creating user and group sshd", function ()
		if not add_group(Target, sshd_group) then
			return false, "Unable to add group sshd"
		end
		if not add_user(Target, sshd_user) then
			return false, "Unable to add group sshd"
		end
	end)
end)

-- Exported Variables
GLibc = GLibc_Configure
Vim = Vim_Configure
SSH = SSH_Configure

