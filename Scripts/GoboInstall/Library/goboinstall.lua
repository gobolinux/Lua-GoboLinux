-- vi: set foldmethod=marker foldlevel=0:
--
-- goboinstall.lua
-- ---------------------------------------------------------------------------
--  - 2008
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 25/01/08 19:15:55 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

require "GoboLinux.Package"
require "GoboLinux.Program"
require "GoboLinux.system"
require "GoboLinux.fs"

local fs = GoboLinux.fs
local Program = GoboLinux.Program
local Package = GoboLinux.Package
local system = GoboLinux.system


-- Local Variables {{{1
local partition_info = "/System/Kernel/Status/partitions"
local block_devices = "/System/Kernel/Objects/block/"
local devices = "/System/Kernel/Devices/"
local skel = "/System/Settings/skel/"

-- Partition ids 
local partition_types = {}
partition_types[5] = "Extended"
partition_types[83] = "Linux"
partition_types[82] = "Linux Swap / Solaris"

-- {user, uid, gid, real_name, home, shell}
local users = {
--	{"pbx",0,0, "pbx", "/Users/pbx","/bin/sh"},
	{"nobody",11,11, "nobody", "/tmp",""},
	{"mail",12,11, "pbx", "/Users/pbx","/bin/sh"},
	{"news",13,11, "pbx", "/Users/pbx","/bin/sh"},
	{"uucp",14,11, "pbx", "/Users/pbx","/bin/sh"},
	{"ftp",15,11, "pbx", "/Users/pbx","/bin/sh"},
	{"fibo",21,21, "pbx", "/Users/pbx","/bin/sh"},
}

local groups = {
	--{"pbx",0,{"pbx"}},
	{"bin",1},
	{"daemon",2},
	{"sys",3},
	{"adm",4},
	{"tty",5},
	{"disk",6},
	{"lp",7},
	{"mem",8},
	{"kmem",9},
	{"audio",10},
	{"nobody",11},
	{"uucp",12},
	{"fibo","21"},
	{"users",100},
}

-- Local Functions {{{1
-- Functions to get info about devices {{{2
local function device_is_removable (device)
	local fd = io.open(block_devices..device.."/removable")
	if not fd then return nil end
	local removable = fd:read("*n")
	if removable == 1 then
		fd:close()
		return true
	end
	fd:close()
	return false
end

local function device_size (device, partition)
	local fd = io.open(block_devices..device.."/"..(partition or "").."/size")
	if not fd then return nil end
	local size = fd:read("*n")
	fd:close()
	return tonumber(string.format("%.0f",size / 2048))
end

local function device_model (device)
	local fd = io.open(block_devices..device.."/device/model")
	if not fd then return nil end
	local model = fd:read("*l")
	fd:close()
	return model:gsub("%s*$",""):gsub("^%s*","")
end

local function device_vendor (device)
	local fd = io.open(block_devices..device.."/device/vendor")
	if not fd then return nil end
	local vendor = fd:read("*l")
	fd:close()
	return vendor:gsub("%s+$",""):gsub("^%s*","")
end

local function device_is_disk (device)
	return device:match("sd*") or device:match("hd*")
end

local function device_partition_type (partition)
	local disk = partition:gsub("[%A%d]","")
	local npartition = partition:gsub("%D","")
	local fd = io.popen("sfdisk --id "..devices..disk
		.." "..npartition.. " 2>/dev/null")
	if not fd then return "Unknow" end
	local id = fd:read("*n")
	fd:close()
	if partition_types[id] then 
		return partition_types[id]
	end
	return "Unknow"
end

-- Functions to create disks and partitions table {{{2
-- Adds a disk into the table {{{3
local function add_disk (disks_table, disk)
	-- Set disk info
	if device_is_disk(disk) then
		disks_table[disk] = disks_table[disk] or {
			Partitions = {},
			nPartitions = {}	
		}
		disk_table = disks_table[disk]
		disk_table.Vendor = device_vendor(disk) or "Disk"
		disk_table.Model = device_model(disk) or "Unknow"
		disk_table.Size = device_size(disk)
	end
end

-- Add a partition into the table {{{3
local function add_partition (disks_table, partition)
	local disk = partition:gsub("[%A%d]","")
	if device_partition_type(partition) == "Extended" then return nil end
	-- Set partition info
	if device_is_disk(disk) then
		disks_table[disk] = disks_table[disk] or {
			Partitions = {},
			nPartitions = {}
		}
		local npartitions = #disks_table[disk].nPartitions
		disks_table[disk].nPartitions[npartitions+1] = partition
		disks_table[disk].Partitions = disks_table[disk].Partitions or {}
		disks_table[disk].Partitions[partition] = {
			Size = device_size(disk,partition),
			Type = device_partition_type(partition)
		}
	end
end

-- Set a disk flag {{{3
local function set_disk_flag (disks_table, disk, flag, value)
	if disks_table[disk] then
		disks_table[types][disk][flag] = value
	end
end

-- Set a partition flag {{{3
local function set_partition_flag (disks_table, partition, flag, value)
	local disk = partition:gsub("[%A%d]","")
	if disks_table[disk] and disks_table[disk].Partitions[partition] then
		disks_table[disk].Partitions[partition][flag] = value
	end
end

-- Functions to manage lvm {{{2
local function lvm_support ()
	if fs.is_executable("/bin/lvm") then
		return true
	end
	return false
end

local function get_lvm_devices (disks)
	local fd = io.popen("/bin/lvm pvdisplay -c 2>/dev/null", "r")
	if not fd then return nil end
	for line in fd:lines() do
		partition, volume_group = line:match("(%a+%d+):(%w*)")
		set_partition_flag(disks,partition, "LVM", volume_group)
	end
	fd:close()
	return disks
end


-- Exported Functions {{{1
--- Umount Device {{{2
function umount_device (mount)
	local cmd = "umount "..mount.. " 2>/dev/null"
	if os.execute(cmd) ~= 0 then
		return false
	end
	return true
end

-- Mount Device {{{2
function mount_device (mount, device)
	local cmd = "mount "..devices..device .. " "..mount 
			.. " 2>/dev/null"
	if os.execute(cmd) ~= 0 then
		return false
	end
	return true
end

-- Format partition {{{2
function format_partition (device)
	local cmd = "mkfs.reiserfs -q "..devices.."/"..device 
				.. " >/dev/null 2>&1"
	if os.execute(cmd) ~= 0 then
		return false
	end
	return true
end

-- Get Disk Info {{{2
function get_disks (removables)
	local fd = io.open(partition_info,"r")
	local disks = {
	}
	fd:read("*l")
	fd:read("*l")
	for line in fd:lines() do
		local _,_,entry = line:find("(%a+.*)",0)
		local disk, partition
		if entry:match("%d$") then
			-- partition device
			disk, partition = entry:gsub("[%A%d]",""), entry
			if not removables or (removables and device_is_removable(disk)) then
				add_disk(disks, disk)
				add_partition(disks, partition)
			end
		else
			-- disk device
			disk = entry
			if not removables or (removables and device_is_removable(disk)) then
				add_disk(disks, disk)
			end
		end
	end
	fd:close()
	if lvm_support() then
		return get_lvm_devices(disks)
	end
	return disks
end

-- Get Disk name {{{2
function get_disk_name (disks_list, disk)
	if not disks_list[disk] then return nil end
	local dtable = disks_list[disk]
	return dtable.Vendor.." "..dtable.Model.." ("..disk..")"
		.." ["..tostring(dtable.Size).." Mb]",1
end

-- Get Partition name {{{2
function get_partition_name (disks_list, disk, partition)
	if not disks_list[disk] or not disks_list[disk].Partitions[partition] then
		return nil
	end
	local ptable = disks_list[disk].Partitions[partition]
	local str = partition.." ["..ptable.Size.." Mb]"
	if ptable.LVM then
		str = str.." LVM Physical Volume ["..ptable.LVM.."]"
	else
		str = str .. " "..ptable.Type
	end
	return str
end

-- Get a table with disks choices, to use with cui.ask_list {{{2
function get_disk_choices (disks, n)
	local disk_choices = {}
	for disk in pairs(disks) do
		disk_choices[#disk_choices+1]={get_disk_name(disks ,disk), nil, disk}
	end
	return disk_choices
end

function get_partition_choices (disks, disk, black_list )
	local partition_choices = {}
	for _, partition in pairs(disks[disk].nPartitions) do
		-- Avoid to list used partitions
		if not black_list[partition] then 
			partition_choices[#partition_choices+1] = {
				get_partition_name(disks, disk, partition),
				nil,
				partition
			}
		end
	end
	return partition_choices
end

-- Add some entries under /var {{{2
function create_var_files (target)
	local utmp = target .. "/System/Variable/run/utmp"
	local wtmp = target .. "/System/Variable/log/wtmp"
	local fd = io.open(utmp,"w")
	if not fd then 
		return nil, "Unable to create " ..utmp
	end
	fd:close()
	fd = io.open(wtmp,"w")
	if not fd then
		return nil, "Unable to create ".. wtmp
	end
	fd:close()
	return true
end

-- Generate fstab {{{2
function create_fstab (target, mounts)
	local system_fs = {
		{"Proc Filesystem", "proc", "/System/Kernel/Status","proc"},
		{"System Filesystem", "none", "/System/Kernel/Object","sysfs"},
		{"Pts Filesystem", "none", "/System/Kernel/Devices/pts", "devpts"},
		{"Shm Filesystem", "none", "/System/Kernel/Devices/shm", "tmpfs"},
	}
	local fstab = target .. "/System/Settings/fstab"
	local fd = io.open(fstab,"w")
	if not fd then
		return nil, "Unable to create "..fstab
	end
	fd:write("# Fstab file\n#\n\n")
	for _, m in ipairs(system_fs) do
		fd:write("#"..m[1].."\n"..m[2].." "..m[3].." "..m[4].." defaults 0 0\n\n")
	end
	for _, m in ipairs(mounts) do
		local mount = m[1]
		local device = m[2]
		fd:write("# "..mount.." ["..device.."]\n")
		fd:write(devices..device.." "..mount.." auto defaults 1 0")
	end
	fd:close()
end

-- Generate issue file {{{2
function create_issue (target)
	local issue_text =[[
GoboPBX 1.0
-------------
ias [2007]
-------------
PBX Solutions
-------------

	]]
	local issue = target .. "/System/Settings/issue"
	local fd = io.open(issue,"w")
	if not fd then
		return nil, "Unable to create "..issue
	end
	fd:write(issue_text.."\n")
	fd:close()
end

-- Generate hosts file {{{2
function create_hosts (target)
	local host = "GoboPBX"
	local hosts = target .. "/System/Settings/hosts"
	local fd = io.open(hosts,"w")
	if not fd then 
		return nil, "Unable to create "..hosts
	end
	fd:write("127.0.0.1 localhost.localdomain localhost "..host.."\n")
	fd:close()
end

-- Create passwd file {{{2
function create_passwd (target)
	local file = target .. "/System/Settings/passwd"
	local fd = io.open(file,"w")
	if not fd then 
		return nil, "Unable to create "..file
	end
	table.sort(users, function (a, b) 
		if a[2] <= b[2] then 
			return true 
		end 
		return false end)
	for _,user in ipairs(users) do
		-- write passwd file
		local str = user[1]..":x:"..user[2]..":"..user[3]..":"..user[4]
					..":"..user[5]..":"..user[6]
		fd:write(str.."\n")
	end
	fd:close()
end

-- Create shadow file {{{2
function create_shadow (target)
	local file = target .. "/System/Settings/shadow"
	local fd = io.open(file, "w")
	if not fd then
		return nil, "Unable to create "..file
	end
	for _,user in ipairs(users) do
		-- write shadow file
		-- Use crypt here to store a password
		str = user[1] ..":!:0:0:99999:7:::"
		fd:write(str.."\n")
	end
	fd:close()
end

-- Create group file {{{2
function create_group (target)
	local file = target .. "/System/Settings/group"
	table.sort(groups, function (a, b)
		if tonumber(a[2]) <= tonumber(b[2]) then 
			return true
		end
		return false
		end)
	fd = io.open(file,"w")
	if not fd then
		return nil, "Unable to create "..file
	end
	for _, group in ipairs(groups) do
		local str = group[1]..":x:"..group[2]..":"
		if group[3] then
			for _, user in ipairs(group[3]) do
				str = str..user..","
			end
		end
		str = str:gsub(",$","")
		fd:write(str.."\n")
	end
	fd:close()
end

-- Add a new gorup {{{2
function add_group (target, group)
	local group_file = target .. "/System/Settings/group"
	local fd, err = io.open(group_file,"a")
	if not fd then
		return nil, "Unable to add group "..group[1]
	end
	local str = group[1]..":x:"..group[2]..":"
	fd:write(str.."\n")
	fd:close()
	return true
end

-- Add a new user {{{2
function add_user (target, user)
	local passwd = target .. "/System/Settings/passwd"
	local shadow = target .. "/System/Settings/shadow"
	local group = target .. "/System/Settings/group"
	local group_cp = target .. "/System/Settings/group_cp"
	local fd, err = io.open(passwd,"a")
	if not fd then
		return nil, "Unable to add user "..user[1]
	end
	local str = user[1]..":x:"..user[2]..":"..user[3]..":"..user[4]
				..":"..user[5]..":"..user[6]
	fd:write(str.."\n")
	fd:close()
	fd, err = io.open(shadow,"a")
	if not fd then 
		return nil, "Unable to add user "..user[1]
	end
	local str = user[1] .."::0:0:99999:7:::"
	fd:write(str.."\n")
	fd:close()
	if not user[7] then
		return true
	end
	fs.mv(group, group_cp)
	fd, err = io.open(group_cp,"r")
	if not fd then
		return nil, "Unable to add user "..user[1]
	end
	fd2 = io.open(group,"w")
	for line in fd:lines() do
		local _,_,group = line:find("([^:]+)",0)
		local l = line
		for _, g in ipairs(user[7]) do
			if group == g then
				-- user must to be added to this group
				if line:match(":$") then
					l = line .. user[1]
				else
					l = line .. ","..user[1]
				end
			end
		end
		fd2:write(l.."\n")
	end
	fd:close()
	fd2:close()
	fs.rm(group_cp)
	return true
end

-- Create User home {{{2
function create_user_home (target, user)
	local home = target .. user[5]
	if not fs.mkdir(home) then
		return nil, errors.error()
	end
	-- Copy files in skel
	for file in fs.files(skel) do
		if not fs.cp(file.path, home.."/"..file.name) then
			return nil, errors.error()
		end
	end
	return true
end

-- Create gshadow file {{{2
function create_gshadow (target)
	local file = target .. "/System/Settings/gshadow"
	table.sort(groups, function (a, b)
		if tonumber(a[2]) <= tonumber(b[2]) then 
			return true
		end
		return false
		end)
	fd = io.open(file,"w")
	if not fd then
		return nil, "Unable to create "..file
	end
	for _, group in ipairs(groups) do
		-- write gshadow file
		str = group[1]..":!::"
		fd:write(str.."\n")
	end
	fd:close()
end

-- Create grub menu (menu.lst) {{{2
function create_grubmenu (target)
	local file = target .. "/System/Kernel/Boot/grub/menu.lst"
	local header=[[

default 0
#timeout 5
splashimage (hd0,0)/grub/gobolinux-grub.xpm.gz
foreground 003080
background 80c0ff
color white/blue blue/white

]]
	local fd, err = io.open(file,"w")
	if not fd then 
		return nil, err
	end
	fd:write(header)
	fd:write("\n")
	fd:close()
	return true
end

-- Add entry to grub {{{2
function add_grub_entry (target, boot_device, root_device, boot_options,
								boot_desc)
	local file = target .. "/System/Kernel/Boot/grub/menu.lst"
	local fd,err  = io.open(file, "a")
	if not fd then
		print(err)
		return nil, "Unable to add entry to grub menu"
	end
--	local fd = io.stdout
	local kernelstr = "kernel "
	local initrdstr = "initrd "
	local grubdisk
	local bootdisk=boot_device:gsub("[%A%d]","")
	local rootdisk=root_device:gsub("[%A%d]","")
	local bootpartition = tonumber(boot_device:sub(4,4))
	local rootpartition = tonumber(root_device:sub(4,4))
	if bootdisk:match("sd*") then
		-- Boot is on a removable device
		grubdisk = "(hd0,"..(bootpartition-1)..")"
	else
		-- Boot is on IDE
		grubdisk = "(hd"..string.byte(bootdisk:sub(3,3))-97
						..","..(bootpartition-1)..")"
		kernelstr = kernelstr .. grubdisk
	end
	if boot_device == root_device then
		-- We use the same device for root and boot, so we need to use a
		-- full path to the kernel
		grubdisk = grubdisk .."/System/Kernel/Boot/"
	else
		-- We have a partition used for Boot, so we can safely use
		-- relative paths to the kernel
		grubdisk = grubdisk .."/"
	end
	kernelstr = kernelstr .. grubdisk .. "kernel "
	if rootdisk:match("sd*") then
		-- Root is on a removable device, so we must to use initramfs, and 
		-- assume that boots from sda
		kernelstr = kernelstr .."root=sda"..rootpartition .. " "
		initrdstr = initrdstr .. grubdisk.."initramfs.cpio.gz"
	else
		-- Root is on IDE
		-- TODO: check here for lvm volumes
		initrdstr = nil
		kernelstr = kernelstr .. "root=/dev/"..root_device .. " "
	end
	kernelstr = kernelstr .. boot_options
	fd:write("\n")
	fd:write("title "..boot_desc.."\n")
	fd:write(kernelstr.."\n")
	if initrdstr then
		fd:write(initrdstr.."\n")
	end
	fd:close()
	return true
end

-- Install grub {{{2
function install_grub (boot_device, root_device)
	local cmd = "grub --batch <<EOT"
	local bootdisk = boot_device:gsub("[%A%d]","")
	local bootpartition = tonumber(boot_device:sub(4,4))
	cmd = cmd .. "\ndevice (hd0) /dev/"..bootdisk
	cmd = cmd .. "\nroot (hd0,"..(bootpartition-1)..")"
	if boot_device == root_device then
		cmd = cmd .."\nsetup (hd0)"
	else
		cmd = cmd .. "\nsetup --prefix=/grub (hd0)"
	end
	cmd = cmd .."\nEOT"
	local result = ""
	local fd = io.popen(cmd)
	for line in fd:lines() do
		result = result .. line .."\n"
	end
	fd:close()
	return cmd, result
end

-- Install package {{{2
function install_package2 (target, name, version, arch)
	local package,err  = Package.new(name, version, arch)
	if not package then return nil, err end
	return package:install()
end
function install_package (package)
	return package:install()
end


-- Symlink a package {{{2 
function symlink_package2 (name, version, arch)
	local program = Program.new(name, version)
	if not program then 
		return nil
	end
	program:symlink()
	program:symlinkExecutables()
	program:symlinkLibraries()
	program:symlinkHeaders()
	program:symlinkManuals()
	program:symlinkShared()
	program:symlinkTasks()
	program:symlinkWrappers()
	program:symlinkEnvironment()
	program:installSettings()
	program:symlinkSettings()
	if program:hasUnmanaged() then
		program:installUnmanaged()
	end
	return true
end

function symlink_program (program)
	program:symlink()
	program:symlinkExecutables()
	program:symlinkLibraries()
	program:symlinkHeaders()
	program:symlinkManuals()
	program:symlinkShared()
	program:symlinkTasks()
	program:symlinkWrappers()
	program:symlinkEnvironment()
	program:installSettings()
	program:symlinkSettings()
	if program:hasUnmanaged() then
		program:installUnmanaged()
	end
	return true
end

-- Umount devices {{{2 
function umount_devices (mounted)
	local success = true
	for i=#mounted, 1, -1  do
		local mount = mounted[i]
		success = success and umount_device(mount)
	end
	return success
end

-- Mount devices {{{2 
function mount_devices (target,mounts)
	local mounted = {}
	for _, m in ipairs(mounts) do
		local mount = m[1]
		local device = m[2]
		if not mount_device(target.."/"..mount, device) then
			umount_devices(mounted)
			return false
		else
			mounted[#mounted+1] = target.."/"..mount
		end
	end
	return mounted
end

-- Shrink program {{{2 
function shrink_program (program)
	if not program then
		return nil, "Program not found"
	end
	local path = program.Prefix..program.Programs..program.Name
	program:disableManuals()
	fs.rmdir(path.."/Current/info")
	fs.rmdir(path.."/Current/man")
	fs.rmdir(path.."/Current/doc")
	fs.rmdir(path.."/Current/Resources/Unmanaged")
	for file in program:goboExecutables() do
		local cmd = "strip "..file.name
	end
	return true
end


