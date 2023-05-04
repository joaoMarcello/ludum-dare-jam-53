local GC = require "lib.component"
local Utils = _G.JM_Utils

---@type JM.Font.Font
local font

local tile = 16

---@class DisplayText : GameComponent
local Display = setmetatable({}, GC)
Display.__index = Display

---@return DisplayText
function Display:new(state, args)
    args = args or {}
    args.w = args.w or 64
    args.draw_order = 50

    local obj = setmetatable(GC:new(state, args), self)
    Display.__constructor__(obj, state, args)
    return obj
end

function Display:__constructor__(state, args)
    self.text = args.text and tostring(args.text) or "None"
    self.text = "<bold>" .. self.text
    self.text_white = "<color, 1, 1, 1>" .. self.text

    self.x = self.x - self.w * 0.5
    self.acumulator = 0
    self.time = 0
    self.duration = args.duration or 1

    -- self:set_draw_order(15)
end

function Display:load()
    font = _G.JM_Font.current
end

function Display:finish()

end

function Display:update(dt)
    GC.update(self, dt)

    self.time = self.time + dt

    local last = self.y

    if self.acumulator <= tile or true then
        local vx, vy, vw, vh = self.gamestate.camera:get_viewport_in_world_coord()

        if not self.gamestate:get_camera("cam2") then
            self.y = Utils:clamp(self.y - tile * 2 * dt, vy + 4, vy + vh - tile * 1.5)
        else
            self.y = self.y - tile * 2 * dt
        end
        self.acumulator = self.acumulator + math.abs(last - self.y)
    end

    if self.time > self.duration then
        self.__remove = true
    end
end

function Display:my_draw()
    -- font:print(self.text, self.x + 1, self.y + 1)
    -- font:print(self.text_white, self.x, self.y)
    font:printf(self.text_white, self.x, self.y, "center", self.w)
end

function Display:draw()
    GC.draw(self, self.my_draw)
end

return Display
