local GC = require "lib.component"
local lgx = love.graphics
local Phys = _G.JM_Love2D_Package.Physics
local Utils = _G.JM_Utils

local imgs

---@class Cauldron : GameComponent
local Cauldron = setmetatable({}, GC)
Cauldron.__index = Cauldron

---@param world JM.Physics.World
function Cauldron:new(state, world, args)
    args = args or {}
    args.type = "dynamic"
    args.y = args.y or 64
    args.x = args.x or 96
    args.w = 48
    args.h = 24
    args.y = args.bottom and (args.bottom - args.h) or args.y
    args.draw_order = 0

    local obj = GC:new(state, args)
    setmetatable(obj, self)
    Cauldron.__constructor__(obj, world, args)
    return obj
end

---@param world JM.Physics.World
function Cauldron:__constructor__(world, args)
    self.world = world

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

---@param bd JM.Physics.Body
function Cauldron:is_inside(bd)
    return bd:check_collision(self.x, self.y + 4, self.w, self.h)
end

function Cauldron:update(dt)
    GC.update(self, dt)

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

function Cauldron:draw()
    GC.draw(self, self.my_draw)

    local camera = self.gamestate.camera
    local font = _G.JM_Font.current

    if not self.gamestate:rect_is_on_view(self.x, self.y, self.w, self.h) then
        local vx, vy, vw, vh = camera:get_viewport_in_world_coord()
        local rot = self.anim_down.rotation

        if self.x > vx + vw then
            self.anim_down:set_rotation(-math.pi / 2)
            --
        elseif self.x < vx then
            self.anim_down:set_rotation(math.pi / 2)
            --
        end

        local player_bd = self.gamestate:game_player().body
        local dist = math.abs(self.x + self.w * 0.5 - player_bd.x + player_bd.w * 0.5)

        font:printf(string.format("<color, 0.9, 0.9, 0.9>%.1f M", dist / self.world.meter * 1),
            Utils:clamp(self.x, vx, vx + vw - self.w),
            Utils:clamp(self.y - 15, vy, vy + vh - self.h - 10), "center", 32
        )

        self.anim_down:draw_rec(
            Utils:clamp(self.x, vx, vx + vw - self.w),
            Utils:clamp(self.y - 10, vy, vy + vh - self.h - 10),
            self.w,
            self.h
        )

        self.anim_down:set_rotation(rot)
        --
    else
        local player_bd = self.gamestate:game_player().body

        if not player_bd:check_collision(self.x - 16, self.y - 32, self.w + 32, self.h + 64) then
            self.anim2:draw_rec(self.x, self.y - 35, self.w, self.h)
        end
        --
    end
end

return Cauldron
