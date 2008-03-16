/*
 * fs.h
 *
 * Include file for lua GoboLinux.fs c code
 *
 */

#define LUA_NOD_FIFO "fifo"
#define LUA_NOD_REGULAR "regular"
#define LUA_NOD_SOCKET "socket"
#define LUA_NOD_BLOCK "block"
#define LUA_NOD_CHAR "char"

#define LUA_TRUE 1
#define LUA_FALSE 0

static int l_mknod (lua_State *);
static int l_rename (lua_State *);
