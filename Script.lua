--==================================================
-- FTP HUB - REALTIME CLIENT TELEMETRY
-- Diagnostic / Pentest Lab
--==================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- GAME LOCK
--==================================================

local ALLOWED_PLACE_ID = 89469502395769

if game.PlaceId ~= ALLOWED_PLACE_ID then
	warn("[FTP TELEMETRY] Wrong PlaceId:", game.PlaceId)
	return
end

--==================================================
-- CONFIG
--==================================================

local CONFIG = {
	PositionInterval = 0.25,
	HealthInterval = 0.10,
	RemoteScanInterval = 5,
	Debug = true,
	GUI = true
}

--==================================================
-- LOGGER
--==================================================

local function timestamp()
	return os.date("%H:%M:%S")
end

local function log(eventName, data)
	print(
		string.format(
			"[%s] [FTP] [%s] [%s] %s",
			timestamp(),
			LocalPlayer.Name,
			eventName,
			tostring(data or "")
		)
	)
end

--==================================================
-- PLAYER STATE
--==================================================

local character
local humanoid
local rootPart

local lastPosition
local lastHealth
local lastWalkSpeed
local lastJumpPower

--==================================================
-- CHARACTER SETUP
--==================================================

local function setupCharacter(char)

	character = char

	log(
		"CHARACTER_CHANGED",
		char:GetFullName()
	)

	humanoid = char:FindFirstChildOfClass("Humanoid")

	rootPart = char:FindFirstChild("HumanoidRootPart")

	if not humanoid then
		log("WARNING", "Humanoid tidak ditemukan")
		return
	end

	if not rootPart then
		log("WARNING", "HumanoidRootPart tidak ditemukan")
	end

	lastHealth = humanoid.Health
	lastWalkSpeed = humanoid.WalkSpeed
	lastJumpPower = humanoid.JumpPower

	if rootPart then
		lastPosition = rootPart.Position
	end

	log("CHARACTER", "Humanoid OK")

	log(
		"STATS",
		"HP=" .. humanoid.Health ..
		" MaxHP=" .. humanoid.MaxHealth ..
		" WalkSpeed=" .. humanoid.WalkSpeed ..
		" JumpPower=" .. humanoid.JumpPower
	)

	--==================================================
	-- HUMANOID STATE
	--==================================================

	humanoid.StateChanged:Connect(function(oldState, newState)

		log(
			"STATE",
			oldState.Name .. " -> " .. newState.Name
		)

	end)

	--==================================================
	-- JUMP
	--==================================================

	humanoid.Jumping:Connect(function(active)

		if active then
			log("JUMP", "Humanoid.Jumping = true")
		end

	end)

	--==================================================
	-- TOOL MONITOR
	--==================================================

	local function monitorTool(tool)

		if not tool:IsA("Tool") then
			return
		end

		log(
			"TOOL",
			"Detected: " .. tool.Name
		)

		tool.Equipped:Connect(function()

			log(
				"TOOL_EQUIP",
				tool.Name
			)

		end)

		tool.Unequipped:Connect(function()

			log(
				"TOOL_UNEQUIP",
				tool.Name
			)

		end)

		tool.Activated:Connect(function()

			log(
				"TOOL_ACTIVATE",
				tool.Name
			)

		end)

		tool.Deactivated:Connect(function()

			log(
				"TOOL_DEACTIVATE",
				tool.Name
			)

		end)

	end

	for _, object in ipairs(char:GetChildren()) do
		monitorTool(object)
	end

	char.ChildAdded:Connect(function(object)

		if object:IsA("Tool") then
			monitorTool(object)
		end

	end)

end

--==================================================
-- INITIAL CHARACTER
--==================================================

setupCharacter(
	LocalPlayer.Character
	or LocalPlayer.CharacterAdded:Wait()
)

--==================================================
-- CHARACTER RESPAWN
--==================================================

LocalPlayer.CharacterAdded:Connect(function(char)

	task.wait(0.25)

	setupCharacter(char)

end)

--==================================================
-- BACKPACK TOOL MONITOR
--==================================================

local backpack = LocalPlayer:WaitForChild("Backpack")

backpack.ChildAdded:Connect(function(object)

	if object:IsA("Tool") then

		log(
			"TOOL_BACKPACK_ADD",
			object.Name
		)

		object.Equipped:Connect(function()

			log(
				"TOOL_EQUIP",
				object.Name
			)

		end)

		object.Unequipped:Connect(function()

			log(
				"TOOL_UNEQUIP",
				object.Name
			)

		end)

	end

end)

backpack.ChildRemoved:Connect(function(object)

	if object:IsA("Tool") then

		log(
			"TOOL_BACKPACK_REMOVE",
			object.Name
		)

	end

end)

--==================================================
-- POSITION / MOVEMENT MONITOR
--==================================================

local positionTimer = 0

RunService.Heartbeat:Connect(function(deltaTime)

	if not character or not humanoid then
		return
	end

	positionTimer += deltaTime

	if positionTimer < CONFIG.PositionInterval then
		return
	end

	positionTimer = 0

	if rootPart then

		local position = rootPart.Position

		if lastPosition then

			local distance =
				(position - lastPosition).Magnitude

			if distance > 0.01 then

				log(
					"POSITION",
					string.format(
						"X=%.2f Y=%.2f Z=%.2f Δ=%.2f",
						position.X,
						position.Y,
						position.Z,
						distance
					)
				)

			end

		end

		lastPosition = position

	end

	--==================================================
	-- WALKSPEED
	--==================================================

	if humanoid.WalkSpeed ~= lastWalkSpeed then

		log(
			"WALKSPEED_CHANGED",
			string.format(
				"%.2f -> %.2f",
				lastWalkSpeed,
				humanoid.WalkSpeed
			)
		)

		lastWalkSpeed = humanoid.WalkSpeed

	end

	--==================================================
	-- JUMPPOWER
	--==================================================

	if humanoid.JumpPower ~= lastJumpPower then

		log(
			"JUMPPOWER_CHANGED",
			string.format(
				"%.2f -> %.2f",
				lastJumpPower,
				humanoid.JumpPower
			)
		)

		lastJumpPower = humanoid.JumpPower

	end

	--==================================================
	-- HEALTH
	--==================================================

	if humanoid.Health ~= lastHealth then

		log(
			"HEALTH_CHANGED",
			string.format(
				"%.2f -> %.2f",
				lastHealth,
				humanoid.Health
			)
		)

		lastHealth = humanoid.Health

	end

end)

--==================================================
-- KEYBOARD INPUT
--==================================================

UserInputService.InputBegan:Connect(function(input, processed)

	local inputType = input.UserInputType

	if inputType == Enum.UserInputType.Keyboard then

		log(
			"KEY_DOWN",
			tostring(input.KeyCode)
		)

	elseif inputType == Enum.UserInputType.MouseButton1 then

		log(
			"MOUSE_DOWN",
			"Left"
		)

	elseif inputType == Enum.UserInputType.MouseButton2 then

		log(
			"MOUSE_DOWN",
			"Right"
		)

	elseif inputType == Enum.UserInputType.MouseButton3 then

		log(
			"MOUSE_DOWN",
			"Middle"
		)

	end

end)

--==================================================
-- INPUT END
--==================================================

UserInputService.InputEnded:Connect(function(input)

	local inputType = input.UserInputType

	if inputType == Enum.UserInputType.Keyboard then

		log(
			"KEY_UP",
			tostring(input.KeyCode)
		)

	elseif inputType == Enum.UserInputType.MouseButton1 then

		log(
			"MOUSE_UP",
			"Left"
		)

	elseif inputType == Enum.UserInputType.MouseButton2 then

		log(
			"MOUSE_UP",
			"Right"
		)

	end

end)

--==================================================
-- INPUT CHANGE
--==================================================

UserInputService.InputChanged:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseMovement then

		log(
			"MOUSE_MOVE",
			string.format(
				"X=%d Y=%d",
				input.Position.X,
				input.Position.Y
			)
		)

	end

end)

--==================================================
-- REMOTE SCANNER
--==================================================

local function scanRemotes()

	local folder =
		ReplicatedStorage:FindFirstChild("Remotes")

	if not folder then

		log(
			"REMOTE_SCAN",
			"ReplicatedStorage.Remotes tidak ditemukan"
		)

		return

	end

	log(
		"REMOTE_SCAN",
		"Scanning " .. folder:GetFullName()
	)

	for _, object in ipairs(folder:GetDescendants()) do

		if object:IsA("RemoteEvent") then

			log(
				"REMOTE_EVENT",
				object:GetFullName()
			)

		elseif object:IsA("RemoteFunction") then

			log(
				"REMOTE_FUNCTION",
				object:GetFullName()
			)

		end

	end

end

scanRemotes()

--==================================================
-- PERIODIC REMOTE SCAN
--==================================================

task.spawn(function()

	while true do

		task.wait(CONFIG.RemoteScanInterval)

		scanRemotes()

	end

end)

--==================================================
-- CHARACTER PROPERTY WATCH
--==================================================

task.spawn(function()

	while true do

		task.wait(0.5)

		if character then

			local children = character:GetChildren()

			log(
				"CHARACTER_SCAN",
				"Children=" .. #children
			)

		end

	end

end)

--==================================================
-- START
--==================================================

print("========================================")
print("FTP HUB REALTIME TELEMETRY READY")
print("Player :", LocalPlayer.Name)
print("Place  :", game.PlaceId)
print("========================================")

log(
	"START",
	"Realtime telemetry aktif"
)
