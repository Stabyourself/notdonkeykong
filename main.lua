require "loop"

function love.load()
    require "variables"

    love.graphics.setDefaultFilter("nearest", "nearest")
    love.physics.setMeter(WORLD_METER)

    if FULLSCREEN then
        love.window.setMode(1680, 1050, {msaa = MSAA, vsync = VSYNC, fullscreen = true})
    else
        love.window.setMode(WIDTH*SCALE, HEIGHT*SCALE, {msaa = MSAA, vsync = VSYNC})
    end
    love.graphics.setLineWidth(1/SCALE)

    HC = require "lib/hc"
    class = require "lib/class"
    json = require "lib/json"
    camera = require "lib/camera"
    JoyController = require "lib/joycontroller"
    easing = require "lib/easing"

    require "level"
    require "mariomaskcontroller"
    require "donkeykong"
    require "barrel"
    require "girder"
    require "ladder"
    require "mario"
    require "scrollingtext"
    require "game"
    
    -- Sounds
    mainMusic = love.audio.newSource("sound/music.ogg", "stream")
    mainMusic:setLooping(true)
    jumpSound = love.audio.newSource("sound/jump.ogg", "static")
    scoreSound = love.audio.newSource("sound/score.ogg", "static")
    
    mainMusic:setVolume(VOLUME)
    jumpSound:setVolume(VOLUME)
    scoreSound:setVolume(VOLUME)

    local pixelGlyphs = "0123456789abcdefghijklmnopqrstuvwxyz.:/,\"C-_> <!"
    pixelFont = love.graphics.newImageFont("img/font.png", pixelGlyphs, 1)
    pixelFont:setLineHeight(1.75)

    local scoreGlyphs = "0123456789"
    scoreFont = love.graphics.newImageFont("img/scorefont.png", scoreGlyphs, 1)

    donkeyKongImg = love.graphics.newImage("img/dankeykang.png")
    donkeyKongQuads = {}
    for i = 1, 6 do
        donkeyKongQuads[i] = love.graphics.newQuad((i-1)*48, 0, 48, 32, donkeyKongImg:getWidth(), donkeyKongImg:getHeight())
    end

    barrelImg = love.graphics.newImage("img/barrel.png")
    barrelFallImg = love.graphics.newImage("img/barrel_fall.png")
    
    barrelFallQuad = {}
    
    for y = 1, 2 do
        barrelFallQuad[y] = love.graphics.newQuad(0, (y-1)*10, 15, 10, 15, 20)
    end
    
    marioImg = love.graphics.newImage("img/plumber.png")
    marioQuads = {}
    for i = 1, 8 do
        marioQuads[i] = love.graphics.newQuad((i-1)*16, 0, 16, 24, marioImg:getWidth(), marioImg:getHeight())
    end
    table.insert(marioQuads, 3, marioQuads[1])

    armImg = love.graphics.newImage("img/arm.png")
    legImg = {love.graphics.newImage("img/leg1.png"), love.graphics.newImage("img/leg2.png")}

    uiPlayer1Img = love.graphics.newImage("img/ui_player1.png")
    uiTopImg = love.graphics.newImage("img/ui_top.png")

    mainCamera = camera.new(WIDTH*.5, HEIGHT*.5)
    mainCamera:zoomTo(SCALE*ZOOM)

    myJoyController = JoyController:new(1)

    if myJoyController.initialized then
        myJoyController:bind({
            {"axis", 2, "neg"},
            {"hat", 1, "u"},
        }, function()
            for _, v in ipairs(game.marios) do
                v:grabLadder("up")
            end
        end)

        myJoyController:bind({
            {"axis", 2, "pos"},
            {"hat", 1, "d"},
        }, function()
            for _, v in ipairs(game.marios) do
                v:grabLadder("down")
            end
        end)

        myJoyController:bind({
            {"axis", 1, "neg"},
            {"hat", 1, "l"},
        }, function()
            for _, v in ipairs(game.marios) do
                v:startMove("left")
            end
        end)

        myJoyController:bind({
            {"axis", 1, "pos"},
            {"hat", 1, "r"},
        }, function()
            for _, v in ipairs(game.marios) do
                v:startMove("right")
            end
        end)
    end
    
    game.load("1")
    love.graphics.setFont(love.graphics.newFont(14))
end

function love.update(dt)
    dt = math.min(1/10, dt) -- limit dt just in case
    

	if FFKEYS then
		for _, v in ipairs(FFKEYS) do
			if love.keyboard.isDown(v.key) then
				dt = dt * v.val
			end
		end
	end

    if gameState == "game" then
        game.update(dt)
    end

    love.window.setTitle("Wonkey Kong (FPS: " .. love.timer.getFPS() .. ")")
end

function love.draw()
    mainCamera:attach()

    if gameState == "game" then
        game.draw()
    end
    mainCamera:detach()
end

function love.keypressed(key)
    if key == KEY_EXIT then
        love.event.quit()
    end

    if gameState == "game" then
        game.keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    --mod x and y to camera, yo
    x, y = mainCamera:worldCoords(x, y)

    if button == 1 then
        local someBarrel = Barrel:new(game.level.world, x, y)

        table.insert(game.barrels, someBarrel)
    end

    if button == 2 then
        game.marios[1].body:setPosition(x, y)
        game.marios[1].body:setLinearVelocity(0, 0)
        game.marios[1].body:setAngularVelocity(0)
        game.marios[1].body:setAngle(0)
        game.marios[1].rotationStart = 0
        game.marios[1]:releaseLadder()
        
        for i = 1, 2 do
            game.marios[1].armBody[i]:setPosition(x+MARIO_ARMOFFSET[i][1], x+MARIO_ARMOFFSET[i][2])
            game.marios[1].armBody[i]:setLinearVelocity(0, 0)
            game.marios[1].armBody[i]:setAngularVelocity(0)
            game.marios[1].armBody[i]:setAngle(0)

            game.marios[1].legBody[i]:setPosition(x+MARIO_LEGOFFSET[i][1], x+MARIO_LEGOFFSET[i][2])
            game.marios[1].legBody[i]:setLinearVelocity(0, 0)
            game.marios[1].legBody[i]:setAngularVelocity(0)
            game.marios[1].legBody[i]:setAngle(0)
        end
    end

    if button == 3 then
        table.insert(game.marios, Mario:new(game.level.world, x, y))
    end
end

function updateGroup(group, dt, func)
    func = func or "update"
	local delete = {}
	
	for i, v in ipairs(group) do
		if v[func](v, dt) or v.deleteme then
			table.insert(delete, i)
		end
	end
	
	table.sort(delete, function(a,b) return a>b end)
	
	for _, v in ipairs(delete) do
		table.remove(group, v) --remove
	end
end

function round(f, base)
    base = base or 1

    if f < 0 then
        return math.ceil((f-base*.5)/base)*base
    else
        return math.floor((f+base*.5)/base)*base
    end
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function bodyDebug(body) -- body debug is like that thing those dentists do with the people who got maggots in their teeth
    for _, fixture in ipairs(body:getFixtures()) do
        local shape = fixture:getShape()

        local type = shape:getType()

        if type == "polygon" then
            local points = {body:getWorldPoints(shape:getPoints())}

            for i, _ in ipairs(points) do
                points[i] = points[i]-.5/SCALE/ZOOM
            end

            love.graphics.polygon("line", unpack(points))
        elseif type == "circle" then
            local x, y = body:getWorldPoint(shape:getPoint())

            love.graphics.circle("line", x-.5/SCALE/ZOOM, y-.5/SCALE/ZOOM, shape:getRadius(), 30)
        end
    end
end

function print_r (t, indent) --Not by me
	local indent=indent or ''
	for key,value in pairs(t) do
		io.write(indent,'[',tostring(key),']') 
		if type(value)=="table" then io.write(':\n') print_r(value,indent..'\t')
		else io.write(' = ',tostring(value),'\n') end
	end
end

function normalizeAngle(a)
    a = math.fmod(a+math.pi, math.pi*2)-math.pi
    a = math.fmod(a-math.pi, math.pi*2)+math.pi

    return a
end

function fixtureAddMask(fixture, category)
    local categories = {fixture:getMask()}

    if not table.contains(categories, category) then
        table.insert(categories, category)
    end

    fixture:setMask(unpack(categories))
end

function fixtureRemoveMask(fixture, category)
    local categories = {fixture:getMask()}

    for i, v in ipairs(categories) do
        if v == category then
            table.remove(categories, i)
            break
        end
    end

    fixture:setMask(unpack(categories))
end

function keyUp()
    if love.keyboard.isDown(KEY_UP) then
        return true
    end

    if myJoyController.joystick then
        local h = myJoyController.joystick:getHat(1)

        if h == "lu" or h == "u" or h == "ru" then
            return true
        end
        
        local joy = myJoyController.joystick:getAxis(2)

        if joy < -JOY_DEADZONE then
            return true
        end
    end

    return false
end

function keyDown()
    if love.keyboard.isDown(KEY_DOWN) then
        return true
    end

    if myJoyController.joystick then
        local h = myJoyController.joystick:getHat(1)

        if h == "ld" or h == "d" or h == "rd" then
            return true
        end
        
        local joy = myJoyController.joystick:getAxis(2)

        if joy > JOY_DEADZONE then
            return true
        end
    end

    return false
end

function keyLeft()
    if love.keyboard.isDown(KEY_LEFT) then
        return true
    end

    if myJoyController.joystick then
        local h = myJoyController.joystick:getHat(1)

        if h == "lu" or h == "l" or h == "ld" then
            return true
        end
        
        local joy = myJoyController.joystick:getAxis(1)

        if joy < -JOY_DEADZONE then
            return true
        end
    end

    return false
end

function keyRight()
    if love.keyboard.isDown(KEY_RIGHT) then
        return true
    end

    if myJoyController.joystick then
        local h = myJoyController.joystick:getHat(1)

        if h == "ru" or h == "r" or h == "rd" then
            return true
        end
        
        local joy = myJoyController.joystick:getAxis(1)

        if joy > JOY_DEADZONE then
            return true
        end
    end

    return false
end

function playSound(sound)
    sound:stop()
    sound:play()
end
