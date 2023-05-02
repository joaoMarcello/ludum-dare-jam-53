local Pack = _G.JM_Love2D_Package
local Phys = Pack.Physics
local Utils = Pack.Utils
local TileMap = Pack.TileMap
local Player = require "scripts.player"
local Bat = require "scripts.bat"
local Cauldron = require "scripts.cauldron"
local Item = require "scripts.item"
local Leader = require "scripts.gamestate.bests"
local Heart = require "scripts.heart"
local DisplayHP = require "scripts.display_hp"
local DisplaySpell = require "scripts.display_spell"
local DisplayBag = require "scripts.display_bag"

---@class GameState.Game : JM.Scene
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT,
    {
        left = -16 * 20,
        top = -16 * 5,
        right = 16 * 50,
        bottom = 16 * 12,
    },
    --
    {
        subpixel = _G.SUB_PIXEL or 3,
        canvas_filter = 'linear',
        tile = 16,
        cam_tile = 16,
    }
)

State.camera:set_focus_y(State.camera.viewport_h * 0.25)
State:set_color(unpack(Utils:get_rgba2(64, 51, 83)))

Leader:on_quit_action(function()
    if not Leader.transition then
        _G.PLAY_SFX("click")

        Leader:add_transition("curtain", "out", { type = "left-right" }, nil, function()
            Leader:change_gamestate(require "scripts.gamestate.title",
                { skip_finish = false, transition = "curtain", transition_conf = { delay = 0.3, type = "left-right" } })
        end)
    end
    -- love.event.quit()
end)

Leader:on_restart_action(function()
    if not Leader.transition then
        _G.PLAY_SFX("click")

        Leader:add_transition("cartoon", "out", { type = "left-right" }, nil, function()
            Leader:change_gamestate(require "scripts.gamestate.how_to_play",
                { skip_finish = false, transition = "cartoon", transition_conf = { delay = 0.3, type = "left-right" } })
        end)
    end
end)

local lgx = love.graphics

--=============================================================================
---@type JM.Physics.World
local world
---@type Player
local player
---@type Cauldron
local cauldron

local components, score, time

local imgs
local anim

local time_spawn = 0.0
local spawn_speed = 11 -- 11
local time_game = 0.0
local time_heart = 0.0

---@type DisplayHP
local display_hp
---@type DisplaySpell
local display_spell
---@type DisplayBag
local display_bag

---@type JM.TileMap
local ground_tilemap

local bottom = State.camera.bounds_bottom - 32
local mush_spot = {
    { x = -16 * 10, bottom = bottom, time = 0.0, obj = nil, type = Item.Types.mush_ex },
    { x = 16 * 7,   bottom = bottom, time = 0.0, obj = nil, type = Item.Types.mush },
    { x = 16 * 27,  bottom = bottom, time = 0.0, obj = nil, type = Item.Types.mush },
    { x = 16 * 40,  bottom = bottom, time = 0.0, obj = nil, type = Item.Types.mush_ex },
}

local ground_map = function()
    local left = -16 * 20
    local top = -16 * 5
    local right = 16 * 50
    local bottom = 16 * 12

    local px, py = left, (bottom - 32)
    local qx = _G.math.floor((right - left) / 16)
    for i = 0, qx do
        if i % 2 == 0 then
            Entry(px + 16 * i, py, 1)
            Entry(px + 16 * i, py + 16, 3)
        else
            Entry(px + 16 * i, py, 2)
            Entry(px + 16 * i, py + 16, 4)
        end
    end
end

local reuse_tab = {}
local pairs = pairs
local function empty_table()
    for index, _ in pairs(reuse_tab) do
        reuse_tab[index] = nil
    end
    return reuse_tab
end
--=============================================================================
local sort_update = function(a, b) return a.update_order > b.update_order end
local sort_draw = function(a, b) return a.draw_order < b.draw_order end

local insert, remove, tab_sort, random, abs = table.insert, table.remove, table.sort, math.random, math
    .abs

local function spawn_enemy(dt)
    if time_game >= 140 then
        spawn_speed = 4.0
    elseif time_game >= 100 then
        spawn_speed = 5.0
    elseif time_game >= 80 then
        spawn_speed = 7.0
    elseif time_game >= 50 then
        spawn_speed = 9.0
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

        local tab = empty_table()
        tab.x = px
        tab.bottom = py

        State:game_add_component(Bat:new(State, world, tab))
        -- State:game_add_component(Bat:new(State, world, { x = px, bottom = py }))
    end
end

local function spawn_heart(dt)
    time_heart = time_heart + dt
    if time_heart >= 25 then --25
        time_heart = 0
        local vx, vy, vw, vh = State.camera:get_viewport_in_world_coord()
        vx = vx + 16
        vw = vw - 16

        local tab = empty_table()
        tab.x = (vx + vw * random())
        tab.y = vy - 32

        State:game_add_component(
            Heart:new(State, world, tab)
        )
        -- State:game_add_component(
        --     Heart:new(State, world, { x = (vx + vw * random()), y = vy - 32 })
        -- )
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

            if spot.time > 18.0 then
                spot.time = 0.0

                ---@type Item
                local obj = State:game_add_component(Item:new(State, world,
                    {
                        x = spot.x,
                        bottom = spot.bottom,
                        allowed_gravity = true,
                        item_type = spot.type,
                    }
                ))

                obj:apply_effect("popin", { speed = 0.3 })

                if State.camera:rect_is_on_view(obj.x, obj.y, obj.w, obj.h) then
                    _G.PLAY_SFX("enemy_die", true)
                end

                spot.obj = obj
            end
        end
    end
end

function State:display_text(text, x, y, duration)
    x = x or 0
    y = y or 0

    local tab = empty_table()
    tab.text = text
    tab.x = x
    tab.y = y
    tab.duration = duration

    if not self.camera:rect_is_on_view(x, y, 0, 0) then
        tab.x = player.x
        tab.y = player.y - 32
    end

    self:game_add_component(_G.DisplayText:new(self, tab))
end

--=============================================================================
State:implements {
    load = function()
        Player:load()
        Bat:load()
        Cauldron:load()
        Item:load()
        Heart:load()
        DisplayHP:load()
        DisplaySpell:load()
        DisplayBag:load()

        ground_tilemap = TileMap:new(ground_map, "data/img/ground-tile.png", 16)

        local newImage = love.graphics.newImage
        imgs = imgs or {
            stars = newImage("data/img/sky.png"),
            night_sky = newImage("data/img/night-sky.png"),
            trees = newImage("data/img/trees.png"),
            mountain = newImage("data/img/mountain.png"),
        }

        local Anima = _G.JM_Anima
        anim = anim or {
            stars = Anima:new { img = imgs.stars },
            night_sky = Anima:new { img = imgs.night_sky },
        }
    end,
    --
    --
    init = function()
        --
        components = {}
        score = 0
        time_spawn = -5.0
        time_game = -5.0
        time_heart = 0.0


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

        player = Player:new(State, world, { x = 16 * 0, bottom = ground.y })
        State:game_add_component(player)

        State.camera.x = 0
        State.camera.y = 0
        State.camera:set_position(player.x - camera.focus_x)


        for i = 1, #mush_spot do
            mush_spot[i].time = 0.0

            local obj = State:game_add_component(Item:new(State, world,
                {
                    x = mush_spot[i].x,
                    bottom = mush_spot[i].bottom,
                    allowed_gravity = true,
                    item_type = mush_spot[i].type,
                }
            ))

            mush_spot[i].obj = obj
        end


        cauldron = State:game_add_component(Cauldron:new(State, world, { x = 16 * 16, bottom = ground.y }))

        display_hp = DisplayHP:new(State)
        display_spell = DisplaySpell:new(State, world)
        display_bag = DisplayBag:new(State)
    end,
    --
    --
    finish = function()
        Player:finish()
        Bat:finish()
        Cauldron:finish()
        Item:finish()
        Heart:finish()
        DisplayHP:finish()
        DisplaySpell:finish()
        DisplayBag:finish()
    end,
    --
    --
    keypressed = function(key)
        -- if key == 'o' then
        --     State.camera:toggle_grid()
        --     State.camera:toggle_world_bounds()
        --     -- State.camera:toggle_debug()
        -- end

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
            spawn_heart(dt)

            State.camera:follow(player.x + player.w * 0.5, player.y + player.h * 0.5)
        else
            if player.time_state >= 5.0 and not State.transition then
                Leader:jgdr_pnt(score)

                State:add_transition("door", "out", {}, nil, function()
                    State:change_gamestate(Leader, { skip_finish = true, transition = "door" })

                    Leader:set_cur_player_rank(10)
                end)
            end
        end

        display_hp:update(dt)
        display_spell:update(dt)
        display_bag:update(dt)
    end,

    layers = {
        --
        --================== SKY ========================
        {
            cam_px = 0.0,
            cam_py = 0.0,
            --
            draw = function(self, camera)
                local vx, vy, vw, vh = State.camera:get_viewport()
                ---@type JM.Anima
                local anima = anim.night_sky
                anima:draw(vw * 0.5, vh * 0.5)
            end
        },
        --
        --================== STARS ========================
        {
            -- cam_px = -0.3,
            -- cam_py = 0.0,
            factor_x = -0.95,
            factor_y = -1,
            infinity_scroll_x = true,
            scroll_width = 320,
            infinity_scroll_y = true,
            scroll_height = 180,
            --
            draw = function(self, camera)
                local vx, vy, vw, vh = State.camera:get_viewport()
                ---@type JM.Anima
                local anima = anim.stars
                anima:draw(vw * 0.5, vh * 0.5)
            end
        },

        {
            factor_x = -0.95,
            factor_y = -0.95,
            infinity_scroll_x = true,
            scroll_width = 320,

            draw = function(self, camera)
                lgx.setColor(1, 1, 1)
                lgx.draw(imgs.mountain, 0, 0)
            end
        },
        --
        --================== TREES ========================
        {
            factor_x = -0.5,
            factor_y = -0.5,
            infinity_scroll_x = true,
            scroll_width = 32 * 6,
            -- cam_py = -32,
            ---@param camera JM.Camera.Camera
            draw = function(self, camera)
                -- love.graphics.setColor(0, 0, 1)
                -- love.graphics.rectangle("fill", -16, camera.bounds_bottom - 16 * 7, 32, 16 * 7)

                lgx.setColor(1, 1, 1)
                lgx.draw(imgs.trees, 0, 0)
            end
        },
        --
        --================== MAIN LAYER ========================
        {
            draw = function(self, camera)
                ground_tilemap:draw(camera)

                tab_sort(components, sort_draw)
                for i = 1, #components do
                    ---@type GameComponent
                    local gc = components[i]
                    local r = gc.draw and gc:draw()
                end

                -- for i = 1, #world.bodies_static do
                --     ---@type JM.Physics.Body
                --     local bd = world.bodies_static[i]
                --     bd:draw()
                -- end
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
                -- font:print(tostring(#components) .. "-" .. tostring(world.bodies_number), 16, 64)

                if player:is_dead() and player.time_state >= 1.0 then
                    font:push()
                    font:set_font_size(22)
                    font:printx("<effect=scream> <color, 0.9, 0.9, 0.9>YOU ARE \n DEAD", 0, 16 * 3, camera.viewport_w,
                        "center")
                    font:pop()
                end

                font:printf("<color, 0.9, 0.9, 0.9>SCORE\n" .. tostring(score), 0, 8, "center", camera.viewport_w)

                -- if player:bag_is_full() then
                --     font:printx("<effect=flickering, speed=0.8> <color, 0.9, 0.9, 0.9>Bag is full!",
                --         camera.viewport_w * 0.5, 8,
                --         camera.viewport_w * 0.5, "center")
                -- else
                --     font:printf("BAG:\n " .. player.bag_count, camera.viewport_w * 0.5, 8, "center",
                --         camera.viewport_w * 0.5)
                -- end

                -- font:printf("HP: " .. player.hp, 8, 8, "left", camera.viewport_w * 0.5)

                display_hp:draw()
                display_spell:draw()
                display_bag:draw()
            end
        }
    }
}

return State
