local ChatUI = {}
ChatUI.tabPanel = {}
ChatUI.textEntry = {}

function ChatUI:prerender()
    ISChat.instance = self
    self.gearButton.onclick = self.onGearButtonClick

    self:setDrawFrame(true)

    if not ISChat.focused then
        self.fade:update()
    end
    self:makeFade(self.fade:fraction())

    -- local a = self.backgroundColor.a
    local titleBar = {
        r = 20 / 255,
        g = 20 / 255,
        b = 20 / 255,
    }
    local background = {
        r = 42 / 255,
        g = 42 / 255,
        b = 42 / 255,
    }
    local titlebarAlpha = self:calcAlpha(ISChat.minControlOpaque, ISChat.maxGeneralOpaque, self.fade:fraction())
    self:drawRect(0, 0, self:getWidth(), self:titleBarHeight(), math.max(titlebarAlpha + 0.3, 1),
        titleBar.r, titleBar.g, titleBar.b)
    self:drawRect(0, self:titleBarHeight(), self:getWidth(), self:getHeight() - self:titleBarHeight(), titlebarAlpha,
        background.r, background.g, background.b)
    local th = self:titleBarHeight()
    -- self:drawRect(2, 1, self:getWidth() - 4, th - 2, titlebarAlpha, r, g, b)
    -- self:drawTextureScaled(self.titlebarbkg, 2, 1, self:getWidth() - 4, th - 2, titlebarAlpha, 1, 1, 1)
    if self.servermsg then
        local x = getCore():getScreenWidth() / 2 - self:getX()
        local y = getCore():getScreenHeight() / 4 - self:getY()
        self:drawTextCentre(self.servermsg, x, y, 1, 0.1, 0.1, 1, UIFont.Title)
        self.servermsgTimer = self.servermsgTimer - UIManager.getMillisSinceLastRender()
        if self.servermsgTimer < 0 then
            self.servermsg = nil
            self.servermsgTimer = 0
        end
    end
end

function ChatUI:render()
    local height = self:getHeight()
    local th = self:titleBarHeight()
    if self.isCollapsed then
        height = th
    end
    if not self.isCollapsed and self.resizable and self.drawFrame and self.resizeWidget:getIsVisible() then
        local rh = self:resizeWidgetHeight()
        -- self:drawRectBorder(0, height - rh - 1, self:getWidth(), rh + 1, self.borderColor.a, self.borderColor.r,
        --    self.borderColor.g, self.borderColor.b)
        local r, g, b, a = 20 / 255, 20 / 255, 20 / 255, 0.8
        -- self:drawTextureScaled(self.statusbarbkg, 2, height - rh, self:getWidth() - 4, rh - 1, a, r, g, b)
        self:drawRect(2, height - rh, self:getWidth() - 4, rh - 1, a, r, g, b)
        self:drawTexture(self.resizeimage, self:getWidth() - 9, height - rh, a, r, g, b)
    end

    if self.clearStentil then
        self:clearStencilRect()
    end
    if self.drawFrame then
        self:drawRectBorder(0, 0, self:getWidth(), height, self.borderColor.a, self.borderColor.r, self.borderColor.g,
            self.borderColor.b)
    end

    if self.drawJoypadFocus then
        self:drawRectBorder(0, 0, self:getWidth(), self:getHeight(), 0.4, 0.2, 1.0, 1.0)
        self:drawRectBorder(1, 1, self:getWidth() - 2, self:getHeight() - 2, 0.4, 0.2, 1.0, 1.0)
    end
end

function ChatUI.tabPanel:prerender()
    -- if the mouse is over the tab panel and we got a tab to drag, we gonna display it outside
    if ISTabPanel.mouseOut and ISTabPanel.viewDragging and not ISMouseDrag.dragView then
        self:clearStencilRect()
        self:setStencilRect(0 - self:getAbsoluteX(), 0 - self:getAbsoluteY(), getCore():getScreenWidth(),
            getCore():getScreenHeight())
        -- self:drawRectBorder(self:getMouseX(), self:getMouseY(), ISTabPanel.viewDragging.view:getWidth(),
        --     ISTabPanel.viewDragging.view:getHeight(), 1, 1, 1, 1)
        self:clearStencilRect()
    end
    self:updateSmoothScrolling()
end

--************************************************************************--
--** ISTabPanel:render
--**
--************************************************************************--
function ChatUI.tabPanel:render()
    local newViewList = {}
    local tabDragSelected = -1
    if self.draggingTab and not self.isDragging and ISTabPanel.xMouse > -1 and ISTabPanel.xMouse ~= self:getMouseX() then -- do we move the mouse since we have let the left button down ?
        self.isDragging = self.allowDraggingTabs
    end
    local tabWidth = self.maxLength
    local inset = 1 -- assumes a 1-pixel window border on the left to avoid
    local gap = 1   -- gap between tabs
    if self.isDragging and not ISTabPanel.mouseOut then
        -- we fetch all our view to remove the tab of the view we're dragging
        for i, viewObject in ipairs(self.viewList) do
            if i ~= (self.draggingTab + 1) then
                table.insert(newViewList, viewObject)
            else
                ISTabPanel.viewDragging = viewObject
            end
        end
        -- in wich tab slot are we dragging our tab
        tabDragSelected = self:getTabIndexAtX(self:getMouseX()) - 1
        tabDragSelected = math.min(#self.viewList - 1, math.max(tabDragSelected, 0))
        -- we draw a white rectangle to show where our tab is going to be
        self:drawRectBorder(inset + (tabDragSelected * (tabWidth + gap)), 0, tabWidth, self.tabHeight - 1, 1, 1, 1, 1)
    else -- no dragging, we display all our tabs
        newViewList = self.viewList
    end
    -- our principal rect, wich display our different view
    self:drawRect(0, self.tabHeight, self.width, self.height - self.tabHeight, self.backgroundColor.a,
        self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, self.tabHeight, self.width, self.height - self.tabHeight, self.borderColor.a,
        self.borderColor.r, self.borderColor.g, self.borderColor.b)
    local x = inset
    if self.centerTabs and (self:getWidth() >= self:getWidthOfAllTabs()) then
        x = (self:getWidth() - self:getWidthOfAllTabs()) / 2
    else
        x = x + self.scrollX
    end
    local widthOfAllTabs = self:getWidthOfAllTabs()
    local overflowLeft = self.scrollX < 0
    local overflowRight = x + widthOfAllTabs > self.width
    local blinkTabsAlphaNotUpdated = true
    if widthOfAllTabs > self.width then
        self:setStencilRect(0, 0, self.width, self.tabHeight)
    end
    for i, viewObject in ipairs(newViewList) do
        tabWidth = self.equalTabWidth and self.maxLength or viewObject.tabWidth
        -- if we drag a tab over an existing one, we move the other
        if tabDragSelected ~= -1 and i == (tabDragSelected + 1) then
            x = x + tabWidth + gap
        end
        -- if this tab is the active one, we make the tab btn lighter
        if viewObject.name == self.activeView.name and not self.isDragging and not ISTabPanel.mouseOut then
            -- self:drawTextureScaled(ISTabPanel.tabSelected, x, 0, tabWidth, self.tabHeight - 1, self.tabTransparency, 1, 1,
            --     1)
            local r, g, b = 90 / 255, 90 / 255, 110 / 255
            self:drawRect(x, 0, tabWidth, self.tabHeight - 1, self.tabTransparency, r, g, b)
        else
            local alpha = self.tabTransparency
            local shouldBlink = false
            if self.blinkTabs then
                for j, tab in ipairs(self.blinkTabs) do
                    if tab and tab == viewObject.name then
                        shouldBlink = true
                    end
                end
            end
            if (self.blinkTab and self.blinkTab == viewObject.name) or (shouldBlink and blinkTabsAlphaNotUpdated) then
                blinkTabsAlphaNotUpdated = false
                if not self.blinkTabAlpha then
                    self.blinkTabAlpha = self.tabTransparency
                    self.blinkTabAlphaIncrease = false
                end

                if not self.blinkTabAlphaIncrease then
                    self.blinkTabAlpha = self.blinkTabAlpha -
                        0.1 * self.tabTransparency * (UIManager.getMillisSinceLastRender() / 33.3)
                    if self.blinkTabAlpha < 0 then
                        self.blinkTabAlpha = 0
                        self.blinkTabAlphaIncrease = true
                    end
                else
                    self.blinkTabAlpha = self.blinkTabAlpha +
                        0.1 * self.tabTransparency * (UIManager.getMillisSinceLastRender() / 33.3)
                    if self.blinkTabAlpha > self.tabTransparency then
                        self.blinkTabAlpha = self.tabTransparency
                        self.blinkTabAlphaIncrease = false
                    end
                end
                alpha = self.blinkTabAlpha
                local r, g, b = 70 / 255, 40 / 255, 40 / 255
                self:drawRect(x, 0, tabWidth, self.tabHeight - 1, alpha, r, g, b)
                -- self:drawTextureScaled(ISTabPanel.tabUnSelected, x, 0, tabWidth, self.tabHeight - 1, self
                --     .tabTransparency, 1, 1, 1)
                -- self:drawRect(x, 0, tabWidth, self.tabHeight - 1, alpha, 1, 1, 1)
            elseif shouldBlink then
                alpha = self.blinkTabAlpha
                -- self:drawTextureScaled(ISTabPanel.tabUnSelected, x, 0, tabWidth, self.tabHeight - 1, self
                --     .tabTransparency, 1, 1, 1)
                -- self:drawRect(x, 0, tabWidth, self.tabHeight - 1, alpha, 1, 1, 1)
                local r, g, b = 70 / 255, 40 / 255, 40 / 255
                self:drawRect(x, 0, tabWidth, self.tabHeight - 1, alpha, r, g, b)
            else
                -- self:drawTextureScaled(ISTabPanel.tabUnSelected, x, 0, tabWidth, self.tabHeight - 1, self
                --     .tabTransparency, 1, 1, 1)
                if self:getMouseY() >= 0 and self:getMouseY() < self.tabHeight and self:isMouseOver() and self:getTabIndexAtX(self:getMouseX()) == i then
                    viewObject.fade:setFadeIn(true)
                else
                    viewObject.fade:setFadeIn(false)
                end
                viewObject.fade:update()
                -- self:drawTextureScaled(ISTabPanel.tabSelected, x, 0, tabWidth, self.tabHeight - 1,
                --     0.2 * viewObject.fade:fraction(), 1, 1, 1)
                local r, g, b = 60 / 255, 60 / 255, 80 / 255
                local a = 0.7 -- 0.2 * viewObject.fade:fraction()
                self:drawRect(x, 0, tabWidth, self.tabHeight - 1, a, r, g, b)
            end
        end
        self:drawTextCentre(viewObject.name, x + (tabWidth / 2), 3, 1, 1, 1, 1, UIFont.Small)
        x = x + tabWidth + gap
    end
    local butPadX = 3
    if overflowLeft then
        local tex = getTexture("media/ui/ArrowLeft.png")
        local butWid = tex:getWidthOrig() + butPadX * 2
        self:drawRect(inset, 0, butWid, self.tabHeight, 1, 0, 0, 0)
        self:drawRectBorder(inset, 0, butWid, self.tabHeight, 1, 1, 1, 1)
        self:drawTexture(tex, inset + butPadX, (self.tabHeight - tex:getHeight()) / 2, 1, 1, 1, 1)
    end
    if overflowRight then
        local tex = getTexture("media/ui/ArrowRight.png")
        local butWid = tex:getWidthOrig() + butPadX * 2
        self:drawRect(self.width - inset - butWid, 0, butWid, self.tabHeight, 1, 0, 0, 0)
        self:drawRectBorder(self.width - inset - butWid, 0, butWid, self.tabHeight, 1, 1, 1, 1)
        self:drawTexture(tex, self.width - butWid + butPadX, (self.tabHeight - tex:getHeight()) / 2, 1, 1, 1, 1)
    end
    if widthOfAllTabs > self.width then
        self:clearStencilRect()
    end
    -- we draw a ghost of our tab we currently dragging
    if self.draggingTab and self.isDragging and not ISTabPanel.mouseOut then
        if self.draggingTab > 0 then
            self:drawTextureScaled(ISTabPanel.tabSelected,
                inset + (self.draggingTab * (tabWidth + gap)) + (self:getMouseX() - ISTabPanel.xMouse), 0, tabWidth,
                self.tabHeight - 1, 0.8, 1, 1, 1)
            self:drawTextCentre(ISTabPanel.viewDragging.name,
                inset + (self.draggingTab * (tabWidth + gap)) + (self:getMouseX() - ISTabPanel.xMouse) + (tabWidth / 2),
                3, 1, 1, 1, 1, UIFont.Normal)
        else
            self:drawTextureScaled(ISTabPanel.tabSelected, inset + (self:getMouseX() - ISTabPanel.xMouse), 0, tabWidth,
                self.tabHeight - 1, 0.8, 1, 1, 1)
            self:drawTextCentre(ISTabPanel.viewDragging.name,
                inset + (self:getMouseX() - ISTabPanel.xMouse) + (tabWidth / 2), 3, 1, 1, 1, 1, UIFont.Normal)
        end
    end
end

function ChatUI.textEntry:prerender()
    -- self.fade:setFadeIn(self:isMouseOver() or self.javaObject:isFocused())
    -- self.fade:update()

    -- local r, g, b = 70 / 255, 70 / 255, 70 / 255
    -- -- self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a, r, g, b)
    -- -- if OnScreenKeyboard and not OnScreenKeyboard.IsVisible() and (self.joyfocus or self.joypadFocused) then
    -- --     local r, g, b, a = 0.2, 1.0, 1.0, 0.4
    -- --     if not self.joyfocus then r, g, b = 1.0, 1.0, 1.0 end
    -- --     self:drawRectBorder(0, 0, self:getWidth(), self:getHeight(), a, r, g, b)
    -- --     self:drawRectBorder(1, 1, self:getWidth() - 2, self:getHeight() - 2, a, r, g, b)
    -- -- elseif self.borderColor.a == 1 then
    -- --     local rgb = math.min(self.borderColor.r + 0.2 * self.fade:fraction(), 1.0)
    -- --     self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, rgb, rgb, rgb)
    -- -- else -- setValid(false)
    -- --     local r = math.min(self.borderColor.r + 0.2 * self.fade:fraction(), 1.0)
    -- --     self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, r, self.borderColor.g,
    -- --         self.borderColor.b)
    -- -- end

    -- if self:isMouseOver() and self.tooltip then
    --     local text = self.tooltip
    --     if not self.tooltipUI then
    --         self.tooltipUI = ISToolTip:new()
    --         self.tooltipUI:setOwner(self)
    --         self.tooltipUI:setVisible(false)
    --     end
    --     if not self.tooltipUI:getIsVisible() then
    --         if string.contains(self.tooltip, "\n") then
    --             self.tooltipUI.maxLineWidth = 1000 -- don't wrap the lines
    --         else
    --             self.tooltipUI.maxLineWidth = 300
    --         end
    --         self.tooltipUI:addToUIManager()
    --         self.tooltipUI:setVisible(true)
    --         self.tooltipUI:setAlwaysOnTop(true)
    --     end
    --     self.tooltipUI.description = text
    --     self.tooltipUI:setX(self:getMouseX() + 23)
    --     self.tooltipUI:setY(self:getMouseY() + 23)
    -- else
    --     if self.tooltipUI and self.tooltipUI:getIsVisible() then
    --         self.tooltipUI:setVisible(false)
    --         self.tooltipUI:removeFromUIManager()
    --     end
    -- end
end

function ChatUI.textEntry:instantiate()
    --self:initialise()
    self.javaObject = UITextBox2.new(self.font, self.x, self.y, self.width, self.height, self.title, false)
    self.javaObject:setTable(self)
    self.javaObject:setX(self.x)
    self.javaObject:setY(self.y)
    self.javaObject:setHeight(self.height)
    self.javaObject:setWidth(self.width)
    self.javaObject:setAnchorLeft(self.anchorLeft)
    self.javaObject:setAnchorRight(self.anchorRight)
    self.javaObject:setAnchorTop(self.anchorTop)
    self.javaObject:setAnchorBottom(self.anchorBottom)
    self.javaObject:setEditable(true)
    -- This forces the cursor to the end of the line
    self.javaObject:SetText(self.title)
end

return ChatUI
