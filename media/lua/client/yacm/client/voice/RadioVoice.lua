local AVoice = require('yacm/client/voice/Avoice')

local RadioVoice = {}

function RadioVoice:new(message, object)
    RadioVoice.__index = self
    setmetatable(RadioVoice, { __index = AVoice })
    local o = AVoice:new(message, object, 'Voice1Radio')
    setmetatable(o, RadioVoice)
    return o
end

return RadioVoice
