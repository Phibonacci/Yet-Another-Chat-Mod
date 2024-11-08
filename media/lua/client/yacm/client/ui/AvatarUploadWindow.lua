require('ISUI/ISCollapsableWindow')

local AvatarManager = require('yacm/client/AvatarManager')
local Character = require('yacm/shared/utils/Character')
local SendYacmClient = require('yacm/client/network/SendYacmClient')


local AvatarUploadWindow = ISCollapsableWindow:derive('AvatarUploadWindow')


local FONT_HGT_NORMAL = getTextManager():getFontHeight(UIFont.Normal)
local AVATAR_WIDTH = 60
local AVATAR_HEIGHT = 80
local lineSpace = 2
local textHeight = (FONT_HGT_NORMAL + lineSpace) * 2
local WIDTH = 200
local HEIGHT = 120 + textHeight
local leftMargin = 2
local rightMargin = leftMargin
local topMargin = 2
local bottomMargin = 2
local function CalculateCoordinatesAndSize()
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    local width = WIDTH
    local height = HEIGHT
    local x = screenWidth / 2 - width / 2
    local y = screenHeight / 2 - height / 2
    return x, y, width, height
end

function AvatarUploadWindow:close()
    self:unsubscribe()
end

function AvatarUploadWindow:subscribe()
    self:initialise()
    self:addToUIManager()
    self:setResizable(false)
    self:setVisible(true)
    ISLayoutManager.RegisterWindow('avatar upload window', ISCollapsableWindow, self)
end

function AvatarUploadWindow:unsubscribe()
    self:removeFromUIManager()
end

function AvatarUploadWindow:render()
    self._parentClass.render(self)
    if self._avatar == nil
    then
        self._avatar = AvatarManager:getRequestAvatar()
    end
    if self._avatar then
        self:drawAvatarTexture()
        self:drawAvatarText()
        if self.yesButton == nil then
            self:createButtons()
        end
    else
        self:drawNoMoreAvatarText()
        self.yesButton = nil
        self.noButton = nil
    end
end

function AvatarUploadWindow:drawNoMoreAvatarText()
    local text1 = 'No avatar found'
    local text2 = 'of approval for this avatar?'
    local alpha = 1
    local x = WIDTH / 2
    self:drawTextCentre(text1,
        x, topMargin + FONT_HGT_NORMAL,
        1.0, 1.0, 1.0, alpha, UIFont.Normal)
    -- self:drawTextCentre(text2,
    --     x, topMargin + FONT_HGT_NORMAL * 2 + lineSpace,
    --     1.0, 1.0, 1.0, alpha, UIFont.Normal)
end

function AvatarUploadWindow:drawAvatarTexture()
    if self._avatar == nil then
        return
    end
    local texture = self._avatar
    -- TODO: invalidate bad size
    local x = (WIDTH - AVATAR_WIDTH) / 2
    local y = 44 + topMargin -- magic number I'm really lazy
    self:drawTexture(texture, x, y, 1)
end

function AvatarUploadWindow:drawAvatarText()
    if self._avatar == nil then
        return
    end
    local text1 = 'Do you want to send a request'
    local text2 = 'of approval for this avatar?'
    local alpha = 1
    local x = WIDTH / 2
    self:drawTextCentre(text1,
        x, topMargin + FONT_HGT_NORMAL,
        1.0, 1.0, 1.0, alpha, UIFont.Normal)
    self:drawTextCentre(text2,
        x, topMargin + FONT_HGT_NORMAL * 2 + lineSpace,
        1.0, 1.0, 1.0, alpha, UIFont.Normal)
end

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
function AvatarUploadWindow:createButtons()
    local y = 44 + topMargin + AVATAR_HEIGHT
    local buttonWidth = 100
    local buttonHeight = math.max(25, FONT_HGT_SMALL + 3 * 2)

    local yesCallback = function()
        self:sendAvatar()
        self:close()
    end


    self.yesButton = ISButton:new(leftMargin, y, buttonWidth, buttonHeight,
        getText("UI_Yes"), nil, yesCallback)
    self.noButton  = ISButton:new(WIDTH - buttonWidth - rightMargin, y, buttonWidth, buttonHeight,
        getText("UI_No"), self, self.close)


    self:addChild(self.yesButton)
    self:addChild(self.noButton)
end

function AvatarUploadWindow:sendAvatar()
    local avatarRequest = AvatarManager:loadAvatarRequest()
    local player = getPlayer()
    local firstName, lastName = Character.getFirstAndLastName(player)
    if avatarRequest then
        if avatarRequest['checksum'] == self._lastSentAvatar then
            ISChat.sendErrorToCurrentTab('Avatar request already sent for "' .. firstName .. ' ' .. lastName .. '"')
            return
        end
        SendYacmClient.sendAvatarRequest(avatarRequest)
        ISChat.sendInfoToCurrentTab('Uploaded avatar request for "' .. firstName .. ' ' .. lastName .. '"')
    else
        ISChat.sendErrorToCurrentTab('Avatar already approved for "' .. firstName .. ' ' .. lastName .. '"')
    end
end

function AvatarUploadWindow:new()
    local x, y, width, height = CalculateCoordinatesAndSize()
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o._parentClass = ISCollapsableWindow
    o._avatar = AvatarManager:getRequestAvatar()
    o._lastSentAvatar = nil
    o._x = x
    o._y = y
    o._width = width
    o._height = height
    return o
end

return AvatarUploadWindow
