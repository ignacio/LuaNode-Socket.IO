local Class = require "luanode.class"
local EventEmitter = require "luanode.event_emitter"
local json = require "json"
local uuid = require "uuid"
local urlparse = require "luanode.url".parse
local OutgoingMessage = require "luanode.http".OutgoingMessage
local Stream = require "luanode.net".Stream
local Decoder = require "socket-io.data".Decoder
local encode = require "socket-io.data".encode
local encodeMessage = require "socket-io.data".encodeMessage
local decodeMessage = require "socket-io.data".decodeMessage
local options = require "socket-io.utils".options
local merge = require "socket-io.utils".merge

local Client = Class.InheritsFrom(EventEmitter)
Client.__type = "socket-io.Client"

function Client:__init (listener, req, res, options, head)
	local newClient = Class.construct(Client)
	newClient.listener = listener

	-- since this refers to 'getOptions' and that is defined in a child class, I can't do this here
	--newClient:options(merge({
		--ignoreEmptyOrigin = true,
		--timeout = 8000,
		--heartbeatInterval = 10000,
		--closeTimeout = 0
	--}, newClient.getOptions and newClient:getOptions() or {}), options)
		
	newClient.connections = 0
	newClient._open = false
	newClient._heartbeats = 0
	newClient.connected = false
	newClient.upgradeHead = head
	newClient.decoder = Decoder()
	newClient.decoder:on('data', function(self, ...)
		newClient:_onMessage(...)
	end)
	
	--newClient:_onConnect(req, res)	-- same cause as "getOptions".
	-- the method afterConstruct will be called later
	
	return newClient
end

function Client:__afterConstruct (listener, req, res, options, head)
	self:options(merge({
		ignoreEmptyOrigin = true,
		timeout = 8000,
		heartbeatInterval = 10000,
		closeTimeout = 0
	}, self.getOptions and self:getOptions() or {}), options)
	
	self:_onConnect(req, res)
end

--
--
function Client:send (message, anns)
	anns = anns or {}
	if type(message) == 'table' then
		anns['j'] = ""
		message = json.encode(message)
	end
	return self:write('1', encodeMessage(message, anns))
end

--
--
function Client:sendJSON (message, anns)
	anns = anns or {}
	anns['j'] = ""
	return self:send(json.encode(message), anns)
end

--
--
function Client:write (type, data)
	if not self._open then
		return self:_queue(type, data)
	end
	return self:_write(encode({type, data}))
end

--
--
function Client:broadcast (message, anns)
	if not self.sessionId then
		return self
	end
	self.listener:broadcast(message, self.sessionId, anns)
	return self
end

--
--
function Client:_onData (data)
	self.decoder:add(data)
end

--
--
function Client:_onMessage (type, data)
	if type == "0" then
		self:_onDisconnect()
	elseif type == "1" then
		local msg = decodeMessage(data)
		-- handle json decoding
		if msg[2].j then
			msg[1] = json.decode(msg[1])
		end
		self:emit("message", msg[1], msg[2])
	
	elseif type == "2" then
		self:_onHeartbeat(data)
	end
end

--
--
function Client:_onConnect (req, res)
	local attachConnection = not self.connection
 	
	self.request = req
	self.response = res
	self.connection = req.connection
	
	if not attachConnection then
		attachConnetion = (not attachConnection and not self.connection.eventsAttached) -- <-- nuevo
	end
	self.connection.eventsAttached = true
	
	if attachConnection then
		local function destroyConnection()
			self:_onClose()
			if self.connection then
				self.connection:destroy()
			end
		end
		self.connection:addListener("end", destroyConnection)
		self.connection:addListener("timeout", destroyConnection)
		self.connection:addListener("error", destroyConnection)
	end
	
	if req then
		local function destroyRequest()
			if req.destroy then
				req:destroy()
			end
		end
		req:addListener("error", destroyRequest)
		req:addListener("timeout", destroyRequest)
		if res then
			local function destroyResponse()
				if res.destroy then
					res:destroy()
				end
			end
			res:addListener("error", destroyResponse)
			res:addListener("timeout", destroyResponse)
		end
		if self._disconnectTimeout then
			clearTimeout(self._disconnectTimeout)
		end
	end
end

--
--
function Client:_payload ()
	self._writeQueue = self._writeQueue or {}
	self.connections = self.connections + 1
	self.connected = true
	self._open = true
  
	if not self.handshaked then
		self:_generateSessionId()
		table.insert(self._writeQueue, 1, {'3', self.sessionId})
		self.handshaked = true
	end
  
	-- we dispatch the encoded current queue
	-- in the future encoding will be handled by _write, that way we can
	-- avoid framing for protocols with framing built-in (WebSocket)
	if #self._writeQueue > 0 then
		self:_write(encode(self._writeQueue))
		self._writeQueue = {}
	end

	-- if this is the first connection we emit the 'connection' ev
	if self.connections == 1 then
		self.listener:_onClientConnect(self)
	end

	-- send the timeout
	if self.options.timeout then
		self:_heartbeat()
	end
end

--
--
function Client:_heartbeat ()
	self._heartbeatInterval = setTimeout(function()
		self._heartbeats = self._heartbeats + 1
		self:write('2', self._heartbeats)
		self._heartbeatTimeout = setTimeout(function()
			self:_onClose()
		end, self.options.timeout)
	end, self.options.heartbeatInterval)
end

--
--
function Client:_onHeartbeat (h)
	if tonumber(h) == self._heartbeats then
		clearTimeout(self._heartbeatTimeout)
		self:_heartbeat()
	end
end

--
--
function Client:_onClose (skipDisconnect)
	if not self._open then
		return self
	end	
	if self._heartbeatInterval then clearTimeout(self._heartbeatInterval) end
	if self._heartbeatTimeout then clearTimeout(self._heartbeatTimeout) end
	self._open = false
	self.request = nil
	self.response = nil
	if skipDisconnect ~= false then
		if self.handshaked then
			self._disconnectTimeout = setTimeout(function()
				self:_onDisconnect()
			end, self.options.closeTimeout)
		else
			self:_onDisconnect()
		end
	end
end

--
--
function Client:_onDisconnect ()
	if self._open then self:_onClose(true) end
	if self._disconnectTimeout then clearTimeout(self._disconnectTimeout) end
	self._writeQueue = {}
	self.connected = false
	if self.handshaked then
		self:emit('disconnect')
		self.listener:_onClientDisconnect(self)
		self.handshaked = false
	end
end

--
--
function Client:_queue (type, data)
	self._writeQueue = self._writeQueue or {}
	table.insert(self._writeQueue, {type, data})
	return self
end

--
--
function Client:_generateSessionId ()
	self.sessionId = uuid.new()
	self.sessionId = self.sessionId:gsub("%-", "")
	return self
end

--
--
function Client:_verifyOrigin (origin)
	local origins = self.listener.options.origins

	if origins:match('*:*') then
		return true
	end
  
	if origin then
		local parts = urlparse(origin)
		return origins:find(parts.host .. ':' .. parts.port)
			or origins:find(parts.host .. ':*')
			or origins:find('*:' .. parts.port)
	end
	
	return self.options.ignoreEmptyOrigin
end

for k,v in pairs(options) do
	Client[k] = v
end

return Client