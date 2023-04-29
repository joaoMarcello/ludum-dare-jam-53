local GC = require "lib.bodyComponent"
local Bullet = require "scripts.bullet"
local Utils = _G.JM_Utils

local lgx = love.graphics
local atan2, sqrt, cos, sin = math.atan2, math.sqrt, math.cos, math.sin
local random = love.math.random

---@enum Bat.States
local States = {
    idle = 0,
    chase = 1,
    dead = 2,
    atk = 3,
}

local max_speed = 16 * 5
local speed = 16 * 2.5
local acc = 16 * 4
local dacc = 16 * 8
local speed_shoot = 2

---@param self Bat
local chase = function(self, dt)
    ---@type GameState.Game | JM.Scene | any
    local gamestate = self.gamestate
    local player = gamestate:game_player()
    local player_bd = player.body
    local bd = self.body

    local dx = (bd.x + bd.w * 0.5) - (player_bd.x + player_bd.w * 0.5)
    local dy = (bd.y + bd.h * 0.5) - (player_bd.y + player_bd.h * 0.5)
    local angle = atan2(dy, dx)
    -- local dist = sqrt(dx ^ 2 + dy ^ 2)

    bd:apply_force(-speed * cos(angle), -speed * sin(angle))

    if self.time_state >= self.dur_chase then
        self.dur_chase = 4 + 3 * math.random()
        self:set_state(States.idle)
    end

    self:shoot(dt)
end

---@param self Bat
local idle = function(self, dt)
    local bd = self.body

    -- bd.speed_x = 0.0
    -- bd.speed_y = 0.0
    -- bd.acc_x = 0.0
    -- bd.acc_y = 0.0

    if self.time_state >= self.dur_idle then
        self.dur_idle = 3 * math.random()
        self:set_state(States.chase)
    end

    self:shoot(dt)
end

---@class Bat : BodyComponent
local Bat = setmetatable({}, GC)
Bat.__index = Bat


function Bat:new(state, world, args)
    args = args or {}

    args = args or {}
    args.type = "dynamic"
    args.x = args.x or (16 * 5)
    args.y = args.y or (16 * 2)
    args.w = 12
    args.h = 12
    args.y = args.bottom and (args.bottom - args.h) or args.y
    args.draw_order = 5

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
    bd.id = "bat"

    self.hp = 1

    self.state = nil
    self:set_state(States.chase)

    self.time_shoot = -5.0 * math.random()
    self.time_state = 0.0
    self.dur_idle = 3 * math.random()
    self.dur_chase = 4 + 3 * math.random()
end

function Bat:set_state(state)
    if state == self.state then return false end
    local bd = self.body
    local last = self.state
    self.state = state

    if state == States.chase then
        self.cur_movement = chase
        --
    elseif state == States.idle then
        self.cur_movement = idle
    end

    self.time_state = 0.0
    return true
end

function Bat:load()
    Bullet:load()
end

function Bat:finish()
    Bullet:finish()
end

function Bat:shoot(dt)
    ---@type GameState.Game | JM.Scene | any
    local gamestate = self.gamestate
    local bd = self.body

    self.time_shoot = self.time_shoot + dt
    if self.time_shoot >= speed_shoot then
        self.time_shoot = self.time_shoot - speed_shoot - 4 * random()
        if self.time_shoot >= speed_shoot then self.time_shoot = 0.0 end

        gamestate:game_add_component(Bullet:new(gamestate, bd.world,
            {
                x = bd.x,
                y = bd.y,
            }
        ))
    end
end

function Bat:update(dt)
    GC.update(self, dt)

    self.time_state = self.time_state + dt
    self:cur_movement(dt)

    local bd = self.body

    self.x, self.y = Utils:round(bd.x), Utils:round(bd.y)
end

function Bat:my_draw()
    lgx.setColor(1, 0, 0)
    lgx.rectangle("fill", self.body:rect())
end

function Bat:draw()
    GC.draw(self, self.my_draw)
end

return Bat
