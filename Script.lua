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
print("        FTP HUB DIAGNOSTIC STARTING")
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
	WelcomeDuration = 8,

	Debug = true,

	ScanRemotes = true,
	ScanTools = true,

	PositionInterval = 0.5,

	MaxLogEntries = 300,

	-- Masukkan asset Roblox di sini kalau sudah upload
	-- contoh:
	-- "rbxassetid://1234567890"
	HorseImage = ""
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
-- CHARACTER REFERENCES
--==================================================

local character =
	LocalPlayer.Character
	or LocalPlayer.CharacterAdded:Wait()

local humanoid =
	character:FindFirstChildOfClass("Humanoid")

local rootPart =
	character:FindFirstChild("HumanoidRootPart")

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
-- KNOWN REMOTES
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
				"[FOUND]",
				name,
				"-",
				object.ClassName
			)

		else

			knownRemoteStatus[name] = false

			warning(
				"[MISSING]",
				name
			)

		end
	end

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
	UDim2.fromOffset(620, 430)

frame.Position =
	UDim2.new(
		0.5,
		-310,
		0,
		35
	)

frame.BackgroundColor3 =
	Color3.fromRGB(8, 8, 8)

frame.BackgroundTransparency = 0.03

frame.BorderSizePixel = 0

frame.Parent = gui

--==================================================
-- CORNER
--==================================================

local corner =
	Instance.new("UICorner")

corner.CornerRadius =
	UDim.new(0, 14)

corner.Parent = frame

--==================================================
-- BORDER
--==================================================

local stroke =
	Instance.new("UIStroke")

stroke.Color =
	Color3.fromRGB(0, 255, 0)

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
		-100,
		0,
		55
	)

title.Position =
	UDim2.fromOffset(
		65,
		8
	)

title.BackgroundTransparency = 1

title.Text =
	"FTP HUB"

title.TextColor3 =
	Color3.fromRGB(
		0,
		255,
		0
	)

title.Font =
	Enum.Font.Code

title.TextSize = 28

title.TextXAlignment =
	Enum.TextXAlignment.Left

title.Parent = frame

--==================================================
-- SUBTITLE
--==================================================

local subtitle =
	Instance.new("TextLabel")

subtitle.Name = "Subtitle"

subtitle.Size =
	UDim2.new(
		1,
		-100,
		0,
		22
	)

subtitle.Position =
	UDim2.fromOffset(
		67,
		38
	)

subtitle.BackgroundTransparency = 1

subtitle.Text =
	"REALTIME ACTIVITY MONITOR"

subtitle.TextColor3 =
	Color3.fromRGB(
		100,
		255,
		100
	)

subtitle.Font =
	Enum.Font.Code

subtitle.TextSize = 12

subtitle.TextXAlignment =
	Enum.TextXAlignment.Left

subtitle.Parent = frame

--==================================================
-- HORSE LOGO
--==================================================

local logoButton =
	Instance.new("TextButton")

logoButton.Name =
	"HorseLogo"

logoButton.Size =
	UDim2.fromOffset(
		48,
		48
	)

logoButton.Position =
	UDim2.fromOffset(
		10,
		10
	)

logoButton.BackgroundColor3 =
	Color3.fromRGB(
		15,
		15,
		15
	)

logoButton.BorderSizePixel = 0

logoButton.Text =
	"♞"

logoButton.TextColor3 =
	Color3.fromRGB(
		0,
		255,
		0
	)

logoButton.Font =
	Enum.Font.Code

logoButton.TextSize = 30

logoButton.Parent = frame

local logoCorner =
	Instance.new("UICorner")

logoCorner.CornerRadius =
	UDim.new(
		0,
		10
	)

logoCorner.Parent =
	logoButton

local logoStroke =
	Instance.new("UIStroke")

logoStroke.Color =
	Color3.fromRGB(
		0,
		255,
		0
	)

logoStroke.Thickness = 1

logoStroke.Parent =
	logoButton

--==================================================
-- OPTIONAL IMAGE
--==================================================

if CONFIG.HorseImage ~= "" then

	logoButton.Text = ""

	local image =
		Instance.new("ImageLabel")

	image.Size =
		UDim2.fromScale(
			1,
			1
		)

	image.BackgroundTransparency = 1

	image.Image =
		CONFIG.HorseImage

	image.Parent =
		logoButton

	local imageCorner =
		Instance.new("UICorner")

	imageCorner.CornerRadius =
		UDim.new(
			0,
			10
		)

	imageCorner.Parent =
		image
end

--==================================================
-- STATUS
--==================================================

local status =
	Instance.new("TextLabel")

status.Name = "Status"

status.Size =
	UDim2.new(
		1,
		-30,
		0,
		30
	)

status.Position =
	UDim2.fromOffset(
		15,
		62
	)

status.BackgroundTransparency = 1

status.Text =
	"● MONITORING"

status.TextColor3 =
	Color3.fromRGB(
		100,
		255,
		100
	)

status.Font =
	Enum.Font.Code

status.TextSize = 15

status.TextXAlignment =
	Enum.TextXAlignment.Left

status.Parent = frame

--==================================================
-- EVENT LOG
--==================================================

local eventLog =
	Instance.new("ScrollingFrame")

eventLog.Name =
	"EventLog"

eventLog.Size =
	UDim2.new(
		1,
		-30,
		0,
		300
	)

eventLog.Position =
	UDim2.fromOffset(
		15,
		98
	)

eventLog.BackgroundColor3 =
	Color3.fromRGB(
		3,
		3,
		3
	)

eventLog.BackgroundTransparency =
	0.15

eventLog.BorderSizePixel = 0

eventLog.ScrollBarThickness = 7

eventLog.ScrollBarImageColor3 =
	Color3.fromRGB(
		0,
		255,
		0
	)

eventLog.ScrollingDirection =
	Enum.ScrollingDirection.Y

eventLog.AutomaticCanvasSize =
	Enum.AutomaticSize.Y

eventLog.CanvasSize =
	UDim2.new(
		0,
		0,
		0,
		0
	)

eventLog.Parent = frame

local logCorner =
	Instance.new("UICorner")

logCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

logCorner.Parent =
	eventLog

--==================================================
-- LOG LAYOUT
--==================================================

local logLayout =
	Instance.new("UIListLayout")

logLayout.Padding =
	UDim.new(
		0,
		1
	)

logLayout.SortOrder =
	Enum.SortOrder.LayoutOrder

logLayout.Parent =
	eventLog

--==================================================
-- EVENT LOGGER
--==================================================

local eventCounter = 0

local function addEvent(
	eventType,
	message
)

	eventCounter += 1

	local timestamp =
		os.date(
			"%H:%M:%S"
		)

	local entry =
		Instance.new("TextLabel")

	entry.Name =
		"Event_" ..
		tostring(eventCounter)

	entry.Size =
		UDim2.new(
			1,
			-12,
			0,
			22
		)

	entry.BackgroundTransparency =
		1

	entry.TextXAlignment =
		Enum.TextXAlignment.Left

	entry.TextYAlignment =
		Enum.TextYAlignment.Center

	entry.Font =
		Enum.Font.Code

	entry.TextSize = 13

	entry.TextColor3 =
		Color3.fromRGB(
			180,
			255,
			180
		)

	entry.Text =
		"[" ..
		timestamp ..
		"] [" ..
		tostring(eventType) ..
		"] " ..
		tostring(message)

	entry.Parent =
		eventLog

	--==================================================
	-- LIMIT LOG
	--==================================================

	local children =
		eventLog:GetChildren()

	local entries = {}

	for _, child in ipairs(children) do

		if child:IsA("TextLabel") then

			table.insert(
				entries,
				child
			)

		end
	end

	if #entries >
		CONFIG.MaxLogEntries then

		table.sort(
			entries,
			function(a, b)

				return a.LayoutOrder
					<
					b.LayoutOrder

			end
		)

		entries[1]:Destroy()
	end

	--==================================================
	-- AUTO SCROLL
	--==================================================

	task.defer(
		function()

			if not eventLog.Parent then
				return
			end

			eventLog.CanvasPosition =
				Vector2.new(
					0,
					math.max(
						0,
						eventLog.AbsoluteCanvasSize.Y
						-
						eventLog.AbsoluteWindowSize.Y
					)
				)

		end
	)

	if CONFIG.Debug then

		log(
			eventType,
			message
		)

	end
end

--==================================================
-- INITIAL EVENT
--==================================================

addEvent(
	"START",
	"Diagnostic monitor started"
)

addEvent(
	"PLAYER",
	LocalPlayer.Name
)

addEvent(
	"PLACE",
	tostring(game.PlaceId)
)

addEvent(
	"REMOTES",
	tostring(#remoteResults)
		.. " objects found"
)

addEvent(
	"TOOLS",
	tostring(#tools)
		.. " tools found"
)

--==================================================
-- CHARACTER MONITOR
--==================================================

local connections = {}

local function disconnectAll()

	for _, connection in ipairs(
		connections
	) do

		if connection then
			connection:Disconnect()
		end

	end

	table.clear(connections)

end

--==================================================
-- TOOL MONITOR
--==================================================

local function watchTool(tool)

	if not tool:IsA("Tool") then
		return
	end

	table.insert(
		connections,
		tool.Equipped:Connect(
			function()

				addEvent(
					"TOOL",
					"EQUIPPED: "
						.. tool.Name
				)

			end
		)
	)

	table.insert(
		connections,
		tool.Unequipped:Connect(
			function()

				addEvent(
					"TOOL",
					"UNEQUIPPED: "
						.. tool.Name
				)

			end
		)
	)

end

local function scanCurrentTools()

	if not character then
		return
	end

	local backpack =
		LocalPlayer:FindFirstChild(
			"Backpack"
		)

	if backpack then

		for _, tool in ipairs(
			backpack:GetChildren()
		) do

			watchTool(tool)

		end
	end

	for _, tool in ipairs(
		character:GetChildren()
	) do

		watchTool(tool)

	end
end

--==================================================
-- CHARACTER MONITOR SETUP
--==================================================

local function setupCharacter(
	newCharacter
)

	disconnectAll()

	character =
		newCharacter

	addEvent(
		"CHARACTER",
		"Character changed"
	)

	humanoid =
		character:WaitForChild(
			"Humanoid",
			5
		)

	rootPart =
		character:WaitForChild(
			"HumanoidRootPart",
			5
		)

	if not humanoid then

		warning(
			"Humanoid tidak ditemukan."
		)

		return
	end

	if rootPart then

		addEvent(
			"CHARACTER",
			"HumanoidRootPart OK"
		)

	end

	--==================================================
	-- HEALTH
	--==================================================

	local lastHealth =
		humanoid.Health

	table.insert(
		connections,
		humanoid.HealthChanged:Connect(
			function(newHealth)

				if newHealth ~= lastHealth then

					addEvent(
						"HEALTH",
						string.format(
							"%.1f -> %.1f",
							lastHealth,
							newHealth
						)
					)

					lastHealth =
						newHealth

				end

			end
		)
	)

	--==================================================
	-- WALKSPEED
	--==================================================

	local lastWalkSpeed =
		humanoid.WalkSpeed

	table.insert(
		connections,
		humanoid:GetPropertyChangedSignal(
			"WalkSpeed"
		):Connect(
			function()

				local newValue =
					humanoid.WalkSpeed

				if newValue ~= lastWalkSpeed then

					addEvent(
						"MOVEMENT",
						"WalkSpeed "
							.. tostring(
								lastWalkSpeed
							)
							.. " -> "
							.. tostring(
								newValue
							)
					)

					lastWalkSpeed =
						newValue

				end

			end
		)
	)

	--==================================================
	-- JUMP POWER
	--==================================================

	local lastJumpPower =
		humanoid.JumpPower

	table.insert(
		connections,
		humanoid:GetPropertyChangedSignal(
			"JumpPower"
		):Connect(
			function()

				local newValue =
					humanoid.JumpPower

				if newValue ~= lastJumpPower then

					addEvent(
						"MOVEMENT",
						"JumpPower "
							.. tostring(
								lastJumpPower
							)
							.. " -> "
							.. tostring(
								newValue
							)
					)

					lastJumpPower =
						newValue

				end

			end
		)
	)

	--==================================================
	-- HUMANOID STATES
	--==================================================

	table.insert(
		connections,
		humanoid.StateChanged:Connect(
			function(
				oldState,
				newState
			)

				if newState ==
					Enum.HumanoidStateType.Jumping then

					addEvent(
						"JUMP",
						"Jumping"
					)

				elseif newState ==
					Enum.HumanoidStateType.Freefall then

					addEvent(
						"FALL",
						"Freefall"
					)

				elseif newState ==
					Enum.HumanoidStateType.Landed then

					addEvent(
						"LAND",
						"Landed"
					)

				elseif newState ==
					Enum.HumanoidStateType.Dead then

					addEvent(
						"CHARACTER",
						"Humanoid died"
					)

				end

			end
		)
	)

	--==================================================
	-- CHARACTER CHILDREN
	--==================================================

	table.insert(
		connections,
		character.ChildAdded:Connect(
			function(object)

				if object:IsA("Tool") then

					addEvent(
						"TOOL",
						"Added: "
							.. object.Name
					)

					watchTool(object)

				else

					addEvent(
						"CHARACTER",
						"Added: "
							.. object.Name
					)

				end

			end
		)
	)

	table.insert(
		connections,
		character.ChildRemoved:Connect(
			function(object)

				addEvent(
					"CHARACTER",
					"Removed: "
						.. object.Name
				)

			end
		)
	)

	--==================================================
	-- TOOL INITIAL SCAN
	--==================================================

	scanCurrentTools()

	--==================================================
	-- POSITION MONITOR
	--==================================================

	task.spawn(
		function()

			local lastPosition = nil

			while
				gui
				and gui.Parent
				and character == newCharacter
			do

				task.wait(
					CONFIG.PositionInterval
				)

				if rootPart
					and rootPart.Parent then

					local position =
						rootPart.Position

					if not lastPosition
						or (
							position
							-
							lastPosition
						).Magnitude > 1 then

						addEvent(
							"POSITION",
							string.format(
								"X=%.1f Y=%.1f Z=%.1f",
								position.X,
								position.Y,
								position.Z
							)
						)

						lastPosition =
							position

					end

				end

			end

		end
	)

end

--==================================================
-- INITIAL CHARACTER
--==================================================

setupCharacter(character)

--==================================================
-- CHARACTER ADDED
--==================================================

LocalPlayer.CharacterAdded:Connect(
	function(newCharacter)

		task.wait(0.3)

		setupCharacter(
			newCharacter
		)

	end
)

--==================================================
-- INPUT MONITOR
--==================================================

UserInputService.InputBegan:Connect(
	function(
		input,
		gameProcessed
	)

		local inputName =
			tostring(
				input.KeyCode
			)

		if input.UserInputType ==
			Enum.UserInputType.Keyboard then

			addEvent(
				"INPUT",
				"KEY DOWN: "
					.. inputName
					.. (
						gameProcessed
						and " [Processed]"
						or ""
					)
			)

		elseif input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			addEvent(
				"INPUT",
				"MOUSE LEFT DOWN"
			)

		elseif input.UserInputType ==
			Enum.UserInputType.MouseButton2 then

			addEvent(
				"INPUT",
				"MOUSE RIGHT DOWN"
			)

		end

	end
)

UserInputService.InputEnded:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.Keyboard then

			addEvent(
				"INPUT",
				"KEY UP: "
					.. tostring(
						input.KeyCode
					)
			)

		elseif input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			addEvent(
				"INPUT",
				"MOUSE LEFT UP"
			)

		elseif input.UserInputType ==
			Enum.UserInputType.MouseButton2 then

			addEvent(
				"INPUT",
				"MOUSE RIGHT UP"
			)

		end

	end
)

--==================================================
-- DRAG SYSTEM
--==================================================

local dragging = false

local dragStart = nil
local startPosition = nil

local function updateDrag(input)

	local delta =
		input.Position
		-
		dragStart

	frame.Position =
		UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset
				+ delta.X,

			startPosition.Y.Scale,
			startPosition.Y.Offset
				+ delta.Y
		)

end

title.InputBegan:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

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

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1 then

			dragging = false

		end

	end
)

UserInputService.InputChanged:Connect(
	function(input)

		if dragging
			and input.UserInputType ==
				Enum.UserInputType.MouseMovement then

			updateDrag(input)

		end

	end
)

--==================================================
-- CLOSE / OPEN
--==================================================

local panelVisible = true

logoButton.MouseButton1Click:Connect(
	function()

		panelVisible = true

		frame.Visible = true

	end
)

--==================================================
-- CLOSE BUTTON
--==================================================

local closeButton =
	Instance.new("TextButton")

closeButton.Name =
	"Close"

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

closeButton.BorderSizePixel = 0

closeButton.Text =
	"X"

closeButton.TextColor3 =
	Color3.fromRGB(
		255,
		80,
		80
	)

closeButton.Font =
	Enum.Font.Code

closeButton.TextSize = 18

closeButton.Parent = frame

local closeCorner =
	Instance.new("UICorner")

closeCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

closeCorner.Parent =
	closeButton

closeButton.MouseButton1Click:Connect(
	function()

		panelVisible = false

		frame.Visible = false

	end
)

--==================================================
-- PERIODIC STATUS
--==================================================

local heartbeatConnection

heartbeatConnection =
	RunService.Heartbeat:Connect(
		function()

			if not gui
				or not gui.Parent then

				if heartbeatConnection then

					heartbeatConnection:Disconnect()

				end

				return
			end

			if humanoid
				and humanoid.Parent then

				local hp =
					math.floor(
						humanoid.Health
					)

				local maxHp =
					math.floor(
						humanoid.MaxHealth
					)

				status.Text =
					"● MONITORING  |  HP "
					.. tostring(hp)
					.. "/"
					.. tostring(maxHp)

			end

		end
	)

--==================================================
-- REMOTE INSTANCE WATCHER
--==================================================

if remotes then

	remotes.DescendantAdded:Connect(
		function(object)

			if object:IsA("RemoteEvent")
				or object:IsA("RemoteFunction") then

				addEvent(
					"REMOTE",
					"ADDED: "
						.. object:GetFullName()
				)

			end

		end
	)

	remotes.DescendantRemoving:Connect(
		function(object)

			if object:IsA("RemoteEvent")
				or object:IsA("RemoteFunction") then

				addEvent(
					"REMOTE",
					"REMOVED: "
						.. object:GetFullName()
				)

			end

		end
	)

end

--==================================================
-- FINAL REPORT
--==================================================

print("========================================")
print("       FTP HUB DIAGNOSTIC READY")
print("========================================")

print(
	"PlaceId :",
	game.PlaceId
)

print(
	"Player  :",
	LocalPlayer.Name
)

print(
	"Remotes :",
	#remoteResults
)

print(
	"Tools   :",
	#tools
)

for name, found in pairs(
	knownRemoteStatus
) do

	print(
		name,
		"=",
		found
			and "FOUND"
			or "MISSING"
	)

end

print("========================================")

addEvent(
	"READY",
	"Realtime monitoring active"
)

--==================================================
-- AUTO REMOVE
--==================================================

task.delay(
	CONFIG.WelcomeDuration,
	function()

		-- Jangan destroy GUI.
		-- Hanya biarkan tetap tersedia
		-- lewat logo.

		if gui and gui.Parent then

			-- tetap aktif

		end

	end
)
