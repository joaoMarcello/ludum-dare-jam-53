local Pack = _G.JM_Love2D_Package
local Phys = Pack.Physics
local Player = require "scripts.player"

local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT,
    {
        left = 0,
        top = -16 * 0,
        right = 16 * 50,
        bottom = 16 * 12,
    },
    --
    {
        subpixel = 2,
        canvas_filter = 'linear',
        tile = 16,
        cam_tile = 16,
    }
)
--=============================================================================
---@type JM.Physics.World
local world
---@type Player
local player
--=============================================================================--=============================================================================
State:implements {
    load = function()
        Player:load()
    end,
    --
    --
    init = function()
        world = Phys:newWorld {
            tile = 16,
        }

        player = Player:new(State, world, {})
        Phys:newBody(world, 0, State.camera.bounds_bottom - 32, 16 * 50, 32, "static")
    end,
    --
    --
    finish = function()
        Player:finish()
    end,
    --
    --
    keypressed = function(key)
        if key == 'o' then
            State.camera:toggle_grid()
            State.camera:toggle_world_bounds()
            -- State.camera:toggle_debug()
        end

        if key == 'p' then
            State:change_gamestate(State, {
                skip_load = true,
                transition = "door",
                transition_conf = {}
            })
            return
        end

        player:key_pressed(key)
    end,

    keyreleased = function(key)
        player:key_released(key)
    end,

    update = function(dt)
        world:update(dt)
        player:update(dt)

        State.camera:follow(player.x + player.w * 0.5, player.y + player.h * 0.5)
    end,

    layers = {
        {
            draw = function(self, camera)
                for i = 1, #world.bodies_static do
                    ---@type JM.Physics.Body
                    local bd = world.bodies_static[i]
                    bd:draw()
                end

                player:draw()
            end
        },
    }
}

return State
