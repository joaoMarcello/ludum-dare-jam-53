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
    args.h = 28
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

    Phys:newBody(world, self.x, self.y, 4, self.h, "static")
    Phys:newBody(world, self.x + self.w - 4, self.y, 4, self.h, "static")
    Phys:newBody(world, self.x - 3, self.y, 3, 3, "static")
    Phys:newBody(world, self.x + self.w, self.y, 3, 3, "static")
end

function Cauldron:load()

end

function Cauldron:finish()

end

function Cauldron:update(dt)
    GC.update(self, dt)
end

function Cauldron:my_draw()
    lgx.setColor(0, 0, 0)
    lgx.rectangle("line", self.x, self.y, self.w, self.h)
end

function Cauldron:draw()
    GC.draw(self, self.my_draw)
end

return Cauldron
