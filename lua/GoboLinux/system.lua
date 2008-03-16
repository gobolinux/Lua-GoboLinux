-- vi:set foldmethod=marker foldlevel=0:
--
-- system.lua
-- ---------------------------------------------------------------------------
-- GoboLua Project - 2007
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 04/11/07 01:27:16 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------
-- Create module {{{1
module("GoboLinux.system",package.seeall)

-- Imports {{{1
require "GoboLinux"
require "GoboLinux.errors"
require "GoboLinux.fs"
require "GoboLinux.types"
require "GoboLinux.output"
require "posix"

local output = GoboLinux.output
local errors = GoboLinux.errors
local fs = GoboLinux.fs
local types = GoboLinux.types

-- Local Variables {{{1
local gobo_tree = { 
	Tree = {
		{"Programs"},
		{"System/Settings",
			{"etc"}},
		{"System/Links/Executables",
			{"sbin","bin","usr/bin","usr/sbin"}},
		{"System/Links/Environment"},
		{"System/Links/Libraries",
			{"lib","usr/lib"}},
		{"System/Links/Headers",
			{"usr/include"}},
		{"System/Links/Shared",
			{"usr/share"}},
		{"System/Links/Manuals",
			{"usr/man"}},
		{"System/Kernel/Devices",
			{"dev"}},
		{"System/Kernel/Status",
			{"proc"}},
		{"System/Kernel/Objects",
			{"sys"}},
		{"System/Kernel/Modules"},
		{"System/Kernel/Boot"},
	},
	Devices = {
		"System/Kernel/Devices", 
		{
		audio={"c",14,4},
		tty={"c",4, 
        	{0,12}},
        console={"c",5,1},
        dsp={"c",14,3},
        fb0={"c",29,0},
        psaux={"c",10,1},
        gpmclt={"c",10,33},
		loop={"b",7,
        	{0,1}},
        null={"c",1,3},
        ram0={"b",1,0},
        random={"c",1,8},
        ttyS={"c",4,
        	{64,65}},
        urandom={"c",1,9},
        zero={"c",1,5},
	}}
}

local settings_path = "/System/Settings/Lua-GoboLinux/"
local config_file = "system.conf"

local GOBO_PREFIX = "/"
local GOBO_PROGRAMS = "Programs/"

-- Exported Variables
TreeTemplate = gobo_tree

-- Local Functions {{{1

-- Exported Functions {{{1
-- create_tree (tree, path) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- 		tree: TABLE - Table where to read the tree structure.
--		path: DIRECTORY_STRING - Place to where put the new gobo tree.
-- @output:
-- 		BOOLEAN
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function create_tree ( path, as_user )
	local cwd, devices_dir
	if not types.check_type(path,"DIRECTORY_STRING") then
		return false
	end
	output.log_verbose("Creating a new GoboLinux tree under " .. path, 1)
	if not TreeTemplate.Tree or not TreeTemplate.Devices then
		errors.new_error("GoboLinux.system.TreeTemplate table is not valid"..
			", please check it at "..config_file)
		return false
	end
	cwd = fs.pwd()
	if not fs.cd(path) then return false end
	-- Create directories
	for _, entry in pairs(TreeTemplate.Tree) do
		local dir, links
		dir=entry[1]
		links = entry[2]
		if not fs.mkdir(dir) then 
			fs.cd(cwd)
			return false 
		end
		if links then
			-- create legacy symlinks
			if type(links) == "table" then
				-- create so many symlynks
				for _, link in pairs(links) do
					local symlink, cwd
					cwd = fs.pwd()
					symlink = path.."/"..link
					if not fs.mkdir_butlast(link) then 
						fs.cd(cwd)
						return false
					end
					if not fs.symlink_relative(dir, link) then
						fs.cd(cwd)
						return false
					end
				end
			else
				-- create only one symlink
				if not fs.mkdir_butlast(link) then
					fs.cd(cwd)
					return false
				end
				if not fs.symlink(dir, link) then 
					fs.cd(cwd)
					return false 
				end
			end
		end
	end
	-- Create Devices
	if posix.getprocessid().euid > 0 and as_user then
		-- We can't create devices, so don't create them
		fs.cd(cwd)
		return true
	end
	devices_dir = TreeTemplate.Devices[1] or "System/Kernel/Devices"
	for device, entry in pairs(TreeTemplate.Devices[2] or {}) do
		local err, mode, major, minor
		mode = entry[1]
		major = entry[2]
		minor = entry[3]
		if type(minor) == "table" then
			for i, nminor in ipairs(minor) do
				_, err = fs.mknod(devices_dir.."/"..device..tostring(i-1),
						mode, major, nminor)
				if err then
					errors.new_error(err)
					fs.cd(cwd)
					return false
				end
				posix.chmod(devices_dir.."/"..device..tostring(i-1),"rw-rw----")
			end
		else
			_, err = fs.mknod(devices_dir.."/"..device, mode, major, minor)
			if err then
				errors.new_error(err)
				fs.cd(cwd)
				return false
			end
			posix.chmod(devices_dir.."/"..device,"rw-rw----")
		end
	end
	fs.cd(cwd)
	return true
end  ----------  end of function create_tree  ----------


-- prefix () {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function prefix (  )
	return string.gsub((GOBO_Prefix or GOBO_PREFIX).."/","/+$","/")
end  ----------  end of function prefix  ----------


-- programs () {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function programs ( programs )
	local programs_path
	programs_path=string.gsub((GOBO_Programs or GOBO_PROGRAMS),"^/+","").."/"
	return programs_path:gsub("/+$","/")
end  ----------  end of function programs  ----------

-- system_path (path) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function system_path ( path )
	local system_paths = {
		System = { 
			Kernel = {
				Modules = {},
				Boot = {},
				Devices = {},
				Status = {},
				Objects = {},
			},
			Links = {
				Executables = {},
				Shared = {},
				Manuals = {},
				Libraries = {},
				Headers = {},
				Environment = {},
			},
			Settings = {}
		},
		Files = {
			Compile = {
				Recipes = {},
				Sources = {},
				LocalRecipes = {},
				Archives = {},
				PackedRecipes = {},
			},
			Descriptions = {},
			Documentation = {},
			Fonts = {},
			Fortunes = {},
			Plugins = {},
			MySQL = {},
			WWW = {},
			Codecs = {},
		},
		Depot = {
			Wallpapers = {},
			Packages = {},
		},
		Programs = {},
		Users = {},
	}
	if not types.check_type(path,"DIRECTORY_STRING") then
		return false
	end
	local prefix = prefix():gsub("%-","%%-")
	local t = system_paths
	-- Iterate over each element in path to see if path is a system path
	for _,path in fs.paths(path:gsub("%/+","/"):gsub(prefix,"")) do
		if t[path:gsub("%/","")] then
			t = t[path:gsub("%/","")]
		else
			return false
		end
	end
	return true
end  ----------  end of function system_path  ----------

-- arch () {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function arch (  )
	return posix.uname():match("([%w]+)$")
end  ----------  end of function arch  ----------


-- ask_yn ( str) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function ask_yn ( str )
	if not str then return nil end
	local answer
	io.write(str .. "(y/n) ")
	answer = io.read(1)
	while answer ~= 'y' and answer ~= 'n' do
		io.write('\n'..str .. "(y/n) ")
		answer = io.read(1)
	end
	if answer == 'y' then return true
	else return false 
	end
end  ----------  end of function ask_yn  ----------

-- ask_choice (str, choices) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function ask_choice ( str, choices )
	if not str then return nil end
	if not choices or not type(choices) == "table" then
		return nil
	end
	local answer
	local fmt_str = "%s "
	local choice_suffix={}
	local choice_prefix = {}
	for _, choice in ipairs(choices) do
		choice_prefix[choice:match("."):lower()]=true
		choice_suffix[#choice_suffix+1]=choice:match(".(.*)")
		fmt_str = fmt_str.."["..choice:match("."):lower().."]%s/"
	end
	io.write(string.format(fmt_str:gsub("/$",""),str,unpack(choice_suffix)).."\n")
	while true do
		answer = io.read(1)
		if choice_prefix[answer] then break end
	end
	return answer
end  ----------  end of function ask_choice  ----------


-- ask_choice_list (str, choices) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------

function ask_choice_list ( str, choices_list, extra_list )
	if not str then return nil end
	if not choices_list or not type(choices_list) == "table" then
		return nil
	end
	local extra_list = extra_list or {}
	local answer
	local choices = {}
	local choices_text = {}
	-- add choices
	for i, l in ipairs(choices_list) do
		local text, desc, choice = l[1], l[2], l[3]
		if not text or not choice then return nil end
		local choice_text = "["..tostring(i).."] "..text
		if desc then
			choice_text=choice_text.."\n\t\t"..desc
		end
		choices_text[i] = choice_text
		choices[tostring(i)] = choice
	end
	-- add extra_list 
	for i, l in ipairs(extra_list) do
		local text, choice = l[1], l[3]
		if not text or not choice then return nil end
		choices[text] = choice
	end
	for _, choice in ipairs(choices_text) do
		--io.write("\t"..choice.."\n")
		output.log_terse(choice,1)
	end
	output.log_terse("")
	output.log_terse(str)
	while true do 
		answer = io.read("*l")
		if choices[answer]then 
			return choices[answer]
		end
	end
end  ----------  end of function ask_choice_list  ----------


-- Initialize module {{{1
GoboLinux.source_config(config_file)
