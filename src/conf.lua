function love.conf(t)
    t.window.title = "Linncontrol"
    -- t.version = "11.4"
    -- t.window.icon = "res/icon.ico"

    t.gammacorrect = true

    t.window.resizable = true
    t.window.width = 1280
    t.window.height = 720
    t.window.minwidth = 200 --720
    t.window.minheight = 200 --540
    t.window.vsync = 1

    t.modules.audio = false
    t.modules.sound = false
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.system = false
    t.modules.video = false
    t.modules.touch = false
end
