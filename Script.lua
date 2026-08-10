```lua
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
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- GAME LOCK
--==================================================

local ALLOWED_PLACE_ID = 89469502395769

print("========================================")
print("       FTP HUB REALTIME DIAGNOSTIC")
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
	MaxLogs = 300,
	PositionInterval = 0.25,
	StatusInterval = 0.15,

	LogPosition = true,
	LogHealth = true,
	LogMovement = true,
	LogInput = true,
	LogTools = true,
	LogCharacter = true,
	LogRemotes = true,
	LogServices = true,

	AutoOpen = true
}

--==================================================
-- LOGGER
--==================================================

local logHistory = {}

local function timestamp()
	return os.date("%H:%M:%S")
end

local function log(...)
	print("[FTP HUB]", ...)
end

local function warning(...)
	warn("[FTP HUB]", ...)
end

local function stringify(value)
	if typeof(value) == "Vector3" then
		return string.format(
			"(%.1f, %.1f, %.1f)",
			value.X,
			value.Y,
			value.Z
		)
	end

	return tostring(value)
end

--==================================================
-- PLAYER
--==================================================

if not LocalPlayer then
	warning("LocalPlayer tidak ditemukan.")
	return
end

log("Player:", LocalPlayer.Name)
log("UserId:", LocalPlayer.UserId)

--==================================================
-- CHARACTER
--==================================================

local character = LocalPlayer.Character
	or LocalPlayer.CharacterAdded:Wait()

local humanoid
local rootPart

local function updateCharacterReferences()
	character = LocalPlayer.Character

	if not character then
		humanoid = nil
		rootPart = nil
		return
	end

	humanoid = character:FindFirstChildOfClass("Humanoid")
	rootPart = character:FindFirstChild("HumanoidRootPart")
end

updateCharacterReferences()

--==================================================
-- GUI
--==================================================

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("FTPHub")

if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "FTPHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

--==================================================
-- OPEN / CLOSE LOGO
--==================================================

local openButton = Instance.new("TextButton")

openButton.Name = "OpenButton"
openButton.Size = UDim2.fromOffset(58, 58)
openButton.Position = UDim2.new(0, 15, 0.5, -29)

openButton.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
openButton.Text = "FTP"
openButton.TextColor3 = Color3.fromRGB(0, 255, 0)
openButton.TextSize = 18
openButton.Font = Enum.Font.Code

openButton.Visible = false
openButton.Parent = gui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(1, 0)
openCorner.Parent = openButton

local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(0, 255, 0)
openStroke.Thickness = 2
openStroke.Parent = openButton

--==================================================
-- MAIN FRAME
--==================================================

local frame = Instance.new("Frame")

frame.Name = "Main"
frame.Size = UDim2.new(0.92, 0, 0.82, 0)
frame.Position = UDim2.new(0.04, 0, 0.09, 0)

frame.BackgroundColor3 = Color3.fromRGB(7, 7, 7)
frame.BackgroundTransparency = 0.03
frame.BorderSizePixel = 0
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 14)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(0, 255, 0)
frameStroke.Thickness = 2
frameStroke.Parent = frame

--==================================================
-- TITLE
--==================================================

local title = Instance.new("TextLabel")

title.Size = UDim2.new(1, -70, 0, 45)
title.Position = UDim2.fromOffset(15, 8)

title.BackgroundTransparency = 1
title.Text = "FTP HUB // REALTIME MONITOR"
title.TextColor3 = Color3.fromRGB(0, 255, 0)

title.Font = Enum.Font.Code
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left

title.Parent = frame

--==================================================
-- CLOSE
--==================================================

local closeButton = Instance.new("TextButton")

closeButton.Size = UDim2.fromOffset(38, 38)
closeButton.Position = UDim2.new(1, -48, 0, 10)

closeButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
closeButton.Text = "X"

closeButton.TextColor3 = Color3.fromRGB(255, 80, 80)
closeButton.Font = Enum.Font.Code
closeButton.TextSize = 20

closeButton.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

--==================================================
-- STATUS
--==================================================

local status = Instance.new("TextLabel")

status.Size = UDim2.new(1, -30, 0, 30)
status.Position = UDim2.fromOffset(15, 55)

status.BackgroundTransparency = 1
status.Text = "● MONITORING"

status.TextColor3 = Color3.fromRGB(100, 255, 100)
status.Font = Enum.Font.Code
status.TextSize = 15

status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

--==================================================
-- LOG SCROLL
--==================================================

local scroll = Instance.new("ScrollingFrame")

scroll.Name = "LogScroll"

scroll.Size = UDim2.new(1, -30, 1, -100)
scroll.Position = UDim2.fromOffset(15, 90)

scroll.BackgroundColor3 = Color3.fromRGB(3, 3, 3)
scroll.BackgroundTransparency = 0.15

scroll.BorderSizePixel = 0

scroll.ScrollBarThickness = 7
scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 0)

scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar

scroll.Parent = frame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 10)
scrollCorner.Parent = scroll

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = scroll

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 3)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

--==================================================
-- GUI LOGGER
--==================================================

local function addLog(category, message)
	local line = Instance.new("TextLabel")

	local text =
		"[" .. timestamp() .. "] "
		.. "[" .. category .. "] "
		.. message

	line.Size = UDim2.new(1, -4, 0, 0)
	line.AutomaticSize = Enum.AutomaticSize.Y

	line.BackgroundTransparency = 1

	line.Text = text
	line.TextColor3 = Color3.fromRGB(210, 210, 210)

	line.Font = Enum.Font.Code
	line.TextSize = 14

	line.TextWrapped = true
	line.TextXAlignment = Enum.TextXAlignment.Left
	line.TextYAlignment = Enum.TextYAlignment.Top

	line.Parent = scroll

	table.insert(logHistory, line)

	if #logHistory > CONFIG.MaxLogs then
		local old = table.remove(logHistory, 1)

		if old then
			old:Destroy()
		end
	end

	task.defer(function()
		if scroll and scroll.Parent then
			scroll.CanvasPosition = Vector2.new(
				0,
				math.max(0, scroll.AbsoluteCanvasSize.Y)
			)
		end
	end)
end

--==================================================
-- SERVICE REPORT
--==================================================

if CONFIG.LogServices then

	addLog(
		"SERVICE",
		"Players = " .. Players:GetFullName()
	)

	addLog(
		"SERVICE",
		"ReplicatedStorage = " .. ReplicatedStorage:GetFullName()
	)

	addLog(
		"SERVICE",
		"RunService = " .. RunService:GetFullName()
	)

	addLog(
		"SERVICE",
		"UserInputService = " .. UserInputService:GetFullName()
	)

	addLog(
		"SERVICE",
		"StarterGui = " .. StarterGui:GetFullName()
	)

	addLog(
		"SERVICE",
		"Workspace = " .. Workspace:GetFullName()
	)

	addLog(
		"PLAYER",
		"Name = " .. LocalPlayer.Name
	)

	addLog(
		"PLAYER",
		"UserId = " .. tostring(LocalPlayer.UserId)
	)

	addLog(
		"GAME",
		"PlaceId = " .. tostring(game.PlaceId)
	)

end

--==================================================
-- REMOTE SCANNER
--==================================================

local remoteResults = {}

local function scanRemotes()

	table.clear(remoteResults)

	local remotes =
		ReplicatedStorage:FindFirstChild("Remotes")

	if not remotes then
		addLog(
			"REMOTE",
			"Folder Remotes tidak ditemukan."
		)

		return nil
	end

	addLog(
		"REMOTE",
		"Folder = " .. remotes:GetFullName()
	)

	for _, object in ipairs(
		remotes:GetDescendants()
	) do

		if object:IsA("RemoteEvent") then

			table.insert(
				remoteResults,
				object
			)

			addLog(
				"REMOTE",
				"RemoteEvent -> "
					.. object:GetFullName()
			)

		elseif object:IsA("RemoteFunction") then

			table.insert(
				remoteResults,
				object
			)

			addLog(
				"REMOTE",
				"RemoteFunction -> "
					.. object:GetFullName()
			)

		end

	end

	addLog(
		"REMOTE",
		"Total = "
			.. tostring(#remoteResults)
	)

	return remotes
end

local remotes = nil

if CONFIG.LogRemotes then
	remotes = scanRemotes()
end

--==================================================
-- TOOL MONITOR
--==================================================

local backpack =
	LocalPlayer:WaitForChild("Backpack")

local knownTools = {}

local function registerTool(tool)

	if not tool:IsA("Tool") then
		return
	end

	if knownTools[tool] then
		return
	end

	knownTools[tool] = true

	addLog(
		"TOOL",
		"Detected = " .. tool.Name
	)

	tool.Equipped:Connect(function()

		addLog(
			"TOOL",
			"EQUIPPED = " .. tool.Name
		)

	end)

	tool.Unequipped:Connect(function()

		addLog(
			"TOOL",
			"UNEQUIPPED = " .. tool.Name
		)

	end)

	tool.Activated:Connect(function()

		addLog(
			"TOOL",
			"ACTIVATED = " .. tool.Name
		)

	end)

end

local function scanTools()

	for _, object in ipairs(
		backpack:GetChildren()
	) do

		registerTool(object)

	end

	if character then

		for _, object in ipairs(
			character:GetChildren()
		) do

			registerTool(object)

		end

	end

end

if CONFIG.LogTools then

	scanTools()

	backpack.ChildAdded:Connect(function(child)

		registerTool(child)

		addLog(
			"TOOL",
			"Backpack + " .. child.Name
		)

	end)

	character.ChildAdded:Connect(function(child)

		if child:IsA("Tool") then

			registerTool(child)

			addLog(
				"TOOL",
				"Character + " .. child.Name
			)

		end

	end)

end

--==================================================
-- HUMANOID MONITOR
--==================================================

local lastHealth = nil
local lastMaxHealth = nil
local lastWalkSpeed = nil
local lastJumpPower = nil
local lastState = nil

local function setupHumanoidMonitor()

	if not humanoid then
		return
	end

	lastHealth = humanoid.Health
	lastMaxHealth = humanoid.MaxHealth
	lastWalkSpeed = humanoid.WalkSpeed
	lastJumpPower = humanoid.JumpPower

	humanoid.StateChanged:Connect(
		function(oldState, newState)

			if CONFIG.LogMovement then

				addLog(
					"MOVEMENT",
					"State "
						.. oldState.Name
						.. " -> "
						.. newState.Name
				)

			end

		end
	)

	humanoid.Jumping:Connect(function(active)

		if active then

			addLog(
				"JUMP",
				"Player jumped"
			)

		end

	end)

	humanoid.FreeFalling:Connect(function(active)

		if active then

			addLog(
				"FALL",
				"Player started falling"
			)

		else

			addLog(
				"FALL",
				"Player stopped falling"
			)

		end

	end)

	humanoid.HealthChanged:Connect(
		function(newHealth)

			if not CONFIG.LogHealth then
				return
			end

			local oldHealth = lastHealth
			lastHealth = newHealth

			addLog(
				"HEALTH",
				string.format(
					"%.1f -> %.1f",
					oldHealth or newHealth,
					newHealth
				)
			)

		end
	)

	humanoid:GetPropertyChangedSignal(
		"WalkSpeed"
	):Connect(function()

		local old = lastWalkSpeed
		lastWalkSpeed = humanoid.WalkSpeed

		addLog(
			"MOVEMENT",
			"WalkSpeed "
				.. tostring(old)
				.. " -> "
				.. tostring(humanoid.WalkSpeed)
		)

	end)

	humanoid:GetPropertyChangedSignal(
		"JumpPower"
	):Connect(function()

		local old = lastJumpPower
		lastJumpPower = humanoid.JumpPower

		addLog(
			"MOVEMENT",
			"JumpPower "
				.. tostring(old)
				.. " -> "
				.. tostring(humanoid.JumpPower)
		)

	end)

end

setupHumanoidMonitor()

--==================================================
-- CHARACTER MONITOR
--==================================================

LocalPlayer.CharacterAdded:Connect(
	function(newCharacter)

		addLog(
			"CHARACTER",
			"CharacterAdded = "
				.. newCharacter.Name
		)

		character = newCharacter

		task.wait(0.5)

		updateCharacterReferences()

		if humanoid then

			addLog(
				"CHARACTER",
				"Humanoid detected"
			)

			setupHumanoidMonitor()

		end

		if rootPart then

			addLog(
				"CHARACTER",
				"HumanoidRootPart detected"
			)

		end

		if CONFIG.LogTools then
			scanTools()
		end

	end
)

--==================================================
-- CHARACTER CHILD CHANGES
--==================================================

if character and CONFIG.LogCharacter then

	character.ChildAdded:Connect(
		function(child)

			addLog(
				"CHARACTER",
				"+ "
					.. child.Name
					.. " ["
					.. child.ClassName
					.. "]"
			)

		end
	)

	character.ChildRemoved:Connect(
		function(child)

			addLog(
				"CHARACTER",
				"- "
					.. child.Name
					.. " ["
					.. child.ClassName
					.. "]"
			)

		end
	)

end

--==================================================
-- INPUT MONITOR
--==================================================

if CONFIG.LogInput then

	UserInputService.InputBegan:Connect(
		function(input, processed)

			local inputName =
				input.KeyCode ~= Enum.KeyCode.Unknown
				and input.KeyCode.Name
				or input.UserInputType.Name

			addLog(
				"INPUT",
				"BEGAN = "
					.. inputName
					.. " | processed="
					.. tostring(processed)
			)

		end
	)

	UserInputService.InputEnded:Connect(
		function(input)

			local inputName =
				input.KeyCode ~= Enum.KeyCode.Unknown
				and input.KeyCode.Name
				or input.UserInputType.Name

			addLog(
				"INPUT",
				"ENDED = "
					.. inputName
			)

		end
	)

	UserInputService.InputChanged:Connect(
		function(input)

			if input.UserInputType ==
				Enum.UserInputType.MouseMovement then

				return
			end

			addLog(
				"INPUT",
				"CHANGED = "
					.. input.UserInputType.Name
			)

		end
	)

end

--==================================================
-- POSITION MONITOR
--==================================================

local lastPosition = nil
local lastPositionTime = 0

--==================================================
-- HEARTBEAT
--==================================================

local heartbeatConnection

heartbeatConnection =
RunService.Heartbeat:Connect(
	function()

		if not gui or not gui.Parent then

			if heartbeatConnection then
				heartbeatConnection:Disconnect()
			end

			return
		end

		if humanoid then

			local hp =
				math.floor(humanoid.Health)

			local maxHp =
				math.floor(humanoid.MaxHealth)

			status.Text =
				"● LIVE | "
				.. LocalPlayer.Name
				.. " | HP "
				.. hp
				.. "/"
				.. maxHp

		end

		-- Position logging
		if CONFIG.LogPosition
			and rootPart then

			local now = os.clock()

			if now - lastPositionTime
				>= CONFIG.PositionInterval then

				local currentPosition =
					rootPart.Position

				if lastPosition == nil then

					lastPosition =
						currentPosition

					addLog(
						"POSITION",
						stringify(currentPosition)
					)

				else

					local distance =
						(
							currentPosition
							- lastPosition
						).Magnitude

					if distance >= 0.5 then

						addLog(
							"POSITION",
							stringify(currentPosition)
								.. " | Δ "
								.. string.format(
									"%.2f",
									distance
								)
						)

						lastPosition =
							currentPosition

					end

				end

				lastPositionTime = now

			end

		end

	end
)

--==================================================
-- CLOSE / OPEN
--==================================================

closeButton.MouseButton1Click:Connect(
	function()

		frame.Visible = false
		openButton.Visible = true

	end
)

openButton.MouseButton1Click:Connect(
	function()

		frame.Visible = true
		openButton.Visible = false

	end
)

--==================================================
-- DRAG SUPPORT
--==================================================

local dragging = false
local dragStart
local startPosition

title.InputBegan:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			dragging = true
			dragStart = input.Position
			startPosition = frame.Position

		end

	end
)

title.InputEnded:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			dragging = false

		end

	end
)

UserInputService.InputChanged:Connect(
	function(input)

		if not dragging then
			return
		end

		if input.UserInputType ==
			Enum.UserInputType.MouseMovement then

			local delta =
				input.Position - dragStart

			frame.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)

		end

	end
)

--==================================================
-- INITIAL CHARACTER REPORT
--==================================================

if humanoid then

	addLog(
		"CHARACTER",
		"Health = "
			.. tostring(humanoid.Health)
	)

	addLog(
		"CHARACTER",
		"MaxHealth = "
			.. tostring(humanoid.MaxHealth)
	)

	addLog(
		"MOVEMENT",
		"WalkSpeed = "
			.. tostring(humanoid.WalkSpeed)
	)

	addLog(
		"MOVEMENT",
		"JumpPower = "
			.. tostring(humanoid.JumpPower)
	)

end

if rootPart then

	addLog(
		"POSITION",
		stringify(rootPart.Position)
	)

end

--==================================================
-- FINAL REPORT
--==================================================

addLog(
	"SYSTEM",
	"================================"
)

addLog(
	"SYSTEM",
	"FTP HUB DIAGNOSTIC READY"
)

addLog(
	"SYSTEM",
	"Realtime monitoring active"
)

addLog(
	"SYSTEM",
	"Scroll untuk melihat event lama"
)

print("========================================")
print(" FTP HUB REALTIME DIAGNOSTIC READY")
print("========================================")
print("Player :", LocalPlayer.Name)
print("PlaceId:", game.PlaceId)
print("Realtime logging active.")
print("========================================")
```
