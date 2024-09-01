local AVoice = require('yacm/client/voice/AVoice')

local RadioVoice = {}

function RadioVoice:new(message, object, voicePitch)
    RadioVoice.__index = self
    setmetatable(RadioVoice, { __index = AVoice })
    local o = AVoice:new(message, object, 'Voice1Radio', voicePitch)
    setmetatable(o, RadioVoice)
    return o
end

return RadioVoice
