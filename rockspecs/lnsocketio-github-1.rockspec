package = "LnSocketIO"
version = "github-1"
source = {
	url = "git://github.com/ignacio/LuaNode-Socket.IO.git",
	branch = "master",
	dir = "LuaNode-Socket.IO"
}
description = {
	summary = "LnSocketIO, a LuaNode server compatible with Socket.IO.",
	detailed = [[
LnSocketIO is a Socket.IO server written with LuaNode.
	]],
	license = "MIT/X11",
	homepage = "https://github.com/ignacio/LuaNode-Socket.IO"
}
dependencies = {
	"lua >= 5.1", "luabitop"
}

external_dependencies = {

}
build = {
	type = "make",
	build_pass = false,
	variables = {
		LUA_LUADIR = "$(LUADIR)",
		LUA_LIBDIR = "$(LIBDIR)",
		LUA_PREFIX  = "$(PREFIX)"
	}
}
