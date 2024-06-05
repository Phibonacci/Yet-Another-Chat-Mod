local TokenString = {}

function TokenString:new(message)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.message = message
    return o
end

function TokenString.getName()
    return 'string'
end

function TokenString:formatCustom()
    return self.message
end

function TokenString:formatBubble(keepTags)
    return self:formatCustom()
end

function TokenString:format()
    return self:formatCustom()
end

return TokenString
