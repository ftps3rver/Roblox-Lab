--==================================================
-- FTP HUB - PENTEST / DIAGNOSTIC CLIENT
-- REALTIME ACTIVITY MONITOR
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
print("       FTP HUB DIAGNOSTIC STARTING")
print("========================================")
print("Current PlaceId  :", game.PlaceId)
print("Expected PlaceId :", ALLOWED_PLACE_ID)
print("========================================")

if game.PlaceId ~= ALLOWED_PLACE_ID then
	warn("[FTP HUB] PlaceId tidak cocok.")
	return
end

print("[FTP HUB] PlaceId verified.")

--==================================================
-- CONFIG
--==================================================

local CONFIG = {
	MaxLogs = 250,
	PositionInterval = 0.25,
	WelcomeDuration = 8,

	Debug = true,
	ScanRemotes = true,
	ScanTools = true,

	-- Roblox image asset.
	-- Ganti dengan rbxassetid://ID decal/image milikmu.
	LOGO_ASSET = "rbxassetid://6031094678"
}

--==================================================
-- LOGGER
--==================================================

local function log(...)
	print("[FTP HUB]", ...)
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

log("Player:", LocalPlayer.Name)
log("UserId:", LocalPlayer.UserId)

--==================================================
-- CHARACTER
--==================================================

local character = LocalPlayer.Character
	or LocalPlayer.CharacterAdded:Wait()

local humanoid
local rootPart

local function refreshCharacter()

	character = LocalPlayer.Character

	if not character then
		return
	end

	humanoid =
		character:FindFirstChildOfClass("Humanoid")

	rootPart =
		character:FindFirstChild("HumanoidRootPart")

end

refreshCharacter()

--==================================================
-- REMOTE SCANNER
--==================================================

local remoteResults = {}

local function scanRemotes()

	table.clear(remoteResults)

	local remotes =
		ReplicatedStorage:FindFirstChild("Remotes")

	if not remotes then

		warning(
			"Folder 'Remotes' tidak ditemukan."
		)

		return nil
	end

	log(
		"Remotes ditemukan:",
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
				"[RemoteEvent]",
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
				"[RemoteFunction]",
				object:GetFullName()
			)

		end
	end

	return remotes
end

local remotes = nil

if CONFIG.ScanRemotes then
	remotes = scanRemotes()
end

--==================================================
-- TOOL SCANNER
--==================================================

local tools = {}

local function scanTools()

	table.clear(tools)

	local backpack =
		LocalPlayer:FindFirstChild("Backpack")

	if backpack then

		for _, object in ipairs(
			backpack:GetChildren()
		) do

			if object:IsA("Tool") then

				table.insert(
					tools,
					object.Name
				)

			end
		end
	end

	if character then

		for _, object in ipairs(
			character:GetChildren()
		) do

			if object:IsA("Tool") then

				table.insert(
					tools,
					object.Name
				)

			end
		end
	end
end

if CONFIG.ScanTools then
	scanTools()
end

--==================================================
-- GUI CLEANUP
--==================================================

local playerGui =
	LocalPlayer:WaitForChild("PlayerGui")

local oldGui =
	playerGui:FindFirstChild("FTPHub")

if oldGui then
	oldGui:Destroy()
end

--==================================================
-- SCREEN GUI
--==================================================

local gui = Instance.new("ScreenGui")

gui.Name = "FTPHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 999
gui.Parent = playerGui

--==================================================
-- LOGO BUTTON
--==================================================

local logoButton = Instance.new("ImageButton")

logoButton.Name = "HorseLogo"

logoButton.Size =
	UDim2.fromOffset(58, 58)

logoButton.Position =
	UDim2.new(0, 15, 0.5, -29)

logoButton.BackgroundColor3 =
	Color3.fromRGB(8, 8, 8)

logoButton.BorderSizePixel = 0

logoButton.Image =
	CONFIG.LOGO_ASSET

logoButton.ScaleType =
	Enum.ScaleType.Fit

logoButton.Visible = false

logoButton.Parent = gui

local logoCorner =
	Instance.new("UICorner")

logoCorner.CornerRadius =
	UDim.new(1, 0)

logoCorner.Parent =
	logoButton

local logoStroke =
	Instance.new("UIStroke")

logoStroke.Color =
	Color3.fromRGB(0, 255, 0)

logoStroke.Thickness = 2

logoStroke.Parent =
	logoButton

--==================================================
-- MAIN FRAME
--==================================================

local frame = Instance.new("Frame")

frame.Name = "Main"

frame.Size =
	UDim2.new(
		0.9,
		0,
		0.75,
		0
	)

frame.Position =
	UDim2.new(
		0.05,
		0,
		0.12,
		0
	)

frame.BackgroundColor3 =
	Color3.fromRGB(8, 8, 8)

frame.BackgroundTransparency =
	0.03

frame.BorderSizePixel = 0

frame.Parent = gui

local frameCorner =
	Instance.new("UICorner")

frameCorner.CornerRadius =
	UDim.new(0, 14)

frameCorner.Parent =
	frame

local frameStroke =
	Instance.new("UIStroke")

frameStroke.Color =
	Color3.fromRGB(0, 255, 0)

frameStroke.Thickness = 2

frameStroke.Parent =
	frame

--==================================================
-- TITLE BAR
--==================================================

local titleBar =
	Instance.new("Frame")

titleBar.Name = "TitleBar"

titleBar.Size =
	UDim2.new(1, 0, 0, 55)

titleBar.BackgroundTransparency = 1

titleBar.Parent =
	frame

local title =
	Instance.new("TextLabel")

title.Size =
	UDim2.new(1, -70, 1, 0)

title.Position =
	UDim2.fromOffset(12, 0)

title.BackgroundTransparency = 1

title.Text =
	"FTP HUB  //  DIAGNOSTIC"

title.TextColor3 =
	Color3.fromRGB(0, 255, 0)

title.Font =
	Enum.Font.Code

title.TextScaled = true

title.TextXAlignment =
	Enum.TextXAlignment.Left

title.Parent =
	titleBar

--==================================================
-- CLOSE / HIDE BUTTON
--==================================================

local closeButton =
	Instance.new("TextButton")

closeButton.Name = "Close"

closeButton.Size =
	UDim2.fromOffset(38, 38)

closeButton.Position =
	UDim2.new(1, -47, 0, 8)

closeButton.BackgroundColor3 =
	Color3.fromRGB(30, 30, 30)

closeButton.Text = "X"

closeButton.TextColor3 =
	Color3.fromRGB(255, 80, 80)

closeButton.Font =
	Enum.Font.Code

closeButton.TextSize = 20

closeButton.Parent =
	titleBar

local closeCorner =
	Instance.new("UICorner")

closeCorner.CornerRadius =
	UDim.new(0, 8)

closeCorner.Parent =
	closeButton

--==================================================
-- STATUS BAR
--==================================================

local status =
	Instance.new("TextLabel")

status.Name = "Status"

status.Size =
	UDim2.new(1, -20, 0, 32)

status.Position =
	UDim2.fromOffset(10, 57)

status.BackgroundTransparency = 1

status.Text =
	"● MONITORING"

status.TextColor3 =
	Color3.fromRGB(100, 255, 100)

status.Font =
	Enum.Font.Code

status.TextSize = 16

status.TextXAlignment =
	Enum.TextXAlignment.Left

status.Parent =
	frame

--==================================================
-- INFO
--==================================================

local info =
	Instance.new("TextLabel")

info.Name = "Info"

info.Size =
	UDim2.new(1, -20, 0, 60)

info.Position =
	UDim2.fromOffset(10, 88)

info.BackgroundTransparency = 1

info.TextColor3 =
	Color3.fromRGB(190, 190, 190)

info.Font =
	Enum.Font.Code

info.TextSize = 14

info.TextXAlignment =
	Enum.TextXAlignment.Left

info.TextYAlignment =
	Enum.TextYAlignment.Top

info.Parent =
	frame

--==================================================
-- SCROLLING FRAME
--==================================================

local scroll =
	Instance.new("ScrollingFrame")

scroll.Name =
	"EventLog"

scroll.Size =
	UDim2.new(
		1,
		-20,
		1,
		-158
	)

scroll.Position =
	UDim2.fromOffset(10, 153)

scroll.BackgroundColor3 =
	Color3.fromRGB(3, 3, 3)

scroll.BackgroundTransparency =
	0.1

scroll.BorderSizePixel = 0

scroll.ScrollBarThickness = 8

scroll.ScrollBarImageColor3 =
	Color3.fromRGB(0, 255, 0)

scroll.ScrollingDirection =
	Enum.ScrollingDirection.Y

scroll.AutomaticCanvasSize =
	Enum.AutomaticSize.Y

scroll.CanvasSize =
	UDim2.new(0, 0, 0, 0)

scroll.Active = true

scroll.Parent =
	frame

local scrollCorner =
	Instance.new("UICorner")

scrollCorner.CornerRadius =
	UDim.new(0, 10)

scrollCorner.Parent =
	scroll

local padding =
	Instance.new("UIPadding")

padding.PaddingTop =
	UDim.new(0, 8)

padding.PaddingBottom =
	UDim.new(0, 8)

padding.PaddingLeft =
	UDim.new(0, 8)

padding.PaddingRight =
	UDim.new(0, 8)

padding.Parent =
	scroll

local layout =
	Instance.new("UIListLayout")

layout.Padding =
	UDim.new(0, 3)

layout.SortOrder =
	Enum.SortOrder.LayoutOrder

layout.Parent =
	scroll

--==================================================
-- EVENT LOG STORAGE
--==================================================

local eventLabels = {}
local eventCounter = 0

local function timestamp()

	return os.date("%H:%M:%S")

end

local function addEvent(eventType, message)

	eventCounter += 1

	local text =
		"[" ..
		timestamp() ..
		"] " ..
		"[" ..
		LocalPlayer.Name ..
		"] " ..
		eventType ..
		" | " ..
		message

	local label =
		Instance.new("TextLabel")

	label.Size =
		UDim2.new(1, -4, 0, 24)

	label.BackgroundTransparency = 1

	label.Text =
		text

	label.TextColor3 =
		Color3.fromRGB(
			200,
			255,
			200
		)

	label.Font =
		Enum.Font.Code

	label.TextSize = 13

	label.TextXAlignment =
		Enum.TextXAlignment.Left

	label.TextWrapped = false

	label.LayoutOrder =
		eventCounter

	label.Parent =
		scroll

	table.insert(
		eventLabels,
		label
	)

	if #eventLabels >
		CONFIG.MaxLogs then

		local old =
			table.remove(
				eventLabels,
				1
			)

		if old then
			old:Destroy()
		end
	end

	task.defer(function()

		if scroll.Parent then

			scroll.CanvasPosition =
				Vector2.new(
					0,
					math.max(
						0,
						scroll.AbsoluteCanvasSize.Y
						- scroll.AbsoluteWindowSize.Y
					)
				)

		end
	end)

end

--==================================================
-- INITIAL INFO
--==================================================

info.Text =
	"PlaceId : " ..
	tostring(game.PlaceId) ..
	"\nPlayer  : " ..
	LocalPlayer.Name ..
	"\nRemotes : " ..
	tostring(#remoteResults) ..
	"    Tools : " ..
	tostring(#tools)

--==================================================
-- INITIAL EVENT
--==================================================

addEvent(
	"INIT",
	"Diagnostic client started"
)

addEvent(
	"PLAYER",
	"UserId=" ..
	tostring(LocalPlayer.UserId)
)

if humanoid then

	addEvent(
		"CHARACTER",
		"Humanoid detected"
	)

	addEvent(
		"HEALTH",
		tostring(humanoid.Health) ..
		"/" ..
		tostring(humanoid.MaxHealth)
	)

	addEvent(
		"MOVEMENT",
		"WalkSpeed=" ..
		tostring(humanoid.WalkSpeed) ..
		" JumpPower=" ..
		tostring(humanoid.JumpPower)
	)

end

--==================================================
-- REMOTE RESULTS
--==================================================

for _, remote in ipairs(
	remoteResults
) do

	addEvent(
		"REMOTE",
		remote.Class ..
		" | " ..
		remote.Path
	)

end

--==================================================
-- TOOL EVENTS
--==================================================

local function toolEquipped(tool)

	if not tool then
		return
	end

	addEvent(
		"TOOL EQUIP",
		tool.Name
	)

end

local function toolUnequipped(tool)

	if not tool then
		return
	end

	addEvent(
		"TOOL UNEQUIP",
		tool.Name
	)

end

local function connectTool(tool)

	if not tool:IsA("Tool") then
		return
	end

	tool.Equipped:Connect(
		function()
			toolEquipped(tool)
		end
	)

	tool.Unequipped:Connect(
		function()
			toolUnequipped(tool)
		end
	)

end

local backpack =
	LocalPlayer:FindFirstChild("Backpack")

if backpack then

	for _, object in ipairs(
		backpack:GetChildren()
	) do

		connectTool(object)

	end

	backpack.ChildAdded:Connect(
		function(object)

			if object:IsA("Tool") then

				connectTool(object)

				addEvent(
					"TOOL",
					"Added: " ..
					object.Name
				)

			end

		end
	)

end

--==================================================
-- CHARACTER CHILD MONITOR
--==================================================

local function monitorCharacter(newCharacter)

	character = newCharacter

	task.wait(0.3)

	refreshCharacter()

	addEvent(
		"CHARACTER",
		"CharacterAdded"
	)

	if humanoid then

		addEvent(
			"HEALTH",
			"Initial=" ..
			tostring(humanoid.Health)
		)

		addEvent(
			"MOVEMENT",
			"WalkSpeed=" ..
			tostring(humanoid.WalkSpeed) ..
			" JumpPower=" ..
			tostring(humanoid.JumpPower)
		)

		humanoid.ChildAdded:Connect(
			function(object)

				addEvent(
					"CHARACTER",
					"Humanoid child + " ..
					object.Name
				)

			end
		)

		humanoid:GetPropertyChangedSignal(
			"WalkSpeed"
		):Connect(
			function()

				addEvent(
					"MOVEMENT",
					"WalkSpeed changed -> " ..
					tostring(humanoid.WalkSpeed)
				)

			end
		)

		humanoid:GetPropertyChangedSignal(
			"JumpPower"
		):Connect(
			function()

				addEvent(
					"MOVEMENT",
					"JumpPower changed -> " ..
					tostring(humanoid.JumpPower)
				)

			end
		)

		humanoid.HealthChanged:Connect(
			function(newHealth)

				addEvent(
					"HEALTH",
					"HP -> " ..
					tostring(
						math.floor(newHealth)
					)
				)

			end
		)

		humanoid.StateChanged:Connect(
			function(oldState, newState)

				if newState ==
					Enum.HumanoidStateType.Jumping then

					addEvent(
						"JUMP",
						tostring(newState)
					)

				elseif newState ==
					Enum.HumanoidStateType.Freefall then

					addEvent(
						"FALL",
						tostring(newState)
					)

				elseif newState ==
					Enum.HumanoidStateType.Landed then

					addEvent(
						"LAND",
						"from " ..
						tostring(oldState)
					)

				end

			end
		)

	end

	for _, object in ipairs(
		newCharacter:GetChildren()
	) do

		if object:IsA("Tool") then

			connectTool(object)

		end

	end

	newCharacter.ChildAdded:Connect(
		function(object)

			if object:IsA("Tool") then

				connectTool(object)

				addEvent(
					"CHARACTER",
					"Tool added: " ..
					object.Name
				)

			else

				addEvent(
					"CHARACTER",
					"Added: " ..
					object.Name
				)

			end

		end
	)

	newCharacter.ChildRemoved:Connect(
		function(object)

			addEvent(
				"CHARACTER",
				"Removed: " ..
				object.Name
			)

		end
	)

end

LocalPlayer.CharacterAdded:Connect(
	monitorCharacter
)

--==================================================
-- INPUT MONITOR
--==================================================

UserInputService.InputBegan:Connect(
	function(input, processed)

		local inputName =
			tostring(input.KeyCode)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			inputName = "MouseButton1"

		elseif input.UserInputType ==
			Enum.UserInputType.MouseButton2 then

			inputName = "MouseButton2"

		elseif input.UserInputType ==
			Enum.UserInputType.MouseButton3 then

			inputName = "MouseButton3"

		elseif input.UserInputType ==
			Enum.UserInputType.Touch then

			inputName = "Touch"

		end

		addEvent(
			"INPUT DOWN",
			inputName ..
			" processed=" ..
			tostring(processed)
		)

	end
)

UserInputService.InputEnded:Connect(
	function(input, processed)

		local inputName =
			tostring(input.KeyCode)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			inputName = "MouseButton1"

		elseif input.UserInputType ==
			Enum.UserInputType.MouseButton2 then

			inputName = "MouseButton2"

		elseif input.UserInputType ==
			Enum.UserInputType.Touch then

			inputName = "Touch"

		end

		addEvent(
			"INPUT UP",
			inputName ..
			" processed=" ..
			tostring(processed)
		)

	end
)

--==================================================
-- POSITION / MOVEMENT MONITOR
--==================================================

local lastPosition = nil
local lastPositionLog = 0

local function updatePosition()

	if not rootPart then
		return
	end

	local position =
		rootPart.Position

	if not lastPosition then

		lastPosition =
			position

		return
	end

	local distance =
		(position - lastPosition).Magnitude

	local now =
		os.clock()

	if distance > 0.05
		and now - lastPositionLog
		>= CONFIG.PositionInterval then

		lastPositionLog =
			now

		addEvent(
			"POSITION",
			string.format(
				"X=%.2f Y=%.2f Z=%.2f",
				position.X,
				position.Y,
				position.Z
			)
		)

		lastPosition =
			position
	end

end

--==================================================
-- GUI STATUS LOOP
--==================================================

local heartbeatConnection

heartbeatConnection =
	RunService.Heartbeat:Connect(
		function()

			if not gui.Parent then

				if heartbeatConnection then
					heartbeatConnection:Disconnect()
				end

				return
			end

			if humanoid then

				status.Text =
					"● MONITORING  |  HP " ..
					math.floor(
						humanoid.Health
					) ..
					"/" ..
					math.floor(
						humanoid.MaxHealth
					)

			end

			updatePosition()

		end
	)

--==================================================
-- HIDE / SHOW
--==================================================

closeButton.MouseButton1Click:Connect(
	function()

		frame.Visible = false
		logoButton.Visible = true

	end
)

logoButton.MouseButton1Click:Connect(
	function()

		frame.Visible = true
		logoButton.Visible = false

	end
)

--==================================================
-- DRAG WINDOW
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

titleBar.InputBegan:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			dragging = true

			dragStart =
				input.Position

			startPosition =
				frame.Position

		end

	end
)

titleBar.InputEnded:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

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
			Enum.UserInputType.MouseMovement
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			updateDrag(input)

		end

	end
)

--==================================================
-- FINAL REPORT
--==================================================

print("========================================")
print("       FTP HUB DIAGNOSTIC READY")
print("========================================")
print("PlaceId :", game.PlaceId)
print("Player  :", LocalPlayer.Name)
print("Remotes :", #remoteResults)
print("Tools   :", #tools)
print("========================================")

--==================================================
-- WELCOME
--==================================================

task.delay(
	CONFIG.WelcomeDuration,
	function()

		if gui and gui.Parent then
			-- Jangan destroy.
			-- Tetap bisa dibuka melalui logo.
			frame.Visible = false
			logoButton.Visible = true
		end

	end
)
