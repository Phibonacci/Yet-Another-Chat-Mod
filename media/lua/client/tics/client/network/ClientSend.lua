local Character = require('tics/shared/utils/Character')

local ClientSend = {}

function ClientSendCommand(commandName, args)
    sendClientCommand('TICS', commandName, args)
end

local function FormatCharacterName(player)
    local first, last = Character.getFirstAndLastName(player)
    return first .. ' ' .. last
end

local function autoFormatString(str)
    str = str:gsub("^%l", string.upper)
    local lastChar = string.sub(str, str:len())
    if not (lastChar == "." or lastChar == "!" or lastChar == "?") then
        str = str .. "."
    end
    return str
end

function ClientSend.sendChatMessage(message, playerColor, type, pitch, disableVerb)
    if not isClient() then return end
    local player = getPlayer()
    message = autoFormatString(message)
    ClientSendCommand('ChatMessage', {
        author = player:getUsername(),
        characterName = FormatCharacterName(player),
        message = message,
        type = type,
        color = playerColor,
        pitch = pitch,
        disableVerb = disableVerb,
    })
end

function ClientSend.sendPrivateMessage(message, playerColor, target, pitch)
    if not isClient() then return end
    local player = getPlayer()
    message = autoFormatString(message)
    ClientSendCommand('ChatMessage', {
        author = getPlayer():getUsername(),
        characterName = FormatCharacterName(player),
        message = message,
        type = 'pm',
        target = target,
        color = playerColor,
        pitch = pitch,
    })
end

function ClientSend.sendTyping(author, type)
    if not isClient() then return end
    ClientSendCommand('Typing', {
        author = author,
        type = type,
    })
end

function ClientSend.sendAskSandboxVars()
    if not isClient() then return end
    ClientSendCommand('AskSandboxVars', {})
end

function ClientSend.sendMuteRadio(radio, state)
    if not isClient() then return end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('TICS error: ClientSend.sendMuteRadio: no radioData found')
        return
    end
    if radioData:isIsoDevice() then
        ClientSendCommand('MuteSquareRadio', {
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
            print('TICS error: ClientSend.sendMuteRadio: no id found')
            return
        end
        ClientSendCommand('MuteInHandRadio', {
            mute = state,
            id = id,
            belt = beltType,
            player = getPlayer():getUsername(),
        })
    end
end

-- only for belt items
function ClientSend.sendGiveRadioState(radio)
    if not isClient() then return end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('TICS error: ClientSend.sendTellRadioState: no radioData found')
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

            ClientSendCommand('GiveBeltRadioState', {
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

function ClientSend.sendAskRadioState(radio)
    if not isClient() then return end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('TICS error: ClientSend.sendAskRadioState: no radioData found')
        return
    end
    if radioData:isIsoDevice() then
        ClientSendCommand('AskSquareRadioState', {
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
            print('TICS error: ClientSend.sendAskRadioState: no id found')
            return
        end
        ClientSendCommand('AskInHandRadioState', {
            id = id,
            belt = beltType,
            player = getPlayer():getUsername(),
        })
    end
end

function ClientSend.sendKnownAvatars(knownAvatars)
    ClientSendCommand('KnownAvatars', {
        avatars = knownAvatars,
    })
end

function ClientSend.sendAvatarRequest(avatarRequest)
    ClientSendCommand('AvatarRequest', avatarRequest)
end

function ClientSend.sendApprovePendingAvatar(username, firstName, lastName, checksum)
    ClientSendCommand('ApproveAvatar', {
        username = username,
        firstName = firstName,
        lastName = lastName,
        checksum = checksum,
    })
end

function ClientSend.sendRejectPendingAvatar(username, firstName, lastName, checksum)
    ClientSendCommand('RejectAvatar', {
        username = username,
        firstName = firstName,
        lastName = lastName,
        checksum = checksum,
    })
end

function ClientSend.sendRoll(diceCount, diceType, addCount)
    ClientSendCommand('Roll', {
        diceCount = diceCount,
        diceType = diceType,
        addCount = addCount,
    })
end

return ClientSend
