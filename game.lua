game = {}

function game.load(name)
    game.level = level:new(name)

    gameState = "game"

    game.barrels = {}
    game.marioMaskControllers = {}
    game.scrollingTexts = {}

    game.marios = {Mario:new(game.level.world, unpack(game.level.properties.mario.position))}
    game.donkeyKongs = {DonkeyKong:new(unpack(game.level.properties.donkeyKong.position))}

    joystickA = {0, 0}
    joystickH = "c"

    game.showBeta = true
    game.showBetaBlink = 0

    game.score = 0
    game.highScore = 12345
    
    playSound(mainMusic)   
end

function game.update(dt)
    if game.showBeta then
        game.showBetaBlink = game.showBetaBlink + dt
        return
    end

    updateGroup(game.barrels, dt)
    updateGroup(game.marioMaskControllers, dt)

    -- Traffic control the barrels
    for _, v in ipairs(game.barrels) do
        local x, y = v.body:getLinearVelocity()

        local fastness = math.abs(x)

        if fastness > BARREL_MAXSPEED then
            local factor = BARREL_MAXSPEED/fastness
            v.body:setLinearVelocity(x*factor, y)
        end
    end

    updateGroup(game.marios, dt)
    updateGroup(game.donkeyKongs, dt)
    game.level:update(dt)
    updateGroup(game.marios, dt, "postPhysicsUpdate")
    updateGroup(game.scrollingTexts, dt)

    myJoyController:update(dt)
    
    if MARIODEBUG then
        mainCamera:lookAt(game.marios[1].body:getPosition())
    end

    --Check for top
    local y = game.marios[1].body:getY()
    if y > HEIGHT then
        game.load("1")
    end
end

function game.draw()
    
    game.level:draw()
    --score
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(pixelFont)
    
    love.graphics.draw(uiPlayer1Img, 24, 16)
    local scoreFormatted = string.format("%06d", game.score)
    love.graphics.print(scoreFormatted, 32, 16)

    --top score
    love.graphics.draw(uiTopImg, 107, 16)
    local scoreFormatted = string.format("%06d", game.highScore)
    love.graphics.print(scoreFormatted, 128, 16)


    

    for _, v in ipairs(game.donkeyKongs) do
        v:draw()
    end

    for _, v in ipairs(game.barrels) do
        v:draw()
    end

    for _, v in ipairs(game.marios) do
        v:draw()
    end

    for _, v in ipairs(game.scrollingTexts) do
        v:draw()
    end

    if DEBUGDRAW then
        for _, body in ipairs(game.level.world:getBodyList()) do
            bodyDebug(body)
        end
        
        for _, v in ipairs(game.level.ladders) do
            v:debugDraw()
        end
        
        love.graphics.setColor(1, 1, 1)
    end

    if game.showBeta then
        love.graphics.setColor(0, 0, 0, 0.2)
        love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)
        love.graphics.setColor(1, 1, 1)

        function printthing(xoff, yoff)
            love.graphics.printf("this game is unfinished!", 16+xoff, 100+yoff, WIDTH-32, "center")

            if math.fmod(game.showBetaBlink, 1.3) > 0.4 then 
                love.graphics.printf("press space to start!", 0+xoff, 116+yoff, WIDTH, "center")
            end
        end

        love.graphics.setColor(0, 0, 0)
        for y = -1, 1, 2 do
            printthing(0, y)
        end

        for x = -1, 1, 2 do
            printthing(x, 0)
        end

        love.graphics.setColor(1, 1, 1)
        printthing(0, 0)
    end
end

function game.keypressed(key)
    if key == KEY_JUMP then
        for _, v in ipairs(game.marios) do
            v:jump()
        end
    end
    
    if key == KEY_UP then
        for _, v in ipairs(game.marios) do
            v:grabLadder("up")
        end
    end
    
    if key == KEY_DOWN then
        for _, v in ipairs(game.marios) do
            v:grabLadder("down")
        end
    end

    if key == KEY_LEFT then
        for _, v in ipairs(game.marios) do
            v:startMove("left")
        end
    elseif key == KEY_RIGHT then
        for _, v in ipairs(game.marios) do
            v:startMove("right")
        end
    end
end

function love.joystickpressed(joystick, button)
    if button == 1 then
        for _, v in ipairs(game.marios) do
            v:jump()
        end
    end
end

function game.beginContact(a, b, coll)
    local bData = b:getUserData()
    local aData = a:getUserData()

    -- Barrel -> Girder dirchanges
    for _, dirChange in ipairs(game.level.dirChanges) do
        local girderFixture, barrelFixture

        if a == dirChange.fixture and bData.object:isInstanceOf(Barrel) then
            girderFixture = a
            barrelFixture = b
        elseif b == dirChange.fixture and aData.object:isInstanceOf(Barrel) then
            girderFixture = b
            barrelFixture = a
        end

        if girderFixture then
            local barrelObj = barrelFixture:getUserData().object
            
            if not table.contains(barrelObj.turnedAroundOn, girderFixture) then
                local barrelBody = barrelFixture:getBody()
                local x, y = barrelBody:getLinearVelocity()
                
                if barrelObj.fallingDownLadder then
                    -- Make barrel move sideways more than it realistically should
                    local dir = coll:getNormal()
                    local xVel = 40
                    
                    if dir <= 0 then
                        xVel = -xVel
                    end
                    
                    barrelBody:setLinearVelocity(xVel, y*0.7)
                else
                    if (dirChange.dir == "left" and x > 0) or (dirChange.dir == "right" and x < 0) then
                        barrelBody:setLinearVelocity(-x, y)
                    end
                end
                
                --Don't turn around again
                table.insert(barrelObj.turnedAroundOn, girderFixture)
            end
        end
    end
    
    -- Barrel fallthrough animation
    local stopFallBarrel = false
    if aData.object:isInstanceOf(Barrel) and aData.object.fallingDownLadder then
        stopFallBarrel = aData.object
    elseif bData.object:isInstanceOf(Barrel) and bData.object.fallingDownLadder then
        stopFallBarrel = bData.object
    end
    
    if stopFallBarrel then
        stopFallBarrel.fallingDownLadder = false
    end

    -- Barrel -> Mario on ladder
    local bData = b:getUserData()
    local aData = a:getUserData()

    local mario
    local obj2
    
    if aData.object:isInstanceOf(Mario) and not bData.object:isInstanceOf(Mario) then
        mario = aData.object
        obj2 = bData.object
    elseif bData.object:isInstanceOf(Mario) and not aData.object:isInstanceOf(Mario)  then
        mario = bData.object
        obj2 = aData.object
    end

    if mario then
        mario:contact(obj2)
    
        if obj2:isInstanceOf(Barrel) and mario.ladder then
            mario:releaseLadder()
        end
    end
end

function game.preSolve(a, b, coll)
    local bData = b:getUserData()
    local aData = a:getUserData()
    
    local marioFixture = false
    local otherFixture = false
    if aData.object:isInstanceOf(Mario) and bData.object:isInstanceOf(Girder) then
        marioFixture = a
        otherFixture = b
    elseif bData.object:isInstanceOf(Mario) and aData.object:isInstanceOf(Girder) then
        marioFixture = b
        otherFixture = a
    end

    if marioFixture then
        marioObject = marioFixture:getUserData().object
        
        if marioObject.ladder then
            return
        end
        
        --check whether the girder was made passable already
        local vx, vy = coll:getNormal()
        if vy > 0.8 then
            if not table.contains({otherFixture:getMask()}, CATEGORY_TEMPORARY_PASSTHROUGH_GIRDERS) then
                -- Temporarily mask Mario and this girder so that Mario can jump through the bottom
                table.insert(game.marioMaskControllers, MarioMaskController:new(marioObject, otherFixture:getUserData().object))
            end

            coll:setEnabled(false)
        end
    end
end

function game.addScore(points)
    playSound(scoreSound)
    
    game.score = game.score + points
end

function game.addScrollingText(text, x, y)
    local myScrollingText = ScrollingText:new(text, x, y)

    table.insert(game.scrollingTexts, myScrollingText)
end