local AToken = require('tics/client/lexer/AToken')

local TokenBold = {}

TokenBold.color = {
    255,
    28,
    77
}

function TokenBold:new(message, childs)
    TokenBold.__index = self
    setmetatable(TokenBold, { __index = AToken })
    local o = AToken:new(message, childs)
    setmetatable(o, TokenBold)
    return o
end

function TokenBold:getColor()
    if TicsServerSettings ~= nil then
        return TicsServerSettings['markdown']['bold']['color']
    else
        return TokenBold.color
    end
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
