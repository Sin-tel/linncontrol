local midilib = require("midilib")

local M = {}

local state = {}
local newstate = {}

local counter = 0

local w = 25
local h = 8

function M.load()
	for i = 1, w do
		state[i] = {}
		newstate[i] = {}
		for j = 1, h do
			state[i][j] = math.random() > 0.9 and 1 or 0
			newstate[i][j] = 0
			midilib.setLight(i, j - 1, state[i][j] == 1 and C_WHITE or C_OFF)
		end
	end
end

function M.update()
	counter = counter + 1
	if counter > 10 then
		counter = 0
		for i = 1, w do
			for j = 1, h do
				local s = 0
				for p = i - 1, i + 1 do
					for q = j - 1, j + 1 do
						-- if p > 0 and p <= w and q > 0 and q <= h then
						p = (p - 1) % w + 1
						q = (q - 1) % h + 1
						s = s + state[p][q]
						-- end
					end
				end
				s = s - state[i][j]
				if s == 3 or (s + state[i][j]) == 3 then
					newstate[i][j] = 1
				else
					newstate[i][j] = 0
				end
				if newstate[i][j] ~= state[i][j] then
					midilib.setLight(i, j - 1, newstate[i][j] == 1 and C_WHITE or C_OFF)
				end
			end
		end
		state, newstate = newstate, state
	end
end

function M.eventHandler(event)
	if event.name == "note on" then
		local x = event.note
		local y = event.channel

		state[x][y + 1] = 1
		midilib.setLight(x, y, C_WHITE)
	end
end

return M
