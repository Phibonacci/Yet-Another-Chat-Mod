local AToken = require('yacm/lexer/AToken')

local TokenBold = {}

function TokenBold:new(message, childs)
    TokenBold.__index = self
    setmetatable(TokenBold, { __index = AToken })
    local o = AToken:new(message, childs)
    setmetatable(o, TokenBold)
    return o
end

function TokenBold:getColor()
    return {
        255,
        28,
        77
    }
end

function TokenBold.getName()
    return 'bold'
end

function TokenBold.getTagSize()
    return 2
end

function TokenBold.getTag()
    return '**'
end

return TokenBold
