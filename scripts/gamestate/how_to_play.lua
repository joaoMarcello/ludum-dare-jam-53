local Pack = _G.JM_Love2D_Package
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT, nil, {
    subpixel = _G.SUB_PIXEL or 3,
    tile = 16,
    canvas_filter = 'linear',
})

State:set_color(74 / 255, 84 / 255, 98 / 255, 1)
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

                font:print("Testando", 100, 100)
            end
        }
    }
}

return State
