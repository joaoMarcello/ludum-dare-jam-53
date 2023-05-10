local GC = require "jm-love2d-package.modules.gamestate.game_object"
-- local GC = require "lib.component"

local pairs = pairs

---@class Smoke : GameObject
local Smoke = setmetatable({}, GC)
Smoke.__index = Smoke

local img
local Anima = _G.JM_Anima

local smoke_obj = setmetatable({}, { __mode = 'k' })
local function smoke_push(obj)
    smoke_obj[obj] = true
end

local function smoke_pop()
    for obj, _ in pairs(smoke_obj) do
        for _, v in pairs(obj) do
            obj[_] = nil
        end

        smoke_obj[obj] = nil

        return obj
    end
end


function Smoke:new(x, y, wait)
    local obj = GC:new(x, y, 8, 8, -3, 0, smoke_pop())
    setmetatable(obj, self)
    Smoke.__constructor__(obj, wait)
    return obj
end

local arg = { img = img, frames = 4, stop_at_the_end = true, duration = 1 }
-- local anim_quad
local anim_frames_obj
local animas = setmetatable({}, { __mode = 'k' })

local function anim_pop()
    for obj, _ in pairs(animas) do
        animas[obj] = nil
        obj:reset()
        return obj
    end
end

local function anim_push(obj)
    animas[obj] = true
end

function Smoke:__constructor__(wait)
    self.ox = 4
    self.oy = 4

    arg.img = img
    arg.__frame_obj_list__ = anim_frames_obj
    -- arg.__quad__ = anim_quad

    local anima = anim_pop()
    self.anim = anima or Anima:new(arg)

    -- if not anim_quad then
    --     anim_quad = self.anim.quad
    -- end
    if not anim_frames_obj then
        anim_frames_obj = self.anim.frames_list
    end

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

    if self.anim.time_paused >= 0.1 and not self.__remove then
        self.__remove = true
        smoke_push(self)
        anim_push(self.anim)
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
