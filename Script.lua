--==================================================
-- FTP HUB - ROBLOX SERVER SCRIPT
--==================================================

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local damageEvent = remotes:WaitForChild("DamageEvent")
local healEvent = remotes:WaitForChild("HealEvent")
local respawnEvent = remotes:WaitForChild("RespawnEvent")

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

	-- Hapus GUI lama jika ada
	local oldGui = playerGui:FindFirstChild("FTPHubGui")

	if oldGui then
		oldGui:Destroy()
	end

	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")

	screenGui.Name = "FTPHubGui"
	screenGui.ResetOnSpawn = false
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

	-- Damage falloff berdasarkan jarak
	if distance > 10 then

		modifier = modifier *
			(1 - (distance - 10) * 0.02)

	end

	-- Random damage variation
	modifier = modifier *
	(math.random() * 0.2 + 0.9)

	return math.floor(baseDamage * modifier)
end

--==================================================
-- PLAYER SETUP
--==================================================

local function setupPlayer(player)

	local character =
		player.Character
		or player.CharacterAdded:Wait()

	local humanoid =
		character:WaitForChild("Humanoid")

	-- Player configuration
	humanoid.WalkSpeed = CONFIG.speed
	humanoid.JumpPower = CONFIG.jumpPower

	humanoid.MaxHealth = CONFIG.maxHealth
	humanoid.Health = CONFIG.maxHealth

	-- Welcome GUI
	createWelcomeGUI(player)

	--==================================================
	-- DAMAGE EVENT
	--==================================================

	damageEvent.OnServerEvent:Connect(
		function(
			playerWhoFired,
			targetPlayer,
			damageAmount,
			weaponIndex
		)

			-- Pastikan event berasal dari player yang benar
			if playerWhoFired ~= player then
				return
			end

			-- Validasi target
			if not targetPlayer then
				return
			end

			if not targetPlayer.Character then
				return
			end

			-- Pilih weapon
			local weapon =
				weapons[weaponIndex or 1]

			if not weapon then
				return
			end

			-- Cari humanoid target
			local targetHumanoid =
				targetPlayer.Character:FindFirstChild("Humanoid")

			if not targetHumanoid then
				return
			end

			-- Cari PrimaryPart attacker
			local attackerRoot =
				player.Character.PrimaryPart

			-- Cari PrimaryPart target
			local targetRoot =
				targetPlayer.Character.PrimaryPart

			if not attackerRoot or not targetRoot then
				return
			end

			-- Hitung jarak
			local playerPosition =
				attackerRoot.Position

			local targetPosition =
				targetRoot.Position

			local distance =
				(playerPosition - targetPosition).Magnitude

			-- Range check
			if distance <= weapon.range then

				-- Hitung damage
				local finalDamage =
					calculateDamage(
						damageAmount or weapon.damage,
						distance,
						targetPlayer
					)

				-- Kurangi HP
				targetHumanoid.Health =
					math.max(
						0,
						targetHumanoid.Health - finalDamage
					)

				-- Kirim efek damage ke target
				local damageEffect =
					remotes:FindFirstChild("DamageEffect")

				if damageEffect then

					damageEffect:FireClient(
						targetPlayer,
						finalDamage
					)

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

	setupPlayer(player)

end

--==================================================
-- NEW PLAYERS
--==================================================

Players.PlayerAdded:Connect(
	function(player)

		setupPlayer(player)

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
					character:FindFirstChild("Humanoid")

				if humanoid then

					-- Player mati
					if humanoid.Health <= 0 then

						-- Cek apakah sedang respawn
						if not character:FindFirstChild(
							"Respawning"
						) then

							local respawning =
								Instance.new("BoolValue")

							respawning.Name =
								"Respawning"

							respawning.Parent =
								character

							-- Delay respawn
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
	print("Players:", #Players:GetPlayers())
	print("Weapons:", #weapons)
	print("================================")

end
