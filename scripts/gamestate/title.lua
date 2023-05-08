local Pack = _G.JM_Love2D_Package
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT, nil, {
    subpixel = _G.SUB_PIXEL or 3,
    tile = 16,
    canvas_filter = 'linear',
})

State:set_color(74 / 255, 84 / 255, 98 / 255, 1)
--============================================================================
local HowToPlay = require "scripts.gamestate.how_to_play"
local Bests = require "scripts.gamestate.bests"

local lgx = love.graphics

--============================================================================

local imgs

State:implements {
    load = function()
        imgs = imgs or {
            title = love.graphics.newImage("data/img/title.png"),
            sky = love.graphics.newImage("data/img/night-sky.png"),
            logo = love.graphics.newImage("data/img/logo-game.png"),
        }

        imgs.logo:setFilter("nearest", "nearest")
    end,

    init = function()

    end,

    finish = function()
        imgs = nil
    end,

    keypressed = function(key)
        if key == 'o' then
            State.camera:toggle_grid()
            -- State.camera:toggle_debug
        end

        if key == "space" or key == 'return' then
            if not State.transition then
                _G.PLAY_SFX("click")

                State:add_transition("fade", "out", {}, nil, function()
                    State:change_gamestate(HowToPlay, {
                        skip_finish = true,
                        skip_transition = true,
                        transition = "fade",
                        transition_conf = {
                            delay = 0.6,
                            duration = 0.15,
                            axis = "y",
                            -- type=""
                        }
                    })
                end)
            end
        end

        if key == "l" then
            if not State.transition then
                Bests:jgdr_pnt(-100)

                _G.PLAY_SFX("click")

                State:add_transition("door", "out", {}, nil, function()
                    State:change_gamestate(Bests, {
                        skip_finish = true,
                        transition = "door",
                        transition_conf = {
                            delay = 0.3,
                        }
                    })
                end)
            end
        end
    end,

    update = function(dt)

    end,

    layers = {
        {
            ---@param camera JM.Camera.Camera
            draw = function(self, camera)
                local font = _G.JM_Font.current
                font:push()

                local U = JM_Utils
                local blue = U:get_rgba2(227, 230, 255)

                lgx.setColor(1, 1, 1)
                lgx.draw(imgs.sky, 0, 0)

                lgx.setColor(1, 1, 1)
                lgx.draw(imgs.logo, camera.viewport_w * 0.5 - imgs.logo:getWidth() * 0.5, 8)

                -- lgx.setColor(blue)
                -- lgx.draw(imgs.title, 0, 0)

                font:printx("<effect=flickering, speed=0.6> <color, 0.9, 0.9, 0.9>Press Enter to Play", 0, 180 - 16 * 3,
                    320,
                    "center")

                font:set_font_size(4)
                font:printf("Press <bold>L</bold> to view leaderboard", 0, 180 - 16, "right", 320 - 16)
                font:printf("Made by João Moreira.", 8, 180 - 16, SCREEN_WIDTH, "left")

                font:pop()
            end
        }
    }
}

return State
