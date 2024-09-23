local ABubble       = require('yacm/client/ui/bubble/ABubble')
local AvatarManager = require('yacm/client/AvatarManager')
local Coordinates   = require('yacm/client/utils/Coordinates')
local Parser        = require('yacm/client/parser/Parser')
local PlayerVoice   = require('yacm/client/voice/PlayerVoice')


local PlayerBubble = ISUIElement:derive('PlayerBubble')

function PlayerBubble:loadTextures()
    self.bubbleTop = getTexture('media/ui/yacm/bubble/simple/bubble-top.png')
    self.bubbleTopLeft = getTexture('media/ui/yacm/bubble/simple/bubble-top-left.png')
    self.bubbleTopRight = getTexture('media/ui/yacm/bubble/simple/bubble-top-right.png')
    self.bubbleCenter = getTexture('media/ui/yacm/bubble/simple/bubble-center.png')
    self.bubbleCenterLeft = getTexture('media/ui/yacm/bubble/simple/bubble-left.png')
    self.bubbleCenterRight = getTexture('media/ui/yacm/bubble/simple/bubble-right.png')
    self.bubbleBot = getTexture('media/ui/yacm/bubble/simple/bubble-bot.png')
    self.bubbleBotLeft = getTexture('media/ui/yacm/bubble/simple/bubble-bot-left.png')
    self.bubbleBotRight = getTexture('media/ui/yacm/bubble/simple/bubble-bot-right.png')
    self.bubbleArrow = getTexture('media/ui/yacm/bubble/simple/bubble-arrow.png')

    self.bubbleBotLeftSquare = getTexture('media/ui/yacm/bubble/simple/bubble-bot-left-square.png')

    if self.portrait == 3 then
        self.avatarWidth = 33
        self.avatarHeight = 32
        local steamId = getSteamIDFromUsername(self.player:getUsername())
        if steamId ~= nil then
            self.playerAvatar = getSteamAvatarFromSteamID(steamId)
        end
    elseif self.portrait == 4 then
        self.avatarWidth = 60
        self.avatarHeight = 80
        self.playerAvatar = AvatarManager:getAvatar(self.player:getUsername())
    end

    if self.portrait == 2 or (self.portrait == 4 and self.playerAvatar == nil) then
        self.avatarWidth = 25
        self.avatarHeight = 80
        self.playerModel = UI3DModel:new()
        -- there is a lot of free space left on the right so the avatarWidth is lower
        self.playerModel:setWidth(40)
        self.playerModel:setHeight(self.avatarHeight)
        self.playerModel:setCharacter(self.player)
        self.playerModel:setState("idle")
        self.playerModel:setDirection(IsoDirections.SE)
        self.playerModel:setIsometric(false)
        self.playerModel:setAnimate(false)
        self.playerModel:setZoom(17)
        self.playerModel:setYOffset(-0.92)
    end
end

function PlayerBubble:render()
    if self.dead then
        return
    end
    if not self.texturesLoaded then
        self:loadTextures()
        self.texturesLoaded = true
    end
    if self.playerAvatar then
        self.topSpace = math.max(self.avatarHeight - (self:getHeight() + 2), 0)
        self.marginLeft = self.avatarWidth + self.defaultLeftMargin
        self:setWidth(self.defaultWidth + self.avatarWidth)
    elseif self.playerModel then
        self.topSpace = math.max(self.avatarHeight - 20 - (self:getHeight() + 2), 0)
        self.marginLeft = self.avatarWidth + self.defaultLeftMargin
        self:setWidth(self.defaultWidth + self.avatarWidth)
    else
        self.topSpace = 0
        self.marginLeft = self.defaultLeftMargin
        self:setWidth(self.defaultWidth)
    end
    local x, y = Coordinates.CenterTopOfPlayer(self.player, self:getWidth(), self:getHeight())
    if x == nil then
        return
    end
    self:updateText(x, y)
    self:drawBubble()
    if self.playerAvatar and self.portrait == 3 or self.portrait == 4 then
        self:drawTextureScaled(self.playerAvatar,
            2, self:getHeight() - self.avatarHeight - 2,
            self.avatarWidth, self.avatarHeight,
            math.min(1, self.fadingProgression + 0.35))
    elseif self.playerModel then
        local width = self:getWidth()
        local height = self:getHeight()
        local screenWidth = getCore():getScreenWidth()
        local screenHeight = getCore():getScreenHeight()
        local modelX = self.currentX + 2
        if self.currentX < 0 then
            modelX = 2
        elseif self.currentX > screenWidth - width - 2 then
            modelX = 2 + screenWidth - width
        end
        local modelY = self.currentY + height - self.avatarHeight - 2
        if self.currentY < 0 then
            modelY = 0
        elseif self.currentY > screenHeight - height - 2 then
            modelY = screenHeight - self.avatarHeight - 2
        end
        self.playerModel:setX(modelX)
        self.playerModel:setY(modelY)
        self.playerModel:render()
    end
end

function PlayerBubble:new(player, message, messageColor, timer, opacity, isVoicesEnabled, voicePitch, portrait)
    local parsedMessages = Parser.ParseYacmMessage(message, messageColor, 20, 200)
    local textLength = getTextManager():MeasureStringX(UIFont.medium, parsedMessages['rawMessage'])
    local width = math.min(textLength * 1.25, 162) + 40
    local height = 0
    local x, y = Coordinates.CenterTopOfPlayer(player, width, height)
    if x == nil then
        x, y = 0, 0
    end
    PlayerBubble.__index = self
    setmetatable(PlayerBubble, { __index = ABubble })
    local o = ABubble:new(
        x, y, parsedMessages['bubble'], parsedMessages['rawMessage'],
        message, messageColor, timer, opacity, 20)
    if x == nil then
        self.dead = true
    end
    setmetatable(o, PlayerBubble)
    o.player = player
    if isVoicesEnabled then
        o.voice = PlayerVoice:new(parsedMessages['rawMessage'], player, voicePitch)
    end
    o.portrait = portrait
    return o
end

return PlayerBubble
