--require("lib/errorhandler")
require("lib/run")

local midilib = require("midilib")
-- local gameoflife = require("gameoflife")
local edomap = require("edomap")
local mpemap = require("mpemap")

io.stdout:setvbuf("no")

local width, height = love.graphics.getDimensions()

function love.load()
	math.randomseed(os.time())
	love.math.setRandomSeed(os.time())

	midilib.load()

	-- mothra / slendric
	-- mpemap.load(6, 1, 31)
	-- mpemap.load(6, 7, 31)
	-- mpemap.load(8, 1, 41)
	-- mpemap.load(9, 1, 46)
	-- mpemap.load(8, 9, 41)

	-- mpemap.load(5, 23, 56)

	-- miracle
	-- mpemap.load(3, 13, 31)
	-- mpemap.load(4, 17, 41)
	-- mpemap.load(4, 5, 41)
	-- mpemap.load(4, 3, 41)

	-- pajara
	-- mpemap.load(1, 5, 12)
	-- mpemap.load(2, 9, 22)
	-- mpemap.load(3, 14, 34)
	-- mpemap.load(4, 19, 46)

	-- meantone
	-- mpemap.load(3, 8, 19)
	-- mpemap.load(5, 13, 31)
	-- mpemap.load(5, 3, 31)
	-- mpemap.load(4, 11, 26)

	-- orwell
	-- mpemap.load(3, 7, 31)

	-- didacus?
	-- mpemap.load(5, 1, 31)

	-- half meantone
	-- mpemap.load(3, 16, 38)

	-- magic
	-- mpemap.load(1, 6, 19)
	-- mpemap.load(1, 7, 22)
	-- mpemap.load(2, 13, 41)

	-- kleismic
	-- mpemap.load(9, 11, 34)
	-- mpemap.load(14, 17, 53)

	--superpyth / schismatic
	-- mpemap.load(3, 7, 17)
	-- mpemap.load(7, 17, 41)
	-- mpemap.load(9, 22, 53)

	-- porcupine
	-- mpemap.load(2, 9, 15)
	-- mpemap.load(3, 13, 22)

	-- tetracot
	-- mpemap.load(5, 14, 34)
	-- mpemap.load(6, 17, 41)
	-- mpemap.load(5, 4, 34)
	-- mpemap.load(6, 5, 41)

	-- leapday (bosanquet)
	-- mpemap.load(8, 3, 46)
	-- schismatic (bosanquet)
	-- mpemap.load(7, 3, 41)
	-- sensi
	-- mpemap.load(5, -2, 46)

	-- schismatic
	mpemap.load(9, 4, 53)

	-- gameoflife.load()
end

function love.update(dt)
	midilib.update(mpemap.eventHandler)

	-- midilib.update(gameoflife.eventHandler)
	-- gameoflife.update()
end

function love.draw()
	--TODO: add some ui
end

function love.mousepressed(x, y, button) end

function love.mousereleased(x, y, button) end

function love.keypressed(key, isrepeat)
	if key == "escape" then
		love.event.quit()
	end
end

function love.quit()
	midilib.quit()
end
