--
-- * Module dependencies
--
local Class = require "luanode.class"
local EventEmitter = require "luanode.event_emitter"

module(..., package.seeall)

--
-- * Data decoder class
-- *
-- * @api public
--

--
-- Inherit from EventEmitter
--
Decoder = Class.InheritsFrom(EventEmitter)
Decoder.__type = "socket-io.data.Decoder"

function Decoder:__init ()
	local decoder = Class.construct(Decoder)
	decoder:reset()
	decoder.buffer = ""
	return decoder
end

--
-- * Add data to the buffer for parsing
-- *
-- * @param {String} data
-- * @api public
--
function Decoder:add (data)
	self.buffer = self.buffer .. data
	self:parse()
end

--
-- Parse the current buffer
--
-- @api private
--
function Decoder:parse ()
	-- no podria resolver esto con un string.match, o mejor, con corutinas?
	if #self.buffer == 0 then
		return
	end
	--console.warn("Decoder:parse '%s'", self.buffer)
	local charCount = 0
	for chr in string.gmatch(self.buffer, "([%z\1-\127\194-\244][\128-\191]*)") do
		self.i = self.i + #chr
		if self.type == nil then
			if chr == ':' then return self:error('Data type not specified') end
			self.type = '' .. chr
		elseif self.length == nil and chr == ':' then
			self.length = ''
		elseif self.data == nil then
			if chr ~= ':' then
				self.length = self.length .. chr
			else
				if #self.length == 0 then
					return self:error('Data length not specified')
				end
				self.length = tonumber(self.length)
				self.data = ''
			end
		elseif charCount == self.length then
			if chr == ',' then
				self:emit('data', self.type, self.data)
				self.buffer = self.buffer:sub(self.i)
				self:reset()
				return self:parse()
			else
				return self:error('Termination character "," expected')
			end
		else
			charCount = charCount + 1
			self.data = self.data .. chr
		end
	end
end

--
-- Reset the parser state
--
-- @api private
--

function Decoder:reset ()
	self.i = 1
	self.type = nil
	self.data = nil
	self.length = nil
end

--
-- Error handling functions
--
-- @api private
--
function Decoder:error (reason)
	self:reset()
	self:emit('error', reason)
end




--
-- Encode function
-- 
-- Examples:
--      encode([3, 'Message of type 3']);
--      encode([[1, 'Message of type 1], [2, 'Message of type 2]]);
-- 
-- @param {Array} list of messages
-- @api public
--

function encode (messages)
	if type(messages[1]) == "table" then
		messages = messages
	else
		messages = {messages}
	end
	--messages = Array.isArray(messages[0]) ? messages : [messages];
	
	local ret = ''
	for _, message in ipairs(messages) do
		local str = message[2] or ""
		local _, count = string.gsub(str, "[^\128-\193]", "")	-- taken from here: http://lua-users.org/wiki/LuaUnicode
		ret = ret .. message[1] .. ":" .. count .. ":" .. str .. ","
	end
	return ret
end

--
-- Encode message function
--
-- @param {String} message
-- @param {Object} annotations
-- @api public
--

function encodeMessage (msg, annotations)
	local data = ''
	local anns = annotations or {}
	for k,v in pairs(anns) do
		data = data .. k .. (v or "") .. "\n"
	end
	
	--for (var i = 0, v, k = Object.keys(anns), l = k.length; i < l; i++){
--		v = anns[k[i]];
		--data += k[i] + (v !== null && v !== undefined ? ':' + v : '') + "\n";
	--}
	data = data .. ':' .. (msg or "")
	return data
end

--
-- Decode message function
--
-- @param {String} message
-- @api public
--

function decodeMessage(msg)
	local anns = {}
	local data
	local key, value
	for i=1, #msg do
		local chr = msg:sub(i, i)
		if i == 1 and chr == ':' then
			data = msg:sub(2)
			break
		end
		if not key and not value and chr == ':' then
			data = msg:sub(i + 1)
			break;
		end
		if chr == "\n" then
			anns[key] = value
			key = nil
			value = nil
		else
			if not key then
				key = chr
			else
				if value == nil and chr == ':' then
					value = ""
				else
					if value then
						value = value .. chr
					else
						key = key .. chr
					end
				end
			end
		end
	end
	return {data, anns}
end
