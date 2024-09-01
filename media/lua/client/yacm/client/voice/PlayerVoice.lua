local AVoice = require('yacm/client/voice/AVoice')

local PlayerVoice = {}

function PlayerVoice:new(message, object, voicePitch)
    PlayerVoice.__index = self
    setmetatable(PlayerVoice, { __index = AVoice })
    local o = AVoice:new(message, object, 'Voice1Player', voicePitch)
    setmetatable(o, PlayerVoice)
    return o
end

return PlayerVoice
