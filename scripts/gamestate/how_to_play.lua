local Pack = _G.JM_Love2D_Package
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT, nil, {
    subpixel = _G.SUB_PIXEL or 3,
    tile = 16,
    canvas_filter = 'linear',
})

State:set_color(185 / 255, 191 / 255, 251 / 255, 1)
--============================================================================
local Game = require "scripts.gamestate.game"
--============================================================================

State:implements {
    load = function()

    end,

    init = function()

    end,

    keypressed = function(key)
        if key == 'o' then
            State.camera:toggle_grid()
            -- State.camera:toggle_debug
        end

        if key == "space" or key == 'return' then
            if not State.transition then
                State:add_transition("door", "out", {}, nil, function()
                    State:change_gamestate(Game, {
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
                font:set_font_size(5)
                font:set_line_space(4)
                local red = string.format("<color,%.2f,%.2f,%.2f>", 180 / 255, 32 / 255, 42 / 255)

                local str = string.format(
                    "\t<bold>Objective:</bold>\n Fly around, catch items and thown them on cauldron. If you see some bats, just\nlaunch a spell on them.\n \n \t<bold>Controls:</bold>\n Move:\tA/D/Left/Right\n Launch Spell:\tF/J/E\n Drop item:\tV/K/Q\n Hover:\tSpace/Up/W\n \n \t<bold> Hint:</bold>\n Try make the dropped item %s bounce in the ground</color> before enter the cauldron. You will\nearn much more points!",
                    red)
                font:printf(str, 24, 24, "left", 320 - 16)

                font:set_font_size(6)
                font:printx("<effect=ghost, speed=1.5, min=0.1>Press Enter/Space to start!", 0, 180 - 24, 320, "center")
                font:pop()
            end
        }
    }
}

return State
