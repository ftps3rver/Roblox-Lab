--==================================================
-- FTP HUB - PENTEST / DIAGNOSTIC CLIENT
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
print("        FTP HUB PENTEST STARTING")
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
	ShowDiagnostics = true,
	ScanRemotes = true,
	ScanTools = true
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

local humanoid = character:FindFirstChildOfClass("Humanoid")
local rootPart = character:FindFirstChild("HumanoidRootPart")

if humanoid then
	log("Humanoid: OK")
	log("Health:", humanoid.Health)
	log("MaxHealth:", humanoid.MaxHealth)
	log("WalkSpeed:", humanoid.WalkSpeed)
	log("JumpPower:", humanoid.JumpPower)
else
	warning("Humanoid tidak ditemukan.")
end

if rootPart then
	log("HumanoidRootPart: OK")
else
	warning("HumanoidRootPart tidak ditemukan.")
end

--==================================================
-- REMOTE SCANNER
--==================================================

local remoteResults = {}

local function scanRemotes()

	table.clear(remoteResults)

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")

	if not remotes then
		warning("Folder 'Remotes' tidak ditemukan.")
		return nil
	end

	log("Remotes ditemukan:", remotes:GetFullName())

	for _, object in ipairs(remotes:GetDescendants()) do

		if object:IsA("RemoteEvent") then

			table.insert(remoteResults, {
				Name = object.Name,
				Class = "RemoteEvent",
				Path = object:GetFullName()
			})

			log(
				"[RemoteEvent]",
				object:GetFullName()
			)

		elseif object:IsA("RemoteFunction") then

			table.insert(remoteResults, {
				Name = object.Name,
				Class = "RemoteFunction",
				Path = object:GetFullName()
			})

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

	for _, name in ipairs(knownRemoteNames) do

		local object = remotes:FindFirstChild(name)

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
-- TOOL / WEAPON SCANNER
--==================================================

local tools = {}

local function scanTools()

	table.clear(tools)

	local backpack = LocalPlayer:FindFirstChild("Backpack")

	if backpack then

		for _, object in ipairs(backpack:GetChildren()) do

			if object:IsA("Tool") then

				table.insert(tools, object.Name)

				log(
					"[BACKPACK TOOL]",
					object.Name
				)

			end
		end
	end

	if character then

		for _, object in ipairs(character:GetChildren()) do

			if object:IsA("Tool") then

				table.insert(tools, object.Name)

				log(
					"[EQUIPPED TOOL]",
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
-- MAIN FRAME
--==================================================

local frame = Instance.new("Frame")

frame.Name = "Main"
frame.Size = UDim2.fromOffset(560, 250)
frame.Position = UDim2.new(0.5, -280, 0, 35)

frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
frame.BackgroundTransparency = 0.05

frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")

corner.CornerRadius = UDim.new(0, 14)
corner.Parent = frame

local stroke = Instance.new("UIStroke")

stroke.Color = Color3.fromRGB(0, 255, 0)
stroke.Thickness = 2

stroke.Parent = frame

--==================================================
-- TITLE
--==================================================

local title = Instance.new("TextLabel")

title.Name = "Title"

title.Size = UDim2.new(1, -20, 0, 65)
title.Position = UDim2.fromOffset(10, 10)

title.BackgroundTransparency = 1

title.Text = "WELCOME TO FTP HUB"

title.TextColor3 =
	Color3.fromRGB(0, 255, 0)

title.Font = Enum.Font.Code
title.TextScaled = true

title.Parent = frame

--==================================================
-- STATUS
--==================================================

local status = Instance.new("TextLabel")

status.Name = "Status"

status.Size = UDim2.new(1, -20, 0, 35)
status.Position = UDim2.fromOffset(10, 78)

status.BackgroundTransparency = 1

status.Text =
	"● PENTEST MODE  |  PLACE VERIFIED"

status.TextColor3 =
	Color3.fromRGB(100, 255, 100)

status.Font = Enum.Font.Code
status.TextScaled = true

status.Parent = frame

--==================================================
-- INFO
--==================================================

local info = Instance.new("TextLabel")

info.Name = "Info"

info.Size = UDim2.new(1, -40, 0, 90)
info.Position = UDim2.fromOffset(20, 125)

info.BackgroundTransparency = 1

info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top

info.TextColor3 =
	Color3.fromRGB(200, 200, 200)

info.Font = Enum.Font.Code
info.TextSize = 16

info.Text =
	"PlaceId : " .. tostring(game.PlaceId)
	.. "\nPlayer  : " .. LocalPlayer.Name
	.. "\nRemotes : " .. tostring(#remoteResults)
	.. "\nTools   : " .. tostring(#tools)

info.Parent = frame

--==================================================
-- CLOSE BUTTON
--==================================================

local closeButton = Instance.new("TextButton")

closeButton.Name = "Close"

closeButton.Size = UDim2.fromOffset(32, 32)
closeButton.Position = UDim2.new(1, -42, 0, 10)

closeButton.BackgroundColor3 =
	Color3.fromRGB(30, 30, 30)

closeButton.Text = "X"

closeButton.TextColor3 =
	Color3.fromRGB(255, 80, 80)

closeButton.Font = Enum.Font.Code
closeButton.TextSize = 18

closeButton.Parent = frame

local closeCorner = Instance.new("UICorner")

closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(
	function()

		gui:Destroy()

	end
)

--==================================================
-- DRAG SYSTEM
--==================================================

local dragging = false
local dragStart
local startPosition

local function updateDrag(input)

	local delta =
		input.Position - dragStart

	frame.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset + delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset + delta.Y
	)
end

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

		if dragging and
			input.UserInputType ==
			Enum.UserInputType.MouseMovement then

			updateDrag(input)

		end

	end
)

--==================================================
-- CHARACTER UPDATE
--==================================================

LocalPlayer.CharacterAdded:Connect(
	function(newCharacter)

		character = newCharacter

		task.wait(0.5)

		humanoid =
			character:FindFirstChildOfClass(
				"Humanoid"
			)

		rootPart =
			character:FindFirstChild(
				"HumanoidRootPart"
			)

		if humanoid then
			log(
				"Character respawned.",
				"Health:",
				humanoid.Health
			)
		end

		if CONFIG.ScanTools then
			scanTools()
		end
	end
)

--==================================================
-- PERIODIC STATUS
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

				local currentHealth =
					math.floor(humanoid.Health)

				local maxHealth =
					math.floor(humanoid.MaxHealth)

				status.Text =
					"● PENTEST MODE  |  HP "
					.. currentHealth
					.. "/"
					.. maxHealth

			end
		end
	)

--==================================================
-- FINAL REPORT
--==================================================

print("========================================")
print("        FTP HUB DIAGNOSTIC READY")
print("========================================")

print("PlaceId verified :", game.PlaceId)
print("Player           :", LocalPlayer.Name)
print("Remote count     :", #remoteResults)
print("Tool count       :", #tools)

for name, found in pairs(knownRemoteStatus) do

	print(
		name,
		"=",
		found and "FOUND" or "MISSING"
	)

end

print("========================================")

--==================================================
-- AUTO REMOVE
--==================================================

task.delay(
	CONFIG.WelcomeDuration,
	function()

		if gui and gui.Parent then
			gui:Destroy()
		end

	end
)
