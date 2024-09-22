local AvatarManager = {}

function AvatarManager:getKnownAvatars()
    local toDelete = {}
    local somethingToDelete = false
    local toSend = {}
    local avatars = ModData.getOrCreate("yacmAvatars")
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
        ModData.add("yacmAvatars", avatars)
    end
    return toSend
end

function AvatarManager:saveAvatar(username, extension, checksum, data)
    local avatars = ModData.getOrCreate("yacmAvatars")
    local serverName = getServerName()
    if serverName == nil then
        serverName = 'unknown'
        print('yacm error: saveAvatar: unknown server name, using "unknown" directory to save avatars')
    end
    local path = 'avatars/' .. serverName .. '/' .. getPlayer():getUsername() .. '/' .. username .. '.' .. extension
    local outFile = getFileOutput(path)
    if outFile == nil then
        print('yacm error: failed to open file in path: ' .. path)
        return
    end
    for _, byte in pairs(data) do
        outFile:writeByte(byte)
    end
    endFileOutput()
    avatars[username] = {
        path = path,
        checksum = checksum,
    }
    ModData.add("yacmAvatars", avatars)
    -- TODO: free texture if already loaded
end

function AvatarManager:getAvatar(username)
    local avatars = ModData.getOrCreate("yacmAvatars")
    local avatar = avatars[username]
    if avatar == nil then
        return nil
    end
    local path = avatar['path']
    if path == nil then
        return nil
    end
    local texture = getTextureFromSaveDir(path, '../Lua')
    if texture == nil then
        print('yacm error: failed to load the avatar for username "' .. username .. '", removing texture from cache')
        avatars[username] = nil
        ModData.add("yacmAvatars", avatars)
    end
    return texture
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
