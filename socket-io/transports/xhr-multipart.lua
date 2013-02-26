local Class = require "luanode.class"
local Client = require "socket-io.client"
local qs = require "luanode.querystring"
local options = require "socket-io.utils".options
local merge = require "socket-io.utils".merge


Multipart = Class.InheritsFrom(Client)
Multipart.__type = "socket-io.Multipart"

function Multipart:__init (...)
	return Class.construct(Multipart, ...)
end

function Multipart:_onConnect (req, res)
	local body = ''
	local headers = {}
	
	-- https://developer.mozilla.org/En/HTTP_Access_Control
	if self:_verifyOrigin(req.headers.origin) then
		headers['Access-Control-Allow-Origin'] = '*'
		headers['Access-Control-Allow-Credentials'] = 'true'
	end
	
	if req.headers['access-control-request-method'] then
		-- CORS preflight message
		headers['Access-Control-Allow-Methods'] = req.headers['access-control-request-method']
		res:writeHead(200, headers)
		res:write('ok')
		res:finish()
		return
	end
	
	if req.method == "GET" then
		Client._onConnect(self, req, res)
		headers['Content-Type'] = 'multipart/x-mixed-replace;boundary="socketio"'
		headers['Connection'] = 'keep-alive'
		self.request.connection:addListener('end', function()
			self:_onClose()	-- beware, that self is not the connection that emits the event, but the Multipart instance
		end)
		self.response.useChunkedEncodingByDefault = false
		self.response.shouldKeepAlive = true
		self.response:writeHead(200, headers)
		self.response:write("--socketio\n")
		if self.response.flush then
			response:flush()
		end
		self:_payload()
		
	elseif req.method == "POST" then
		headers['Content-Type'] = 'text/plain'
		req:addListener('data', function(self, message)
			body = body .. tostring(message)
		end)
		req:addListener('end', function()
			local ok, err = pcall(function()
				-- the request is application/x-www-form-urlencoded, so we need to decode first
				local msg = qs.parse(body)
				self:_onData(msg.data)
			end)
			if not ok then
				-- TODO: proper logging
				console.trace("%s", err)
			end
			res:writeHead(200, headers)
			res:write('ok')
			res:finish()
			body = ''
		end)
	end
end
  
function Multipart:_write (message)
	if self._open then
		if #message == 1 and message:byte(1) == 6 then
			self.response:write("Content-Type: text/plain; charset=us-ascii\n\n")
		else
			self.response:write("Content-Type: text/plain\n\n")
		end
		self.response:write(message .. "\n")
		self.response:write("--socketio\n")
	end
end


return Multipart
