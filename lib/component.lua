local Affectable = _G.JM_Affectable

---@class GameComponent: JM.Template.Affectable
local GC = setmetatable({}, Affectable)
GC.__index = GC

---@param game JM.Scene
---@return table
function GC:new(game, args)
    args = args or {}
    local obj = setmetatable(Affectable:new(), GC)
    GC.__constructor__(obj, game, args)
    return obj
end

---@param state JM.Scene
function GC:__constructor__(state, args)
    self.gamestate = state

    self.x = args.x or 0
    self.y = args.y or 0
    self.w = args.w or 0
    self.h = args.h or 0

    self.is_visible = true
    self.is_enable = true

    self.__remove = false

    self.draw_order = args.draw_order or 0
    self.update_order = args.update_order or 0

    self.draw_order = self.draw_order + math.random()
    self.update_order = self.update_order + math.random()
end

function GC:set_draw_order(value)
    value = math.abs(value)
    self.draw_order = value + math.random()
end

function GC:set_update_order(value)
    value = math.abs(value)
    self.update_order = value + math.random()
end

function GC:load()

end

function GC:init()

end

function GC:finish()

end

---@param eff_type JM.Effect.id_string
---@param eff_args any
---@return JM.Effect|any
function GC:apply_effect(eff_type, eff_args, force)
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

function GC:update(dt)
    Affectable.update(self, dt)
end

---@param custom_draw function|nil
function GC:draw(custom_draw)
    if custom_draw then
        Affectable.draw(self, custom_draw)
    end
end

return GC
