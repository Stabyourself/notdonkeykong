function love.run()
	love.math.setRandomSeed(os.time())
	love.load(arg)
 
	-- We don't want the first frame's dt to include time taken by love.load.
	love.timer.step()
 
	local dt = 0
 
	-- Main loop time.
	while true do
		-- Process events.
		love.event.pump()
		for name, a,b,c,d,e,f in love.event.poll() do
			if name == "quit" then
				if not love.quit or not love.quit() then
					return a
				end
			end
			love.handlers[name](a,b,c,d,e,f)
		end
 
		-- Update dt, as we'll be passing it to update
		love.timer.step()
		dt = love.timer.getDelta()
 
		-- Call update and draw
		love.update(dt) -- will pass 0 if love.timer is disabled
 
		love.graphics.clear(love.graphics.getBackgroundColor())
		love.graphics.origin()
		love.draw()
		love.graphics.present()
 
		if not production then love.timer.sleep(0.001) end
	end
end