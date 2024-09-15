local Character    = require('yacm/shared/utils/Character')
local ChatMessage  = require('yacm/server/ChatMessage')
local SendServer   = require('yacm/server/network/SendServer')
local Radio        = require('yacm/server/radio/Radio')
local RadioManager = require('yacm/server/radio/RadioManager')
local World        = require('yacm/shared/utils/World')


local RecvServer = {}


RecvServer['MuteInHandRadio'] = function(player, args)
    local playerName = args['player']
    if playerName == nil then
        print('yacm error: MuteInHandRadio packet with null player name')
        return
    end
    if args['id'] == nil then
        print('yacm error: MuteInHandRadio packet with a null id')
        return
    end
    local id = args['id']
    if id == nil then
        print('yacm error: MuteInHandRadio packet has no id value')
        return
    end
    local radio = Character.getItemById(player, id) or Character.getFirstAttachedItemByType(player, args['belt'])
    if radio == nil or not instanceof(radio, 'Radio') then
        print('yacm error: MuteInHandRadio packet asking for id ' .. id ..
            ' but no radio was found')
        return
    end
    local muteState = args['mute']
    if type(muteState) ~= 'boolean' then
        print('yacm error: MuteInHandRadio packet has no "mute" variable')
        return
    end
    Radio.MuteRadio(radio, muteState)
    Radio.SyncHand(radio, player, id)
end


RecvServer['MuteSquareRadio'] = function(player, args)
    local x = args['x']
    local y = args['y']
    local z = args['z']
    if x == nil or y == nil or z == nil then
        print('yacm error: MuteSquareRadio packet with null coordinate')
        return
    end
    local square = getSquare(x, y, z)
    if square == nil then
        print('yacm error: MuteSquareRadio packet coordinate do not point to a square: x: ' ..
            x .. ', y: ' .. y .. ', z: ' .. z)
        return
    end
    local radios = World.getSquareItemsByGroup(square, 'IsoRadio')
    if radios == nil or #radios <= 0 then
        print('yacm error: MuteSquareRadio packet square does not contain a radio at: x: ' ..
            x .. ', y: ' .. y .. ', z: ' .. z)
        return
    end
    local radio = radios[1]
    if radio == nil or radio.getModData == nil or radio:getModData() == nil then
        print('yacm error: MuteSquareRadio packet lead to an impossible error where we found a corrupted radio')
        return
    end
    local muteState = args['mute']
    if type(muteState) ~= 'boolean' then
        print('yacm error: MuteSquareRadio packet has no "mute" variable')
        return
    end
    Radio.MuteRadio(radio, muteState)
    Radio.SyncSquare(radio)
end


RecvServer['ChatMessage'] = function(player, args)
    ChatMessage.ProcessMessage(player, args, 'ChatMessage', true)
end


RecvServer['Typing'] = function(player, args)
    ChatMessage.ProcessMessage(player, args, 'Typing', false)
end


RecvServer['AskSandboxVars'] = function(player, args)
    SendServer.Command(player, 'SendSandboxVars', ChatMessage.MessageTypeSettings)
end


RecvServer['GiveBeltRadioState'] = function(player, args)
    local playerName = args['player']
    if playerName == nil then
        print('yacm error: GiveBeltRadioState packet with null player name')
        return
    end
    local beltType = args['belt']
    if beltType == nil then
        print('yacm error: GiveBeltRadioState packet has no "belt" variable')
        return
    end
    local turnedOn = args['turnedOn']
    if type(turnedOn) ~= 'boolean' then
        print('yacm error: GiveBeltRadioState packet has no "turnedOn" variable')
        return
    end
    local muteState = args['mute']
    if type(muteState) ~= 'boolean' then
        print('yacm error: GiveBeltRadioState packet has no "mute" variable')
        return
    end
    local volume = args['volume']
    if type(volume) ~= 'number' then
        print('yacm error: GiveBeltRadioState packet has no "volume" variable')
        return
    end
    local frequency = args['frequency']
    if type(frequency) ~= 'number' then
        print('yacm error: GiveBeltRadioState packet has no "frequency" variable')
        return
    end
    local battery = args['battery']
    if type(battery) ~= 'number' then
        print('yacm error: GiveBeltRadioState packet has no "battery" variable')
        return
    end
    local headphone = args['headphone']
    if type(headphone) ~= 'number' then
        print('yacm error: GiveBeltRadioState packet has no "headphone" variable')
        return
    end
    local isTwoWay = args['isTwoWay']
    if type(isTwoWay) ~= 'boolean' then
        print('yacm error: GiveBeltRadioState packet has no "isTwoWay" variable')
        return
    end
    local transmitRange = args['transmitRange']
    if type(transmitRange) ~= 'number' then
        print('yacm error: GiveBeltRadioState packet has no "transmitRange" variable')
        return
    end
    local radio = Character.getFirstAttachedItemByType(player, beltType)
    if radio == nil or not instanceof(radio, 'Radio') then
        print('yacm error: GiveBeltRadioState packet asking for a belt radio of type ' .. beltType ..
            ' but no radio was found')
        return
    end
    radio = RadioManager:getOrCreateFakeBeltRadio(player)
    Radio.MuteRadio(radio, muteState)
    Radio.SyncBelt(radio, player, turnedOn, muteState, volume, frequency, battery, headphone, isTwoWay, transmitRange)
end


RecvServer['AskInHandRadioState'] = function(player, args)
    local playerName = args['player']
    if playerName == nil then
        print('yacm error: AskInHandRadioState packet with null player name')
        return
    end
    local id = args['id']
    if id == nil then
        print('yacm error: AskInHandRadioState packet with a null id')
        return
    end
    local radio = Character.getItemById(player, id) or Character.getFirstAttachedItemByType(player, args['belt'])
    if radio == nil or not instanceof(radio, 'Radio') then
        print('yacm error: AskInHandRadioState packet asking for id ' .. id ..
            ' but no radio was found')
        return
    end
    Radio.SyncHand(radio, player, id)
end


RecvServer['AskSquareRadioState'] = function(player, args)
    local x = args['x']
    local y = args['y']
    local z = args['z']
    if x == nil or y == nil or z == nil then
        print('yacm error: AskSquareRadioState packet with null coordinate')
        return
    end
    local square = getSquare(x, y, z)
    if square == nil then
        print('yacm error: AskSquareRadioState packet coordinate do not point to a square: x: ' ..
            x .. ', y: ' .. y .. ', z: ' .. z)
        return
    end
    local radios = World.getSquareItemsByGroup(square, 'IsoRadio')
    if radios == nil or #radios <= 0 then
        print('yacm error: AskSquareRadioState packet square does not contain a radio at: x: ' ..
            x .. ', y: ' .. y .. ', z: ' .. z)
        return
    end
    local radio = radios[1]
    Radio.SyncSquare(radio, player)
end

local function OnClientCommand(module, command, player, args)
    if module == 'YACM' and RecvServer[command] then
        RecvServer[command](player, args)
    end
end


Events.OnClientCommand.Add(OnClientCommand)
