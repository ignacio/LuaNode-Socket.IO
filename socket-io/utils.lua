local pairs = pairs

module((...))

--[[
exports.options = {
  options: function(options, merge){
    this.options = exports.merge(options || {}, merge || {});
  }
};
--]]

options = {
	options = function(self, options, merge)
		self.options = _M.merge(options or {}, merge or {})
	end
}

function merge(source, merge)
	for k,v in pairs(merge) do
		source[k] = v
	end
	return source
end