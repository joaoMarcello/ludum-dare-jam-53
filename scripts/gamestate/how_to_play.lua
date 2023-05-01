local Pack = _G.JM_Love2D_Package
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT, nil, {
    subpixel = _G.SUB_PIXEL or 3,
    tile = 16,
    canvas_filter = 'linear',
})

State:set_color(121 / 255, 58 / 255, 128 / 255, 1)
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

                local red = string.format("<color,%.2f,%.2f,%.2f>",
                    180 / 255, 32 / 255, 42 / 255)
                local black = string.format("<color,%.2f,%.2f,%.2f>",
                    59 / 255, 23 / 255, 37 / 255)

                love.graphics.setColor(JM_Utils:get_rgba2(188, 74, 155))
                love.graphics.rectangle("fill", 8, 4, 320 - 16, 180 - 8)

                font:push()
                font:set_font_size(5)
                font:set_line_space(4)
                -- font:set_color(JM_Utils:get_rgba2(254, 243, 192))
                font:set_color(JM_Utils:get_rgba2(59, 23, 37))


                local str = string.format(
                    "\t %s <bold>Objective:</bold></color>\n Fly around, catch items and throw them on cauldron. If you see some bats, just\nlaunch a spell on them.\n \n \t %s <bold>Controls:</color></bold>\n Move:</color>\tA/D/Left/Right\n Launch Spell:</color>\tF/J/E\n Drop item:</color>\tV/K/Q\n Hover:</color>\tSpace/Up/W\n Restart:</color>\tP\n \n \t %s <bold> Hint:</bold></color>\n Try make the dropped item %s bounce in the ground</color> before enter the cauldron. You will\nearn much more points!",
                    black, black, black, red)
                font:printf(str, 24, 16, "left", 320 - 16)

                font:set_font_size(6)
                str = string.format(" %s <effect=ghost, speed=1.5, min=0.1>Press Enter/Space to start!",
                    "<color, 0.9, 0.9, 0.9>")
                font:printx(str, 0, 180 - 24, 320, "center")
                font:pop()
            end
        }
    }
}

return State
