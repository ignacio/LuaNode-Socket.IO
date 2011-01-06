package.path = [[C:\LuaRocks\1.0\lua\?.lua;C:\LuaRocks\1.0\lua\?\init.lua;]] .. package.path
require "luarocks.require"

local socket_io = require "socket-io"

--/**
 --* Important note: this application is not suitable for benchmarks!
 --*/

local http = require('luanode.http')
local url = require('luanode.url')
local fs = require('luanode.fs')

local server = http.createServer(function(self, req, res)
	local function send404(res)
		res:writeHead(404)
		res:write('404')
		res:finish()
	end
	-- your normal server code
	local path = url.parse(req.url).pathname
	if path == "/" then
		res:writeHead(200, {['Content-Type'] = 'text/html'});
		res:write('<h1>Welcome. Try the <a href="/chat.html">chat</a> example.</h1>');
		res:finish();
	
	elseif path == "/json.js" or path == "/chat.html" then
		fs.readFile(process.cwd() .. path, function(err, data)
			if err then 
				return send404(res)
			end
			if path == "/json.js" then
				res:writeHead(200, {['Content-Type'] = 'text/javascript'})
			else
				res:writeHead(200, {['Content-Type'] = 'text/html'})
			end
			res:write(data, 'utf8')
			res:finish()
		end)
	
	else
		send404(res)
	end
end)

server:listen(8080)

local s_io = socket_io(server, {timeout = false})
local buffer = {}
  
s_io:on('connection', function(self, client)
	client:send({ buffer = buffer })
	client:broadcast({ announcement = client.sessionId .. ' connected' })
	
	client:on('message', function(self, message) 
		console.info("Client got message", client.sessionId)
		local msg = { message = {client.sessionId, message} }
		table.insert(buffer, msg)
		if #buffer > 15 then 
			table.remove(buffer, 1)
		end
		client:broadcast(msg)
		console.info("Client done broadcasting")
	end)

	client:on('disconnect', function()
		client:broadcast({ announcement = client.sessionId .. ' disconnected' })
	end)
end)

process:loop()