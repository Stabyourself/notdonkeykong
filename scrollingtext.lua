ScrollingText = class("ScrollingText")

local scrollingTextTime = 1
local scrollingTextMovement = 5

function ScrollingText:init(text, x, y)
    self.text = text
    self.x = x
    self.startY = y

    self.y = self.startY

    self.t = 0
end

function ScrollingText:update(dt)
    self.t = self.t + dt

    self.y = easing.outElastic(self.t, self.startY, -scrollingTextMovement, scrollingTextTime)

    return self.t >= scrollingTextTime
end

function ScrollingText:draw()
    local font
    if type(self.text) == "number" then
        font = scoreFont
    else
        font = pixelFont
    end
    
    love.graphics.setFont(font)
    
    local w = font:getWidth(self.text)
    local x = self.x-WIDTH/2
    local x = math.min(x, WIDTH-w/2-WIDTH/2) -- limit right
    local x = math.max(x, w/2-WIDTH/2) -- limit left
    
    love.graphics.printf(self.text, x, self.y, WIDTH, "center")
end
