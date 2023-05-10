-- local GC = require "lib.bodyComponent"
local GC = require "jm-love2d-package.modules.gamestate.body_object"
local lgx = love.graphics
local Phys = _G.JM_Love2D_Package.Physics

---@enum Spell.States
local States = {
    straight = 1,
    chase = 2,
}

local speed = 16 * 3
local speed_chase = 16 * 3
local dacc = 16 * 3

local imgs

---@type GameState.Game | JM.Scene | any
local gamestate

---@param self Spell
local chase = function(self, dt)
    local bd = self.body
    local obj_bd = self.chase_obj.body

    bd.speed_x = 0.0
    bd.acc_x = 0.0

    local dx = (bd.x + bd.w * 0.5) - (obj_bd.x + obj_bd.w * 0.5)
    local dy = (bd.y + bd.h * 0.5) - (obj_bd.y + obj_bd.h * 0.5)
    local angle = math.atan2(dy, dx)
    local dist = math.sqrt(dx ^ 2 + dy ^ 2)


    bd:refresh(
        bd.x - speed_chase * math.cos(angle) * dt,
        bd.y - speed_chase * math.sin(angle) * dt
    )

    if self.chase_obj:is_dead() or self.chase_obj.__remove then
        self.direction = bd.speed_x < 0 and -1 or 0
        self:set_state(States.straight)
    end

    self:destroy_bat()
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

    local col = box:check(nil, nil, filter_to_chase,
        box.empty_table(), box.empty_table_for_coll()
    )
    if col.n > 0 then
        local index = math.random(1, col.n)
        self.chase_obj = col.items[index].holder
        self:set_state(States.chase)
        --
    elseif not self.gamestate.camera:rect_is_on_view(bd:rect()) then
        self:remove()
        --
    end

    self:destroy_bat()
end

---@class Spell : BodyObject
local Spell = setmetatable({}, GC)
Spell.__index = Spell

function Spell:new(x, y, direction)
    --
    local obj = GC:new(x, y, 10, 10, 15, 0, "ghost")
    setmetatable(obj, self)
    Spell.__constructor__(obj, direction)
    return obj
end

local anim_args = { img = imgs }
function Spell:__constructor__(direction)
    local bd = self.body
    bd.allowed_gravity = false
    bd.allowed_air_dacc = true
    bd.max_speed_x = speed
    bd.id = "spell"

    self.direction = direction or 1

    self.strength = 1

    self.state = nil
    self:set_state(States.straight)

    self.hit_box = Phys:newBody(self.world, self.x, self.y,
        16 * 4,
        16 * 6, "ghost"
    )
    self.hit_box.allowed_gravity = false

    anim_args.img = imgs
    self.anim = _G.JM_Anima:new(anim_args)
    anim_args.__frame_obj_list__ = self.anim.frames_list

    ---@type Bat | any
    self.chase_obj = nil
end

function Spell:load()
    imgs = imgs or lgx.newImage("data/img/spell.png")
end

function Spell:finish()
    imgs = nil
end

function Spell:destroy_bat()
    local bd = self.body
    local col = bd:check(nil, nil, filter_to_chase, bd.empty_table(), bd.empty_table_for_coll())

    if col.n > 0 then
        for i = 1, col.n do
            ---@type Bat
            local bat = col.items[i].holder
            bat:damage(self.strength)
        end
        self:remove()
    end
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
        self.body.speed_x = self.direction > 0 and speed or -speed
        --
    elseif state == States.chase then
        self.cur_movement = chase
        --
    end

    return true
end

function Spell:update(dt)
    GC.update(self, dt)

    self.anim:update(dt)

    ---@type GameState.Game
    ---@diagnostic disable-next-line: assign-type-mismatch
    gamestate = self.gamestate

    local player = gamestate:game_player()

    if player:is_dead() then
        self:remove()
    else
        self:cur_movement(dt)
    end

    gamestate = nil
end

function Spell:my_draw()
    -- lgx.setColor(0, 0, 0)
    -- lgx.rectangle("fill", self.body:rect())

    -- lgx.rectangle("line", self.hit_box:rect())

    self.anim:draw(self.x + self.w * 0.5, self.y + self.h * 0.5)
end

function Spell:draw()
    GC.draw(self, self.my_draw)
end

return Spell
