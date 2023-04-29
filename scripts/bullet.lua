local GC = require "lib.component"

---@class Bullet : GameComponent
local Bullet = setmetatable({}, GC)
Bullet.__index = Bullet

function Bullet:new(state, args)
    local obj = GC:new(state, args)
    setmetatable(obj, self)
    Bullet.__constructor__(args)
    return obj
end

function Bullet:__constructor__(args)

end

return Bullet
