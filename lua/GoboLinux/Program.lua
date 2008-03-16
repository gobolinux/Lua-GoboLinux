-- vi: set foldmethod=marker foldlevel=0:
-- Program.lua
-- ---------------------------------------------------------------------------
--  - 2007
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 29/10/07 11:15:11 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

-- Create the new module {{{1
module("GoboLinux.Program",package.seeall)

-- Import {{{1
require "GoboLinux"
require "GoboLinux.errors"
require "GoboLinux.fs"
require "GoboLinux.types"
require "GoboLinux.output"
require "GoboLinux.system"
require "GoboLinux.Program"

local errors = GoboLinux.errors
local output = GoboLinux.output
local types = GoboLinux.types
local fs = GoboLinux.fs
local system = GoboLinux.system
local Package = GoboLinux.Package

-- Local Variables {{{1

local system_mappings = {
	library = "System/Links/Libraries",
	binary = "System/Links/Executables",
	header = "System/Links/Headers",
	shared = "System/Links/shared",
	manual = "System/Links/Manuals",
	task = "System/Links/Tasks",
	environment = "System/Links/Environment",
	configuration = "System/Settings",
	variable = "System/Variable",
}

local system_roles = {
	Libraries = {
		{ "lib" },
		"System/Links/Libraries"
	},
	Executables = {
		{"bin", "sbin"},
		"System/Links/Executables",
	},
	Headers = {
		{"include"},
		"System/Links/Headers",
	},
	Shared = {
		{"Shared"},
		"System/Links/Shared"
	},
	Manuals = {
		{"man", "usr/share/man", "usr/X11/man", "usr/local/man"},
		"System/Links/Manuals"		
	},
	Tasks = {
		{"Resources/Tasks"},
		"System/Links/Tasks",
	},
	Wrappers = {
		{"Resources/Wrappers"},
		"System/Links/Executables",
	},
	Environment = {
		{"Resources/Environment"},
		"System/Links/Environment",
	},
	Settings = {
		{"../Settings"},
		"System/Settings",
	},
	Unmanaged = {
		{"Resources/Unmanaged"},
		nil,
	}
}

-- Local Functions {{{1

local function current_version (name, programs, prefix )
	local current=prefix.."/"..programs.."/"..name.."/Current"
	if fs.is_symlink(current) then
		return fs.readlink(current)
	end
	return nil
end  ----------  end of function current_version  ----------


local function latest_version ( name, programs, prefix )
	local program_path = prefix.."/"..programs.."/"..name
	local latest = ""
	for file in fs.files(program_path) do
		if file.name > latest and 
				(file.name ~= "Current" and file.name ~= "Settings") then
			latest = file.name
		end
	end
	if latest ~= "" then return latest end
	return nil
end  ----------  end of function latest_version  ----------
-- name_to_realname (name, prefix) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------

local function name_to_realname( name, programs, prefix )
	for file in fs.files(prefix.."/"..programs) do
		if string.upper(file.name) == string.upper(name) then
			if file.name ~= "Settings" then
				return file.name
			end
		end
	end
	return nil
end  ----------  end of function name_to_realname  ----------

-- has_version (name, version, programs, prefix) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function has_version ( name, version, programs, prefix )
	for ver in fs.files(prefix.."/"..programs.."/"..name) do
		if ver.name == version then
			return true
		end
	end
	return false
end  ----------  end of function has_version  ----------


-- expand_dir (path) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------

local function expand_dir ( program, dir )
	local dest, orig, tmp_dir
	tmp_dir = fs.dirname(dir).."/"..fs.basename(dir).."_expand"
	if not fs.mkdir(tmp_dir) then
		return false
	end
	dest = tmp_dir:gsub(program:prefix():gsub("%-","%%-"),"")

	for file in fs.files(fs.dereference(fs.readlink(dir),
		fs.dirname(dir))) do

		orig = file.path:gsub(program:prefix():gsub("%-","%%-"),"")
		if not fs.symlink_relative(orig, dest.."/"..file.name, program:prefix()) then
			errors.new_error(errors.error())
			fs.rmdir(tmp_dir)
			return false
		end
	end
	if not fs.rm(dir) then
		errors.new_error(errors.error())
		return false
	end
	if not fs.mv(tmp_dir, dir) then
		errors.new_error(errors.error())
		return false
	end
	return true
end  ----------  end of function expand_dir  ----------

-- link_conflict ( gobofile) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function link_conflict ( gobofile )
--	output.log_error(gobofile.." [CONFLICT]")
	return false
end  ----------  end of function link_conflict  ----------

-- copy_conflict (file) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function copy_conflict ( file )
--	output.log_error(file.." [CONFLICT]")
	return false
end  ----------  end of function copy_conflict  ----------

-- gobofiles (program, role) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function gobofiles ( program, role )
	local paths = {}
	if not system_roles[role] then return function () return nil end end
	local program_path = program:prefix()..program:programs()..program.Name
		.."/"..program.Version
	for i, path in ipairs(system_roles[role][1]) do
		paths[i] = program_path.."/"..path
	end
	iter = fs.tree(unpack(paths))
	return function ()
		local gobofile, level, file
		file, level = iter()
		if file then
			local rep, exec_path, exec_prefix
			exec_path = system_roles[role][2]
			exec_dirs = system_roles[role][1]
			gobofile = file.path:gsub(program_path:gsub("%-","%%-"),program:prefix()..(exec_path or "/"))
			for _, prefix in ipairs(exec_dirs) do
				gobofile, rep = gobofile:gsub("/"..prefix,"",1)
				if rep ~= 0 then
					break
				end
			end
		else return nil end
		return file, gobofile, level
	end

end  ----------  end of function gobofiles  ----------

-- link_gobofile (program, file, gobofile) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function link_gobofile (program, file, gobofile)
	local orig, dest
	orig = file.path:gsub(program:prefix():gsub("%-","%%-"),"")
	dest = gobofile:gsub(program:prefix():gsub("%-","%%-"),"")
	if not fs.is_path(gobofile) then
		if not fs.symlink_relative(orig, dest, program:prefix()) then
			return false
		end
		return true
	end
	if fs.is_symlink(gobofile) then
		-- gobofile is yet a link
		if program:owns(gobofile) then
			-- program owns the link
			if not fs.rm(gobofile) then
				return false
			end
			if not fs.symlink_relative(orig, dest, program:prefix()) then
				return false
			end
			return true
		else
			-- program doesn't own the link, conflict!
			return link_conflict(gobofile)
		end
	end
	-- gobofile isn't a link, conflict!
	return link_conflict(gobofile)
end

-- copy_gobofile (orig, dest) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function copy_gobofile (orig, dest )
	if not fs.is_path(dest) then
		if not fs.cp(orig, dest) then
			return false
		end
		return true
	end
	return copy_conflict(dest)
end  ----------  end of function copy_gobofile  ----------

-- link_gobodir (program, fi le, gobodir) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function link_gobodir ( program, file, gobodir )
	local orig, dest
	orig = file.path:gsub(program:prefix():gsub("%-","%%-"),"")
	dest = gobodir:gsub(program:prefix():gsub("%-","%%-"),"")
	if not fs.is_path(gobodir) then
		-- gobodir doesn't exist
		if not fs.symlink_relative(orig, dest, program:prefix()) then
			return false
		end
		return true, true
	end
	if not fs.is_symlink(gobodir) then
		-- gobodir exists and isn't a link
		if fs.is_directory(gobodir) then
			-- gobodir is a directory, so continue
			return true, false
		else
			-- conflict
			return link_conflict(gobodir)
		end
	end
	if program:owns(gobodir) then
		-- program owns the link
		if not fs.rm(gobodir) then
			return false
		end
		if not fs.symlink_relative(orig, dest, program:prefix()) then
			return false
		end
		return true, true
	end
	-- program doesn't own the link
	if not fs.is_directory(fs.dereference(fs.readlink(gobodir),
			fs.dirname(gobodir))) then
		-- gobodir points to something not being a directory
		return link_conflict(gobodir)
	end
	-- gobodir points to a directory so expand it
	return expand_dir(program, gobodir), false
end  ----------  end of function link_gobodir  ----------

-- copy_gobodir (orig, dest) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function copy_gobodir ( orig, dest )
	if not fs.is_path(dest) then
		-- directory doesn't exists, copy it
		if not fs.cpdir(orig,dest) then
			return false
		end
		return true, true
	end
	if fs.is_directory(dest) then
		return true, false
	end
	return copy_conflict(dest)
end  ----------  end of function copy_gobodir  ----------

-- link_gobolink (program, file, gobolink) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function link_gobolink ( program, file, gobolink )
	local real_file 
	if fs.is_absolute_path(fs.readlink(file.path)) then
		real_file = fs.dereference(program:prefix()..fs.readlink(file.path),
			fs.dirname(file.path))
	else
		real_file = fs.dereference(fs.readlink(file.path),
			fs.dirname(file.path))
	end
	if fs.is_symlink(real_file) then
		return link_gobolink(program, fs.stat(real_file), gobolink)
	end
	if fs.is_directory(real_file) then
		return link_gobodir(program, fs.stat(real_file), gobolink)
	end
	return link_gobofile(program, fs.stat(real_file), gobolink)
end  ----------  end of function link_gobolink  ----------

-- copy_gobolink ( orig, dest) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function copy_gobolink ( orig, dest ) 
	local real_file = fs.readlink(orig)
	if not fs.symlink(real_file, dest) then
		return false
	end
	return true
end  ----------  end of function copy_gobolink  ----------

 -- link_gobofiles (program, iter_func, copy) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function link_gobofiles ( program, iter_func, copy )
	local skip_level = 0
	local success = {}
	local fails = {}
	local skip = false
	for file, gobofile, level in iter_func(program) do
		-- Restore the skip level when we return to the latest level skipped
		if not skip then
			skip_level = level
		else
			if level < skip_level then
				skip = false
				skip_level = level
			end
		end
		if level == skip_level then
			local linked
			if fs.is_directory(file) then
				if copy then
					linked, skip = copy_gobodir(file.path, gobofile)
				else
					linked, skip = link_gobodir(program, file, gobofile)
				end
				if not linked then 
					fails[#fails+1]={gobofile, errors.error()}
				else
					success[#success+1] = gobofile
				end
			else if fs.is_symlink(file) then
				-- file is a symlink
				if copy then
					if not copy_gobolink(file.path, gobofile) then
						fails[#fails+1] = {gobofile, errors.error()}
					else
						success[#success+1] = gobofile
					end
				else
					if not link_gobolink(program, file, gobofile) then
						fails[#fails+1] = {gobofile, errors.error()}
					else
						success[#success+1] = gobofile
					end
				end
			else if fs.is_path(file) then
				-- file isn't dir or symlink
				if copy then
					if not copy_gobofile(file.path, gobofile) then
						fails[#fails] = {gobofile, errors.error()}
					else
						success[#success+1] = gobofile
					end
				else
					if not link_gobofile(program, file, gobofile) then
						fails[#fails+1] = {gobofile, errors.error()}
					else
						success[#success+1] = gobofile
					end
				end
				end  -- fs.is_directory(gobofile)
			end end  -- if fs.is_directory(file)
		end
	end
	return {success=success, fails=fails}
end  ----------  end of function link_gobofiles  ----------

-- disable_gobofiles (program, iter_func) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function disable_gobofiles (program, iter_func)
	local skip_level = 0
	local fails = {}
	local success = {}
	local dirs = {}
	for file, gobofile, level in iter_func(program) do
		if fs.is_symlink(gobofile) then
			-- file is linked
			if program:owns(gobofile) then
				-- symlink owned by program
				if not fs.rm(gobofile) then
					fails[#fails+1] = {gobofile, errors.error()}
				else	
					success[#success+1] = gobofile
				end
			end
		else if fs.is_directory(gobofile) and fs.is_directory(file.path) then
			-- gobofile and file are both dirs
			if not system.system_path(gobofile) then
				dirs[level] = dirs[level] or {}
				dirs[level][#dirs[level]+1] = gobofile
			end
		end end
	end
	-- Remove empty dirs
	for i=#dirs, 1, -1 do
		if type(dirs[i]) == "table" then
			for j=1, #dirs[i] do
				if #posix.dir(dirs[i][j]) == 2 then
					if not fs.rmdir(dirs[i][j]) then
						fails[#fails+1] = {dirs[i][j], errors.error()}
					end
				end
			end
		end
	end
	return {success=success, fails=fails}
end

-- disable_gobosettings (program, iter_func) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- 	* Replace the #posix.dir() call for a function in fs module
-- ---------------------------------------------------------------------------
local function disable_gobosettings ( program, iter_func )
	local skip_level = 0
	local fails = {}
	local success = {}
	local dirs = {}
	for file, gobofile, level in iter_func(program) do
		if fs.is_symlink(gobofile) then
			-- file is linked
			if program:owns(gobofile,"name") then
				-- symlink owned by program
				if not fs.rm(gobofile) then
					fails[#fails+1] = {gobofile, errors.error()}
				else	
					success[#success+1] = gobofile
				end
			end
		else if fs.is_directory(gobofile) and fs.is_directory(file.path) then
			-- gobofile and file are both dirs
			if not system.system_path(gobofile) then
				dirs[level] = dirs[level] or {}
				dirs[level][#dirs[level]+1] = gobofile
			end
		end end
	end
	-- Remove empty dirs
	for i=#dirs, 1, -1 do
		if type(dirs[i]) == "table" then
			for j=1, #dirs[i] do
				if #posix.dir(dirs[i][j]) == 2 then
					if not fs.rmdir(dirs[i][j]) then
						fails[#fails+1] = {dirs[i][j], errors.error()}
					end
				end
			end
		end
	end
	return {success=success, fails=fails}
end  ----------  end of function local function disable_gobosettings  ----------


-- disable_gobounmanaged (program, iter_func) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function disable_gobounmanaged ( program, iter_func )
	local skip_level = 0
	local fails = {}
	local success = {}
	local dirs = {}
	for file, gobofile, level in iter_func(program) do
		if fs.is_symlink(gobofile) and fs.is_symlink(file.path) then
			if not fs.rm(gobofile) then
				fails[#fails+1] = {gobofile, errors.error()}
			else
				success[#success+1] = gobofile
			end
		elseif fs.is_regular(gobofile) and fs.is_regular(file.path) then
			if not fs.rm(gobofile) then
				fails[#fails+1] = {gobofile, errors.error()}
			else
				success[#success+1] = gobofile
			end
		elseif fs.is_directory(gobofile) and 
				not system.system_path(gobofile) then
			dirs[level] = dirs[level] or {}
			dirs[level][#dirs[level]+1] = gobofile
		end
	end
	-- Remove empty dirs
	for i=#dirs, 1, -1 do
		if type(dirs[i]) == "table" then
			for j=1, #dirs[i] do
				if #posix.dir(dirs[i][j]) == 2 then
					if not fs.rmdir(dirs[i][j]) then
						fails[#fails+1] = {dirs[i][j], errors.error()}
					end
				end
			end
		end
	end
	return {success=success, fails=fails}
end  ----------  end of function disable_gobounmanaged  ----------

-- symlink (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function symlink ( self )
	local func_name="Programs:symlink()"
	local cwd, program_path
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return false
	end
	cwd = fs.pwd()
	program_path = self.Prefix.."/"..self.Programs.."/"..self.Name
	if not fs.cd(program_path) then
		fs.cd(cwd)
		return false
	end
	if not fs.is_directory(self.Version) then
		errors.new_error(func_name..":Unable to find Version "..self.Version..
			" for "..self.Name)
		fs.cd(pwd)
		return false
	end
	-- Symlink 'Current' to Version
	if not fs.symlink(self.Version, "Current") then
		errors.new_error(func_name..":Could not symlink "..self.Name.." "..
			self.Version..", is yet symlinked")
		fs.cd(cwd)
		return false
	end
	fs.cd(cwd)
	return true
end  ----------  end of function symlink  ----------

-- symlinkExecutables (self) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function symlinkExecutables ( self )
	local func_name="Programs:symlinkExecutables()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return link_gobofiles(self, self.goboExecutables)
end  ----------  end of function symlinkExecutables  ----------

-- symlinkLibraries (self) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function symlinkLibraries ( self )
	local func_name = "Programs:symlinkLibraries()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return link_gobofiles(self, self.goboLibraries)
end  ----------  end of function symlinkLibraries  ----------

-- symlinkManuals (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function symlinkManuals ( self )
	local func_name = "Programs:symlinkManuals()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return link_gobofiles(self, self.goboManuals)
end  ----------  end of function symlinkManuals  ----------

-- symlinkHeaders (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function symlinkHeaders ( self )
	local func_name = "Programs:symlinkHeaders()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return link_gobofiles(self, self.goboHeaders)
end  ----------  end of function symlinkHeaders  ----------

-- symlinkTasks (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function symlinkTasks ( self )
	local func_name = "Programs:symlinkTasks()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return link_gobofiles(self, self.goboTasks)
end  ----------  end of function symlinkTasks  ----------

-- symlinkEnvironment (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function symlinkEnvironment ( self )
	local func_name = "Programs:symlinkEnvironment()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return link_gobofiles(self, self.goboEnvironment)
end  ----------  end of function symlinkEnvironment  ----------

-- symlinkSettings (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function symlinkSettings ( self )
	local func_name = "Programs:symlinkSettings()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return link_gobofiles(self, self.goboSettings)
end  ----------  end of function symlinkSettings  ----------

-- symlinkShared (self) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function symlinkShared ( self )
	local func_name = "Programs:symlinkShared()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	-- Manage share dirs
	return link_gobofiles(self, self.goboShared)
end  ----------  end of function symlinkShared  ----------

-- symlinkWrappers (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function symlinkWrappers ( self )
	local func_name = "Programs:symlinkWrappers()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return link_gobofiles(self, self.goboWrappers)

end  ----------  end of function symlinkWrappers  ----------
-- installUnmanaged (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function installUnmanaged ( self )
	local func_name = "Programs:installUnmanaged()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return link_gobofiles(self, self.goboUnmanaged, true)
end  ----------  end of function installUnmanaged  ----------

-- installSettings (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function installSettings ( self )
	local func_name = "Programs:installSettings"
	local program_setting, settings
	program_settings = self:prefix()..self:programs()..self.Name
			.."/"..self.Version.."/Resources/Defaults/Settings"
	settings = self:prefix()..self:programs()..self.Name
			.."/Settings"

	if fs.is_directory(program_settings) then
		if fs.is_directory(settings) then
			if not fs.rmdir(settings) then
				errors.new_error(errors.error(), func_name)
				return nil
			end
		end
		if not fs.mkdir(settings) then
			errors.new_error(errors.error(), func_name)
			return nil
		end
		if not fs.cpdir(program_settings, settings) then
			errors.new_error(errors.error(), func_name)
			return nil
		end
	end
	return true
end  ----------  end of function installSettings  ----------
-- disable (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function disable ( self )
	local func_name = "Program:disable()"
	local cwd 

	if not self:isActive() then
		errors.new_error("Program is not actived", func_name)
		return nil
	end

	cwd = fs.pwd()
	if not fs.cd(self:prefix()..self:programs().."/"..self.Name) then
		errors.new_error(errors.error(),func_name)
		return nil
	end
	if fs.readlink("Current") == self.Version then
		if not fs.rm("Current") then
			fs.cd(cwd)
			errors.new_error(errors.error(), func_name)
			return nil
		end
	end
	fs.cd(cwd)
	return true
end  ----------  end of function disable  ----------

-- disableExecutables (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------

local function disableExecutables ( self )
	local func_name = "Program:disableExecutables()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return disable_gobofiles(self, self.goboExecutables)
end  ----------  end of function disableExecutables  ----------

-- disableLibraries (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function disableLibraries ( self )
	local func_name = "Program:disableLibraries()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return disable_gobofiles(self, self.goboLibraries)
end  ----------  end of function disableLibraries  ----------

-- disableHeaders (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function disableHeaders ( self )
	local func_name = "Program:disableHeaders()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return disable_gobofiles(self, self.goboHeaders)
end  ----------  end of function disableHeaders  ----------

-- disableManuals (self) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function disableManuals ( self )
	local func_name = "Program:disableManuals()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return disable_gobofiles(self, self.goboManuals)
end  ----------  end of function disableManuals  ----------

-- disableTasks (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function disableTasks ( self )
	local func_name = "Program:disableTasks()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return disable_gobofiles(self, self.goboTasks)
end  ----------  end of function disableTasks  ----------

-- disableEnvironment (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------

local function disableEnvironment ( self )
	local func_name = "Program:disableEnvironment()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return disable_gobofiles(self, self.goboEnvironment)
end  ----------  end of function disableEnvironment  ----------

-- disableSettings (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function disableSettings ( self )
	local func_name = "Program:disableSettings()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return disable_gobosettings(self, self.goboSettings)
end  ----------  end of function disableSettings  ----------

-- disableUnmanaged (self) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function disableUnmanaged ( self )
	local func_name = "Program:disableUnmanaged()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return disable_gobounmanaged(self, self.goboUnmanaged)
end  ----------  end of function disableUnmanaged  ----------
-- disableShared (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function disableShared ( self )
	local func_name = "Program:disableShared()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return disable_gobofiles(self, self.goboShared)
end  ----------  end of function disableShared  ----------

-- disableWrappers (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function disableWrappers ( self )
	local func_name = "Program:disableWrappers()"
	if not types.check_arg(func_name, 1, self, "PROGRAM") then
		return nil
	end
	return disable_gobofiles(self, self.goboWrappers)

end  ----------  end of function disableWrappers  ----------
-- remove (self) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function remove ( self )
	if self:isActive() then
		if not self:disable() then
			return false
		end
	end
	--[[	if not self:disableExecutables() then
			return false
		end
		if not self:disableLibraries() then
			return false
		end
		if not self:disableHeaders() then
			return false
		end
		if not self:disableShared() then
			return false
		end
		if not self:disableManuals() then
			return false
		end
		if not self:disableTasks() then
			return false
		end
		if not self:disableEnvironment() then
			return false
		end
		if not self:disableSettings() then
			return false
		end
	end--]]
	if not fs.rmdir(self:prefix()..self:programs()..self.Name
			.."/"..self.Version) then
		return false
	end
	return true
end  ----------  end of function remove  ----------

-- owns (self, path) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function owns ( self, path , mode)
	local func_name="Programs:owns()"
	local name, version
	local mode = mode or "name_version" -- default mode
	if not types.check_arg(func_name, 2, path, "PATH_STRING") then
		return false
	end
	name, version = owner(fs.dereference(fs.readlink(path) or path,fs.dirname(path)))
	return switch(mode):caseof {
		name = function () 
			return name == self.Name
		end,
		name_version = function ()
			return name == self.Name and version == self.Version
		end,
	}
end  ----------  end of function owns  ----------

-- isActive (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function isActive ( self )
	local func_name = "Program.isActive()"
	local cwd
	cwd = fs.pwd()
	if not fs.cd(self:prefix()..self:programs()) then
		errors.new_error(errors.error(),func_name)
		return nil
	end
	if fs.readlink(self.Name.."/Current") == self.Version then
		fs.cd(cwd)
		return true
	end
	fs.cd(cwd)
	return false
end  ----------  end of function isActive  ----------

-- hasUnmanaged (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------

local function hasUnmanaged ( self )
	local path = self:prefix()..self:programs().."/"..self.Name.."/"
		..self.Version.."/"..system_roles["Unmanaged"][1][1]
	if fs.is_directory(path) then
		return true
	end
	return false
end  ----------  end of function hasUnmanaged  ----------
-- prefix (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function prefix ( self  )
	local old_GOBO_Prefix, prefix
	old_GOBO_Prefix = GOBO_Prefix
	GOBO_Prefix = self.Prefix
	prefix = system.prefix()
	GOBO_Prefix = old_GOBO_Prefix
	return prefix
end  ----------  end of function prefix  ----------


-- programs (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function programs ( self )
	local old_GOBO_Programs, programs
	old_GOBO_Programs = GOBO_Programs
	GOBO_Programs = self.Programs
	programs = system.programs()
	GOBO_Programs = old_GOBO_Programs
	return programs
end  ----------  end of function programs  ----------


-- executables (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------

local function executables ( self )
	local program_path
	program_path = self:prefix()..self:programs()..self.Name.."/"..self.Version
	return fs.tree(program_path.."/bin",program_path.."/sbin")

end  ----------  end of function executables  ----------


-- goboExecuables (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function goboExecutables ( self )
	return gobofiles(self, "Executables")
end  ----------  end of function goboExecutables  ----------

-- goboLibraries (self) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function goboLibraries ( self )
	return gobofiles(self, "Libraries")
end  ----------  end of function goboLibraries  ----------

-- goboHeaders (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function goboHeaders ( self )
	return gobofiles(self, "Headers")
end  ----------  end of function goboHeaders  ----------

-- goboManuals (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function goboManuals ( self )
	return gobofiles(self, "Manuals")
end  ----------  end of function goboManuals  ----------

-- goboTasks (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function goboTasks ( self )
	return gobofiles(self, "Tasks")
end  ----------  end of function goboTasks  ----------

-- goboEnvironment (self) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function goboEnvironment ( self )
	return gobofiles(self, "Environment")
end  ----------  end of function Environment  ----------

-- goboShared (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function goboShared ( self )
	return gobofiles(self, "Shared")
end  ----------  end of function goboShared  ----------

-- goboSettings (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function goboSettings ( self )
	return gobofiles(self, "Settings")
end  ----------  end of function goboSettings  ----------

-- goboUnmanaged (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------

local function goboUnmanaged ( self )
	return gobofiles(self, "Unmanaged")
end  ----------  end of function goboUnmanaged  ----------

-- goboWrappers (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function goboWrappers ( self )
	return gobofiles(self, "Wrappers")
end  ----------  end of function goboWrappers  ----------
-- Instance Methods {{{1
local methods = {
	isA="Program",
	disable=disable,
	disableExecutables = disableExecutables,
	disableHeaders = disableHeaders,
	disableLibraries = disableLibraries,
	disableManuals = disableManuals,
	disableTasks = disableTasks,
	disableShared = disableShared,
	disableEnvironment = disableEnvironment,
	disableSettings = disableSettings,
	disableUnmanaged = disableUnmanaged,
	disableWrappers = disableWrappers,
	remove=remove,
	symlink = symlink,
	owns = owns,
	symlinkExecutables = symlinkExecutables,
	symlinkLibraries = symlinkLibraries,
	symlinkManuals = symlinkManuals,
	symlinkHeaders = symlinkHeaders,
	symlinkSettings = symlinkSettings,
	symlinkTasks = symlinkTasks,
	symlinkShared = symlinkShared,
	symlinkEnvironment = symlinkEnvironment,
	symlinkWrappers = symlinkWrappers,
	installSettings = installSettings,
	installUnmanaged = installUnmanaged,
	isActive = isActive,
	hasUnmanaged = hasUnmanaged,
	programs = programs,
	prefix = prefix,
	executables = executables,
	goboExecutables = goboExecutables,
	goboLibraries = goboLibraries,
	goboHeaders = goboHeaders,
	goboManuals = goboManuals,
	goboEnvironment = goboEnvironment,
	goboShared = goboShared,
	goboTasks = goboTasks,
	goboWrappers = goboWrappers, 
	goboSettings = goboSettings,
	goboUnmanaged = goboUnmanaged,
}

-- Exported Functions {{{1
-- owner (path) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function owner ( path )
	local func_name="Program.owner()"
	local name, version, iter
	if not types.check_arg(func_name, 1, path, "PATH_STRING") then
		errors.new_error(func_name..":"..errors.error())
		return nil
	end
	local prefix, programs, program, name, version, iter
	prefix = system.prefix():gsub("%-","%%-")
	programs = system.programs():gsub("%-","%%-")
	if not path:match(prefix..programs) then
		return nil
	end
	iter = fs.paths(path:gsub(prefix..programs,""))
	_, name = iter()
	_, version = iter()
	if not name or not version then
		return nil
	end
	return name:gsub("/",""), version:gsub("/","")
end  ----------  end of function owner  ----------


-- installed (name, version) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function is_installed ( name, version )
	local program
	program = new(name, version)
	if program then
		program = nil
		return true
	end
	return false
end  ----------  end of function installed  ----------
-- new (name, version, prefix) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output: 
--	Program Table: {
--		Name
--		Version
--		Prefix
--	}
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function new ( name, version )
	local func_name = "Program.new()"
	local prefix_path
	local programs_path
	local program = {} -- Table for the program instance

	if not types.check_arg(func_name, 1, name, "STRING") then
		return nil
	end
	if not types.check_arg(func_name, 2, version, "STRING", "NIL") then 
		return nil
	end

	program.Prefix = system.prefix()
	program.Programs = system.programs()
	program.Name = name_to_realname(name, program.Programs, program.Prefix)
	if not program.Name then
		errors.new_error("Unable to found program "..name.." in "..
			program.Prefix..program.Programs)
			return nil
	end
	local name = program.Name
	if version then
		-- if a version was passed, use it
		program.Version = version
		if not has_version(name, version, program.Programs, program.Prefix) then
			errors.new_error("Unable to found program "..name.." "..
			version.. " in " ..program.Prefix..program.Programs)
			return nil
		end
	else
		-- try to get the 'Current' version, if there is not a 'Current' one
		-- return the latest
		program.Version = current_version(name, program.Programs, program.Prefix) or
						latest_version(name, program.Programs, program.Prefix)
		if not program.Version then
			errors.new_error("Unable to found any version for "..name.." "..
			" in " ..program.Prefix..program.Programs)
			return nil
		end
	end
	setmetatable(program, {__index=methods})
	return program
end  ----------  end of function new  ----------



-- Types {{{1
-- Type PROGRAM {{{2
types.add_type("PROGRAM", function (v)
		return type(v) == "table" and v.isA and v.isA == "Program"
	end
)

-- Init module {{{1
