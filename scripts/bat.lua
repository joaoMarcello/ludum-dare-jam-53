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

    ---@type GameState.Game | JM.Scene | any
    local gamestate = self.gamestate

    if not gamestate.camera:rect_is_on_view(bd:rect()) then
        -- self.time_state = self.time_state + dt * 3.0
        self.dur_idle = 0
    end

    -- bd.speed_x = 0.0
    -- bd.speed_y = 0.0
    -- bd.acc_x = 0.0
    -- bd.acc_y = 0.0

    if self.time_state >= self.dur_idle
        and not gamestate:game_player():is_dead()
    then
        self.dur_idle = 3 * math.random()
        self:set_state(States.chase)
    end

    self:shoot(dt)
end

---@param self Bat
local dead = function(self, dt)
    local bd = self.body

    if self.time_state >= 5
    then
        self.__remove = true
    end
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

    self.hp = 2
    self.max_hp = 4

    self.state = nil
    self:set_state(States.chase)

    self.time_shoot = -5.0 * math.random()
    self.time_state = 0.0
    self.dur_idle = 3 * math.random()
    self.dur_chase = 4 + 3 * math.random()
end

function Bat:is_dead()
    return self.state == States.dead or self.hp <= 0
end

function Bat:damage(value)
    if self:is_dead() then return false end

    value = value or 1

    self.hp = Utils:clamp(self.hp - value, 0, self.max_hp)

    if self.hp == 0 then
        self:set_state(States.dead)
    end

    return true
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
        --
    elseif state == States.dead then
        self.cur_movement = dead
        bd.allowed_air_dacc = false
        bd.allowed_gravity = true
        bd.speed_y = 0.0
        bd.speed_x = bd.speed_x < 0 and (-32) or 32
        bd.mass = bd.world.default_mass * 0.5
        bd.type = bd.Types.ghost
        bd.max_speed_y = nil
        bd:jump(16 * 2, -1)
        self:set_draw_order(16)
        --
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

    if self.time_shoot >= speed_shoot
        and not gamestate:game_player():is_dead()
    then
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
    local font = JM_Font.current
    font:print(tostring(self.hp), self.x, self.y - 10)
end

return Bat
