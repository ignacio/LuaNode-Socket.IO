local Class = require "luanode.class"
local net = require "luanode.net"
local WebSocket = require "socket-io.transports.websocket"
local listeners = {}
local netserver

Flashsocket = Class.InheritsFrom(WebSocket)
Flashsocket.__type = "socket-io.Flashsocket"

Flashsocket.httpUpgrade = true

local function policy(listeners)
	local xml = [[
<?xml version="1.0"?>
<!DOCTYPE cross-domain-policy SYSTEM  "http://www.macromedia.com/xml/dtds/cross-domain-policy.dtd">
<cross-domain-policy>
]]

	for _, l in pairs(listeners) do
		local origins
		if type(l.options.origins) == "string" then
			origins = { l.options.origins }
		elseif type(l.options.origins) == "table" then
			origins = l.options.origins
		else
			error("options.origins must be a string or a table")
		end
		for _, origin in ipairs(origins) do
			local p1, p2 = origin:match("(.+):(.+)")
			xml = xml .. '<allow-access-from domain="' .. p1 .. '" to-ports="' .. p2 ..'"/>\n'
		end
	end

	xml = xml .. '</cross-domain-policy>\n'
	return xml
end


function Flashsocket.init (listener)
	table.insert(listeners, listener)
	
	listener.server:on('close', function()
		--listeners.splice(listeners.indexOf(listener), 1);
		for i, l in ipairs(listeners) do
			if l == listener then
				table.remove(listeners, i)
				break
			end
		end
		
		if #listeners == 0 and netserver then
			--try {
				netserver:close()
			--} catch(e){}
		end
	end)
  
	if listener.options.flashPolicyServer and not netserver then
		netserver = net.createServer(function(self, socket)
			listener.options.log("lnsocket.io: connection on flash port")
			socket:addListener('error', function(self, err)
				if socket and socket.finish then
					socket:finish()
					socket:destroy()
				end
			end)
			
			socket:on("close", function()
				listener.options.log("socket has been closed")
			end)
			
			listener.options.log("socket:readyState", socket:readyState())
			if socket and socket:readyState() == 'open' then
				local xml = policy(listeners)
				socket:finish(policy(listeners))
				--socket:destroy()
			end
		end)
		
		--try {
			netserver:listen(843)
		--} catch(e){
			--if (e.errno == 13) {
				--listener.options.log('Your node instance does not have root privileges.'
					--		+ ' This means that the flash XML policy file will be'
							--+ ' served inline instead of on port 843. This will slow'
							--+ ' connection time slightly');
			--}
			--netserver = null;
		--}
	end
	
	-- Could not listen on port 843 so policy requests will be inline
	listener.server:addListener('connection', function(self, stream)
		local flashCheck = function (self, data)
			-- Only check the initial data
			--listener.options.log("data arrived", data)
			if data:sub(1, 1) == "<" and #data == 23 then
				if data == '<policy-file-request/>\0' then
					listener.options.log("Answering flash policy request inline")
					if stream and stream:readyState() == 'open' then
						local xml = policy({listener})
						stream:write(xml)
						stream:finish()
					end
				end
			end
		end
		-- Only check the initial data
		stream:once('data', flashCheck)
	end)
end

return Flashsocket