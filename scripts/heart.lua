local GC = require "lib.bodyComponent"
local lgx = love.graphics

---@class Heart : BodyComponent
local Heart = setmetatable({}, GC)
Heart.__index = Heart

local score = 500

function Heart:new(state, world, args)
    args = args or {}
    args.x = args.x or 32
    args.y = args.y or 0
    args.w = 14
    args.h = 14
    args.type = "dynamic"

    local obj = GC:new(state, world, args)
    setmetatable(obj, self)
    Heart.__constructor__(obj, args)
    return obj
end

function Heart:__constructor__(args)
    local bd = self.body
    bd.allowed_gravity = true
    bd.bouncing_y = 0.9
    bd.mass = bd.mass * 0.3
    bd.max_speed_y = 16 * 2.5
    bd.speed_y = bd.max_speed_y

    self.ox = self.w * 0.5
    self.oy = self.h * 0.5

    self.duration = 10
end

function Heart:load()

end

function Heart:finish()

end

local tab = { speed = 0.1 }
function Heart:update(dt)
    GC.update(self, dt)

    local gamestate = self.gamestate
    local player = gamestate:game_player()
    local bd = self.body

    if not player:is_dead() then
        if player.body:check_collision(bd:rect()) then
            gamestate:game_add_score(score)
            player:hp_up(1)
            self.__remove = true
            return
        end
    end

    self.duration = self.duration - dt
    if self.duration <= 0 then
        self.__remove = true
    elseif self.duration <= 2.5 then
        self:apply_effect("flickering", tab)
    end
end

function Heart:my_draw()
    lgx.setColor(1, 0, 0)
    lgx.rectangle("fill", self.body:rect())
end

function Heart:draw()
    GC.draw(self, self.my_draw)
end

return Heart