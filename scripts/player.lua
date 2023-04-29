local GC = require "lib.bodyComponent"
local Utils = _G.JM_Utils

local keys = {
    left = { 'left', 'a' },
    right = { 'right', 'd' },
    down = { 'down', 's' },
    jump = { 'space', 'up', 'w' },
    atk = { 'e', 'q', 'f' },
}

---@enum Player.States
local States = {
    default = 0,
    idle = 1,
    atk = 2,
    dead = 3,
    fall = 4,
    damage = 5,
    move = 6,
    up = 7,
}
--==========================================================================
local keyboard_is_down = love.keyboard.isDown
local math_abs, type = math.abs, type
local lgx = love.graphics

local function pressing(key)
    local field = keys[key]
    if not field then return nil end

    if type(field) == "string" then
        return keyboard_is_down(field)
    else
        return keyboard_is_down(field[1])
            or (field[2] and keyboard_is_down(field[2]))
            or (field[3] and keyboard_is_down(field[3]))
    end
end

local function pressed(key, key_pressed)
    local field = keys[key]
    if not field then return nil end

    if type(field) == "string" then
        return key_pressed == field
    else
        return key_pressed == field[1] or key_pressed == field[2] or key_pressed == field[3]
    end
end

---@param self Player
local function move_default(self, dt)
    local bd = self.body
    local gamestate = self.gamestate
    local camera = gamestate.camera

    bd.max_speed_x = bd.ground and self.max_speed_ground or self.max_speed

    if pressing('left') and bd.speed_x <= 0.0 then
        bd:apply_force(-self.acc)
        self.direction = -1
        --
    elseif pressing('right') and bd.speed_x >= 0.0 then
        bd:apply_force(self.acc)
        self.direction = 1
    end

    if pressing('jump') then
        bd:apply_force(nil, -bd:weight() - self.acc * 2)
        if bd.speed_y <= -self.max_speed then
            bd.speed_y = -self.max_speed
        end
    end

    local last_px, last_py = bd.x, bd.y

    bd:refresh(
        Utils:clamp(bd.x, camera.bounds_left, camera.bounds_right - bd.w),
        Utils:clamp(bd.y, camera.bounds_top, math.huge)
    )

    if bd.x ~= last_px then
        bd.speed_x = 0.0
    end

    if bd.y ~= last_py then
        bd.speed_y = bd.world.meter * 1.5
    end
end
--==========================================================================

---@class Player : BodyComponent
local Player = setmetatable({}, GC)
Player.__index = Player

function Player:new(state, world, args)
    args = args or {}
    args.type = "dynamic"
    args.x = args.x or (16 * 5)
    args.y = args.y or (0)
    args.w = 12
    args.h = 24
    args.y = args.bottom and (args.bottom - args.h) or args.y

    args.acc = 16 * 12
    args.max_speed = 16 * 5
    args.dacc = 16 * 4

    local obj = GC:new(state, world, args)
    setmetatable(obj, self)
    Player.__constructor__(obj, state)
    return obj
end

function Player:__constructor__(state)
    self.ox = self.w * 0.5
    self.oy = self.h * 0.5

    local bd = self.body
    bd.allowed_air_dacc = true
    bd.max_speed_x = self.max_speed
    bd.mass = bd.mass * 0.25

    self.max_speed_ground = self.max_speed * 0.5

    self.direction = 1

    self:set_update_order(10)

    self.time_state = 0.0
    self:set_state(States.default)

    self.draw = Player.draw
end

function Player:set_state(state)
    if state == self.state then return false end
    local last = self.state
    self.state = state
    self.time_state = 0.0

    if state == States.default then
        self.cur_movement = move_default
    end

    return true
end

function Player:key_pressed(key)
    local bd = self.body

    -- if pressed('jump', key) then
    --     if bd.speed_y == 0.0 then
    --         bd:jump(16 * 3, -1)
    --     end
    -- end
end

function Player:key_released(key)
    local bd = self.body
    if pressed('jump', key) and bd.speed_y < 0 then
        bd.speed_y = bd.speed_y * 0.5
    end
end

function Player:update(dt)
    local bd = self.body
    GC.update(self, dt)

    self.time_state = self.time_state + dt
    self:cur_movement(dt)

    self.x, self.y = Utils:round(bd.x), Utils:round(bd.y)
end

function Player:my_draw()
    lgx.setColor(0, 0, 1)
    local bd = self.body
    lgx.rectangle("fill", bd.x, bd.y, bd.w, bd.h)
end

function Player:draw()
    GC.draw(self, self.my_draw)
end

return Player
