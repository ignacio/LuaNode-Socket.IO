install:
	mkdir -p $(LUA_LUADIR)
	mkdir -p $(LUA_LUADIR)/socket-io
	mkdir -p $(LUA_LUADIR)/socket-io/socket.io-client
	cp -r socket-io/* $(LUA_LUADIR)/socket-io
	cp -r socket.io-client/* $(LUA_LUADIR)/socket-io/socket.io-client
