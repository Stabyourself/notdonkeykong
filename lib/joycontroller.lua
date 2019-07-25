local JoyController = class("JoyController")

function JoyController:init(i)
    self.i = i

    local joysticks = love.joystick.getJoysticks()

    self.joystick = joysticks[i]

    if self.joystick then
        self.initialized = true
    end

    self.axisBinds = {}
    self.hatBinds = {}
    self.butBinds = {}
end

function JoyController:update(dt)
    for _, v in ipairs(self.axisBinds) do
        val = self.joystick:getAxis(v.num)

        if v.dir == "pos" then
            if v.last < JOY_DEADZONE then
                if val >= JOY_DEADZONE then
                    v.func()
                end
            end

        elseif v.dir == "neg" then
            if v.last > -JOY_DEADZONE then
                if val <= -JOY_DEADZONE then
                    v.func()
                end
            end

        end

        v.last = val
    end

    for _, v in ipairs(self.hatBinds) do
        val = self.joystick:getHat(v.num)

        if v.last == "c" then
            if string.find(val, v.dir) then
                v.func()
            end
        end

        v.last = val
    end
end

function JoyController:bind(input, func)
    for _, v in ipairs(input) do
        if v[1] == "axis" then
            table.insert(self.axisBinds, {
                num = v[2],
                dir = v[3],
                func = func,
                last = 0
            })

        elseif v[1] == "hat" then
            table.insert(self.hatBinds, {
                num = v[2],
                dir = v[3],
                func = func,
                last = 0
            })

        end
    end
end

return JoyController
