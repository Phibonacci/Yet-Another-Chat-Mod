local YacmClientSendCommands = require('yacm/client/network/SendYacmClient')

function ISRadioAction:performMuteMicrophone()
    if self:isValidMuteMicrophone() then
        YacmClientSendCommands.sendMuteRadio(
            self.device, self.secondaryItem)
    end
end
