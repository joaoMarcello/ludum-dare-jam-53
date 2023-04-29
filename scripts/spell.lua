local GC = require "lib.bodyComponent"
local lgx = love.graphics
local Phys = _G.JM_Love2D_Package.Physics

---@enum Spell.States
local States = {
    straight = 1,
    chase = 2,
}

local speed = 16 * 8


---@param self Spell
local chase = function(self, dt)
    local bd = self.body
    bd.speed_x = 0.0
    bd.acc_x = 0.0
end

---@param item JM.Physics.Body
local filter_to_chase = function(obj, item)
    ---@type Bat | nil
    local h = item.holder
    return item.id == 'bat' and (h and not h:is_dead())
end

---@param self Spell
local straight = function(self, dt)
    local box = self.hit_box
    local bd = self.body

    box:refresh(bd.x + bd.w * 0.5 - box.w * 0.5, bd.y + bd.h * 0.5 - box.h * 0.5)

    local col = box:check(nil, nil, filter_to_chase)
    if col.n > 0 then
        local index = math.random(1, col.n)
        self.chase_obj = col.items[index].holder
        self:set_state(States.chase)
    end
end

---@class Spell : BodyComponent
local Spell = setmetatable({}, GC)
Spell.__index = Spell

function Spell:new(state, world, args)
    args = args or {}
    args.type = "ghost"
    args.w = 10
    args.h = 10
    args.draw_order = 15
    args.direction = args.direction or 1

    local obj = GC:new(state, world, args)
    setmetatable(obj, self)
    Spell.__constructor__(obj, args)
    return obj
end

function Spell:__constructor__(args)
    local bd = self.body
    bd.allowed_gravity = false
    bd.allowed_air_dacc = true
    bd.id = "spell"

    self.direction = args.direction
    bd.speed_x = args.direction > 0 and speed or -speed
    -- bd.dacc_x = 0

    self.state = nil
    self:set_state(States.straight)

    self.hit_box = Phys:newBody(self.world, self.x, self.y,
        16 * 5,
        16 * 5, "ghost"
    )
    self.hit_box.allowed_gravity = false

    ---@type Bat | any
    self.chase_obj = nil
end

function Spell:load()

end

function Spell:finish()

end

function Spell:remove()
    self.__remove = true
    self.hit_box.__remove = true
end

function Spell:set_state(state)
    if state == self.state then return false end
    local last = self.state
    self.state = state

    if state == States.straight then
        self.cur_movement = straight
        --
    elseif state == States.chase then
        self.cur_movement = chase
        --
    end

    return true
end

function Spell:update(dt)
    GC.update(self, dt)

    self:cur_movement(dt)
end

function Spell:my_draw()
    lgx.setColor(0, 0, 0)
    lgx.rectangle("fill", self.body:rect())

    lgx.rectangle("line", self.hit_box:rect())
end

function Spell:draw()
    GC.draw(self, self.my_draw)
end

return Spell
