local GC = require "lib.component"

---@class DisplayBag : GameComponent
local Display = setmetatable({}, GC)
Display.__index = Display

local img

local lgx = love.graphics

local font = JM_Font.current


function Display:new(state, args)
    local obj = GC:new(state, args)
    setmetatable(obj, self)
    Display.__constructor__(obj, args)
    return obj
end

function Display:__constructor__(args)
    self.anim = _G.JM_Anima:new { img = img, frames = 4 }
end

function Display:load()
    img = img or lgx.newImage("data/img/bag-icons-Sheet.png")
end

function Display:finish()

end

function Display:update(dt)
    GC.update(self, dt)

    self.anim:update(dt)
end

local color = string.format("<color, %.2f, %.2f, %.2f>", 255 / 255, 252 / 255, 64 / 255)
function Display:my_draw()
    local player = self.gamestate:game_player()
    local w = 16 * player.bag_capacity
    local px = 320 - 20 - w
    local py = 12

    font:push()
    font:set_font_size(6)
    font:printf("<color, 0.9, 0.9, 0.9>BAG", px, py - 10, "center", w - 4)

    if player:bag_is_full() then
        font:set_font_size(8)
        local t = string.format("<effect=flickering, speed=0.6> %sFULL", color)
        font:printx(t, px, py + 16, w - 4, "center")
    end
    font:pop()

    for i = player.bag_capacity, 1, -1 do
        self.anim.current_frame = 4

        if player.bag_count >= i then
            ---@type Item
            local item = player.items[i]

            if item then
                local tp = item.type
                local Types = item.Types

                if tp == Types.mush then
                    lgx.setColor(1, 0, 0)
                    self.anim.current_frame = 1
                    --
                elseif tp == Types.mush_ex then
                    lgx.setColor(1, 1, 0)
                    self.anim.current_frame = 2
                    --
                elseif tp == Types.wing then
                    lgx.setColor(1, 0, 1)
                    self.anim.current_frame = 3
                    --
                end
                --
            else -- Item not ideintified
                lgx.setColor(1, 1, 1)
                --
            end
            --
        else -- EMPTY
            lgx.setColor(0, 0, 0)
        end

        -- lgx.rectangle("fill", px, py, 12, 12)
        self.anim:draw_rec(px, py, 16, 16)
        px = px + 16
    end

    -- self.anim:draw(100, 100)
end

function Display:draw()
    GC.draw(self, self.my_draw)
end

return Display
