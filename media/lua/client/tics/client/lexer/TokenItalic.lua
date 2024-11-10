local AToken = require('tics/client/lexer/AToken')

local TokenItalic = {}

TokenItalic.color = {
    93,
    255,
    60
}

function TokenItalic:new(message, childs)
    TokenItalic.__index = self
    setmetatable(TokenItalic, { __index = AToken })
    local o = AToken:new(message, childs)
    setmetatable(o, TokenItalic)
    return o
end

function TokenItalic:getColor()
    if TicsServerSettings ~= nil then
        return TicsServerSettings['markdown']['italic']['color']
    else
        return TokenItalic.color
    end
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
