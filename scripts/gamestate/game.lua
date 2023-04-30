local Pack = _G.JM_Love2D_Package
local Phys = Pack.Physics
local Player = require "scripts.player"
local Bat = require "scripts.bat"
local Cauldron = require "scripts.cauldron"
local Item = require "scripts.item"

---@class GameState.Game : JM.Scene
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT,
    {
        left = -16 * 6,
        top = -16 * 5,
        right = 16 * 50,
        bottom = 16 * 12,
    },
    --
    {
        subpixel = 3,
        canvas_filter = 'linear',
        tile = 16,
        cam_tile = 16,
    }
)

State.camera:set_focus_y(State.camera.viewport_h * 0.25)
--=============================================================================
---@type JM.Physics.World
local world
---@type Player
local player
---@type Cauldron
local cauldron

local components, score, time
--=============================================================================
local sort_update = function(a, b) return a.update_order > b.update_order end
local sort_draw = function(a, b) return a.draw_order < b.draw_order end

local insert, remove, tab_sort, random, abs = table.insert, table.remove, table.sort, math.random, math
    .abs

function State:game_add_component(gc)
    insert(components, gc)
    return gc
end

function State:game_remove_component(index)
    ---@type JM.Physics.Body
    local body = components[index].body
    if body then
        body.__remove = true
    end
    return remove(components, index)
end

function State:game_components()
    return components
end

function State:game_player()
    return player
end

function State:game_cauldron()
    return cauldron
end

function State:game_add_score(value)
    value = abs(value)
    score = score + value
end

--=============================================================================
State:implements {
    load = function()
        Player:load()
        Bat:load()
        Cauldron:load()
        Item:load()
    end,
    --
    --
    init = function()
        --
        components = {}
        score = 0

        world = Phys:newWorld {
            tile = 16,
        }

        player = Player:new(State, world, {})
        State:game_add_component(player)

        State:game_add_component(Bat:new(State, world, {}))
        State:game_add_component(Bat:new(State, world, { x = 0, y = 0 }))
        State:game_add_component(Item:new(State, world, { x = 64, y = 0, allowed_gravity = true }))

        local ground = Phys:newBody(world, 0, State.camera.bounds_bottom - 32, 16 * 50, 32, "static")

        cauldron = State:game_add_component(Cauldron:new(State, world, { x = 16 * 16, bottom = ground.y }))
    end,
    --
    --
    finish = function()
        Player:finish()
        Bat:finish()
        Cauldron:finish()
        Item:finish()
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
                skip_finish = true,
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

        tab_sort(components, sort_update)

        for i = #components, 1, -1 do
            ---@type GameComponent
            local gc = components[i]

            local r = gc.update and gc.is_enable
                and not gc.__remove and gc:update(dt)

            if gc.__remove then
                State:game_remove_component(i)
            end
        end

        State.camera:follow(player.x + player.w * 0.5, player.y + player.h * 0.5)
    end,

    layers = {
        --
        --================== TREES ========================
        {
            factor_x = -0.6,
            factor_y = -0.6,
            infinity_scroll_x = true,
            scroll_width = 32 * 6,
            ---@param camera JM.Camera.Camera
            draw = function(self, camera)
                love.graphics.setColor(0, 0, 1)
                love.graphics.rectangle("fill", -16, camera.bounds_bottom - 16 * 7, 32, 16 * 7)
            end
        },
        --
        --================== MAIN LAYER ========================
        {
            draw = function(self, camera)
                for i = 1, #world.bodies_static do
                    ---@type JM.Physics.Body
                    local bd = world.bodies_static[i]
                    bd:draw()
                end

                tab_sort(components, sort_draw)
                for i = 1, #components do
                    ---@type GameComponent
                    local gc = components[i]
                    local r = gc.draw and gc:draw()
                end
            end
        },
        --
        --
        {
            cam_px = 0,
            cam_py = 0,
            draw = function(self, camera)
                local font = JM_Font.current
                font:print(tostring(#components) .. "-" .. tostring(world.bodies_number), 16, 64)

                font:printf("SCORE:\n" .. tostring(score), 0, 8, "center", camera.viewport_w)
            end
        }
    }
}

return State
