local GC = require 'lib.component'

-- local Palette = {
--     red = { 212 / 255, 113 / 255, 93 / 255, 1 },
--     purple = { 77 / 255, 35 / 255, 74 / 255, 1 },
-- }

local img

---@class DisplayHP : GameComponent
local Display = setmetatable({}, GC)
Display.__index = Display

function Display:new(state, args)
    args = args or {}
    args.x = 16
    args.y = 8 + 4
    args.w = 32
    args.h = 16
    local obj = GC:new(state, args)
    setmetatable(obj, self)
    Display.__constructor__(obj, state, args)
    return obj
end

---@param state GameState.Game
function Display:__constructor__(state, args)
    self.gamestate = state

    local hp_max = state:game_player().max_hp

    self.hearts = {}
    for i = 1, hp_max do
        self.hearts[i] = _G.JM_Anima:new { img = img, frames = 2 }
        -- self.hearts[i]:apply_effect('pulse')
    end

    self.n_hearts = #self.hearts
    self.actives = {}
end

function Display:load()
    img = img or love.graphics.newImage('data/img/heart-icon-Sheet.png')
end

function Display:finish()
    img = nil
end

function Display:update(dt)
    GC.update(self, dt)

    -- for i = 1, self.n_hearts do
    --     ---@type JM.Anima
    --     local anima = self.hearts[i]
    --     anima:update(dt)
    -- end

    -- local player = self.gamestate:game_player()
    -- local i = player.hp
    -- if not self.actives[i] then
    --     ---@type JM.Anima
    --     local anima = self.hearts[i]
    --     self.actives[i] = anima:apply_effect('pulse')

    --     if self.actives[i + 1] then self.actives[i + 1].__remove = true end
    --     if self.actives[i - 1] then self.actives[i - 1].__remove = true end
    --     if self.actives[i - 2] then self.actives[i - 2].__remove = true end
    -- end
end

function Display:my_draw()
    local player = self.gamestate:game_player()

    for i = 1, player.max_hp do
        ---@type JM.Anima
        local heart = self.hearts[i]

        if i <= player.hp then
            -- love.graphics.setColor(Palette.red)
            heart.current_frame = 1
        else
            -- love.graphics.setColor(Palette.purple)
            heart.current_frame = 2
        end

        local px = self.x + (i - 1) * 16

        ---@type JM.Anima
        local heart = self.hearts[i]
        heart:draw(px, self.y)
        --love.graphics.rectangle("fill", px, self.y, 16, 16)
    end
end

function Display:draw()
    GC.draw(self, self.my_draw)
end

return Display
