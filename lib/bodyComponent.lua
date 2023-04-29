local Phys = _G.JM_Love2D_Package.Physics
local Affectable = _G.JM_Love2D_Package.Affectable
local GC = require "lib.component"

---@class BodyComponent: JM.Template.Affectable, GameComponent
local Component = JM_Utils:create_class(Affectable, GC)

---@param game JM.Scene
---@param world JM.Physics.World
---@param args table
---@return table
function Component:new(game, world, args)
    local obj = GC:new(game, args)

    setmetatable(obj, self)
    Affectable.__constructor__(obj)
    Component.__constructor__(obj, world, args)
    return obj
end

function Component:__constructor__(world, args)
    args.x = args.x or (32 * 2)
    args.y = args.y or (32 * 3)
    args.w = args.w or 32
    args.h = args.h or 32

    self.x = args.x
    self.y = args.y
    self.w = args.w
    self.h = args.h

    self.args = args

    ---@type JM.Physics.World
    self.world = world

    self.is_enable = true
    self.__remove = false

    self.body = Phys:newBody(world, args.x, args.y, args.w, args.h, args.type or "static")

    self.body:set_holder(self)

    if self.body.type ~= Phys.BodyTypes.static then
        self.max_speed = args.max_speed or (64 * 5)
        self.acc = args.acc or (64 * 4)
        self.dacc = args.dacc or (64 * 10)
    end
end

function Component:init()
    local args = self.args
    self.x = args.x
    self.y = args.y
    self.w = args.w
    self.h = args.h

    self.is_enable = true
    self.__remove = false
end

---@param eff_type JM.Effect.id_string
---@param eff_args any
---@return JM.Effect|any
function Component:apply_effect(eff_type, eff_args, force)
    if not self.eff_actives then self.eff_actives = {} end

    if not force
        and self.eff_actives[eff_type]
        and not self.eff_actives[eff_type].__remove
    then
        return nil
    end

    if self.eff_actives[eff_type] then
        self.eff_actives[eff_type].__remove = true
    end

    self.eff_actives[eff_type] = Affectable.apply_effect(self, eff_type, eff_args)
    return self.eff_actives[eff_type]
end

function Component:get_cx()
    return self.body.x + self.body.w * 0.5
end

function Component:get_cy()
    return self.body.y + self.body.h * 0.5
end

function Component:update(dt)
    Affectable.update(self, dt)
    self.x, self.y = self.body.x, self.body.y
end

function Component:draw(custom_draw)
    if custom_draw then
        Affectable.draw(self, custom_draw)
    end
    return false
end

return Component
