local midilib = require("midilib")
local colors = require("colors")

local M = {}

-- steps to highlight
local scale_ratios = { 9 / 8, 5 / 4, 4 / 3, 3 / 2, 5 / 3, 15 / 8 }
-- local scale_ratios = { 9 / 8, 5 / 4, 4 / 3, 3 / 2, 5 / 3, 15 / 8, 7 / 4, 7 / 6, 11 / 8, 11 / 6 }
-- local scale_ratios = { 9 / 8, 5 / 4, 4 / 3, 3 / 2, 5 / 3, 15 / 8, 7 / 4, 11 / 8 }
-- local scale_ratios = { 9 / 8, 7 / 6, 4 / 3, 3 / 2, 14 / 9, 7 / 4 }
-- local scale_ratios = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }

-- center
local cx = 11 -- 11
local cy = 4 -- 4

-- C5
local midi_center = 60

local gx, gy, edo = 1, 5, 12

local C_PLAY = colors.RED
local C_HIGHLIGHT = colors.WHITE
local C_SCALE = colors.BLUE

-- 4095 / 24
local X_PER_ROW = 170.625

local PB_RANGE = 48

local touches = {}

local function log2(x)
	return math.log(x) / math.log(2)
end

local function getNote(x, y)
	return gx * (x - cx) + gy * (y - cy)
end

local function findTouch(x, y)
	for i = 1, 15 do
		if touches[i] and touches[i].x == x and touches[i].y == y then
			return touches[i]
		end
	end
end

local function newTouch(x, y)
	local note = getNote(x, y)

	local ch = 0
	for i = 1, 15 do
		if not touches[i] then
			ch = i
			break
		end
	end
	local touch = { channel = ch, note = note, x = x, y = y }
	touches[ch] = touch

	return touch
end

function M.load(gx_, gy_, edo_)
	gx = gx_
	gy = gy_
	edo = edo_

	-- l = lcm(math.abs(gx), math.abs(gy))

	-- print("=====")
	-- print(l / gx, -l / gy)

	M.scale = {}
	for i = 0, edo do
		M.scale[i] = false
	end

	for i, v in ipairs(scale_ratios) do
		local nt = math.floor(edo * log2(v) + 0.5) % edo
		M.scale[nt] = true
	end

	-- for i = 0, edo do
	-- 	print(M.scale[i])
	-- end

	M.note = {}
	M.layout = {}
	for i = 1, 25 do
		M.layout[i] = {}
		M.note[i] = {}
		for j = 0, 7 do
			local nn = getNote(i, j)

			M.note[i][j] = nn

			M.layout[i][j] = 0

			if nn % edo == 0 then
				M.layout[i][j] = C_HIGHLIGHT
			elseif M.scale[nn % edo] then
				M.layout[i][j] = C_SCALE
			end
			midilib.setLight(i, j, M.layout[i][j])
		end
	end

	-- midilib.setLight(cx, cy, C_HIGHLIGHT)
end

function M.eventHandler(event)
	if event.name == "note on" then
		local x = event.note
		local y = event.channel

		-- print("on", x, y)

		local note = getNote(x, y)

		if x > 0 then
			for i = 1, 25 do
				for j = 0, 7 do
					local ni = getNote(i, j)
					if note == ni then
						midilib.setLight(i, j, C_PLAY)
					end
				end
			end
		end

		local touch = newTouch(x, y)

		midilib.sendLoop({
			name = "note on",
			channel = touch.channel,
			vel = event.vel,
			note = note + midi_center,
		})
	elseif event.name == "note off" then
		local x = event.note
		local y = event.channel

		local note = getNote(x, y)

		-- print("off", x, y, event.vel)

		if x > 0 then
			for i = 1, 25 do
				for j = 0, 7 do
					local ni = getNote(i, j)
					if note == ni then
						midilib.setLight(i, j, M.layout[i][j])
					end
				end
			end
		end
		local touch = findTouch(x, y)

		if touch then
			midilib.sendLoop({
				name = "note off",
				channel = touch.channel,
				vel = event.vel,
				note = note + midi_center,
			})

			touches[touch.channel] = nil
		end
	elseif event.name == "aftertouch" then
		-- pressure
		local x = event.note
		local y = event.channel
		local p = event.vel

		local note = getNote(x, y)

		local touch = findTouch(x, y)
		if touch then
			midilib.sendLoop({ name = "pressure", channel = touch.channel, vel = event.vel })
		end
	elseif event.name == "cc" then
		if event.cc >= 1 and event.cc <= 25 then
			-- X data MSB
			local x = event.cc
			local y = event.channel
			local note = getNote(x, y)

			local touch = findTouch(x, y)

			if touch then
				local x_row = (touch.x_lsb + event.value * 128) / X_PER_ROW

				-- relative to 12edo
				-- local bend = (x_row - x + 0.5) * gx * edo / (12 * PB_RANGE)
				-- relative to current horizontal step
				-- local bend = (x_row - x + 0.5) * gx / PB_RANGE
				-- 100 cents
				-- local bend = (x_row - x + 0.5) * edo / (12 * PB_RANGE)
				-- 50 cents
				local bend = (x_row - x + 0.5) * 0.5 * edo / (12 * PB_RANGE)
				midilib.sendLoop({ name = "pitchbend", channel = touch.channel, value = bend })
			end
		end
		if event.cc >= 33 and event.cc <= 57 then
			-- X data LSB
			local x = event.cc - 32
			local y = event.channel
			local note = getNote(x, y)
			local touch = findTouch(x, y)
			if touch then
				touch.x_lsb = event.value
			end
		end
		if event.cc == 119 then
			print("transition", event.channel, event.value)
		end
		if event.cc == 64 and event.channel == 1 then
			-- sustain pedal
			midilib.sendLoop({ name = "cc", channel = 0, cc = event.cc, value = event.value })
		end
	else
		-- print(event.name)
	end
end

return M
