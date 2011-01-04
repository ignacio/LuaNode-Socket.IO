local Class = require "luanode.class"
local EventEmitter = require "luanode.event_emitter"

--module(..., package.seeall)
--[[
 * Pseudo-listener constructor
 *
 * @param {String} realm name
 * @param {Listener} listener the realm belongs to
 * @api public
--]]

Realm = Class.InheritsFrom(EventEmitter)

function Realm:__init (name, listener)
	local e = Class.construct(Realm)
	e.name = name
	e.listener = listener
	return e
end

--[[
 * Override connection event so that client.send() appends the realm annotation
 *
 * @param {String} ev name
 * @param {Function} callback
 * @api public
--]]

function Realm:on (ev, fn)
	if ev == 'connection' then
		self.listener:on('connection', function(self_, conn)
			fn(self, RealmClient(self.name, conn))
		end)
	else
		self.listener:on(ev, fn)
	end
	return self
end

--[[
 * Broadcast a message annotated for this realm
 *
 * @param {String} message
 * @param {Array/String} except
 * @param {Object} message annotations
 * @api public
--]]

function Realm:broadcast (message, except, atts)
	atts = atts or {}
	atts['r'] = self.name
	self.listener:broadcast(message, except, atts)
	return self
end

--[[
 * List of properties to proxy to the listener
--]]

--P
--[[
['clients', 'options', 'server'].forEach(function(p){
	Realm.prototype.__defineGetter__(p, function(){
		return this.listener[p];
	});
});
--]]

--[[
 * List of methods to proxy to the listener
--]]
--P
--[[
['realm'].forEach(function(m){
	Realm.prototype[m] = function(){
		return this.listener[m].apply(this.listener, arguments);
	};
});
--]]

--[[
 * Pseudo-client constructor
 *
 * @param {Client} Actual client
 * @api public
--]]

RealmClient = Class.InheritsFrom(EventEmitter)

function RealmClient:__init (name, client)
	local e = Class.construct(RealmClient)
	e.name = name
	e.client = client
	return e
end


--[[
 * Override Client#on to filter messages from our realm
 *
 * @param {String} ev name
 * @param {Function) callback
--]]

function RealmClient:on (ev, fn)
	if ev == 'message' then
		self.client:on('message', function(self_, msg, atts)
			if atts.r == self.name then
				fn(self, msg, atts)
			end
		end)
	else
		self.client:on(ev, fn)
	end
	return self
end

--[[
 * Client#send wrapper with realm annotations
 *
 * @param {String} message
 * @param {Object} annotations
 * @apu public
--]]

function RealmClient:send (message, anns)
	anns = anns or {}
	anns.r = self.name
	return self.client:send(message, anns)
end

--[[
 * Client#send wrapper with realm annotations
 *
 * @param {String} message
 * @param {Object} annotations
 * @apu public
--]]

function RealmClient:sendJSON (message, anns)
	anns = anns or {}
	anns.r = self.name
	return self.client:sendJSON(message, anns)
end

--[[
 * Client#send wrapper with realm annotations
 *
 * @param {String} message
 * @param {Object} annotations
 * @apu public
--]]

function RealmClient:broadcast (message, anns)
	anns = anns or {}
	anns.r = self.name
	return self.client:broadcast(message, anns)
end

--[[
 * Proxy some properties to the client
--]]
--P
--[[
['connected', 'options', 'connections', 'listener'].forEach(function(p){
	RealmClient.prototype.__defineGetter__(p, function(){
		return this.client[p];
	});
});
--]]


--[[
 * Module exports
--]]

--module.exports = Realm;
--module.exports.Client = RealmClient;

return Realm