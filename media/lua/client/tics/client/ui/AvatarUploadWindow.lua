require('ISUI/ISModalRichText')

local AvatarIO = require('tics/shared/utils/AvatarIO')
local AvatarManager = require('tics/client/AvatarManager')
local Character = require('tics/shared/utils/Character')
local ClientSend = require('tics/client/network/ClientSend')


local AvatarUploadWindow = ISModalRichText:derive('AvatarUploadWindow')


local FONT_HGT_NORMAL = getTextManager():getFontHeight(UIFont.Normal)
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

local AVATAR_WIDTH = 60
local AVATAR_HEIGHT = 80
local lineSpace = 2
local textHeight = (FONT_HGT_NORMAL + lineSpace) * 2
local WIDTH = 200
local WIDTH_HELP = 600
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

function AvatarUploadWindow:updateButtons()
    if self.ok then
        local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
        local padBottom = 10
        self.ok:setY(self:getHeight() - padBottom - btnHgt)
    end
end

local padBottom = 10
local btnWid = 100
local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
function AvatarUploadWindow:initialise()
    ISPanelJoypad.initialise(self)

    self.chatText = ISRichTextPanel:new(2, 2, self.width - 4, self.height - padBottom - btnHgt)
    self.chatText.marginRight = self.chatText.marginLeft
    self.chatText:initialise()
    self:addChild(self.chatText)
    self.chatText:addScrollBars()

    self.chatText.background = false
    self.chatText.clip = true
    self.chatText.autosetheight = false
    self.chatText.text = self.text
    self.chatText:paginate()
end

function AvatarUploadWindow:onClick(button)
    self:close()
    self:destroy()
    if self.onclick ~= nil then
        self.onclick(self.target, button, self.param1, self.param2)
    end
end

function AvatarUploadWindow:close()
    self:unsubscribe()
end

function AvatarUploadWindow:subscribe()
    self:initialise()
    self:addToUIManager()
    -- self:setResizable(false)
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
        if self._avatar then
            Texture.reload(self._avatar:getName())
        end
        self._avatar = AvatarManager:getRequestAvatar()
        self._avatarRequest = AvatarManager:loadAvatarRequest()
    end
    if self._avatar then
        local screenWidth = getCore():getScreenWidth()
        local screenHeight = getCore():getScreenHeight()
        local width = WIDTH
        local height = HEIGHT
        local x = screenWidth / 2 - width / 2
        local y = screenHeight / 2 - height / 2
        self:setX(x)
        self:setY(y)
        self:setWidth(WIDTH)
        self:setHeight(HEIGHT)
        self.chatText:setWidth(WIDTH)
        self.chatText:setHeight(HEIGHT)
        self.chatText.text = ''
        if self._avatar:getWidth() ~= AVATAR_WIDTH or
            self._avatar:getHeight() ~= AVATAR_HEIGHT
        then
            self:drawInvalidSize()
            if self.yesButton then
                self:removeChild(self.yesButton)
                self:removeChild(self.noButton)
                self.yesButton = nil
                self.noButton = nil
            end
            if self._lastUpdate == 'help' then
                if self.ok then
                    self:removeChild(self.ok)
                    self.ok = nil
                end
            end
            self:addOkButton()
        else
            self:drawAvatarTexture()
            self:drawAvatarText()
            if self.yesButton == nil then
                self:createButtons()
            end
            if self.ok then
                self:removeChild(self.ok)
                self.ok = nil
            end
        end
        self._lastUpdate = 'avatar'
    else
        self._lastUpdate = 'help'
        local screenWidth = getCore():getScreenWidth()
        local screenHeight = getCore():getScreenHeight()
        local width = WIDTH_HELP
        local height = self:getHeight()
        local x = screenWidth / 2 - width / 2
        local y = screenHeight / 2 - height / 2
        self:setX(x)
        self:setY(y)
        self:setWidth(WIDTH_HELP)
        self.chatText:setWidth(WIDTH_HELP)
        self:drawHelp()
        if self.yesButton then
            self:removeChild(self.yesButton)
            self:removeChild(self.noButton)
            self.yesButton = nil
            self.noButton = nil
        end
    end
end

function AvatarUploadWindow:addOkButton()
    if self.ok == nil then
        self.ok = ISButton:new((self:getWidth() / 2) - btnWid / 2, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt,
            getText("UI_Ok"), self, AvatarUploadWindow.onClick)
        self.ok.internal = "OK"
        self.ok.anchorTop = false
        self.ok.anchorBottom = true
        self.ok:initialise()
        self.ok:instantiate()
        self.ok.borderColor = { r = 1, g = 1, b = 1, a = 0.1 }
        self:addChild(self.ok)
    end
end

function AvatarUploadWindow:drawHelp()
    local player = getPlayer()
    local username = player:getUsername()
    local firstName, lastName = Character.getFirstAndLastName(player)
    local path = '%userprofile%\\Zomboid\\Lua\\avatars\\client\\' .. getServerIP() .. '\\' .. username .. '\\request\\'
    local text = getText('SurvivalGuide_TICS_AvatarUploadHelp',
        AvatarIO.createFileName(username, firstName, lastName),
        path
    )
    self.chatText.text = text
    self:addOkButton()
end

function AvatarUploadWindow:drawInvalidSize()
    local text = getText('SurvivalGuide_TICS_AvatarSizeError',
        AVATAR_WIDTH, AVATAR_HEIGHT)
    self.chatText.text = text
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
    local player = getPlayer()
    local firstName, lastName = Character.getFirstAndLastName(player)
    if self._avatarRequest then
        if self._avatarRequest['checksum'] == self._lastSentAvatar then
            ISChat.sendErrorToCurrentTab('Avatar request already sent for "' .. firstName .. ' ' .. lastName .. '"')
            return
        end
        ClientSend.sendAvatarRequest(self._avatarRequest)
        ISChat.sendInfoToCurrentTab('Uploaded avatar request for "' .. firstName .. ' ' .. lastName .. '"')
    else
        ISChat.sendErrorToCurrentTab('Avatar already approved for "' .. firstName .. ' ' .. lastName .. '"')
    end
end

function AvatarUploadWindow:new()
    local x, y, width, height = CalculateCoordinatesAndSize()
    local o = ISModalRichText:new(x, y, width, height, '', false)
    setmetatable(o, self)
    self.__index = self
    o._parentClass = ISModalRichText
    o._avatar = AvatarManager:getRequestAvatar()
    o._avatarRequest = AvatarManager:loadAvatarRequest()
    if o._avatar then
        Texture.reload(o._avatar:getName())
    end
    o._avatar = AvatarManager:getRequestAvatar()
    o._lastSentAvatar = nil
    o._x = x
    o._y = y
    o._width = width
    o._height = height
    return o
end

return AvatarUploadWindow
