-- vi: set foldmethod=marker foldlevel=0:
--
-- StandardSteps.lua
-- ---------------------------------------------------------------------------
--  - 2008
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 06/02/08 18:33:38 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

module("StandardInstall", package.seeall)

-- Imports
require "Steps"
require "Steps.CommonSteps"
require "goboinstall"
require "GoboLinux.cui"
require "GoboLinux.errors"
require "GoboLinux.fs"
--require "GoboLinux.system"

local errors = GoboLinux.errors
local fs = GoboLinux.fs
local cui = GoboLinux.cui
local system = GoboLinux.system

local modifiers = {
	"LevelPosition=Center",
	"Level=2"
}

local Mounts

-- Local Functions {{{1
local function sort_mounts (a, b)
	local la = (a[1].."/"):gsub("/+$",""):gsub("[^/]",""):len() 
	local lb = (b[1].."/"):gsub("/+$",""):gsub("[^/]",""):len() 
	if la <= lb then 
		return true
	end
	return false
end

-- Steps {{{1
-- ChooseRoot {{{2
local function ChooseRoot (disks)
	return "AskMount", disks, choose_mount_point(disks, nil, "/",{}, {})
end

local function AskMount (disks, mounts, used_partitions)
	return "InstallWarning", disks, ask_mount (disks, mounts, used_partitions)
end

local function InstallWarning (disks, mounts)
	if not install_warning(disks, mounts) then
		return nil, "Installation aborted"
	else
		table.sort(mounts, sort_mounts)
		return "CreateGoboTree", mounts
	end
end

-- CreateGoboTree {{{2
local function CreateGoboTree (mounts)
	if not fs.is_directory(Target) then
		output.log_error("Unable to mount "..Target.." to install")
		return nil
	end
	local tasks = {
		{"Mounting filesystems", function ()
			Mounted = mount_devices(Target, mounts)
			if not Mounted then
				return nil, "Unable to mount devices under "..Target
			end
		end},
		{"Creating GoboLinux Tree", function ()
			if not system.create_tree(Target) then
				return nil, errors.error()
			end
		end},
		{"Creating entries under /System/Variable", function ()
			return  create_var_files(Target)
		end},
		{"Creating fstab file", function ()
		--	table.sort(mounts, sort_mounts)
			return create_fstab(Target, mounts)
		end},
		{"Creating issue file", function () 
			return create_issue(Target)
		end},
		{"Creating hosts file", function () 
			return create_hosts (Target)
		end},
		{"Creating passwd file", function ()
			return create_passwd(Target)
		end},
		{"Creating shadow file", function ()
			return create_shadow(Target)
		end},
		{"Creating group file", function ()
			return create_group(Target)
		end},
		{"Creating gshadow file", function ()
			return create_gshadow(Target)
		end},
		{"Copying files", function ()
			if not fs.cpdir("Resources/Fonts/", Target.."/Files/Fonts") then
				return nil, "Unable to copy Fonts"
			end
			if not fs.cp("Resources/ramfs.cpio.gz", Target.."/System/Kernel/Boot/initramfs.cpio.gz") then
				return nil, errors.error()
			end
			io.open(Target.."/System/Settings/mtab","w")
		end},
	}
	local co = coroutine.create(function ()
		for _, p in ipairs(tasks) do
			coroutine.yield(true, p[1], p[2])
		end
		return true, "GoboLinux Tree Created"
	end)
	if not format_partitions(mounts) then
		return nil, "Unable to format some partitions"
	end
	print()
	cui.title("Creating GoboLinux Tree","Color=BoldGreen",unpack(modifiers))
	print()
	local errors
	_, errors = cui.percent_bar(#tasks, co, "Position=Center", unpack(modifiers))
	if errors then
		return nil, errors
	end
	print()
	-- Make mounts visible to other funcs
	Mounts = mounts
	return nil
end

-- ChooseRootUser {{{2
local function ChooseRootUser (users)
	cui.title("GoboLinux Users","Color=BoldGreen",unpack(modifiers))
	print()
	return "AskUser", root_user(users)
end

local function AskUser (users)
	return "CreateUsers", ask_user(users)
end

local function CreateUsers (users)
	local _, err = create_users(users)
	if err then 
		return nil, nil, err
	end
	return "ConfigureBoot"
end

local function ConfigureBoot ()
	local _, err = configure_boot(Mounts)
	if err then
		return nil, nil, err
	end
	return nil, "GoboPBX installed successful"
end

-- Exported Functions {{{1
-- start {{{2
function start ()
	local StandardSteps = {
		ChooseRoot = ChooseRoot,
		AskMount = AskMount,
		InstallWarning = InstallWarning,
		CreateGoboTree = CreateGoboTree,
		}
	local steps = Steps.new(StandardSteps)
	local disks = get_disks()
	return steps:start("ChooseRoot", disks)
end

-- finish {{{2
function finish ()
	local StandardStepsFinish = {
		ChooseRootUser = ChooseRootUser,
		AskUser = AskUser,
		CreateUsers = CreateUsers,
		ConfigureNetwork = ConfigureNetwork,
		ConfigureBoot = ConfigureBoot,
	}
	local steps = Steps.new(StandardStepsFinish)
	return steps:start("ChooseRootUser", {})
end

