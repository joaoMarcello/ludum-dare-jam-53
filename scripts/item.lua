local GC = require "lib.bodyComponent"
local lgx = love.graphics

---@enum Item.Types
local Types = {
    mush = 1,
    wing = 2,
    fruit = 3,
    heart = 4,
}

---@class Item : BodyComponent
local Item = setmetatable({}, GC)
Item.__index = Item
Item.Types = Types

function Item:new(state, world, args)
    args = args or {}
    args.type = "dynamic"
    args.w = 16
    args.h = 16
    args.draw_order = 0

    local obj = GC:new(state, world, args)
    setmetatable(obj, self)
    Item.__constructor__(obj, args)
    return obj
end

function Item:__constructor__(args)
    local bd = self.body
    bd.allowed_gravity = args.allowed_gravity
    bd.allowed_air_dacc = args.allowed_air_dacc

    self.type = args.type or Types.mush
end

function Item:load()

end

function Item:finish()

end

function Item:update(dt)
    GC.update(self, dt)
end

function Item:my_draw()
    lgx.setColor(1, 0, 1)
    lgx.rectangle("fill", self.body:rect())
end

function Item:draw()
    GC.draw(self, self.my_draw)
end

return Item
