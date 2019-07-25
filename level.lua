level = class("level")

function level:init(name)
    self.name = name

    self.img = love.graphics.newImage("levels/" .. self.name .. ".png")
    self.properties = json.decode(love.filesystem.read("levels/" .. self.name .. ".json"))
    self.world = love.physics.newWorld(0, GRAVITY)
    
    self.world:setCallbacks(
        function(...) game.beginContact(...) end, 
        function() end, 
        function(...) game.preSolve(...) end, 
        function() end
    )

    self.fixtures = {}

    self.girders = {}
    self.dirChanges = {}
    local fixture, shape

    for _, girder in ipairs(self.properties.girders) do
        local myGirder = Girder:new(self.world, girder)
        table.insert(self.girders, myGirder)
        
        for i, fixture in ipairs(girder) do
            if fixture.dirChange then
                table.insert(self.dirChanges, {
                    dir = fixture.dirChange,
                    fixture = myGirder.fixtures[i]
                })
            end
        end
    end
    
    self.ladders = {}
    
    for _, ladder in ipairs(self.properties.ladders) do
        local myLadder = Ladder:new(ladder.x, ladder.y, ladder.height, ladder.connectsTop, ladder.connectsBottom)
        table.insert(self.ladders, myLadder)
    end
end

function level:update(dt)
    self.world:update(dt)
end

function level:draw()
    love.graphics.draw(self.img)
end