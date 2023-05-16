-- local GC = require "lib.component"
local GC = require "jm-love2d-package.modules.gamestate.game_object"
local lgx = love.graphics
local Phys = _G.JM_Love2D_Package.Physics
local Utils = _G.JM_Utils
local PS = require "jm-love2d-package.modules.jm_ps"
local imgs

---@param self JM.Particle
---@param dt any
local part_update = function(self, dt)
    local bd = self.body
    if bd.speed_y >= 0 then
        self.sx = self.sx - 1.0 / 2 * dt
        if self.sx < 0.0 then
            self.sx = 0.0
        end
        self.sy = self.sx

        -- local w = self.body.w * self.sx
        -- local h = self.body.h * self.sx
        -- if w <= 0 then w = 1 end
        -- if h <= 0 then h = 1 end
        -- bd:refresh(nil, bd.y + bd.h - h, w, h)
    end
end

---@param self JM.Emitter
---@param dt any
---@param args Cauldron
local bubble_action = function(self, dt, args)
    self.time = self.time + dt

    args.time = args.time + dt

    if self.time >= 0.15 then
        self.time = 0.0

        local p = self:add_particle(PS.Particle:newBodyAnimated(
            PS.Emitter:pop_anima("bubble"),
            math.random(self.x, self.x + self.w), self.y, 6, 6, 2, nil,
            "bubble"
        ))

        p.__custom_update__ = part_update
        local dir = p.body.x <= self.x + self.w * 0.5 and -1 or 1
        local bd = p.body
        bd.speed_x = (16 * 4 * math.random()) * dir
        bd.dacc_x = 16 * 6
        bd.bouncing_y = 0.3
        bd.allowed_air_dacc = false
        bd.mass = bd.mass * 0.75

        bd:jump(16 + 24 * math.random(), -1)
    end
end


---@class Cauldron : GameObject
local Cauldron = setmetatable({}, GC)
Cauldron.__index = Cauldron

function Cauldron:new(x, y, bottom)
    -- args = args or {}
    -- args.type = "dynamic"
    -- args.y = args.y or 64
    -- args.x = args.x or 96
    -- args.w = 48
    -- args.h = 24
    -- args.y = args.bottom and (args.bottom - args.h) or args.y
    -- args.draw_order = 0

    x = x or 96
    y = y or 64
    if bottom then
        y = bottom - 24
    end

    local obj = GC:new(x, y, 48, 24, 0, 0)
    setmetatable(obj, self)
    Cauldron.__constructor__(obj)
    return obj
end

function Cauldron:__constructor__()
    -- self.world = world
    local world = self.world

    Phys:newBody(world, self.x - 3, self.y, 3, 3, "static")
    Phys:newBody(world, self.x + self.w, self.y, 3, 3, "static")
    Phys:newBody(world, self.x, self.y, 1, self.h, "static")
    Phys:newBody(world, self.x + self.w - 1, self.y, 1, self.h, "static")

    local Anima = _G.JM_Anima
    local color = _G.JM_Utils:get_rgba2(255, 252, 64)

    self.anim_down = Anima:new { img = imgs.down }
    self.anim_down:apply_effect("flickering", { speed = 0.15 })
    self.anim_down:set_color(color)


    self.anim1 = Anima:new { img = imgs.cauldron }

    self.anim2 = Anima:new { img = imgs.down }
    self.anim2:apply_effect("float", { range = 1.4, speed = 0.6 })
    self.anim2:set_color(color)

    self.ox = self.w * 0.5
    self.oy = self.h

    self.emitter = PS.Emitter:new(self.x, self.y - 8, self.w, 8, self.draw_order - 1, math.huge, bubble_action, self)

    ---@type GameState.Game | any
    local gamestate = self.gamestate

    gamestate:game_add_component(self.emitter)

    self.time = 0.0
end

function Cauldron:load()
    imgs = imgs or {
        down = lgx.newImage("data/img/down.png"),
        down_left = lgx.newImage("data/img/down-left.png"),
        cauldron = lgx.newImage("data/img/cauldron.png"),
    }
end

function Cauldron:finish()
    imgs = nil
end

local shake_tab = { duration = 0.2, speed = 0.2, range = 0.15 }
function Cauldron:shake()
    -- local sp = 0.2
    self:apply_effect("jelly", shake_tab, true)
end

---@param bd JM.Physics.Body
function Cauldron:is_inside(bd)
    return bd:check_collision(self.x, self.y + 4, self.w, self.h)
end

function Cauldron:update(dt)
    -- GC.update(self, dt)
    self.__effect_manager:update(dt)

    self.anim_down:update(dt)
    self.anim1:update(dt)
    self.anim2:update(dt)

    ---@type GameState.Game | any
    local gamestate = self.gamestate
    local player = gamestate:game_player()

    if not player:is_dead() then
        local bd = player.body
        if self:is_inside(bd) then
            player:damage(self)
            bd:jump(16 * 3, -1)
        end
    end
end

function Cauldron:my_draw()
    -- lgx.setColor(0, 0, 0)
    -- lgx.rectangle("line", self.x, self.y, self.w, self.h)

    self.anim1:draw_rec(self.x, self.y, self.w, self.h)
end

function Cauldron:draw(cam)
    GC.draw(self, self.my_draw)

    if cam and cam == self.gamestate:get_camera("cam2") then return end

    local camera = self.gamestate.camera
    local font = _G.JM_Font.current
    ---@type GameState.Game | any
    local gamestate = self.gamestate
    local player_bd = gamestate:game_player().body


    if not camera:rect_is_on_view(self.x - 1, self.y, self.w + 2, self.h) then
        --
        local vx, vy, vw, vh = camera:get_viewport_in_world_coord()
        local rot = self.anim_down.rotation
        local half_pi = math.pi * 0.5

        if self.x > vx + vw then
            self.anim_down:set_rotation(-half_pi)
            --
        elseif self.x < vx then
            self.anim_down:set_rotation(half_pi)
            --
        end

        local dist --= math.abs(self.x + self.w * 0.5 - player_bd.x + player_bd.w * 0.5)

        local fx, fy
        if self.x < vx then
            fx = vx + 8
            fy = self.y - 16
            dist = math.abs(self.x + self.w - vx)
            --
        elseif self.x > vx + vw then
            fx = vx + vw - 8
            fy = self.y - 16
            dist = math.abs(self.x - (vx + vw))
            --
        elseif self.y > vy + vh then
            fx = self.x + self.w * 0.5 - 16
            fy = self.y - 16
            dist = math.abs(self.y - (vy + vh))
        end

        if fx and fy and dist then
            font:printf(string.format("<color, 0.9, 0.9, 0.9>%.1f M", dist / self.world.meter),
                Utils:clamp(fx, vx, vx + vw - self.w),
                Utils:clamp(fy, vy, vy + vh - self.h - 10), "center", 38
            )
        end

        self.anim_down:draw_rec(
            Utils:clamp(self.x, vx, vx + vw - self.w),
            Utils:clamp(self.y - 10, vy, vy + vh - self.h - 10),
            self.w,
            self.h
        )

        self.anim_down:set_rotation(rot)
        --
    else
        if not player_bd:check_collision(self.x - 16, self.y - 32, self.w + 32, self.h + 64) then
            self.anim2:draw_rec(self.x, self.y - 35, self.w, self.h)
        end
        --
    end
end

return Cauldron
