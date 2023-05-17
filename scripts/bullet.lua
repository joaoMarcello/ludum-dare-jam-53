-- local GC = require "jm-love2d-package.modules.gamestate.body_object"
local GC = _G.JM_Package.BodyObject
local lgx = love.graphics
local atan2 = math.atan2
local Anima = _G.JM_Anima

---@class Bullet : BodyObject
local Bullet = setmetatable({}, GC)
Bullet.__index = Bullet

local speed = 16 * 7

local img
---@type JM.Anima
local anima

function Bullet:new(x, y)
    local obj = GC:new(x, y, 10, 10, 15, 0, "ghost")
    setmetatable(obj, self)
    Bullet.__constructor__(obj)
    return obj
end

-- local anim_arg = { img = img }
--
function Bullet:__constructor__()
    ---@type GameState.Game | any
    local gamestate = self.gamestate
    local player_bd = gamestate:game_player().body
    local bd = self.body

    local dx = (bd.x + bd.w * 0.5) - (player_bd.x + player_bd.w * 0)
    local dy = (bd.y + bd.h * 0.5) - (player_bd.y + player_bd.h * 0.5)
    local angle = atan2(dy, dx)

    bd.allowed_gravity = false
    bd.allowed_air_dacc = false
    bd.dacc_x = 0
    bd.dacc_y = 0
    bd.speed_x = -speed * math.cos(angle)
    bd.speed_y = -speed * math.sin(angle)

    -- anim_arg.img = img
    self.anim = anima:copy() --Anima:new(anim_arg)

    -- if not anim_arg.__frame_obj_list__ then
    --     anim_arg.__frame_obj_list__ = self.anim.frames_list
    -- end

    self.update = Bullet.update
    self.draw = Bullet.draw
end

function Bullet:load()
    img = img or love.graphics.newImage("data/img/bullet.png")
    anima = anima or Anima:new { img = img, frames = 2, speed = 0.08 }
end

function Bullet:finish()
    img = nil
end

function Bullet:update(dt)
    -- GC.update(self, dt)
    self.__effect_manager:update(dt)

    self.anim:update(dt)

    ---@type GameState.Game | any
    local gamestate = self.gamestate
    local player = gamestate:game_player()
    local player_bd = player.body
    local bd = self.body

    if not gamestate.camera:rect_is_on_view(bd.x, bd.y, bd.w, bd.h) then
        self.__remove = true
        return
    end

    if bd:check_collision(player_bd:rect()) and not player:is_dead() then
        player:damage(self)
        self.__remove = true
    end
end

function Bullet:my_draw()
    -- lgx.setColor(1, 1, 0)
    -- lgx.rectangle("fill", self.x, self.y, self.w, self.h)
    self.anim:draw(self.x + self.w * 0.5, self.y + self.h * 0.5)
end

function Bullet:draw()
    GC.draw(self, self.my_draw)
end

return Bullet
