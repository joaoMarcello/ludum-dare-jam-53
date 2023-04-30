local GC = require "lib.bodyComponent"
local lgx = love.graphics

---@enum Item.Types
local Types = {
    mush = 1,
    wing = 2,
    fruit = 3,
    heart = 4,
}

---@enum Item.Scores
local Scores = {
    [Types.mush] = 150,
    [Types.wing] = 50,
    [Types.fruit] = 150,
    [Types.heart] = 100,
}

---@class Item : BodyComponent
local Item = setmetatable({}, GC)
Item.__index = Item
Item.Types = Types
Item.Scores = Scores

function Item:new(state, world, args)
    args = args or {}
    args.type = "dynamic"
    args.w = 12
    args.h = 12
    args.draw_order = -1
    args.y = args.bottom and (args.bottom - args.h) or args.y

    local obj = GC:new(state, world, args)
    setmetatable(obj, self)
    Item.__constructor__(obj, args)
    return obj
end

---@param self Item
local ground_touch_action = function(self)
    self.bounce_count = self.bounce_count + 1
end

function Item:__constructor__(args)
    local bd = self.body
    bd.allowed_gravity = args.allowed_gravity
    bd.allowed_air_dacc = args.allowed_air_dacc
    bd.speed_x = args.speed_x or bd.speed_x

    bd.mass = bd.mass * 0.25
    bd.max_speed_y = 16 * 4

    self.type = args.item_type or Types.mush
    self.score = Scores[self.type]

    self.grabbed = false

    self.auto_remove = args.auto_remove

    self.time_dropped = 0.0
    self.time_throw = 0.0
    self.bounce_count = 0

    self.ox = self.w * 0.5
    self.oy = self.h * 0.5

    bd:on_event("ground_touch", ground_touch_action, self)
end

function Item:load()

end

function Item:finish()

end

function Item:drop()
    if self.dropped then return end

    self.dropped = true

    ---@type GameState.Game | any
    local gamestate = self.gamestate
    local player_bd = gamestate:game_player().body

    local bd = self.body
    bd.allowed_gravity = true
    bd.allowed_air_dacc = false
    bd.max_speed_y = nil
    bd.bouncing_y = 0.6
    bd.bouncing_x = 0.5
    bd.speed_y = 0.0
    self:set_visible(true)
    bd.speed_x = player_bd.speed_x
    bd.dacc_x = 16 * 1

    self:deflick()

    self.time_dropped = 0.0
    self.time_throw = 0.0
    self.bounce_count = 0

    bd:refresh(player_bd.x, player_bd:bottom() - bd.h)
end

function Item:deflick()
    local eff = self.eff_actives and self.eff_actives['flickering']
    if eff then
        eff.__remove = true
        self.eff_actives['flickering'] = nil
        self:set_visible(true)
    end
end

function Item:grab()
    local player = self.gamestate:game_player()
    local success = player:insert_item(self)

    if success then
        self.grabbed = true
        self.dropped = false
        self:deflick()
        self:set_visible(false)
    end
end

local tab = { speed = 0.06 }
function Item:update(dt)
    GC.update(self, dt)

    ---@type GameState.Game | any
    local gamestate = self.gamestate

    local bd = self.body

    if not self.grabbed then
        local player = gamestate:game_player()

        if bd:check_collision(player.body:rect()) then
            self:grab()
        end
    end

    if self.dropped or (not self.grabbed and self.auto_remove) then
        self.time_throw = self.time_throw + dt

        local cauldron = gamestate:game_cauldron()
        if cauldron:is_inside(bd) then
            local score = self.score
            score = self.bounce_count > 0 and (score * 5) or score
            gamestate:game_add_score(score)
            self.__remove = true
            return
        end

        if bd.ground then
            if bd.speed_y == 0 then
                bd.dacc_x = 16 * 8
            end
            self.time_dropped = self.time_dropped + dt

            if self.time_dropped >= 3 then
                self:apply_effect('flickering', tab)
            end

            if self.time_dropped >= 4.5 then
                self.__remove = true
                return
            end
        end

        if bd.ground or self.time_throw >= 1.5 then
            local player = gamestate:game_player()
            if bd:check_collision(player.body:rect()) then
                self:grab()
            end
        end
    end
end

function Item:my_draw()
    lgx.setColor(self.color)
    lgx.rectangle("fill", self.body:rect())
end

function Item:draw()
    GC.draw(self, self.my_draw)
    -- local font = JM_Font.current
    -- font:print(tostring(self.bounce_count), self.x, self.y - 10)
end

return Item
