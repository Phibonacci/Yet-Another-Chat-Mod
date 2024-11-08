local Character = require('yacm/shared/utils/Character')
local File = require('yacm/shared/utils/File')


local AvatarIO = {}

function AvatarIO.getBasePath()
    if isClient() then
        -- a client does not know the server name...
        return 'avatars/client/' .. getServerIP() .. '/'
    else
        local serverName = getServerName()
        if serverName == nil then
            serverName = 'unknown'
            print('yacm error: AvatarIO: unknown server name, using "unknown" directory for avatars')
        end
        return 'avatars/server/' .. serverName .. '/'
    end
end

function AvatarIO.getAvatarPath(partialPath)
    local basePath = AvatarIO.getBasePath()
    local pathPrefix = basePath .. '/' .. partialPath .. '.'
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

function AvatarIO.createFileName(username, firstName, lastName)
    return username .. '_' .. firstName .. '_' .. lastName
end

function AvatarIO.createFileNameFromPlayer(player)
    local username = player:getUsername()
    local firstName, lastName = Character.getFirstAndLastName(player)
    return AvatarIO.createFileName(username, firstName, lastName)
end

function AvatarIO.loadPlayerAvatarFromNames(path, username, firstName, lastName)
    local key = AvatarIO.createFileName(username, firstName, lastName)
    local partialPath = path .. '/' .. key
    print('yacm info: load avatar for "' .. partialPath .. '"')
    local fullPath, extension = AvatarIO.getAvatarPath(partialPath)
    if fullPath == nil then
        return
    end
    local data, checksum = File.readAllBytes(fullPath)
    if data == nil or checksum == nil then
        print('yacm error: failed to read file at path: "' .. fullPath .. '"')
        return
    end
    return {
        data = data,
        checksum = checksum:tonumber(),
        extension = extension,
        username = username,
        firstName = firstName,
        lastName = lastName,
    }
end

function AvatarIO.loadPlayerAvatar(path, player)
    local username = player:getUsername()
    local firstName, lastName = Character.getFirstAndLastName(player)
    return AvatarIO.loadPlayerAvatarFromNames(path, username, firstName, lastName)
end

function AvatarIO.savePlayerAvatar(username, firstName, lastName, extension, data, path)
    local basePath = AvatarIO.getBasePath()
    local fileName = AvatarIO.createFileName(username, firstName, lastName)
    local fullPath = basePath .. '/' .. path .. '/' .. fileName .. '.' .. extension
    File.writeAllBytes(data, fullPath)
    return fullPath
end

return AvatarIO
