local YacmClientSendCommands = {}

function SendYacmClientCommand(commandName, args)
    sendClientCommand('YACM', commandName, args)
end

function YacmClientSendCommands.sendChatMessage(message, playerColor, type, pitch)
    if not isClient() then return end
    SendYacmClientCommand('ChatMessage', {
        author = getPlayer():getUsername(),
        message = message,
        type = type,
        color = playerColor,
        pitch = pitch,
    })
end

function YacmClientSendCommands.sendPrivateMessage(message, playerColor, target, pitch)
    if not isClient() then return end
    SendYacmClientCommand('ChatMessage', {
        author = getPlayer():getUsername(),
        message = message,
        type = 'pm',
        target = target,
        color = playerColor,
        pitch = pitch,
    })
end

function YacmClientSendCommands.sendTyping(author, type)
    if not isClient() then return end
    SendYacmClientCommand('Typing', {
        author = author,
        type = type,
    })
end

function YacmClientSendCommands.sendAskSandboxVars()
    if not isClient() then return end
    SendYacmClientCommand('AskSandboxVars', {})
end

function YacmClientSendCommands.sendMuteRadio(radio, state)
    if not isClient() then return end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('yacm error: YacmClientSendCommands.sendMuteRadio: no radioData found')
        return
    end
    if radioData:isIsoDevice() then
        SendYacmClientCommand('MuteSquareRadio', {
            mute = state,
            x = radio:getX(),
            y = radio:getY(),
            z = radio:getZ(),
        })
    elseif instanceof(radio, 'Radio') then -- is an inventoryItem radio
        local id = radio:getID()
        if id == nil then
            print('yacm error: YacmClientSendCommands.sendMuteRadio: no id found')
            return
        end
        SendYacmClientCommand('MuteInHandRadio', {
            mute = state,
            id = id,
            player = getPlayer():getUsername(),
        })
    end
end

function YacmClientSendCommands.sendAskRadioState(radio)
    if not isClient() then return end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('yacm error: YacmClientSendCommands.sendAskRadioState: no radioData found')
        return
    end
    if radioData:isIsoDevice() then
        SendYacmClientCommand('AskSquareRadioState', {
            x = radio:getX(),
            y = radio:getY(),
            z = radio:getZ(),
        })
    elseif instanceof(radio, 'Radio') then -- is an inventoryItem radio
        local id = radio:getID()
        if id == nil then
            print('yacm error: YacmClientSendCommands.sendAskRadioState: no id found')
            return
        end
        SendYacmClientCommand('AskInHandRadioState', {
            id = id,
            player = getPlayer():getUsername(),
        })
    end
end

return YacmClientSendCommands
