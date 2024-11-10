local StringBuilder = require('tics/client/parser/StringBuilder')

local AToken = {}

function AToken:new(message, childs)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.message = message
    o.childs = childs
    return o
end

function AToken:getLength()
    local length = 0
    for _, child in pairs(self.childs) do
        length = length + child:getLength()
    end
    return length
end

function AToken:formatCustom(wrapWords, keepTags, rgbCall, lengthLeft)
    local colorObj = self:getColor()
    local color = rgbCall(colorObj)
    local newMessage = ''
    local stop = false
    local rawMessage = ''
    if keepTags and self.getTagSize() > 0 then
        newMessage = color .. self.getTag()
    end
    for _, child in pairs(self.childs) do
        if child.getName() == 'string' then
            newMessage = newMessage .. color
        end
        local subMessage, subRawMessage, subLengthLeft = child:formatCustom(wrapWords, keepTags, rgbCall, lengthLeft)
        lengthLeft = subLengthLeft
        newMessage = newMessage .. subMessage
        rawMessage = rawMessage .. subRawMessage
        if lengthLeft ~= nil and lengthLeft <= 0 then
            return newMessage, rawMessage, lengthLeft
        end
    end
    if keepTags and self.getTagSize() > 0 then
        newMessage = newMessage .. self.getTag()
    end
    return newMessage, rawMessage, lengthLeft
end

function AToken:formatVanillaBubble(keepTags, wrapWords)
    return self:formatCustom(wrapWords, keepTags, StringBuilder.BuildAsteriskColorString)
end

function AToken:format(keepTags, wrapWords, maxBubbleLength)
    return self:formatCustom(wrapWords, keepTags, StringBuilder.BuildBracketColorString, maxBubbleLength)
end

function AToken:getColor()
    error('abstract method not implemented')
end

function AToken.getName()
    error('abstract method not implemented')
end

function AToken.getTagSize()
    error('abstract method not implemented')
end

function AToken.getTag()
    error('abstract method not implemented')
end

return AToken
