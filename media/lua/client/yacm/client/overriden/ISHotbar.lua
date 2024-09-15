-- There is an ISRadioWindow.instances already but it only remembers the last
-- opened window, while multiple windows could be opened at the same time
local openedHotbarRadioWindows = {}
local vanillaEquipItem = ISHotbar.equipItem
function ISHotbar:equipItem(item)
    if instanceof(item, "Radio") then
        local openedWindow = openedHotbarRadioWindows[item:getID()]
        if openedWindow then
            openedWindow:close()
            openedHotbarRadioWindows[item:getID()] = nil
        else
            local window = ISRadioWindow.activate(getPlayer(), item)
            openedHotbarRadioWindows[item:getID()] = window
        end
    else
        vanillaEquipItem(self, item)
    end
end
