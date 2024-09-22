local CRC32 = require('yacm/shared/libs/crc32/crc32')


local World      = require('yacm/shared/utils/World')
local SendServer = require('yacm/server/network/SendServer')


local AvatarManager = {}

local function GetAvatarPath(username)
    local pathPrefix = 'avatars/' .. username .. '.'
    local extension = 'png'
    local path = pathPrefix .. extension
    if not serverFileExists('../Lua/' .. path) then
        extension = 'jpg'
        path = pathPrefix .. extension
        if not serverFileExists('../Lua/' .. path) then
            extension = 'jpeg'
            path = pathPrefix .. extension
            if not serverFileExists('../Lua/' .. path) then
                return nil
            end
        end
    end
    return path, extension
end

function AvatarManager:loadPlayerAvatar(username)
    print('load avatar for ' .. username)
    local path, extension = GetAvatarPath(username)
    if path == nil then
        print('no file')
        return
    end
    local file = getFileInput(path)
    if file == nil then
        print('yacm error: could not read avatar file at :"' .. path .. '"')
        return
    end
    local data = {}
    local checksum = CRC32.newcrc32()
    print('yacm info: ignore the InvocationTargetException in AvatarManager below, it means the file has been read')
    while true do
        local byte = file:readUnsignedByte()
        -- an exception will be thrown, it's unavoidable unless we know the size of the file
        -- and I am not writing my own PNG/JPEG parser to avoid it
        -- the exception does not stop the execution flow
        if byte == nil then
            print(
                'yacm info: ignore the InvocationTargetException in AvatarManager above, it means the file has been read')
            break
        end
        checksum:update(byte)
        table.insert(data, byte)
    end
    endFileInput()
    print('avatar is stored, checksum is ' .. checksum:tonumber())
    self.avatars[username] = {
        data = data,
        checksum = checksum:tonumber(),
        extension = extension,
    }
end

function AvatarManager:freePlayerAvatar(username)
    print('free ' .. username .. ' avatar')
    self.avatars[username] = nil
end

function AvatarManager:registerPlayerAvatars(player, avatars)
    print('register ' .. player:getUsername() .. ' known avatars')
    for username, checksum in pairs(avatars) do
        print(username .. ': ' .. checksum)
    end
    self.players[player:getUsername()] = avatars
end

function AvatarManager:trackPlayersOnline()
    local newConnecterPlayers = {}
    World.forAllPlayers(
        function(player)
            local username = player:getUsername()
            if not self.connectedPlayers[username] then
                self:loadPlayerAvatar(username)
            end
            newConnecterPlayers[username] = player
        end
    )
    for username, _ in pairs(self.connectedPlayers) do
        if newConnecterPlayers[username] == nil then
            self:freePlayerAvatar(username)
        end
    end
    self.connectedPlayers = newConnecterPlayers
end

function AvatarManager:sendAvatars()
    for playerUsername, playerAvatars in pairs(self.players) do
        for avatarUsername, avatar in pairs(self.avatars) do
            local storedAvatarChecksum = avatar['checksum']
            local playerAvatarChecksum = playerAvatars[avatarUsername]
            if playerAvatarChecksum ~= storedAvatarChecksum then
                if playerAvatarChecksum ~= nil then
                    print('stored checksum for avatar ' .. avatarUsername .. ' is ' .. storedAvatarChecksum
                        .. ' but ' .. playerUsername .. ' has ' .. playerAvatarChecksum)
                else
                    print('unknown avatar ' .. avatarUsername)
                end
                local player = self.connectedPlayers[playerUsername]
                if player ~= nil then
                    print('send avatar ' .. avatarUsername .. ' to ' .. player:getUsername())
                    SendServer.Avatar(player, avatarUsername, storedAvatarChecksum, avatar['data'], avatar['extension'])
                    playerAvatars[avatarUsername] = storedAvatarChecksum
                else
                    print('yacm error: sendAvatars: player not found: ' .. playerUsername)
                    break
                end
            end
        end
    end
end

function AvatarManager:update()
    local currentTime = Calendar.getInstance():getTimeInMillis()
    local elapsed = currentTime - self.previousTime
    if elapsed < 500 then
        return
    end
    self:trackPlayersOnline()
    self:sendAvatars()
    self.previousTime = currentTime
end

local function CreateAvatarManager()
    local o = {}
    setmetatable(o, AvatarManager)
    AvatarManager.__index = AvatarManager
    o.players = {}
    o.avatars = {}
    o.connectedPlayers = {}
    o.previousTime = 0
    return o
end

local instance = CreateAvatarManager()

if not isClient() then
    Events.OnTick.Add(function() instance:update() end)
end

-- Since a lua file is only read once, this file will always return the same
-- value. Making this a singleton that cannot be missused.
return instance
