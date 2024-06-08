require('yacm/parser/StringBuilder')

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

function AToken:formatCustom(wrapWords, keepTags, rgbCall)
    local colorObj = self:getColor()
    local color = rgbCall(colorObj)
    local newMessage = ''
    if keepTags and self.getTagSize() > 0 then
        newMessage = color .. self.getTag()
    end
    for _, child in pairs(self.childs) do
        if child.getName() == 'string' then
            newMessage = newMessage .. color
        end
        newMessage = newMessage .. child:formatCustom(wrapWords, keepTags, rgbCall)
    end
    if keepTags and self.getTagSize() > 0 then
        newMessage = newMessage .. self.getTag()
    end
    return newMessage
end

-- format for the old bubbles
function AToken:formatBubble(keepTags, wrapWords)
    return self:formatCustom(wrapWords, keepTags, BuildAsteriskColorString)
end

function AToken:format(keepTags, wrapWords)
    return self:formatCustom(wrapWords, keepTags, BuildBracketColorString)
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
