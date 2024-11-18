local ChatText = ISRichTextPanel:derive("ChatText")

-- from ISRichTextPanel:render
function ChatText:render()
    local drawLineBackground = false
    self.r = 1
    self.g = 1
    self.b = 1

    if self.lines == nil then
        return
    end

    if self.keybinds then
        for binding, text in pairs(self.keybinds) do
            if getKeyName(getCore():getKey(binding)) ~= text then
                self.textDirty = true
                break
            end
        end
    end

    if self.clip then self:setStencilRect(0, 0, self.width, self.height) end
    if self.textDirty then
        self:paginate()
    end
    --ISPanel.render(self)
    for c, v in ipairs(self.images) do
        self:drawTextureScaled(v, self.imageX[c] + self.marginLeft, self.imageY[c] + self.marginTop, self.imageW[c],
            self.imageH[c], self.contentTransparency, 1, 1, 1)
    end
    self.font = self.defaultFont
    local orient = "left"
    local c = 1
    if self.lines[self.firstPrintableLine] ~= nil then
        c = self.firstPrintableLine
        if self.firstPrintableLineColor then
            self.r = self.firstPrintableLineColor.r
            self.g = self.firstPrintableLineColor.g
            self.b = self.firstPrintableLineColor.b
        end
        if self.firstPrintableLineOrient then
            orient = self.firstPrintableLineOrient
        end
    else
        self.firstPrintableLine = 1
    end
    local previousLineY = nil
    local printableLineFound = false
    while c <= #self.lines do
        local v = self.lines[c]

        if self.lineY[c] + self.marginTop + self:getYScroll() >= self:getHeight() then
            break
        end
        if self.rgb[c] then
            self.r = self.rgb[c].r
            self.g = self.rgb[c].g
            self.b = self.rgb[c].b
        end

        if self.orient[c] then
            orient = self.orient[c]
        end

        if self.fonts[c] then
            self.font = self.fonts[c]
        end

        if self.marginTop + self:getYScroll() + self.lineY[c] + getTextManager():getFontHeight(self.font) + self:getHeight() * 2 > 0 then
            if not printableLineFound then
                printableLineFound = true
                self.firstPrintableLine = c
                self.firstPrintableLineColor = {
                    r = self.r,
                    g = self.g,
                    b = self.b,
                }
                self.firstPrintableLineOrient = orient
            end
        end

        if self.marginTop + self:getYScroll() + self.lineY[c] + getTextManager():getFontHeight(self.font) > 0 then
            local r = self.r
            local b = self.b
            local g = self.g

            if v:contains("&lt") then
                v = v:gsub("&lt", "<")
            end
            if v:contains("&gt") then
                v = v:gsub("&gt", ">")
            end

            if string.trim(v) ~= "" then
                if orient == "centre" then
                    local lineY = self.lineY[c]
                    local lineLength = 0
                    local c2 = c
                    while (c2 <= #self.lines) and (self.lineY[c2] == lineY) do
                        local font = self.fonts[c2] or self.font
                        lineLength = lineLength + getTextManager():MeasureStringX(font, string.trim(self.lines[c2]))
                        c2 = c2 + 1
                    end
                    local lineX = self.marginLeft + (self.width - self.marginLeft - self.marginRight - lineLength) / 2
                    while (c <= #self.lines) and (self.lineY[c] == lineY) do
                        if self.rgb[c] then
                            self.r = self.rgb[c].r
                            self.g = self.rgb[c].g
                            self.b = self.rgb[c].b
                        end
                        local r = self.r
                        local b = self.b
                        local g = self.g
                        if self.orient[c] then
                            orient = self.orient[c]
                        end
                        if self.fonts[c] then
                            self.font = self.fonts[c]
                        end
                        self:drawText(string.trim(self.lines[c]), lineX + self.lineX[c], self.lineY[c] + self.marginTop,
                            r, g, b, self.contentTransparency, self.font)
                        --						lineX = lineX + getTextManager():MeasureStringX(self.font, self.lines[c])
                        c = c + 1
                    end
                    c = c - 1
                elseif orient == "right" then
                    self:drawTextRight(string.trim(v), self.lineX[c] + self.marginLeft, self.lineY[c] + self.marginTop, r,
                        g, b, self.contentTransparency, self.font)
                else
                    local lineHeight = getTextManager():getFontHeight(self.font)
                    if self.lineY[c] ~= previousLineY then
                        previousLineY = self.lineY[c]
                        if drawLineBackground then
                            self:drawRect(
                                0,
                                self.lineY[c] + 3,
                                self.width + self.marginLeft + self.marginRight,
                                lineHeight,
                                0.05, 0.5, 0.5, 0.5)
                        end
                        drawLineBackground = not drawLineBackground
                    end
                    self:drawText(string.trim(v), self.lineX[c] + self.marginLeft, self.lineY[c] + self.marginTop, r, g,
                        b, self.contentTransparency, self.font)
                end
            end
        end
        c = c + 1
    end

    if ISRichTextPanel.drawMargins then
        self:drawRectBorder(0, 0, self.width, self:getScrollHeight(), 0.5, 1, 1, 1)
        self:drawRect(self.marginLeft, 0, 1, self:getScrollHeight(), 1, 1, 1, 1)
        local maxLineWidth = self.maxLineWidth or (self.width - self.marginRight - self.marginLeft)
        --		self:drawRect(self.marginLeft + maxLineWidth, 0, 1, self:getScrollHeight(), 1,1,1,1)
        self:drawRect(self.width - self.marginRight, 0, 1, self:getScrollHeight(), 1, 1, 1, 1)
        self:drawRect(0, self.marginTop, self.width, 1, 1, 1, 1, 1)
        self:drawRect(0, self:getScrollHeight() - self.marginBottom, self.width, 1, 1, 1, 1, 1)
    end

    if self.clip then self:clearStencilRect() end
    --self:setScrollHeight(y)
end

function ChatText:setYScroll(y)
    self.firstPrintableLine = 1
    ISRichTextPanel.setYScroll(self, y)
end

function ChatText:updateScroll(value)
    self:setYScroll(self:getYScroll() - (value * 18))
    return true
end

function ChatText:scrollToTop()
    self:setYScroll(0)
    return true
end

function ChatText:scrollToBottom()
    self:setYScroll(-(self:getScrollHeight() - self:getScrollAreaHeight()))
    return true
end

function ChatText:onMouseMove(dx, dy)
    ISRichTextPanel.onMouseMove(self, dx, dy)
    self._isFocused = true
end

function ChatText:onMouseMoveOutside(dx, dy)
    ISRichTextPanel.onMouseMoveOutside(self, dx, dy)
    self._isFocused = false
end

local VK_PRIOR = 201 -- PAGE UP key
local VK_NEXT  = 209 -- PAGE DOWN key
local VK_HOME  = 199 -- HOME key
local VK_END   = 207 -- END key

function ChatText:onKey(key)
    if self._isFocused then
        if key == VK_PRIOR then
            self:updateScroll(-1)
        elseif key == VK_NEXT then
            self:updateScroll(1)
        elseif key == VK_HOME then
            self:scrollToTop()
        elseif key == VK_END then
            self:scrollToBottom()
        end
    end
end

function ChatText:new(x, y, width, height)
    self.__index = self
    -- setmetatable(self, { __index = ISRichTextPanel })
    local o = ISRichTextPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    local lambda = function(key)
        o:onKey(key)
    end
    o._isFocused = false
    Events.OnKeyStartPressed.Add(lambda)
    Events.OnKeyKeepPressed.Add(lambda)
    return o
end

return ChatText
