local function copyTable(table)
	local result = {}

	local mt = getmetatable(table)
	if mt then
		setmetatable(result, mt)
	end

	for k, v in pairs(table) do
		if type(v) == 'table' and k ~= '__index' and k ~= '__newindex' then
			result[k] = copyTable(v)
		else
			result[k] = v
		end
	end
	return result
end

setmetatable(class, {
	__call = function(self, classScope)
		return setmetatable({}, {
			__index = classScope,
			__call = function(self, objectScope)
				local obj = objectScope or {}
				setmetatable(obj, {__index = self})

				if obj.constructor and type(obj.constructor) == 'function' then
					obj:constructor()
				end

				for key, value in pairs(classScope) do
					if type(value) == 'table' then
						obj[key] = copyTable(value)
					else
						obj[key] = value
					end
				end
				return obj
			end
		})
	end
})

return class