local GC = require "lib.bodyComponent"
local Utils = _G.JM_Utils
local Spell = require "scripts.spell"

local keys = {
    left = { 'left', 'a' },
    right = { 'right', 'd' },
    down = { 'down', 's' },
    jump = { 'space', 'up', 'w' },
    atk = { 'j', 'f' },
    drop = { 'd', 'k' },
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

    if bd.speed_y > 0 and bd.speed_y > self.max_speed then
        bd.speed_y = self.max_speed
    end
end

---@param self Player
local function move_dead(self, dt)
    local bd = self.body
    bd.speed_x = 0
    bd.acc_x = 0
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
    args.w = args.w or 12
    args.h = args.h or 24
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

    self.max_speed_ground = self.max_speed * 0.4

    self.direction = 1

    --=======   STATS ============
    self.max_hp = 3
    self.hp = self.max_hp
    self.atk = 1
    self.max_atk = 3
    self.def = 1
    self.max_def = 3
    --=============================

    self.time_invicible = 0.0
    self.invicible_duration = 1

    self.max_spell = 3
    self.count_spell = self.max_spell
    self.time_spell = 0.0
    self.time_reload_spell = 1.0

    self.bag_count = 0
    self.bag_capacity = 1

    self:set_update_order(10)

    self.time_state = 0.0
    self:set_state(States.default)

    self.items = {}

    self.update = Player.update
    self.draw = Player.draw
end

function Player:load()
    Spell:load()
end

function Player:finish()
    Spell:finish()
end

function Player:reload_spell(dt)
    if self.count_spell < self.max_spell then
        self.time_spell = self.time_spell + dt

        local rel_time = self.count_spell <= 0
            and (self.time_reload_spell * 3.5)
            or self.time_reload_spell

        if self.time_spell >= rel_time then
            self.time_spell = self.time_spell - rel_time
            self.count_spell = self.count_spell + 1
        end
    else
        self.time_spell = 0.0
    end
end

function Player:bag_is_full()
    return self.bag_count >= self.bag_capacity
end

---@param item Item
function Player:insert_item(item)
    if self.bag_count >= self.bag_capacity or self:is_dead() then
        return false
    end
    table.insert(self.items, item)
    self.bag_count = self.bag_count + 1
    return true
end

function Player:is_dead()
    return self.state == States.dead or self.hp <= 0
end

function Player:is_invencible()
    return self.time_invicible ~= 0
end

function Player:increase_hp()
    local last = self.hp
    self.hp = Utils:clamp(self.hp + 1, 0, self.max_hp)
    return self.hp ~= last
end

function Player:damage(obj)
    if self:is_dead() or self.time_invicible ~= 0.0 then return false end

    self.hp = Utils:clamp(self.hp - 1, 0, self.max_hp)
    self.time_invicible = self.invicible_duration

    if self.hp == 0 then
        self:set_state(States.dead)
        _G.PLAY_SFX("death")
    else
        _G.PLAY_SFX("scream")
    end

    self.hit_obj = obj
    self.gamestate:pause(self:is_dead() and 1.3 or 0.2, function(dt)
        self.gamestate.camera:update(dt)
    end)
    return true
end

function Player:set_state(state)
    if state == self.state then return false end
    local last = self.state
    local bd = self.body
    self.state = state
    self.time_state = 0.0

    if state == States.default then
        self.cur_movement = move_default
        --
    elseif state == States.dead then
        self.cur_movement = move_dead
        bd.speed_y = 0
        bd:jump(16 * 1.5, -1)
        bd.bouncing_y = 0.25
        -- bd.mass = bd.world.default_mass * 0.4
        --
    end

    return true
end

function Player:lauch_spell()
    if self.count_spell <= 0 then return false end

    self.count_spell = self.count_spell - 1

    local gamestate = self.gamestate
    local bd = self.body

    local px = self.direction > 0 and (bd.x + 5) or (bd.x - 5 - 8)
    gamestate:game_add_component(Spell:new(gamestate, self.world, {
        x = px,
        y = bd.y,
        direction = self.direction,
    }))

    self.time_spell = 0.0

    return true
end

function Player:drop_item()
    ---@type Item | nil
    local item = table.remove(self.items, self.bag_count)

    if item then
        item:drop()
        self.bag_count = self.bag_count - 1
    end
end

function Player:key_pressed(key)
    if self.state ~= States.dead then
        if pressed('atk', key) then
            self:lauch_spell()
            --
        elseif pressed('drop', key) then
            self:drop_item()
            --
        end
    end
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

    self:reload_spell(dt)

    self.time_state = self.time_state + dt
    self:cur_movement(dt)

    if self.time_invicible ~= 0 then
        self.time_invicible = Utils:clamp(self.time_invicible - dt, 0, self.invicible_duration)
    end

    if self.time_invicible ~= 0 and not self:is_dead() then
        self:apply_effect('flickering', { speed = 0.06 })
    else
        local eff = self.eff_actives and self.eff_actives['flickering']
        if eff then
            eff.__remove = true
            self.eff_actives['flickering'] = nil
            self:set_visible(true)
        end
    end

    self.x, self.y = Utils:round(bd.x), Utils:round(bd.y)
end

function Player:my_draw()
    lgx.setColor(0, 0, 1)
    local bd = self.body
    lgx.rectangle("fill", bd.x, bd.y, bd.w, bd.h)
    lgx.setColor(0, 0, 0)
    lgx.rectangle("line", bd.x, bd.y, bd.w, bd.h)
end

function Player:draw()
    GC.draw(self, self.my_draw)

    local font = JM_Font.current
    local t = self.count_spell
    font:print(tostring(t), self.x, self.y - 10)
end

return Player
