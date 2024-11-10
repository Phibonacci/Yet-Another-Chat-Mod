local AvatarIO  = require('tics/shared/utils/AvatarIO')
local Character = require('tics/shared/utils/Character')
local File      = require('tics/shared/utils/File')


local AvatarManager = {}

function AvatarManager:getKnownAvatars()
    local toDelete = {}
    local somethingToDelete = false
    local toSend = {}
    local avatars = ModData.getOrCreate('ticsApprovedAvatars')
    for username, avatar in pairs(avatars) do
        local path = avatar['path']
        local checksum = avatar['checksum']
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
        ModData.add('ticsApprovedAvatars', avatars)
    end
    return toSend
end

function AvatarManager:createRequestDirectory()
    local player = getPlayer()
    local username = player:getUsername()
    local path = username .. '/request/'
    local directoryPath = AvatarIO.getBasePath() .. path
    File.createDirectory(directoryPath, 'move_your_avatar_here')
end

function AvatarManager:loadAvatarRequest()
    local player = getPlayer()
    local username = player:getUsername()
    local path = username .. '/request/'
    local directoryPath = AvatarIO.getBasePath() .. path
    File.createDirectory(directoryPath, 'move_your_avatar_here')
    local avatar = AvatarIO.loadPlayerAvatar(path, player)
    if avatar == nil then
        return nil
    end
    local firstName, lastName = Character.getFirstAndLastName(player)
    local knownAvatar = AvatarManager:getAvatarData(username, firstName, lastName)
    if knownAvatar and knownAvatar.checksum == avatar.checksum then
        return nil -- avatar already approved
    end
    return avatar
end

local function SaveAvatar(username, firstName, lastName, extension, checksum, data, directory, modDataPath)
    local avatars = ModData.getOrCreate(modDataPath)
    local path = getPlayer():getUsername() .. '/' .. directory
    local fullPath = AvatarIO.savePlayerAvatar(username, firstName, lastName, extension, data, path)
    local key = AvatarIO.createFileName(username, firstName, lastName)
    avatars[key] = {
        path = fullPath,
        checksum = checksum,
        username = username,
        firstName = firstName,
        lastName = lastName,
    }
    ModData.add(modDataPath, avatars)
    local texture = getTextureFromSaveDir(fullPath, '../Lua')
    if texture then
        Texture.reload(texture:getName())
    end
end

function AvatarManager:saveApprovedAvatar(username, firstName, lastName, extension, checksum, data)
    SaveAvatar(username, firstName, lastName, extension, checksum, data, '', 'ticsApprovedAvatars')
end

function AvatarManager:savePendingAvatar(username, firstName, lastName, extension, checksum, data)
    SaveAvatar(username, firstName, lastName, extension, checksum, data, 'pending', 'ticsPendingAvatars')
end

function AvatarManager:getPendingAvatarData(username, firstName, lastName)
    local avatars = ModData.getOrCreate('ticsPendingAvatars')
    local key = AvatarIO.createFileName(username, firstName, lastName)
    return avatars[key]
end

function AvatarManager:getAvatarData(username, firstName, lastName)
    local avatars = ModData.getOrCreate('ticsApprovedAvatars')
    local key = AvatarIO.createFileName(username, firstName, lastName)
    if avatars[key] and not File.exists(avatars[key]['path']) then
        avatars[key] = nil
        ModData.add("ticsApprovedAvatars", avatars)
    end
    return avatars[key]
end

function AvatarManager:removeAvatarData(username, firstName, lastName)
    local avatars = ModData.getOrCreate('ticsApprovedAvatars')
    local key = AvatarIO.createFileName(username, firstName, lastName)
    avatars[key] = nil
    ModData.add("ticsApprovedAvatars", avatars)
end

function AvatarManager:getRequestAvatar()
    local player = getPlayer()
    local username = player:getUsername()
    local firstName, lastName = Character.getFirstAndLastName(player)
    local fileName = AvatarIO.createFileName(username, firstName, lastName)
    local path = AvatarIO.getAvatarPath(username .. '/request/' .. fileName)
    if path == nil then
        return nil
    end
    local texture = getTextureFromSaveDir(path, '../Lua')
    if texture == nil then
        print('TICS error: failed to load the request avatar for username "'
            .. username .. '" with character named "'
            .. firstName .. ' ' .. lastName .. '"')
    end
    return texture
end

function AvatarManager:getAvatar(username, firstName, lastName)
    local avatar = self:getAvatarData(username, firstName, lastName)
    if avatar == nil then
        return nil
    end
    local path = avatar['path']
    if path == nil then
        print('TICS error: AvatarManager:getAvatar: avatar path is null')
        return nil
    end
    local texture = getTextureFromSaveDir(path, '../Lua')
    if texture == nil then
        print('TICS error: failed to load the avatar for username "'
            .. username .. '" with character named "'
            .. firstName .. ' ' .. lastName .. '", removing texture from cache')
        self:removeAvatarData(username, firstName, lastName)
    end
    return texture
end

function AvatarManager:removeAvatarPending(username, firstName, lastName, checksum)
    assert(type(username) == 'string', 'TICS error: rejectAvatar: missing username')
    assert(type(firstName) == 'string', 'TICS error: rejectAvatar: missing firstName')
    assert(type(lastName) == 'string', 'TICS error: rejectAvatar: missing lastName')
    assert(type(checksum) == 'number', 'TICS error: rejectAvatar: missing checksum')
    local key = AvatarIO.createFileName(username, firstName, lastName)
    local avatars = ModData.getOrCreate('ticsPendingAvatars')
    if avatars[key] ~= nil and avatars[key]['checksum'] == checksum then
        local path = avatars[key]['path']
        assert(type(path) == 'string', 'TICS error: removeAvatarPending: avatar path not found for username "'
            .. username .. '" with character named "'
            .. firstName .. ' ' .. lastName .. '"')
        avatars[key] = nil
        ModData.add("ticsPendingAvatars", avatars)
        File.remove(path)
    end
end

function AvatarManager:isPendingAvatarAlive(username, firstName, lastName, checksum)
    assert(type(username) == 'string', 'TICS error: rejectAvatar: missing username')
    assert(type(firstName) == 'string', 'TICS error: rejectAvatar: missing firstName')
    assert(type(lastName) == 'string', 'TICS error: rejectAvatar: missing lastName')
    assert(type(checksum) == 'number', 'TICS error: rejectAvatar: missing checksum')
    local avatar = self:getPendingAvatarData(username, firstName, lastName)
    return avatar ~= nil and avatar['checksum'] == checksum
end

function AvatarManager:getFirstAvatarPending()
    local avatars = ModData.getOrCreate('ticsPendingAvatars')
    local toRemove = {}
    local avatarResult = nil
    for key, avatar in pairs(avatars) do
        local path = avatar['path']
        local texture = getTextureFromSaveDir(path, '../Lua')
        local checksum = avatar['checksum']
        local username = avatar['username']
        local firstName = avatar['firstName']
        local lastName = avatar['lastName']
        if path == nil then
            print('TICS error: no path set for unapproved avatar "' .. key .. '", removing avatar from cache')
            table.insert(toRemove, key)
        elseif texture == nil then
            print('TICS error: failed to load the unapproved avatar texture for "' ..
                key .. '" at "' .. path .. '", removing texture from cache')
            table.insert(toRemove, key)
        elseif checksum == nil then
            print('TICS error: failed to load the unapproved avatar checksum for "' ..
                key .. '", removing texture from cache')
            table.insert(toRemove, key)
        elseif username == nil then
            print('TICS error: failed to load the unapproved avatar username for "' ..
                key .. '", removing texture from cache')
            table.insert(toRemove, key)
        elseif firstName == nil then
            print('TICS error: failed to load the unapproved avatar first name for "' ..
                key .. '", removing texture from cache')
            table.insert(toRemove, key)
        elseif lastName == nil then
            print('TICS error: failed to load the unapproved avatar last name for "' ..
                key .. '", removing texture from cache')
            table.insert(toRemove, key)
        else
            avatarResult = {
                username  = username,
                texture   = texture,
                checksum  = checksum,
                firstName = firstName,
                lastName  = lastName,
            }
            break
        end
    end
    for _, key in pairs(toRemove) do
        avatars[key] = nil
        ModData.add("ticsPendingAvatars", avatars)
    end
    return avatarResult
end

function AvatarManager:getAvatarsPending()
    local avatars = ModData.getOrCreate('ticsPendingAvatars')
    local avatarsToApprove = {}
    local count = 0
    local toRemove = {}
    for key, avatar in pairs(avatars) do
        local path = avatar['path']
        local texture = getTextureFromSaveDir(path, '../Lua')
        local checksum = avatar['checksum']
        local username = avatar['username']
        local firstName = avatar['firstName']
        local lastName = avatar['lastName']
        if path == nil then
            print('TICS error: no path set for unapproved avatar "' .. key .. '", removing avatar from cache')
            table.insert(toRemove, key)
        elseif texture == nil then
            print('TICS error: failed to load the unapproved avatar texture for "' ..
                key .. '" at "' .. path .. '", removing texture from cache')
            table.insert(toRemove, key)
        elseif checksum == nil then
            print('TICS error: failed to load the unapproved avatar checksum for "' ..
                key .. '", removing texture from cache')
            table.insert(toRemove, key)
        elseif username == nil then
            print('TICS error: failed to load the unapproved avatar username for "' ..
                key .. '", removing texture from cache')
            table.insert(toRemove, key)
        elseif firstName == nil then
            print('TICS error: failed to load the unapproved avatar first name for "' ..
                key .. '", removing texture from cache')
            table.insert(toRemove, key)
        elseif lastName == nil then
            print('TICS error: failed to load the unapproved avatar last name for "' ..
                key .. '", removing texture from cache')
            table.insert(toRemove, key)
        else
            table.insert(avatarsToApprove, {
                username  = username,
                texture   = texture,
                checksum  = checksum,
                firstName = firstName,
                lastName  = lastName,
            })
            count = count + 1
        end
    end
    for _, key in pairs(toRemove) do
        avatars[key] = nil
        ModData.add("ticsPendingAvatars", avatars)
    end
    return avatarsToApprove, count
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
