--==================================================
-- FTP HUB - REALTIME PENTEST / DIAGNOSTIC CLIENT
--==================================================

--==================================================
-- SERVICES
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

print("========================================")
print("       FTP HUB PENTEST STARTING")
print("========================================")
print("Current PlaceId :", game.PlaceId)
print("Expected PlaceId:", ALLOWED_PLACE_ID)

if game.PlaceId ~= ALLOWED_PLACE_ID then
	warn("[FTP HUB] PlaceId tidak cocok.")
	return
end

print("[FTP HUB] PlaceId verified.")

--==================================================
-- CONFIG
--==================================================

local CONFIG = {
	WelcomeDuration = 8,

	Debug = true,

	ScanRemotes = true,
	ScanTools = true,

	TrackPosition = true,
	TrackMovement = true,
	TrackHealth = true,
	TrackStats = true,
	TrackInput = true,
	TrackCharacter = true,

	PositionInterval = 0.25,
	RemoteScanInterval = 5
}

--==================================================
-- LOGGER
--==================================================

local function log(eventName, ...)
	if CONFIG.Debug then
		print(
			"[FTP HUB][" ..
			os.date("%H:%M:%S") ..
			"][" ..
			LocalPlayer.Name ..
			"][" ..
			eventName ..
			"]",
			...
		)
	end
end

local function warning(...)
	warn("[FTP HUB]", ...)
end

--==================================================
-- PLAYER
--==================================================

if not LocalPlayer then
	warning("LocalPlayer tidak ditemukan.")
	return
end

log(
	"PLAYER",
	"Name =", LocalPlayer.Name,
	"UserId =", LocalPlayer.UserId
)

--==================================================
-- CHARACTER STATE
--==================================================

local character
local humanoid
local rootPart

local lastPosition = nil
local lastHealth = nil
local lastWalkSpeed = nil
local lastJumpPower = nil

--==================================================
-- TOOL CONNECTION STORAGE
--==================================================

local monitoredTools = {}

--==================================================
-- TOOL LOGGER
--==================================================

local function monitorTool(tool)

	if not tool:IsA("Tool") then
		return
	end

	if monitoredTools[tool] then
		return
	end

	monitoredTools[tool] = true

	log(
		"TOOL_DETECTED",
		tool.Name,
		"| Parent =",
		tool.Parent:GetFullName()
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

	tool.Destroying:Connect(function()

		log(
			"TOOL_DESTROY",
			tool.Name
		)

		monitoredTools[tool] = nil

	end)

end

--==================================================
-- TOOL SCANNER
--==================================================

local tools = {}

local function scanTools()

	table.clear(tools)

	-- Backpack

	local backpack = LocalPlayer:FindFirstChild("Backpack")

	if backpack then

		for _, object in ipairs(backpack:GetChildren()) do

			if object:IsA("Tool") then

				table.insert(
					tools,
					object.Name
				)

				monitorTool(object)

				log(
					"BACKPACK_TOOL",
					object.Name
				)

			end

		end

	end

	-- Equipped

	if character then

		for _, object in ipairs(character:GetChildren()) do

			if object:IsA("Tool") then

				table.insert(
					tools,
					object.Name
				)

				monitorTool(object)

				log(
					"EQUIPPED_TOOL",
					object.Name
				)

			end

		end

	end

end

--==================================================
-- BACKPACK MONITOR
--==================================================

local backpack = LocalPlayer:WaitForChild("Backpack")

backpack.ChildAdded:Connect(function(object)

	if object:IsA("Tool") then

		log(
			"TOOL_ADDED",
			object.Name
		)

		monitorTool(object)

	end

end)

backpack.ChildRemoved:Connect(function(object)

	if object:IsA("Tool") then

		log(
			"TOOL_REMOVED",
			object.Name
		)

	end

end)

--==================================================
-- CHARACTER SETUP
--==================================================

local characterConnections = {}

local function setupCharacter(newCharacter)

	character = newCharacter

	log(
		"CHARACTER_CHANGED",
		newCharacter:GetFullName()
	)

	-- Clear old connections

	for _, connection in ipairs(characterConnections) do

		if connection then
			connection:Disconnect()
		end

	end

	table.clear(characterConnections)

	-- Find parts

	humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	rootPart =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	if not humanoid then

		warning(
			"Humanoid tidak ditemukan."
		)

		return

	end

	if not rootPart then

		warning(
			"HumanoidRootPart tidak ditemukan."
		)

	end

	-- Initial values

	lastHealth = humanoid.Health
	lastWalkSpeed = humanoid.WalkSpeed
	lastJumpPower = humanoid.JumpPower

	if rootPart then
		lastPosition = rootPart.Position
	end

	--==================================================
	-- HUMANOID STATE
	--==================================================

	table.insert(
		characterConnections,

		humanoid.StateChanged:Connect(
			function(oldState, newState)

				log(
					"STATE_CHANGED",
					oldState.Name,
					"->",
					newState.Name
				)

			end
		)
	)

	--==================================================
	-- JUMP
	--==================================================

	table.insert(
		characterConnections,

		humanoid.Jumping:Connect(
			function(active)

				if active then

					log(
						"JUMP",
						"Jump detected"
					)

				end

			end
		)
	)

	--==================================================
	-- RUNNING
	--==================================================

	table.insert(
		characterConnections,

		humanoid.Running:Connect(
			function(speed)

				if speed > 0 then

					log(
						"RUNNING",
						"Speed =",
						math.floor(speed * 100) / 100
					)

				end

			end
		)
	)

	--==================================================
	-- CHARACTER CHILDREN
	--==================================================

	table.insert(
		characterConnections,

		character.ChildAdded:Connect(
			function(object)

				log(
					"CHARACTER_CHILD_ADDED",
					object.Name,
					object.ClassName
				)

				if object:IsA("Tool") then
					monitorTool(object)
				end

			end
		)
	)

	table.insert(
		characterConnections,

		character.ChildRemoved:Connect(
			function(object)

				log(
					"CHARACTER_CHILD_REMOVED",
					object.Name,
					object.ClassName
				)

			end
		)
	)

	--==================================================
	-- INITIAL TOOL SCAN
	--==================================================

	scanTools()

	log(
		"CHARACTER_READY",
		"Health =", humanoid.Health,
		"WalkSpeed =", humanoid.WalkSpeed,
		"JumpPower =", humanoid.JumpPower
	)

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

LocalPlayer.CharacterAdded:Connect(
	function(newCharacter)

		log(
			"RESPAWN",
			"New character detected"
		)

		task.wait(0.5)

		setupCharacter(newCharacter)

	end
)

--==================================================
-- REMOTE SCANNER
--==================================================

local remoteResults = {}

local function scanRemotes()

	table.clear(remoteResults)

	local remotes =
		ReplicatedStorage:FindFirstChild(
			"Remotes"
		)

	if not remotes then

		warning(
			"Folder 'Remotes' tidak ditemukan."
		)

		return nil

	end

	log(
		"REMOTE_SCAN",
		"Scanning:",
		remotes:GetFullName()
	)

	for _, object in ipairs(
		remotes:GetDescendants()
	) do

		if object:IsA("RemoteEvent") then

			table.insert(
				remoteResults,
				{
					Name = object.Name,
					Class = "RemoteEvent",
					Path = object:GetFullName()
				}
			)

			log(
				"REMOTE_EVENT",
				object:GetFullName()
			)

		elseif object:IsA("RemoteFunction") then

			table.insert(
				remoteResults,
				{
					Name = object.Name,
					Class = "RemoteFunction",
					Path = object:GetFullName()
				}
			)

			log(
				"REMOTE_FUNCTION",
				object:GetFullName()
			)

		end

	end

	log(
		"REMOTE_SCAN_DONE",
		"Count =",
		#remoteResults
	)

	return remotes

end

local remotes = nil

if CONFIG.ScanRemotes then
	remotes = scanRemotes()
end

--==================================================
-- KNOWN REMOTE CHECK
--==================================================

local knownRemoteNames = {
	"DamageEvent",
	"HealEvent",
	"RespawnEvent",
	"DamageEffect"
}

local knownRemoteStatus = {}

if remotes then

	for _, name in ipairs(
		knownRemoteNames
	) do

		local object =
			remotes:FindFirstChild(name)

		if object then

			knownRemoteStatus[name] = true

			log(
				"REMOTE_FOUND",
				name,
				object.ClassName
			)

		else

			knownRemoteStatus[name] = false

			log(
				"REMOTE_MISSING",
				name
			)

		end

	end

end

--==================================================
-- REMOTE PERIODIC SCAN
--==================================================

task.spawn(function()

	while true do

		task.wait(
			CONFIG.RemoteScanInterval
		)

		if CONFIG.ScanRemotes then
			scanRemotes()
		end

	end

end)

--==================================================
-- REALTIME MOVEMENT / STATS
--==================================================

local heartbeatConnection

local positionTimer = 0

heartbeatConnection =
RunService.Heartbeat:Connect(
	function(deltaTime)

		--==================================================
		-- GUI CHECK
		--==================================================

		if not character
			or not humanoid then

			return

		end

		--==================================================
		-- TIMER
		--==================================================

		positionTimer += deltaTime

		if positionTimer <
			CONFIG.PositionInterval then

			return

		end

		positionTimer = 0

		--==================================================
		-- POSITION
		--==================================================

		if CONFIG.TrackPosition
			and rootPart then

			local position =
				rootPart.Position

			if lastPosition then

				local delta =
					(position - lastPosition).Magnitude

				if delta > 0.01 then

					log(
						"POSITION",
						string.format(
							"X=%.2f Y=%.2f Z=%.2f | Delta=%.2f",
							position.X,
							position.Y,
							position.Z,
							delta
						)
					)

				end

			end

			lastPosition = position

		end

		--==================================================
		-- HEALTH
		--==================================================

		if CONFIG.TrackHealth then

			if humanoid.Health
				~= lastHealth then

				log(
					"HEALTH_CHANGED",
					string.format(
						"%.2f -> %.2f",
						lastHealth,
						humanoid.Health
					)
				)

				lastHealth =
					humanoid.Health

			end

		end

		--==================================================
		-- WALKSPEED
		--==================================================

		if CONFIG.TrackStats then

			if humanoid.WalkSpeed
				~= lastWalkSpeed then

				log(
					"WALKSPEED_CHANGED",
					string.format(
						"%.2f -> %.2f",
						lastWalkSpeed,
						humanoid.WalkSpeed
					)
				)

				lastWalkSpeed =
					humanoid.WalkSpeed

			end

		end

		--==================================================
		-- JUMPPOWER
		--==================================================

		if CONFIG.TrackStats then

			if humanoid.JumpPower
				~= lastJumpPower then

				log(
					"JUMPPOWER_CHANGED",
					string.format(
						"%.2f -> %.2f",
						lastJumpPower,
						humanoid.JumpPower
					)
				)

				lastJumpPower =
					humanoid.JumpPower

			end

		end

	end
)

--==================================================
-- KEYBOARD / MOUSE
--==================================================

if CONFIG.TrackInput then

	UserInputService.InputBegan:Connect(
		function(input, processed)

			if input.UserInputType
				== Enum.UserInputType.Keyboard then

				log(
					"KEY_DOWN",
					input.KeyCode.Name,
					"Processed =",
					processed
				)

			elseif input.UserInputType
				== Enum.UserInputType.MouseButton1 then

				log(
					"MOUSE_DOWN",
					"Left",
					"Processed =",
					processed
				)

			elseif input.UserInputType
				== Enum.UserInputType.MouseButton2 then

				log(
					"MOUSE_DOWN",
					"Right",
					"Processed =",
					processed
				)

			elseif input.UserInputType
				== Enum.UserInputType.MouseButton3 then

				log(
					"MOUSE_DOWN",
					"Middle",
					"Processed =",
					processed
				)

			end

		end
	)

	UserInputService.InputEnded:Connect(
		function(input)

			if input.UserInputType
				== Enum.UserInputType.Keyboard then

				log(
					"KEY_UP",
					input.KeyCode.Name
				)

			elseif input.UserInputType
				== Enum.UserInputType.MouseButton1 then

				log(
					"MOUSE_UP",
					"Left"
				)

			elseif input.UserInputType
				== Enum.UserInputType.MouseButton2 then

				log(
					"MOUSE_UP",
					"Right"
				)

			end

		end
	)

	UserInputService.InputChanged:Connect(
		function(input)

			if input.UserInputType
				== Enum.UserInputType.MouseMovement then

				log(
					"MOUSE_MOVE",
					string.format(
						"X=%d Y=%d",
						input.Position.X,
						input.Position.Y
					)
				)

			end

		end
	)

end

--==================================================
-- GUI
--==================================================

local playerGui =
	LocalPlayer:WaitForChild(
		"PlayerGui"
	)

local oldGui =
	playerGui:FindFirstChild(
		"FTPHub"
	)

if oldGui then
	oldGui:Destroy()
end

local gui =
	Instance.new("ScreenGui")

gui.Name = "FTPHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

--==================================================
-- MAIN FRAME
--==================================================

local frame =
	Instance.new("Frame")

frame.Name = "Main"

frame.Size =
	UDim2.fromOffset(
		620,
		360
	)

frame.Position =
	UDim2.new(
		0.5,
		-310,
		0,
		35
	)

frame.BackgroundColor3 =
	Color3.fromRGB(
		8,
		8,
		8
	)

frame.BackgroundTransparency =
	0.05

frame.BorderSizePixel = 0
frame.Parent = gui

local corner =
	Instance.new("UICorner")

corner.CornerRadius =
	UDim.new(0, 14)

corner.Parent = frame

local stroke =
	Instance.new("UIStroke")

stroke.Color =
	Color3.fromRGB(
		0,
		255,
		0
	)

stroke.Thickness = 2
stroke.Parent = frame

--==================================================
-- TITLE
--==================================================

local title =
	Instance.new("TextLabel")

title.Name = "Title"

title.Size =
	UDim2.new(
		1,
		-70,
		0,
		55
	)

title.Position =
	UDim2.fromOffset(
		10,
		8
	)

title.BackgroundTransparency = 1

title.Text =
	"FTP HUB // REALTIME TELEMETRY"

title.TextColor3 =
	Color3.fromRGB(
		0,
		255,
		0
	)

title.Font = Enum.Font.Code
title.TextScaled = true
title.Parent = frame

--==================================================
-- STATUS
--==================================================

local status =
	Instance.new("TextLabel")

status.Name = "Status"

status.Size =
	UDim2.new(
		1,
		-20,
		0,
		30
	)

status.Position =
	UDim2.fromOffset(
		10,
		65
	)

status.BackgroundTransparency = 1

status.Text =
	"● TELEMETRY ACTIVE"

status.TextColor3 =
	Color3.fromRGB(
		100,
		255,
		100
	)

status.Font = Enum.Font.Code
status.TextScaled = true
status.Parent = frame

--==================================================
-- INFO
--==================================================

local info =
	Instance.new("TextLabel")

info.Name = "Info"

info.Size =
	UDim2.new(
		1,
		-40,
		0,
		180
	)

info.Position =
	UDim2.fromOffset(
		20,
		105
	)

info.BackgroundTransparency = 1

info.TextXAlignment =
	Enum.TextXAlignment.Left

info.TextYAlignment =
	Enum.TextYAlignment.Top

info.TextColor3 =
	Color3.fromRGB(
		200,
		200,
		200
	)

info.Font = Enum.Font.Code
info.TextSize = 16
info.Parent = frame

--==================================================
-- CLOSE
--==================================================

local closeButton =
	Instance.new("TextButton")

closeButton.Name = "Close"

closeButton.Size =
	UDim2.fromOffset(
		32,
		32
	)

closeButton.Position =
	UDim2.new(
		1,
		-42,
		0,
		10
	)

closeButton.BackgroundColor3 =
	Color3.fromRGB(
		30,
		30,
		30
	)

closeButton.Text = "X"

closeButton.TextColor3 =
	Color3.fromRGB(
		255,
		80,
		80
	)

closeButton.Font = Enum.Font.Code
closeButton.TextSize = 18
closeButton.Parent = frame

local closeCorner =
	Instance.new("UICorner")

closeCorner.CornerRadius =
	UDim.new(0, 8)

closeCorner.Parent =
	closeButton

closeButton.MouseButton1Click:Connect(
	function()

		if heartbeatConnection then
			heartbeatConnection:Disconnect()
		end

		gui:Destroy()

	end
)

--==================================================
-- DRAG
--==================================================

local dragging = false
local dragStart
local startPosition

local function updateDrag(input)

	local delta =
		input.Position - dragStart

	frame.Position =
		UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)

end

title.InputBegan:Connect(
	function(input)

		if input.UserInputType
			== Enum.UserInputType.MouseButton1 then

			dragging = true

			dragStart =
				input.Position

			startPosition =
				frame.Position

		end

	end
)

title.InputEnded:Connect(
	function(input)

		if input.UserInputType
			== Enum.UserInputType.MouseButton1 then

			dragging = false

		end

	end
)

UserInputService.InputChanged:Connect(
	function(input)

		if dragging
			and input.UserInputType
			== Enum.UserInputType.MouseMovement then

			updateDrag(input)

		end

	end
)

--==================================================
-- GUI UPDATE
--==================================================

task.spawn(function()

	while gui and gui.Parent do

		task.wait(0.25)

		if humanoid and rootPart then

			local position =
				rootPart.Position

			info.Text =
				"PlaceId : " ..
				tostring(game.PlaceId) ..

				"\nPlayer  : " ..
				LocalPlayer.Name ..

				"\nUserId  : " ..
				tostring(LocalPlayer.UserId) ..

				"\n\nHP      : " ..
				string.format(
					"%.0f / %.0f",
					humanoid.Health,
					humanoid.MaxHealth
				) ..

				"\nWalkSpeed : " ..
				string.format(
					"%.2f",
					humanoid.WalkSpeed
				) ..

				"\nJumpPower : " ..
				string.format(
					"%.2f",
					humanoid.JumpPower
				) ..

				"\n\nPosition" ..

				"\nX : " ..
				string.format(
					"%.2f",
					position.X
				) ..

				"\nY : " ..
				string.format(
					"%.2f",
					position.Y
				) ..

				"\nZ : " ..
				string.format(
					"%.2f",
					position.Z
				) ..

				"\n\nRemotes : " ..
				tostring(
					#remoteResults
				) ..

				"\nTools : " ..
				tostring(
					#tools
				)

		end

	end

end)

--==================================================
-- FINAL REPORT
--==================================================

print("========================================")
print("      FTP HUB TELEMETRY READY")
print("========================================")

print(
	"PlaceId       :",
	game.PlaceId
)

print(
	"Player        :",
	LocalPlayer.Name
)

print(
	"Remote count  :",
	#remoteResults
)

print(
	"Tool count    :",
	#tools
)

print("========================================")

for name, found in pairs(
	knownRemoteStatus
) do

	print(
		"[REMOTE]",
		name,
		"=",
		found and "FOUND" or "MISSING"
	)

end

print("========================================")

log(
	"READY",
	"Realtime diagnostic aktif."
)
