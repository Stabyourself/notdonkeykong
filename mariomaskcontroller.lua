MarioMaskController = class("MarioMaskController")

function MarioMaskController:init(mario, other)
    self.mario = mario
    self.other = other

    for _, fixture in ipairs(self.other.body:getFixtures()) do
        fixtureAddMask(fixture, CATEGORY_TEMPORARY_PASSTHROUGH_GIRDERS)
    end
end

function hcShapeListFromBody(body)
    local hcShapes = {}

    for _, fixture in ipairs(body:getFixtures()) do
        local b2Shape = fixture:getShape()

        if b2Shape:getType() == "polygon" then
            local points = {body:getWorldPoints(b2Shape:getPoints())}
            local hcShape = HC.polygon(unpack(points))

            table.insert(hcShapes, hcShape)

        elseif b2Shape:getType() == "circle" then
            local x, y = body:getWorldPoint(b2Shape:getPoint())
            local hcShape = HC.circle(x, y, b2Shape:getRadius())
            
            table.insert(hcShapes, hcShape)
        end
    end

    return hcShapes
end

function MarioMaskController:update(dt)
    local _, vy = self.mario.body:getLinearVelocity()
    
    --create hc objects
    local marioShapes = hcShapeListFromBody(self.mario.body)
    local otherShapes = hcShapeListFromBody(self.other.body)
    
    local collision = false
    for _, marioShape in ipairs(marioShapes) do
        for _, otherShape in ipairs(otherShapes) do
            if marioShape:collidesWith(otherShape) then
                collision = true
            end
        end
    end

    if not collision then
        for _, fixture in ipairs(self.other.body:getFixtures()) do
            fixtureRemoveMask(fixture, CATEGORY_TEMPORARY_PASSTHROUGH_GIRDERS)
        end
        
        return true
    end
end