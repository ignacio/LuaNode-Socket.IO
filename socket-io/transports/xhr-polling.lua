local Class = require "luanode.class"
local Client = require "socket-io.client"
local qs = require "luanode.querystring"
local options = require "socket-io.utils".options
local merge = require "socket-io.utils".merge
local null_option = require "socket-io.utils".null_option

Polling = Class.InheritsFrom(Client)
Polling.__type = "socket-io.Polling"

function Polling:__init (...)
	local newClient = Class.construct(Polling, ...)
	
	newClient:__afterConstruct(...)
	
	return newClient
end

function Polling:getOptions ()
	return {
		timeout = null_option, -- no heartbeats
		closeTimeout = 8000,
		duration = 20000
	}
end

function Polling:_onConnect (req, res)
	local body = ''

	if req.method == "GET" then
		Client._onConnect(self, req, res)
		
		self._closeTimeout = setTimeout(function()
			self:_write('')
		end, self.options.duration)
		self:_payload()
	
	elseif req.method == "POST" then
		req:on('data', function(self, message)
			body = body .. message
		end)
		req:on('end', function()
			local headers = { ['Content-Type'] = 'text/plain' }
			if self:_verifyOrigin(req.headers.origin) then
				headers['Access-Control-Allow-Origin'] = '*'
				if req.headers.cookie then
					headers['Access-Control-Allow-Credentials'] = 'true'
				end
			else
				res:writeHead(401)
				res:write('unauthorized')
				res:finish()
				return
			end
			--try {
				-- optimization: just strip first 5 characters here?
				local msg = qs.parse(body)
				self:_onData(msg.data)
			--} catch(e){}
			res:writeHead(200, headers)
			res:write('ok')
			res:finish()
		end)
	end
end

function Polling:_onClose ()
	if self._closeTimeout then
		clearTimeout(self._closeTimeout)
	end
	return Client._onClose(self)
end

function Polling:_write (message)
	if self._open then
		local headers = { 	['Content-Type'] = 'text/plain; charset=UTF-8',
							['Content-Length'] = #message
						}
		-- https://developer.mozilla.org/En/HTTP_Access_Control
		if self.request.headers.origin and self:_verifyOrigin(self.request.headers.origin) then
			headers['Access-Control-Allow-Origin'] = self.request.headers.origin
			if self.request.headers.cookie then
				headers['Access-Control-Allow-Credentials'] = 'true'
			end
		end
		self.response:writeHead(200, headers)
		self.response:write(message)
		self.response:finish()
		self:_onClose()
	end
end

return Polling
