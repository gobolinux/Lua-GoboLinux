-- vi: set foldmethod=marker foldlevel=0:
--
-- CommonSteps.lua
-- ---------------------------------------------------------------------------
--  - 2008
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 05/02/08 20:05:12 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

-- Imports
require "GoboLinux.cui"
require "goboinstall"
local cui=GoboLinux.cui

-- Local Variables
local modifiers = {
	"LevelPosition=Center",
	"Level=2"
}

-- choose_mount_point {{{2
function choose_mount_point (disks, disk, mount_point, mounts, used_partitions)
	local title = "Where to Install GoboLinux [ "..mount_point.." ]"
	local diskstr = "Choose a disk to install GoboLinux [ "..mount_point.." ]:"
	local partitionstr = "Choose a partition to install GoboLinux [ "..mount_point.." ]:"
	cui.title(title,"Color=BoldGreen",unpack(modifiers))
	local destdisk, destpartition
	if not disk or not disks[disk] then
		local disks_choices = {}
		for disk in pairs(disks) do
			disks_choices[#disks_choices+1]={get_disk_name(disks ,disk), nil, disk}
		end
		destdisk=cui.ask_list(diskstr, 
					disks_choices, nil, "Position=Center", "Align=Left",
					unpack(modifiers))
		if #disks[destdisk].nPartitions < 2 and removable then
			cui.text("In order to install GoboLinux on a removable device, "..
				"you need to have at least 2 partitions, you can do that"..
				" with fdisk program", "Color=BoldRed",unpack(modifiers))
			return choose_mount_point(disks, disk, mount_point, removable)
		end
	else
		destdisk = disk
	end
	local partitions_choices = {}
	for _, partition in pairs(disks[destdisk].nPartitions) do
		-- Avoid to list used partitions
		if not used_partitions[partition] then 
			partitions_choices[#partitions_choices+1] = {
				get_partition_name(disks, destdisk, partition),
				nil,
				partition
			}
		end
	end
	destpartition=cui.ask_list(partitionstr,
							partitions_choices, nil, 
						"Position=Center", "Align=Left",unpack(modifiers))
	mounts[#mounts+1] = {mount_point, destpartition}
	used_partitions[destpartition] = true
	return mounts, used_partitions, destdisk, destpartition
end

-- choose_root_user {{{2
function choose_root_user (users)
	local root = cui.ask("Please, choose your root user name for the new GoboLinux System?")
	print()
	users[#users+1] = {root, 0, 0, "GoboLinux God!",
			"/Users/"..root, "/bin/sh", {"sys"}}
	return users
end

-- AskMount {{{2
function ask_mount (disks, mounts, used_partitions)
	local text1 = "Do you want to choose more mount points?"
	local text2 = "Please, chose a mount point: "
	local err1 = "You can't choose /System/[...] as a mount point"
	print()
	if not cui.ask_yn(text1, "Color=White",unpack(modifiers)) then
		return mounts
	end
	local mountpoint = cui.ask(text2, "Color=White",unpack(modifiers))
	choose_mount_point(disks, nil, mountpoint, mounts, used_partitions)
	return ask_mount(disks, mounts, used_partitions)
end

-- InstallWarning {{{2
function install_warning (disks, mounts)
	print()
	local text = "You are going to install GoboLinux on:\n\n"
	for _, m in ipairs(mounts) do 
		text = text .. "\t"..get_partition_name(disks, m[2]:gsub("[%A%d]",""),
								m[2])
					.." -> "..m[1].."  - ["
				..get_disk_name(disks, m[2]:gsub("[%A%d]","")).."]\n"
	end
	cui.text(text,unpack(modifiers),"Position=Center","Color=BoldMagenta",unpack(modifiers))
	print()
	if not cui.ask_yn("Do you want to proceed?","Color=White",unpack(modifiers)) then
		return nil
	end
--	table.sort(mounts, sort_mounts)
	return true
end

-- ChooseRootUser {{{2
function root_user (users)
	print()
	local root = cui.ask("Please, choose your root user name for the new GoboLinux System?",
			"Color=White", unpack(modifiers))
	users[#users+1] = {root, 0, 0, "GoboLinux God!",
			"/Users/"..root, "/bin/sh", {"sys"}}
	return users
end

-- ChooseUser {{{2
function ask_user (users)
	print()
	if not cui.ask_yn("Do you want to add more users?","Color=White",unpack(modifiers))	then
		return users
	end
	print()
	local user = cui.ask("User name?","Color=White",unpack(modifiers))
	users[#users+1] = {user, 1000 + (#users-1), 100, user, "/Users/"..user, 
			"/bin/sh", {"users", "audio"}}
	return ask_user(users)
end

-- create_users {{{2
function create_users (users)
	local co = coroutine.create(function ()
		for _, user in ipairs(users) do
			coroutine.yield(nil, "Adding user "..user[1], function () 
				return add_user(Target, user)
			end)
			coroutine.yield(true,"Creating Home for user "..user[1], function () 
				return create_user_home(Target, user)
			end)
		end
		return true, "All users added"
	end)
	local err
	_, err = cui.percent_bar(#users, co, "Position=Center",unpack(modifiers))
	if err then
		return nil, err
	end
	return true
end

-- configure_boot {{{2
function configure_boot (mounts)
   	local ask1 = "Do you want to install grub for your new system?"
	local ask2 = "Are you going to install grub on %s, do you want to continue?"
	local text = "Installing grub on %s"
	local boot_partition, root_partition
	if not cui.ask_yn(ask1,"Color=White",unpack(modifiers)) then
		return true
	end
	for _, m in ipairs(mounts) do
		if m[1] == "/System/Kernel/Boot" then
				boot_partition=m[2]
		elseif m[1] == "/" then
				root_partition = m[2]
		end
	end
	if not boot_partition then 
		boot_partition = root_partition
	end
        if not cui.ask_yn(string.format(ask2,boot_partition:gsub("[%A%d]","")),
					"Color=White",unpack(modifiers)) then
		return true
	end
	cui.text(string.format(text,boot_partition:gsub("[%A%d]","")), 
								unpack(modifiers))
	if not create_grubmenu(Target) then
		return nil, "Unable to create grub menu"
	end
	if not add_grub_entry(Target, boot_partition, 
							root_partition, "noapic vga=0", 
							"GoboLinux - Console") then
		return nil, "Unable to add grub entry"
	end
	local cmd, text
	cmd, text = install_grub(boot_partition, root_partition)
	print()
	cui.text(text, "Color=Magenta", unpack(modifiers))
	print()
	return true
end

function format_partitions (mounts)
	local text1 = "You are going to format %s, this operation will"
		.. " remove all the contents. Do you want to format it?"
	local text2 = "Formating %s (reiserfs)"
	for _, mount in ipairs(mounts) do
		local device = mount[2]
		if cui.ask_yn(string.format(text1, device), "Color=White",
						unpack(modifiers)) then
			cui.text(string.format(text2, device), "Color=White",
						unpack(modifiers))
			if not format_partition(device) then
				return false
			end
		end
	end
	return true
end





