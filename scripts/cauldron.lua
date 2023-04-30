local GC = require "lib.component"
local lgx = love.graphics
local Phys = _G.JM_Love2D_Package.Physics

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
end

function Cauldron:load()

end

function Cauldron:finish()

end

---@param bd JM.Physics.Body
function Cauldron:is_inside(bd)
    return bd:check_collision(self.x, self.y + 4, self.w, self.h)
end

function Cauldron:update(dt)
    GC.update(self, dt)

    ---@type GameState.Game | any
    local gamestate = self.gamestate
    local player = gamestate:game_player()

    if not player:is_dead() then
        local bd = player.body
        if self:is_inside(bd) then
            -- bd:apply_force(nil, -bd:weight() - bd.acc_y - 16 * 6)
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
end

return Cauldron
