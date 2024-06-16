require('yacm/parser/Parser')
require('yacm/parser/StringBuilder')
local Bubble = require('yacm/ui/Bubble')
local TypingDots = require('yacm/ui/TypingDots')
local YacmClientSendCommands = require('yacm/network/SendYacmClient.lua')


ISChat.allChatStreams     = {}
ISChat.allChatStreams[1]  = { name = 'say', command = '/say ', shortCommand = '/s ', tabID = 1 }
ISChat.allChatStreams[2]  = { name = 'whisper', command = '/whisper ', shortCommand = '/w ', tabID = 1 }
ISChat.allChatStreams[3]  = { name = 'low', command = '/low ', shortCommand = '/l ', tabID = 1 }
ISChat.allChatStreams[4]  = { name = 'yell', command = '/yell ', shortCommand = '/y ', tabID = 1 }
ISChat.allChatStreams[5]  = { name = 'pm', command = '/pm ', shortCommand = '/p ', tabID = 1 }
ISChat.allChatStreams[6]  = { name = 'faction', command = '/faction ', shortCommand = '/f ', tabID = 1 }
ISChat.allChatStreams[7]  = { name = 'safehouse', command = '/safehouse ', shortCommand = '/sh ', tabID = 1 }
ISChat.allChatStreams[8]  = { name = 'general', command = '/all ', shortCommand = '/g', tabID = 1 }
ISChat.allChatStreams[9]  = { name = 'ooc', command = '/ooc ', shortCommand = '/o ', tabID = 2 }
ISChat.allChatStreams[10] = { name = 'admin', command = '/admin ', shortCommand = '/a ', tabID = 3 }


ISChat.defaultTabStream    = {}
ISChat.defaultTabStream[1] = ISChat.allChatStreams[1]
ISChat.defaultTabStream[2] = ISChat.allChatStreams[9]
ISChat.defaultTabStream[3] = ISChat.allChatStreams[10]


local function IsOnlySpacesOrEmpty(command)
    local commandWithoutSpaces = command:gsub('%s+', '')
    return #commandWithoutSpaces == 0
end

local function GetCommandFromMessage(command)
    if IsOnlySpacesOrEmpty(command) then
        return nil
    end
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


local function AddTab(tabTitle, tabID)
    local chat = ISChat.instance
    local newTab = chat:createTab()
    newTab.parent = chat
    newTab.tabTitle = tabTitle
    newTab.tabID = tabID
    newTab.streamID = 1
    newTab.chatStreams = {}
    for _, stream in ipairs(ISChat.allChatStreams) do
        if stream.tabID == tabID then
            table.insert(newTab.chatStreams, stream)
        end
    end
    newTab.lastChatCommand = newTab.chatStreams[newTab.streamID].command
    newTab:setUIName("chat text panel with title '" .. tabTitle .. "'")
    local pos = chat:calcTabPos()
    local size = chat:calcTabSize()
    newTab:setY(pos.y)
    newTab:setHeight(size.height)
    newTab:setWidth(size.width)
    if chat.tabCnt == 0 then
        chat:addChild(newTab)
        chat.chatText = newTab
        chat.chatText:setVisible(true)
        chat.currentTabID = tabID
    end
    if chat.tabCnt == 1 then
        chat.panel:setVisible(true)
        chat.chatText:setY(pos.y)
        chat.chatText:setHeight(size.height)
        chat.chatText:setWidth(size.width)
        chat:removeChild(chat.chatText)
        chat.panel:addView(chat.chatText.tabTitle, chat.chatText)
    end

    if chat.tabCnt >= 1 then
        chat.panel:addView(tabTitle, newTab)
        chat.minimumWidth = chat.panel:getWidthOfAllTabs() + 2 * chat.inset
    end
    chat.tabs[tabID] = newTab
    chat.tabCnt = chat.tabCnt + 1
end

local function InitTabs()
    AddTab('General', 1)
    AddTab('OCC', 2)
end

Events.OnChatWindowInit.Remove(ISChat.initChat)

ISChat.initChat = function()
    local instance = ISChat.instance
    if instance.tabCnt == 1 then
        instance.chatText:setVisible(false)
        instance:removeChild(instance.chatText)
        instance.chatText = nil
    elseif instance.tabCnt > 1 then
        instance.panel:setVisible(false)
        for tabId, tab in pairs(instance.tabs) do
            instance.panel:removeView(tab)
        end
    end
    instance.tabCnt = 0
    instance.tabs = {}
    instance.currentTabID = 0
    InitTabs()
end

Events.OnGameStart.Remove(ISChat.createChat)

ISChat.createChat = function()
    if not isClient() then
        return
    end
    ISChat.chat = ISChat:new(15, getCore():getScreenHeight() - 400, 500, 200)
    ISChat.chat:initialise()
    ISChat.chat:addToUIManager()
    ISChat.chat:setVisible(true)
    ISChat.chat:bringToTop()
    ISLayoutManager.RegisterWindow('chat', ISChat, ISChat.chat)

    ISChat.instance:setVisible(true)

    Events.OnAddMessage.Add(ISChat.addLineInChat)
    Events.OnMouseDown.Add(ISChat.unfocusEvent)
    Events.OnKeyPressed.Add(ISChat.onToggleChatBox)
    Events.OnKeyKeepPressed.Add(ISChat.onKeyKeepPressed)
    Events.OnTabAdded.Add(ISChat.onTabAdded)
    Events.OnSetDefaultTab.Add(ISChat.onSetDefaultTab)
    Events.OnTabRemoved.Add(ISChat.onTabRemoved)
    Events.SwitchChatStream.Add(ISChat.onSwitchStream)
end

Events.OnGameStart.Add(ISChat.createChat)

local function ProcessChatCommand(stream, command)
    local yacmCommand = ParseYacmMessage(command)
    if yacmCommand == nil then
        return false
    end
    if stream.name == 'yell' then
        YacmClientSendCommands.sendChatMessage(command, 'yell')
    elseif stream.name == 'say' then
        YacmClientSendCommands.sendChatMessage(command, 'say')
    elseif stream.name == 'low' then
        YacmClientSendCommands.sendChatMessage(command, 'low')
    elseif stream.name == 'whisper' then
        YacmClientSendCommands.sendChatMessage(command, 'whisper')
    elseif stream.name == 'pm' then
        local targetStart, targetEnd = command:find('^%s*"%a+%s?%a+"')
        if targetStart == nil then
            targetStart, targetEnd = command:find('^%s*%a+')
        end
        if targetStart == nil or targetEnd + 1 >= #command or command:sub(targetEnd + 1, targetEnd + 1) ~= ' ' then
            return false
        end
        local target = command:sub(targetStart, targetEnd)
        local pmBody = command:sub(targetEnd + 2)
        YacmClientSendCommands.sendPrivateMessage(pmBody, target)
        ISChat.instance.chatText.lastChatCommand = ISChat.instance.chatText.lastChatCommand .. target .. ' '
    elseif stream.name == 'faction' then
        YacmClientSendCommands.sendChatMessage(command, 'faction')
    elseif stream.name == 'safehouse' then
        YacmClientSendCommands.sendChatMessage(command, 'safehouse')
    elseif stream.name == 'general' then
        YacmClientSendCommands.sendChatMessage(command, 'general')
    elseif stream.name == 'admin' then
        YacmClientSendCommands.sendChatMessage(command, 'admin')
    elseif stream.name == 'ooc' then
        YacmClientSendCommands.sendChatMessage(command, 'ooc')
    end
    return true
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
            print('user error: tried to send command ' ..
                stream['name'] .. ' from TabID ' .. chat.currentTabID ..
                ' but TabID ' .. stream.tabID .. ' was expected')
        else
            chat.chatText.lastChatCommand = commandName
            if #commandName > 0 and #command >= #commandName then
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
    for tabNumber, chatText in pairs(self.tabs) do
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
    ['pm'] = { 255, 149, 211 },
    ['faction'] = { 100, 255, 66 },
    ['safehouse'] = { 220, 255, 80 },
    ['general'] = { 109, 111, 170 },
    ['admin'] = { 230, 130, 111 },
    ['ooc'] = { 146, 255, 148 },
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
    ['radio'] = ' over the radio, ',
    ['pm'] = ' (private): ',
    ['faction'] = ' (faction): ',
    ['safehouse'] = ' (Safe House): ',
    ['general'] = ' (General): ',
    ['admin'] = ' (Admin): ',
    ['ooc'] = ' (OOC): ',
}

function BuildVerbString(type)
    if MessageTypeToVerb[type] == nil then
        error('unknown message type "' .. type .. '"')
    end
    return MessageTypeToVerb[type]
end

local NoQuoteTypes = {
    ['general'] = true,
    ['safehouse'] = true,
    ['faction'] = true,
    ['admin'] = true,
    ['pm'] = true,
}

function BuildQuote(type)
    if NoQuoteTypes[type] == true then
        return ''
    end
    return '"'
end

function BuildMessageFromPacket(packet)
    local messageColor = BuildColorFromMessageType(packet.type)
    local message = ParseYacmMessage(packet.message, messageColor, 20)
    local radioPrefix = ''
    if packet.type == 'radio' then
        radioPrefix = '(' .. string.format('%.1fMHz', packet.frequency / 1000) .. '), '
    end
    local messageColorString = BuildBracketColorString(messageColor)
    local quote = BuildQuote(packet.type)
    local formatedMessage = BuildBracketColorString({ 109, 93, 199 }) ..
        packet.author ..
        BuildBracketColorString({ 150, 150, 150 }) ..
        BuildVerbString(packet.type) ..
        radioPrefix .. messageColorString .. quote .. message.body .. messageColorString .. quote
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
    ISChat.instance.bubble = ISChat.instance.bubble or {}
    ISChat.instance.typingDots = ISChat.instance.typingDots or {}
    if ISChat.instance.bubble[author] ~= nil then
        ISChat.instance.bubble[author]:delete()
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
    local bubble = Bubble:new(authorObj, message, length, 10)
    ISChat.instance.bubble[author] = bubble
    if ISChat.instance.typingDots[author] ~= nil then
        ISChat.instance.typingDots[author]:delete()
        ISChat.instance.typingDots[author] = nil
    end
end

function ISChat.onTypingPacket(author, type)
    ISChat.instance.typingDots = ISChat.instance.typingDots or {}
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
    if ISChat.instance.typingDots[author] then
        ISChat.instance.typingDots[author]:refresh()
    else
        ISChat.instance.typingDots[author] = TypingDots:new(authorObj, 1000)
    end
end

local function GetStreamFromType(type)
    for _, stream in ipairs(ISChat.allChatStreams) do
        if type == stream['name'] then
            return stream
        end
    end
    return nil
end

function ISChat.onMessagePacket(packet)
    local formattedMessage, message = BuildMessageFromPacket(packet)
    ISChat.instance.chatFont = ISChat.instance.chatFont or 'medium'
    CreateBubble(packet.author, message['bubble'], message['length'])
    local time = Calendar.getInstance():getTimeInMillis()
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, formattedMessage, time)
    local stream = GetStreamFromType(packet.type)
    if stream == nil then
        print('error: onMessagePacket: stream not found')
        return
    end

    if not ISChat.instance.chatText then
        ISChat.instance.chatText = ISChat.instance.defaultTab
        ISChat.instance:onActivateView()
    end
    local chatText = ISChat.instance.tabs[stream['tabID']]

    chatText.chatTextRawLines = chatText.chatTextRawLines or {}
    table.insert(chatText.chatTextRawLines,
        {
            time = time,
            line = formattedMessage,
        })
    if chatText.tabTitle ~= ISChat.instance.chatText.tabTitle then
        local alreadyExist = false
        for _, blinkedTab in pairs(ISChat.instance.panel.blinkTabs) do
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
        ISChat.onMessagePacket({
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

    if not ISChat.instance.chatText then
        ISChat.instance.chatText = ISChat.instance.defaultTab
        ISChat.instance:onActivateView()
    end
    local chatText
    if tabID + 1 == 1 then
        chatText = ISChat.instance.tabs[tabID + 1]
    elseif tabID + 1 == 2 then
        chatText = ISChat.instance.tabs[tabID + 1]
    else
        print('error: addLineInChat: unknown id ' .. tabID)
        return
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

function ISChat:render()
    if ISChat.instance.bubble then
        local indexToDelete = {}
        for index, bubble in pairs(ISChat.instance.bubble) do
            if bubble.dead then
                bubble:delete()
                table.insert(indexToDelete, index)
            else
                bubble:render()
            end
        end
        for _, index in pairs(indexToDelete) do
            ISChat.instance.bubble[index] = nil
        end
    end

    if ISChat.instance.typingDots then
        local indexToDelete = {}
        for index, typingDots in pairs(ISChat.instance.typingDots) do
            if typingDots.dead then
                typingDots:delete()
                table.insert(indexToDelete, index)
            else
                typingDots:render()
            end
        end
        for _, index in pairs(indexToDelete) do
            ISChat.instance.typingDots[index] = nil
        end
    end
    ISCollapsableWindow.render(self)
end

function ISChat.onTextChange()
    local t = ISChat.instance.textEntry
    local internalText = t:getInternalText()
    if ISChat.instance.chatText.lastChatCommand ~= nil then
        for _, chat in ipairs(ISChat.instance.chatText.chatStreams) do
            local prefix
            if chat.command and luautils.stringStarts(internalText, chat.command) then
                prefix = chat.command
            elseif chat.shortCommand and luautils.stringStarts(internalText, chat.shortCommand) then
                prefix = chat.shortCommand
            end
            if prefix then
                if string.sub(t:getText(), prefix:len() + 1, t:getText():len()):len() <= 5
                    and luautils.stringStarts(internalText, "/")
                    and luautils.stringEnds(internalText, "/") then
                    t:setText("/")
                    return
                end
            end
        end
        if t:getText():len() <= 5 and luautils.stringEnds(internalText, "/") then
            t:setText("/")
            return
        end
    end
    local stream = GetCommandFromMessage(internalText)
    if stream ~= nil then
        YacmClientSendCommands.sendTyping(getPlayer():getUsername(), stream['name'])
    end
end

function ISChat:onActivateView()
    if self.tabCnt > 1 then
        self.chatText = self.panel.activeView.view
    end
    for i, blinkedTab in ipairs(self.panel.blinkTabs) do
        if self.chatText.tabTitle and self.chatText.tabTitle == blinkedTab then
            table.remove(self.panel.blinkTabs, i)
            break
        end
    end
end

function ISChat:createTab()
    local chatY = self:titleBarHeight() + self.btnHeight + 2 * self.inset
    local chatHeight = self.textEntry:getY() - chatY
    local chatText = ISRichTextPanel:new(0, chatY, self:getWidth(), chatHeight)
    chatText.maxLines = 500
    chatText:initialise()
    chatText.background = false
    chatText:setAnchorBottom(true)
    chatText:setAnchorRight(true)
    chatText:setAnchorTop(true)
    chatText:setAnchorLeft(true)
    chatText.log = {}
    chatText.logIndex = 0
    chatText.marginTop = 2
    chatText.marginBottom = 0
    chatText.onRightMouseUp = nil
    chatText.render = ISChat.render_chatText
    chatText.autosetheight = false
    chatText:addScrollBars()
    chatText.vscroll:setVisible(false)
    chatText.vscroll.background = false
    chatText:ignoreHeightChange()
    chatText:setVisible(false)
    chatText.chatTextLines = {}
    chatText.chatMessages = {}
    chatText.onRightMouseUp = ISChat.onRightMouseUp
    chatText.onRightMouseDown = ISChat.onRightMouseDown
    chatText.onMouseUp = ISChat.onMouseUp
    chatText.onMouseDown = ISChat.onMouseDown
    return chatText
end

function ISChat:render_chatText()
    self:setStencilRect(0, 0, self.width, self.height)
    ISRichTextPanel.render(self)
    self:clearStencilRect()
end

ISChat.onTabAdded = function(tabTitle, tabID)
    -- callback from the Java
    -- 0 is General
    -- 1 is Admin
    if tabID == 1 then
        AddTab('Admin', 3)
    end
end

local function GetFirstTab()
    if ISChat.instance.tabs == nil then
        return nil
    end
    for tabId, tab in pairs(ISChat.instance.tabs) do
        return tabId, tab
    end
end

ISChat.onTabRemoved = function(tabTitle, tabID)
    if tabID ~= 1 then -- Admin tab is 1 in the Java code
        return
    end
    tabID = 3 -- Admin tab is 3 in our table
    local foundTab
    for tabId, tab in pairs(ISChat.instance.tabs) do
        if tabID == tab.tabID then
            foundTab = tab
            table.remove(ISChat.instance.tabs, tabId)
            break
        end
    end
    if ISChat.instance.tabCnt > 1 then
        for i, blinkedTab in ipairs(ISChat.instance.panel.blinkTabs) do
            if tabTitle == blinkedTab then
                table.remove(ISChat.instance.panel.blinkTabs, i)
                break
            end
        end
        ISChat.instance.panel:removeView(foundTab)
        ISChat.instance.minimumWidth = ISChat.instance.panel:getWidthOfAllTabs() + 2 * ISChat.instance.inset;
    end
    ISChat.instance.tabCnt = ISChat.instance.tabCnt - 1
    local firstTabId, firstTab = GetFirstTab()
    if firstTabId == nil then
        return
    end
    if ISChat.instance.currentTabID == tabID then
        ISChat.instance.currentTabID = firstTabId
        local chat = ISChat.instance
        chat.panel:activateView(chat.tabs[chat.currentTabID].tabTitle)
    end
    if ISChat.instance.tabCnt == 1 then
        local lastTab = firstTab
        ISChat.instance.panel:setVisible(false)
        ISChat.instance.panel:removeView(lastTab)
        ISChat.instance.chatText = lastTab
        ISChat.instance:addChild(ISChat.instance.chatText)
        ISChat.instance.chatText:setVisible(true)
    end
    ISChat.instance:onActivateView();
end

ISChat.onSetDefaultTab = function(defaultTabTitle)
end

local function GetNextTabId(currentTabId)
    local firstId = nil
    local found = false
    for tabId, _ in pairs(ISChat.instance.tabs) do
        if firstId == nil then
            firstId = tabId
        end
        if currentTabId == tabId then
            found = true
        elseif found == true then
            return tabId
        end
    end
    return firstId
end

ISChat.onToggleChatBox = function(key)
    if ISChat.instance == nil then return; end
    if key == getCore():getKey("Toggle chat") or key == getCore():getKey("Alt toggle chat") then
        ISChat.instance:focus()
    end
    local chat = ISChat.instance;
    if key == getCore():getKey("Switch chat stream") then
        local nextTabId = GetNextTabId(chat.currentTabID)
        if nextTabId == nil then
            print('error: onToggleChatBox: next tab ID not found')
            return
        end
        chat.currentTabID = nextTabId
        chat.panel:activateView(chat.tabs[chat.currentTabID].tabTitle)
        ISChat.instance:onActivateView()
    end
end

local function GetTabFromOrder(tabIndex)
    local index = 1
    for tabId, tab in pairs(ISChat.instance.tabs) do
        if tabIndex == index then
            return tabId
        end
        index = index + 1
    end
    return nil
end

ISChat.ISTabPanelOnMouseDown = function(target, x, y)
    if target:getMouseY() >= 0 and target:getMouseY() < target.tabHeight then
        if target:getScrollButtonAtX(x) == "left" then
            target:onMouseWheel(-1)
            return true
        end
        if target:getScrollButtonAtX(x) == "right" then
            target:onMouseWheel(1)
            return true
        end
        local tabIndex = target:getTabIndexAtX(target:getMouseX())
        local tabId = GetTabFromOrder(tabIndex)
        if tabId ~= nil then
            ISChat.instance.currentTabID = tabId
        end
        -- if we clicked on a tab, the first time we set up the x,y of the mouse, so next time we can see if the player moved the mouse (moved the tab)
        if tabIndex >= 1 and tabIndex <= #target.viewList and ISTabPanel.xMouse == -1 and ISTabPanel.yMouse == -1 then
            ISTabPanel.xMouse = target:getMouseX();
            ISTabPanel.yMouse = target:getMouseY();
            target.draggingTab = tabIndex - 1;
            local clickedTab = target.viewList[target.draggingTab + 1];
            target:activateView(clickedTab.name)
            return true
        end
    end
    return false
end

Events.OnChatWindowInit.Add(ISChat.initChat)
