-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- Settings
local AIM_ENABLED = true
local HOLD_KEY = Enum.KeyCode.LeftAlt
local SMOOTHNESS = 0.15
local FOV_DEGREES = 120
local FOV_COS = math.cos(math.rad(FOV_DEGREES / 2))
local TARGET_PART = "Head" -- change to "Torso" if needed

---------------------------------------------------
-- GUI
---------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AimAssistGUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 160, 0, 40)
button.Position = UDim2.new(0, 20, 0, 20)
button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
button.TextColor3 = Color3.new(1,1,1)
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.Text = "Aim Assist: ON"
button.Parent = gui

button.MouseButton1Click:Connect(function()
	AIM_ENABLED = not AIM_ENABLED
	button.Text = "Aim Assist: " .. (AIM_ENABLED and "ON" or "OFF")
	button.BackgroundColor3 = AIM_ENABLED
		and Color3.fromRGB(35, 35, 35)
		or Color3.fromRGB(80, 30, 30)
end)

---------------------------------------------------
-- FOV Circle
---------------------------------------------------
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = 200 -- adjustable
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 0.5

---------------------------------------------------
-- Utility
---------------------------------------------------
local function isSameTeam(player)
	if player.Team and LocalPlayer.Team then
		return player.Team == LocalPlayer.Team
	end
	return false
end

local function hasLineOfSight(targetPart)
	local origin = Camera.CFrame.Position
	local direction = (targetPart.Position - origin)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
	params.IgnoreWater = true
	local result = workspace:Raycast(origin, direction, params)
	return result == nil
end

local function getClosestTarget()
	local closestScreenPos = nil
	local shortestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and not isSameTeam(player) then
			local targetPart = player.Character:FindFirstChild(TARGET_PART)
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if targetPart and humanoid and humanoid.Health > 0 then
				local toTarget = (targetPart.Position - Camera.CFrame.Position).Unit
				if toTarget:Dot(Camera.CFrame.LookVector) >= FOV_COS then
					if hasLineOfSight(targetPart) then
						local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
						if onScreen then
							local mousePos = UserInputService:GetMouseLocation()
							local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
							if dist < shortestDistance then
								shortestDistance = dist
								closestScreenPos = screenPos
							end
						end
					end
				end
			end
		end
	end

	return closestScreenPos
end

---------------------------------------------------
-- Input
---------------------------------------------------
local holding = false
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == HOLD_KEY then
		holding = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == HOLD_KEY then
		holding = false
	end
end)

---------------------------------------------------
-- Main Loop
---------------------------------------------------
RunService.RenderStepped:Connect(function()
	-- Update FOV Circle
	local mousePos = UserInputService:GetMouseLocation()
	fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
	fovCircle.Visible = AIM_ENABLED

	if not AIM_ENABLED or not holding then return end

	local target = getClosestTarget()
	if target then
		local mousePos = UserInputService:GetMouseLocation()
		local newPos = mousePos:Lerp(Vector2.new(target.X, target.Y), SMOOTHNESS)
		UserInputService:SetMouseLocation(newPos.X, newPos.Y)
	end
end)
