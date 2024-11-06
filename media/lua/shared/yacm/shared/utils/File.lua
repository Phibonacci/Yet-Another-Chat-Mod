local CRC32 = require('yacm/shared/libs/crc32/crc32')


local File = {}

function File.createDirectory(path, fileName)
    -- create useless file to ensure the directory is created
    local fullPath
    if fileName then
        fullPath = path .. '/' .. fileName
    else
        fullPath = path .. '/delete_me'
    end
    if serverFileExists('../Lua/' .. fullPath) then
        return
    end
    getFileOutput(fullPath)
    endFileOutput()
end

function File.readAllBytes(path)
    if path == nil then
        print('yacm error: File.readAllBytes: path is nil')
        return
    end
    local file = getFileInput(path)
    if file == nil then
        print('yacm error: File.readAllBytes: could not read avatar file at :"' .. path .. '"')
        return
    end
    local data = {}
    local checksum = CRC32.newcrc32()
    print(
        'yacm info: File.readAllBytes: ignore the InvocationTargetException below, it means the file has been read')
    while true do
        local byte = file:readUnsignedByte()
        -- an exception will be thrown, it's unavoidable unless we know the size of the file
        -- and I am not writing my own PNG/JPEG parser to avoid it
        -- the exception does not stop the execution flow
        if byte == nil then
            print(
                'yacm info: File.readAllBytes: ignore the InvocationTargetException above, it means the file has been read')
            break
        end
        checksum:update(byte)
        table.insert(data, byte)
    end
    endFileInput()
    return data, checksum
end

function File.writeAllBytes(data, path)
    local outFile = getFileOutput(path)
    if outFile == nil then
        print('yacm error: File.writeAllBytes: failed to write file in path: ' .. path)
        return
    end
    for _, byte in pairs(data) do
        outFile:writeByte(byte)
    end
    endFileOutput()
end

function File.remove(path) -- we can only erase the bytes of the file, not the file
    File.writeAllBytes({}, path)
end

return File
