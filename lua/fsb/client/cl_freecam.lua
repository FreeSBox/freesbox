--[[
Based on code from BadAPI.
The code in BadAPI is based off of code in YimMenu, which is licensed under GPL3.

https://github.com/TupoyeMenu/BadAPI-Lua/blob/master/builtin/commands/freecam.lua
]]

---@class fsb_freecam
local fsb_freecam = {}

fsb_freecam.position = nil
fsb_freecam.speed = 0.25
fsb_freecam.mult = 0

---Client only.
---Enables freecam.
function FSB.EnableFreecam()
	if fsb_freecam.position == nil then
		fsb_freecam.position = LocalPlayer():EyePos()
	end

	hook.Add("CreateMove", "fsb_freecam_input", function (cmd)
		local rot = cmd:GetViewAngles()
		local forward = rot:Forward() * (cmd:GetForwardMove()/10000)
		local right = rot:Right() * (cmd:GetSideMove()/10000)
		local up = rot:Up() * (cmd:GetUpMove()/10000) -- BUG: Doesn't work?
		if cmd:GetForwardMove() == 0 and cmd:GetSideMove() == 0 then
			fsb_freecam.mult = 0
		elseif fsb_freecam.mult < 10 then
			fsb_freecam.mult = fsb_freecam.mult + 0.06
		end

		if forward then
			fsb_freecam.position.x = fsb_freecam.position.x + (forward.x + right.x + up.x) * fsb_freecam.mult
			fsb_freecam.position.y = fsb_freecam.position.y + (forward.y + right.y + up.y) * fsb_freecam.mult
			fsb_freecam.position.z = fsb_freecam.position.z + (forward.z + right.z + up.z) * fsb_freecam.mult
		end

		cmd:ClearMovement()
		cmd:ClearButtons()
	end)
	hook.Add("CalcView", "fsb_freecam_view", function (ply, origin, angles, fov, znear, zfar)
		local view = {
			origin = fsb_freecam.position,
			angles = angles,
			fov = fov,
			drawviewer = true
		}

		return view
	end)
end

---Client only.
---Disables freecam.
function FSB.DisableFreecam()
	fsb_freecam.position = nil
	hook.Remove("CreateMove", "fsb_freecam_input")
	hook.Remove("CalcView", "fsb_freecam_view")
end
