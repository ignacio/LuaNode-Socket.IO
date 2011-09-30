local Class = require "luanode.class"
local Client = require "socket-io.client"
local Stream = require "luanode.net".Stream
local url = require "luanode.url"
local crypto = require "luanode.crypto"
local EventEmitter = require "luanode.event_emitter"
local bit = require "bit"
local Utils = require "luanode.utils"
local options = require "socket-io.utils".options
local merge = require "socket-io.utils".merge


WebSocket = Class.InheritsFrom(Client)
WebSocket.__type = "socket-io.WebSocket"

function WebSocket:__init (...)
	return Class.construct(WebSocket, ...)
end

function WebSocket:_onConnect (req, socket)
	local headers = {}
  
	if not req.connection.setTimeout then
		req.connection:finish()
		return false
	end

	self.parser = Parser()
	self.parser:on('data', function(emitter, ...)
		return self:_onData(...)
	end)
	self.parser:on('error', function(emitter, ...)
		self.listener.options.log(...)
		return self:_onClose(...)
	end)

	Client._onConnect(self, req)
	
	if self.request.headers.upgrade ~= 'WebSocket' or not self:_verifyOrigin(self.request.headers.origin) then
		self.listener.options.log('WebSocket connection invalid or Origin not verified')
		self:_onClose()
		return false
	end
	
	local origin = self.request.headers.origin
	local location = ((origin and origin:match('^https')) and 'wss' or 'ws')
						.. '://' .. self.request.headers.host .. self.request.url
	
	self.waitingForNonce = false
	if self.request.headers['sec-websocket-key1'] then
		--[[  We need to send the 101 response immediately when using Draft 76 with
		a load balancing proxy, such as HAProxy.  In order to protect an
		unsuspecting non-websocket HTTP server, HAProxy will not send the
		8-byte nonce through the connection until the Upgrade: WebSocket
		request has been confirmed by the WebSocket server by a 101 response
		indicating that the server can handle the upgraded protocol.  We
		therefore must send the 101 response immediately, and then wait for
		the nonce to be forwarded to us afterward in order to finish the
		Draft 76 handshake.
		--]]
		
		-- If we don't have the nonce yet, wait for it.
		if (not self.upgradeHead and #self.upgradeHead >= 8) then
			self.waitingForNonce = true
		end
				
		headers = {
			'HTTP/1.1 101 WebSocket Protocol Handshake',
			'Upgrade: WebSocket',
			'Connection: Upgrade',
			'Sec-WebSocket-Origin: ' .. origin,
			'Sec-WebSocket-Location: ' .. location
		}
	
		if self.request.headers['sec-websocket-protocol'] then
			headers[#headers + 1] = 'Sec-WebSocket-Protocol: ' .. self.request.headers['sec-websocket-protocol']
		end
	else
		headers = {
			'HTTP/1.1 101 Web Socket Protocol Handshake',
			'Upgrade: WebSocket',
			'Connection: Upgrade',
			'WebSocket-Origin: ' .. origin,
			'WebSocket-Location: ' .. location
		}
		
		--try {
			self.connection:write( table.concat(headers, "\r\n") .. "\r\n" )
		--} catch(e){
		--this._onClose();
		--}
	end
  
	self.connection:setTimeout(0)
	self.connection:setNoDelay(true)
	self.connection:setEncoding('utf-8')
	
	if self.waitingForNonce then
		-- Since we will be receiving the binary nonce through the normal HTTP
		-- data event, set the connection to 'binary' temporarily
		self.connection:setEncoding("binary")
		self._headers = headers
	else
		if self:_proveReception(headers) then
			self:_payload()
		end
	end
	
	self.buffer = "";
	
	self.connection:addListener('data', function(self_, data)
		if self.waitingForNonce then
			self.buffer = self.buffer .. data
			
			if #self.buffer < 8 then return end
			-- Restore the connection to utf8 encoding after receiving the nonce
			self.connection:setEncoding("utf8")
			self.waitingForNonce = false
			-- Stuff the nonce into the location where it's expected to be
			self.upgradeHead = self.buffer:sub(0, 8)
			self.buffer = ""
			if self:_proveReception(headers) then
				self:_payload()
			end
			return
		end
		
		self.parser:add(data)
	end)
end

-- Two helper functions for websocket's handshake
local function count(data, pattern)
	local n = 0
	for _ in data:gmatch(pattern) do n = n + 1 end
	return n
end

local function pack(num)
	local result = string.char(
		bit.band( bit.rshift(num, 24), 255),
		bit.band( bit.rshift(num, 16), 255),
		bit.band( bit.rshift(num, 8), 255 ),
		bit.band( num, 255 )
	)
	return result
end

-- http://www.whatwg.org/specs/web-apps/current-work/complete/network.html#opening-handshake
function WebSocket:_proveReception (headers)
	local key1 = self.request.headers['sec-websocket-key1']
	local key2 = self.request.headers['sec-websocket-key2']
	
	if key1 and key2 then
		local numkey1 = tonumber( (key1:gsub("[^%d]", "")) )	-- discard the second argument from gsub
		local numkey2 = tonumber( (key2:gsub("[^%d]", "")) )

		local spaces1 = count(key1, "[%s]")
		local spaces2 = count(key2, "[%s]")
		
		if spaces1 == 0 or spaces2 == 0 or numkey1 % spaces1 ~= 0 or numkey2 % spaces2 ~= 0 then
			self.listener.options.log('Invalid WebSocket key: "%s". Dropping connection', k)
			self:_onClose()
			return false
		end
		
		local md5 = crypto.createHash('md5')
		local key1 = pack( math.floor(numkey1 / spaces1) )
		local key2 = pack( math.floor(numkey2 / spaces2) )
		
		md5:update(key1):update(key2):update(self.upgradeHead)
		self.connection:write(table.concat(headers, '\r\n') ..  "\r\n" .. "\r\n"..md5:final("binary"))
	end
	
	return true
end

function WebSocket:_write (message)
  --try {
		--self.connection:write("\0", 'binary')
		--self.connection:write(message, 'utf8')
		--self.connection:write("\255", 'binary')
		self.connection:write("\0"..message.."\255")
	--} catch(e){
		--this._onClose();
	--}
end

WebSocket.httpUpgrade = true

Parser = Class.InheritsFrom(EventEmitter)
Parser.__type = "Parser"

function Parser:__init ()
	local o = Class.construct(Parser)
	o.buffer = ""
	o.i = 1
	return o
end

function Parser:add (data)
	self.buffer = self.buffer .. data
	self:parse()
end

function Parser:parse ()
	for i = self.i, #self.buffer do
		local chr = self.buffer:sub(i, i)
		if i == 1 then
			if chr ~= '\0' then
				self:error('Bad framing. Expected null byte as first frame.\n' .. Utils.DumpDataInHex(self.buffer))
			end
		else
			if chr == '\255' then
				local data = self.buffer:sub(2, i - 1)
				self:emit('data', data)
				self.buffer = self.buffer:sub(i + 1)
				self.i = 1
				return self:parse()
			end
		end
	end
end

function Parser:error (reason)
	self.buffer = ''
	self.i = 1
	--console.error("Bad framing. Expected null byte as first frame")
	self:emit('error', reason)
	return self
end

return WebSocket
