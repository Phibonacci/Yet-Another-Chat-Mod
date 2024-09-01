local Character = require('yacm/shared/utils/Character')
local SendServer = require('yacm/server/network/SendServer')
local StringParser = require('yacm/shared/utils/StringParser')
local World = require('yacm/shared/utils/World')

local ChatMessage = {}

local function PlayersDistance(source, target)
    local stupidDistance = source:DistTo(target:getX(), target:getY())
    local accurateDistance = math.max(stupidDistance - 1, 0)
    return math.floor(accurateDistance + 0.5)
end

local function DistanceManhatten(source, target)
    return math.abs(target:getX() - source:getX()) + math.abs(target:getY() - source:getY())
end

local MessageHasAccessByType = {
    ['whisper']   = function(author, player, args) return true end,
    ['low']       = function(author, player, args) return true end,

    ['say']       = function(author, player, args) return true end,

    ['yell']      = function(author, player, args) return true end,
    ['pm']        = function(author, player, args)
        return args.target ~= nil and args.author ~= nil and
            (player:getUsername():lower() == args.target:lower() or player:getUsername():lower() == args.author:lower())
    end,
    ['faction']   = function(author, player, args)
        local playerFaction = Faction.getPlayerFaction(player)
        local authorFaction = Faction.getPlayerFaction(author)
        return playerFaction ~= nil and authorFaction ~= nil and playerFaction:getName() == authorFaction:getName()
    end,
    ['safehouse'] = function(author, player, args)
        local playerSafeHouse = SafeHouse.hasSafehouse(player)
        local authorSafeHouse = SafeHouse.hasSafehouse(author)
        return playerSafeHouse ~= nil and authorSafeHouse ~= nil and
            playerSafeHouse:getTitle() == authorSafeHouse:getTitle()
    end,
    ['general']   = function(author, player, args) return true end,
    ['admin']     = function(author, player, args)
        return player:getAccessLevel() == 'Admin'
    end,
    ['ooc']       = function(author, player, args) return true end,
}

local function GetColorFromString(colorString)
    local defaultColor = { 255, 0, 255 }
    local rgb = StringParser.hexaStringToRGB(colorString)
    if rgb == nil then
        print('yacm error: invalid string for Sandbox Variable: "' .. name .. '"')
        return defaultColor
    end
    return rgb
end

local function GetColorSandbox(name)
    local colorString = SandboxVars.YetAnotherChatMod[name .. 'Color']
    return GetColorFromString(colorString)
end

ChatMessage.MessageTypeSettings = nil

local function SetMessageTypeSettings()
    ChatMessage.MessageTypeSettings = {
        ['markdown'] = {
            ['italic'] = {
                ['color'] = GetColorSandbox('MarkdownOneAsterisk')
            },
            ['bold'] = {
                ['color'] = GetColorSandbox('MarkdownTwoAsterisks')
            },
        },
        ['whisper'] = {
            ['range'] = SandboxVars.YetAnotherChatMod.WhisperRange,
            ['zombieRange'] = SandboxVars.YetAnotherChatMod.WhisperZombieRange,
            ['enabled'] = SandboxVars.YetAnotherChatMod.WhisperEnabled,
            ['color'] = GetColorSandbox('Whisper'),
            ['radio'] = true,
        },
        ['low'] = {
            ['range'] = SandboxVars.YetAnotherChatMod.LowRange,
            ['zombieRange'] = SandboxVars.YetAnotherChatMod.LowZombieRange,
            ['enabled'] = SandboxVars.YetAnotherChatMod.LowEnabled,
            ['color'] = GetColorSandbox('Low'),
            ['radio'] = true,
        },
        ['say'] = {
            ['range'] = SandboxVars.YetAnotherChatMod.SayRange,
            ['zombieRange'] = SandboxVars.YetAnotherChatMod.SayZombieRange,
            ['enabled'] = SandboxVars.YetAnotherChatMod.SayEnabled,
            ['color'] = GetColorSandbox('Say'),
            ['radio'] = true,
        },
        ['yell'] = {
            ['range'] = SandboxVars.YetAnotherChatMod.YellRange,
            ['zombieRange'] = SandboxVars.YetAnotherChatMod.YellZombieRange,
            ['enabled'] = SandboxVars.YetAnotherChatMod.YellEnabled,
            ['color'] = GetColorSandbox('Yell'),
            ['radio'] = true,
        },
        ['pm'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.PrivateMessageEnabled,
            ['color'] = GetColorSandbox('PrivateMessage'),
            ['radio'] = false,
        },
        ['faction'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.FactionMessageEnabled,
            ['color'] = GetColorSandbox('FactionMessage'),
            ['radio'] = false,
        },
        ['safehouse'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.SafeHouseMessageEnabled,
            ['color'] = GetColorSandbox('SafeHouseMessage'),
            ['radio'] = false,
        },
        ['general'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.GeneralMessageEnabled,
            ['color'] = GetColorSandbox('GeneralMessage'),
            ['radio'] = false,
        },
        ['admin'] = {
            ['range'] = -1,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.AdminMessageEnabled,
            ['color'] = GetColorSandbox('AdminMessage'),
            ['radio'] = false,
        },
        ['ooc'] = {
            ['range'] = SandboxVars.YetAnotherChatMod.OutOfCharacterMessageRange,
            ['zombieRange'] = -1,
            ['enabled'] = SandboxVars.YetAnotherChatMod.OutOfCharacterMessageEnabled,
            ['color'] = GetColorSandbox('OutOfCharacterMessage'),
            ['radio'] = false,
        },
        ['scriptedRadio'] = {
            ['enabled'] = true,
            ['color'] = GetColorFromString(SandboxVars.YetAnotherChatMod.RadioColor),
        },
        ['options'] = {
            ['verb'] = SandboxVars.YetAnotherChatMod.VerbEnabled,
            ['bubble'] = {
                ['timer'] = SandboxVars.YetAnotherChatMod.BubbleTimerInSeconds,
                ['opacity'] = SandboxVars.YetAnotherChatMod.BubbleOpacity,
            },
            ['radio'] = {
                ['chatEnabled'] = SandboxVars.YetAnotherChatMod.RadioChatEnabled,
                ['color'] = GetColorFromString(SandboxVars.YetAnotherChatMod.RadioColor),
            },
            ['hideCallout'] = SandboxVars.YetAnotherChatMod.HideCallout,
        },
    }
end


local function GetRangeForMessageType(type)
    local messageSettings = ChatMessage.MessageTypeSettings[type]
    if messageSettings ~= nil then
        return messageSettings['range']
    end
    error('unknown message type "' .. type .. '"')
    return nil
end

local function GetConnectedPlayer(username)
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if connectedPlayer:getUsername():lower() == username:lower() then
            return connectedPlayer
        end
    end
    return nil
end

local function IsAllowed(author, player, args)
    if args.type == nil or ChatMessage.MessageTypeSettings[args.type] == nil
        or ChatMessage.MessageTypeSettings[args.type]['enabled'] ~= true
        or MessageHasAccessByType[args.type] == nil
    then
        return false
    end
    return MessageHasAccessByType[args.type](author, player, args)
end

local function IsInRadioEmittingRange(radioEmitters, receiver)
    if radioEmitters == nil then
        return false
    end
    for _, radioEmitter in pairs(radioEmitters) do
        local radioData = radioEmitter:getDeviceData()
        if radioData ~= nil then
            local transmitRange = radioData:getTransmitRange()
            local distance = DistanceManhatten(radioEmitter, receiver)
            if distance <= transmitRange then
                return true
            end
        end
    end
    return false
end

local function GetSquaresRadios(player, args, radioFrequencies)
    local radiosByFrequency = {}
    local radioMaxRange = 10
    local radios = World.getItemsInRangeByGroup(player, radioMaxRange, 'IsoRadio')
    local found = false
    for _, radio in pairs(radios) do
        local pos = {
            x = radio:getX(),
            y = radio:getY(),
            z = radio:getZ(),
        }
        local radioData = radio:getDeviceData()
        if radioData ~= nil then
            local frequency = radioData:getChannel()
            local turnedOn = radioData:getIsTurnedOn()
            local volume = radioData:getDeviceVolume()
            if volume == nil then
                volume = 0
            end
            volume = math.abs(volume)
            local radioRange = math.abs(volume * radioMaxRange + 0.5)
            local playerDistance = PlayersDistance(player, radio)
            if turnedOn and frequency ~= nil and radioFrequencies[frequency] ~= nil
                and playerDistance <= radioRange
                and IsInRadioEmittingRange(radioFrequencies[frequency], radio)
            then
                if radiosByFrequency[frequency] == nil then
                    radiosByFrequency[frequency] = {}
                end
                table.insert(radiosByFrequency[frequency], pos)
                found = true
            end
        end
    end
    return radiosByFrequency, found
end

local function GetPlayerRadios(player, args, radioFrequencies)
    local radiosByFrequency = {}
    local radio = Character.getHandItemByGroup(player, 'Radio')
    local found = false
    if radio == nil then
        return radiosByFrequency
    end
    local radioData = radio and radio:getDeviceData() or nil
    if radioData then
        local frequency = radioData:getChannel()
        if radioData:getIsTurnedOn()
            and frequency ~= nil and radioFrequencies[frequency] ~= nil
            and IsInRadioEmittingRange(radioFrequencies[frequency], radio)
        then
            if radiosByFrequency[frequency] == nil then
                radiosByFrequency[frequency] = {}
            end
            table.insert(radiosByFrequency[frequency], player:getUsername())
            found = true
        end
    end
    return radiosByFrequency, found
end

local function GetVehiclesRadios(player, args, radioFrequencies)
    local vehiclesByFrequency = {}
    local radioMaxRange = 10
    local vehicles = World.getVehiclesInRange(player, radioMaxRange)
    local found = false
    for _, vehicle in pairs(vehicles) do
        local radio = vehicle:getPartById('Radio')
        if radio ~= nil then
            local radioData = radio:getDeviceData()
            if radioData ~= nil then
                local frequency = radioData:getChannel()
                if radioData:getIsTurnedOn()
                    and frequency ~= nil and radioFrequencies[frequency] ~= nil
                    and IsInRadioEmittingRange(radioFrequencies[frequency], radio)
                then
                    if vehiclesByFrequency[frequency] == nil then
                        vehiclesByFrequency[frequency] = {}
                    end
                    table.insert(vehiclesByFrequency[frequency], vehicle:getKeyId())
                    found = true
                end
            end
        end
    end
    return vehiclesByFrequency, found
end

local function SendRadioPackets(author, player, args, sourceRadioByFrequencies)
    local squaresRadios, squaresRadiosFound = GetSquaresRadios(player, args, sourceRadioByFrequencies)
    local playersRadios, playersRadiosFound = GetPlayerRadios(player, args, sourceRadioByFrequencies)
    local vehiclesRadios, vehiclesRadiosFound = GetVehiclesRadios(player, args, sourceRadioByFrequencies)

    if not squaresRadiosFound and not playersRadiosFound and not vehiclesRadiosFound then
        return
    end

    local targetRadiosByFrequencies = {}
    for frequency, _ in pairs(sourceRadioByFrequencies) do
        targetRadiosByFrequencies[frequency] = {
            squares = squaresRadios[frequency] or {},
            players = playersRadios[frequency] or {},
            vehicles = vehiclesRadios[frequency] or {},
        }
    end

    SendServer.Command(player, 'RadioMessage', {
        author = args.author,
        message = args.message,
        color = args.color,
        type = args.type,
        radios = targetRadiosByFrequencies,
    })
end

local function GetEmittingRadios(player, packetType, messageType, range)
    local radioEmission = false
    local radioFrequencies = {}
    if ChatMessage.MessageTypeSettings[messageType] and ChatMessage.MessageTypeSettings[messageType]['radio'] == true
        and packetType == 'ChatMessage' and range > 0
    then
        local radios = World.getItemsInRangeByGroup(player, range, 'IsoRadio')
        for _, radio in pairs(radios) do
            local radioData = radio:getDeviceData()
            if radioData ~= nil then
                local frequency = radioData:getChannel()
                if radioData:getIsTwoWay() and radioData:getIsTurnedOn()
                    and not radioData:getMicIsMuted() and frequency ~= nil
                then
                    if radioFrequencies[frequency] == nil then
                        radioFrequencies[frequency] = {}
                    end
                    table.insert(radioFrequencies[frequency], radio)
                    radioEmission = true
                end
            end
        end
        local radio = Character.getHandItemByGroup(player, 'Radio')
        local radioData = radio and radio:getDeviceData() or nil
        if radioData then
            local frequency = radioData:getChannel()
            if radioData and radioData:getIsTwoWay() and radioData:getIsTurnedOn()
                and not radioData:getMicIsMuted() and frequency ~= nil
            then
                if radioFrequencies[frequency] == nil then
                    radioFrequencies[frequency] = {}
                end
                table.insert(radioFrequencies[frequency], radio)
                radioEmission = true
            end
        end
    end
    return radioEmission, radioFrequencies
end

function ChatMessage.ProcessMessage(player, args, packetType, sendError)
    if args.type == nil then
        error('error: YACM: Received a message from "' .. player:getUsername() .. '" with no type')
        return
    end
    if args.type == "faction" then
        if Faction.getPlayerFaction(player) == nil then
            if sendError then
                SendServer.ChatErrorMessage(player, args.type, 'you are not part of a faction.')
            end
            return
        end
    elseif args.type == 'safehouse' then
        if SafeHouse.hasSafehouse(player) == nil then
            if sendError then
                SendServer.ChatErrorMessage(player, args.type, 'you are not part of a safe house.')
            end
            return
        end
    elseif args.type == 'pm' then
        if args.target == nil or GetConnectedPlayer(args.target) == nil then
            if args.target ~= nil then
                if sendError then
                    SendServer.ChatErrorMessage(player, args.type, 'unknown player "' .. args.target .. '".')
                end
            else
                error('error: YACM: Received a private message from "' .. player:getUsername() .. '" without a contact.')
            end
            return
        end
    end
    local range = GetRangeForMessageType(args.type)
    if range == nil then
        error('error: YACM: No range for message type "' .. args.type .. '".')
        return
    end
    local radioEmission, radioFrequencies = GetEmittingRadios(player, packetType, args['type'], range)
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if IsAllowed(player, connectedPlayer, args)
        then
            if connectedPlayer:getOnlineID() == player:getOnlineID()
                or range == -1 or PlayersDistance(player, connectedPlayer) < range + 0.001
                or Character.AreInSameVehicle(player, connectedPlayer)
            then
                SendServer.Command(connectedPlayer, packetType, args)
            end
            if radioEmission then
                SendRadioPackets(player, connectedPlayer, args, radioFrequencies)
            end
        end
    end
end

Events.OnServerStarted.Add(SetMessageTypeSettings)

return ChatMessage
