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
	platforms = {
		windows = {	-- Asumo que en Windows estoy aun con LuaRocks 1
			type = "builtin",
			modules = {
				["socket-io.init"] = "socket-io/init.lua",
				["socket-io.client"] = "socket-io/client.lua",
				["socket-io.data"] = "socket-io/data.lua",
				["socket-io.listener"] = "socket-io/listener.lua",
				["socket-io.realm"] = "socket-io/realm.lua",
				["socket-io.utils"] = "socket-io/utils.lua",
				["socket-io.transports.flashsocket"] = "socket-io/transports/flashsocket.lua",
				["socket-io.transports.websocket"] = "socket-io/transports/websocket.lua",
				["socket-io.transports.xhr-multipart"] = "socket-io/transports/xhr-multipart.lua",
			},
			copy_directories = { "doc" }--, "samples", "test" }
		},
		unix = {
			type = "builtin",
			modules = {
				["socket-io"] = "socket-io/init.lua",
				["socket-io.client"] = "socket-io/client.lua",
				["socket-io.data"] = "socket-io/data.lua",
				["socket-io.listener"] = "socket-io/listener.lua",
				["socket-io.realm"] = "socket-io/realm.lua",
				["socket-io.utils"] = "socket-io/utils.lua",
				["socket-io.transports.flashsocket"] = "socket-io/transports/flashsocket.lua",
				["socket-io.transports.websocket"] = "socket-io/transports/websocket.lua",
				["socket-io.transports.xhr-multipart"] = "socket-io/transports/xhr-multipart.lua",
			},
			copy_directories = { "doc" }--, "samples", "test" }
		}
	}
}
