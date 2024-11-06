local Character = require('yacm/shared/utils/Character')

local SendYacmClient = {}

function SendYacmClientCommand(commandName, args)
    sendClientCommand('YACM', commandName, args)
end

local function FormatCharacterName(player)
    local first, last = Character.getFirstAndLastName(player)
    return first .. ' ' .. last
end

function SendYacmClient.sendChatMessage(message, playerColor, type, pitch, disableVerb)
    if not isClient() then return end
    local player = getPlayer()
    SendYacmClientCommand('ChatMessage', {
        author = player:getUsername(),
        characterName = FormatCharacterName(player),
        message = message,
        type = type,
        color = playerColor,
        pitch = pitch,
        disableVerb = disableVerb,
    })
end

function SendYacmClient.sendPrivateMessage(message, playerColor, target, pitch)
    if not isClient() then return end
    local player = getPlayer()
    SendYacmClientCommand('ChatMessage', {
        author = getPlayer():getUsername(),
        characterName = FormatCharacterName(player),
        message = message,
        type = 'pm',
        target = target,
        color = playerColor,
        pitch = pitch,
    })
end

function SendYacmClient.sendTyping(author, type)
    if not isClient() then return end
    SendYacmClientCommand('Typing', {
        author = author,
        type = type,
    })
end

function SendYacmClient.sendAskSandboxVars()
    if not isClient() then return end
    SendYacmClientCommand('AskSandboxVars', {})
end

function SendYacmClient.sendMuteRadio(radio, state)
    if not isClient() then return end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('yacm error: SendYacmClient.sendMuteRadio: no radioData found')
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
            print('yacm error: SendYacmClient.sendMuteRadio: no id found')
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
function SendYacmClient.sendGiveRadioState(radio)
    if not isClient() then return end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('yacm error: SendYacmClient.sendTellRadioState: no radioData found')
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

function SendYacmClient.sendAskRadioState(radio)
    if not isClient() then return end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('yacm error: SendYacmClient.sendAskRadioState: no radioData found')
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
            print('yacm error: SendYacmClient.sendAskRadioState: no id found')
            return
        end
        SendYacmClientCommand('AskInHandRadioState', {
            id = id,
            belt = beltType,
            player = getPlayer():getUsername(),
        })
    end
end

function SendYacmClient.sendKnownAvatars(knownAvatars)
    SendYacmClientCommand('KnownAvatars', {
        avatars = knownAvatars,
    })
end

function SendYacmClient.sendAvatarRequest(avatarRequest)
    SendYacmClientCommand('AvatarRequest', avatarRequest)
end

function SendYacmClient.sendApprovePendingAvatar(username, firstName, lastName, checksum)
    SendYacmClientCommand('ApproveAvatar', {
        username = username,
        firstName = firstName,
        lastName = lastName,
        checksum = checksum,
    })
end

function SendYacmClient.sendRejectPendingAvatar(username, firstName, lastName, checksum)
    SendYacmClientCommand('RejectAvatar', {
        username = username,
        firstName = firstName,
        lastName = lastName,
        checksum = checksum,
    })
end

return SendYacmClient
