local AVoice = require('yacm/client/voice/Avoice')

local PlayerVoice = {}

function PlayerVoice:new(message, object)
    PlayerVoice.__index = self
    setmetatable(PlayerVoice, { __index = AVoice })
    local o = AVoice:new(message, object, 'Voice1Player')
    setmetatable(o, PlayerVoice)
    return o
end

return PlayerVoice
