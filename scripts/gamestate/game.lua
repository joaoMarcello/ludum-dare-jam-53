local Pack = _G.JM_Love2D_Package
local Phys = Pack.Physics
local Utils = Pack.Utils
local Player = require "scripts.player"
local Bat = require "scripts.bat"
local Cauldron = require "scripts.cauldron"
local Item = require "scripts.item"
local Leader = require "scripts.gamestate.bests"

---@class GameState.Game : JM.Scene
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT,
    {
        left = -16 * 30,
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

Leader:on_quit_action(function()
    Leader:change_gamestate(State, {})
end)

Leader:on_restart_action(function()
    Leader:change_gamestate(State, {})
end)

--=============================================================================
---@type JM.Physics.World
local world
---@type Player
local player
---@type Cauldron
local cauldron

local components, score, time

local time_spawn = 0.0
local spawn_speed = 10.0
local time_game = 0.0

local bottom = State.camera.bounds_bottom - 32
local mush_spot = {
    { x = 16 * 7,  bottom = bottom, time = 0.0, obj = nil },
    { x = 16 * 27, bottom = bottom, time = 0.0, obj = nil },
}
--=============================================================================
local sort_update = function(a, b) return a.update_order > b.update_order end
local sort_draw = function(a, b) return a.draw_order < b.draw_order end

local insert, remove, tab_sort, random, abs = table.insert, table.remove, table.sort, math.random, math
    .abs

local function spawn_enemy(dt)
    if time_game >= 120 then
        spawn_speed = 4.0
    elseif time_game >= 90 then
        spawn_speed = 5.0
    elseif time_game >= 75 then
        spawn_speed = 6.0
    elseif time_game >= 45 then
        spawn_speed = 8.0
    end

    time_spawn = time_spawn + dt
    if time_spawn >= spawn_speed then
        time_spawn = time_spawn - spawn_speed
        if time_spawn >= spawn_speed then time_spawn = 0.0 end

        local cam = State.camera
        local vx, vy, vw, vh = cam:get_viewport_in_world_coord()

        local px, py
        py = vy + random() * (vh - 16 * 3)

        if random() >= 0.5 then
            px = vx - 32
        else
            px = vx + vw + 32
        end

        State:game_add_component(Bat:new(State, world, { x = px, bottom = py }))
    end
end


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

local function respawn_mush(dt)
    for i = 1, #mush_spot do
        local spot = mush_spot[i]

        ---@type Item
        local item = spot.obj
        if item.grabbed or item.dropped then
            spot.time = spot.time + dt

            if spot.time > 15.0 then
                spot.time = 0.0

                ---@type Item
                local obj = State:game_add_component(Item:new(State, world,
                    { x = spot.x, bottom = spot.bottom, allowed_gravity = false, item_type = item.type }))

                obj:apply_effect("popin", { speed = 0.3 })

                spot.obj = obj
            end
        end
    end
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
        time_spawn = -5.0
        time_game = 0.0

        State.camera.x = 0
        State.camera.y = 0

        world = Phys:newWorld {
            tile = 16,
        }

        local camera = State.camera

        local ground = Phys:newBody(world,
            camera.bounds_left,
            camera.bounds_bottom - 32,
            camera.bounds_right - camera.bounds_left,
            32,
            "static"
        )

        player = Player:new(State, world, { x = 16 * 3, bottom = ground.y })
        State:game_add_component(player)


        for i = 1, #mush_spot do
            mush_spot[i].time = 0.0

            local obj = State:game_add_component(Item:new(State, world,
                { x = mush_spot[i].x, bottom = mush_spot[i].bottom, allowed_gravity = true }))

            mush_spot[i].obj = obj
        end


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
        time_game = time_game + dt

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

        if not player:is_dead() then
            spawn_enemy(dt)
            respawn_mush(dt)

            State.camera:follow(player.x + player.w * 0.5, player.y + player.h * 0.5)
        else
            if player.time_state >= 3.0 and not State.transition then
                Leader:jgdr_pnt(score)



                State:add_transition("door", "out", {}, nil, function()
                    State:change_gamestate(Leader, { skip_finish = true, transition = "door" })
                end)
            end
        end
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
        --================== GUI ========================
        {
            cam_px = 0,
            cam_py = 0,
            --
            ---@param camera JM.Camera.Camera
            draw = function(self, camera)
                local font = JM_Font.current
                font:print(tostring(#components) .. "-" .. tostring(world.bodies_number), 16, 64)

                font:printf("SCORE:\n" .. tostring(score), 0, 8, "center", camera.viewport_w)


                if player:bag_is_full() then
                    font:printx("<effect=flickering, speed=0.8> <color>Bag is full!", 4, camera.viewport_h - 20)
                else
                    font:print("BAG: " .. player.bag_count, 4, camera.viewport_h - 20)
                end
            end
        }
    }
}

return State
