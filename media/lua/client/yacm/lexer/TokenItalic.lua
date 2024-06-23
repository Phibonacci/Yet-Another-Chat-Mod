local AToken = require('yacm/lexer/AToken')

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
    if YacmServerSettings ~= nil then
        print('ITALIC IS SET')
        print(YacmServerSettings['markdown']['italic']['color'][1])
        print(YacmServerSettings['markdown']['italic']['color'][2])
        print(YacmServerSettings['markdown']['italic']['color'][3])
        return YacmServerSettings['markdown']['italic']['color']
    else
        print('ITALIC IS NILL')
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
