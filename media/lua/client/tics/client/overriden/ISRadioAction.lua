local Character              = require('tics/shared/utils/Character')
local TicsClientSendCommands = require('tics/client/network/ClientSend')

-- mute was not sync at all with the server so we do it there
function ISRadioAction:performMuteMicrophone()
    if self:isValidMuteMicrophone() then
        -- a belt item is not sync with the server, so we need to tell it everything
        if Character.isItemOnBeltAndNotInHand(getPlayer(), self.device) then
            self.deviceData:setMicIsMuted(self.secondaryItem)
            TicsClientSendCommands.sendGiveRadioState(self.device)
        else
            TicsClientSendCommands.sendMuteRadio(
                self.device, self.secondaryItem)
        end
    end
end

-- a belt item is not sync with the server, so we need to tell it everything
local defaultPerformToggleOnOff = ISRadioAction.performToggleOnOff
function ISRadioAction:performToggleOnOff()
    defaultPerformToggleOnOff(self)
    if Character.isItemOnBeltAndNotInHand(getPlayer(), self.device) then
        TicsClientSendCommands.sendGiveRadioState(self.device)
    end
end

local defaultPerformSetVolume = ISRadioAction.performSetVolume
function ISRadioAction:performSetVolume()
    defaultPerformSetVolume(self)
    if Character.isItemOnBeltAndNotInHand(getPlayer(), self.device) then
        TicsClientSendCommands.sendGiveRadioState(self.device)
    end
end

local defaultPerformRemoveHeadphones = ISRadioAction.performRemoveHeadphones
function ISRadioAction:performRemoveHeadphones()
    defaultPerformRemoveHeadphones(self)
    if Character.isItemOnBeltAndNotInHand(getPlayer(), self.device) then
        TicsClientSendCommands.sendGiveRadioState(self.device)
    end
end

local defaultPerformAddHeadphones = ISRadioAction.performAddHeadphones
function ISRadioAction:performAddHeadphones()
    defaultPerformAddHeadphones(self)
    if Character.isItemOnBeltAndNotInHand(getPlayer(), self.device) then
        TicsClientSendCommands.sendGiveRadioState(self.device)
    end
end

local defaultPerformRemoveBattery = ISRadioAction.performRemoveBattery
function ISRadioAction:performRemoveBattery()
    defaultPerformRemoveBattery(self)
    if Character.isItemOnBeltAndNotInHand(getPlayer(), self.device) then
        -- when removing the battery the device is not turned on if not synced (belt is not synced)
        if self.deviceData:getIsTurnedOn() then
            defaultPerformToggleOnOff(self)
        end
        TicsClientSendCommands.sendGiveRadioState(self.device)
    end
end

local defaultPerformAddBattery = ISRadioAction.performAddBattery
function ISRadioAction:performAddBattery()
    defaultPerformAddBattery(self)
    if Character.isItemOnBeltAndNotInHand(getPlayer(), self.device) then
        TicsClientSendCommands.sendGiveRadioState(self.device)
    end
end

local defaultPerformSetChannel = ISRadioAction.performSetChannel
function ISRadioAction:performSetChannel()
    defaultPerformSetChannel(self)
    if Character.isItemOnBeltAndNotInHand(getPlayer(), self.device) then
        TicsClientSendCommands.sendGiveRadioState(self.device)
    end
end
