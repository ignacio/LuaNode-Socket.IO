# LuaNode-Socket.IO #

Sockets for the rest of us (in [LuaNode][1]).

**LuaNode-Socket.IO** is a Socket.IO server for [LuaNode][1]. It's currently only compatible with [Socket.IO][2] v0.7pre, so it is 
not ready for prime-time yet.

## Status #
Currently, the only transports implemented are *websockets* and *flashsockets*, and the server ir only compatible with 
v0.7pre clients. I'll add the other transports soon and eventually add support for v0.6 clients.

## Installation #
The easiest way to install is with [LuaRocks][3].

  - luarocks install full_url
  
You'll also need some Json library for Lua. [LuaJSON][4] or [Json4Lua][] are recommended.

  - luarocks install json4lua

## Documentation #
The usage is the same as [Socket.IO-node][6].

## Example #
See the included file `test.lua`. Once properly installed, you'd be able to do:
    sudo luanode test.lua

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