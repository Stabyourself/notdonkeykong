DonkeyKong = class("DonkeyKong")

function DonkeyKong:init(x, y)
    self.x = x
    self.y = y

    local props = game.level.properties.donkeyKong

    self.throws = props.throws or "barrels"
    self.delays = props.delays or {2, 2, 4, 1, 0.4}
    self.throwAt = props.throwAt or {80, 56-BARREL_RADIUS}
    self.throwForce = props.throwForce or {50, -100}

    self.throwTimer = 0
    self.idleTimer = -DONKEYKONG_HOLDPOSE
    self:newThrowDelay()
end

function DonkeyKong:update(dt)
    self.idleTimer = self.idleTimer + dt

    if self.throws then
        self.throwTimer = self.throwTimer + dt

        while self.throwTimer > self.throwDelay do
            self:throw()
            self.idleTimer = -DONKEYKONG_HOLDPOSE

            self.throwTimer = self.throwTimer - self.throwDelay
            self:newThrowDelay()
        end
    end
end

function DonkeyKong:draw()
    --determine which quad to use
    local quad = 5
    if self.throwTimer < DONKEYKONG_HOLDPOSE then
        quad = 4
    elseif self.throwTimer > self.throwDelay-DONKEYKONG_GETBARRELTIME then --throw animation
        quad = 4
    elseif self.throwTimer > self.throwDelay-DONKEYKONG_MIDDLETIME then --throw animation
        quad = 3
    elseif self.throwTimer > self.throwDelay-DONKEYKONG_IDLETIME then --get barrel animation
        quad = 2
    elseif math.fmod(self.idleTimer, DONKEYKONG_IDLEFRAMETIME*2) > DONKEYKONG_IDLEFRAMETIME then
        quad = 6
    end

    love.graphics.draw(donkeyKongImg, donkeyKongQuads[quad], self.x, self.y)
end

function DonkeyKong:newThrowDelay()
    self.throwDelay = self.delays[love.math.random(#self.delays)]
end

function DonkeyKong:throw() -- featuring steel, azk, dazed and swag
    local barrel = Barrel:new(game.level.world, unpack(self.throwAt))
    barrel.body:setLinearVelocity(unpack(self.throwForce))

    table.insert(game.barrels, barrel)
end