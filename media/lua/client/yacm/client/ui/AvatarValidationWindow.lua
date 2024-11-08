require('ISUI/ISCollapsableWindow')


local AvatarManager = require('yacm/client/AvatarManager')
local SendYacmClient = require('yacm/client/network/SendYacmClient')


local AvatarValidationWindow = ISCollapsableWindow:derive('AvatarValidationWindow')


local FONT_HGT_NORMAL = getTextManager():getFontHeight(UIFont.Normal)
local lineSpace = 2
local textHeight = (FONT_HGT_NORMAL + lineSpace) * 2
local avatarCellWidth = 100
local avatarCellHeight = 120 + textHeight
local leftMargin = 2
local rightMargin = leftMargin
local topMargin = 2
local bottomMargin = 2
local function CalculateCoordinatesAndSize()
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    local width = avatarCellWidth + leftMargin + rightMargin
    local height = avatarCellHeight + topMargin + bottomMargin
    local x = screenWidth / 2 - width / 2
    local y = screenHeight / 2 - height / 2
    return x, y, width, height
end

local voteButtonWidth = 32
local voteButtonHeight = 32
function AvatarValidationWindow:onMouseUp(x, y)
    if self._rejectButtonState == true and
        x > leftMargin and
        x < leftMargin + voteButtonWidth and
        y > avatarCellHeight - voteButtonHeight + topMargin and
        y < avatarCellHeight + topMargin
    then
        self:rejectAvatar()
        AvatarManager:removeAvatarPending(
            self._avatar['username'], self._avatar['firstName'],
            self._avatar['lastName'], self._avatar['checksum'])
        self._avatar = nil
    elseif self._approveButtonState == true and
        x > leftMargin + avatarCellWidth - voteButtonWidth and
        x < leftMargin + avatarCellWidth and
        y > avatarCellHeight - voteButtonHeight + topMargin and
        y < avatarCellHeight + topMargin
    then
        self:approveAvatar()
        AvatarManager:removeAvatarPending(
            self._avatar['username'], self._avatar['firstName'],
            self._avatar['lastName'], self._avatar['checksum'])
        self._avatar = nil
    end
    self._rejectButtonState = false
    self._approveButtonState = false
    self._parentClass.onMouseUp(self, x, y)
end

function AvatarValidationWindow:onMouseDown(x, y)
    if x > leftMargin and
        x < leftMargin + voteButtonWidth and
        y > avatarCellHeight - voteButtonHeight + topMargin and
        y < avatarCellHeight + topMargin
    then
        self._rejectButtonState = true
    elseif x > leftMargin + avatarCellWidth - voteButtonWidth and
        x < leftMargin + avatarCellWidth and
        y > avatarCellHeight - voteButtonHeight + topMargin and
        y < avatarCellHeight + topMargin
    then
        self._approveButtonState = true
    else
        self._parentClass.onMouseDown(self, x, y)
    end
end

-- function AvatarValidationWindow:onMouseMove(dx, dy)
--     self._parentClass.onMouseMove(self, x, y)
-- end

-- function AvatarValidationWindow:onMouseMoveOutside(x, y)
--     self._parentClass.onMouseMoveOutside(self, x, y)
-- end

function AvatarValidationWindow:onMouseUpOutside(x, y)
    self._parentClass.onMouseUpOutside(self, x, y)
    self._rejectButtonState = false
    self._approveButtonState = false
end

-- function AvatarValidationWindow:addView(view)
--     self._parentClass.addView(self, view)
-- end

function AvatarValidationWindow:close()
    self:unsubscribe()
end

-- function AvatarValidationWindow:initialise()
--     self._parentClass.initialise(self)
--     self:setTitle('')
-- end

-- function AvatarValidationWindow:prerender()
--     self._parentClass.prerender(self)
-- end

function AvatarValidationWindow:render()
    self._parentClass.render(self)
    if self._avatar == nil or
        not AvatarManager:isPendingAvatarAlive(self._avatar['username'],
            self._avatar['firstName'], self._avatar['lastName'], self._avatar['checksum'])
    then
        self._avatar = AvatarManager:getFirstAvatarPending()
    end
    if self._avatar then
        self:drawAvatarChoice()
        self:drawAvatarText()
        self:drawButtons()
    else
        self:drawNoMoreAvatarText()
    end
end

function AvatarValidationWindow:createChildren()
    -- close button
    local th = self:titleBarHeight()
    self.closeButton = ISButton:new(3, 0, th, th, "", self, self.close)
    self.closeButton:initialise()
    self.closeButton.borderColor.a = 0.0
    self.closeButton.backgroundColor.a = 0
    self.closeButton.backgroundColorMouseOver.a = 0.5
    self.closeButton:setImage(self.closeButtonTexture)
    self.closeButton:setUIName('avatar validator window close button')
    self:addChild(self.closeButton)
end

function AvatarValidationWindow:drawAvatarChoice()
    if self._avatar == nil then
        return
    end
    local texture = self._avatar['texture']
    -- TODO: invalidate bad size
    local x = 20 + leftMargin
    local y = 44 + topMargin -- magic number I'm really lazy
    self:drawTexture(texture, x, y, 1)
end

function AvatarValidationWindow:drawAvatarText()
    if self._avatar == nil then
        return
    end
    local alpha = 1
    local x = (avatarCellWidth + leftMargin + rightMargin) / 2
    self:drawTextCentre(self._avatar['username'],
        x, topMargin + FONT_HGT_NORMAL,
        1.0, 1.0, 1.0, alpha, UIFont.Normal)
    local name = '"' .. self._avatar['firstName'] .. ' ' .. self._avatar['lastName'] .. '"'
    self:drawTextCentre(name,
        x, topMargin + FONT_HGT_NORMAL * 2 + lineSpace,
        1.0, 1.0, 1.0, alpha, UIFont.Normal)
end

function AvatarValidationWindow:drawNoMoreAvatarText()
    local alpha = 1
    local text = 'No avatar request'
    local text2 = 'to process'
    local x = (avatarCellWidth + leftMargin + rightMargin) / 2
    self:drawTextCentre(text,
        x, avatarCellHeight / 2,
        1.0, 1.0, 1.0, alpha, UIFont.Normal)
    self:drawTextCentre(text2,
        x, avatarCellHeight / 2 + FONT_HGT_NORMAL + lineSpace,
        1.0, 1.0, 1.0, alpha, UIFont.Normal)
end

function AvatarValidationWindow:drawButtons()
    local rejectButtonTexture = getTexture('media/ui/yacm/icons/thumbdown_red.png')
    local approveButtonTexture = getTexture('media/ui/emotes/thumbup_green.png')
    local y = avatarCellHeight - voteButtonHeight + topMargin
    local r, g, b = 1.0, 1.0, 1.0
    if self._rejectButtonState == true then
        r, g, b = 0.5, 0.5, 0.5
    end
    self:drawTexture(rejectButtonTexture, leftMargin, y, 1, r, g, b)
    r, g, b = 1.0, 1.0, 1.0
    if self._approveButtonState == true then
        r, g, b = 0.5, 0.5, 0.5
    end
    self:drawTexture(approveButtonTexture, leftMargin + avatarCellWidth - 32, y - 8, 1, r, g, b)
end

function AvatarValidationWindow:subscribe()
    self:initialise()
    self:addToUIManager()
    self:setResizable(false)
    self:setVisible(true)
    ISLayoutManager.RegisterWindow('avatar validation window', ISCollapsableWindow, self)
end

function AvatarValidationWindow:unsubscribe()
    self:removeFromUIManager()
end

function AvatarValidationWindow:approveAvatar()
    if self._avatar == nil then
        return
    end
    local username  = self._avatar['username']
    local firstName = self._avatar['firstName']
    local lastName  = self._avatar['lastName']
    local checksum  = self._avatar['checksum']
    assert(type(username) == 'string', 'yacm error: rejectAvatar: missing username')
    assert(type(firstName) == 'string', 'yacm error: rejectAvatar: missing firstName')
    assert(type(lastName) == 'string', 'yacm error: rejectAvatar: missing lastName')
    assert(type(checksum) == 'number', 'yacm error: rejectAvatar: missing checksum')
    print('yacm info: avatar approved: ' ..
        username ..
        ' "' .. firstName .. ' ' .. lastName .. '" (' .. checksum .. ')')
    SendYacmClient.sendApprovePendingAvatar(username, firstName, lastName, checksum)
end

function AvatarValidationWindow:rejectAvatar()
    if self._avatar == nil then
        return
    end
    local username  = self._avatar['username']
    local firstName = self._avatar['firstName']
    local lastName  = self._avatar['lastName']
    local checksum  = self._avatar['checksum']
    assert(type(username) == 'string', 'yacm error: rejectAvatar: missing username')
    assert(type(firstName) == 'string', 'yacm error: rejectAvatar: missing firstName')
    assert(type(lastName) == 'string', 'yacm error: rejectAvatar: missing lastName')
    assert(type(checksum) == 'number', 'yacm error: rejectAvatar: missing checksum')
    print('yacm info: avatar rejected: ' ..
        username ..
        ' "' .. firstName .. ' ' .. lastName .. '" (' .. checksum .. ')')
    SendYacmClient.sendRejectPendingAvatar(username, firstName, lastName, checksum)
end

function AvatarValidationWindow:new()
    local x, y, width, height = CalculateCoordinatesAndSize()
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o._parentClass = ISCollapsableWindow
    o._avatar = AvatarManager:getFirstAvatarPending()
    o._x = x
    o._y = y
    o._width = width
    o._height = height
    self._rejectButtonState = false
    self._approveButtonState = false
    return o
end

return AvatarValidationWindow
