local GC = require "lib.component"

---@class Smoke : GameComponent
local Smoke = setmetatable({}, GC)
Smoke.__index = Smoke

local img
local Anima = _G.JM_Anima

local tab = {}
function Smoke:new(state, x, y, wait)
    tab.x = x
    tab.y = y
    tab.w = 8
    tab.h = 8
    tab.draw_order = -3
    tab.wait = wait

    local obj = GC:new(state, tab)
    setmetatable(obj, self)
    Smoke.__constructor__(obj)
    return obj
end

local arg = { img = img, frames = 4, stop_at_the_end = true, duration = 1 }
function Smoke:__constructor__(wait)
    self.ox = 4
    self.oy = 4

    arg.img = img
    self.anim = Anima:new(arg)

    self.wait = wait
end

function Smoke:load()
    img = img or love.graphics.newImage("data/img/smoke-Sheet.png")
end

function Smoke:finish()
    img = nil
end

function Smoke:update(dt)
    if self.wait then
        self.wait = self.wait - dt
        if self.wait <= 0 then
            return
        else
            self.wait = nil
        end
    end

    GC.update(self, dt)

    self.anim:update(dt)

    if self.anim.time_paused >= 0.1 then
        self.__remove = true
    end
end

function Smoke:my_draw()
    if self.wait then return end
    self.anim:draw_rec(self.x, self.y, self.w, self.h)
end

function Smoke:draw()
    GC.draw(self, self.my_draw)
end

return Smoke
