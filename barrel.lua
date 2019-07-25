Barrel = class("Barrel")

local barrelShape = love.physics.newCircleShape(BARREL_RADIUS)
local barrelRestitution = 0.6
local barrelLadderCheckMargin = 1
local barrelLadderChance = 0.5
local barrelLadderDistance = 20
local barrelFallFrameTime = 0.2

function Barrel:init(world, x, y)
    self.body = love.physics.newBody(world, x, y, "dynamic")
    self.fixture = love.physics.newFixture(self.body, barrelShape, BARREL_DENSITY)
    self.fixture:setRestitution(barrelRestitution)

    self.fixture:setUserData({
        isBarrel = true,
        object = self
    })

    self.fixture:setCategory(CATEGORY_NO_BARREL_COLLISION)

    self.turnedAroundOn = {}
    self.overLadder = false
    self.fallingDownLadder = false
    self.previousX = self.body:getX()
    
    self.fallFrame = 1
    self.fallFrameTimer = 0
end

function Barrel:update(dt)
    local currentlyOverLadder = self:isOverLadder()
    
    if currentlyOverLadder and not self.overLadder then
        self.overLadder = true
        
        if love.math.random() <= barrelLadderChance then
            self:fallDownLadder(currentlyOverLadder)
        end
    elseif not currentlyOverLadder then
        self.overLadder = false
    end
    
    if self.fallingDownLadderThrough then
        if self.body:getY() > self.fallingDownLadderStart+barrelLadderDistance then
            self:stopFallDownLadder()
        end
    end
    
    self.previousX = self.body:getX()
    
    if self.fallingDownLadder then
        self.fallFrameTimer = self.fallFrameTimer + dt
        
        while self.fallFrameTimer > barrelFallFrameTime do
            self.fallFrameTimer = self.fallFrameTimer - barrelFallFrameTime
            self.fallFrame = self.fallFrame + 1
            
            if self.fallFrame > 2 then
                self.fallFrame = 1
            end
        end
    end
end

function Barrel:draw()
    if self.fallingDownLadder then
        love.graphics.draw(barrelFallImg, barrelFallQuad[self.fallFrame], self.body:getX(), self.body:getY(), 0, 1, 1, 8, 5)
    else
        love.graphics.draw(barrelImg, self.body:getX(), self.body:getY(), self.body:getAngle(), 1, 1, 5, 5)
    end
end

function Barrel:fallDownLadder(ladder)
    self.body:setX(ladder.x+LADDER_WIDTH/2)
    
    local _, yVel = self.body:getLinearVelocity()
    self.body:setLinearVelocity(0, yVel)
    
    self.fixture:setCategory(CATEGORY_TEMPORARY_PASSTHROUGH_BARRELS)
    
    self.fallingDownLadder = true
    self.fallingDownLadderThrough = true
    self.fallingDownLadderStart = self.body:getY()
    self.body:setGravityScale(0.5)
end

function Barrel:stopFallDownLadder()
    self.fixture:setCategory(CATEGORY_NO_BARREL_COLLISION)
    self.fallingDownLadderThrough = false
    
    self.body:setGravityScale(1)
end

function Barrel:jumpOver()
    self.jumpedOver = true
end

function Barrel:isOverLadder()
    for _, v in ipairs(game.level.ladders) do
        if v.connectsTop then
            -- check X
            if (self.body:getX() >= v.x+LADDER_WIDTH/2 and self.previousX < v.x+LADDER_WIDTH/2) or
               (self.body:getX() < v.x+LADDER_WIDTH/2 and self.previousX >= v.x+LADDER_WIDTH/2) then
                -- check Y
                
                if v.y-13.35-barrelLadderCheckMargin < self.body:getY() 
                and v.y-13.35+barrelLadderCheckMargin > self.body:getY() 
                    then
                    return v
                end
            end
        end
    end
    
    return false
end