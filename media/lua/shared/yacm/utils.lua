local utils = {}

function utils.hexaToRGB(hexa)
    local regex = '#[abcdefABCDEF%d][abcdefABCDEF%d][abcdefABCDEF%d][abcdefABCDEF%d][abcdefABCDEF%d][abcdefABCDEF%d]'
    if hexa == nil or #hexa ~= 7
        or hexa:match(regex) == nil
    then
        return nil
    end
    return {
        tonumber(hexa:sub(2, 3), 16),
        tonumber(hexa:sub(4, 5), 16),
        tonumber(hexa:sub(6, 7), 16),
    }
end

return utils
