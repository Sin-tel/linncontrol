local rtmidi = require("./lib/rtmidi_ffi")
local bit = require("bit")
local colors = require("colors")

local M = {}

function M.load()
	local handle_in = rtmidi.createIn()
	print("available midi input ports:")
	rtmidi.printPorts(handle_in)

	local handle_out = rtmidi.createOut()
	print("available midi output ports:")
	rtmidi.printPorts(handle_out)

	M.linn_in = M.openDevice("linnstrument", "in")
	M.linn_out = M.openDevice("linnstrument", "out")
	M.loop_out = M.openDevice("loopmidi", "out")

	M.setUserFirmware(true)

	-- enable X
	for i = 0, 7 do
		rtmidi.sendMessage(M.linn_out, rtmidi.newMessage({ 0xB0 + i, 10, 1 }))
	end
	-- enable slide
	for i = 0, 7 do
		rtmidi.sendMessage(M.linn_out, rtmidi.newMessage({ 0xB0 + i, 9, 1 }))
	end
	-- enable Z
	for i = 0, 7 do
		rtmidi.sendMessage(M.linn_out, rtmidi.newMessage({ 0xB0 + i, 12, 1 }))
	end
end

function M.sendLoop(event)
	local t = M.unparse(event)
	if t then
		-- print(bit.band(t[1], 15), t[2], t[3])
		rtmidi.sendMessage(M.loop_out, rtmidi.newMessage(t))
	end
end

function M.openDevice(name, device_type)
	local device_handle

	if device_type == "in" then
		device_handle = rtmidi.createIn()
	elseif device_type == "out" then
		device_handle = rtmidi.createOut()
	else
		print("Warning: specify in/out device type")
		return
	end

	local port_n

	if name == "default" then
		port_n = 0
	else
		port_n = rtmidi.findPort(device_handle, name)
	end

	if port_n then
		rtmidi.openPort(device_handle, port_n)

		if device_handle.ok then
			if device_type == "in" then
				rtmidi.ignoreTypes(device_handle, true, true, true)
			end

			return device_handle
		end
	end

	print("Warning: couldn't open port: " .. name)
end

function M.update(eventhandler)
	while true do
		local msg, s = rtmidi.getMessage(M.linn_in)
		if s == 0 then
			break
		end
		local event = M.parse(msg, s)

		eventhandler(event)
	end
end

function M.parse(msg, s)
	local status = bit.rshift(msg.data[0], 4)
	local channel = bit.band(msg.data[0], 15)

	local b = msg.data[1]
	local c = 0

	if s > 2 then
		c = msg.data[2]
	end

	local event = {}

	event.channel = channel

	if status == 9 and c > 0 then
		event.name = "note on"
		event.note = b
		event.vel = c
	elseif status == 8 or (status == 9 and c == 0) then -- note on with velocity 0 is treated as a note off
		event.name = "note off"
		event.note = b
		event.vel = c
	elseif status == 13 then
		event.name = "pressure"
		event.vel = b
	elseif status == 14 then
		event.name = "pitchbend"
		event.value = (b + c * 128 - 8192) / 8192 -- [-1, 1]
	elseif status == 11 then
		event.name = "cc"
		event.cc = b
		event.value = c
	elseif status == 10 then
		event.name = "aftertouch"
		event.note = b
		event.vel = c
	else
		print("Event not parsed!", status)
	end

	return event
end

function M.unparse(event)
	local data = { 0, 0 }

	local status = -1

	if event.name == "note on" then
		status = 9
		data[2] = event.note
		data[3] = event.vel
	elseif event.name == "note off" then
		status = 8
		data[2] = event.note
		data[3] = event.vel
	elseif event.name == "pressure" then
		status = 13
		data[2] = event.vel
	elseif event.name == "pitchbend" then
		status = 14
		local p = math.min(math.max(event.value, -1), 1)
		-- 2^14 - 1
		local w = 16383 * ((p + 1) / 2)
		local msb = math.floor(w / 128)
		local lsb = math.floor(w - 128 * msb)

		data[2] = lsb
		data[3] = msb
	elseif event.name == "cc" then
		status = 11
		data[2] = event.cc
		data[3] = event.value
	elseif event.name == "aftertouch" then
		status = 10
		data[2] = event.note
		data[3] = event.vel
	else
		print("Event not parsed!", status)
	end

	assert(status > 0)

	data[1] = event.channel + bit.lshift(status, 4)

	return data
end

function M.quit()
	M.setUserFirmware(false)
	if M.linn_in then
		rtmidi.closePort(M.linn_in)
	end
	if M.linn_out then
		rtmidi.closePort(M.linn_out)
	end
	if M.loop_out then
		rtmidi.closePort(M.loop_out)
	end
	print("closing")
end

function M.setUserFirmware(on)
	-- send NRPN 245 1
	rtmidi.sendMessage(M.linn_out, rtmidi.newMessage({ 0xB0, 0x63, 0x01 }))
	rtmidi.sendMessage(M.linn_out, rtmidi.newMessage({ 0xB0, 0x62, 0x75 }))
	rtmidi.sendMessage(M.linn_out, rtmidi.newMessage({ 0xB0, 0x06, 0x00 }))
	if on then
		rtmidi.sendMessage(M.linn_out, rtmidi.newMessage({ 0xB0, 0x26, 0x01 }))
	else
		rtmidi.sendMessage(M.linn_out, rtmidi.newMessage({ 0xB0, 0x26, 0x00 }))
	end
end

function M.setLight(x, y, color)
	if color == 0 then
		color = colors.OFF
	end
	-- send CCs 20, 21 and 22
	rtmidi.sendMessage(M.linn_out, rtmidi.newMessage({ 0xB0, 20, x }))
	rtmidi.sendMessage(M.linn_out, rtmidi.newMessage({ 0xB0, 21, y }))
	rtmidi.sendMessage(M.linn_out, rtmidi.newMessage({ 0xB0, 22, color }))
end

return M
