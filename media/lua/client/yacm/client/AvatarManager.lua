local AvatarIO = require('yacm/shared/utils/AvatarIO')
local Character = require('yacm/shared/utils/Character')

local AvatarManager = {}

function AvatarManager:getKnownAvatars()
    local toDelete = {}
    local somethingToDelete = false
    local toSend = {}
    local avatars = ModData.getOrCreate('yacmAvatars')
    for username, avatar in pairs(avatars) do
        local path = avatar['path']
        local checksum = avatar['checksum']
        print(username .. ': ' .. checksum .. ' at path: ' .. path)
        if path == nil or checksum == nil or not serverFileExists('../Lua/' .. avatar['path']) then
            table.insert(toDelete, username)
            somethingToDelete = true
        else
            toSend[username] = checksum
        end
    end
    if somethingToDelete then
        for _, username in pairs(toDelete) do
            avatars[username] = nil
        end
        ModData.add('yacmAvatars', avatars)
    end
    return toSend
end

function AvatarManager:loadAvatarRequest()
    local player = getPlayer()
    local username = player:getUsername()
    local path = username .. '/request/'
    local avatar = AvatarIO.loadPlayerAvatar(path, player)
    if avatar == nil then -- to make it clear this can be nil
        return nil
    end
    local firstName, lastName = Character.getFirstAndLastName(player)
    local knownAvatar = AvatarManager:getAvatarData(username, firstName, lastName)
    if knownAvatar and knownAvatar.checksum == avatar.checksum then
        return nil -- avatar already validated
    end
    return avatar
end

local function SaveAvatar(username, firstName, lastName, extension, checksum, data, directory, modDataPath)
    local avatars = ModData.getOrCreate(modDataPath)
    local path = getPlayer():getUsername() .. '/' .. directory
    AvatarIO.savePlayerAvatar(username, firstName, lastName, extension, data, path)
    local key = AvatarIO.createFileName(username, firstName, lastName)
    avatars[key] = {
        path = path,
        checksum = checksum,
        username = username,
        firstName = firstName,
        lastName = lastName,
    }
    ModData.add(modDataPath, avatars)
    -- TODO: free texture if already loaded
end

function AvatarManager:saveApprovedAvatar(username, firstName, lastName, extension, checksum, data)
    SaveAvatar(username, extension, checksum, data, '', 'yacmApprovedAvatars')
end

function AvatarManager:savePendingAvatar(username, firstName, lastName, extension, checksum, data)
    SaveAvatar(username, extension, checksum, data, 'pending', 'yacmPendingAvatars')
end

function AvatarManager:getAvatarData(username, firstName, lastName)
    local avatars = ModData.getOrCreate('yacmApprovedAvatars')
    local key = AvatarIO.createFileName(username, firstName, lastName)
    return avatars[key]
end

function AvatarManager:removeAvatarData(username, firstName, lastName)
    local avatars = ModData.getOrCreate('yacmApprovedAvatars')
    local key = AvatarIO.createFileName(username, firstName, lastName)
    avatars[key] = nil
end

function AvatarManager:getAvatar(username, firstName, lastName)
    local avatar = self:getAvatarData(username, firstName, lastName)
    if avatar == nil then
        print('no avatar found for ' .. username)
        return nil
    end
    local path = avatar['path']
    if path == nil then
        print('yacm error: AvatarManager:getAvatar: avatar path is null')
        return nil
    end
    print('found avatar with path ' .. path)
    local texture = getTextureFromSaveDir(path, '../Lua')
    if texture == nil then
        print('yacm error: failed to load the avatar for username "'
            .. username .. '" with character named "'
            .. firstName .. ' ' .. lastName .. '", removing texture from cache')
        self:removeAvatarData(username, firstName, lastName)
    end
    return texture
end

function AvatarManager:getAvatarsPending()
    local avatars = ModData.getOrCreate('yacmPendingAvatars')
    local avatarsToValidate = {}
    local count = 0
    local toRemove = {}
    for key, avatar in pairs(avatars) do
        local path = avatar['path']
        if path == nil then
            print('yacm error: no path set for unvalidated avatar "' .. key .. '", removing avatar from cache')
            table.insert(toRemove, key)
            break
        end
        local texture = getTextureFromSaveDir(path, '../Lua')
        if texture == nil then
            print('yacm error: failed to load the unvalidated avatar for "' ..
                key .. '", removing texture from cache')
            table.insert(toRemove, key)
            break
        end
        local checksum = avatar['checksum']
        if checksum == nil then
            print('yacm error: failed to load the unvalidated checksum avatar for "' ..
                key .. '", removing texture from cache')
            table.insert(toRemove, key)
            break
        end
        local username = avatar['username']
        if username == nil then
            print('yacm error: failed to load the unvalidated username avatar for "' ..
                key .. '", removing texture from cache')
            table.insert(toRemove, key)
            break
        end
        local firstName = avatar['firstName']
        if checksum == nil then
            print('yacm error: failed to load the unvalidated avatar first name for "' ..
                key .. '", removing texture from cache')
            table.insert(toRemove, key)
            break
        end
        local lastName = avatar['lastName']
        if checksum == nil then
            print('yacm error: failed to load the unvalidated avatar last name for "' ..
                key .. '", removing texture from cache')
            table.insert(toRemove, key)
            break
        end
        table.insert(avatarsToValidate, {
            username  = username,
            texture   = texture,
            checksum  = checksum,
            firstName = firstName,
            lastName  = lastName,
        })
        count = count + 1
    end
    for _, username in pairs(toRemove) do
        avatars[username] = nil
        ModData.add("yacmPendingAvatars", avatars)
    end
    return avatarsToValidate, count
end

local function CreateAvatarManager()
    local o = {}
    setmetatable(o, AvatarManager)
    AvatarManager.__index = AvatarManager
    return o
end

local instance = CreateAvatarManager()

-- Since a lua file is only read once, this file will always return the same
-- value. Making this a singleton that cannot be missused.
return instance
