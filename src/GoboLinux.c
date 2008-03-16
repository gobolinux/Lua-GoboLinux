#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "GoboLinux.h"

extern const struct luaL_reg fs [];

int luaopen_GoboLinux_fs_core (lua_State *L) {
	luaL_openlib(L,"GoboLinux.fs",fs, 0);
	return 1;
}
