-- vi: set foldmethod=marker foldlevel=0:
--
-- test.lua
-- ---------------------------------------------------------------------------
--  - 2007
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 07/11/07 21:14:22 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

require "GoboLinux.fs"
local fs=GoboLinux.fs
local major = 23
local minor = 0
local files = {
	fifo={
		"/myfifo",
		"/tmp/myfifo",
		"/tmp/myfifo"},
	char={
		"/mychar",
		"/tmp/mychar",
		"/tmp/mychar"},
	socket={
		"/mysocket",
		"/tmp/mysocket",
		"/tmp/mysocket"},
	block={
		"/myblock",
		"/tmp/myblock",
		"/tmp/myblock"},
	regular={
		"myregular",
		"/tmp/myregular",
		"/tmp/myregular"}
}

for type, files in pairs(files) do
	print("Testing mknod "..type)
	for _,file in ipairs(files) do
		print("\tCreating "..file)
		local success, err = fs.mknod(file, type, major, minor)
		if not success then
			print("\t\tError: "..err)
		end	
	end
end
