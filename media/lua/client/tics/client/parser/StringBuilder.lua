local StringBuilder = {}

function StringBuilder.BuildAsteriskColorString(color)
    return '�*' .. color[1] .. ',' .. color[2] .. ',' .. color[3] .. '*�'
end

function StringBuilder.BuildBracketColorString(color)
    return '� <RGB:'
        .. string.format('%.3f', color[1] / 255) .. ','
        .. string.format('%.3f', color[2] / 255) .. ','
        .. string.format('%.3f', color[3] / 255) .. '> �'
end

function StringBuilder.GetCurrentFormatedTime(time)
    local ms = time
    local s = ms / 1000
    local m = s / 60
    local h = m / 60
    return string.format('%02d', h % 24) .. ':' .. string.format('%02d', m % 60) .. ':' .. string.format('%02d', s % 60)
end

function StringBuilder.BuildTimePrefixString(time)
    local formatedTime = StringBuilder.GetCurrentFormatedTime(time)
    return StringBuilder.BuildBracketColorString({ 130, 130, 130 }) .. formatedTime .. ' '
end

function StringBuilder.BuildFontSizeString(size)
    return '<SIZE:' .. size .. '>'
end

function StringBuilder.BuildNewLine()
    return ' <LINE> '
end

return StringBuilder
