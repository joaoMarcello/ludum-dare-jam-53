local GC = require "lib.bodyComponent"
local lgx = love.graphics
local atan2 = math.atan2

---@class Bullet : BodyComponent
local Bullet = setmetatable({}, GC)
Bullet.__index = Bullet

local speed = 16 * 8.5

function Bullet:new(state, world, args)
    args = args or {}
    args.w = 10
    args.h = 10
    args.draw_order = 15
    args.type = "ghost"

    local obj = GC:new(state, world, args)
    setmetatable(obj, self)
    Bullet.__constructor__(obj, args)
    return obj
end

function Bullet:__constructor__(args)
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
end

function Bullet:load()

end

function Bullet:finish()

end

function Bullet:update(dt)
    GC.update(self, dt)

    ---@type GameState.Game | any
    local gamestate = self.gamestate
    local player_bd = gamestate:game_player().body
    local bd = self.body

    if not gamestate.camera:rect_is_on_view(bd.x, bd.y, bd.w, bd.h) then
        self.__remove = true
        return
    end

    if bd:check_collision(player_bd:rect()) then
        self.__remove = true
    end
end

function Bullet:my_draw()
    lgx.setColor(1, 1, 0)
    lgx.rectangle("fill", self.x, self.y, self.w, self.h)
end

function Bullet:draw()
    GC.draw(self, self.my_draw)
end

return Bullet
