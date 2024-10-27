local AvatarIO   = require('yacm/shared/utils/AvatarIO')
local SendServer = require('yacm/server/network/SendServer')
local World      = require('yacm/shared/utils/World')


local AvatarManager = {}

function AvatarManager:loadPlayerAvatar(player)
    local avatar = AvatarIO.loadPlayerAvatar('approved', player)
    if avatar == nil then -- just to make it clear
        return nil
    end
    local key = AvatarIO.createFileNameFromPlayer(player)
    self.avatars[key] = avatar
end

function AvatarManager:freePlayerAvatar(player)
    print('free ' .. player:getUsername() .. ' avatar')
    local key = AvatarIO.createFileNameFromPlayer(player)
    self.avatars[key] = nil
end

function AvatarManager:registerPlayerAvatars(player, avatars)
    print('register ' .. player:getUsername() .. ' known avatars')
    if self.players[player:getUsername()] == nil then
        self.players[player:getUsername()] = {}
    end
    self.players[player:getUsername()]['validated'] = avatars
    if self.players[player:getUsername()]['pending'] == nil then
        self.players[player:getUsername()]['pending'] = {}
    end
end

function AvatarManager:loadPendingAvatarsData()
    if self.pendingAvatarsStored == nil then
        self.pendingAvatarsStored = ModData.getOrCreate('yacmPendingAvatars')
    end
end

function AvatarManager:loadPendingAvatar(key, avatar)
    local username = avatar['username']
    local firstName = avatar['firstName']
    local lastName = avatar['lastName']
    local checksum = avatar['checksum']
    local extension = avatar['extension']
    local avatarBytes = AvatarIO.loadPlayerAvatarFromNames('pending', username, firstName, lastName)
    if avatarBytes ~= nil then
        self.pendingAvatarsShared[key] = {
            data = avatarBytes,
            checksum = checksum,
            username = username,
            firstName = firstName,
            lastName = lastName,
            extension = extension,
        }
    end
end

function AvatarManager:loadPendingAvatars()
    if self.pendingAvatarsStored == nil then
        AvatarManager:loadPendingAvatarsData()
    end
    for key, avatar in pairs(self.pendingAvatarsStored) do
        self:loadPendingAvatar(key, avatar)
    end
end

function AvatarManager:trackPlayersOnline()
    local newConnectedPlayers = {}
    World.forAllPlayers(
        function(player)
            local username = player:getUsername()
            if not self.connectedPlayers[username] then
                self:loadPlayerAvatar(player)
            end
            newConnectedPlayers[username] = player
        end
    )
    for username, player in pairs(self.connectedPlayers) do
        if newConnectedPlayers[username] == nil then
            self:freePlayerAvatar(player)
        end
    end
    self.connectedPlayers = newConnectedPlayers
end

function AvatarManager:sendValidatedAvatars(playerUsername, playerAvatars)
    for key, avatar in pairs(self.avatars) do
        local storedAvatarChecksum = avatar['checksum']
        local playerAvatarChecksum = playerAvatars[key]
        if playerAvatarChecksum ~= storedAvatarChecksum then
            if playerAvatarChecksum ~= nil then
                print('stored checksum for avatar ' .. key .. ' is ' .. storedAvatarChecksum
                    .. ' but ' .. playerUsername .. ' has ' .. playerAvatarChecksum)
            else
                print('unknown avatar ' .. key)
            end
            local player = self.connectedPlayers[playerUsername]
            if player ~= nil then
                print('send avatar ' .. key .. ' to ' .. player:getUsername())
                SendServer.Avatar(player, key, storedAvatarChecksum, avatar['data'], avatar['extension'])
                playerAvatars[key] = storedAvatarChecksum
            else
                print('yacm error: sendAvatars: player not found: ' .. playerUsername)
                break
            end
        end
    end
end

function AvatarManager:sendPendingAvatars(playerUsername, playerAvatars)
    for key, avatar in pairs(self.avatars) do
        local storedAvatarChecksum = avatar['checksum']
        local playerAvatarChecksum = playerAvatars[key]
        if playerAvatarChecksum ~= storedAvatarChecksum then
            if playerAvatarChecksum ~= nil then
                print('stored checksum for avatar ' .. key .. ' is ' .. storedAvatarChecksum
                    .. ' but ' .. playerUsername .. ' has ' .. playerAvatarChecksum)
            else
                print('unknown avatar ' .. key)
            end
            local player = self.connectedPlayers[playerUsername]
            if player ~= nil then
                print('send avatar ' .. key .. ' to ' .. player:getUsername())
                SendServer.Avatar(player, key, storedAvatarChecksum, avatar['data'], avatar['extension'])
                playerAvatars[key] = storedAvatarChecksum
            else
                print('yacm error: sendAvatars: player not found: ' .. playerUsername)
                break
            end
        end
    end
end

function AvatarManager:sendAvatars()
    for playerUsername, playerAvatarCategories in pairs(self.players) do
        local validatedAvatars = playerAvatarCategories['validated']
        local pendingAvatars = playerAvatarCategories['pending']
        self:sendValidatedAvatars(playerUsername, validatedAvatars)
        self:sendPendingAvatars(playerUsername, pendingAvatars)
    end
end

-- we could additionally store the data in a table directly, but we could not
-- guarantee the image was successfully saved
function AvatarManager:registerAvatarRequest(username, firstName, lastName, extension, checksum, data)
    if self.pendingAvatarsStored == nil then
        AvatarManager:loadPendingAvatarsData()
    end
    local avatars = ModData.getOrCreate('yacmPendingAvatars')
    local path = '/pending'
    AvatarIO.savePlayerAvatar(username, firstName, lastName, extension, data, path)
    local key = AvatarIO.createFileName(username, firstName, lastName)
    local pendingAvatarInfo = {
        path = path,
        checksum = checksum,
        username = username,
        firstName = firstName,
        lastName = lastName,
        extension = extension,
    }
    avatars[key] = pendingAvatarInfo
    ModData.add('yacmPendingAvatars', avatars)
    self.pendingAvatarsStored[key] = pendingAvatarInfo
    self:loadPendingAvatar(key, pendingAvatarInfo)
end

function AvatarManager:update()
    local currentTime = Calendar.getInstance():getTimeInMillis()
    local elapsed = currentTime - self.previousTime
    if elapsed < 500 then
        return
    end
    self:loadPendingAvatars()
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
    o.pendingAvatarsStored = nil
    o.pendingAvatarsShared = nil
    o.pendingAvatarToLoad = {}
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
