local Character = require('yacm/shared/utils/Character')
local ChatMessage = require('yacm/server/ChatMessage')
local SendServer = require('yacm/server/network/SendServer')
local Radio = require('yacm/server/Radio')
local World = require('yacm/shared/utils/World')

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
    local radio = Character.getItemById(player, id)
    if radio == nil then
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
    local radio = Character.getItemById(player, id)
    if radio == nil then
        print('yacm error: AskInHandRadioState packet asking for id ' .. id ..
            ' but no radio was found')
        return
    end
    Radio.SyncHand(radio, player)
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
