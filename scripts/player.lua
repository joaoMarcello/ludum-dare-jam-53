-- local GC = require "jm-love2d-package.modules.gamestate.body_object"
local GC = _G.JM_Package.BodyObject
local Utils = _G.JM_Utils
local Spell = require "scripts.spell"
local PS = _G.JM_Package.ParticleSystem

local keys = {
    left = { 'left', 'a' },
    right = { 'right', 'd' },
    down = { 'down', 's' },
    jump = { 'space', 'up', 'w' },
    atk = { 'j', 'f', 'e' },
    drop = { 'v', 'k', 'q' },
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
    dummy = 8,
}

local imgs

--==========================================================================
local keyboard_is_down = love.keyboard.isDown
local math_abs, type = math.abs, type
local lgx = love.graphics

local reuse_tab = {}
local pairs = pairs
local function empty_table()
    for index, _ in pairs(reuse_tab) do
        reuse_tab[index] = nil
    end
    return reuse_tab
end

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
        --
    elseif bd.speed_x ~= 0 then
        if bd.speed_x > 0 and pressing('left')
            or bd.speed_x < 0 and pressing('right')
        then
            bd.speed_x = 0.0
        end
        --
    end

    if pressing('jump') then
        bd:apply_force(nil, -bd:weight() - self.acc * 2)
        if bd.speed_y <= -self.max_speed then
            bd.speed_y = -self.max_speed
        end
    end

    if pressing('down') then
        bd:apply_force(nil, bd:weight() * 3)
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
        bd.speed_y = bd.world.meter * 2.5 --1.5
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

---@param self Player
local function move_atk(self, dt)
    move_default(self, dt)

    if self.time_state >= 0.3 then
        self:set_state(States.default)
    end
end


---@param self JM.Emitter
local function smoke_emitter_update(self, dt, args)
    self.time = self.time + dt
    ---@type Player
    local player = args

    if self.time >= 0.15 and not player:is_dead() and player.body.speed_y < 0 then
        self.time = 0.0

        -- self:add_particle(PS.Particle:newAnimated(
        --     self:pop_anima('smoke'),
        --     -- self.Animas['smoke']:copy(),
        --     self.x,
        --     self.y,
        --     7, 7,
        --     1, nil, nil, nil, nil, nil, nil, nil, nil, self.draw_order,
        --     "smoke"
        -- ))

        self:add_particle(PS:newAnimatedParticle("smoke", self.x, self.y))
    end
end
--==========================================================================

---@class Player : BodyObject
local Player = setmetatable({}, GC)
Player.__index = Player

function Player:new(x, y, bottom)
    -- args = args or {}
    -- args.type = "dynamic"
    -- args.x = args.x or (16 * 5)
    -- args.y = args.y or (0)
    -- args.w = args.w or 12
    -- args.h = args.h or 24
    -- args.y = args.bottom and (args.bottom - args.h) or args.y
    -- args.draw_order = 1

    x = x or (16 * 5)
    y = y or 0
    if bottom then
        y = bottom - 24
    end
    -- args.acc = 16 * 12
    -- args.max_speed = 16 * 6
    -- args.dacc = 16 * 25 -- 25

    local obj = GC:new(x, y, 12, 24, 1, 0, "dynamic")
    setmetatable(obj, self)
    Player.__constructor__(obj)
    return obj
end

function Player:__constructor__()
    self.ox = self.w * 0.5
    self.oy = self.h * 0.5

    self.acc = 16 * 12
    self.max_speed = 16 * 6
    self.dacc = 16 * 25

    local bd = self.body
    bd.allowed_air_dacc = true
    bd.max_speed_x = self.max_speed
    bd.dacc_x = self.dacc
    bd.mass = bd.mass * 0.25

    self.max_speed_ground = self.max_speed * 0.4
    self.max_speed_y = self.max_speed

    self.direction = 1

    --=======   STATS ============
    self.max_hp = 5
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
    self.time_reload_spell = 0.7
    self.time_reload_spell_slow = self.time_reload_spell * 3

    self.bag_count = 0
    self.bag_capacity = 5

    self:set_update_order(-10)

    self.time_state = 0.0


    self.time_smoke = 0.0

    self.items = {}

    local Anima = _G.JM_Anima
    self.anim = {
        [States.default] = Anima:new { img = imgs[States.default], frames = 2, duration = 0.3 },
        [States.dead] = Anima:new { img = imgs[States.dead] },
        [States.atk] = Anima:new { img = imgs[States.atk], frames = 2, duration = 0.15 },
    }

    self.cur_anima = self.anim[States.default]

    self.skull = Anima:new { img = imgs.skull }
    self.skull:apply_effect("float", { speed = 0.6, range = 1.5 })

    self:apply_effect("float", { range = 1, speed = 0.6 })

    self:set_state(States.default)

    self.smoke_emitter = PS:newEmitter(self.x, self.y, 16, 16, self.draw_order - 1, math.huge, smoke_emitter_update,
        self)


    ---@type GameState.Game | any
    local gamestate = self.gamestate
    gamestate:game_add_component(self.smoke_emitter)

    self.update = Player.update
    self.draw = Player.draw
end

function Player:load()
    Spell:load()
    -- Smoke:load()

    local newImage = lgx.newImage
    imgs = imgs or {
        [States.default] = newImage("data/img/brunette-fly-Sheet.png"),
        [States.dead] = newImage("data/img/brunnette-die.png"),
        [States.atk] = newImage("data/img/brunnette-spell-Sheet.png"),
        skull = newImage("data/img/skull.png"),
    }
end

function Player:finish()
    Spell:finish()
    -- Smoke:finish()
    imgs = nil
end

function Player:hp_up(value)
    value = value or 1
    self.hp = Utils:clamp(self.hp + 1, 0, self.max_hp)
    self:pulse()
end

local eff_tab = { duration = 0.3, speed = 0.3, range = 0.25 }
function Player:pulse()
    self:apply_effect("stretchVertical", eff_tab, true)
end

function Player:reload_spell_speed()
    local rel_time = self.count_spell <= 0
        and self.time_reload_spell_slow
        or self.time_reload_spell

    return rel_time
end

function Player:reload_spell(dt)
    if self.count_spell < self.max_spell then
        self.time_spell = self.time_spell + dt

        local rel_time = self.count_spell <= 0
            and self.time_reload_spell_slow
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

    self.cur_anima = self.anim[States.default]

    if state == States.default then
        self.cur_movement = move_default
        --
    elseif state == States.atk then
        self.cur_movement = move_atk
        self.cur_anima = self.anim[state]
        --
    elseif state == States.dead then
        self.cur_movement = move_dead
        bd.speed_y = 0
        bd:jump(16 * 1.5, -1)
        bd.bouncing_y = 0.25
        -- bd.mass = bd.world.default_mass * 0.4
        local eff = self.eff_actives and self.eff_actives["float"]
        if eff then
            eff.__remove = true
            self.eff_actives['float'] = nil
        end

        self.cur_anima = self.anim[state]
        --
    end

    self.cur_anima:reset()
    return true
end

function Player:lauch_spell()
    if self.count_spell <= 0 then
        _G.PLAY_SFX("spell_fail", false)
        return false
    end

    self.count_spell = self.count_spell - 1

    ---@type GameState.Game | any
    local gamestate = self.gamestate
    local bd = self.body

    -- local px = self.direction > 0 and (bd.x + 5) or (bd.x - 5 - 8)

    local x, y

    if self.direction > 0 then
        x = bd.x + bd.w * 0.5 + 22
    else
        x = bd.x + bd.w * 0.5 - 28
    end
    y = bd.y + 6

    gamestate:game_add_component(Spell:new(x, y, self.direction))

    self.time_spell = 0.0

    self.state = States.dummy
    self:set_state(States.atk)

    _G.PLAY_SFX("spell", true)

    return true
end

function Player:drop_item()
    ---@type Item | nil
    local item = table.remove(self.items, 1)

    if item then
        item:drop()
        self.bag_count = self.bag_count - 1
    else
        _G.PLAY_SFX("spell_fail", false)
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

    if key == 'z' then
        PS.Emitter:flush()
    end

    if key == 'm' then
        collectgarbage()
    end
end

function Player:mouse_pressed(x, y, button, istouch, presses)
    if self.state ~= States.dead then
        if button == 2 then
            self:key_pressed(keys.atk[1])
        elseif button == 1 then
            self:key_pressed(keys.drop[2])
        end
    end
end

function Player:key_released(key)
    local bd = self.body
    if pressed('jump', key) and bd.speed_y < 0 then
        bd.speed_y = bd.speed_y * 0.5

        -- local S = _G.JM_Love2D_Package.Sound
        -- local audio = S:get_sfx("fly")
        -- if audio then
        --     if audio.source:isPlaying() then audio.source:stop() end
        -- end
    end
end

function Player:update(dt)
    local bd = self.body
    GC.update(self, dt)

    ---@type GameState.Game | any
    local gamestate = self.gamestate

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

    self.cur_anima:update(dt)
    self.cur_anima:set_flip_x(self.direction < 0 and true or false)

    if not self:is_dead() then
        -- self.time_smoke = self.time_smoke + dt
        -- if self.time_smoke >= 0.15 and bd.speed_y < 0 then
        --     self.time_smoke = 0.0

        --     gamestate:game_add_component(Smoke:new(
        --         self.x - 16 * self.direction,
        --         self.y + 16
        --     ))
        -- end

        self.smoke_emitter.x = self.x - 16 * self.direction
        self.smoke_emitter.y = self.y + 16

        if bd.speed_y < 16 then
            _G.PLAY_SFX("fly", false)
        end
        --
    else
        --
        -- if bd.ground then
        self.skull:update(dt)
        -- end
    end

    if bd.speed_y >= 0 or self:is_dead() then
        local S = _G.JM_Love2D_Package.Sound
        local audio = S:get_sfx("fly")
        if audio then
            if audio.source:isPlaying() or true then audio.source:stop() end
        end
    end
    self.x, self.y = Utils:round(bd.x), Utils:round(bd.y)
end

function Player:my_draw()
    -- local bd = self.body
    -- lgx.setColor(0, 0, 1)
    -- lgx.rectangle("fill", bd.x, bd.y, bd.w, bd.h)
    -- lgx.setColor(0, 0, 0)
    -- lgx.rectangle("line", bd.x, bd.y, bd.w, bd.h)

    self.cur_anima:draw(self.x + self.w * 0.5, self.y + self.h * 0.5)
end

function Player:draw()
    GC.draw(self, self.my_draw)

    if self:is_dead() then
        self.skull:draw(self.x + self.w * 0.5 - 16 * self.direction, self.y - 4)
    end

    -- local font = JM_Font.current
    -- local N = 0

    -- for _, __ in pairs(self.body.BodyRecycler) do
    --     N = N + 1
    -- end
    -- font:print(tostring(N), self.x, self.y - 10)
end

return Player
