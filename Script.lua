```lua
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
print(" FTP HUB PENTEST STARTING")
print("========================================")
print("Current PlaceId :", game.PlaceId)
print("Expected PlaceId:", ALLOWED_PLACE_ID)
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
    ScanAllServices = true,
    MaxLogs = 500
}

--==================================================
-- LOGGER
--==================================================

local eventLogs = {}

local function log(...)
    print("[FTP HUB]", ...)
end

local function warning(...)
    warn("[FTP HUB]", ...)
end

local function addLog(text)
    table.insert(eventLogs, 1, {
        Time = os.date("%H:%M:%S"),
        Text = text
    })

    if #eventLogs > CONFIG.MaxLogs then
        table.remove(eventLogs)
    end
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

    local containers = {}

    -- ReplicatedStorage
    table.insert(containers, ReplicatedStorage)

    -- Folder Remotes kalau ada
    local remotesFolder =
        ReplicatedStorage:FindFirstChild("Remotes")

    if remotesFolder then
        table.insert(containers, remotesFolder)
    end

    local seen = {}

    for _, container in ipairs(containers) do

        for _, object in ipairs(container:GetDescendants()) do

            if object:IsA("RemoteEvent")
                or object:IsA("RemoteFunction") then

                if not seen[object] then

                    seen[object] = true

                    local className =
                        object:IsA("RemoteEvent")
                        and "RemoteEvent"
                        or "RemoteFunction"

                    local entry = {
                        Name = object.Name,
                        Class = className,
                        Path = object:GetFullName()
                    }

                    table.insert(
                        remoteResults,
                        entry
                    )

                    addLog(
                        "[" .. className .. "] "
                        .. object:GetFullName()
                    )

                    log(
                        "[" .. className .. "]",
                        object:GetFullName()
                    )

                end
            end
        end
    end

    return #remoteResults
end

if CONFIG.ScanRemotes then
    scanRemotes()
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

for _, name in ipairs(knownRemoteNames) do

    local object =
        ReplicatedStorage:FindFirstChild(
            name,
            true
        )

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

        log(
            "[MISSING]",
            name
        )

    end
end

--==================================================
-- TOOL / WEAPON SCANNER
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

                addLog(
                    "[TOOL BACKPACK] "
                    .. object.Name
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

                addLog(
                    "[TOOL EQUIPPED] "
                    .. object.Name
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

local playerGui =
    LocalPlayer:WaitForChild("PlayerGui")

local oldGui =
    playerGui:FindFirstChild("FTPHub")

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
    UDim2.fromOffset(560, 420)

frame.Position =
    UDim2.new(0.5, -280, 0.5, -210)

frame.BackgroundColor3 =
    Color3.fromRGB(8, 8, 8)

frame.BackgroundTransparency = 0.05
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
    Color3.fromRGB(0, 255, 0)

stroke.Thickness = 2
stroke.Parent = frame

--==================================================
-- TITLE
--==================================================

local title =
    Instance.new("TextLabel")

title.Size =
    UDim2.new(1, -70, 0, 45)

title.Position =
    UDim2.fromOffset(15, 8)

title.BackgroundTransparency = 1

title.Text =
    "FTP HUB | DIAGNOSTIC"

title.TextColor3 =
    Color3.fromRGB(0, 255, 0)

title.Font = Enum.Font.Code
title.TextSize = 22
title.TextXAlignment =
    Enum.TextXAlignment.Left

title.Parent = frame

--==================================================
-- CLOSE
--==================================================

local closeButton =
    Instance.new("TextButton")

closeButton.Size =
    UDim2.fromOffset(35, 35)

closeButton.Position =
    UDim2.new(1, -45, 0, 8)

closeButton.BackgroundColor3 =
    Color3.fromRGB(35, 35, 35)

closeButton.Text = "X"

closeButton.TextColor3 =
    Color3.fromRGB(255, 80, 80)

closeButton.Font = Enum.Font.Code
closeButton.TextSize = 20

closeButton.Parent = frame

local closeCorner =
    Instance.new("UICorner")

closeCorner.CornerRadius =
    UDim.new(0, 8)

closeCorner.Parent = closeButton

--==================================================
-- STATUS
--==================================================

local status =
    Instance.new("TextLabel")

status.Size =
    UDim2.new(1, -30, 0, 30)

status.Position =
    UDim2.fromOffset(15, 55)

status.BackgroundTransparency = 1

status.Text =
    "● PENTEST MODE"

status.TextColor3 =
    Color3.fromRGB(100, 255, 100)

status.Font = Enum.Font.Code
status.TextSize = 16

status.TextXAlignment =
    Enum.TextXAlignment.Left

status.Parent = frame

--==================================================
-- SCROLL FRAME
--==================================================

local scroll =
    Instance.new("ScrollingFrame")

scroll.Name = "LogViewer"

scroll.Size =
    UDim2.new(1, -30, 1, -100)

scroll.Position =
    UDim2.fromOffset(15, 90)

scroll.BackgroundColor3 =
    Color3.fromRGB(3, 3, 3)

scroll.BackgroundTransparency = 0.15

scroll.BorderSizePixel = 0

scroll.ScrollBarThickness = 7

scroll.ScrollBarImageColor3 =
    Color3.fromRGB(0, 255, 0)

scroll.CanvasSize =
    UDim2.new(0, 0, 0, 0)

scroll.AutomaticCanvasSize =
    Enum.AutomaticSize.Y

scroll.ScrollingDirection =
    Enum.ScrollingDirection.Y

scroll.Parent = frame

local scrollCorner =
    Instance.new("UICorner")

scrollCorner.CornerRadius =
    UDim.new(0, 10)

scrollCorner.Parent = scroll

--==================================================
-- LOG CONTENT
--==================================================

local logLayout =
    Instance.new("UIListLayout")

logLayout.Padding =
    UDim.new(0, 4)

logLayout.SortOrder =
    Enum.SortOrder.LayoutOrder

logLayout.Parent = scroll

local logPadding =
    Instance.new("UIPadding")

logPadding.PaddingTop =
    UDim.new(0, 8)

logPadding.PaddingLeft =
    UDim.new(0, 8)

logPadding.PaddingRight =
    UDim.new(0, 8)

logPadding.PaddingBottom =
    UDim.new(0, 8)

logPadding.Parent = scroll

--==================================================
-- ADD GUI LOG
--==================================================

local function addGuiLog(text)

    local label =
        Instance.new("TextLabel")

    label.Size =
        UDim2.new(1, -5, 0, 22)

    label.BackgroundTransparency = 1

    label.Text =
        "[" .. os.date("%H:%M:%S") .. "] "
        .. text

    label.TextColor3 =
        Color3.fromRGB(210, 210, 210)

    label.Font = Enum.Font.Code
    label.TextSize = 14

    label.TextXAlignment =
        Enum.TextXAlignment.Left

    label.TextWrapped = true

    label.AutomaticSize =
        Enum.AutomaticSize.Y

    label.Parent = scroll

    task.defer(function()

        scroll.CanvasPosition =
            Vector2.new(
                0,
                math.max(
                    0,
                    scroll.AbsoluteCanvasSize.Y
                    - scroll.AbsoluteWindowSize.Y
                )
            )

    end)
end

--==================================================
-- INITIAL REPORT
--==================================================

addGuiLog(
    "PLAYER : "
    .. LocalPlayer.Name
)

addGuiLog(
    "USER ID : "
    .. tostring(LocalPlayer.UserId)
)

addGuiLog(
    "PLACE ID : "
    .. tostring(game.PlaceId)
)

addGuiLog(
    "CHARACTER : "
    .. character.Name
)

addGuiLog(
    "REMOTE COUNT : "
    .. tostring(#remoteResults)
)

addGuiLog(
    "TOOL COUNT : "
    .. tostring(#tools)
)

--==================================================
-- REMOTE LIST
--==================================================

addGuiLog("========== REMOTES ==========")

for _, remote in ipairs(remoteResults) do

    addGuiLog(
        "[" .. remote.Class .. "] "
        .. remote.Name
    )

    addGuiLog(
        "  PATH: "
        .. remote.Path
    )

end

--==================================================
-- TOOL LIST
--==================================================

addGuiLog("========== TOOLS ==========")

for _, toolName in ipairs(tools) do

    addGuiLog(
        "[TOOL] "
        .. toolName
    )

end

--==================================================
-- CHARACTER INFO
--==================================================

if humanoid then

    addGuiLog(
        "HEALTH : "
        .. tostring(humanoid.Health)
        .. "/"
        .. tostring(humanoid.MaxHealth)
    )

    addGuiLog(
        "WALKSPEED : "
        .. tostring(humanoid.WalkSpeed)
    )

    addGuiLog(
        "JUMPPOWER : "
        .. tostring(humanoid.JumpPower)
    )

end

--==================================================
-- CLOSE / REOPEN BUTTON
--==================================================

local reopen =
    Instance.new("TextButton")

reopen.Name = "Reopen"

reopen.Size =
    UDim2.fromOffset(55, 55)

reopen.Position =
    UDim2.new(0, 15, 0.5, -27)

reopen.BackgroundColor3 =
    Color3.fromRGB(5, 5, 5)

reopen.Text = "FTP"

reopen.TextColor3 =
    Color3.fromRGB(0, 255, 0)

reopen.Font = Enum.Font.Code
reopen.TextSize = 15

reopen.Visible = false
reopen.Parent = gui

local reopenCorner =
    Instance.new("UICorner")

reopenCorner.CornerRadius =
    UDim.new(1, 0)

reopenCorner.Parent = reopen

local reopenStroke =
    Instance.new("UIStroke")

reopenStroke.Color =
    Color3.fromRGB(0, 255, 0)

reopenStroke.Thickness = 2
reopenStroke.Parent = reopen

closeButton.MouseButton1Click:Connect(
    function()

        frame.Visible = false
        reopen.Visible = true

    end
)

reopen.MouseButton1Click:Connect(
    function()

        frame.Visible = true
        reopen.Visible = false

    end
)

--==================================================
-- DRAG
--==================================================

local dragging = false
local dragStart
local startPosition

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

        if dragging and
            input.UserInputType ==
            Enum.UserInputType.MouseMovement then

            local delta =
                input.Position - dragStart

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

        addGuiLog(
            "========== CHARACTER =========="
        )

        addGuiLog(
            "CHARACTER CHANGED : "
            .. character.Name
        )

        if humanoid then

            addGuiLog(
                "HEALTH : "
                .. tostring(humanoid.Health)
            )

            addGuiLog(
                "WALKSPEED : "
                .. tostring(humanoid.WalkSpeed)
            )

            addGuiLog(
                "JUMPPOWER : "
                .. tostring(humanoid.JumpPower)
            )

        end

        if CONFIG.ScanTools then
            scanTools()
        end

    end
)

--==================================================
-- TOOL CHANGE MONITOR
--==================================================

if character then

    character.ChildAdded:Connect(
        function(object)

            if object:IsA("Tool") then

                addGuiLog(
                    "[EQUIP] "
                    .. object.Name
                )

                log(
                    "[EQUIP]",
                    object.Name
                )

            end

        end
    )

    character.ChildRemoved:Connect(
        function(object)

            if object:IsA("Tool") then

                addGuiLog(
                    "[UNEQUIP] "
                    .. object.Name
                )

                log(
                    "[UNEQUIP]",
                    object.Name
                )

            end

        end
    )

end

--==================================================
-- PERIODIC CHARACTER MONITOR
--==================================================

local lastHealth = nil
local lastWalkSpeed = nil
local lastJumpPower = nil
local lastPosition = nil

local heartbeatConnection

heartbeatConnection =
    RunService.Heartbeat:Connect(
        function()

            if not gui or
                not gui.Parent then

                heartbeatConnection:Disconnect()
                return

            end

            if humanoid then

                local health =
                    math.floor(
                        humanoid.Health
                    )

                local walkSpeed =
                    humanoid.WalkSpeed

                local jumpPower =
                    humanoid.JumpPower

                if lastHealth ~= nil
                    and health ~= lastHealth then

                    addGuiLog(
                        "[HEALTH] "
                        .. tostring(lastHealth)
                        .. " -> "
                        .. tostring(health)
                    )

                end

                if lastWalkSpeed ~= nil
                    and walkSpeed ~= lastWalkSpeed then

                    addGuiLog(
                        "[WALKSPEED] "
                        .. tostring(lastWalkSpeed)
                        .. " -> "
                        .. tostring(walkSpeed)
                    )

                end

                if lastJumpPower ~= nil
                    and jumpPower ~= lastJumpPower then

                    addGuiLog(
                        "[JUMPPOWER] "
                        .. tostring(lastJumpPower)
                        .. " -> "
                        .. tostring(jumpPower)
                    )

                end

                lastHealth = health
                lastWalkSpeed = walkSpeed
                lastJumpPower = jumpPower

                status.Text =
                    "● LIVE | HP "
                    .. tostring(health)
                    .. "/"
                    .. tostring(
                        math.floor(
                            humanoid.MaxHealth
                        )
                    )

            end

            if rootPart then

                local pos =
                    rootPart.Position

                if lastPosition then

                    local distance =
                        (
                            pos - lastPosition
                        ).Magnitude

                    -- Hanya tampilkan perubahan
                    -- posisi yang cukup signifikan
                    if distance >= 5 then

                        addGuiLog(
                            string.format(
                                "[POSITION] %.1f, %.1f, %.1f",
                                pos.X,
                                pos.Y,
                                pos.Z
                            )
                        )

                    end

                end

                lastPosition = pos

            end

        end
    )

--==================================================
-- FINAL REPORT
--==================================================

print("========================================")
print(" FTP HUB DIAGNOSTIC READY")
print("========================================")
print("PlaceId      :", game.PlaceId)
print("Player       :", LocalPlayer.Name)
print("Remote count :", #remoteResults)
print("Tool count   :", #tools)
print("========================================")

for _, remote in ipairs(remoteResults) do

    print(
        "[" .. remote.Class .. "]",
        remote.Path
    )

end

print("========================================")
```
