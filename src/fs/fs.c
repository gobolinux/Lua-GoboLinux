#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <sys/sysmacros.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "fs.h"

/*
 * Lua call:
 * 		mknod(path, type, major, minor)
 * 			path: string
 * 			type: ["regular" | "fifo" | "socket" | "char" | "block" ]
 * 			major: number
 * 			minor: number
 *
 */
static int l_mknod (lua_State *L) {
	int major, minor;
	size_t ltype=0;
	char * path, *type;
	path = (char *)luaL_checkstring(L,1);
	type = (char *)luaL_checklstring(L,2,&ltype);
	if (strncmp(type, LUA_NOD_REGULAR,ltype) == 0) {
		if (mknod(path,S_IFREG,(dev_t)NULL) < 0) {
			lua_pushnil(L);
			lua_pushstring(L,strerror(errno));
			return 2;
		}
	}
	else if (strncmp(type, LUA_NOD_FIFO,ltype) == 0) {
		if (mknod(path,S_IFIFO,(dev_t)NULL) < 0) {
			lua_pushnil(L);
			lua_pushstring(L,strerror(errno));
			return 2;
		}
	}
	else if (strncmp(type, LUA_NOD_SOCKET,ltype) == 0) {
		if (mknod(path, S_IFSOCK,(dev_t)NULL) < 0) {
			lua_pushnil(L);
			lua_pushstring(L,strerror(errno));
			return 2;
		}
	} 
	else if (strncmp(type, LUA_NOD_BLOCK,ltype) == 0) {
		major = luaL_checknumber(L,3);
		minor = luaL_checknumber(L,4);
		if (mknod(path, S_IFBLK, makedev(major,minor)) < 0) {
			lua_pushnil(L);
			lua_pushstring(L,strerror(errno));
			return 2;
		}
	}
	else if (strncmp(type, LUA_NOD_CHAR,ltype) == 0) {
		major = luaL_checknumber(L,3);
		minor = luaL_checknumber(L,4);
		if (mknod(path, S_IFCHR, makedev(major, minor)) < 0) {
			lua_pushnil(L);
			lua_pushstring(L,strerror(errno));
			return 2;
		}
	}
	else {
		lua_pushnil(L);
		lua_pushfstring(L,"Type %s unknow\n",type);
		return 2;
	}
	lua_pushboolean(L,LUA_TRUE);
	return 1;
}

static int l_rename (lua_State *L) {
	const char *oldpath, *newpath;
	oldpath = (char *)luaL_checkstring(L,1);
	newpath = (char *)luaL_checkstring(L,2);
	if (rename(oldpath, newpath)) {
		lua_pushnil(L);
		lua_pushstring(L, strerror(errno));
		return 2;
	}

	lua_pushboolean(L,1);
	return 1;
}

const struct luaL_reg fs [] = {
	{"mknod", l_mknod},
	{"mv", l_rename},
	{NULL,NULL}
};
