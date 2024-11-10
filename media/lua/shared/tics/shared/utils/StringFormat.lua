local StringFormat = {}

function StringFormat.color(color)
    return color[1] .. ', ' .. color[2] .. ', ' .. color[3]
end

return StringFormat
