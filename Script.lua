--==================================================
-- FTP HUB - ROBLOX SERVER SCRIPT
--==================================================

--==================================================
-- SERVICES
--==================================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--==================================================
-- GAME LOCK
--==================================================

local ALLOWED_PLACE_ID = 89469502395769

print("================================")
print("FTP HUB STARTING")
print("Current PlaceId:", game.PlaceId)
print("Required PlaceId:", ALLOWED_PLACE_ID)
print("================================")

if game.PlaceId ~= ALLOWED_PLACE_ID then
	warn("FTP HUB: Game tidak sesuai.")
	return
end

print("FTP HUB: Game terverifikasi.")

--==================================================
-- MAIN CONFIGURATION
--==================================================

local CONFIG = {
	speed = 15,
	jumpPower = 40,
	maxHealth = 176,
	respawnTime = 3,
	debugMode = false
}

--==================================================
-- REMOTES
--==================================================

local remotes = ReplicatedStorage:FindFirstChild("Remotes")

if not remotes then
	warn("FTP HUB: Folder 'Remotes' tidak ditemukan di ReplicatedStorage.")
	return
end

local damageEvent = remotes:FindFirstChild("DamageEvent")
local healEvent = remotes:FindFirstChild("HealEvent")
local respawnEvent = remotes:FindFirstChild("RespawnEvent")
local damageEffect = remotes:FindFirstChild("DamageEffect")

if not damageEvent then
	warn("FTP HUB: DamageEvent tidak ditemukan.")
	return
end

if not healEvent then
	warn("FTP HUB: HealEvent tidak ditemukan.")
	return
end

if not respawnEvent then
	warn("FTP HUB: RespawnEvent tidak ditemukan.")
	return
end

print("FTP HUB: RemoteEvent berhasil ditemukan.")

--==================================================
-- WEAPON DEFINITIONS
--==================================================

local weapons = {
	{
		name = "Sword",
		damage = 15,
		cooldown = 0.8,
		range = 4
	},

	{
		name = "Bow",
		damage = 10,
		cooldown = 1.2,
		range = 30
	},

	{
		name = "Staff",
		damage = 25,
		cooldown = 2.5,
		range = 15
	}
}

--==================================================
-- WELCOME GUI
--==================================================

local function createWelcomeGUI(player)

	local playerGui = player:WaitForChild("PlayerGui")

	-- Hapus GUI lama
	local oldGui = playerGui:FindFirstChild("FTPHubGui")

	if oldGui then
		oldGui:Destroy()
	end

	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")

	screenGui.Name = "FTPHubGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = playerGui

	-- Main frame
	local frame = Instance.new("Frame")

	frame.Name = "WelcomeFrame"

	frame.Size = UDim2.new(0, 500, 0, 90)
	frame.Position = UDim2.new(0.5, -250, 0, 40)

	frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	frame.BackgroundTransparency = 0.1

	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	-- Rounded corners
	local corner = Instance.new("UICorner")

	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	-- Green border
	local stroke = Instance.new("UIStroke")

	stroke.Color = Color3.fromRGB(0, 255, 0)
	stroke.Thickness = 2
	stroke.Parent = frame

	-- Text
	local text = Instance.new("TextLabel")

	text.Name = "WelcomeText"

	text.Size = UDim2.new(1, -20, 1, -20)
	text.Position = UDim2.new(0, 10, 0, 10)

	text.BackgroundTransparency = 1

	text.Text = "WELCOME TO FTP HUB"

	text.TextColor3 = Color3.fromRGB(0, 255, 0)
	text.TextScaled = true
	text.Font = Enum.Font.Code

	text.Parent = frame

	-- Hapus GUI setelah 5 detik
	task.delay(5, function()

		if screenGui and screenGui.Parent then
			screenGui:Destroy()
		end

	end)
end

--==================================================
-- DAMAGE CALCULATION
--==================================================

local function calculateDamage(baseDamage, distance, player)

	local character = player.Character

	if not character then
		return 0
	end

	local modifier = 1

	-- Damage falloff
	if distance > 10 then

		modifier = modifier *
			(1 - (distance - 10) * 0.02)

	end

	-- Random variation 90% - 110%
	modifier = modifier *
	(math.random() * 0.2 + 0.9)

	return math.floor(baseDamage * modifier)
end

--==================================================
-- PLAYER SETUP
--==================================================

local function setupPlayer(player)

	if not player or not player.Parent then
		return
	end

	local character =
		player.Character
		or player.CharacterAdded:Wait()

	if not character then
		return
	end

	local humanoid =
		character:WaitForChild("Humanoid")

	--==================================================
	-- PLAYER CONFIGURATION
	--==================================================

	humanoid.WalkSpeed = CONFIG.speed
	humanoid.JumpPower = CONFIG.jumpPower

	humanoid.MaxHealth = CONFIG.maxHealth
	humanoid.Health = CONFIG.maxHealth

	--==================================================
	-- WELCOME GUI
	--==================================================

	createWelcomeGUI(player)

	--==================================================
	-- DAMAGE EVENT
	--==================================================

	-- Cegah setup yang sama membuat koneksi berulang
	local connectionFolder =
		player:FindFirstChild("FTP_HUB_CONNECTIONS")

	if connectionFolder then
		return
	end

	connectionFolder = Instance.new("Folder")
	connectionFolder.Name = "FTP_HUB_CONNECTIONS"
	connectionFolder.Parent = player

	local damageConnection

	damageConnection = damageEvent.OnServerEvent:Connect(
		function(
			playerWhoFired,
			targetPlayer,
			damageAmount,
			weaponIndex
		)

			-- Pastikan event berasal dari player ini
			if playerWhoFired ~= player then
				return
			end

			-- Validasi target
			if not targetPlayer then
				return
			end

			if not targetPlayer:IsA("Player") then
				return
			end

			if not targetPlayer.Character then
				return
			end

			-- Weapon
			local index = tonumber(weaponIndex) or 1

			local weapon = weapons[index]

			if not weapon then
				return
			end

			-- Target humanoid
			local targetHumanoid =
				targetPlayer.Character:FindFirstChildOfClass(
					"Humanoid"
				)

			if not targetHumanoid then
				return
			end

			if targetHumanoid.Health <= 0 then
				return
			end

			-- Attacker root
			if not player.Character then
				return
			end

			local attackerRoot =
				player.Character:FindFirstChild(
					"HumanoidRootPart"
				)

			-- Target root
			local targetRoot =
				targetPlayer.Character:FindFirstChild(
					"HumanoidRootPart"
				)

			if not attackerRoot or not targetRoot then
				return
			end

			-- Distance
			local playerPosition =
				attackerRoot.Position

			local targetPosition =
				targetRoot.Position

			local distance =
				(playerPosition - targetPosition).Magnitude

			-- Range check
			if distance > weapon.range then
				return
			end

			-- Damage
			local requestedDamage =
				tonumber(damageAmount)

			local baseDamage

			if requestedDamage then
				baseDamage = requestedDamage
			else
				baseDamage = weapon.damage
			end

			local finalDamage =
				calculateDamage(
					baseDamage,
					distance,
					targetPlayer
				)

			if finalDamage <= 0 then
				return
			end

			-- Apply damage
			targetHumanoid.Health =
				math.max(
					0,
					targetHumanoid.Health - finalDamage
				)

			-- Client damage effect
			if damageEffect then

				damageEffect:FireClient(
					targetPlayer,
					finalDamage
				)

			end

			if CONFIG.debugMode then

				print(
					"[FTP HUB]",
					player.Name,
					"hit",
					targetPlayer.Name,
					"with",
					weapon.name,
					"for",
					finalDamage,
					"damage"
				)

			end

		end
	)

	-- Simpan connection
	local objectValue = Instance.new("ObjectValue")
	objectValue.Name = "DamageConnection"
	objectValue.Parent = connectionFolder

	--==================================================
	-- CLEANUP
	--==================================================

	player.AncestryChanged:Connect(
		function(_, parent)

			if parent == nil then

				if damageConnection then
					damageConnection:Disconnect()
				end

			end

		end
	)

end

--==================================================
-- EXISTING PLAYERS
--==================================================

for _, player in ipairs(
	Players:GetPlayers()
) do

	task.spawn(
		function()

			setupPlayer(player)

		end
	)

end

--==================================================
-- NEW PLAYERS
--==================================================

Players.PlayerAdded:Connect(
	function(player)

		setupPlayer(player)

		-- Setup ulang ketika character respawn
		player.CharacterAdded:Connect(
			function(character)

				task.wait(0.5)

				if not player.Parent then
					return
				end

				local humanoid =
					character:FindFirstChildOfClass(
						"Humanoid"
					)

				if humanoid then

					humanoid.WalkSpeed =
						CONFIG.speed

					humanoid.JumpPower =
						CONFIG.jumpPower

					humanoid.MaxHealth =
						CONFIG.maxHealth

					humanoid.Health =
						CONFIG.maxHealth

				end

				createWelcomeGUI(player)

			end
		)

	end
)

--==================================================
-- GAME LOOP
--==================================================

RunService.Heartbeat:Connect(
	function(deltaTime)

		for _, player in ipairs(
			Players:GetPlayers()
		) do

			local character =
				player.Character

			if character then

				local humanoid =
					character:FindFirstChildOfClass(
						"Humanoid"
					)

				if humanoid then

					-- Player mati
					if humanoid.Health <= 0 then

						-- Cek respawning marker
						if not character:FindFirstChild(
							"Respawning"
						) then

							local respawning =
								Instance.new("BoolValue")

							respawning.Name =
								"Respawning"

							respawning.Parent =
								character

							-- Respawn delay
							task.delay(
								CONFIG.respawnTime,
								function()

									if player
										and player.Parent then

										respawnEvent:FireClient(
											player
										)

									end

								end
							)

						end

					end

				end

			end

		end

	end
)

--==================================================
-- DEBUG
--==================================================

if CONFIG.debugMode then

	print("================================")
	print("FTP HUB SERVER INITIALIZED")
	print("PlaceId:", game.PlaceId)
	print("Players:", #Players:GetPlayers())
	print("Weapons:", #weapons)
	print("================================")

end
