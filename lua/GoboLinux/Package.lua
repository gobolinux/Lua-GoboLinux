-- vi: set foldmethod=marker foldlevel=0:
--
-- Package.lua (Class)
-- ---------------------------------------------------------------------------
--  - 2007
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 29/10/07 11:15:02 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

-- Create the new module {{{1
module("GoboLinux.Package",package.seeall)

-- Import {{{1
require "GoboLinux"
require "GoboLinux.output"
require "GoboLinux.errors"
require "GoboLinux.fs"
require "GoboLinux.types"
require "GoboLinux.Program"
require "GoboLinux.system"
require "tar"

local output = GoboLinux.output
local errors = GoboLinux.errors
local fs = GoboLinux.fs
local types = GoboLinux.types
local Program = GoboLinux.Program
local system = GoboLinux.system

-- Local Variables {{{1
local config_file = "Package.conf"
local package_dir = "/Files/Compile/PackedRecipes"

local package_regexp = ".+%-%-.+%-%-.+tar.bz2"
local package_capture = "(.+)%-%-(.+)%-%-(.+).tar.bz2"
local revision_regexp = "%-r%d+"


-- Local Functions {{{1
-- find_package (name, version) {{{2
-- ---------------------------------------------------------------------------
-- @input:
--		name: String
--		version: String | NIL
-- @output:
--		String
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function find_local_package (name, version, arch)
	local package_regexp = ("^"..name.."--"..(version or "").."(.+)--"
		..(arch or system.arch())..".tar.bz2"):gsub("%-","%%-")
	local matchs, newest_package
	matchs = {}
	for package in fs.files(GoboLinux.PACKAGES) do
		if package.name:upper():match(package_regexp:upper()) then
			matchs[#matchs+1]=package.name
		end
	end
	if #matchs == 0 then
		return nil
	end
	-- Try to found the latest version
	newest_package = matchs[1]
	for _, package in ipairs(matchs) do
		if get_version(package) > get_version(newest_package) then
			newest_package = package
		end
	end
	return GoboLinux.PACKAGES.."/"..newest_package
end

-- install (self) {{{2
-- ---------------------------------------------------------------------------
-- @input:
--		self: Package Instace
-- @output:
--		Boolean
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------

local function install (self)
	local func_name="Package:install()"
	local prefix
	local programs
	if not types.check_arg(func_name, 1, self, "PACKAGE") then
		return nil
	end
	if not types.check_type(path, "DIRECTORY_STRING", "NIL") then
		errors.new_error("Path not found: "..path,func_name)
		return nil
	end
	local path = system.prefix()..system.programs()
	if not fs.is_writable(path) or not fs.is_readable(path) then
		errors.new_error("Could not install "..self.Name.." "..self.Version..
			". Can't write on "..path..".", fun_name)
		return nil
	end
	local tarfile, err = tar.open(self.Location,"r","bzip2")
	if not tarfile:extractAll(path) then
		errors.new_error(err,func_name)
		tarfile:close()
		return nil
	end
	tarfile:close()
	local program = Program.new(self.Name, self.Version)
	return program
end  ----------  end of function install  ----------

-- sign (self) {{{2
-- ---------------------------------------------------------------------------
-- @input:
--		self: Package Instance
-- @output:
--		Boolean
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------

local function sign (self)
	return
end  ----------  end of function local sign  ----------

-- Instance Methods {{{1

local methods = {
	install = install,
	sign = sign,
	isA = "Package"
}

-- Exported Functions {{{1
-- get_name (str) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function get_name ( str )
	if not string.match(str,package_regexp) then 
		return nil
	else
		return string.gsub(str, package_capture, "%1")
	end
end  ----------  end of function get_name  ----------


 -- get_version (str) {{{2  
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function get_version ( str, get_rev )
	local ver
	local rev_start
	if not string.match(str, package_regexp) then
		return nil
	end
	ver = string.gsub(str, package_capture, "%2")
	rev_start = ver:find(revision_regexp)
--	if rev_start then
--		rev_start = rev_start - 1
--	else
	if not rev_start then
		rev_start = ver:len()
	else
		rev_start = rev_start - 1
	end
	if get_rev then
		-- return revision
		local rev = ver:sub(rev_start+2, ver:len())
		if rev ~= "" then
			return rev
		end
		return nil
	end
	-- return version
	return ver:sub(1,rev_start)
end  ----------  end of function get_version  ----------

-- get_revision (str) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function get_revision  ( str )
	return get_version(str, true)
end  ----------  end of function get_revision   ----------

-- get_architecture () {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function get_architecture (str)
	if not string.match(str, package_regexp) then
		return nil
	end
	return string.gsub(str, package_capture, "%3")
end ----------- end of function get_architecture  ----------

-- new (name, version) {{{2
-- ---------------------------------------------------------------------------
-- @input:
--		name: String
--		version: String | NIL
-- @output:
--		Package Instance
-- ---------------------------------------------------------------------------
-- Description: Constructor for Pacakge class
-- Package Instace:
--	Name
--	Version
--	Location
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function new (name, version, arch)
	local func_name="Package:new()"
	if not types.check_type(name,"STRING") then 
		return nil
	end
	if not types.check_type(version,"STRING","NIL") then
		return nil
	end
	local new = {}
	new.Location = find_local_package(name, version, arch)
	if not new.Location then
		errors.new_error("Package for "..name.." " ..(version or "")..
			" not found.", func_name)
		return nil
	end
	new.Version = get_version(fs.basename(new.Location))
	new.Name = get_name(fs.basename(new.Location))
	new.Revision = get_revision(fs.basename(new.Location)) or "r0"
	-- set metatable to package functions
	setmetatable(new,{ __index=methods})
	output.unregister_name()
	return new
end  ----------  end of function new  ----------


-- newFromFile (file) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function newFromFile ( file )
	local func_name="Package:newFromFile()"
	if not fs.is_regular(file) then
		errors.new_error("Unable to open: "..file, func_name)
		return nil
	end
	local new = {}
	new.Name = get_name(file)
	if not new.Name then
		errors.new_error("Bad package file `"..file.."'.", func_name)
		return nil
	end
	new.Version = get_version(file)
	if not new.Version then
		errors.new_error("Bad package file `"..file.."'.", func_name)
		return nil
	end
	new.Architecture = get_architecture(file)
	if not new.Architecture then
		errors.new_error("Bad package file name: "..file
				..", unknow Architecture")
		return nil
	end
	new.Revision = get_revision(file) or "r0"
	print("Revision: "..new.Revision)
	new.Location = file
	setmetatable(new, {__index=methods})
	output.unregister_name()
	return new
end  ----------  end of function newFromFile  ----------

-- Types {{{1
-- Type PACKAGE {{{2
GoboLinux.types.add_type("PACKAGE", function (v)
		if not type(v) == "table" or not v.isA == "Package" then
			return false
		end
		return true
	end
)

--Type PACKAGE_STRING {{{2
GoboLinux.types.add_type("PACKAGE_STRING", function (v)
	if not type(v) == "string" then
		return false
	end
	return true
end
)

-- Init module {{{1
GoboLinux.source_config(config_file)
