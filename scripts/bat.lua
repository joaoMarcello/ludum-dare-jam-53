local GC = require "lib.bodyComponent"
local lgx = love.graphics
local atan2, sqrt, cos, sin = math.atan2, math.sqrt, math.cos, math.sin

---@enum Bat.States
local States = {
    idle = 0,
    chase = 1,
    dead = 2,

}

---@class Bat : BodyComponent
local Bat = setmetatable({}, GC)
Bat.__index = Bat

local max_speed = 16 * 5
local speed = 16 * 2.5
local acc = 16 * 2
local dacc = 16 * 7

function Bat:new(state, world, args)
    args = args or {}

    args = args or {}
    args.type = "dynamic"
    args.x = args.x or (16 * 5)
    args.y = args.y or (16 * 2)
    args.w = 12
    args.h = 12
    args.y = args.bottom and (args.bottom - args.h) or args.y

    local obj = GC:new(state, world, args)
    setmetatable(obj, self)
    Bat.__constructor__(obj, args)
    return obj
end

function Bat:__constructor__(args)
    local bd = self.body

    bd.allowed_gravity = false
    bd.allowed_air_dacc = true

    bd.max_speed_x = max_speed
    bd.max_speed_y = max_speed
    bd.acc_x = acc
    bd.acc_y = acc
    bd.dacc_x = dacc
    bd.dacc_y = dacc

    self.hp = 1
end

function Bat:load()

end

function Bat:finish()

end

function Bat:update(dt)
    GC.update(self, dt)

    ---@type GameState.Game | JM.Scene | any
    local gamestate = self.gamestate
    local player = gamestate:game_player()
    local player_bd = player.body
    local bd = self.body

    local dx = (bd.x + bd.w * 0.5) - (player_bd.x + player_bd.w * 0.5)
    local dy = (bd.y + bd.h * 0.5) - (player_bd.y + player_bd.h * 0.5)
    local angle = atan2(dy, dx)
    local dist = sqrt(dx ^ 2 + dy ^ 2)

    bd:apply_force(-speed * cos(angle), -speed * sin(angle))
end

function Bat:my_draw()
    lgx.setColor(1, 0, 0)
    lgx.rectangle("fill", self.body:rect())
end

function Bat:draw()
    GC.draw(self, self.my_draw)
end

return Bat
