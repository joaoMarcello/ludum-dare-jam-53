-- local GC = require "lib.bodyComponent"
local GC = require "jm-love2d-package.modules.gamestate.body_object"
local lgx = love.graphics

---@class Heart : BodyObject
local Heart = setmetatable({}, GC)
Heart.__index = Heart

local score = 500

local img

function Heart:new(x, y, bottom)
    -- args = args or {}
    -- args.x = args.x or 32
    -- args.y = args.y or 0
    -- args.w = 14
    -- args.h = 14
    -- args.type = "dynamic"
    -- args.draw_order = -2
    x = x or 32
    y = y or 0
    if bottom then
        y = bottom - 14
    end

    local obj = GC:new(x, y, 14, 14, -2, 0, "dynamic")
    setmetatable(obj, self)
    Heart.__constructor__(obj)
    return obj
end

function Heart:__constructor__()
    local bd = self.body
    bd.allowed_gravity = true
    bd.bouncing_y = 0.9
    bd.mass = bd.mass * 0.3
    bd.max_speed_y = 16 * 2.5
    bd.speed_y = bd.max_speed_y

    self.ox = self.w * 0.5
    self.oy = self.h * 0.5

    self.duration = 10

    self.anim = _G.JM_Anima:new { img = img }

    self:apply_effect("pulse", { range = 0.1, speed = 1 })
end

function Heart:load()
    img = img or love.graphics.newImage("data/img/heart.png")
end

function Heart:finish()

end

local tab = { speed = 0.1 }
function Heart:update(dt)
    GC.update(self, dt)
    self.anim:update(dt)

    ---@type GameState.Game | any
    local gamestate = self.gamestate
    local player = gamestate:game_player()
    local bd = self.body

    if not player:is_dead() then
        if player.body:check_collision(bd:rect()) then
            gamestate:game_add_score(score)
            player:hp_up(1)
            gamestate:display_text(tostring(score), bd.x, bd.y - 32, 2)
            _G.PLAY_SFX("power_up", false)
            self.__remove = true
            return
        end
    end

    self.duration = self.duration - dt
    if self.duration <= 0 then
        self.__remove = true
    elseif self.duration <= 2.5 then
        self:apply_effect("flickering", tab)
    end
end

function Heart:my_draw()
    -- lgx.setColor(1, 0, 0)
    -- lgx.rectangle("fill", self.body:rect())

    self.anim:draw(self.x + self.w * 0.5, self.y + self.h * 0.5)
end

function Heart:draw()
    GC.draw(self, self.my_draw)
end

return Heart
