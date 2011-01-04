# $Id: Makefile,v 1.14 2008/04/04 02:01:01 mascarenhas Exp $

#include config

install:
	mkdir -p $(LUA_LUADIR)
	mkdir -p $(LUA_LUADIR)/socket-io
	mkdir -p $(LUA_LUADIR)/socket-io/socket.io-client
	cp -r socket-io/* $(LUA_LUADIR)/socket-io
	cp -r socket.io-client/* $(LUA_LUADIR)/socket-io/socket.io-client

clean:
#	rm src/fastcgi/lfcgi.o src/fastcgi/lfcgi.so

