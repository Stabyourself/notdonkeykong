Ladder = class("Ladder")

local grabHitbox = {-2, 2, 0, 0} -- Left, right, up, down
local connectHeight = 8

function Ladder:init(x, y, height, connectsTop, connectsBottom)
    self.x = x
    self.y = y
    self.height = height
    self.width = LADDER_WIDTH
    self.connectsTop = connectsTop
    self.connectsBottom = connectsBottom
end

function Ladder:debugDraw()
    if self.connectsBottom and self.connectsTop then
        love.graphics.setColor(1, 1, 1)
    elseif self.connectsTop then
        love.graphics.setColor(1, 0, 0)
    elseif self.connectsBottom then
        love.graphics.setColor(0, 0, 1)
    else
        love.graphics.setColor(1, 1, 0)
    end
    
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
end

function Ladder:isGrabbable(dir, x, y)
    local upAdd = 0
    local downAdd = -10
    if dir == "down" and self.connectsTop then
        upAdd = connectHeight + 8
    end
    
    if dir == "up" then
        downAdd = 0
    end
    
    if  x > self.x + grabHitbox[1] and
        x < self.x + grabHitbox[2] + self.width and
        y > self.y + grabHitbox[3] - upAdd and
        y < self.y + grabHitbox[4] + self.height + downAdd then
        if y > self.y then
            return true, "bottom"
        else   
            return true, "top"
        end
    else
        return false
    end
end

function Ladder:getTop()
    local top = self.y

    if self.connectsTop then
        top = top - connectHeight - MARIO_HEIGHT*.5
    end

    return top
end

function Ladder:getBottom()
    return self.y+self.height-MARIO_HEIGHT*.5
end

function Ladder:climbPos(y, dir, dt)
    local newY = y + MARIO_LADDERSPEED*dir*dt
    
    if newY > self:getBottom() then
        if self.connectsBottom or dir == 0 then
            return self:getBottom(), true
        else
            newY = math.min(self:getBottom(), newY)
        end
    end
    

    if newY < self:getTop() then
        if self.connectsTop or dir == 0 then
            return self:getTop(), true
        else
            newY = self:getTop()
        end
    end

    return newY, false
end

function Ladder:distanceFromTop(y)
    return y - self:getTop()
end