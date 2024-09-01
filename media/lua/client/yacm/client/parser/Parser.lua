local TokenBold = require 'yacm/client/lexer/TokenBold'
local TokenItalic = require 'yacm/client/lexer/TokenItalic'
local TokenRoot = require 'yacm/client/lexer/TokenRoot'
local TokenString = require 'yacm/client/lexer/TokenString'

local function GetTag(message, indexStart, tag)
    if string.len(message) - indexStart + 1 < string.len(tag) then
        return nil
    end
    local index = 1
    while index <= string.len(tag) do
        if message:byte(index + indexStart - 1) ~= tag:byte(index) then
            return nil
        end
        index = index + 1
    end
    return {
        ['first'] = indexStart,
        ['last'] = index - 1 + indexStart - 1,
        ['tag'] = tag,
    }
end

local tags = { '**', '*', '__', '_' }
local function ListTags(message)
    local list = {}
    local index = 1
    while index <= string.len(message) do
        local found = false
        for _, tag in pairs(tags) do
            local tagObj = GetTag(message, index, tag)
            if tagObj ~= nil then
                table.insert(list, tagObj)
                index = tagObj.last + 1
                found = true
                break
            end
        end
        if not found then
            index = index + 1
        end
    end
    return list
end

local function CreateToken(tag, message, childs)
    if tag == '**' then
        return TokenBold:new(message, childs)
    elseif tag == '*' then
        return TokenItalic:new(message, childs)
    elseif tag == '__' then
        return TokenBold:new(message, childs)
    elseif tag == '_' then
        return TokenItalic:new(message, childs)
    else
        error('unknown tag "' .. tag .. '"')
    end
end

local function SubTokenize(message, messageStart, messageEnd, tagsFound, indexStart, indexEnd)
    local messageIndex = messageStart
    local index = indexStart
    local tokens = {}
    while index <= indexEnd do
        local matchTagFound = false
        for indexMatch = index + 1, indexEnd do
            if tagsFound[index].tag == tagsFound[indexMatch].tag then
                matchTagFound = true
                if messageIndex ~= tagsFound[index].first then
                    local tokenString = TokenString:new(
                        string.sub(message, messageIndex, tagsFound[index].first - 1))
                    table.insert(tokens, tokenString)
                end
                local subMessage = string.sub(
                    message, tagsFound[index].last + 1, tagsFound[indexMatch].first - 1)
                local childTokens = SubTokenize(message, tagsFound[index].last + 1, tagsFound[indexMatch].first - 1,
                    tagsFound, index + 1, indexMatch - 1)
                local newToken = CreateToken(tagsFound[index].tag, subMessage, childTokens)
                table.insert(tokens, newToken)
                index = indexMatch + 1
                messageIndex = tagsFound[indexMatch].last + 1
                break
            end
        end
        if not matchTagFound then
            index = index + 1
        end
    end
    if messageIndex <= messageEnd then
        local tokenString = TokenString:new(
            string.sub(message, messageIndex, messageEnd))
        table.insert(tokens, tokenString)
    end
    return tokens
end

local function Tokenize(message, tagsFound, defaultColor)
    return TokenRoot:new(message, SubTokenize(message, 1, #message, tagsFound, 1, #tagsFound), defaultColor)
end

local function FormatMessage(message, defaultColor, wrapWords, maxBubbleLength)
    local tagsFound = ListTags(message)
    local token = Tokenize(message, tagsFound, defaultColor)
    local wrappedMessage, wrappedRawMessage = token:format(false, wrapWords, maxBubbleLength)
    return token:format(false), wrappedMessage, wrappedRawMessage
end

local function ParseYacmHeaderArg(header, pattern)
    local authorStart, authorEnd = string.find(header, pattern)
    authorStart = authorStart + 2
    authorEnd = authorEnd - 1
    local arg = nil
    if authorEnd - authorStart < 1 then
        return nil
    end
    arg = header.sub(header, authorStart, authorEnd)
    return arg
end

local function ParseYacmHeader(message)
    local yacmPattern = '<YACM t:%a+;a:%a+;>';
    local typePattern = 't:%a+;';
    local authorPattern = 'a:%a+;';
    local headerStart, headerEnd = string.find(message, yacmPattern)
    if headerStart == nil then
        return nil
    end
    local headerString = string.sub(message, headerStart, headerEnd)
    local type = ParseYacmHeaderArg(headerString, typePattern)
    local author = ParseYacmHeaderArg(headerString, authorPattern)
    if type == nil or author == nil then
        return nil
    end
    return {
        ['type'] = type,
        ['author'] = author,
    }, headerEnd
end

function ParseYacmMessage(message, defaultColor, wrapWords, maxBubbleLength)
    -- local header, headerEnd = ParseYacmHeader(message)
    -- if header == nil then
    --     return nil
    -- end
    local body = message --string.sub(message, headerEnd + 1)
    local bodyChat, bodyBubble, rawMessage = FormatMessage(body, defaultColor, wrapWords, maxBubbleLength)
    return {
        --['header'] = header,
        ['body'] = bodyChat,
        ['bubble'] = bodyBubble,
        ['rawMessage'] = rawMessage,
    }
end
