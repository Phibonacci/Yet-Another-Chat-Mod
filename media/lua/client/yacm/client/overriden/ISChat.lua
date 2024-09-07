local YET_ANOTHER_CHAT_MOD_VERSION = require('yacm/shared/Version')

local ChatUI = require('yacm/client/ui/ChatUI')


local Parser                 = require('yacm/client/parser/Parser')
local PlayerBubble           = require('yacm/client/ui/bubble/PlayerBubble')
local RadioBubble            = require('yacm/client/ui/bubble/RadioBubble')
local RangeIndicator         = require('yacm/client/ui/RangeIndicator')
local StringFormat           = require('yacm/shared/utils/StringFormat')
local StringParser           = require('yacm/shared/utils/StringParser')
local TypingDots             = require('yacm/client/ui/TypingDots')
local World                  = require('yacm/shared/utils/World')
local StringBuilder          = require('yacm/client/parser/StringBuilder')
local YacmClientSendCommands = require('yacm/client/network/SendYacmClient')


ISChat.allChatStreams     = {}
ISChat.allChatStreams[1]  = { name = 'say', command = '/say ', shortCommand = '/s ', tabID = 1 }
ISChat.allChatStreams[2]  = { name = 'whisper', command = '/whisper ', shortCommand = '/w ', tabID = 1 }
ISChat.allChatStreams[3]  = { name = 'low', command = '/low ', shortCommand = '/l ', tabID = 1 }
ISChat.allChatStreams[4]  = { name = 'yell', command = '/yell ', shortCommand = '/y ', tabID = 1 }
ISChat.allChatStreams[5]  = { name = 'faction', command = '/faction ', shortCommand = '/f ', tabID = 1 }
ISChat.allChatStreams[6]  = { name = 'safehouse', command = '/safehouse ', shortCommand = '/sh ', tabID = 1 }
ISChat.allChatStreams[7]  = { name = 'general', command = '/all ', shortCommand = '/g', tabID = 1 }
ISChat.allChatStreams[8]  = { name = 'scriptedRadio', command = nil, shortCommand = nil, tabID = 1 }
ISChat.allChatStreams[9]  = { name = 'ooc', command = '/ooc ', shortCommand = '/o ', tabID = 2 }
ISChat.allChatStreams[10] = { name = 'pm', command = '/pm ', shortCommand = '/p ', tabID = 3 }
ISChat.allChatStreams[11] = { name = 'admin', command = '/admin ', shortCommand = '/a ', tabID = 4 }


ISChat.yacmCommand    = {}
ISChat.yacmCommand[1] = { name = 'color', command = '/color', shortCommand = nil }
ISChat.yacmCommand[2] = { name = 'pitch', command = '/pitch', shortCommand = nil }


ISChat.defaultTabStream    = {}
ISChat.defaultTabStream[1] = ISChat.allChatStreams[1]
ISChat.defaultTabStream[2] = ISChat.allChatStreams[8]
ISChat.defaultTabStream[3] = ISChat.allChatStreams[9]
ISChat.defaultTabStream[4] = ISChat.allChatStreams[10]


local function IsOnlySpacesOrEmpty(command)
    local commandWithoutSpaces = command:gsub('%s+', '')
    return #commandWithoutSpaces == 0
end

local function GetCommandFromMessage(command)
    if not luautils.stringStarts(command, '/') then
        local defaultStream = ISChat.defaultTabStream[ISChat.instance.currentTabID]
        return defaultStream, ''
    end
    if IsOnlySpacesOrEmpty(command) then
        return nil
    end
    for _, stream in ipairs(ISChat.allChatStreams) do
        if stream.command and luautils.stringStarts(command, stream.command) then
            return stream, stream.command
        elseif stream.shortCommand and luautils.stringStarts(command, stream.shortCommand) then
            return stream, stream.shortCommand
        end
    end
    return nil
end

local function GetYacmCommandFromMessage(command)
    if not luautils.stringStarts(command, '/') then
        return nil
    end
    if IsOnlySpacesOrEmpty(command) then
        return nil
    end
    for _, stream in ipairs(ISChat.yacmCommand) do
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
        if stream['tabID'] == tabID and YacmServerSettings and YacmServerSettings[name] and YacmServerSettings[name]['enabled'] then
            table.insert(newTab.chatStreams, stream)
        end
    end
    if #newTab.chatStreams >= 1 then
        ISChat.defaultTabStream[tabID] = newTab.chatStreams[1]
        newTab.lastChatCommand = newTab.chatStreams[1].command
    end
end

local function UpdateRangeIndicator(stream)
    if YacmServerSettings ~= nil
        and YacmServerSettings[stream.name]['range'] ~= nil
        and YacmServerSettings[stream.name]['range'] ~= -1
        and YacmServerSettings[stream.name]['color'] ~= nil
    then
        local range = YacmServerSettings[stream.name]['range']
        ISChat.instance.rangeIndicator = RangeIndicator:new(range,
            YacmServerSettings[stream.name]['color'])
    else
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
        ISChat.instance.textEntry:setText(chatStreams[curTxtPanel.streamID].command)
        UpdateRangeIndicator(chatStreams[curTxtPanel.streamID])
    end
end

local function AddTab(tabTitle, tabID)
    local chat = ISChat.instance
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
    ISChat.instance.yacmModData['playerColor'] = color
    ModData.add('yacm', ISChat.instance.yacmModData)
end

local function SetPlayerPitch(pitch)
    ISChat.instance.yacmModData['voicePitch'] = pitch
    ModData.add('yacm', ISChat.instance.yacmModData)
end

local function InitGlobalModData()
    local yacmModData = ModData.getOrCreate("yacm")
    ISChat.instance.yacmModData = yacmModData

    if yacmModData['playerColor'] == nil then
        SetPlayerColor(GenerateRandomColor())
    end
    if yacmModData['isVoiceEnabled'] == nil and ISChat.instance.isVoiceEnabled == nil then
        -- wait for the server settings to override this if voices are enabled by default
        ISChat.instance.isVoiceEnabled = false
    elseif yacmModData['isVoiceEnabled'] ~= nil then
        ISChat.instance.isVoiceEnabled = yacmModData['isVoiceEnabled']
    end
    if yacmModData['voicePitch'] == nil then
        local randomPitch = ZombRandFloat(0.85, 1.15)
        if getPlayer():getVisual():isFemale() then
            randomPitch = randomPitch + 0.30
        end
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

    YacmClientSendCommands.sendAskSandboxVars()
end

ISChat.initChat = function()
    YacmServerSettings = nil
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
    instance.rangeIndicatorState = false

    InitGlobalModData()
    AddTab('General', 1)
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
    if YacmServerSettings and YacmServerSettings[stream.name] == false then
        return false
    end
    local pitch = ISChat.instance.yacmModData['voicePitch']
    local yacmCommand = Parser.ParseYacmMessage(command)
    local playerColor = ISChat.instance.yacmModData['playerColor']
    if yacmCommand == nil then
        return false
    end
    if stream.name == 'yell' then
        YacmClientSendCommands.sendChatMessage(command, playerColor, 'yell', pitch)
    elseif stream.name == 'say' then
        YacmClientSendCommands.sendChatMessage(command, playerColor, 'say', pitch)
    elseif stream.name == 'low' then
        YacmClientSendCommands.sendChatMessage(command, playerColor, 'low', pitch)
    elseif stream.name == 'whisper' then
        YacmClientSendCommands.sendChatMessage(command, playerColor, 'whisper', pitch)
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
        YacmClientSendCommands.sendPrivateMessage(pmBody, playerColor, target, pitch)
        ISChat.instance.chatText.lastChatCommand = ISChat.instance.chatText.lastChatCommand .. target .. ' '
    elseif stream.name == 'faction' then
        YacmClientSendCommands.sendChatMessage(command, playerColor, 'faction', pitch)
    elseif stream.name == 'safehouse' then
        YacmClientSendCommands.sendChatMessage(command, playerColor, 'safehouse', pitch)
    elseif stream.name == 'general' then
        YacmClientSendCommands.sendChatMessage(command, playerColor, 'general', pitch)
    elseif stream.name == 'admin' then
        YacmClientSendCommands.sendChatMessage(command, playerColor, 'admin', pitch)
    elseif stream.name == 'ooc' then
        YacmClientSendCommands.sendChatMessage(command, playerColor, 'ooc', pitch)
    else
        return false
    end
    if YacmServerSettings ~= nil
        and YacmServerSettings[stream.name] ~= nil
        and YacmServerSettings[stream.name]['zombieRange'] ~= nil
        and YacmServerSettings[stream.name]['zombieRange'] ~= -1
    then
        local zombieRange = YacmServerSettings[stream.name]['zombieRange']
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

local function GetArgumentsFromMessage(yacmCommand, message)
    if #message < #yacmCommand['command'] + 2 then -- command + space + chars
        return nil
    end
    local arguments = message:sub(#yacmCommand['command'] + 2)
    arguments = RemoveLeadingSpaces(arguments)
    if #arguments == 0 then
        return nil
    end
    return arguments
end

local function ProcessColorCommand(arguments)
    local currentColor = ISChat.instance.yacmModData['playerColor']
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
        ISChat.sendInfoToCurrentTab('pitch value is ' .. ISChat.instance.yacmModData['voicePitch'])
        return true
    end
    local regex = '^(%d+.?%d*) *$'
    local valueAsText = arguments:match(regex)
    if valueAsText then
        local value = tonumber(valueAsText)
        if value ~= nil and value >= 0.85 and value <= 1.45 then
            local currentPitch = ISChat.instance.yacmModData['voicePitch']
            SetPlayerPitch(value)
            ISChat.sendInfoToCurrentTab('pitch value updated to ' .. value .. ' from ' .. currentPitch)
            return true
        end
    end
    return false
end

local function ProcessYacmCommand(yacmCommand, message)
    local arguments = GetArgumentsFromMessage(yacmCommand, message)
    if yacmCommand['name'] == 'color' then
        if ProcessColorCommand(arguments) == false then
            ISChat.sendErrorToCurrentTab(
                'color command expects the format: "/color value" with value as 255, 255, 255 or #FFFFFF')
            return false
        end
    elseif yacmCommand['name'] == 'pitch' then
        if ProcessPitchCommand(arguments) == false then
            ISChat.sendErrorToCurrentTab('pitch command expects the format: "/pitch value" with value from 0.85 to 1.45')
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
    local yacmCommand = GetYacmCommandFromMessage(command)
    if stream then -- chat message
        if chat.currentTabID ~= stream.tabID then
            -- from one-based to zero-based
            print('user error: tried to send command ' ..
                stream['name'] .. ' from TabID ' .. chat.currentTabID ..
                ' but TabID ' .. stream.tabID .. ' was expected')
        else
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
        end
    elseif yacmCommand ~= nil then
        ProcessYacmCommand(yacmCommand, command)
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
    if YacmServerSettings ~= nil then
        color = YacmServerSettings[channel]['color']
    else
        color = { 255, 255, 255 }
    end
    return StringBuilder.BuildBracketColorString(color) .. '[' .. channel .. '] '
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
            local line = StringBuilder.BuildFontSizeString(self.chatFont)
            if self.showTimestamp then
                line = line .. StringBuilder.BuildTimePrefixString(msg.time)
            end
            if self.showTitle then
                line = line .. BuildChannelPrefixString(msg.channel)
            end
            line = line .. msg.line .. StringBuilder.BuildNewLine()
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
    if YacmServerSettings ~= nil
        and YacmServerSettings[type]
        and YacmServerSettings[type]['color']
    then
        return YacmServerSettings[type]['color']
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
    ['pm'] = ': ',
    ['faction'] = ' (faction): ',
    ['safehouse'] = ' (Safe House): ',
    ['general'] = ' (General): ',
    ['admin'] = ': ',
    ['ooc'] = ': ',
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

function BuildMessageFromPacket(type, message, author, playerColor, frequency)
    local messageColor = BuildColorFromMessageType(type)
    local parsedMessage = Parser.ParseYacmMessage(message, messageColor, 20, 200)
    local radioPrefix = ''
    if frequency then
        radioPrefix = '(' .. string.format('%.1fMHz', frequency / 1000) .. '), '
    end
    local messageColorString = StringBuilder.BuildBracketColorString(messageColor)
    local quote
    local verbString
    if YacmServerSettings == nil or YacmServerSettings['options']['verb'] == true then
        quote = BuildQuote(type)
        verbString = BuildVerbString(type)
    else
        quote = ''
        verbString = ' '
    end
    local formatedMessage = ''
    if author ~= nil then
        formatedMessage = formatedMessage .. StringBuilder.BuildBracketColorString(playerColor) .. author
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
    local onlineUsers = getOnlinePlayers()
    if author == nil then
        print('yacm error: CreatePlayerBubble: author is null')
        return
    end
    local authorObj = World.getPlayerByUsername(author)
    if authorObj == nil then
        print('yacm error: CreatePlayerBubble: author not found ' .. author)
        return
    end
    local timer = 10
    local opacity = 70
    if YacmServerSettings then
        timer = YacmServerSettings['options']['bubble']['timer']
        opacity = YacmServerSettings['options']['bubble']['opacity']
    end
    local bubble = PlayerBubble:new(
        authorObj, message, color, timer, opacity, ISChat.instance.isVoiceEnabled, voicePitch)
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
            print('yacm error: CreateSquareRadioBubble: nil position for a square radio')
            return
        end
        x, y, z = math.abs(x), math.abs(y), math.abs(z)
        if ISChat.instance.radioBubble['x' .. x .. 'y' .. y .. 'z' .. z] ~= nil then
            ISChat.instance.radioBubble['x' .. x .. 'y' .. y .. 'z' .. z].dead = true
        end
        local timer = 10
        local opacity = 70
        local square = getSquare(x, y, z)
        local bubble = RadioBubble:new(
            square, message, messageColor, timer, opacity, RadioBubble.types.square,
            ISChat.instance.isVoiceEnabled, voicePitch)
        ISChat.instance.radioBubble['x' .. x .. 'y' .. y .. 'z' .. z] = bubble
    end
end

function CreatePlayerRadioBubble(author, message, messageColor, voicePitch)
    ISChat.instance.playerRadioBubble = ISChat.instance.playerRadioBubble or {}
    local onlineUsers = getOnlinePlayers()
    if author == nil then
        print('yacm error: CreatePlayerRadioBubble: author is null')
        return
    end
    local authorObj = World.getPlayerByUsername(author)
    if authorObj == nil then
        print('yacm error: CreatePlayerRadioBubble: author not found ' .. author)
        return
    end
    local timer = 10
    local opacity = 70
    if YacmServerSettings then
        timer = YacmServerSettings['options']['bubble']['timer']
        opacity = YacmServerSettings['options']['bubble']['opacity']
    end
    local bubble = RadioBubble:new(authorObj, message, messageColor, timer, opacity,
        RadioBubble.types.player, ISChat.instance.isVoiceEnabled, voicePitch)
    ISChat.instance.playerRadioBubble[author] = bubble
end

function CreateVehicleRadioBubble(vehicle, message, messageColor, voicePitch)
    ISChat.instance.vehicleRadioBubble = ISChat.instance.vehicleRadioBubble or {}
    local timer = 10
    local opacity = 70
    if YacmServerSettings then
        timer = YacmServerSettings['options']['bubble']['timer']
        opacity = YacmServerSettings['options']['bubble']['opacity']
    end
    local keyId = vehicle:getKeyId()
    if keyId == nil then
        print('yacm error: CreateVehicleBubble: key id is null')
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
    player:getBodyDamage():setBoredomLevel(boredom - 0.6)
end

function ISChat.onMessagePacket(type, author, message, color, hideInChat, target, isFromDiscord, voicePitch)
    if author ~= getPlayer():getUsername() then
        ReduceBoredom()
    end
    local formattedMessage, parsedMessage = BuildMessageFromPacket(type, message, author, color)
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
        print('yacm error: onMessagePacket: stream not found')
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
    local color = (YacmServerSettings and YacmServerSettings['server']['color']) or { 255, 86, 64 }
    local time = Calendar.getInstance():getTimeInMillis()
    local stream = GetStreamFromType('general')
    if stream == nil then
        print('yacm error: onMessagePacket: stream not found')
        return
    end
    local parsedMessage = Parser.ParseYacmMessage(message, color, 20, 200)
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, ISChat.instance.showTitle,
        parsedMessage.body, time, 'server')
    AddMessageToTab(stream['tabID'], time, parsedMessage.body, line, 'server')
end

local function CreateSquaresRadiosBubbles(message, messageColor, squaresPos, voicePitch)
    if squaresPos == nil then
        print('yacm error: CreateSquaresRadiosBubbles: squaresPos table is null')
        return
    end
    for _, position in pairs(squaresPos) do
        CreateSquareRadioBubble(position, message, messageColor, voicePitch)
    end
end

local function CreatePlayersRadiosBubbles(message, messageColor, playersUsernames, voicePitch)
    if playersUsernames == nil then
        print('yacm error: CreatePlayersRadiosBubbles: playersUsernames table is null')
        return
    end
    for _, username in pairs(playersUsernames) do
        CreatePlayerRadioBubble(
            getPlayer():getUsername(), message, messageColor, voicePitch)
    end
end

local function CreateVehiclesRadiosBubbles(message, messageColor, vehiclesKeyIds, voicePitch)
    if vehiclesKeyIds == nil then
        print('yacm error: CreateVehiclesRadiosBubbles: vehiclesKeyIds table is null')
        return
    end
    local range = (YacmServerSettings and YacmServerSettings['say']['range']) or 15
    local vehicles = World.getVehiclesInRange(getPlayer(), range)
    for _, vehicleKeyId in pairs(vehiclesKeyIds) do
        local vehicle = vehicles[vehicleKeyId]
        if vehicle == nil then
            print('yacm error: CreateVehiclesRadiosBubble: vehicle not found for key id ' .. vehicleKeyId)
        else
            CreateVehicleRadioBubble(vehicle, message, messageColor, voicePitch)
        end
    end
end

function ISChat.onDiscordPacket(message)
    processGeneralMessage(message)
end

function ISChat.onRadioEmittingPacket(type, author, message, color, frequency)
    local time = Calendar.getInstance():getTimeInMillis()
    local stream = GetStreamFromType(type)
    if stream == nil then
        print('yacm error: onRadioEmittingPacket: stream not found')
        return
    end
    local formattedMessage, parsedMessages = BuildMessageFromPacket(type, message, author, color, frequency)
    local line = BuildChatMessage(ISChat.instance.chatFont, ISChat.instance.showTimestamp, ISChat.instance.showTitle,
        formattedMessage, time, type)
    AddMessageToTab(stream['tabID'], time, formattedMessage, line, stream['name'])
end

function ISChat.onRadioPacket(type, author, message, color, radiosInfo, voicePitch)
    local time = Calendar.getInstance():getTimeInMillis()
    local stream = GetStreamFromType(type)
    if stream == nil then
        print('yacm error: onRadioPacket: stream not found')
        return
    end

    local playerName = getPlayer():getUsername()
    if author ~= playerName then
        ReduceBoredom()
    end
    for frequency, radios in pairs(radiosInfo) do
        local formattedMessage, parsedMessages = BuildMessageFromPacket(type, message, author, color, frequency)
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
    local radios = World.getListeningRadios(getPlayer(), YacmServerSettings['say']['range'], frequency)
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
    local line = message:getText()
    local messageType = GetMessageType(message)
    if message:getRadioChannel() ~= -1 then -- scripted radio message
        local messageWithoutColorPrefix = message:getText():gsub('*%d+,%d+,%d+*', '')
        message:setText(messageWithoutColorPrefix)
        local color = (YacmServerSettings and YacmServerSettings['options']['radio']['color']) or {
            171, 240, 140,
        }
        ISChat.onRadioPacket(
            'scriptedRadio',
            nil,
            messageWithoutColorPrefix,
            color,
            nil, -- todo find a way to locate the radio
            message:getRadioChannel()
        )
    else
        message:setOverHeadSpeech(false)
    end

    if messageType == 'Local' then -- when pressing Q to shout
        ISChat.onMessagePacket(
            'yell',
            message:getAuthor(),
            line,
            { 255, 255, 255 },
            YacmServerSettings and YacmServerSettings['options'] and
            YacmServerSettings['options']['hideCallout'] or nil,
            nil -- voice pitch, should not be used, if we want it we need to send a packet to the server instead
        )
    end

    if message:isFromDiscord() then
        local discordColor = { 88, 101, 242 } -- discord logo color
        local messageWithoutPrefix = RemoveDiscordMessagePrefix(line)
        if messageWithoutPrefix == nil then
            print('yacm error: failed to remove discord message prefix for message: "' .. line .. '"')
            return
        end
        if YacmServerSettings and YacmServerSettings['general']
            and YacmServerSettings['general']['discord']
            and YacmServerSettings['general']['enabled']
        then
            ISChat.onMessagePacket(
                'general',
                message:getAuthor(),
                messageWithoutPrefix,
                discordColor,
                nil,
                nil,
                true,
                nil -- voice pitch, should not be used
            )
        end
        if YacmServerSettings and YacmServerSettings['options']
            and YacmServerSettings['options']['radio']
            and YacmServerSettings['options']['radio']['discord']
        then
            local frequency = YacmServerSettings['options']['radio']['frequency']
            if frequency then
                local radiosInfo = GenerateRadiosPacketFromListeningRadiosInRange(frequency)
                if radiosInfo ~= nil then
                    ISChat.onRadioPacket(
                        'say',
                        message:getAuthor(),
                        messageWithoutPrefix,
                        discordColor,
                        radiosInfo
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
        print('yacm error: addLineInChat: unknown id ' .. tabID)
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
    local instance = ISChat.instance
    if instance.rangeIndicator ~= nil
        and instance.rangeIndicatorState == true
        and ISChat.focused == true
    then
        instance.rangeIndicator:render()
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
    ChatUI.render(self)
end

function ISChat:prerender()
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
        ISChat.instance.rangeIndicator = nil
        ISChat.instance.lastStream = nil
        return
    end

    if internalText == '/r' and ISChat.instance.lastPrivateMessageAuthor ~= nil then
        t:setText('/pm ' .. ISChat.instance.lastPrivateMessageAuthor .. ' ')
        return
    end
    local stream = GetCommandFromMessage(internalText)
    if stream ~= nil then
        if ISChat.instance.lastStream ~= stream then
            UpdateRangeIndicator(stream)
        end
        YacmClientSendCommands.sendTyping(getPlayer():getUsername(), stream['name'])
    else
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

local function RenderChatText(self)
    self:setStencilRect(0, 0, self.width, self.height)
    ISRichTextPanel.render(self)
    self:clearStencilRect()
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
    if tabID == 1 and YacmServerSettings ~= nil and YacmServerSettings['admin']['enabled']
        and ISChat.instance.tabs[4] == nil then
        AddTab('Admin', 4)
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
    local info = getText('SurvivalGuide_YetAnotherChatMod', YET_ANOTHER_CHAT_MOD_VERSION)
    if YacmServerSettings['whisper']['enabled'] then
        info = info .. getText('SurvivalGuide_YetAnotherChatMod_Whisper')
    end
    if YacmServerSettings['low']['enabled'] then
        info = info .. getText('SurvivalGuide_YetAnotherChatMod_Low')
    end
    if YacmServerSettings['say']['enabled'] then
        info = info .. getText('SurvivalGuide_YetAnotherChatMod_Say')
    end
    if YacmServerSettings['yell']['enabled'] then
        info = info .. getText('SurvivalGuide_YetAnotherChatMod_Yell')
    end
    if YacmServerSettings['pm']['enabled'] then
        info = info .. getText('SurvivalGuide_YetAnotherChatMod_Pm')
    end
    if YacmServerSettings['faction']['enabled'] then
        info = info .. getText('SurvivalGuide_YetAnotherChatMod_Faction')
    end
    if YacmServerSettings['safehouse']['enabled'] then
        info = info .. getText('SurvivalGuide_YetAnotherChatMod_SafeHouse')
    end
    if YacmServerSettings['general']['enabled'] then
        info = info .. getText('SurvivalGuide_YetAnotherChatMod_General')
    end
    if YacmServerSettings['admin']['enabled'] then
        info = info .. getText('SurvivalGuide_YetAnotherChatMod_Admin')
    end
    if YacmServerSettings['ooc']['enabled'] then
        info = info .. getText('SurvivalGuide_YetAnotherChatMod_Ooc')
    end
    info = info .. getText('SurvivalGuide_YetAnotherChatMod_Color')
    info = info .. getText('SurvivalGuide_YetAnotherChatMod_Pitch')
    ISChat.instance:setInfo(info)
end

local function HasAtLeastOneChanelEnabled(tabId)
    if YacmServerSettings == nil then
        return false
    end
    for _, stream in pairs(ISChat.allChatStreams) do
        local name = stream['name']
        if stream['tabID'] == tabId and YacmServerSettings[name] and YacmServerSettings[name]['enabled'] then
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
    if YacmServerSettings ~= nil then
        return
    end
    Events.OnPostRender.Remove(AskServerData)

    YacmServerSettings = messageTypeSettings -- a global

    if HasAtLeastOneChanelEnabled(2) == true then
        AddTab('Out Of Character', 2)
    end
    if HasAtLeastOneChanelEnabled(3) == true then
        AddTab('Private Message', 3)
    end
    if getPlayer():getAccessLevel() == 'Admin' and messageTypeSettings['admin']['enabled'] then
        AddTab('Admin', 4)
    end
    if ISChat.instance.tabCnt > 1 and not HasAtLeastOneChanelEnabled(1) then
        RemoveTab('General', 1)
    else
        UpdateTabStreams(ISChat.instance.tabs[1], 1)
    end

    UpdateRangeIndicator(ISChat.defaultTabStream[ISChat.instance.currentTabID])
    UpdateInfoWindow()
    if ISChat.instance.yacmModData == nil or ISChat.instance.yacmModData['isVoiceEnabled'] == nil then
        -- wait for the server settings to override this if voices are enabled by default
        ISChat.instance.isVoiceEnabled = messageTypeSettings['options']['isVoiceEnabled']
    end
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
            print('yacm error: onToggleChatBox: next tab ID not found')
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
    ISChat.instance.rangeIndicatorState = not ISChat.instance.rangeIndicatorState
    if ISChat.instance.rangeIndicatorState == true then
        ISChat.instance.rangeButton:setImage(getTexture("media/ui/yacm/icons/eye-on.png"))
    else
        ISChat.instance.rangeButton:setImage(getTexture("media/ui/yacm/icons/eye-off.png"))
    end
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
    local info = getText('SurvivalGuide_YetAnotherChatMod', YET_ANOTHER_CHAT_MOD_VERSION)
    info = info .. getText('SurvivalGuide_YetAnotherChatMod_Color')
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
    self.rangeButton:setImage(getTexture("media/ui/yacm/icons/eye-off.png"))
    self.rangeButton:setUIName(ISChat.rangeButtonName)
    self:addChild(self.rangeButton)
    self.rangeButton:setVisible(true)

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
    self.textEntry:setText(self.chatText.lastChatCommand)
    if self.chatText.lastChatCommand ~= nil then
        local stream = GetCommandFromMessage(self.chatText.lastChatCommand)
        if stream ~= nil then
            UpdateRangeIndicator(stream)
        end
    else
        ISChat.instance.rangeIndicator = nil
    end
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
        print('yacm error: ISChat:onGearButtonClick: gear button context is null')
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

    local voiceOptionName = getText("UI_YACM_chat_enable_voices")
    if self.isVoiceEnabled then
        voiceOptionName = getText("UI_YACM_chat_disable_voices")
    end
    context:addOption(voiceOptionName, ISChat.instance, ISChat.onToggleVoicePrefix)
end

function ISChat.onToggleVoicePrefix()
    ISChat.instance.isVoiceEnabled = not ISChat.instance.isVoiceEnabled

    -- the player has set this option at least once, that means he is aware of its existence
    -- we'll use this settings in the future instead of the server default behavior
    ISChat.instance.yacmModData['isVoiceEnabled'] = ISChat.instance.isVoiceEnabled
    ModData.add('yacm', ISChat.instance.yacmModData)
end

Events.OnChatWindowInit.Add(ISChat.initChat)
