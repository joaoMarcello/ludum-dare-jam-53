-- local GC = require "lib.bodyComponent"
-- local GC = require "jm-love2d-package.modules.gamestate.body_object"
local GC = _G.JM_Package.BodyObject
local lgx = love.graphics

---@enum Item.Types
local Types = {
    mush = 1,
    wing = 2,
    fruit = 3,
    heart = 4,
    mush_ex = 5,
}

---@enum Item.Scores
local Scores = {
    [Types.mush] = 150,
    [Types.wing] = 50,
    [Types.fruit] = 150,
    [Types.heart] = 100,
    [Types.mush_ex] = 250,
}

local reuse_tab = {}
local pairs = pairs
local function empty_table()
    for index, _ in pairs(reuse_tab) do
        reuse_tab[index] = nil
    end
    return reuse_tab
end

local imgs

local arrow_color = _G.JM_Utils:get_rgba2(180, 32, 42)

---@class Item : BodyObject
local Item = setmetatable({}, GC)
Item.__index = Item
Item.Types = Types
Item.Scores = Scores

function Item:new(args)
    args = args or {}
    -- args.type = "dynamic"
    -- args.w = 12
    -- args.h = 12
    -- args.draw_order = -1
    args.y = args.bottom and (args.bottom - 12) or args.y

    local obj = GC:new(args.x, args.y, 12, 12, -1, 0, "dynamic")
    setmetatable(obj, self)
    Item.__constructor__(obj, args)
    return obj
end

---@param self Item
local ground_touch_action = function(self)
    self.bounce_count = self.bounce_count + 1
end

local eff_tab = { range = 2 }
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

    local Anima = _G.JM_Anima

    local tab = empty_table()
    tab.img = imgs[self.type]
    self.anim = Anima:new(tab)

    tab = empty_table()
    tab.img = imgs["mini-arrow"]
    self.anim_arrow = Anima:new(tab)
    self.anim_arrow:apply_effect("float", eff_tab)
    self.anim_arrow:set_color(arrow_color)

    bd:on_event("ground_touch", ground_touch_action, self)
end

function Item:load()
    local newImage = lgx.newImage
    imgs = imgs or {
        [Types.wing] = newImage("data/img/bat-wing.png"),
        [Types.mush] = newImage("data/img/mushroom.png"),
        [Types.mush_ex] = newImage("data/img/mush-ex.png"),
        ["mini-arrow"] = newImage("/data/img/mini-arrow.png"),
    }
end

function Item:finish()
    imgs = nil
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
    bd.speed_y = 16 + 16
    self:set_visible(true)
    bd.speed_x = player_bd.speed_x
    bd.dacc_x = 16 * 1

    self:deflick()

    self.time_dropped = 0.0
    self.time_throw = 0.0
    self.bounce_count = 0

    bd:refresh(player_bd.x, player_bd:bottom())

    local col = bd:check(nil, bd.y + 2, bd.filter_col_y, bd.empty_table(), bd.empty_table_for_coll())

    if col.n > 0 then
        bd:resolve_collisions_y(col)
    else
        _G.PLAY_SFX("drop", true)
    end

    -- gamestate:display_text("grabbed", bd.x, bd.y)
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
    ---@type GameState.Game | any
    local gamestate = self.gamestate
    local player = gamestate:game_player()
    local success = player:insert_item(self)

    if success then
        self.grabbed = true
        self.dropped = false
        self:deflick()
        self:set_visible(false)
        _G.PLAY_SFX("collect", true)
    end
end

local tab = { speed = 0.06 }
function Item:update(dt)
    -- GC.update(self, dt)
    self.__effect_manager:update(dt)

    self.anim:update(dt)
    self.anim_arrow:update(dt)

    ---@type GameState.Game | any
    local gamestate = self.gamestate

    local bd = self.body

    if not self.grabbed then
        local player = gamestate:game_player()

        if player.body:check_collision(self.x, self.y - 4, self.w, self.h + 8) then
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

            gamestate:display_text(tostring(score), bd.x, cauldron.y - 32)
            _G.PLAY_SFX("power_up", true)

            cauldron:shake()

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
            -- if bd:check_collision(player.body:rect()) then
            if player.body:check_collision(self.x, self.y - 8, self.w, self.h + 16) then
                self:grab()
            end
        end
    end
end

function Item:my_draw()
    -- lgx.setColor(self.color)
    -- lgx.rectangle("fill", self.body:rect())
    self.anim:draw_rec(self.x, self.y, self.w, self.h)

    if self.body.ground and self.body.speed_y == 0 then
        self.anim_arrow:draw_rec(self.x, self.y - 24, self.w, self.h)
    end
end

function Item:draw()
    if self.grabbed and not self.dropped then return end
    GC.draw(self, self.my_draw)
    -- local font = JM_Font.current
    -- font:print(tostring(self.bounce_count), self.x, self.y - 10)
end

return Item
