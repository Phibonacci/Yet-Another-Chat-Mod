require('yacm/parser/Parser')
require('yacm/parser/StringBuilder')
local Bubble = require('yacm/ui/Bubble')
local YacmClientSendCommands = require('yacm/network/SendYacmClient.lua')

ISChat.allChatStreams = {}
ISChat.allChatStreams[1] = { name = 'whisper', command = '/whisper ', shortCommand = '/w ', tabID = 1, range = 30.0, zombieRange = 15.0 }
ISChat.allChatStreams[2] = { name = 'low', command = '/low ', shortCommand = '/l ', tabID = 1, range = 30.0, zombieRange = 15.0 }
ISChat.allChatStreams[3] = { name = 'say', command = '/say ', shortCommand = '/s ', tabID = 1, range = 30.0, zombieRange = 15.0 }
ISChat.allChatStreams[4] = { name = 'yell', command = '/yell ', shortCommand = '/y ', tabID = 1, range = 60.0, zombieRange = 60.0 }
ISChat.allChatStreams[5] = { name = 'pm', command = '/pm ', shortCommand = '/p ', tabID = 1, range = 30.0, zombieRange = 15.0 }
ISChat.allChatStreams[6] = { name = 'faction', command = '/faction ', shortCommand = '/f ', tabID = 1, range = nil, zombieRange = nil }
ISChat.allChatStreams[7] = { name = 'safehouse', command = '/safehouse ', shortCommand = '/sh ', tabID = 1, range = nil, zombieRange = nil }
ISChat.allChatStreams[8] = { name = 'general', command = '/all ', shortCommand = nil, tabID = 1, range = nil, zombieRange = nil }
ISChat.allChatStreams[9] = { name = 'admin', command = '/admin ', shortCommand = '/a ', tabID = 2, range = nil, zombieRange = nil }

local function GetCommandFromMessage(command)
    for _, stream in ipairs(ISChat.allChatStreams) do
        if luautils.stringStarts(command, stream.command) then
            return stream, stream.command
        elseif stream.shortCommand and luautils.stringStarts(command, stream.shortCommand) then
            return stream, stream.shortCommand
        end
    end
    if not luautils.stringStarts(command, '/') then
        local defaultStream = ISChat.defaultTabStream[ISChat.instance.currentTabID]
        return defaultStream, ''
    end
    return nil
end

local function ProcessChatCommand(stream, command)
    local yacmCommand = ParseYacmMessage(command)
    if yacmCommand == nil then
        return false
    end
    --local commandWithHeader = header .. command
    if stream.name == 'yell' then
        processSayMessage(yacmCommand.bubble)
        YacmClientSendCommands.sendRangeMessage(getPlayer():getUsername(), command, 'yell')
    elseif stream.name == 'say' then
        processSayMessage(yacmCommand.bubble)
        YacmClientSendCommands.sendRangeMessage(getPlayer():getUsername(), command, 'say')
    elseif stream.name == 'low' then
        processSayMessage(yacmCommand.bubble)
        YacmClientSendCommands.sendRangeMessage(getPlayer():getUsername(), command, 'low')
    elseif stream.name == 'whisper' then
        processSayMessage(yacmCommand.bubble)
        YacmClientSendCommands.sendRangeMessage(getPlayer():getUsername(), command, 'whisper')
    elseif stream.name == 'pm' then
        local targetStart, targetEnd = command:find('^%s*"%a+%s?%a+"')
        if targetStart == nil then
            targetStart, targetEnd = command:find('^%s*%a+')
        end
        if targetStart == nil or targetEnd + 2 >= #command or command[targetEnd + 1] ~= ' ' then
            return false
        end
        local target = command:sub(targetStart, targetEnd)
        local whisperMessage = ParseYacmMessage(command:sub(targetEnd + 2))['bubble']
        processSayMessage(target .. ' ' .. whisperMessage)
        YacmClientSendCommands.sendWhisperMessage(whisperMessage)
        ISChat.instance.chatText.lastChatCommand = ISChat.instance.chatText.lastChatCommand .. username .. ' '
    elseif stream.name == 'faction' then
        proceedFactionMessage(yacmCommand.bubble)
    elseif stream.name == 'safehouse' then
        processSafehouseMessage(yacmCommand.bubble)
    elseif stream.name == 'admin' then
        processAdminChatMessage(yacmCommand.bubble)
    elseif stream.name == 'general' then
        processGeneralMessage(yacmCommand.bubble)
    end
    return true
end

local function IsOnlySpacesOrEmpty(command)
    local commandWithoutSpaces = command:gsub('%s+', '')
    return #commandWithoutSpaces == 0
end

function ISChat:onCommandEntered()
    local command = ISChat.instance.textEntry:getText()
    local chat = ISChat.instance

    ISChat.instance:unfocus()
    if not command or command == '' then
        return
    end

    local stream, commandName = GetCommandFromMessage(command)
    if stream then -- chat message
        if chat.currentTabID ~= stream.tabID then
            -- from one-based to zero-based
            showWrongChatTabMessage(chat.currentTabID - 1, stream.tabID - 1, commandName)
        else
            chat.chatText.lastChatCommand = commandName
            if #commandName > 0 and #command > #commandName then
                -- removing the command and trailing space '/command '
                command = string.sub(command, #commandName + 1)
            end
            if IsOnlySpacesOrEmpty(command) then
                return
            end
            if not ProcessChatCommand(stream, command) then
                return
            end
            chat:logChatCommand(command)
        end
    elseif luautils.stringStarts(command, '/') then -- server command
        SendCommandToServer(command)
        chat:logChatCommand(command)
    end

    doKeyPress(false)
    ISChat.instance.timerTextEntry = 20
end

function ISChat:updateChatPrefixSettings()
    updateChatSettings(self.chatFont, self.showTimestamp, self.showTitle)
    for tabNumber, chatText in ipairs(self.tabs) do
        chatText.text = ""
        local newText = ""
        chatText.chatTextLines = {}
        chatText.chatTextRawLines = chatText.chatTextRawLines or {}
        for i, msg in ipairs(chatText.chatTextRawLines) do
            self.chatFont = self.chatFont or 'medium'
            local line = BuildFontSizeString(self.chatFont)
            if ISChat.instance.showTimestamp then
                line = line .. BuildTimePrefixString(msg.time)
            end
            line = line .. msg.line .. BuildNewLine()
            table.insert(chatText.chatTextLines, line)
            if i == #chatText.chatMessages then
                line = string.gsub(line, " <LINE> $", "")
            end
            newText = newText .. line
        end
        chatText.text = newText
        chatText:paginate()
    end
end

local MessageTypeToColor = {
    ['whisper'] = { 130, 200, 200 },
    ['low'] = { 180, 230, 230 },
    ['say'] = { 255, 255, 255 },
    ['yell'] = { 230, 150, 150 },
    ['radio'] = { 144, 122, 176 },
}

function BuildColorFromMessageType(type)
    if MessageTypeToColor[type] == nil then
        error('unknown message type "' .. type .. '"')
    end
    return MessageTypeToColor[type]
end

local MessageTypeToVerb = {
    ['whisper'] = ' whispers, ',
    ['low'] = ' says quietly, ',
    ['say'] = ' says, ',
    ['yell'] = ' yells, ',
    ['radio'] = ' over the radio ',
}

function BuildVerbString(type)
    if MessageTypeToVerb[type] == nil then
        error('unknown message type "' .. type .. '"')
    end
    return MessageTypeToVerb[type]
end

function BuildMessageFromPacket(packet)
    local messageColor = BuildColorFromMessageType(packet.type)
    local message = ParseYacmMessage(packet.message, messageColor, 20)
    local radioPrefix = ''
    if packet.type == 'radio' then
        radioPrefix = '(' .. string.format('%.1fMHz', packet.frequency / 1000) .. '), '
    end
    local messageColorString = BuildBracketColorString(messageColor)
    local formatedMessage = BuildBracketColorString({ 109, 93, 199 }) ..
        packet.author ..
        BuildBracketColorString({ 150, 150, 150 }) ..
        BuildVerbString(packet.type) ..
        radioPrefix .. messageColorString .. '"' .. message.body .. messageColorString .. '"'
    return formatedMessage, message
end

function BuildChatMessage(fontSize, showTimestamp, rawMessage, time)
    local line = BuildFontSizeString(fontSize)
    if showTimestamp then
        line = line .. BuildTimePrefixString(time)
    end
    line = line .. rawMessage
    return line
end

function CreateBubble(author, message, length)
    if ISChat.instance.bubble then
        ISChat.instance.bubble:delete()
    end
    local onlineUsers = getOnlinePlayers()
    local authorObj = nil
    for i = 0, onlineUsers:size() - 1 do
        local user = onlineUsers:get(i)
        if user:getUsername() == author then
            authorObj = onlineUsers:get(i)
            break
        end
    end
    if authorObj == nil then
        return
    end
    ISChat.instance.bubble = Bubble:new(authorObj, message, length, 10)
    ISChat.instance.bubble:initialise()
    ISChat.instance.bubble:paginate()
end

function ISChat.addCustomLineInChat(packet)
    local formattedMessage, message = BuildMessageFromPacket(packet)
    ISChat.instance.chatFont = ISChat.instance.chatFont or 'medium'
    CreateBubble(packet.author, message['bubble'], message['length'])
    local time = Calendar.getInstance():getTimeInMillis()
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, formattedMessage, time)

    if not ISChat.instance.chatText then
        ISChat.instance.chatText = ISChat.instance.defaultTab
        ISChat.instance:onActivateView()
    end
    local chatText = ISChat.instance.tabs[1]
    chatText.chatTextRawLines = chatText.chatTextRawLines or {}
    table.insert(chatText.chatTextRawLines,
        {
            time = time,
            line = formattedMessage,
        })
    if chatText.tabTitle ~= ISChat.instance.chatText.tabTitle then
        local alreadyExist = false
        for _, blinkedTab in ipairs(ISChat.instance.panel.blinkTabs) do
            if blinkedTab == chatText.tabTitle then
                alreadyExist = true
                break
            end
        end
        if alreadyExist == false then
            table.insert(ISChat.instance.panel.blinkTabs, chatText.tabTitle)
        end
    end
    local vscroll = chatText.vscroll
    local scrolledToBottom = (chatText:getScrollHeight() <= chatText:getHeight()) or (vscroll and vscroll.pos == 1)
    if #chatText.chatTextLines > ISChat.maxLine then
        local newLines = {}
        for i, v in ipairs(chatText.chatTextLines) do
            if i ~= 1 then
                table.insert(newLines, v)
            end
        end
        table.insert(newLines, line .. BuildNewLine())
        chatText.chatTextLines = newLines
    else
        table.insert(chatText.chatTextLines, line .. BuildNewLine())
    end
    chatText.text = ''
    local newText = ''
    for i, v in ipairs(chatText.chatTextLines) do
        if i == #chatText.chatTextLines then
            v = string.gsub(v, ' <LINE> $', '')
        end
        newText = newText .. v
    end
    chatText.text = newText
    chatText:paginate()
    if scrolledToBottom then
        chatText:setYScroll(-10000)
    end
end

-- TODO: try to clean this mess copied from the base game
ISChat.addLineInChat = function(message, tabID)
    local line = message:getText()
    print('message with prefix: "' .. message:getTextWithPrefix() .. '"')
    if message:getRadioChannel() ~= -1 then
        local messageWithoutColorPrefix = message:getText():gsub('*%d+,%d+,%d+*', '')
        message:setText(messageWithoutColorPrefix)
        ISChat.addCustomLineInChat({
            author = message:getAuthor(),
            message = messageWithoutColorPrefix,
            type = 'radio',
            frequency = message:getRadioChannel()
        })
    else
        message:setOverHeadSpeech(false)
    end
    if message:isServerAlert() then
        ISChat.instance.servermsg = ''
        if message:isShowAuthor() then
            ISChat.instance.servermsg = message:getAuthor() .. ': '
        end
        ISChat.instance.servermsg = ISChat.instance.servermsg .. message:getText()
        ISChat.instance.servermsgTimer = 5000
    else
        return
    end
    -- I'm pretty sure this "user" is not a global but an old variable that will always be nil
    if user and ISChat.instance.mutedUsers[user] then return end
    if not ISChat.instance.chatText then
        ISChat.instance.chatText = ISChat.instance.defaultTab
        ISChat.instance:onActivateView()
    end
    local chatText
    for i, tab in ipairs(ISChat.instance.tabs) do
        if tab and tab.tabID == tabID then
            chatText = tab
            break
        end
    end
    if chatText.tabTitle ~= ISChat.instance.chatText.tabTitle then
        local alreadyExist = false
        for i, blinkedTab in ipairs(ISChat.instance.panel.blinkTabs) do
            if blinkedTab == chatText.tabTitle then
                alreadyExist = true
                break
            end
        end
        if alreadyExist == false then
            table.insert(ISChat.instance.panel.blinkTabs, chatText.tabTitle)
        end
    end
    local vscroll = chatText.vscroll
    local scrolledToBottom = (chatText:getScrollHeight() <= chatText:getHeight()) or (vscroll and vscroll.pos == 1)
    if #chatText.chatTextLines > ISChat.maxLine then
        local newLines = {}
        for i, v in ipairs(chatText.chatTextLines) do
            if i ~= 1 then
                table.insert(newLines, v)
            end
        end
        table.insert(newLines, line .. ' <LINE> ')
        chatText.chatTextLines = newLines
    else
        table.insert(chatText.chatTextLines, line .. ' <LINE> ')
    end
    chatText.text = ''
    local newText = ''
    for i, v in ipairs(chatText.chatTextLines) do
        if i == #chatText.chatTextLines then
            v = string.gsub(v, ' <LINE> $', '')
        end
        newText = newText .. v
    end
    chatText.text = newText
    chatText.chatTextRawLines = chatText.chatTextRawLines or {}
    table.insert(chatText.chatTextRawLines,
        {
            time = Calendar.getInstance():getTimeInMillis(),
            line = message:getText(),
        })
    table.insert(chatText.chatMessages, message)
    chatText:paginate()
    if scrolledToBottom then
        chatText:setYScroll(-10000)
    end
end
