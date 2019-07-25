Mario = class("Mario")

local marioShapes = {
    love.physics.newRectangleShape(MARIO_WIDTH-MARIO_BALLSIZE*2, MARIO_HEIGHT),
    love.physics.newRectangleShape(MARIO_WIDTH, MARIO_HEIGHT-MARIO_BALLSIZE*2),
    love.physics.newCircleShape(MARIO_WIDTH*0.5-MARIO_BALLSIZE, MARIO_HEIGHT*0.5-MARIO_BALLSIZE, MARIO_BALLSIZE), --bottom right
    love.physics.newCircleShape(-MARIO_WIDTH*0.5+MARIO_BALLSIZE, MARIO_HEIGHT*0.5-MARIO_BALLSIZE, MARIO_BALLSIZE), --bottom left
    love.physics.newCircleShape(MARIO_WIDTH*0.5-MARIO_BALLSIZE, -MARIO_HEIGHT*0.5+MARIO_BALLSIZE, MARIO_BALLSIZE), --top right
    love.physics.newCircleShape(-MARIO_WIDTH*0.5+MARIO_BALLSIZE, -MARIO_HEIGHT*0.5+MARIO_BALLSIZE, MARIO_BALLSIZE) --top left
}

local marioArmShape = love.physics.newRectangleShape(0, MARIO_ARMLENGTH*.5-MARIO_ARMWIDTH*.5, MARIO_ARMWIDTH, MARIO_ARMLENGTH)
local marioLegShape = love.physics.newRectangleShape(0, MARIO_LEGLENGTH*.5-MARIO_LEGWIDTH*.5, MARIO_LEGWIDTH, MARIO_LEGLENGTH)

function Mario:init(world, x, y)
    self.body = love.physics.newBody(world, x, y, "dynamic")
    self.body:setGravityScale(MARIO_GRAVITY_SCALE)

    self.dir = 1
    self.frame = 1
    self.frameDistance = 0
    
    self.ladder = false
    self.ladderFrame = 1
    self.ladderFrameProgress = 0

    self.previousX = self.body:getX()

    self.bodyFixtures = {}

    for _, v in ipairs(marioShapes) do
        local fixture = love.physics.newFixture(self.body, v)
        fixture:setFriction(0.1)
        fixture:setUserData({
            object = self
        })

        table.insert(self.bodyFixtures, fixture)
    end

    -- Add arms
    self.armBody = {}
    self.armFixture = {}
    self.armJoint = {}
    self.armFrictionJoint = {}
    self.legFrictionJoint = {}

    -- And legs
    self.legBody = {}
    self.legFixture = {}
    self.legJoint = {}

    for i = 1, 2 do
        self.armBody[i] = love.physics.newBody(world, x+MARIO_ARMOFFSET[i][1], y+MARIO_ARMOFFSET[i][2], "dynamic")
        self.armBody[i]:setSleepingAllowed(false)
        
        self.armFixture[i] = love.physics.newFixture(self.armBody[i], marioArmShape, MARIO_LIMBWEIGHT)
        self.armFixture[i]:setUserData({
            object = self
        })

        self.armFixture[i]:setSensor(true)
        
        self.legBody[i] = love.physics.newBody(world, x+MARIO_LEGOFFSET[i][1], y+MARIO_LEGOFFSET[i][2], "dynamic")
        self.legBody[i]:setSleepingAllowed(false)
        
        self.legFixture[i] = love.physics.newFixture(self.legBody[i], marioLegShape, MARIO_LIMBWEIGHT)
        self.legFixture[i]:setUserData({
            object = self
        })

        self.legFixture[i]:setSensor(true)
    end


    self:adjustLimbJoints()
    
    for _, fixture in ipairs(self.body:getFixtures()) do
        fixture:setCategory(CATEGORY_TEMPORARY_PASSTHROUGH_GIRDERS)
    end
    
    self.previousOnGround = self:isOnGround()
    self.rotationStart = self.body:getAngle()
end

function Mario:update(dt)
    if self:isUpright() and self:isOnGround() then -- Ground Control
        if keyRight() then
            self.body:applyForce(MARIO_ACCELERATION, 0)
            self:changeDir(1)
            
            self:walkingAnimation()
        elseif keyLeft() then
            self.body:applyForce(-MARIO_ACCELERATION, 0)
            self:changeDir(-1)

            self:walkingAnimation()
        end
    end
    
    if not self:isUpright() then
        local aSpeed = self.body:getAngularVelocity()
        
        if keyRight() and aSpeed <= MARIO_MAXTORQUE then
            self.body:applyTorque(MARIO_AIRTORQUE)
        elseif keyLeft() and aSpeed >= -MARIO_MAXTORQUE then
            self.body:applyTorque(-MARIO_AIRTORQUE)
        end
    end

    --speed limit
    local xVol, yVol = self.body:getLinearVelocity()

    local fastness = math.abs(xVol)

    if fastness > MARIO_MAXSPEED then
        local factor = MARIO_MAXSPEED/fastness
        self.body:setLinearVelocity(xVol*factor, yVol)
    end

    --update frame
    if self:isOnGround(true) then
        self.frameDistance = self.frameDistance + math.min(math.abs(self.body:getLinearVelocity()), MARIO_MAX_ANIMATIONSPEED)*dt
    end

    while self.frameDistance >= MARIO_ANIMATION_DISTANCE do
        self.frameDistance = self.frameDistance - MARIO_ANIMATION_DISTANCE
        self.frame = math.fmod(self.frame, 4)+1
    end
    
    if math.abs(xVol) < MARIO_STOPSPEED then
        self.frame = 1
    end
    
    -- Flip detection
    self.previousOnGround = self:isOnGround()
end

function Mario:postPhysicsUpdate(dt)
    if self.ladder then
        self.body:setX(self.ladder.x + self.ladder.width*.5)
            
        self.body:setLinearVelocity(0, 0)
        self.body:setAngularVelocity(0)
        self.body:setAngle(0)
        self.rotationStart = 0

        local newY, detach
        local y = self.body:getY()
        
        if keyUp() then
            newY, detach = self.ladder:climbPos(y, -1, dt)
            
        elseif keyDown() then
            newY, detach = self.ladder:climbPos(y, 1, dt)
            
        else
            newY, detach = self.ladder:climbPos(y, 0, dt)
        end

        if newY then
            self.body:setY(newY)

            self.ladderFrameProgress = self.ladderFrameProgress + math.abs(newY-y)

            while self.ladderFrameProgress > MARIO_LADDERANIMATIONDISTANCE do
                self.ladderFrameProgress = self.ladderFrameProgress - MARIO_LADDERANIMATIONDISTANCE
                self.ladderFrame = self.ladderFrame + 1

                if self.ladderFrame > 2 then
                    self.ladderFrame = 1
                end
            end
        end

        if detach then
            self:releaseLadder()
        end
    end

    --check if jumping over barrel
    if not self.ladder then
        for _, v in ipairs(game.barrels) do
            if v.previousX and not v.jumpedOver then
                -- within some Y distance
                local dist = v.body:getY() - self.body:getY()

                if dist < 20 and dist > 0 then
                    if  (self.previousX < v.previousX and self.body:getX() >= v.body:getX()) or
                        (self.previousX > v.previousX and self.body:getX() <= v.body:getX()) then
                        self:barrelJump()
                        v:jumpOver()
                    end
                end
            end
        end
    end

    self.previousX = self.body:getX()
end

function Mario:draw()
    if self.ladder then
        local dist = self.ladder:distanceFromTop(self.body:getY())
        local quad

        if not self.ladder.connectsTop or dist > MARIO_LADDERANIMATIONDIST[2] then
            quad = self.ladderFrame+5
        elseif dist > MARIO_LADDERANIMATIONDIST[1] then
            quad = 8
        else
            quad = 9
        end

        love.graphics.draw(marioImg, marioQuads[quad], self.body:getX(), self.body:getY(), self.body:getAngle(), self.dir, 1, 8, MARIO_HEIGHT+1)
    else
        local visibleArm = 2
        local hiddenArm = 1
        if self.dir == -1 then
            visibleArm = 1
            hiddenArm = 2
        end

        --left arm
        love.graphics.draw(armImg, self.armBody[hiddenArm]:getX(), self.armBody[hiddenArm]:getY(), self.armBody[hiddenArm]:getAngle(), self.dir, 1, 2, 1)

        local frame = self.frame
        if not self:isOnGround(true) or not self:isUpright() then
            frame = 5
        end

        love.graphics.draw(marioImg, marioQuads[frame], self.body:getX(), self.body:getY(), self.body:getAngle(), self.dir, 1, 8, MARIO_HEIGHT+1)

        --legs
        if frame == 5 then
            for i = 1, 2 do
                local usei = i

                if self.dir == -1 then
                    usei = math.abs(usei-2)+1
                end

                love.graphics.draw(legImg[usei], self.legBody[i]:getX(), self.legBody[i]:getY(), self.legBody[i]:getAngle(), self.dir, 1, 2, 1)
            end
        end

        --right arm
        love.graphics.draw(armImg, self.armBody[visibleArm]:getX(), self.armBody[visibleArm]:getY(), self.armBody[visibleArm]:getAngle(), self.dir, 1, 2, 1)
    end
end

function Mario:barrelJump()
    game.addScore(100)

    game.addScrollingText(100, self.body:getX(), self.body:getY())
end

function Mario:walkingAnimation()
    for i = 1, 2 do
        local dir = 1

        if i == 2 then
            if self.armBody[2]:getAngularVelocity() < 0 then
                dir = -dir
            end
        else
            dir = -dir

            if self.armBody[2]:getAngularVelocity() < 0 then
                dir = -dir
            end
        end

        local a = math.abs(normalizeAngle(self.armBody[i]:getAngle()))

        local factor = math.max(0, 1-a/MARIO_ARMSWINGDROPOFF)

        self.armBody[i]:applyTorque(MARIO_ARMSWINGFORCE*dir*factor)
    end
end

function Mario:jump() -- man
    if game.showBeta then
        game.showBeta = false
    end

    --meanwhile enjoy flying
    if self:isOnGround() and self:isUpright() then
        playSound(jumpSound)
        self.body:applyLinearImpulse(0, -MARIO_JUMPFORCE)
        
        local _, yVel = self.body:getLinearVelocity()
        
        if yVel < MARIO_MAXJUMPSPEED then
            yVel = MARIO_MAXJUMPSPEED
        end

        --make them legs do the jelly dance
        for i = 1, 2 do
            local speed = MARIO_LEGJIGGLE*MARIO_LIMBWEIGHT
            
            if i == 1 then
                speed = -speed
            end

            --find nearest math.pi*2 of angle
            local a = round(self.legBody[i]:getAngle(), math.pi*2)
            
            self.legBody[i]:setAngle(a)
            self.legBody[i]:setAngularVelocity(0)
            self.legBody[i]:setLinearVelocity(0, 0)
            self.legBody[i]:applyAngularImpulse(speed)
        end
        
        for i = 1, 2 do
            local speed = MARIO_ARMJIGGLE*MARIO_LIMBWEIGHT
            if i == 1 then
                speed = -speed
            end
            
            self.armBody[i]:applyAngularImpulse(speed)
        end
    end
end

function Mario:grabLadder(dir)
    -- Find which ladder it is (if any)
    if self:isOnGround() and not self.ladder then
        for _, v in ipairs(game.level.ladders) do
            if (dir == "up" and v.connectsBottom) or (dir == "down" and v.connectsTop) then
                local grabbable, pos = v:isGrabbable(dir, self.body:getPosition())

                if grabbable then
                    self.ladder = v
                    self.body:setX(self.ladder.x + self.ladder.width*.5)
                    
                    for _, fixture in ipairs(self.body:getFixtures()) do
                        fixtureAddMask(fixture, CATEGORY_PERMANENT_PASSTHROUGH_MARIOS)
                    end

                    if pos == "bottom" then
                        self.body:setY(v:getBottom())
                    elseif pos == "top" then
                        self.body:setY(v:getTop())
                    end

                    self.body:setGravityScale(0)
                    
                    break
                end 
            end
        end
    end
end

function Mario:releaseLadder()
    self.ladder = false
    
    for _, fixture in ipairs(self.body:getFixtures()) do
        fixtureRemoveMask(fixture, CATEGORY_PERMANENT_PASSTHROUGH_MARIOS)
    end
    
    self.body:setGravityScale(MARIO_GRAVITY_SCALE)
end

function Mario:isOnGround(girdersOnly)
    local xVol, yVol = self.body:getLinearVelocity()
    
    if yVol < -30 then
        return false
    end

    local rayCasts = {-2, 0, -2}

    local hit = false

    for _, xAdd in ipairs(rayCasts) do
        local x1, y1 = self.body:getWorldPoint(xAdd, MARIO_HEIGHT*.5)
        local x2, y2 = self.body:getWorldPoint(xAdd, MARIO_HEIGHT*.5+3)

        game.level.world:rayCast(x1, y1, x2, y2, function(fixture)
            local obj = fixture:getUserData().object

            if girdersOnly and not obj:isInstanceOf(Girder) then
                return 1
            end
            
            if obj ~= self then
                hit = true
            end
            return 1 
        end)
    end

    return hit
end

function Mario:isUpright(margin)
    local a = self.body:getAngle()

    --mod a in both directions
    a = normalizeAngle(a)

    return math.abs(a) < (margin or MARIO_UPRIGHTWINDOW)
end

function Mario:changeDir(dir)
    if dir == self.dir then
        return
    end

    self.dir = dir
    
    --update arm and leg positions
    for i = 1, 2 do

        self.armBody[i]:setAngularVelocity(-self.armBody[i]:getAngularVelocity())
        self.armBody[i]:setAngle(-self.armBody[i]:getAngle())
    end

    self:adjustLimbJoints()
end

function Mario:adjustLimbJoints()
    for i = 1, 2 do
        local useOffset = i
        if self.dir == -1 then --switch around arm positions
            useOffset = math.abs(i-2)+1
        end

        --Arm body
        local x, y = self.body:getWorldPoint(MARIO_ARMOFFSET[useOffset][1]*self.dir, MARIO_ARMOFFSET[useOffset][2])
        self.armBody[i]:setPosition(x, y)

        --Arm joint
        if self.armJoint[i] ~= nil then
            self.armJoint[i]:destroy()
        end

        self.armJoint[i] = love.physics.newRevoluteJoint(self.body, self.armBody[i], self.body:getWorldPoint(MARIO_ARMOFFSET[useOffset][1]*self.dir, MARIO_ARMOFFSET[useOffset][2]))

        --Arm friction
        if self.armFrictionJoint[i] ~= nil then
            self.armFrictionJoint[i]:destroy()
        end

        self.armFrictionJoint[i] = love.physics.newFrictionJoint(self.body, self.armBody[i], x, y)
        self.armFrictionJoint[i]:setMaxTorque(MARIO_LIMB_FRICTION)

        --Leg body
        x, y = self.body:getWorldPoint(MARIO_LEGOFFSET[useOffset][1]*self.dir, MARIO_LEGOFFSET[useOffset][2])
        self.legBody[i]:setPosition(x, y)

        --Leg joint
        if self.legJoint[i] ~= nil then
            self.legJoint[i]:destroy()
        end

        self.legJoint[i] = love.physics.newRevoluteJoint(self.body, self.legBody[i], self.body:getWorldPoint(MARIO_LEGOFFSET[useOffset][1]*self.dir, MARIO_LEGOFFSET[useOffset][2]))
        
        self.legJoint[i]:setLimits(MARIO_LEGLIMITS[i][1], MARIO_LEGLIMITS[i][2])
        self.legJoint[i]:setLimitsEnabled(true)

        --Leg friction
        if self.legFrictionJoint[i] ~= nil then
            self.legFrictionJoint[i]:destroy()
        end
        
        self.legFrictionJoint[i] = love.physics.newFrictionJoint(self.body, self.legBody[i], x, y)
        self.legFrictionJoint[i]:setMaxTorque(MARIO_LIMB_FRICTION)
    end
end

function Mario:startMove(dir)
    local mul = 1
    if dir == "left" then
        mul = -1
    end

    -- Apply some force to the limbs
    if not self:isOnGround(true) then
        self.legBody[1]:applyAngularImpulse(MARIO_WIGGLEIMPULSE*MARIO_LIMBWEIGHT*mul)
        self.legBody[2]:applyAngularImpulse(-MARIO_WIGGLEIMPULSE*MARIO_LIMBWEIGHT*mul)

        self.armBody[1]:applyAngularImpulse(MARIO_WIGGLEIMPULSE*MARIO_LIMBWEIGHT*mul)
        self.armBody[2]:applyAngularImpulse(-MARIO_WIGGLEIMPULSE*MARIO_LIMBWEIGHT*mul)
    end
end

function Mario:contact(obj2)
    if self:isUpright(MARIO_UPRIGHTWINDOWFLIP) then
        local a = self.body:getAngle()
        local diff = math.abs(a-self.rotationStart)
        
        local spinCount = math.floor((diff+math.pi*0.5)/(math.pi*2))
        
        if a-self.rotationStart < 0 then
            spinCount = -spinCount
        end
        
        if self.dir == -1 then
            spinCount = -spinCount
        end
        
        if spinCount ~= 0 then
            local s
            if math.abs(spinCount) == 1 then
                s = "nice"
            elseif math.abs(spinCount) == 2 then
                s = "awesome"
            elseif math.abs(spinCount) >= 3 then
                s = "ludicrous"
            end
            
            if spinCount > 0 then
                s = s .. " flip!"
            else
                s = s .. " backflip!"
            end
            
            game.addScrollingText(s, self.body:getX(), self.body:getY())
        end
    end
    
    self.rotationStart = self.body:getAngle()
end
