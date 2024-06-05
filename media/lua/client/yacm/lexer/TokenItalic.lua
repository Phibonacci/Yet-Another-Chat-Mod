local AToken = require('yacm/lexer/AToken')

local TokenItalic = {}

function TokenItalic:new(message, childs)
    TokenItalic.__index = self
    setmetatable(TokenItalic, { __index = AToken })
    local o = AToken:new(message, childs)
    setmetatable(o, TokenItalic)
    return o
end

function TokenItalic:getColor()
    return {
        93,
        255,
        60
    }
end

function TokenItalic.getName()
    return 'italic'
end

function TokenItalic.getTagSize()
    return 1
end

function TokenItalic.getTag()
    return '*'
end

return TokenItalic
