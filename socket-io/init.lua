local Io = {}

Io.Listener = require "socket-io.listener"

listen = function(server, options)
	return Listener(server, options)
end

return listen