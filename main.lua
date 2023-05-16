local love = _G.love
local lgx = love.graphics
local Pack = require "jm-love2d-package.init"
local SceneManager = Pack.SceneManager
do
    local Word = require "jm-love2d-package.modules.font.Word"
    Word.eff_wave_range = 1
    Word.eff_scream_range_y = 1.5
    Word.eff_scream_range_x = 0.8
end



math.randomseed(os.time())
lgx.setBackgroundColor(0, 0, 0, 1)
lgx.setDefaultFilter("nearest", "nearest")
lgx.setLineStyle("rough")
love.mouse.setVisible(false)

local font = Pack.FontGenerator:new_by_ttf {
    path = "data/font/PressStart2P-Regular.ttf",
    dpi = 24,
    name = "press start",
    font_size = 8,
    tab_size = 4,
    character_space = 0,
    min_filter = "linear",
    max_filter = "nearest"
}
JM_Font.current = font
JM_Font.current:set_font_size(8)
JM_Font.current:set_line_space(2)

_G.DisplayText = require "scripts.display_text"
DisplayText:load()

-- JM_Font.current.__imgs[0]:setFilter("nearest", "nearest")
-- love.mouse.setRelativeMode(true)

-- collectgarbage("setstepmul", 150)
-- collectgarbage("setpause", 250)

--==================================================================

SCREEN_WIDTH = Pack.Utils:round(320)  --576 *1.5
SCREEN_HEIGHT = Pack.Utils:round(180) -- 384 32*15
SUB_PIXEL = 3
CANVAS_FILTER = 'linear'

TARGET = "Web_"

local initial_state = 'game'

--==================================================================

function PLAY_SFX(name, force)
    Pack.Sound:play_sfx(name, force)
end

function PLAY_SONG(name)
    Pack.Sound:play_song(name)
end

--=========================================================================
function love.load()
    local S = Pack.Sound
    S:add_sfx("/data/sfx/spell.wav", "spell")
    S:add_sfx("/data/sfx/bullet.wav", "bullet")
    S:add_sfx("/data/sfx/drop.wav", "drop")
    S:add_sfx("/data/sfx/power_up.wav", "power_up")
    S:add_sfx("/data/sfx/collect.wav", "collect", 0.75)
    S:add_sfx("/data/sfx/fly.wav", "fly", 0.1)
    S:add_sfx("/data/sfx/enemy_die.wav", "enemy_die")
    S:add_sfx("/data/sfx/enemy_hit.wav", "enemy_hit")
    S:add_sfx("/data/sfx/spell_fail.wav", "spell_fail", 0.25)
    S:add_sfx("/data/sfx/click.wav", "click")

    -- S:add_song("/data/song/Whimsical-Popsicle.mp3", "game", 0.3)

    require "scripts.gamestate.game"

    SceneManager:change_gamestate(require("scripts.gamestate." .. initial_state))
end

function love.textinput(t)
    local scene = SceneManager.scene
    scene:textinput(t)
end

function love.keypressed(key)
    local scene = SceneManager.scene

    if key == "escape" and TARGET ~= "Web"
        or (TARGET == "Web" and key == ";")
    then
        scene:finish()
        scene = nil
        collectgarbage()
        love.event.quit()
        return
    end

    if scene then scene:keypressed(key) end
end

function love.keyreleased(key)
    local scene = SceneManager.scene
    if scene then scene:keyreleased(key) end
end

function love.mousepressed(x, y, button, istouch, presses)
    local scene = SceneManager.scene
    if scene then scene:mousepressed(x, y, button, istouch, presses) end
end

function love.mousereleased(x, y, button, istouch, presses)
    local scene = SceneManager.scene
    if scene then scene:mousereleased(x, y, button, istouch, presses) end
end

function love.mousemoved(x, y, dx, dy, istouch)
    local scene = SceneManager.scene
    if scene then scene:mousemoved(x, y, dx, dy, istouch) end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    local scene = SceneManager.scene
    if scene then scene:touchpressed(id, x, y, dx, dy, pressure) end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    local scene = SceneManager.scene
    if scene then scene:touchreleased(id, x, y, dx, dy, pressure) end
end

local km = 0
local collectgarbage = collectgarbage

local start = love.timer.getTime()
local timer_getTime = love.timer.getTime
local function collect()
    for i = 1, 100 do
        collectgarbage("step", 5)
        if timer_getTime() - start > 0.001 then
            return
        end
    end
end

-- local tm = 0.0
-- local fr = 5.0
function love.update(dt)
    km = collectgarbage("count") / 1024.0

    Pack:update(dt)
    SceneManager.scene:update(dt)

    -- tm = tm + dt
    -- if tm >= fr then
    --     tm = tm - fr
    --     if tm >= fr then tm = 0 end
    --     if not collectgarbage("isrunning") then
    --         collectgarbage("step")
    --     end
    -- end

    collect()
end

function love.draw()
    SceneManager.scene:draw()

    lgx.setColor(0, 0, 0, 0.7)
    lgx.rectangle("fill", 0, 0, 80, 120)
    lgx.setColor(1, 1, 0, 1)
    lgx.print(string.format("Memory:\n\t%.2f Mb", km), 5, 10)
    lgx.print("FPS: " .. tostring(love.timer.getFPS()), 5, 50)
    local maj, min, rev, code = love.getVersion()
    lgx.print(string.format("Version:\n\t%d.%d.%d", maj, min, rev), 5, 75)

    -- local stats = love.graphics.getStats()
    -- local font = _G.JM_Font
    -- -- font:print(stats.texturememory / (10 ^ 6), 100, 96)
    -- font:print(stats.drawcalls, 200, 96 + 32)
    -- font:print(stats.canvasswitches, 200, 96 + 32 + 22)
end
