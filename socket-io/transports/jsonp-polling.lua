local Class = require "luanode.class"
local XHRPolling = require "socket-io.transports.xhr-polling"
local options = require "socket-io.utils".options
local merge = require "socket-io.utils".merge
local null_option = require "socket-io.utils".null_option
local json = require "json"


JSONPPolling = Class.InheritsFrom(XHRPolling)
JSONPPolling.__type = "socket-io.JSONPPolling"


function JSONPPolling:__init (...)
	local newClient = Class.construct(JSONPPolling, ...)
	
	newClient:__afterConstruct(...)
	
	return newClient
end

function JSONPPolling:getOptions ()
	return {
		timeout = null_option, -- no heartbeats
		closeTimeout = 8000,
		duration = 20000
	}
end
  
function JSONPPolling:_onConnect (req, res)
	console.warn("JSONPPolling:_onConnect req.url= %s", req.url)
	--this._index = req.url.match(/\/([0-9]+)\/?$/).pop();
	--self._index = req.url:match(/\/([0-9]+)\/?$/).pop();	-- TODO: implement what ?
	XHRPolling._onConnect(self, req, res)
end
  
function JSONPPolling:_write (message)
	if self._open then
		if self:_verifyOrigin(self.request.headers.origin) then
			message = "io.JSONP[" .. self._index .. "]._(" .. json.encode(message) .. ")"
		else
			message = "alert('Cross domain security restrictions not met')";
		end
		this.response:writeHead(200, {
			['Content-Type'] = 'text/javascript; charset=UTF-8',
			['Content-Length'] = #message
		})
		self.response:write(message)
		self.response:finish()
		self._onClose()
	end
end

return JSONPPolling
