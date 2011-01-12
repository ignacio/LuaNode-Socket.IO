local pairs = pairs

module((...))

--[[
exports.options = {
  options: function(options, merge){
    this.options = exports.merge(options || {}, merge || {});
  }
};
--]]

null_option = {}

options = {
	options = function(self, options, merge)
		self.options = _M.merge(options or {}, merge or {})
	end
}

function merge(source, merge)
	for k,v in pairs(merge) do
		if v == null_option then
			source[k] = nil
		else
			source[k] = v
		end
	end
	return source
end