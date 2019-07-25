Girder = class("Girder")

function Girder:init(world, fixtures) -- girders don't have their own body. like a Linkin Park song or something
    self.body = love.physics.newBody(world, 0, 0)
    self.fixtureDefinitions = fixtures

    self.fixtures = {}

    for _, v in ipairs(self.fixtureDefinitions) do
        local myShape
        local myFixture

        self.vertices = v.vertices

        local points = {}
        for _, w in ipairs(self.vertices) do
            table.insert(points, w[1])
            table.insert(points, w[2])
        end
        
        myShape = love.physics.newPolygonShape(unpack(points))
        
        myFixture = love.physics.newFixture(self.body, myShape)
        myFixture:setUserData({
            object = self
        })

        if(v.collidesWithBarrels == false) then
            fixtureAddMask(myFixture, CATEGORY_NO_BARREL_COLLISION)
        end
        
        fixtureAddMask(myFixture, CATEGORY_TEMPORARY_PASSTHROUGH_BARRELS)
        
        myFixture:setCategory(
            CATEGORY_PERMANENT_PASSTHROUGH_MARIOS
        )

        table.insert(self.fixtures, myFixture)
    end
end
