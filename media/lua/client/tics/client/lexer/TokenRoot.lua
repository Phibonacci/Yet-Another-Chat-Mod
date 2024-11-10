local AToken = require('tics/client/lexer/AToken')

local TokenRoot = {}

function TokenRoot:new(message, childs, defaultColor)
    TokenRoot.__index = self
    setmetatable(TokenRoot, { __index = AToken })
    local o = AToken:new(message, childs)
    setmetatable(o, TokenRoot)
    o.color = defaultColor
    if defaultColor == nil then
        o.color = {
            242,
            242,
            242
        }
    end
    return o
end

function TokenRoot:getColor()
    return self.color
end

function TokenRoot.getName()
    return 'root'
end

function TokenRoot.getTagSize()
    return 0
end

function TokenRoot.getTag()
    return ''
end

return TokenRoot
