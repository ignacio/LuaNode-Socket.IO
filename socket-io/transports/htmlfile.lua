local Class = require "luanode.class"
local Client = require "socket-io.client"
local qs = require "luanode.querystring"
local options = require "socket-io.utils".options
local merge = require "socket-io.utils".merge
local json = require "json"


HTMLFile = Class.InheritsFrom(Client)
HTMLFile.__type = "socket-io.HTMLFile"


function HTMLFile:__init (...)
	local newClient = Class.construct(HTMLFile, ...)
	
	newClient:__afterConstruct(...)
	
	return newClient
end

function HTMLFile:_onConnect (req, res)
	local body = ''
	
	if req.method == "GET" then
		Client._onConnect(self, req, res)
		
		self.response.useChunkedEncodingByDefault = true
		self.response.shouldKeepAlive = true
		self.response:writeHead(200, {
			['Content-Type'] = 'text/html',
			['Connection'] = 'keep-alive',
			['Transfer-Encoding'] = 'chunked'
		})
		self.response:write('<html><body>' .. string.rep(" ", 245))
		self:_payload()
	
	elseif req.method == 'POST' then
		req:on('data', function(self, message)
			body = body .. message
		end)
		req:on('end', function()
			--try {
				local msg = qs.parse(body)
				self:_onData(msg.data)
			--} catch(e){}
			res:writeHead(200, {['Content-Type'] = 'text/plain'})
			res:write('ok')
			res:finish()
		end)
	end
end
  
function HTMLFile:_write (msg)
	if self._open then
		if self:_verifyOrigin(self.request.headers.origin) then
			-- we leverage json for escaping
			msg = '<script>parent.s._(' .. json.encode(msg) .. ', document);</script>'
		else
			msg = "<script>alert('Cross domain security restrictions not met');</script>"
		end
		self.response:write(msg)
	end
end

return HTMLFile
