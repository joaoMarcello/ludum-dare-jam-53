-- local GC = require "lib.bodyComponent"
local GC = require "jm-love2d-package.modules.gamestate.body_object"
local Bullet = require "scripts.bullet"
local Utils = _G.JM_Utils
local Item = require "scripts.item"
local Smoke = require "scripts.smoke"

local lgx = love.graphics
local atan2, sqrt, cos, sin = math.atan2, math.sqrt, math.cos, math.sin
local random = love.math.random

local reuse_tab = {}
local pairs = pairs
local function empty_table()
    for index, _ in pairs(reuse_tab) do
        reuse_tab[index] = nil
    end
    return reuse_tab
end

---@enum Bat.States
local States = {
    idle = 0,
    chase = 1,
    dead = 2,
    atk = 3,
    leave = 4,
}

---@enum Bat.Modes
local Modes = {
    normal = 1,
    medium = 2,
    hard = 3
}

local imgs

local max_speed = 16 * 5
local speed = 16 * 2.5
local acc = 16 * 4
local dacc = 16 * 8
local speed_shoot = 1

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

    if bd.ground then bd:jump(4) end

    if self.time_state >= self.dur_chase then
        self.dur_chase = 4 + 3 * math.random()
        self:set_state(States.idle)
    end

    self:shoot(dt)

    if bd.speed_x ~= 0 then
        self.direction = bd.speed_x > 0 and 1 or -1
    end
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

    local player = gamestate:game_player()
    local player_bd = player.body

    if player_bd.x + player_bd.w * 0.5 < bd.x + bd.w * 0.5 then
        self.direction = 1
    else
        self.direction = -1
    end
end

---@param self Bat
local leave = function(self, dt)
    local bd = self.body

    ---@type GameState.Game | any
    local gamestate = self.gamestate

    local player = gamestate:game_player()
    local player_bd = player.body

    if player_bd.x + player_bd.w * 0.5 < bd.x + bd.w * 0.5 then
        self.direction = -1
    else
        self.direction = 1
    end

    bd:apply_force(16 * 3 * self.direction, -bd:weight() - 16 * 3)

    self:shoot(dt)

    if not gamestate.camera:rect_is_on_view(bd:rect()) then
        self.__remove = true
    end
end

---@param self Bat
local dead = function(self, dt)
    local bd = self.body

    if self.time_state >= 5
    then
        self.__remove = true
    end
end

---@class Bat : BodyObject
local Bat = setmetatable({}, GC)
Bat.__index = Bat
Bat.States = States
Bat.Modes = Modes

function Bat:new(x, y, bottom, mode)
    -- args = args or empty_table()
    -- args.type = "dynamic"
    -- args.x = args.x or (16 * 5)
    -- args.y = args.y or (16 * 2)
    -- args.w = 12
    -- args.h = 12
    -- args.y = args.bottom and (args.bottom - args.h) or args.y
    -- args.draw_order = -1
    x = x or (16 * 5)
    y = y or (16 * 2)
    if bottom then
        y = bottom - 12
    end

    local obj = GC:new(x, y, 12, 12, -1, 0, "dynamic")
    setmetatable(obj, self)
    Bat.__constructor__(obj, mode)
    return obj
end

function Bat:__constructor__(mode)
    local bd = self.body

    bd.allowed_gravity = false
    bd.allowed_air_dacc = true

    self.mode = mode or Modes.normal

    bd.max_speed_x = max_speed
    bd.max_speed_y = max_speed
    bd.acc_x = acc
    bd.acc_y = acc
    bd.dacc_x = dacc
    bd.dacc_y = dacc
    bd.id = "bat"

    self.hp = 2
    self.max_hp = 4

    local Anima = _G.JM_Anima
    self.anim = {
        [States.idle] = Anima:new { img = imgs[States.idle], frames = 2, duration = 0.3 },
        -- [States.dead] = Anima:new { img = imgs[States.dead], frames = 1 },
    }
    self.anim[States.chase] = self.anim[States.idle]
    self.anim[States.leave] = self.anim[States.idle]
    self.anim[States.atk] = self.anim[States.idle]
    self.anim[States.dead] = self.anim[States.idle]

    self.state = nil
    self:set_state(States.chase)


    self.time_shoot = -5.0 * math.random()
    self.time_state = 0.0
    self.time_leave = 0.0
    self.dur_idle = 3 * math.random()
    self.dur_chase = 4 + 3 * math.random()

    self.cur_anima = self.anim[States.idle]

    self.time_smoke = 0.0

    self.direction = 1
end

function Bat:load()
    Bullet:load()
    Item:load()
    Smoke:load()

    local newImage = lgx.newImage
    imgs = imgs or {
        [States.idle] = newImage("/data/img/bat-fly-Sheet.png"),
        -- [States.dead] = newImage("data/img/bat-fly.png"),
    }
end

function Bat:finish()
    Bullet:finish()
    Item:finish()
    Smoke:finish()
    imgs = nil
end

function Bat:is_dead()
    return self.state == States.dead or self.hp <= 0
end

local eff_args = { duration = 1, speed = 1 / 12 }
function Bat:damage(value)
    if self:is_dead() then return false end

    value = value or 1

    self.hp = Utils:clamp(self.hp - value, 0, self.max_hp)

    if self.hp == 0 then
        self:set_state(States.dead)
        _G.PLAY_SFX("enemy_die", true)
    else
        _G.PLAY_SFX("enemy_hit", true)
        -- self:apply_effect("flash", { duration = 1, speed = 1 / 6, color = { 1, 1, 1, 1 }, max = 1.2 })
        self:apply_effect("flickering", eff_args)
    end

    return true
end

function Bat:drop_wing()
    if love.math.random() <= 0.4 then return false end
    local bd = self.body

    local tab = empty_table()
    tab.x = bd.x
    tab.bottom = bd:bottom()
    tab.allowed_gravity = true
    tab.allowed_air_dacc = true
    tab.item_type = Item.Types.wing
    tab.speed_x = bd.speed_x
    tab.auto_remove = true

    local wing = Item:new(tab)
    -- local wing = Item:new(self.gamestate, self.body.world, {
    --     x = bd.x,
    --     bottom = bd:bottom(),
    --     allowed_gravity = true,
    --     allowed_air_dacc = true,
    --     item_type = Item.Types.wing,
    --     speed_x = bd.speed_x,
    --     auto_remove = true,
    -- })
    ---@type GameState.Game | any
    local gamestate = self.gamestate
    gamestate:game_add_component(wing)
    return true
end

function Bat:set_state(state)
    if state == self.state then return false end
    local bd = self.body
    local last = self.state
    self.state = state

    ---@type GameState.Game | any
    local gamestate = self.gamestate

    if state == States.chase then
        self.cur_movement = chase
        --
    elseif state == States.idle then
        self.cur_movement = idle
        --
    elseif state == States.leave then
        self.cur_movement = leave
        bd.allowed_gravity = true
        bd.mass = bd.world.default_mass
        bd.max_speed_y = nil
        --
    elseif state == States.dead then
        self:drop_wing()

        self.cur_movement = dead
        bd.allowed_air_dacc = false
        bd.allowed_gravity = true
        bd.speed_y = 0.0
        bd.speed_x = bd.speed_x < 0 and (-32) or 32
        bd.mass = bd.world.default_mass * 0.5
        bd.type = bd.Types.ghost
        bd.max_speed_y = nil
        bd:jump(16 * 1.5, -1)
        self:set_draw_order(16)

        local pt = self:get_score()
        gamestate:game_add_score(pt)
        gamestate:display_text(tostring(pt), self.x, self.y - 20)

        --
    end

    self.time_state = 0.0
    self.cur_anima = self.anim[self.state]

    return true
end

function Bat:get_score()
    if self.mode == Modes.normal then
        return 20
    elseif self.mode == Modes.medium then
        return 50
    else
        return 80
    end
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

        -- local tab = empty_table()
        -- tab.x = bd.x
        -- tab.y = bd.y

        gamestate:game_add_component(Bullet:new(bd.x, bd.y))

        if gamestate.camera:rect_is_on_view(bd:rect()) then
            _G.PLAY_SFX("bullet", true)
        end
    end
end

function Bat:update(dt)
    GC.update(self, dt)

    self.cur_anima:update(dt)

    self.time_state = self.time_state + dt
    self:cur_movement(dt)

    local bd = self.body

    ---@type GameState.Game | any
    local gamestate = self.gamestate

    if not self:is_dead() then
        if gamestate.camera:rect_is_on_view(self.x, self.y, self.w, self.h)
        then
            self.time_leave = self.time_leave + dt
        end

        local player = gamestate:game_player()
        local player_bd = player.body
        if player_bd:check_collision(bd:rect()) then
            player:damage(self)
        end

        if self.time_leave >= 20 then
            self:set_state(States.leave)
        end

        self.cur_anima:set_flip_x(player_bd.x > bd.x and true or false)

        self.time_smoke = self.time_smoke + dt

        if self.time_smoke >= 0.2 and bd.speed_y ~= 0 and self.state ~= States.idle then
            self.time_smoke = 0.0
            local sk = Smoke:new(
                self.x + self.w * 0.5 - 1 * self.direction,
                self.y + self.h * 0.5 - 1 * bd:direction_y(),
                0.3
            )
            gamestate:game_add_component(sk)
        end
        --
    else
        self.cur_anima.current_frame = 1
        self.cur_anima:set_rotation(math.pi)
        --
    end

    self.x, self.y = Utils:round(bd.x), Utils:round(bd.y)
end

function Bat:my_draw()
    -- lgx.setColor(1, 0, 0)
    -- lgx.rectangle("fill", self.body:rect())
    self.cur_anima:draw(self.x + self.w * 0.5, self.y + self.h * 0.5)
end

function Bat:draw()
    GC.draw(self, self.my_draw)
    -- local font = JM_Font.current
    -- font:print(tostring(self.hp), self.x, self.y - 10)
end

return Bat
