local Character = require('yacm/shared/utils/Character')

local YacmClientSendCommands = {}

function SendYacmClientCommand(commandName, args)
    sendClientCommand('YACM', commandName, args)
end

function YacmClientSendCommands.sendChatMessage(message, playerColor, type, pitch, disableVerb)
    if not isClient() then return end
    local player = getPlayer()
    SendYacmClientCommand('ChatMessage', {
        author = player:getUsername(),
        characterName = Character.getFirstAndLastName(player),
        message = message,
        type = type,
        color = playerColor,
        pitch = pitch,
        disableVerb = disableVerb,
    })
end

function YacmClientSendCommands.sendPrivateMessage(message, playerColor, target, pitch)
    if not isClient() then return end
    local player = getPlayer()
    SendYacmClientCommand('ChatMessage', {
        author = getPlayer():getUsername(),
        characterName = Character.getFirstAndLastName(player),
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
        local player = getPlayer()
        local primary = player:getPrimaryHandItem()
        local secondary = player:getSecondaryHandItem()
        local beltType = nil
        if (primary == nil or primary:getID() ~= id)
            and (secondary == nil or secondary:getID() ~= id)
        then
            -- the ID is unreliable for non-in-hand items so we're going with the type
            -- and pray to find the right radio, or (un)mute the wrong one...
            beltType = radio:getType()
        end
        if id == nil then
            print('yacm error: YacmClientSendCommands.sendMuteRadio: no id found')
            return
        end
        SendYacmClientCommand('MuteInHandRadio', {
            mute = state,
            id = id,
            belt = beltType,
            player = getPlayer():getUsername(),
        })
    end
end

-- only for belt items
function YacmClientSendCommands.sendGiveRadioState(radio)
    if not isClient() then return end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('yacm error: YacmClientSendCommands.sendTellRadioState: no radioData found')
        return
    end

    if instanceof(radio, 'Radio') then -- is an inventoryItem radio
        local player = getPlayer()
        local primary = player:getPrimaryHandItem()
        local secondary = player:getSecondaryHandItem()
        local beltType = nil
        local id = radio:getID()
        -- is not in-hand (so the server is not sync with it already)
        if (primary == nil or primary:getID() ~= id)
            and (secondary == nil or secondary:getID() ~= id)
        then
            -- the ID is unreliable for non-in-hand items so we're going with the type
            -- and pray to find the right radio, or sync the wrong one...
            beltType = radio:getType()

            SendYacmClientCommand('GiveBeltRadioState', {
                belt = beltType,
                player = getPlayer():getUsername(),
                turnedOn = radioData:getIsTurnedOn(),
                mute = radioData:getMicIsMuted(),
                volume = radioData:getDeviceVolume(),
                frequency = radioData:getChannel(),
                battery = radioData:getPower(),
                headphone = radioData:getHeadphoneType(),
                isTwoWay = radioData:getIsTwoWay(),
                transmitRange = radioData:getTransmitRange(),
            })
        end
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
        local player = getPlayer()
        local primary = player:getPrimaryHandItem()
        local secondary = player:getSecondaryHandItem()
        local beltType = nil
        if (primary == nil or primary:getID() ~= id)
            and (secondary == nil or secondary:getID() ~= id)
        then
            -- the ID is unreliable for non-in-hand items so we're going with the type
            -- and pray to find the right radio, or (un)mute the wrong one...
            beltType = radio:getType()
        end
        if id == nil then
            print('yacm error: YacmClientSendCommands.sendAskRadioState: no id found')
            return
        end
        SendYacmClientCommand('AskInHandRadioState', {
            id = id,
            belt = beltType,
            player = getPlayer():getUsername(),
        })
    end
end

return YacmClientSendCommands
