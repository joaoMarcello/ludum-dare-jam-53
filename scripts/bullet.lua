local GC = require "lib.bodyComponent"
-- local GC = require "jm-love2d-package.modules.gamestate.body_object"
local lgx = love.graphics
local atan2 = math.atan2
local Anima = _G.JM_Anima

---@class Bullet : BodyComponent
local Bullet = setmetatable({}, GC)
Bullet.__index = Bullet

local speed = 16 * 7

local img

function Bullet:new(state, world, args)
    args = args or {}
    args.w = 10
    args.h = 10
    args.draw_order = 15
    args.type = "ghost"

    local obj = GC:new(state, world, args)
    setmetatable(obj, self)
    Bullet.__constructor__(obj)
    return obj
end

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

    self.anim = Anima:new { img = img }
end

function Bullet:load()
    img = img or love.graphics.newImage("data/img/bullet.png")
end

function Bullet:finish()
    img = nil
end

function Bullet:update(dt)
    GC.update(self, dt)

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
