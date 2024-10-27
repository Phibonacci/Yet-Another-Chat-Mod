require('ISUI/ISCollapsableWindow')


local AvatarManager = require('yacm/client/AvatarManager')

local AvatarValidationWindow = ISCollapsableWindow:derive("AvatarValidationWindow")

-- function AvatarValidationWindow:onMouseUp(x, y)
--     self._parentClass.onMouseUp(self, x, y)
-- end

-- function AvatarValidationWindow:onMouseDown(x, y)
--     self._parentClass.onMouseDown(self, x, y)
-- end

-- function AvatarValidationWindow:onMouseMove(dx, dy)
--     self._parentClass.onMouseMove(self, x, y)
-- end

-- function AvatarValidationWindow:onMouseMoveOutside(x, y)
--     self._parentClass.onMouseMoveOutside(self, x, y)
-- end

-- function AvatarValidationWindow:onMouseUpOutside(x, y)
--     self._parentClass.onMouseUpOutside(self, x, y)
-- end

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

-- function AvatarValidationWindow:render()
--     self._parentClass.render(self)
-- end

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

function AvatarValidationWindow:drawAvatarChoice(avatar, x, y)
end

local avatarCellWidth = 100
local avatarCellHeight = 120
local leftMargin = 2
local rightMargin = leftMargin
local topMargin = 2
local bottomMargin = 2
local maxAvatarsByLine = 4
local function CalculateCoordinatesAndSize(count)
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    local avatarsByLine = math.floor((screenWidth - leftMargin - rightMargin) / count)
    avatarsByLine = math.min(math.max(1, avatarsByLine), maxAvatarsByLine)
    local width = avatarCellWidth * avatarsByLine + leftMargin + rightMargin
    local lines = math.floor(math.max(0, count - 1) / avatarsByLine) + 1
    local height = avatarCellHeight * lines + topMargin + bottomMargin
    local x = screenWidth / 2 - width / 2
    local y = screenHeight / 2 - height / 2
    return x, y, width, height
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

function AvatarValidationWindow:new()
    local avatars, count = AvatarManager:getAvatarsToValidate()
    local x, y, width, height = CalculateCoordinatesAndSize(count)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    print('AvatarValidationWindow methods:')
    for name, method in pairs(o) do
        print(name)
    end
    o._parentClass = ISCollapsableWindow
    o._avatars = avatars
    o._count = count
    o._x = x
    o._y = y
    o._width = width
    o._height = height
    return o
end

return AvatarValidationWindow
