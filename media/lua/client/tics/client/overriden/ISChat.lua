local TICS_VERSION = require('tics/shared/Version')


local ChatUI                 = require('tics/client/ui/ChatUI')
local ChatText               = require('tics/client/ui/Chat/ChatText')

local AvatarManager          = require('tics/client/AvatarManager')
local AvatarUploadWindow     = require('tics/client/ui/AvatarUploadWindow')
local AvatarValidationWindow = require('tics/client/ui/AvatarValidationWindow')
local Character              = require('tics/shared/utils/Character')
local FakeRadioPacket        = require('tics/client/FakeRadioPacket')
local Parser                 = require('tics/client/parser/Parser')
local PlayerBubble           = require('tics/client/ui/bubble/PlayerBubble')
local RadioBubble            = require('tics/client/ui/bubble/RadioBubble')
local RadioRangeIndicator    = require('tics/client/ui/RadioRangeIndicator')
local RangeIndicator         = require('tics/client/ui/RangeIndicator')
local ClientSend             = require('tics/client/network/ClientSend')
local StringBuilder          = require('tics/client/parser/StringBuilder')
local StringFormat           = require('tics/shared/utils/StringFormat')
local StringParser           = require('tics/shared/utils/StringParser')
local TypingDots             = require('tics/client/ui/TypingDots')
local World                  = require('tics/shared/utils/World')


ISChat.allChatStreams     = {}
ISChat.allChatStreams[1]  = { name = 'say', command = '/say ', shortCommand = '/s ', tabID = 1 }
ISChat.allChatStreams[2]  = { name = 'whisper', command = '/whisper ', shortCommand = '/w ', tabID = 1 }
ISChat.allChatStreams[3]  = { name = 'low', command = '/low ', shortCommand = '/l ', tabID = 1 }
ISChat.allChatStreams[4]  = { name = 'yell', command = '/yell ', shortCommand = '/y ', tabID = 1 }
ISChat.allChatStreams[5]  = { name = 'faction', command = '/faction ', shortCommand = '/f ', tabID = 1 }
ISChat.allChatStreams[6]  = { name = 'safehouse', command = '/safehouse ', shortCommand = '/sh ', tabID = 1 }
ISChat.allChatStreams[7]  = { name = 'general', command = '/all ', shortCommand = '/g ', tabID = 1 }
ISChat.allChatStreams[8]  = { name = 'scriptedRadio', command = nil, shortCommand = nil, tabID = 1 }
ISChat.allChatStreams[9]  = { name = 'ooc', command = '/ooc ', shortCommand = '/o ', tabID = 2 }
ISChat.allChatStreams[10] = { name = 'pm', command = '/pm ', shortCommand = '/p ', tabID = 3 }
ISChat.allChatStreams[11] = { name = 'admin', command = '/admin ', shortCommand = '/a ', tabID = 4 }


ISChat.noVerbStreams    = {}
ISChat.noVerbStreams[1] = { name = 'mesay', command = '/me ', shortCommand = '/ms ', tabID = 1, forget = true }
ISChat.noVerbStreams[2] = { name = 'mewhisper', command = '/mewhisper ', shortCommand = '/mw ', tabID = 1, forget = true }
ISChat.noVerbStreams[3] = { name = 'melow', command = '/melow ', shortCommand = '/ml ', tabID = 1, forget = true }
ISChat.noVerbStreams[4] = { name = 'meyell', command = '/meyell ', shortCommand = '/my ', tabID = 1, forget = true }


ISChat.ticsCommand    = {}
ISChat.ticsCommand[1] = { name = 'color', command = '/color', shortCommand = nil }
ISChat.ticsCommand[2] = { name = 'pitch', command = '/pitch', shortCommand = nil }
ISChat.ticsCommand[3] = { name = 'roll', command = '/roll', shortCommand = nil }


ISChat.defaultTabStream    = {}
ISChat.defaultTabStream[1] = ISChat.allChatStreams[1]
ISChat.defaultTabStream[2] = ISChat.allChatStreams[9]
ISChat.defaultTabStream[3] = ISChat.allChatStreams[10]
ISChat.defaultTabStream[4] = ISChat.allChatStreams[11]


ISChat.lastTabStream    = {}
ISChat.lastTabStream[1] = ISChat.defaultTabStream[1]
ISChat.lastTabStream[2] = ISChat.defaultTabStream[2]
ISChat.lastTabStream[3] = ISChat.defaultTabStream[3]
ISChat.lastTabStream[4] = ISChat.defaultTabStream[4]


local function IsOnlySpacesOrEmpty(command)
    local commandWithoutSpaces = command:gsub('%s+', '')
    return #commandWithoutSpaces == 0
end

local function GetCommandFromMessage(command)
    if not luautils.stringStarts(command, '/') then
        local defaultStream = ISChat.defaultTabStream[ISChat.instance.currentTabID]
        return defaultStream, '', false
    end
    if IsOnlySpacesOrEmpty(command) then
        return nil
    end
    for _, stream in ipairs(ISChat.allChatStreams) do
        if stream.command and luautils.stringStarts(command, stream.command) then
            return stream, stream.command, false
        elseif stream.shortCommand and luautils.stringStarts(command, stream.shortCommand) then
            return stream, stream.shortCommand, false
        end
    end
    for _, stream in ipairs(ISChat.noVerbStreams) do
        if stream.command and luautils.stringStarts(command, stream.command) then
            return stream, stream.command
        elseif stream.shortCommand and luautils.stringStarts(command, stream.shortCommand) then
            return stream, stream.shortCommand
        end
    end
    return nil
end

local function GetTicsCommandFromMessage(command)
    if not luautils.stringStarts(command, '/') then
        return nil
    end
    if IsOnlySpacesOrEmpty(command) then
        return nil
    end
    for _, stream in ipairs(ISChat.ticsCommand) do
        if luautils.stringStarts(command, stream.command) then
            return stream, stream.command
        elseif stream.shortCommand and luautils.stringStarts(command, stream.shortCommand) then
            return stream, stream.shortCommand
        end
    end
    return nil
end

local function UpdateTabStreams(newTab, tabID)
    newTab.chatStreams = {}
    for _, stream in pairs(ISChat.allChatStreams) do
        local name = stream['name']
        if stream['tabID'] == tabID and TicsServerSettings and TicsServerSettings[name] and TicsServerSettings[name]['enabled'] then
            table.insert(newTab.chatStreams, stream)
        end
    end
    if #newTab.chatStreams >= 1 then
        ISChat.defaultTabStream[tabID] = newTab.chatStreams[1]
        newTab.lastChatCommand = newTab.chatStreams[1].command
    end
end

local function UpdateRangeIndicatorVisibility()
    if ISChat.instance.rangeButtonState == 'visible' then
        if ISChat.instance.rangeIndicator and ISChat.instance.focused then
            ISChat.instance.rangeIndicator:subscribe()
        end
    elseif ISChat.instance.rangeButtonState == 'hidden' then
        if ISChat.instance.rangeIndicator then
            ISChat.instance.rangeIndicator:unsubscribe()
        end
    else
        if ISChat.instance.rangeIndicator then
            ISChat.instance.rangeIndicator:subscribe()
        end
    end
end

local function UpdateRangeIndicator(stream)
    if TicsServerSettings ~= nil
        and TicsServerSettings[stream.name]['range'] ~= nil
        and TicsServerSettings[stream.name]['range'] ~= -1
        and TicsServerSettings[stream.name]['color'] ~= nil
    then
        if ISChat.instance.rangeIndicator then
            ISChat.instance.rangeIndicator:unsubscribe()
        end
        local range = TicsServerSettings[stream.name]['range']
        ISChat.instance.rangeIndicator = RangeIndicator:new(getPlayer(), range,
            TicsServerSettings[stream.name]['color'])
        UpdateRangeIndicatorVisibility()
    else
        if ISChat.instance.rangeIndicator then
            ISChat.instance.rangeIndicator:unsubscribe()
        end
        ISChat.instance.rangeIndicator = nil
    end
end

ISChat.onSwitchStream = function()
    if ISChat.focused then
        local t = ISChat.instance.textEntry
        local internalText = t:getInternalText()
        local data = luautils.split(internalText, " ")
        local onlineUsers = getOnlinePlayers()
        for i = 0, onlineUsers:size() - 1 do
            local username = onlineUsers:get(i):getUsername()
            if #data > 1 and string.match(string.lower(username), string.lower(data[#data])) then
                local txt = ""
                for i = 1, #data - 1 do
                    txt = txt .. data[i] .. " "
                end
                txt = txt .. username
                ISChat.instance.textEntry:setText(txt)
                return
            end
        end

        local curTxtPanel = ISChat.instance.chatText
        if curTxtPanel == nil then
            return
        end
        local chatStreams = curTxtPanel.chatStreams
        curTxtPanel.streamID = curTxtPanel.streamID % #chatStreams + 1
        local stream = chatStreams[curTxtPanel.streamID]
        ISChat.lastTabStream[ISChat.instance.currentTabID] = stream
        ISChat.instance.textEntry:setText(stream.command)
        UpdateRangeIndicator(stream)
    end
end

local function AddTab(tabTitle, tabID)
    local chat = ISChat.instance
    if chat.tabs[tabID] ~= nil then
        return
    end
    local newTab = chat:createTab()
    newTab.parent = chat
    newTab.tabTitle = tabTitle
    newTab.tabID = tabID
    newTab.streamID = 1
    UpdateTabStreams(newTab, tabID)
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

Events.OnChatWindowInit.Remove(ISChat.initChat)

local function GetRandomInt(min, max)
    return ZombRand(max - min) + min
end

local function GenerateRandomColor()
    return { GetRandomInt(0, 254), GetRandomInt(0, 254), GetRandomInt(0, 254), }
end

local function SetPlayerColor(color)
    ISChat.instance.ticsModData['playerColor'] = color
    ModData.add('tics', ISChat.instance.ticsModData)
end

local function SetPlayerPitch(pitch)
    ISChat.instance.ticsModData['voicePitch'] = pitch
    ModData.add('tics', ISChat.instance.ticsModData)
end

local function RandomVoicePitch(isFemale)
    local randomPitch = ZombRandFloat(0.85, 1.15)
    if isFemale == true then
        randomPitch = randomPitch + 0.30
    end
    return randomPitch
end

local function InitGlobalModData()
    local ticsModData = ModData.getOrCreate("tics")
    ISChat.instance.ticsModData = ticsModData

    if ticsModData['playerColor'] == nil then
        SetPlayerColor(GenerateRandomColor())
    end
    if ticsModData['isVoiceEnabled'] == nil and ISChat.instance.isVoiceEnabled == nil then
        -- wait for the server settings to override this if voices are enabled by default
        ISChat.instance.isVoiceEnabled = false
    elseif ticsModData['isVoiceEnabled'] ~= nil then
        ISChat.instance.isVoiceEnabled = ticsModData['isVoiceEnabled']
    end
    if ticsModData['isRadioIconEnabled'] == nil and ISChat.instance.isRadioIconEnabled == nil then
        ISChat.instance.isRadioIconEnabled = true
    elseif ticsModData['isRadioIconEnabled'] ~= nil then
        ISChat.instance.isRadioIconEnabled = ticsModData['isRadioIconEnabled']
    end
    if ticsModData['isPortraitEnabled'] == nil and ISChat.instance.isPortraitEnabled == nil then
        ISChat.instance.isPortraitEnabled = true
    elseif ticsModData['isPortraitEnabled'] ~= nil then
        ISChat.instance.isPortraitEnabled = ticsModData['isPortraitEnabled']
    end
    if ticsModData['voicePitch'] == nil then
        local randomPitch = RandomVoicePitch(getPlayer():getVisual():isFemale())
        SetPlayerPitch(randomPitch)
    end
end

local lastAskedDataTime = Calendar.getInstance():getTimeInMillis() - 2000
local function AskServerData()
    local delta = Calendar.getInstance():getTimeInMillis() - lastAskedDataTime
    if delta < 2000 then
        return
    end
    lastAskedDataTime = Calendar.getInstance():getTimeInMillis()

    ClientSend.sendAskSandboxVars()
end

ISChat.initChat = function()
    TicsServerSettings = nil
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
    instance.rangeButtonState = 'hidden'
    instance.online = false
    instance.lastDiscordMessages = {}

    InitGlobalModData()
    AddTab('General', 1)
    AvatarManager:createRequestDirectory()
    Events.OnPostRender.Add(AskServerData)
end

Events.OnGameStart.Remove(ISChat.createChat)

local function CreateChat()
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

Events.OnGameStart.Add(CreateChat)

local function ProcessChatCommand(stream, command)
    if TicsServerSettings and TicsServerSettings[stream.name] == false then
        return false
    end
    local pitch = ISChat.instance.ticsModData['voicePitch']
    local ticsCommand = Parser.ParseTicsMessage(command)
    local playerColor = ISChat.instance.ticsModData['playerColor']
    if ticsCommand == nil then
        return false
    end
    if stream.name == 'yell' then
        ClientSend.sendChatMessage(command, playerColor, 'yell', pitch, false)
    elseif stream.name == 'say' then
        ClientSend.sendChatMessage(command, playerColor, 'say', pitch, false)
    elseif stream.name == 'low' then
        ClientSend.sendChatMessage(command, playerColor, 'low', pitch, false)
    elseif stream.name == 'whisper' then
        ClientSend.sendChatMessage(command, playerColor, 'whisper', pitch, false)
    elseif stream.name == 'meyell' then
        ClientSend.sendChatMessage(command, playerColor, 'yell', pitch, true)
    elseif stream.name == 'mesay' then
        ClientSend.sendChatMessage(command, playerColor, 'say', pitch, true)
    elseif stream.name == 'melow' then
        ClientSend.sendChatMessage(command, playerColor, 'low', pitch, true)
    elseif stream.name == 'mewhisper' then
        ClientSend.sendChatMessage(command, playerColor, 'whisper', pitch, true)
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
        ClientSend.sendPrivateMessage(pmBody, playerColor, target, pitch)
        ISChat.instance.chatText.lastChatCommand = ISChat.instance.chatText.lastChatCommand .. target .. ' '
    elseif stream.name == 'faction' then
        ClientSend.sendChatMessage(command, playerColor, 'faction', pitch, false)
    elseif stream.name == 'safehouse' then
        ClientSend.sendChatMessage(command, playerColor, 'safehouse', pitch, false)
    elseif stream.name == 'general' then
        ClientSend.sendChatMessage(command, playerColor, 'general', pitch, false)
    elseif stream.name == 'admin' then
        ClientSend.sendChatMessage(command, playerColor, 'admin', pitch, false)
    elseif stream.name == 'ooc' then
        ClientSend.sendChatMessage(command, playerColor, 'ooc', pitch, false)
    else
        return false
    end
    if TicsServerSettings ~= nil
        and TicsServerSettings[stream.name] ~= nil
        and TicsServerSettings[stream.name]['zombieRange'] ~= nil
        and TicsServerSettings[stream.name]['zombieRange'] ~= -1
    then
        local zombieRange = TicsServerSettings[stream.name]['zombieRange']
        local square = getPlayer():getSquare()
        addSound(getPlayer(), square:getX(), square:getY(), square:getZ(), zombieRange, zombieRange)
    end
    return true
end

local function RemoveLeadingSpaces(text)
    local trailingCount = 0
    for index = 1, #text do
        if text:byte(index) ~= 32 then -- 32 is ASCII code for space ' '
            break
        end
        trailingCount = trailingCount + 1
    end
    return text:sub(trailingCount)
end

local function GetArgumentsFromMessage(ticsCommand, message)
    if #message < #ticsCommand['command'] + 2 then -- command + space + chars
        return nil
    end
    local arguments = message:sub(#ticsCommand['command'] + 2)
    arguments = RemoveLeadingSpaces(arguments)
    if #arguments == 0 then
        return nil
    end
    return arguments
end

local function ProcessColorCommand(arguments)
    local currentColor = ISChat.instance.ticsModData['playerColor']
    if arguments == nil then
        ISChat.sendInfoToCurrentTab('color value is ' .. StringFormat.color(currentColor))
        return true
    end
    local newColor = StringParser.rgbStringToRGB(arguments) or StringParser.hexaStringToRGB(arguments)
    if newColor == nil then
        return false
    end
    SetPlayerColor(newColor)
    ISChat.sendInfoToCurrentTab('player color updated to '
        .. StringFormat.color(newColor)
        .. ' from '
        .. StringFormat.color(currentColor))
    return true
end

local function ProcessPitchCommand(arguments)
    if arguments == nil then
        ISChat.sendInfoToCurrentTab('pitch value is ' .. ISChat.instance.ticsModData['voicePitch'])
        return true
    end
    local regex = '^(%d+.?%d*) *$'
    local valueAsText = arguments:match(regex)
    if valueAsText then
        local value = tonumber(valueAsText)
        if value ~= nil and value >= 0.85 and value <= 1.45 then
            local currentPitch = ISChat.instance.ticsModData['voicePitch']
            SetPlayerPitch(value)
            ISChat.sendInfoToCurrentTab('pitch value updated to ' .. value .. ' from ' .. currentPitch)
            return true
        end
    end
    return false
end

local function ProcessRollCommand(arguments)
    if arguments == nil then
        return false
    end
    local regex = '^(%d*)d(%d+)(%+?)(%d*) *$'
    local m1, m2, m3, m4 = arguments:match(regex)
    local diceCount = tonumber(m1)
    local diceType = tonumber(m2)
    local hasPlus = m3 == '+'
    local addCount = tonumber(m4)
    if diceType == nil or diceType < 1 then
        return false
    end
    if diceCount == nil then
        diceCount = 1
    end
    if diceCount < 1 or diceCount > 20 or (hasPlus and addCount == nil) then
        return false
    end
    ClientSend.sendRoll(diceCount, diceType, addCount)
    return true
end

local function ProcessTicsCommand(ticsCommand, message)
    local arguments = GetArgumentsFromMessage(ticsCommand, message)
    if ticsCommand['name'] == 'color' then
        if ProcessColorCommand(arguments) == false then
            ISChat.sendErrorToCurrentTab(
                'color command expects the format: "/color value" with value as 255, 255, 255 or #FFFFFF')
            return false
        end
    elseif ticsCommand['name'] == 'pitch' then
        if ProcessPitchCommand(arguments) == false then
            ISChat.sendErrorToCurrentTab('pitch command expects the format: "/pitch value" with value from 0.85 to 1.45')
            return false
        end
    elseif ticsCommand['name'] == 'roll' then
        if ProcessRollCommand(arguments) == false then
            ISChat.sendErrorToCurrentTab(
                'roll command expects the format: "/roll xdy" with x and y numbers and x from 1 to 20')
            return false
        end
    end
end

function ISChat:onCommandEntered()
    local command = ISChat.instance.textEntry:getText()
    local chat = ISChat.instance

    ISChat.instance:unfocus()
    if not command or command == '' then
        return
    end

    local stream, commandName = GetCommandFromMessage(command)
    local ticsCommand = GetTicsCommandFromMessage(command)
    if stream then -- chat message
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
        chat.chatText.lastChatCommand = commandName
        chat:logChatCommand(command)
    elseif ticsCommand ~= nil then
        ProcessTicsCommand(ticsCommand, command)
    elseif luautils.stringStarts(command, '/') then -- server command
        SendCommandToServer(command)
        chat:logChatCommand(command)
    end

    doKeyPress(false)
    ISChat.instance.timerTextEntry = 20
end

local function BuildChannelPrefixString(channel)
    if channel == nil then
        return ''
    end
    local color
    if TicsServerSettings ~= nil then
        color = TicsServerSettings[channel]['color']
    else
        color = { 255, 255, 255 }
    end
    return StringBuilder.BuildBracketColorString(color) .. '[' .. channel .. '] '
end

local function FontStringToEnum(fontString)
    if fontString == 'small' then
        return UIFont.NewSmall
    elseif fontString == 'medium' then
        return UIFont.Medium
    else
        return UIFont.Large
    end
end

function ISChat:updateChatPrefixSettings()
    updateChatSettings(self.chatFont, self.showTimestamp, self.showTitle)
    for tabNumber, chatText in pairs(self.tabs) do
        chatText.firstPrintableLine = 1
        chatText.text = ""
        local newText = ""
        chatText.chatTextLines = {}
        chatText.chatTextRawLines = chatText.chatTextRawLines or {}
        chatText.defaultFont = FontStringToEnum(self.chatFont or 'medium')
        for i, msg in ipairs(chatText.chatTextRawLines) do
            self.chatFont = self.chatFont or 'medium'
            local line = StringBuilder.BuildFontSizeString(self.chatFont)
            if self.showTimestamp then
                line = line .. StringBuilder.BuildTimePrefixString(msg.time)
            end
            if self.showTitle then
                line = line .. BuildChannelPrefixString(msg.channel)
            end
            line = line .. msg.line .. StringBuilder.BuildNewLine()
            table.insert(chatText.chatTextLines, line)
            if i == #chatText.chatTextRawLines then
                line = string.gsub(line, " <LINE> $", "")
            end
            newText = newText .. line
        end
        chatText.text = newText
        chatText:paginate()
        chatText:scrollToBottom()
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
    if TicsServerSettings ~= nil
        and TicsServerSettings[type]
        and TicsServerSettings[type]['color']
    then
        return TicsServerSettings[type]['color']
    elseif MessageTypeToColor[type] == nil then
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
    ['scriptedRadio'] = 'over the radio, ',
    ['pm'] = ' ',
    ['faction'] = ' ',
    ['safehouse'] = ' ',
    ['general'] = ' ',
    ['admin'] = ' ',
    ['ooc'] = ' ',
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
    ['ooc'] = true,
}

function BuildQuote(type)
    if NoQuoteTypes[type] == true then
        return ''
    end
    return '"'
end

function BuildMessageFromPacket(type, message, name, playerColor, frequency, disableVerb)
    local messageColor = BuildColorFromMessageType(type)
    local parsedMessage = Parser.ParseTicsMessage(message, messageColor, 20, 200)
    local radioPrefix = ''
    if frequency then
        radioPrefix = '(' .. string.format('%.1fMHz', frequency / 1000) .. ') '
    end
    local messageColorString = StringBuilder.BuildBracketColorString(messageColor)
    local quote
    local verbString
    if not disableVerb and (TicsServerSettings == nil or TicsServerSettings['options']['verb'] == true) then
        quote = BuildQuote(type)
        verbString = BuildVerbString(type)
    else
        quote = ''
        verbString = ' '
    end
    local formatedMessage = ''
    if name ~= nil then
        formatedMessage = formatedMessage .. StringBuilder.BuildBracketColorString(playerColor) .. name
    end
    formatedMessage = formatedMessage ..
        StringBuilder.BuildBracketColorString({ 150, 150, 150 }) ..
        verbString ..
        radioPrefix .. messageColorString .. quote .. parsedMessage.body .. messageColorString .. quote
    return formatedMessage, parsedMessage
end

function BuildChatMessage(fontSize, showTimestamp, showTitle, rawMessage, time, channel)
    local line = StringBuilder.BuildFontSizeString(fontSize)
    if showTimestamp then
        line = line .. StringBuilder.BuildTimePrefixString(time)
    end
    if showTitle and channel ~= nil then
        line = line .. BuildChannelPrefixString(channel)
    end
    line = line .. rawMessage
    return line
end

function CreatePlayerBubble(author, message, color, voicePitch)
    ISChat.instance.bubble = ISChat.instance.bubble or {}
    ISChat.instance.typingDots = ISChat.instance.typingDots or {}
    if author == nil then
        print('TICS error: CreatePlayerBubble: author is null')
        return
    end
    local authorObj = World.getPlayerByUsername(author)
    if authorObj == nil then
        print('TICS error: CreatePlayerBubble: author not found ' .. author)
        return
    end
    local timer = 10
    local opacity = 70
    if TicsServerSettings then
        timer = TicsServerSettings['options']['bubble']['timer']
        opacity = TicsServerSettings['options']['bubble']['opacity']
    end
    local portrait = (TicsServerSettings and ISChat.instance.isPortraitEnabled and TicsServerSettings['options']['portrait'])
        or 1
    local bubble = PlayerBubble:new(
        authorObj, message, color, timer, opacity, ISChat.instance.isVoiceEnabled, voicePitch, portrait)
    ISChat.instance.bubble[author] = bubble
    -- the player is not typing anymore if his bubble appears
    if ISChat.instance.typingDots[author] ~= nil then
        ISChat.instance.typingDots[author] = nil
    end
end

local function CreateSquareRadioBubble(position, message, messageColor, voicePitch)
    ISChat.instance.radioBubble = ISChat.instance.radioBubble or {}
    if position ~= nil then
        local x, y, z = position['x'], position['y'], position['z']
        if x == nil or y == nil or z == nil then
            print('TICS error: CreateSquareRadioBubble: nil position for a square radio')
            return
        end
        x, y, z = math.abs(x), math.abs(y), math.abs(z)
        if ISChat.instance.radioBubble['x' .. x .. 'y' .. y .. 'z' .. z] ~= nil then
            ISChat.instance.radioBubble['x' .. x .. 'y' .. y .. 'z' .. z].dead = true
        end
        local timer = 10
        local opacity = 70
        local square = getSquare(x, y, z)
        local radios = World.getSquareItemsByGroup(square, 'IsoRadio')
        local offsetY = 0
        if radios ~= nil and #radios > 0 then
            local radio = radios[1]
            offsetY = radio:getRenderYOffset()
        end
        local bubble = RadioBubble:new(
            square, message, messageColor, timer, opacity, RadioBubble.types.square,
            ISChat.instance.isVoiceEnabled, voicePitch, offsetY)
        ISChat.instance.radioBubble['x' .. x .. 'y' .. y .. 'z' .. z] = bubble
    end
end

function CreatePlayerRadioBubble(author, message, messageColor, voicePitch)
    ISChat.instance.playerRadioBubble = ISChat.instance.playerRadioBubble or {}
    if author == nil then
        print('TICS error: CreatePlayerRadioBubble: author is null')
        return
    end
    local authorObj = World.getPlayerByUsername(author)
    if authorObj == nil then
        print('TICS error: CreatePlayerRadioBubble: author not found ' .. author)
        return
    end
    local timer = 10
    local opacity = 70
    if TicsServerSettings then
        timer = TicsServerSettings['options']['bubble']['timer']
        opacity = TicsServerSettings['options']['bubble']['opacity']
    end
    local bubble = RadioBubble:new(authorObj, message, messageColor, timer, opacity,
        RadioBubble.types.player, ISChat.instance.isVoiceEnabled, voicePitch)
    ISChat.instance.playerRadioBubble[author] = bubble
end

function CreateVehicleRadioBubble(vehicle, message, messageColor, voicePitch)
    ISChat.instance.vehicleRadioBubble = ISChat.instance.vehicleRadioBubble or {}
    local timer = 10
    local opacity = 70
    if TicsServerSettings then
        timer = TicsServerSettings['options']['bubble']['timer']
        opacity = TicsServerSettings['options']['bubble']['opacity']
    end
    local keyId = vehicle:getKeyId()
    if keyId == nil then
        print('TICS error: CreateVehicleBubble: key id is null')
        return
    end
    local bubble = RadioBubble:new(vehicle, message, messageColor, timer, opacity,
        RadioBubble.types.vehicle, ISChat.instance.isVoiceEnabled, voicePitch)
    ISChat.instance.vehicleRadioBubble[keyId] = bubble
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
        ISChat.instance.typingDots[author] = TypingDots:new(authorObj, 1)
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

local function AddMessageToTab(tabID, time, formattedMessage, line, channel)
    if not ISChat.instance.chatText then
        ISChat.instance.chatText = ISChat.instance.defaultTab
        ISChat.instance:onActivateView()
    end
    local chatText = ISChat.instance.tabs[tabID]

    chatText.chatTextRawLines = chatText.chatTextRawLines or {}
    table.insert(chatText.chatTextRawLines,
        {
            time = time,
            line = formattedMessage,
            channel = channel,
        })
    local chatTextRawLinesSize = #chatText.chatTextRawLines
    local maxRawMessages = chatText.maxLines
    if chatTextRawLinesSize > maxRawMessages then
        local newRawLines = {}
        for i = chatTextRawLinesSize - maxRawMessages, chatTextRawLinesSize do
            table.insert(newRawLines, chatText.chatTextRawLines[i])
        end
        chatText.chatTextRawLines = newRawLines
    end
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
        table.insert(newLines, line .. StringBuilder.BuildNewLine())
        chatText.chatTextLines = newLines
    else
        table.insert(chatText.chatTextLines, line .. StringBuilder.BuildNewLine())
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

local function ReduceBoredom()
    local player = getPlayer()
    local boredom = player:getBodyDamage():getBoredomLevel()
    local boredomReduction = 0
    if TicsServerSettings then
        boredomReduction = TicsServerSettings['options']['boredomReduction']
    end
    player:getBodyDamage():setBoredomLevel(boredom - boredomReduction)
end

function ISChat.onDiceResult(author, characterName, diceCount, diceType, addCount, diceResults, finalResult)
    local name = characterName
    if TicsServerSettings and not TicsServerSettings['options']['showCharacterName'] then
        name = author
    end
    local message = name .. ' rolled ' .. diceCount .. 'd' .. diceType
    if addCount ~= nil then
        message = message .. '+' .. addCount
    end
    message = message .. ' ('
    local first = true
    for _, r in pairs(diceResults) do
        if first then
            first = false
        else
            message = message .. ', '
        end
        message = message .. r
    end
    message = message .. ')'
    if addCount ~= nil then
        message = message .. '+' .. addCount
    end
    message = message .. ' = ' .. finalResult
    ISChat.sendInfoToCurrentTab(message)
end

function ISChat.onMessagePacket(type, author, characterName, message, color, hideInChat, target, isFromDiscord,
                                voicePitch, disableVerb)
    if author ~= getPlayer():getUsername() then
        ReduceBoredom()
    end
    local name = characterName
    if TicsServerSettings and not TicsServerSettings['options']['showCharacterName'] then
        name = author
    end
    local formattedMessage, parsedMessage = BuildMessageFromPacket(type, message, name, color, nil, disableVerb)
    if type == 'pm' and target:lower() == getPlayer():getUsername():lower() then
        ISChat.instance.lastPrivateMessageAuthor = author
    end
    ISChat.instance.chatFont = ISChat.instance.chatFont or 'medium'
    if not isFromDiscord and voicePitch ~= nil then
        CreatePlayerBubble(author, message, BuildColorFromMessageType(type), voicePitch)
    end
    local time = Calendar.getInstance():getTimeInMillis()
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, ISChat.instance.showTitle,
        formattedMessage, time, type)
    local stream = GetStreamFromType(type)
    if stream == nil then
        print('TICS error: onMessagePacket: stream not found')
        return
    end
    if not hideInChat then
        AddMessageToTab(stream['tabID'], time, formattedMessage, line, stream['name'])
    end
end

function BuildServerMessage(fontSize, showTimestamp, showTitle, rawMessage, time, channel)
    local line = StringBuilder.BuildFontSizeString(fontSize)
    if showTimestamp then
        line = line .. StringBuilder.BuildTimePrefixString(time)
    end
    if showTitle and channel ~= nil then
        line = line .. BuildChannelPrefixString(channel)
    end
    line = line .. rawMessage
    return line
end

function ISChat.onServerMessage(message)
    local color = (TicsServerSettings and TicsServerSettings['server']['color']) or { 255, 86, 64 }
    local time = Calendar.getInstance():getTimeInMillis()
    local stream = GetStreamFromType('general')
    if stream == nil then
        print('TICS error: onMessagePacket: stream not found')
        return
    end
    local parsedMessage = Parser.ParseTicsMessage(message, color, 20, 200)
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, ISChat.instance.showTitle,
        parsedMessage.body, time, 'server')
    AddMessageToTab(stream['tabID'], time, parsedMessage.body, line, 'server')
end

local function CreateSquaresRadiosBubbles(message, messageColor, squaresInfo, voicePitch)
    if squaresInfo == nil then
        print('TICS error: CreateSquaresRadiosBubbles: squaresInfo table is null')
        return
    end
    for _, info in pairs(squaresInfo) do
        local position = info['position']
        if position ~= nil then
            CreateSquareRadioBubble(position, message, messageColor, voicePitch)
            local square = getSquare(position['x'], position['y'], position['z'])
            if square ~= nil then
                local radio = World.getFirstSquareItem(square, 'IsoRadio')
                if radio ~= nil then
                    local radioData = radio:getDeviceData()
                    if radioData ~= nil then
                        local distance = info['distance']
                        if distance ~= nil then
                            radioData:doReceiveSignal(distance)
                        else
                            print('TICS error: received radio packet for a square radio without distance')
                        end
                    else
                        print('TICS error: received radio packet for a square radio without data')
                    end
                else
                    print('TICS error: received radio packet for a square with no radio')
                end
            else
                print('TICS error: received radio packet for a null square')
            end
        else
            print('TICS error: received radio packet for a square without position')
        end
    end
end

local function CreatePlayersRadiosBubbles(message, messageColor, playersInfo, voicePitch)
    if playersInfo == nil then
        print('TICS error: CreatePlayersRadiosBubbles: playersInfo table is null')
        return
    end
    for _, info in pairs(playersInfo) do
        local username = info['username']
        if username ~= nil then
            CreatePlayerRadioBubble(
                getPlayer():getUsername(), message, messageColor, voicePitch)
            if username:upper() == getPlayer():getUsername():upper() then
                local radio = Character.getFirstHandOrBeltItemByGroup(getPlayer(), 'Radio')
                if radio ~= nil then
                    local radioData = radio:getDeviceData()
                    if radioData ~= nil then
                        local distance = info['distance']
                        if distance ~= nil then
                            radioData:doReceiveSignal(distance)
                        else
                            print('TICS error: received radio packet for a player radio without distance')
                        end
                    else
                        print('TICS error: received radio packet for a player radio without data')
                    end
                else
                    print('TICS error: received radio packet for a player with no radio in hand')
                end
            end
        else
            print('TICS error: received radio packet for a player without username')
        end
    end
end

local function CreateVehiclesRadiosBubbles(message, messageColor, vehiclesInfo, voicePitch)
    if vehiclesInfo == nil then
        print('TICS error: CreateVehiclesRadiosBubbles: vehiclesKeyIds table is null')
        return
    end
    local range = (TicsServerSettings and TicsServerSettings['say']['range']) or 15
    local vehicles = World.getVehiclesInRange(getPlayer(), range)
    for _, info in pairs(vehiclesInfo) do
        local vehicleKeyId = info['key']
        if vehicleKeyId ~= nil then
            local vehicle = vehicles[vehicleKeyId]
            if vehicle ~= nil then
                CreateVehicleRadioBubble(vehicle, message, messageColor, voicePitch)
                local radio = vehicle:getPartById('Radio')
                if radio ~= nil then
                    local radioData = radio:getDeviceData()
                    if radioData ~= nil then
                        local distance = info['distance']
                        if distance ~= nil then
                            radioData:doReceiveSignal(distance)
                        else
                            print('TICS error: received radio packet for a vehicle radio without distance')
                        end
                    else
                        print('TICS error: received radio packet for a vehicle radio without data')
                    end
                else
                    print('TICS error: received radio packet for a vehicle with no radio')
                end
            else
                print('TICS error: CreateVehiclesRadiosBubble: vehicle not found for key id ' .. vehicleKeyId)
            end
        else
            print('TICS error: received vehicle packet for a vehicle with no key')
        end
    end
end

function ISChat.onDiscordPacket(message)
    processGeneralMessage(message)
end

function ISChat.onRadioEmittingPacket(type, author, characterName, message, color, frequency, disableVerb)
    local time = Calendar.getInstance():getTimeInMillis()
    local stream = GetStreamFromType(type)
    if stream == nil then
        print('TICS error: onRadioEmittingPacket: stream not found')
        return
    end
    local name = characterName
    if TicsServerSettings and not TicsServerSettings['options']['showCharacterName'] then
        name = author
    end
    local formattedMessage, parsedMessages = BuildMessageFromPacket(type, message, name, color, frequency, disableVerb)
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, ISChat.instance.showTitle,
        formattedMessage, time, type)
    AddMessageToTab(stream['tabID'], time, formattedMessage, line, stream['name'])
end

function ISChat.onRadioPacket(type, author, characterName, message, color, radiosInfo, voicePitch, disableVerb)
    local time = Calendar.getInstance():getTimeInMillis()
    local stream = GetStreamFromType(type)
    if stream == nil then
        print('TICS error: onRadioPacket: stream not found')
        return
    end

    local playerName = getPlayer():getUsername()
    if author ~= playerName then
        ReduceBoredom()
    end
    local name = characterName
    if TicsServerSettings and not TicsServerSettings['options']['showCharacterName'] then
        name = author
    end
    for frequency, radios in pairs(radiosInfo) do
        local formattedMessage, parsedMessages = BuildMessageFromPacket(type, message, name, color, frequency,
            disableVerb)
        local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, ISChat.instance.showTitle,
            formattedMessage, time, type)
        local messageColor = BuildColorFromMessageType(type)
        CreateSquaresRadiosBubbles(message, messageColor, radios['squares'], voicePitch)
        CreatePlayersRadiosBubbles(message, messageColor, radios['players'], voicePitch)
        CreateVehiclesRadiosBubbles(message, messageColor, radios['vehicles'], voicePitch)
        -- a special packet is making sure the author always has a radio feedback in the chat
        -- useful in case the listening range and emitting range of the radio differs
        -- this is to avoid any confusion from players thinking the radios mights not work
        if author ~= playerName then
            AddMessageToTab(stream['tabID'], time, formattedMessage, line, stream['name'])
        end
    end
end

function ISChat.sendInfoToCurrentTab(message)
    local time = Calendar.getInstance():getTimeInMillis()
    local formattedMessage = StringBuilder.BuildBracketColorString({ 70, 70, 255 }) .. message
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, false,
        formattedMessage, time, nil)
    local tabID = ISChat.defaultTabStream[ISChat.instance.currentTabID]['tabID']
    AddMessageToTab(tabID, time, formattedMessage, line, nil)
end

function ISChat.sendErrorToCurrentTab(message)
    local time = Calendar.getInstance():getTimeInMillis()
    local formattedMessage = StringBuilder.BuildBracketColorString({ 255, 40, 40 }) ..
        'error: ' .. StringBuilder.BuildBracketColorString({ 255, 70, 70 }) .. message
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, false,
        formattedMessage, time, nil)
    local tabID = ISChat.defaultTabStream[ISChat.instance.currentTabID]['tabID']
    AddMessageToTab(tabID, time, formattedMessage, line, nil)
end

function ISChat.onChatErrorPacket(type, message)
    local time = Calendar.getInstance():getTimeInMillis()
    local formattedMessage = StringBuilder.BuildBracketColorString({ 255, 50, 50 }) ..
        'error: ' .. StringBuilder.BuildBracketColorString({ 255, 60, 60 }) .. message
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, ISChat.instance.showTitle,
        formattedMessage, time, type)
    local stream
    if type == nil then
        stream = ISChat.defaultTabStream[ISChat.instance.currentTabID]
    else
        stream = GetStreamFromType(type)
        if stream == nil then
            stream = ISChat.defaultTabStream[ISChat.instance.currentTabID]
        end
    end
    AddMessageToTab(stream['tabID'], time, formattedMessage, line)
end

local function GetMessageType(message)
    local stringRep = message:toString()
    return stringRep:match('^ChatMessage{chat=(%a*),')
end

local function GenerateRadiosPacketFromListeningRadiosInRange(frequency)
    if TicsServerSettings == nil then
        return nil
    end
    local maxSoundRange = TicsServerSettings['options']['radio']['soundMaxRange']
    local radios = FakeRadioPacket.getListeningRadiosPositions(getPlayer(), maxSoundRange, frequency)
    if radios == nil then
        return nil
    end
    return {
        [frequency] = radios
    }
end

local function RemoveDiscordMessagePrefix(message)
    local regex = '<@%d*>(.*)'
    return message:match(regex)
end

-- TODO: try to clean this mess copied from the base game
ISChat.addLineInChat = function(message, tabID)
    if UdderlyUpToDate and
        message.setOverHeadSpeech == nil and
        message.isFromDiscord == nil and
        message.getDatetimeStr == nil
    then -- probably a fake message from UdderlyUpToDate mod
        ISChat.sendErrorToCurrentTab(message:getText())
        return
    end
    local line = message:getText()
    local messageType = GetMessageType(message)
    if message:getAuthor() == 'Server' then
        ISChat.sendInfoToCurrentTab(line)
    elseif message:getRadioChannel() ~= -1 then -- scripted radio message
        local messageWithoutColorPrefix = message:getText():gsub('*%d+,%d+,%d+*', '')
        message:setText(messageWithoutColorPrefix)
        local color = (TicsServerSettings and TicsServerSettings['scriptedRadio']['color']) or {
            171, 240, 140,
        }
        ISChat.onRadioPacket(
            'scriptedRadio',
            nil,
            nil,
            messageWithoutColorPrefix,
            color,
            {}, -- todo find a way to locate the radio
            message:getRadioChannel(),
            false
        )
    else
        message:setOverHeadSpeech(false)
    end

    if messageType == 'Local' then -- when pressing Q to shout
        ISChat.onMessagePacket(
            'yell',
            message:getAuthor(),
            message:getAuthor(),
            line,
            { 255, 255, 255 },
            TicsServerSettings and TicsServerSettings['options'] and
            TicsServerSettings['options']['hideCallout'] or nil,
            nil,
            false,
            ISChat.instance.ticsModData['voicePitch'],
            false
        )
    end

    if message:isFromDiscord() then
        local currentDiscordMessage = message:getDatetimeStr() .. message:getText()
        local currentTime = Calendar.getInstance():getTimeInMillis()
        local isDuplicate = false
        local toRemove = {}
        for key, discordMessageInfo in pairs(ISChat.instance.lastDiscordMessages) do
            local discordMessage = discordMessageInfo['message']
            local discordMessageTime = discordMessageInfo['time']
            if currentTime - discordMessageTime < 2000 then
                if discordMessage == currentDiscordMessage then
                    isDuplicate = true
                end
            else
                table.insert(toRemove, key)
            end
        end
        for _, key in pairs(toRemove) do
            ISChat.instance.lastDiscordMessages[key] = nil
        end
        if isDuplicate then
            return
        end
        table.insert(ISChat.instance.lastDiscordMessages, {
            message = currentDiscordMessage,
            time = currentTime
        })
        local discordColor = { 88, 101, 242 } -- discord logo color
        local messageWithoutPrefix = RemoveDiscordMessagePrefix(line)
        if messageWithoutPrefix == nil then
            print('TICS error: failed to remove discord message prefix for message: "' .. line .. '"')
            return
        end
        if TicsServerSettings and TicsServerSettings['general']
            and TicsServerSettings['general']['discord']
            and TicsServerSettings['general']['enabled']
        then
            ISChat.onMessagePacket(
                'general',
                message:getAuthor(),
                message:getAuthor(),
                messageWithoutPrefix,
                discordColor,
                false,
                nil,
                true,
                1.15, -- voice pitch, should not be used anyway
                false
            )
        end
        if TicsServerSettings and TicsServerSettings['options']
            and TicsServerSettings['options']['radio']
            and TicsServerSettings['options']['radio']['discord']
        then
            local frequency = TicsServerSettings['options']['radio']['frequency']
            if frequency then
                local radiosInfo = GenerateRadiosPacketFromListeningRadiosInRange(frequency)
                if radiosInfo ~= nil then
                    ISChat.onRadioPacket(
                        'say',
                        message:getAuthor(),
                        message:getAuthor(),
                        messageWithoutPrefix,
                        discordColor,
                        radiosInfo,
                        1.15,
                        false
                    )
                end
            end
        end
        return
    elseif message:isServerAlert() then
        ISChat.instance.servermsg = ''
        if message:isShowAuthor() then
            ISChat.instance.servermsg = message:getAuthor() .. ': '
        end
        ISChat.instance.servermsg = ISChat.instance.servermsg .. message:getText()
        ISChat.instance.servermsgTimer = 5000
        ISChat.instance.onServerMessage(line)
        return
    else
        return
    end
end

function ISChat:render()
    ChatUI.render(self)
end

function ISChat:prerender()
    local instance = ISChat.instance

    instance:createValidationWindowButton()

    if instance.rangeIndicator ~= nil then
        if instance.rangeButtonState == 'visible' then
            if ISChat.instance.focused then
                instance.rangeIndicator:subscribe()
            else
                instance.rangeIndicator:unsubscribe()
            end
        elseif instance.rangeButtonState == 'hidden' then
            instance.rangeIndicator:unsubscribe()
        else
            instance.rangeIndicator:subscribe()
        end
    end

    local allBubbles = {
        instance.radioBubble,
        instance.vehicleRadioBubble,
        instance.playerRadioBubble,
        instance.bubble,
        instance.typingDots
    }
    for _, bubbles in pairs(allBubbles) do
        local indexToDelete = {}
        for index, bubble in pairs(bubbles) do
            if bubble.dead then
                table.insert(indexToDelete, index)
            else
                bubble:render()
            end
        end
        for _, index in pairs(indexToDelete) do
            bubbles[index] = nil
        end
    end
    ChatUI.prerender(self)
end

function IsOnlyCommand(text)
    return text:match('/%a* *') == text
end

function ISChat.onTextChange()
    local t = ISChat.instance.textEntry
    local internalText = t:getInternalText()
    if #internalText > 1
        and IsOnlyCommand(internalText:sub(1, #internalText - 1))
        and internalText:sub(#internalText) == '/'
    then
        t:setText("/")
        if ISChat.instance.rangeIndicator then
            ISChat.instance.rangeIndicator:unsubscribe()
        end
        ISChat.instance.rangeIndicator = nil
        ISChat.instance.lastStream = nil
        return
    end

    if internalText == '/r' and ISChat.instance.lastPrivateMessageAuthor ~= nil
        and ISChat.instance.currentTabID == 3
    then
        t:setText('/pm ' .. ISChat.instance.lastPrivateMessageAuthor .. ' ')
        return
    end
    local stream = GetCommandFromMessage(internalText)
    if stream ~= nil then
        if ISChat.instance.lastStream ~= stream then
            UpdateRangeIndicator(stream)
        end
        -- you are allowed to use a command from another tab but it wont be remembered for the next message
        -- /me* commands are also not remembered as they should be occasional
        if ISChat.instance.currentTabID == stream['tabID'] and not stream['forget'] then
            ISChat.lastTabStream[ISChat.instance.currentTabID] = stream
        end
        ClientSend.sendTyping(getPlayer():getUsername(), stream['name'])
    else
        if ISChat.instance.rangeIndicator then
            ISChat.instance.rangeIndicator:unsubscribe()
        end
        ISChat.instance.rangeIndicator = nil
    end
    ISChat.instance.lastStream = stream
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

local function RenderChatText(chat)
    chat:setStencilRect(0, 0, chat.width, chat.height)
    ChatText.render(chat)
    chat:clearStencilRect()
end

function ISChat:createTab()
    local chatY = self:titleBarHeight() + self.btnHeight + 2 * self.inset
    local chatHeight = self.textEntry:getY() - chatY
    local chatText = ChatText:new(0, chatY, self:getWidth(), chatHeight)
    chatText.maxLines = 100
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
    chatText.render = RenderChatText
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

ISChat.onTabAdded = function(tabTitle, tabID)
    -- callback from the Java
    -- 0 is General
    -- 1 is Admin
    if tabID == 1 then
        if TicsServerSettings ~= nil and TicsServerSettings['admin']['enabled']
            and ISChat.instance.tabs[4] == nil then
            AddTab('Admin', 4)
        end
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

local function UpdateInfoWindow()
    local info = getText('SurvivalGuide_TICS', TICS_VERSION)
    info = info .. getText('SurvivalGuide_TICS_Markdown')
    if TicsServerSettings['whisper']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Whisper')
    end
    if TicsServerSettings['whisper']['enabled'] and TicsServerSettings['options']['verb'] then
        info = info .. getText('SurvivalGuide_TICS_MeWhisper')
    end
    if TicsServerSettings['low']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Low')
    end
    if TicsServerSettings['low']['enabled'] and TicsServerSettings['options']['verb'] then
        info = info .. getText('SurvivalGuide_TICS_MeLow')
    end
    if TicsServerSettings['say']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Say')
    end
    if TicsServerSettings['say']['enabled'] and TicsServerSettings['options']['verb'] then
        info = info .. getText('SurvivalGuide_TICS_MeSay')
    end
    if TicsServerSettings['yell']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Yell')
    end
    if TicsServerSettings['yell']['enabled'] and TicsServerSettings['options']['verb'] then
        info = info .. getText('SurvivalGuide_TICS_MeYell')
    end
    if TicsServerSettings['pm']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Pm')
    end
    if TicsServerSettings['faction']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Faction')
    end
    if TicsServerSettings['safehouse']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_SafeHouse')
    end
    if TicsServerSettings['general']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_General')
    end
    if TicsServerSettings['admin']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Admin')
    end
    if TicsServerSettings['ooc']['enabled'] then
        info = info .. getText('SurvivalGuide_TICS_Ooc')
    end
    info = info .. getText('SurvivalGuide_TICS_Color')
    info = info .. getText('SurvivalGuide_TICS_Pitch')
    info = info .. getText('SurvivalGuide_TICS_Roll')
    ISChat.instance:setInfo(info)
end

local function HasAtLeastOneChanelEnabled(tabId)
    if TicsServerSettings == nil then
        return false
    end
    for _, stream in pairs(ISChat.allChatStreams) do
        local name = stream['name']
        if stream['tabID'] == tabId and TicsServerSettings[name] and TicsServerSettings[name]['enabled'] then
            return true
        end
    end
    return false
end

local function RemoveTab(tabTitle, tabID)
    local foundTab
    if ISChat.instance.tabs[tabID] ~= nil then
        foundTab = ISChat.instance.tabs[tabID]
        ISChat.instance.tabs[tabID] = nil
    else
        return
    end
    if ISChat.instance.tabCnt > 1 then
        for i, blinkedTab in ipairs(ISChat.instance.panel.blinkTabs) do
            if tabTitle == blinkedTab then
                table.remove(ISChat.instance.panel.blinkTabs, i)
                break
            end
        end
        ISChat.instance.panel:removeView(foundTab)
        ISChat.instance.minimumWidth = ISChat.instance.panel:getWidthOfAllTabs() + 2 * ISChat.instance.inset
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
    ISChat.instance:onActivateView()
end

ISChat.onRecvSandboxVars = function(messageTypeSettings)
    if TicsServerSettings == nil then
        Events.OnPostRender.Remove(AskServerData)
    end

    local knownAvatars = AvatarManager:getKnownAvatars()
    ClientSend.sendKnownAvatars(knownAvatars)

    TicsServerSettings = messageTypeSettings -- a global

    if HasAtLeastOneChanelEnabled(2) == true then
        AddTab('Out Of Character', 2)
    elseif ISChat.instance.tabs[2] ~= nil then
        RemoveTab('Out Of Character', 2)
    end
    if HasAtLeastOneChanelEnabled(3) == true then
        AddTab('Private Message', 3)
    elseif ISChat.instance.tabs[3] ~= nil then
        RemoveTab('Private Message', 3)
    end
    if getPlayer():getAccessLevel() == 'Admin' and messageTypeSettings['admin']['enabled'] then
        AddTab('Admin', 4)
    elseif ISChat.instance.tabs[4] ~= nil then
        RemoveTab('Admin', 4)
    end
    if ISChat.instance.tabCnt > 1 and not HasAtLeastOneChanelEnabled(1) then
        RemoveTab('General', 1)
    else
        UpdateTabStreams(ISChat.instance.tabs[1], 1)
    end

    UpdateRangeIndicator(ISChat.defaultTabStream[ISChat.instance.currentTabID])
    UpdateInfoWindow()
    if ISChat.instance.ticsModData == nil or ISChat.instance.ticsModData['isVoiceEnabled'] == nil then
        ISChat.instance.isVoiceEnabled = messageTypeSettings['options']['isVoiceEnabled']
    end
    local radioMaxRange = TicsServerSettings['options']['radio']['soundMaxRange']
    if ISChat.instance.radioRangeIndicator then
        ISChat.instance.radioRangeIndicator:unsubscribe()
    end
    ISChat.instance.radioRangeIndicator = RadioRangeIndicator:new(25, radioMaxRange, ISChat.instance.isRadioIconEnabled)
    if ISChat.instance.radioButtonState == true then
        ISChat.instance.radioRangeIndicator:subscribe()
    end
    ISChat.instance.online = true
end

ISChat.onTabRemoved = function(tabTitle, tabID)
    if tabID ~= 1 then -- Admin tab is 1 in the Java code
        return
    end
    RemoveTab('Admin', 4) -- Admin tab is 4 in our table
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
    if ISChat.instance == nil then return end
    if key == getCore():getKey("Toggle chat") or key == getCore():getKey("Alt toggle chat") then
        ISChat.instance:focus()
    end
    local chat = ISChat.instance
    if key == getCore():getKey("Switch chat stream") then
        local nextTabId = GetNextTabId(chat.currentTabID)
        if nextTabId == nil then
            print('TICS error: onToggleChatBox: next tab ID not found')
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
            ISTabPanel.xMouse = target:getMouseX()
            ISTabPanel.yMouse = target:getMouseY()
            target.draggingTab = tabIndex - 1
            local clickedTab = target.viewList[target.draggingTab + 1]
            target:activateView(clickedTab.name)
        end
    end
    return false
end

local function OnRangeButtonClick()
    if TicsServerSettings == nil then
        return
    end
    if ISChat.instance.rangeButtonState == 'visible' then
        ISChat.instance.rangeButtonState = 'always-visible'
        ISChat.instance.rangeButton:setImage(getTexture("media/ui/tics/icons/eye-on-plus.png"))
    elseif ISChat.instance.rangeButtonState == 'always-visible' then
        ISChat.instance.rangeButtonState = 'hidden'
        ISChat.instance.rangeButton:setImage(getTexture("media/ui/tics/icons/eye-off.png"))
    else
        ISChat.instance.rangeButtonState = 'visible'
        ISChat.instance.rangeButton:setImage(getTexture("media/ui/tics/icons/eye-on.png"))
    end
    UpdateRangeIndicator(ISChat.lastTabStream[ISChat.instance.currentTabID])
end

local function OnRadioButtonClick()
    if TicsServerSettings == nil or ISChat.instance.radioRangeIndicator == nil then
        return
    end
    ISChat.instance.radioButtonState = not ISChat.instance.radioButtonState
    if ISChat.instance.radioButtonState == true then
        ISChat.instance.radioRangeIndicator:subscribe()
        ISChat.instance.radioButton:setImage(getTexture("media/ui/tics/icons/mic-on.png"))
    else
        ISChat.instance.radioRangeIndicator:unsubscribe()
        ISChat.instance.radioButton:setImage(getTexture("media/ui/tics/icons/mic-off.png"))
    end
end

local function OnAvatarUploadButtonClick()
    if ISChat.instance.avatarUploadWindow then
        ISChat.instance.avatarUploadWindow:unsubscribe()
    end
    ISChat.instance.avatarUploadWindow = AvatarUploadWindow:new()
    ISChat.instance.avatarUploadWindow:subscribe()
end

local function OnAvatarValidationWindowButtonClick()
    if ISChat.instance.avatarValidationWindow then
        ISChat.instance.avatarValidationWindow:unsubscribe()
    end
    ISChat.instance.avatarValidationWindow = AvatarValidationWindow:new()
    ISChat.instance.avatarValidationWindow:subscribe()
end

-- redefining ISTabPanel:activateView to remove the update of the info button
local function PanelActivateView(panel, viewName)
    local self = panel
    for ind, value in ipairs(self.viewList) do
        -- we get the view we want to display
        if value.name == viewName then
            self.activeView.view:setVisible(false)
            value.view:setVisible(true)
            self.activeView = value
            self:ensureVisible(ind)

            if self.onActivateView and self.target then
                self.onActivateView(self.target, self)
            end

            return true
        end
    end
    return false
end

function ISChat:createValidationWindowButton()
    if TicsServerSettings == nil or TicsServerSettings['options']['portrait'] ~= 2 then
        if self.avatarUploadButton then
            self:removeChild(self.avatarUploadButton)
            self.avatarUploadButton = nil
        end
        if self.avatarValidationWindowButton then
            self:removeChild(self.avatarValidationWindowButton)
            self.avatarValidationWindowButton = nil
        end
        return
    end

    local th = self:titleBarHeight()
    if self.avatarUploadButton == nil then
        --avatar upload button
        ISChat.avatarUploadButtonName = "avatar upload"
        self.avatarUploadButton = ISButton:new(self.radioButton:getX() - th / 2 - th, 1, th, th, "", self,
            OnAvatarUploadButtonClick)
        self.avatarUploadButton.anchorRight = true
        self.avatarUploadButton.anchorLeft = false
        self.avatarUploadButton:initialise()
        self.avatarUploadButton.borderColor.a = 0.0
        self.avatarUploadButton.backgroundColor.a = 0
        self.avatarUploadButton.backgroundColorMouseOver.a = 0.5
        self.avatarUploadButton:setImage(getTexture("media/ui/tics/icons/upload.png"))
        self.avatarUploadButton:setUIName(ISChat.avatarUploadButtonName)
        self:addChild(self.avatarUploadButton)
        self.avatarUploadButton:setVisible(true)
    end

    if self.avatarValidationWindowButton == nil then
        local accessLevel = getPlayer():getAccessLevel()
        if accessLevel == 'Admin' or accessLevel == 'Moderator' then
            ISChat.avatarValidationWindowButtonName = 'avatar validation window button'
            self.avatarValidationWindowButton = ISButton:new(self.avatarUploadButton:getX() - th / 2 - th, 1, th, th,
                '', self, OnAvatarValidationWindowButtonClick)
            self.avatarValidationWindowButton.anchorRight = true
            self.avatarValidationWindowButton.anchorLeft = false
            self.avatarValidationWindowButton:initialise()
            self.avatarValidationWindowButton.borderColor.a = 0.0
            self.avatarValidationWindowButton.backgroundColor.a = 0
            self.avatarValidationWindowButton.backgroundColorMouseOver.a = 0.5
            self.avatarValidationWindowButton:setImage(getTexture('media/ui/tics/icons/portrait.png'))
            self.avatarValidationWindowButton:setUIName(ISChat.avatarValidationWindowButtonName)
            self:addChild(self.avatarValidationWindowButton)
            self.avatarValidationWindowButton:setVisible(true)
        end
    end
end

function ISChat:createChildren()
    --window stuff
    -- Do corner x + y widget
    local rh = self:resizeWidgetHeight()
    local resizeWidget = ISResizeWidget:new(self.width - rh, self.height - rh, rh, rh, self)
    resizeWidget:initialise()
    resizeWidget.onMouseDown = ISChat.onMouseDown
    resizeWidget.onMouseUp = ISChat.onMouseUp
    resizeWidget:setVisible(self.resizable)
    resizeWidget:bringToTop()
    resizeWidget:setUIName(ISChat.xyResizeWidgetName)
    self:addChild(resizeWidget)
    self.resizeWidget = resizeWidget

    -- Do bottom y widget
    local resizeWidget2 = ISResizeWidget:new(0, self.height - rh, self.width - rh, rh, self, true)
    resizeWidget2.anchorLeft = true
    resizeWidget2.anchorRight = true
    resizeWidget2:initialise()
    resizeWidget2.onMouseDown = ISChat.onMouseDown
    resizeWidget2.onMouseUp = ISChat.onMouseUp
    resizeWidget2:setVisible(self.resizable)
    resizeWidget2:setUIName(ISChat.yResizeWidgetName)
    self:addChild(resizeWidget2)
    self.resizeWidget2 = resizeWidget2

    -- close button
    local th = self:titleBarHeight()
    self.closeButton = ISButton:new(3, 0, th, th, "", self, self.close)
    self.closeButton:initialise()
    self.closeButton.borderColor.a = 0.0
    self.closeButton.backgroundColor.a = 0
    self.closeButton.backgroundColorMouseOver.a = 0.5
    self.closeButton:setImage(self.closeButtonTexture)
    self.closeButton:setUIName(ISChat.closeButtonName)
    self:addChild(self.closeButton)

    -- lock button
    self.lockButton = ISButton:new(self.width - 19, 0, th, th, "", self, ISChat.pin)
    self.lockButton.anchorRight = true
    self.lockButton.anchorLeft = false
    self.lockButton:initialise()
    self.lockButton.borderColor.a = 0.0
    self.lockButton.backgroundColor.a = 0
    self.lockButton.backgroundColorMouseOver.a = 0.5
    if self.locked then
        self.lockButton:setImage(self.chatLockedButtonTexture)
    else
        self.lockButton:setImage(self.chatUnLockedButtonTexture)
    end
    self.lockButton:setUIName(ISChat.lockButtonName)
    self:addChild(self.lockButton)
    self.lockButton:setVisible(true)

    --gear button
    self.gearButton = ISButton:new(self.lockButton:getX() - th / 2 - th, 1, th, th, "", self, ISChat.onGearButtonClick)
    self.gearButton.anchorRight = true
    self.gearButton.anchorLeft = false
    self.gearButton:initialise()
    self.gearButton.borderColor.a = 0.0
    self.gearButton.backgroundColor.a = 0
    self.gearButton.backgroundColorMouseOver.a = 0.5
    self.gearButton:setImage(getTexture("media/ui/Panel_Icon_Gear.png"))
    self.gearButton:setUIName(ISChat.gearButtonName)
    self:addChild(self.gearButton)
    self.gearButton:setVisible(true)

    --info button
    ISChat.infoButtonName = "chat info button"
    self.infoButton = ISButton:new(self.gearButton:getX() - th / 2 - th, 1, th, th, "", self, ISCollapsableWindow.onInfo)
    self.infoButton.anchorRight = true
    self.infoButton.anchorLeft = false
    self.infoButton:initialise()
    self.infoButton.borderColor.a = 0.0
    self.infoButton.backgroundColor.a = 0
    self.infoButton.backgroundColorMouseOver.a = 0.5
    self.infoButton:setImage(getTexture("media/ui/Panel_info_button.png"))
    self.infoButton:setUIName(ISChat.infoButtonName)
    self:addChild(self.infoButton)
    self.infoButton:setVisible(true)
    local info = getText('SurvivalGuide_TICS', TICS_VERSION)
    info = info .. getText('SurvivalGuide_TICS_Color')
    self:setInfo(info)


    --range button
    ISChat.rangeButtonName = "chat range button"
    self.rangeButton = ISButton:new(self.infoButton:getX() - th / 2 - th, 1, th, th, "", self, OnRangeButtonClick)
    self.rangeButton.anchorRight = true
    self.rangeButton.anchorLeft = false
    self.rangeButton:initialise()
    self.rangeButton.borderColor.a = 0.0
    self.rangeButton.backgroundColor.a = 0
    self.rangeButton.backgroundColorMouseOver.a = 0.5
    self.rangeButton:setImage(getTexture("media/ui/tics/icons/eye-off.png"))
    self.rangeButton:setUIName(ISChat.rangeButtonName)
    self:addChild(self.rangeButton)
    self.rangeButton:setVisible(true)

    --radio button
    ISChat.radioButtonName = "radio button"
    self.radioButton = ISButton:new(self.rangeButton:getX() - th / 2 - th, 1, th, th, "", self, OnRadioButtonClick)
    self.radioButton.anchorRight = true
    self.radioButton.anchorLeft = false
    self.radioButton:initialise()
    self.radioButton.borderColor.a = 0.0
    self.radioButton.backgroundColor.a = 0
    self.radioButton.backgroundColorMouseOver.a = 0.5
    self.radioButton:setImage(getTexture("media/ui/tics/icons/mic-off.png"))
    self.radioButton:setUIName(ISChat.radioButtonName)
    self:addChild(self.radioButton)
    self.radioButton:setVisible(true)

    --avatar validation window button
    self:createValidationWindowButton()

    --general stuff
    self.minimumHeight = 90
    self.minimumWidth = 200
    self:setResizable(true)
    self:setDrawFrame(true)
    self:addToUIManager()

    self.tabs = {}
    self.tabCnt = 0
    self.btnHeight = 25
    self.currentTabID = 0
    self.inset = 2
    self.fontHgt = getTextManager():getFontFromEnum(UIFont.Medium):getLineHeight()

    --text entry stuff
    local inset, EdgeSize, fontHgt = self.inset, 5, self.fontHgt

    -- EdgeSize must match UITextBox2.EdgeSize
    local height = EdgeSize * 2 + fontHgt
    self.textEntry = ISTextEntryBox:new("", inset, self:getHeight() - 8 - inset - height, self:getWidth() - inset * 2,
        height)
    self.textEntry.font = UIFont.Medium
    self.textEntry:initialise()
    -- self.textEntry:instantiate()
    ChatUI.textEntry.instantiate(self.textEntry)
    self.textEntry.backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 }
    self.textEntry.borderColor = { r = 1, g = 1, b = 1, a = 0.0 }
    self.textEntry:setHasFrame(true)
    self.textEntry:setAnchorTop(false)
    self.textEntry:setAnchorBottom(true)
    self.textEntry:setAnchorRight(true)
    self.textEntry.onCommandEntered = ISChat.onCommandEntered
    self.textEntry.onTextChange = ISChat.onTextChange
    self.textEntry.onPressDown = ISChat.onPressDown
    self.textEntry.onPressUp = ISChat.onPressUp
    self.textEntry.onOtherKey = ISChat.onOtherKey
    self.textEntry.onClick = ISChat.onMouseDown
    self.textEntry:setUIName(ISChat.textEntryName) -- need to be right this. If it will empty or another then focus will lost on click in chat
    self.textEntry:setHasFrame(true)
    self:addChild(self.textEntry)
    self.textEntry.prerender = ChatUI.textEntry.prerender
    ISChat.maxTextEntryOpaque = self.textEntry:getFrameAlpha()

    --tab panel stuff
    local panelHeight = self.textEntry:getY() - self:titleBarHeight() - self.inset
    self.panel = ISTabPanel:new(0, self:titleBarHeight(), self.width - inset, panelHeight)
    self.panel:initialise()
    self.panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.panel.onActivateView = ISChat.onActivateView
    self.panel.target = self
    self.panel:setAnchorTop(true)
    self.panel:setAnchorLeft(true)
    self.panel:setAnchorRight(true)
    self.panel:setAnchorBottom(true)
    self.panel:setEqualTabWidth(false)
    self.panel:setVisible(false)
    self.panel.onRightMouseUp = ISChat.onRightMouseUp
    self.panel.onRightMouseDown = ISChat.onRightMouseDown
    self.panel.onMouseUp = ISChat.onMouseUp
    self.panel.onMouseDown = ISChat.ISTabPanelOnMouseDown
    self.panel:setUIName(ISChat.tabPanelName)
    self:addChild(self.panel)
    self.panel.activateView = PanelActivateView
    self.panel.render = ChatUI.tabPanel.render
    self.panel.prerender = ChatUI.tabPanel.prerender

    self:bringToTop()
    self.textEntry:bringToTop()
    self.minimumWidth = self.panel:getWidthOfAllTabs() + 2 * inset
    self.minimumHeight = self.textEntry:getHeight() + self:titleBarHeight() + 2 * inset + self.panel.tabHeight +
        fontHgt * 4
    self:unfocus()

    self.mutedUsers = {}
end

function ISChat:focus()
    self:setVisible(true)
    ISChat.focused = true
    self.textEntry:setEditable(true)
    self.textEntry:focus()
    self.textEntry:ignoreFirstInput()
    local stream = ISChat.lastTabStream[ISChat.instance.currentTabID]
    self.textEntry:setText(stream['command'])
    UpdateRangeIndicator(stream)
    self.fade:reset()
    self.fade:update() --reset fraction to start value
end

function ISChat:unfocus()
    self.textEntry:unfocus()
    self.textEntry:setText("")
    if ISChat.focused then
        self.fade:reset() -- to begin fade. unfocus called when element was unfocused also.
    end
    ISChat.focused = false
    self.textEntry:setEditable(false)
end

function ISChat:onGearButtonClick()
    local context = ISContextMenu.get(0, self:getAbsoluteX() + self:getWidth() / 2,
        self:getAbsoluteY() + self.gearButton:getY())
    if context == nil then
        print('TICS error: ISChat:onGearButtonClick: gear button context is null')
        return
    end

    local timestampOptionName = getText("UI_chat_context_enable_timestamp")
    if self.showTimestamp then
        timestampOptionName = getText("UI_chat_context_disable_timestamp")
    end
    context:addOption(timestampOptionName, ISChat.instance, ISChat.onToggleTimestampPrefix)

    local tagOptionName = getText("UI_chat_context_enable_tags")
    if self.showTitle then
        tagOptionName = getText("UI_chat_context_disable_tags")
    end
    context:addOption(tagOptionName, ISChat.instance, ISChat.onToggleTagPrefix)

    local fontSizeOption = context:addOption(getText("UI_chat_context_font_submenu_name"), ISChat.instance)
    local fontSubMenu = context:getNew(context)
    context:addSubMenu(fontSizeOption, fontSubMenu)
    fontSubMenu:addOption(getText("UI_chat_context_font_small"), ISChat.instance, ISChat.onFontSizeChange, "small")
    fontSubMenu:addOption(getText("UI_chat_context_font_medium"), ISChat.instance, ISChat.onFontSizeChange, "medium")
    fontSubMenu:addOption(getText("UI_chat_context_font_large"), ISChat.instance, ISChat.onFontSizeChange, "large")
    if self.chatFont == "small" then
        fontSubMenu:setOptionChecked(fontSubMenu.options[1], true)
    elseif self.chatFont == "medium" then
        fontSubMenu:setOptionChecked(fontSubMenu.options[2], true)
    elseif self.chatFont == "large" then
        fontSubMenu:setOptionChecked(fontSubMenu.options[3], true)
    end

    local minOpaqueOption = context:addOption(getText("UI_chat_context_opaque_min"), ISChat.instance)
    local minOpaqueSubMenu = context:getNew(context)
    context:addSubMenu(minOpaqueOption, minOpaqueSubMenu)
    local opaques = { 0, 0.25, 0.5, 0.6, 0.75, 1 }
    for i = 1, #opaques do
        if logTo01(opaques[i]) <= self.maxOpaque then
            local option = minOpaqueSubMenu:addOption((opaques[i] * 100) .. "%", ISChat.instance,
                ISChat.onMinOpaqueChange, opaques[i])
            local current = math.floor(self.minOpaque * 1000)
            local value = math.floor(logTo01(opaques[i]) * 1000)
            if current == value then
                minOpaqueSubMenu:setOptionChecked(option, true)
            end
        end
    end

    local maxOpaqueOption = context:addOption(getText("UI_chat_context_opaque_max"), ISChat.instance)
    local maxOpaqueSubMenu = context:getNew(context)
    context:addSubMenu(maxOpaqueOption, maxOpaqueSubMenu)
    for i = 1, #opaques do
        if logTo01(opaques[i]) >= self.minOpaque then
            local option = maxOpaqueSubMenu:addOption((opaques[i] * 100) .. "%", ISChat.instance,
                ISChat.onMaxOpaqueChange, opaques[i])
            local current = math.floor(self.maxOpaque * 1000)
            local value = math.floor(logTo01(opaques[i]) * 1000)
            if current == value then
                maxOpaqueSubMenu:setOptionChecked(option, true)
            end
        end
    end

    local fadeTimeOption = context:addOption(getText("UI_chat_context_opaque_fade_time_submenu_name"), ISChat.instance)
    local fadeTimeSubMenu = context:getNew(context)
    context:addSubMenu(fadeTimeOption, fadeTimeSubMenu)
    local availFadeTime = { 0, 1, 2, 3, 5, 10 }
    local option = fadeTimeSubMenu:addOption(getText("UI_chat_context_disable"), ISChat.instance, ISChat
        .onFadeTimeChange, 0)
    if 0 == self.fadeTime then
        fadeTimeSubMenu:setOptionChecked(option, true)
    end
    for i = 2, #availFadeTime do
        local time = availFadeTime[i]
        option = fadeTimeSubMenu:addOption(time .. " s", ISChat.instance, ISChat.onFadeTimeChange, time)
        if time == self.fadeTime then
            fadeTimeSubMenu:setOptionChecked(option, true)
        end
    end

    local opaqueOnFocusOption = context:addOption(getText("UI_chat_context_opaque_on_focus"), ISChat.instance)
    local opaqueOnFocusSubMenu = context:getNew(context)
    context:addSubMenu(opaqueOnFocusOption, opaqueOnFocusSubMenu)
    opaqueOnFocusSubMenu:addOption(getText("UI_chat_context_disable"), ISChat.instance, ISChat.onFocusOpaqueChange, false)
    opaqueOnFocusSubMenu:addOption(getText("UI_chat_context_enable"), ISChat.instance, ISChat.onFocusOpaqueChange, true)
    opaqueOnFocusSubMenu:setOptionChecked(opaqueOnFocusSubMenu.options[self.opaqueOnFocus and 2 or 1], true)

    local voiceOptionName = getText("UI_TICS_chat_enable_voices")
    if self.isVoiceEnabled then
        voiceOptionName = getText("UI_TICS_chat_disable_voices")
    end
    context:addOption(voiceOptionName, ISChat.instance, ISChat.onToggleVoice)

    local radioIconOptionName = getText("UI_TICS_enable_radio_icon")
    if self.isRadioIconEnabled then
        radioIconOptionName = getText("UI_TICS_disable_radio_icon")
    end
    context:addOption(radioIconOptionName, ISChat.instance, ISChat.onToggleRadioIcon)

    if TicsServerSettings and TicsServerSettings['options']['portrait'] ~= 1 then
        local portraitOptionName = getText("UI_TICS_enable_portrait")
        if self.isPortraitEnabled then
            portraitOptionName = getText("UI_TICS_disable_portrait")
        end
        context:addOption(portraitOptionName, ISChat.instance, ISChat.onTogglePortrait)
    end
end

function ISChat.onToggleVoice()
    ISChat.instance.isVoiceEnabled = not ISChat.instance.isVoiceEnabled

    -- the player has set this option at least once, that means he is aware of its existence
    -- we'll use this settings in the future instead of the server default behavior
    ISChat.instance.ticsModData['isVoiceEnabled'] = ISChat.instance.isVoiceEnabled
    ModData.add('tics', ISChat.instance.ticsModData)
end

function ISChat.onToggleRadioIcon()
    ISChat.instance.isRadioIconEnabled = not ISChat.instance.isRadioIconEnabled
    ISChat.instance.ticsModData['isRadioIconEnabled'] = ISChat.instance.isRadioIconEnabled
    ModData.add('tics', ISChat.instance.ticsModData)
    if ISChat.instance.radioRangeIndicator then
        ISChat.instance.radioRangeIndicator.showIcon = ISChat.instance.isRadioIconEnabled
    end
end

function ISChat.onTogglePortrait()
    ISChat.instance.isPortraitEnabled = not ISChat.instance.isPortraitEnabled
    ISChat.instance.ticsModData['isPortraitEnabled'] = ISChat.instance.isRadioIconEnabled
    ModData.add('tics', ISChat.instance.ticsModData)
end

Events.OnChatWindowInit.Add(ISChat.initChat)
