# LuaNode-Socket.IO #

Sockets for the rest of us (in [LuaNode][1]).

**LuaNode-Socket.IO** is a Socket.IO server for [LuaNode][1]. It's currently only compatible with [Socket.IO][2] 
v0.7pre, so it is not ready for prime-time yet.

## Status #
Currently, the only transports actively supported are *websockets*, *flashsockets*, *xhr-multipart* and *xhr-polling*, 
and the server is only compatible with v0.7pre clients. The other transports are disabled by default because they are a 
bit unstable at the moment. 
I'll add proper support for them soon and eventually add support for v0.6 clients.

## Installation #
The easiest way to install is with [LuaRocks][3].

  - luarocks install https://github.com/ignacio/LuaNode-Socket.IO/raw/master/rockspecs/lnsocketio-github-1.rockspec
  
You'll also need some Json library for Lua. [LuaJSON][4] or [Json4Lua][5] are recommended.

  - luarocks install json4lua
  
And also:

  - luarocks install luuid
  - luarocks install luabitop
  
If luuid gives you trouble to install (especially on MacOSX), you might try the following:

  - Download and extract [e2fsprogs](http://prdownloads.sourceforge.net/e2fsprogs/e2fsprogs-1.41.12.tar.gz)
  - cd e2fsprogs-1.41.12
  - ./configure
  - cd lib/uuid
  - make
  - ./tst_uuid
  - cp uuid.so /usr/local/lib/lua/5.1/

or read [this post](http://li9lo54.tumblr.com/tir_on_mac_workaround).


## Documentation #
The usage is the same as [Socket.IO-node][6].

## Example #
See the included file `test.lua`. Once properly installed, you'd be able to do:

```bash
git clone git://github.com/ignacio/LuaNode-Socket.IO.git lnsocket-io
cd lnsocket-io/
sudo luanode test.lua
```

And then point your browser to `http://localhost:8080`.

## Acknowledgements #

 - Guillermo Rauch ([Guille](http://github.com/guille)) and Arnout Kazemier ([3rd-Eden](http://github.com/3rd-Eden)) for 
[Socket.IO][2].

## License #
**LuaNode-Socket.IO** is available under the MIT license.


[1]: https://github.com/ignacio/LuaNode/
[2]: http://socket.io/
[3]: http://luarocks.org/
[4]: https://github.com/harningt/luajson/
[5]: http://json.luaforge.net/
[6]: https://github.com/LearnBoost/Socket.IO-node/