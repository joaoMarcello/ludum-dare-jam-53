local Pack = _G.JM_Love2D_Package
local Scene = Pack.Scene
local Utils = Pack.Utils
local Board = Pack.Mlrs
local Loader = Pack.Ldr
local Label = Pack.GUI.Label
local Component = Pack.GUI.Component
local Affectable = Pack.Affectable

---@class LeaderBoard : JM.Scene
local State = Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT, nil,
    {
        subpixel = 2,
        canvas_filter = 'linear',

    }
)

-- local dm2 = love.filesystem.read("/data/dymmy2.txt")
-- Loader.save(dm2, "dummy1.dat")
Board:init(Loader.load("data/dummy1.dat"))

-- local http = require "socket.http"
-- http.request("http://dreamlo.com/lb/ENIIH2BoRkG30ewXF2HHKQXqsst4hqDk2nMtrwAI7pGA/add/Marco/50")

--[[
    marco, joana, bruno, sarah, peter
]]
--[[
    Dummy1 Content
{
    [1]="http://dreamlo.com/lb/644e7e728f40bb6dec7c1941/",
    [2]="http://dreamlo.com/lb/ENIIH2BoRkG30ewXF2HHKQXqsst4hqDk2nMtrwAI7pGA/"
}
]]
--=============================================================================
local lgx = love.graphics
local format = string.format

local font = _G.JM_Font.current

local tile = 16

font:push()
font:set_font_size(8)
Label:set_font(font)
font:pop()

---@type JM.Font.Phrase
local fr_leader
local fr_leader_w, fr_leader_h
local fr_leader_py = 4

---@type JM.GUI.Label
local label

---@type number|any
local player_score = 4650
---@type number|any
local player_sec
---@type string|any
local player_text

local img_btn_refresh
---@type JM.Anima
local anima_btn_refresh

---@type JM.GUI.Component
local btn_refresh
---@type JM.GUI.Component
local btn_send

---@type JM.Template.Affectable
local aff_player

local MAX = 5
local WEB = false

local rank_data, rank_time, rank_cur_player
local rank_speed = 0.4 / MAX

local code = [[
local http = require "socket.http"
local r = http.request(...)
love.thread.getChannel('resp'):push(r)
]]

---@type love.Thread | any
local thread
thread = not WEB and love.thread.newThread(code)
--=============================================================================
local refresh = function()
    if WEB then
        State:init()
    else
        rank_data = nil
        if thread and not thread:isRunning() then
            thread:start(Board:str_rec())
        end
    end
end

local find_player = function(player_name)
    if not rank_data then return false end

    local N = #rank_data
    local name, score, sec, text, date, success
    for i = 1, N do
        name, score, sec, text = Board:get_proper(rank_data[i])
        if name and name == player_name then
            return name, score, sec, text, date
        end
    end
    return false
end

local ready_to_send = function(player_name)
    local name, score, sec, text, date = find_player(player_name)

    if name then
        return player_score > score
        --
    else
        name, score, sec, text, date = Board:get_proper(rank_data and rank_data[MAX])

        if name then
            return player_score > score
        end
    end

    return false
end

local send = function()
    local player_name = label.text
    if player_name == "" then return false end

    local to_send = ready_to_send(player_name)

    if to_send then
        label.locked = true
    end

    if WEB then
        if to_send then
            local data = Board:env(player_name, player_score, player_sec, player_text)

            if data then
                rank_data = Board:get_tab(data)
            end
        end
        --
    else
        if to_send then
            rank_data = nil

            if thread and not thread:isRunning() then
                thread:start(Board:str_env(player_name, player_score, player_sec, player_text))
            end
        end
    end
end

local enabled = function()
    return rank_data and rank_cur_player >= MAX
end

local player_is_on_ranking = function()
    if rank_data then
        local name, score, sec, text, date = Board:get_proper(rank_data[MAX])

        if name then
            return player_score > score
        end
    end
end

---@param self JM.GUI.Component
local bt_refresh_draw = function(self)
    if self.on_focus then
        lgx.setColor(1, 0, 0)
    else
        lgx.setColor(0, 0, 1)
    end
    lgx.rectangle("fill", self.x, self.y, self.w, self.h)

    if anima_btn_refresh then
        anima_btn_refresh:draw(self.x + self.w * 0.5, self.y + self.h * 0.5)
    end
end

---@param self JM.GUI.Component
local bt_send_draw = function(self)
    if self.on_focus then
        lgx.setColor(1, 0, 0)
    else
        lgx.setColor(0, 0, 1)
    end
    lgx.rectangle("fill", self.x, self.y, self.w, self.h)

    font:printf("Send", self.x, self.y + self.h * 0.5 - font.__font_size * 0.5, "center", self.w)
end

function State:jgdr_pnt(value)
    player_score = math.abs(value)
end

--=============================================================================

State:implements {

    load = function(args)
        local cam = State.camera

        fr_leader, fr_leader_w, fr_leader_h = font:generate_phrase("<effect=wave>LEADERBOARD", nil, nil,
            State.camera.viewport_w,
            "center")
        fr_leader_h = font.__font_size

        label = Label:new {
            x = tile,
            y = cam.viewport_h - tile * 1.5,
            w = tile * 6,
            use_filter = true,
            align = "center",
            max = 10,
            on_focus = true,
            border = Utils:get_rgba(0.9, 0.9, 0.9),
            color = Utils:get_rgba(1, 1, 1, 0.5),
        }

        local img_dir = "data/img/refresh_02.png"
        img_btn_refresh = img_btn_refresh or (love.filesystem.getInfo(img_dir)
            and lgx.newImage(img_dir))

        if img_btn_refresh then
            anima_btn_refresh = Pack.Anima:new { img = img_btn_refresh }
            anima_btn_refresh:set_size(25)
        end

        ---@type JM.GUI.Component
        btn_refresh = Component:new {
            x = 0,
            y = 0,
            w = tile,
            h = tile,
            on_focus = nil,
        }
        btn_refresh.__custom_draw__ = bt_refresh_draw
        btn_refresh:on_event("mouse_pressed", refresh)

        ---@type JM.GUI.Component
        btn_send = Component:new {
            x = 0, y = 0,
            w = tile * 2.5,
            h = tile,
            on_focus = true
        }
        btn_send.__custom_draw__ = bt_send_draw
        btn_send:on_event("mouse_pressed", send)

        if args and type(args) == "table" then
            player_score = args.pnts
            player_sec = args.sgnd
            player_text = args.text
        end

        ---@type JM.Template.Affectable
        aff_player = Affectable:new()
        aff_player:apply_effect("flickering")
    end,

    init = function(data)
        rank_data = data or Board:get_tab()
        rank_time = 0.0
        rank_cur_player = 1
    end,

    finish = function()
        player_score = nil
        player_sec = nil
        player_text = nil
    end,

    keypressed = function(key)
        if key == ';' then
            State.camera:toggle_debug()
        end

        if key == "up" then
            player_score = player_score + 10
            --
        elseif key == "down" then
            player_score = player_score - 10
        end

        -- if key == 'r' then
        --     refresh()
        -- end

        if enabled() then
            label:key_pressed(key)
        end
    end,

    textinput = function(t)
        if enabled() then
            label:textinput(t)
        end
    end,

    mousepressed = function(x, y, b, istouch, presses)
        btn_refresh:mouse_pressed(x, y, b, istouch, presses)
        if not enabled() or not player_is_on_ranking() then return end

        label:mouse_pressed(x, y, b, istouch, presses)
        btn_send:mouse_pressed(x, y, b, istouch, presses)
    end,

    mousereleased = function(x, y, b, istouch, presses)
        label:mouse_released(x, y, b, istouch, presses)
        btn_refresh:mouse_released(x, y, b, istouch, presses)
        btn_send:mouse_released(x, y, b, istouch, presses)
    end,

    update = function(dt)
        rank_time = rank_time + dt
        if rank_time >= rank_speed then
            rank_time = rank_time - rank_speed
            if rank_time >= rank_speed then rank_time = 0.0 end

            rank_cur_player = Utils:clamp(rank_cur_player + 1, 0, MAX)
        end

        if not rank_data then
            local r = love.thread.getChannel('resp'):pop()
            if r then
                rank_data = Board:get_tab(r)
                State:init(rank_data)
            end
        end

        do
            local mx, my = State:get_mouse_position()
            label:update(dt)

            local col = btn_refresh:check_collision(mx, my, 0, 0)

            if col then
                if not btn_refresh.on_focus then btn_refresh:set_focus(true) end
                --
            elseif btn_refresh.on_focus then
                btn_refresh:set_focus(false)
                --
            end

            col = btn_send:check_collision(mx, my, 0, 0)
            if col then
                if not btn_send.on_focus then
                    btn_send:set_focus(true)
                end
            elseif btn_send.on_focus then
                btn_send:set_focus(false)
            end

            btn_send:update(dt)
            btn_refresh:update(dt)
            aff_player:update(dt)
        end
    end,

    layers = {
        {
            infinity_scroll_x = true,
            infinity_scroll_y = true,
            scroll_width = tile * 4 * 2,
            scroll_height = tile * 4 * 2,
            factor_x = -0.6,
            factor_y = -0.6,
            cam_py = 0,
            cam_px = 0,
            --
            update = function(self, dt)
                self.cam_py = self.cam_py - tile * 2.5 * dt
                self.cam_px = self.cam_px - tile * 2 * dt
            end,
            --
            draw = function(self, camera)
                local s = tile * 4

                lgx.setColor(Utils:get_rgba2(120, 100, 198))
                lgx.rectangle("fill", 0, 0, s, s)
                lgx.rectangle("fill", s, s, s, s)

                lgx.setColor(Utils:get_rgba2(156, 139, 219))
                lgx.rectangle("fill", s, 0, s, s)
                lgx.rectangle("fill", 0, s, s, s)
            end
        },
        --
        --
        {
            ---@param camera JM.Camera.Camera
            draw = function(self, camera)
                --
                fr_leader:draw(0, fr_leader_py, "center")

                lgx.setColor(1, 0, 0)
                lgx.rectangle("fill",
                    (camera.viewport_w * .5) - (fr_leader_w * .5) - 32,
                    fr_leader_py + (fr_leader_h * 0.5) - (32 * 0.5),
                    32, 32)

                lgx.rectangle("fill",
                    (camera.viewport_w * 0.5) + (fr_leader_w * 0.5),
                    fr_leader_py + (fr_leader_h * 0.5) - (32 * 0.5),
                    32, 32)

                if rank_data then
                    font:push()
                    font:set_font_size(10)

                    local py = fr_leader_py + fr_leader_h + tile / 2
                    local px = tile

                    local N = #rank_data
                    N = Utils:clamp(N, 0, MAX)
                    local center = false

                    local offset = tile / 2
                    local line_space = font.__font_size + 14
                    local rect_height = font.__font_size + 8
                    local total_width = tile * 2 + offset
                        + tile * 5 + offset
                        + tile * 4
                    local total_height = (line_space) * N - 14
                    if center then
                        py = camera.viewport_h * 0.5 - total_height * 0.5
                    end

                    local px_init = camera.viewport_w * 0.5 - total_width * 0.5
                    local py_init = py
                    local frst_rect_color = Utils:get_rgba2(115, 239, 232)
                    local frst_font_color = Utils:get_rgba2(63, 105, 130)
                    local def_font_color = Utils:get_rgba(0.9, 0.9, 0.9)
                    local def_rect_color = Utils:get_rgba2(70, 71, 98)
                    local shadow_color = Utils:get_rgba(0, 0, 0, 0.25)


                    for i = 1, N do
                        if i > rank_cur_player then break end

                        px = px_init
                        local name, score, sec, text, date = Board:get_proper(rank_data[i])

                        local rank
                        local font_color = def_font_color
                        local rect_color = def_rect_color

                        if i == 1 then
                            rank = "1ST"
                            font_color = frst_font_color
                            rect_color = frst_rect_color
                            --
                        elseif i == 2 then
                            rank = "2ND"
                        elseif i == 3 then
                            rank = "3RD"
                        else
                            rank = format("%dTH", i)
                        end

                        font:set_color(font_color)

                        lgx.setColor(shadow_color)
                        lgx.rectangle("fill", px, py + 1, tile * 2, rect_height)
                        lgx.setColor(rect_color)
                        lgx.rectangle("fill", px, py - 2, tile * 2, rect_height)
                        lgx.setColor(1, 1, 1)
                        lgx.rectangle("line", px, py - 2, tile * 2, rect_height)
                        font:printf(rank, px, py, "center", tile * 2)
                        px = px + tile * 2 + offset

                        lgx.setColor(shadow_color)
                        lgx.rectangle("fill", px, py + 1, tile * 5, rect_height)
                        lgx.setColor(rect_color)
                        lgx.rectangle("fill", px, py - 2, tile * 5, rect_height)
                        lgx.setColor(1, 1, 1)
                        lgx.rectangle("line", px, py - 2, tile * 5, rect_height)
                        font:printf(name, px, py, "center", tile * 5)
                        px = px + tile * 5 + offset

                        lgx.setColor(shadow_color)
                        lgx.rectangle("fill", px, py + 1, tile * 4, rect_height)
                        lgx.setColor(rect_color)
                        lgx.rectangle("fill", px, py - 2, tile * 4, rect_height)
                        lgx.setColor(1, 1, 1)
                        lgx.rectangle("line", px, py - 2, tile * 4, rect_height)
                        font:printf(tostring(score), px, py, "center", tile * 4)

                        py = py + line_space
                    end -- End For


                    if enabled() then
                        if player_is_on_ranking() then
                            font:set_color(def_rect_color)
                            font:print("Enter your name:", label.x - tile / 2, label.y - font.__font_size - 4, math.huge)
                            label:draw()

                            btn_send:set_position(label.right + 16, label.y + label.h * 0.5 - btn_send.h * 0.5)
                            btn_send:draw()
                        end

                        btn_refresh:set_position(px_init + total_width + 8,
                            py_init + total_height - btn_refresh.h + 4)
                        btn_refresh:draw()
                    end

                    font:pop()

                    --
                else -- no rank_data
                    --
                    if thread and thread:isRunning() then
                        font:printf("Wait...", 0, camera.viewport_h * 0.5 - font.__font_size * 0.5, "center",
                            camera.viewport_w)
                    else
                        font:printf("Can't load the ranking.\n \n Check your connection\n and try again.",
                            0,
                            camera.viewport_h * 0.5 - font.__font_size * 4, "center", camera.viewport_w)

                        btn_refresh:set_position(camera.viewport_w * 0.5 - btn_refresh.w * 0.5,
                            camera.viewport_h * 0.5 + font.__font_size * 3 + 16)
                        btn_refresh:draw()
                    end
                end
            end
        },
        --
        --
        -- {
        --     ---@param camera JM.Camera.Camera
        --     draw = function(self, camera)
        --         -- if enabled() then
        --         --     label:draw()
        --         --     btn_refresh:draw()
        --         -- end
        --     end
        -- }
    }
}

return State