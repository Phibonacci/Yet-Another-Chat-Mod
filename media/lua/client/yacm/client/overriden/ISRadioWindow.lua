local Character              = require('yacm/shared/utils/Character')
local YacmClientSendCommands = require('yacm/client/network/SendYacmClient')


local DefaultISRadioWindowActivate = ISRadioWindow.activate

function ISRadioWindow.activate(_player, _deviceObject)
    -- a belt item is not sync with the server, so we need to tell it everything
    if Character.isItemOnBeltAndNotInHand(getPlayer(), _deviceObject) then
        YacmClientSendCommands.sendGiveRadioState(_deviceObject)
    else
        YacmClientSendCommands.sendAskRadioState(_deviceObject)
    end
    return DefaultISRadioWindowActivate(_player, _deviceObject)
end

local DefaultISRadioWindowUpdate = ISRadioWindow.update

local dist = 10
function ISRadioWindow:update()
    if self:getIsVisible() then
        if self.deviceType and self.device and self.player and self.deviceData then
            if self.deviceType == 'InventoryItem' then -- incase of inventory item check if player has it on belt
                if self.device:getAttachedSlot() ~= -1 then
                    ISCollapsableWindow.update(self)
                    return
                end
            end
        end
    end
    DefaultISRadioWindowUpdate(self)
end
