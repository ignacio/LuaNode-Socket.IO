package = "LnSocketIO"
version = "git-1"
source = {
	url = "git://git.inconcert/inconcert-6/lnsocket-io.git",
	branch = "master",
	dir = "lnsocket-io"
}
description = {
	summary = "LnSocketIO, a LuaNode server compatible with Socket.IO.",
	detailed = [[
LnSocketIO is a Socket.IO server written with LuaNode.
	]],
	license = "MIT/X11",
	homepage = "http://git.inconcert/inconcert-6/lnsocket-io"
}
dependencies = {
	"lua >= 5.1",
}

external_dependencies = {

}
build = {
	type = "make",
	build_pass = false,
	variables = {
		INCONCERT_DEVEL = "$(INCONCERT_DEVEL)",
		LUA_LUADIR = "$(LUADIR)",
		LUA_LIBDIR = "$(LIBDIR)",
		LUA_PREFIX  = "$(PREFIX)"
	}
}
