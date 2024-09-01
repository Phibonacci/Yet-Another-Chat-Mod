local YacmClientSendCommands = require('yacm/client/network/SendYacmClient')

local DefaultISRadioWindowActivate = ISRadioWindow.activate

function ISRadioWindow.activate(_player, _deviceObject)
    local radio = _deviceObject
    YacmClientSendCommands.sendAskRadioState(radio)

    return DefaultISRadioWindowActivate(_player, _deviceObject)
end
