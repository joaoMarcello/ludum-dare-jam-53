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

    Phys:newBody(world, self.x, self.y, 1, self.h, "static")
    Phys:newBody(world, self.x + self.w - 1, self.y, 1, self.h, "static")
    Phys:newBody(world, self.x - 3, self.y, 3, 3, "static")
    Phys:newBody(world, self.x + self.w, self.y, 3, 3, "static")

    local Anima = _G.JM_Anima
    self.anim_down = Anima:new { img = imgs.down }
    self.anim_down:apply_effect("flickering", { range = 4, speed = 0.15 })
end

function Cauldron:load()
    imgs = imgs or {
        down = lgx.newImage("data/img/down.png"),
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
    lgx.setColor(0, 0, 0)
    lgx.rectangle("line", self.x, self.y, self.w, self.h)
end

function Cauldron:draw()
    GC.draw(self, self.my_draw)

    local camera = self.gamestate.camera
    if not camera:rect_is_on_view(self.x, self.y, self.w, self.h) then
        local vx, vy, vw, vh = camera:get_viewport_in_world_coord()
        local rot = self.anim_down.rotation

        if self.x > vx + vw then
            self.anim_down:set_rotation(-math.pi / 2)
        elseif self.x < vx then
            self.anim_down:set_rotation(math.pi / 2)
        end

        self.anim_down:draw_rec(
            Utils:clamp(self.x, vx, vx + vw - self.w),
            Utils:clamp(self.y - 10, vy, vy + vh - self.h - 10),
            self.w,
            self.h
        )

        -- if not camera:rect_is_on_view(self.x, vy - 10, self.w, vh) then
        --     if vx > self.x then
        --         self.anim_down:set_rotation(math.pi / 2)
        --         self.anim_down:draw_rec(vx,
        --             Utils:clamp(self.y, self.y, vy + vh - self.h - 10),
        --             32, self.h
        --         )
        --     end

        --     if vx < self.x then
        --         self.anim_down:set_rotation(-math.pi / 2)
        --         self.anim_down:draw_rec(vx + vw - 32,
        --             Utils:clamp(self.y, self.y, vy + vh - self.h - 10),
        --             32, self.h
        --         )
        --     end
        -- end

        self.anim_down:set_rotation(rot)
    end
end

return Cauldron
