local GC = require "lib.component"

---@class DisplaySpell : GameComponent
local Display = setmetatable({}, GC)
Display.__index = Display

local color = _G.JM_Utils:get_rgba2(254, 243, 192)

function Display:new(state, world, args)
    args = args or {}
    args.x = 12
    args.y = 16 * 2 - 8

    local obj = GC:new(state, args)
    setmetatable(obj, self)
    Display.__constructor__(self, world, args)
    return obj
end

function Display:__constructor__(world, args)
    self.max_width = 16 * 3
end

function Display:load()

end

function Display:finish()

end

function Display:update(dt)
    GC.update(self, dt)

    local player = self.gamestate:game_player()
    local time_rel = player:reload_spell_speed()

    local perc = (time_rel - player.time_spell) / time_rel

    self.w = self.max_width * (1 - perc)
end

function Display:my_draw()
    local player = self.gamestate:game_player()

    local lgx = love.graphics
    local px = self.x
    for i = 1, player.max_spell do
        if i <= player.count_spell then
            lgx.setColor(1, 1, 1)
        else
            lgx.setColor(0, 0, 0)
        end
        lgx.rectangle("fill", px, self.y, 13, 13)
        px = px + 16
    end

    lgx.setColor(color)
    lgx.rectangle("fill", self.x, self.y + 18, self.w, 3)
end

function Display:draw()
    GC.draw(self, self.my_draw)
end

return Display
