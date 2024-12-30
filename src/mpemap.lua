local midilib = require("midilib")
local colors = require("colors")

local M = {}

-- steps to highlight
local scale_ratios = { 1 / 1, 9 / 8, 5 / 4, 4 / 3, 3 / 2, 5 / 3, 15 / 8 }
-- local scale_ratios = { 9 / 8, 5 / 4, 4 / 3, 3 / 2, 5 / 3, 15 / 8, 7 / 4, 7 / 6, 11 / 8, 11 / 6 }
-- local scale_ratios = { 9 / 8, 5 / 4, 4 / 3, 3 / 2, 5 / 3, 15 / 8, 7 / 4, 11 / 8 }
-- local scale_ratios = { 9 / 8, 7 / 6, 4 / 3, 3 / 2, 14 / 9, 7 / 4 }
-- local scale_ratios = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 }

-- local scale_ratios2 = { 7, 11, 13 }
-- local scale_ratios2 = { 7 / 4, 11 / 8 }
local scale_ratios2 = { 7 / 6, 7 / 4, 14 / 9 }
-- local scale_ratios2 = { 6 / 5 }

local scale_ratios2 = { 7 / 6, 7 / 4, 14 / 9 }

-- center
local cx = 7 -- 7 -- 11
local cy = 4 -- 4

local color_offset = 0

-- C5
local midi_center = 60

local gx, gy, edo = 1, 5, 12

local C_PLAY = colors.RED
local C_SCALE = { colors.WHITE, colors.BLUE, colors.ORANGE, colors.YELLOW }

-- 4095 / 24
local X_PER_ROW = 170.625

local PB_RANGE = 48 -- 48 / 24

local touches = {}

local function log2(x)
	return math.log(x) / math.log(2)
end

local function getNote(x, y)
	return gx * (x - cx) + gy * (y - cy)
end

local function to_midi(note)
	local pitch = (note * 12 / edo) + midi_center
	local midi_note = math.floor(pitch + 0.5)
	local offset = pitch - midi_note
	return midi_note, offset
end

local function findTouch(x, y)
	for i = 1, 15 do
		if touches[i] and touches[i].x == x and touches[i].y == y then
			return touches[i]
		end
	end
end

local last_touch = 1

local function newTouch(x, y)
	local note = getNote(x, y)

	local ch = last_touch + 1
	if ch >= 16 then
		ch = 1
	end
	if touches[ch] then
		for i = 1, 15 do
			if not touches[i] then
				ch = i
				break
			end
		end
	end

	-- TODO: if no channel available we should note-off a previous one

	last_touch = ch

	local touch = { channel = ch, note = note, x = x, y = y }
	touches[ch] = touch

	return touch
end

local function mapping(v)
	return math.floor(edo * log2(v) + 0.5) % edo
end

function M.load(gx_, gy_, edo_)
	gx = gx_
	gy = gy_
	edo = edo_

	M.scale = {}
	for i = 0, edo do
		M.scale[i] = 0
	end

	for i, v in ipairs(scale_ratios2) do
		local nt = mapping(v)
		M.scale[nt] = 3
	end

	-- for i, v in ipairs(scale_ratios) do
	-- 	local nt = (mapping(v) + 1) % edo
	-- 	M.scale[nt] = 3
	-- end

	-- M.scale[1] = 4

	for i, v in ipairs(scale_ratios) do
		local nt = mapping(v)
		M.scale[nt] = 2
	end

	M.scale[0] = 1

	M.note = {}
	M.layout = {}
	for i = 1, 25 do
		M.layout[i] = {}
		M.note[i] = {}
		for j = 0, 7 do
			local nn = getNote(i, j)

			M.note[i][j] = nn

			M.layout[i][j] = 0

			local c_scale = M.scale[(nn - color_offset) % edo]
			if c_scale > 0 then
				M.layout[i][j] = C_SCALE[c_scale]
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

		-- print(x, y)
		if x == 0 then
			if y == 7 then
				color_offset = color_offset + mapping(3 / 2)
				M.load(gx, gy, edo)
			end
			if y == 6 then
				color_offset = color_offset - mapping(3 / 2)
				M.load(gx, gy, edo)
			end
			if y == 5 then
				color_offset = color_offset + 1
				M.load(gx, gy, edo)
			end
			if y == 4 then
				color_offset = color_offset - 1
				M.load(gx, gy, edo)
			end

			return
		end

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

		local midi_note, offset = to_midi(note)
		local bend = offset / PB_RANGE

		local touch = newTouch(x, y)
		touch.base_bend = bend

		midilib.sendLoop({ name = "pitchbend", channel = touch.channel, value = bend })

		midilib.sendLoop({
			name = "note on",
			channel = touch.channel,
			vel = event.vel,
			note = midi_note,
		})
	elseif event.name == "note off" then
		local x = event.note
		local y = event.channel

		local note = getNote(x, y)
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

		local midi_note, offset = to_midi(note)

		if touch then
			midilib.sendLoop({
				name = "note off",
				channel = touch.channel,
				vel = event.vel,
				note = midi_note,
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
				-- local bend = (x_row - x + 0.5) * gx / PB_RANGE
				-- relative to current horizontal step
				-- local bend = (x_row - x + 0.5) * gx * 12 / (edo * PB_RANGE)
				-- 100 cents
				-- local bend = (x_row - x + 0.5) / PB_RANGE
				-- 50 cents
				local bend = (x_row - x + 0.5) * 0.5 / PB_RANGE
				-- local bend = 0

				-- quantize
				if not touch.bend then
					touch.bend = bend
				end
				bend = bend - touch.bend

				bend = bend + touch.base_bend
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
