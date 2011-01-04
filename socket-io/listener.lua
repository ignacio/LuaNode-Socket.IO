local Class = require "luanode.class"
local EventEmitter = require "luanode.event_emitter"
local json = require "json"
local url = require "luanode.url"
--local sys = require "luanode.sys"
local fs = require "luanode.fs"
local options = require "socket-io.utils".options
local Realm = require "socket-io.realm"
local Client = require "socket-io.client"
local clientVersion = "0.7pre"	-- esto sale de D:\Desarrollo\socket.io-node\support\socket.io-client\lib\io.js (version)

local transports = {
	flashsocket = require("socket-io.transports.flashsocket"),
	--htmlfile = require("socket-io.transports.htmlfile"),
	websocket = require("socket-io.transports.websocket"),
	--["xhr-multipart"] = require("socket-io.transports.xhr-multipart"),
	--["xhr-polling"] = require("socket-io.transports.xhr-polling"),
	--["jsonp-polling"] = require("socket-io.transports.jsonp-polling")
}

--module(..., package.seeall)

Listener = Class.InheritsFrom(EventEmitter)

function Listener:__init (server, options)
	local newListener = Class.construct(Listener)
	
	newListener.server = server
	newListener:options({
		origins = '*:*',
		resource = 'socket.io',
		flashPolicyServer = true,
		transports = {'websocket', 'flashsocket', 'htmlfile', 'xhr-multipart', 'xhr-polling', 'jsonp-polling'},
		transportOptions = {},
		log = console.warn
	}, options)
	
	if not newListener.options.log then
		newListener.options.log = function() end
	end

	newListener.clients = {}
	newListener._clientCount = 0
	newListener._clientFiles = {}
	newListener._realms = {}
  
	local listeners = newListener.server:listeners('request')
	newListener.server:removeAllListeners('request')
	
	newListener.server:addListener('request', function(self, req, res)
		if newListener:check(req, res) then
			return
		end
		for k,v in ipairs(listeners) do
			v(self, req, res)
		end
	end)
  
	newListener.server:addListener('upgrade', function(self, req, socket, head)
		if not newListener:check(req, socket, true, head) then
			socket:finish()
			socket:destroy()
			return true
		end
		return false
	end)
	for k, transport in pairs(transports) do
		if type(transport.init) == "function" then
			transport.init(newListener)
		end
	end
  
	newListener.options.log('socket.io ready - accepting connections')
		
	return newListener
end

for k,v in pairs(options) do
	Listener[k] = v
end
--sys.inherits(Listener, process.EventEmitter)
--for (var i in options) Listener.prototype[i] = options[i]

function Listener:broadcast (message, except, atts)
	for k,client in pairs(self.clients) do
		if not except or ((type(except) == "number" or type(except) == "string") and k ~= except) or 
			(type(except) == "table" and except[client])
		then
			client:send(message, atts)
		end
	end
	return self
end

function Listener:broadcastJSON (message, except, atts)
	atts = atts or {}
	atts['j'] = ""
	return self:broadcast(json.encode(message), except, atts)
end

function Listener:check (req, res, httpUpgrade, head)
	local path = url.parse(req.url).pathname
	
	if path and path:match('^/' .. self.options.resource) then
		--console.warn("check:" .. path)
		local parts = {}
		path:sub(2):gsub("([^/]+)", function(part)
			parts[#parts + 1] = part
		end)
		local clone = {}
		for k,v in pairs(parts) do clone[k] = v end
		--console.debug("parts[1]=", parts[1])
		--console.debug("parts[2]=", parts[2])
		--console.debug("parts[3]=", parts[3])
		table.remove(clone, 1)
		if self:_serveClient(table.concat(clone, "/"), req, res) then
			--console.warn("serveClient returned true")
			return true
		end
		if not transports[parts[2]] then
			console.warn("no transport for " .. parts[2]);
			return false
		end
		if parts[3] and parts[3] ~= "" then
			local cn = self.clients[parts[3]]
			if cn then
				cn:_onConnect(req, res)
			else
				req.connection:finish()
				req.connection:destroy()
				self.options.log('Couldnt find client with session id "' .. parts[2] .. '"')
			end
		else
			self:_onConnection(parts[2], req, res, httpUpgrade, head)
		end
		return true
	end
	return false
end

function Listener:_serveClient (file, req, res)
	local clientPaths = {
		["socket.io.js"] = 'socket.io.js',
		["lib/vendor/web-socket-js/WebSocketMain.swf"] = 'lib/vendor/web-socket-js/WebSocketMain.swf', -- for compat with old clients
		["WebSocketMain.swf"] = 'lib/vendor/web-socket-js/WebSocketMain.swf'
	}
	local types = {
		swf = 'application/x-shockwave-flash',
		js = 'text/javascript'
	}
	
	local function write(path)
		if req.headers['if-none-match'] == clientVersion then
			res:writeHead(304)
			res:finish()
		else
			res:writeHead(200, self._clientFiles[path].headers)
			res:finish(self._clientFiles[path].content, self._clientFiles[path].encoding)
		end
	end
	
	local path = clientPaths[file]
	
	if req.method == 'GET' and path then
		if self._clientFiles[path] then
			write(path)
			return true
		end
		
		local __dirname = process.cwd()
		
		--fs:readFile(__dirname .. '/../../support/socket.io-client/' .. path, function(err, data)
		fs.readFile(__dirname .. '/socket.io-client/' .. path, function(err, data)
			if err then
				res:writeHead(404)
				res:finish('404')
			else
				local ext = path:match("%.([^.]*)$")
				self._clientFiles[path] = {
					headers = {
						['Content-Length'] = #data,
						['Content-Type'] = types[ext],
						ETag = clientVersion
					},
					content = data,
					encoding = (ext == 'swf' and 'binary' or 'utf8')
				}
				write(path)
			end
		end)
		return true
	end
	
	return false
end

--
--
function Listener:realm (realm)
	if not self._realms[realm] then
		self._realms[realm] = Realm(realm, self)
	end
	return self._realms[realm]
end

function Listener:_onClientConnect (client)
	self.clients[client.sessionId] = client
	self.options.log('Client ' .. client.sessionId .. ' connected')
	self:emit('connection', client)
end

function Listener:_onClientDisconnect (client)
	self.clients[client.sessionId] = nil
	self.options.log('Client ' .. client.sessionId .. ' disconnected')
end

function Listener:_onConnection (transport, req, res, httpUpgrade, head)
	self.options.log('Initializing client with transport "' .. transport .. '"')
	transports[transport](self, req, res, self.options.transportOptions[transport], head)
end



return Listener