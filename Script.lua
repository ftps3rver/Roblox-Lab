--[[
================================================================
  KICK A LUCKY BLOCK — AUTO FARM HUB  (v1.0)
================================================================
  Self-contained: tidak butuh library luar (Rayfield/Kavo dll).
  Executor: Delta / Wave / Krnl / Synapse / Xeno (butuh
            hookmetamethod + firetouchinterest untuk fitur penuh,
            tapi tetap jalan tanpa itu dengan mode Teleport).

  CARA PAKAI SINGKAT:
   1. Execute script ini di dalam game.
   2. Klik tombol [SPY: OFF] -> jadi ON.
   3. Kick 1 lucky block secara MANUAL.
   4. Buka console executor (F9 / tombol Console).
      Akan muncul baris: [SPY] Path:FireServer(args...)
   5. Copy nama remote itu ke CONFIG.KickRemote di bawah,
      lalu execute ulang. (Opsional — Auto Kick tetap bisa
      jalan pakai fallback tanpa langkah ini.)
   6. Nyalakan toggle yang mau dipakai.
================================================================
]]

--================================================================
-- 0. GUARD (biar tidak dobel kalau di-execute 2x)
--================================================================
if getgenv then
    if getgenv().KALB_LOADED then
        local old = getgenv().KALB_CLEANUP
        if typeof(old) == "function" then pcall(old) end
    end
    getgenv().KALB_LOADED = true
end

--================================================================
-- 1. SERVICES
--================================================================
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local VirtualUser        = game:GetService("VirtualUser")
local StarterGui         = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

--================================================================
-- 2. CONFIG  <-- edit bagian ini
--================================================================
local CONFIG = {
    -- Toggle (bisa diubah dari UI juga)
    AutoKick        = false,
    AutoCollect     = false,
    AutoRebirth     = false,
    AutoUpgrade     = false,
    AntiAFK         = true,
    NoClipFall      = true,   -- anti jatuh / anti void saat teleport

    -- Metode kick
    UseTeleport     = true,   -- true = TP ke block, false = tetap di tempat
    KickDelay       = 0.15,   -- jeda antar kick (detik). Jangan < 0.05
    CollectDelay    = 0.10,
    RebirthDelay    = 1.00,
    UpgradeDelay    = 0.50,
    RescanInterval  = 3.00,   -- refresh daftar block (detik)
    ScanRadius      = 500,    -- studs, 0 = tanpa batas

    -- Nama remote (isi dari hasil SPY, kosongkan = pakai auto-detect)
    KickRemote      = "",     -- contoh: "KickBlock"
    RebirthRemote   = "",     -- contoh: "Rebirth"
    UpgradeRemote   = "",     -- contoh: "BuyUpgrade"

    -- Argumen remote. Pakai "$BLOCK" sebagai placeholder instance block.
    -- Contoh dari spy: FireServer(game.Workspace.Blocks.LuckyBlock)
    --   -> KickArgs = { "$BLOCK" }
    -- Contoh: FireServer("Kick", 1)  -> KickArgs = { "Kick", 1 }
    KickArgs        = { "$BLOCK" },
    RebirthArgs     = { },
    UpgradeArgs     = { },    -- contoh: { "Power" }

    -- Kata kunci pencarian objek di Workspace
    BlockKeywords   = { "luckyblock", "lucky", "block", "crate", "box" },
    DropKeywords    = { "coin", "cash", "money", "gem", "drop", "orb", "pickup" },
}

--================================================================
-- 3. UTIL
--================================================================
local function log(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    print("[KALB] " .. table.concat(parts, " "))
end

local function notify(text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = "Kick a Lucky Block",
            Text     = tostring(text),
            Duration = dur or 3,
        })
    end)
    log(text)
end

-- loop yang tidak mati kalau ada error
local function loopTask(getEnabled, getDelay, body)
    task.spawn(function()
        while getgenv and getgenv().KALB_LOADED do
            if getEnabled() then
                local ok, err = pcall(body)
                if not ok then log("err:", err) end
                task.wait(getDelay())
            else
                task.wait(0.25)
            end
        end
    end)
end

local function hasKeyword(name, list)
    local n = string.lower(name)
    for _, k in ipairs(list) do
        if string.find(n, k, 1, true) then return true end
    end
    return false
end

--================================================================
-- 4. CHARACTER HELPER
--================================================================
local function getChar()
    local c = LocalPlayer.Character
    if c and c.Parent then return c end
    return nil
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart") or nil
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid") or nil
end

local savedCFrame = nil

local function savePos()
    local hrp = getHRP()
    if hrp and not savedCFrame then savedCFrame = hrp.CFrame end
end

local function restorePos()
    local hrp = getHRP()
    if hrp and savedCFrame then
        hrp.CFrame = savedCFrame
        savedCFrame = nil
    end
end

local function tpTo(cf)
    local hrp = getHRP()
    if not hrp then return false end
    local hum = getHum()
    if CONFIG.NoClipFall and hum then
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end
    hrp.CFrame = cf
    hrp.AssemblyLinearVelocity = Vector3.zero
    return true
end

--================================================================
-- 5. REMOTE INDEX + AUTO DETECT
--================================================================
local function indexRemotes()
    local out = {}
    local roots = { ReplicatedStorage, LocalPlayer, Workspace }
    for _, root in ipairs(roots) do
        local ok, desc = pcall(function() return root:GetDescendants() end)
        if ok then
            for _, obj in ipairs(desc) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
                or obj:IsA("UnreliableRemoteEvent") then
                    out[#out + 1] = obj
                end
            end
        end
    end
    return out
end

-- cari remote: exact name dulu, kalau tidak ada baru fuzzy by keyword
local function findRemote(exactName, keywords)
    local all = indexRemotes()
    if exactName and exactName ~= "" then
        for _, r in ipairs(all) do
            if r.Name == exactName then return r end
        end
        for _, r in ipairs(all) do
            if string.lower(r.Name) == string.lower(exactName) then return r end
        end
    end
    if keywords then
        for _, r in ipairs(all) do
            if hasKeyword(r.Name, keywords) then return r end
        end
    end
    return nil
end

local remoteCache = {}

local function getRemote(slot, exactName, keywords)
    local cached = remoteCache[slot]
    if cached and cached.Parent then return cached end
    local r = findRemote(exactName, keywords)
    remoteCache[slot] = r
    if r then log("remote[" .. slot .. "] =", r:GetFullName()) end
    return r
end

local function buildArgs(template, block)
    local args = {}
    for i, v in ipairs(template) do
        if v == "$BLOCK" then
            args[i] = block
        elseif v == "$BLOCKNAME" then
            args[i] = block and block.Name or ""
        else
            args[i] = v
        end
    end
    return args
end

local function fireRemote(remote, args)
    if not remote then return false end
    local ok = pcall(function()
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(table.unpack(args))
        else
            remote:FireServer(table.unpack(args))
        end
    end)
    return ok
end

--================================================================
-- 6. REMOTE SPY (untuk menemukan nama remote yang benar)
--================================================================
local Spy = { enabled = false, seen = {}, hooked = false }

local function fmtArgs(...)
    local out = {}
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        local t = typeof(v)
        if t == "Instance" then
            out[#out + 1] = v:GetFullName()
        elseif t == "string" then
            out[#out + 1] = '"' .. v .. '"'
        elseif t == "table" then
            out[#out + 1] = "{table}"
        else
            out[#out + 1] = tostring(v)
        end
    end
    return table.concat(out, ", ")
end

local function initSpy()
    if Spy.hooked then return true end
    if not (hookmetamethod and getnamecallmethod) then
        notify("Executor tidak support hookmetamethod — Spy nonaktif")
        return false
    end
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if Spy.enabled then
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local ok, path = pcall(function() return self:GetFullName() end)
                if ok then
                    local key = path .. "|" .. method
                    if not Spy.seen[key] then
                        Spy.seen[key] = true
                        log(string.format("[SPY] %s:%s(%s)", path, method, fmtArgs(...)))
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    Spy.hooked = true
    return true
end

--================================================================
-- 7. TARGET FINDER (lucky block & drop)
--================================================================
local blockCache, dropCache = {}, {}

local function pivotOf(obj)
    if obj:IsA("BasePart") then return obj.CFrame end
    if obj:IsA("Model") then
        local ok, cf = pcall(function() return obj:GetPivot() end)
        if ok then return cf end
    end
    return nil
end

local function primaryOf(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

-- scan Workspace, ambil yang match keyword & masih hidup
local function scanTargets()
    local blocks, drops = {}, {}
    local ok, desc = pcall(function() return Workspace:GetDescendants() end)
    if not ok then return blocks, drops end

    local char = getChar()
    for _, obj in ipairs(desc) do
        if (obj:IsA("Model") or obj:IsA("BasePart"))
        and not (char and obj:IsDescendantOf(char))
        and not Players:GetPlayerFromCharacter(obj) then
            if hasKeyword(obj.Name, CONFIG.BlockKeywords) then
                -- skip kalau ini child dari block lain yang sudah dicatat
                if primaryOf(obj) then blocks[#blocks + 1] = obj end
            elseif hasKeyword(obj.Name, CONFIG.DropKeywords) then
                if primaryOf(obj) then drops[#drops + 1] = obj end
            end
        end
    end
    return blocks, drops
end

local function nearest(list)
    local hrp = getHRP()
    if not hrp then return nil end
    local origin = hrp.Position
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(list) do
        if obj.Parent then
            local cf = pivotOf(obj)
            if cf then
                local d = (cf.Position - origin).Magnitude
                if d < bestDist and (CONFIG.ScanRadius <= 0 or d <= CONFIG.ScanRadius) then
                    best, bestDist = obj, d
                end
            end
        end
    end
    return best, bestDist
end

-- refresh cache di background
task.spawn(function()
    while getgenv and getgenv().KALB_LOADED do
        local ok, b, d = pcall(scanTargets)
        if ok then blockCache, dropCache = b, d end
        task.wait(CONFIG.RescanInterval)
    end
end)

--================================================================
-- 8. AKSI
--================================================================
local function tryTouch(targetPart)
    local hrp = getHRP()
    if not (hrp and targetPart and firetouchinterest) then return false end
    local ok = pcall(function()
        firetouchinterest(hrp, targetPart, 0)
        task.wait()
        firetouchinterest(hrp, targetPart, 1)
    end)
    return ok
end

local function tryPrompt(obj)
    if not fireproximityprompt then return false end
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt then return false end
    return pcall(function() fireproximityprompt(prompt) end)
end

-- Urutan usaha: Remote -> ProximityPrompt -> Touch -> Teleport
local function kickBlock(block)
    if not (block and block.Parent) then return false end
    local part = primaryOf(block)

    local remote = getRemote("kick", CONFIG.KickRemote,
        { "kick", "hitblock", "punch", "damageblock", "clickblock" })
    if remote and fireRemote(remote, buildArgs(CONFIG.KickArgs, block)) then
        return true
    end

    if tryPrompt(block) then return true end
    if part and tryTouch(part) then return true end

    if CONFIG.UseTeleport then
        local cf = pivotOf(block)
        if cf then
            savePos()
            return tpTo(cf * CFrame.new(0, 3, 0))
        end
    end
    return false
end

local function collectDrop(drop)
    if not (drop and drop.Parent) then return false end
    local part = primaryOf(drop)
    if part and tryTouch(part) then return true end
    if tryPrompt(drop) then return true end
    if CONFIG.UseTeleport then
        local cf = pivotOf(drop)
        if cf then
            savePos()
            return tpTo(cf)
        end
    end
    return false
end

local function doRebirth()
    local remote = getRemote("rebirth", CONFIG.RebirthRemote,
        { "rebirth", "prestige", "reset", "ascend" })
    return fireRemote(remote, buildArgs(CONFIG.RebirthArgs, nil))
end

local function doUpgrade()
    local remote = getRemote("upgrade", CONFIG.UpgradeRemote,
        { "upgrade", "buyupgrade", "buy", "purchase", "kickpower", "power" })
    return fireRemote(remote, buildArgs(CONFIG.UpgradeArgs, nil))
end

--================================================================
-- 9. LOOPS
--================================================================
loopTask(
    function() return CONFIG.AutoKick end,
    function() return CONFIG.KickDelay end,
    function()
        local block = nearest(blockCache)
        if block then
            kickBlock(block)
        else
            -- cache kosong: paksa rescan cepat
            local ok, b, d = pcall(scanTargets)
            if ok then blockCache, dropCache = b, d end
        end
    end
)

loopTask(
    function() return CONFIG.AutoCollect end,
    function() return CONFIG.CollectDelay end,
    function()
        local drop = nearest(dropCache)
        if drop then collectDrop(drop) end
    end
)

loopTask(
    function() return CONFIG.AutoRebirth end,
    function() return CONFIG.RebirthDelay end,
    doRebirth
)

loopTask(
    function() return CONFIG.AutoUpgrade end,
    function() return CONFIG.UpgradeDelay end,
    doUpgrade
)

-- balikin posisi kalau semua auto dimatikan
task.spawn(function()
    while getgenv and getgenv().KALB_LOADED do
        if not (CONFIG.AutoKick or CONFIG.AutoCollect) and savedCFrame then
            restorePos()
        end
        task.wait(1)
    end
end)

--================================================================
-- 10. ANTI-AFK
--================================================================
local afkConn = LocalPlayer.Idled:Connect(function()
    if not CONFIG.AntiAFK then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

--================================================================
-- 11. UI
--================================================================
local COL = {
    bg     = Color3.fromRGB(22, 22, 28),
    bar    = Color3.fromRGB(32, 32, 40),
    off    = Color3.fromRGB(48, 48, 58),
    on     = Color3.fromRGB(64, 176, 110),
    text   = Color3.fromRGB(235, 235, 240),
    accent = Color3.fromRGB(120, 150, 255),
}

local function round(inst, px)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, px or 6)
    c.Parent = inst
    return c
end

local gui = Instance.new("ScreenGui")
gui.Name             = "KALB_Hub"
gui.ResetOnSpawn     = false
gui.IgnoreGuiInset   = true
gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end

local main = Instance.new("Frame")
main.Size             = UDim2.fromOffset(260, 372)
main.Position         = UDim2.new(0, 24, 0.5, -186)
main.BackgroundColor3 = COL.bg
main.BorderSizePixel  = 0
main.Active           = true
main.Parent           = gui
round(main, 10)

local stroke = Instance.new("UIStroke")
stroke.Color        = Color3.fromRGB(60, 60, 75)
stroke.Thickness     = 1
stroke.Parent        = main

local bar = Instance.new("Frame")
bar.Size             = UDim2.new(1, 0, 0, 34)
bar.BackgroundColor3 = COL.bar
bar.BorderSizePixel  = 0
bar.Parent           = main
round(bar, 10)

local title = Instance.new("TextLabel")
title.Size                = UDim2.new(1, -70, 1, 0)
title.Position            = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Font                = Enum.Font.GothamBold
title.TextSize            = 13
title.TextColor3          = COL.text
title.TextXAlignment      = Enum.TextXAlignment.Left
title.Text                = "Lucky Block · Auto"
title.Parent              = bar

local minBtn = Instance.new("TextButton")
minBtn.Size                = UDim2.fromOffset(28, 22)
minBtn.Position            = UDim2.new(1, -64, 0, 6)
minBtn.BackgroundColor3    = COL.off
minBtn.BorderSizePixel     = 0
minBtn.Font                = Enum.Font.GothamBold
minBtn.TextSize            = 14
minBtn.TextColor3          = COL.text
minBtn.Text                = "–"
minBtn.Parent              = bar
round(minBtn, 5)

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.fromOffset(28, 22)
closeBtn.Position         = UDim2.new(1, -32, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 64, 64)
closeBtn.BorderSizePixel  = 0
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 12
closeBtn.TextColor3       = COL.text
closeBtn.Text             = "X"
closeBtn.Parent           = bar
round(closeBtn, 5)

local body = Instance.new("ScrollingFrame")
body.Size                 = UDim2.new(1, -16, 1, -46)
body.Position             = UDim2.fromOffset(8, 40)
body.BackgroundTransparency = 1
body.BorderSizePixel      = 0
body.ScrollBarThickness   = 3
body.CanvasSize           = UDim2.new()
body.AutomaticCanvasSize  = Enum.AutomaticSize.Y
body.Parent               = main

local list = Instance.new("UIListLayout")
list.Padding             = UDim.new(0, 6)
list.SortOrder           = Enum.SortOrder.LayoutOrder
list.Parent              = body

local function addToggle(label, key, onChange)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = CONFIG[key] and COL.on or COL.off
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.Gotham
    btn.TextSize         = 12
    btn.TextColor3       = COL.text
    btn.Text             = string.format("%s : %s", label, CONFIG[key] and "ON" or "OFF")
    btn.Parent           = body
    round(btn, 6)

    btn.MouseButton1Click:Connect(function()
        CONFIG[key] = not CONFIG[key]
        btn.BackgroundColor3 = CONFIG[key] and COL.on or COL.off
        btn.Text = string.format("%s : %s", label, CONFIG[key] and "ON" or "OFF")
        if onChange then pcall(onChange, CONFIG[key]) end
    end)
    return btn
end

local function addButton(label, fn)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = COL.accent
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.GothamMedium
    btn.TextSize         = 12
    btn.TextColor3       = Color3.fromRGB(15, 15, 20)
    btn.Text             = label
    btn.Parent           = body
    round(btn, 6)
    btn.MouseButton1Click:Connect(function() pcall(fn, btn) end)
    return btn
end

local function addSlider(label, key, min, max, step)
    local holder = Instance.new("Frame")
    holder.Size                 = UDim2.new(1, 0, 0, 40)
    holder.BackgroundColor3     = COL.off
    holder.BorderSizePixel      = 0
    holder.Parent               = body
    round(holder, 6)

    local txt = Instance.new("TextLabel")
    txt.Size                    = UDim2.new(1, -12, 0, 16)
    txt.Position                = UDim2.fromOffset(8, 3)
    txt.BackgroundTransparency  = 1
    txt.Font                    = Enum.Font.Gotham
    txt.TextSize                = 11
    txt.TextColor3              = COL.text
    txt.TextXAlignment          = Enum.TextXAlignment.Left
    txt.Text                    = string.format("%s: %.2f", label, CONFIG[key])
    txt.Parent                  = holder

    local track = Instance.new("Frame")
    track.Size                  = UDim2.new(1, -16, 0, 6)
    track.Position              = UDim2.fromOffset(8, 24)
    track.BackgroundColor3      = Color3.fromRGB(70, 70, 84)
    track.BorderSizePixel       = 0
    track.Parent                = holder
    round(track, 3)

    local fill = Instance.new("Frame")
    fill.Size                   = UDim2.fromScale((CONFIG[key] - min) / (max - min), 1)
    fill.BackgroundColor3       = COL.accent
    fill.BorderSizePixel        = 0
    fill.Parent                 = track
    round(fill, 3)

    local sliding = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = min + rel * (max - min)
        val = math.floor(val / step + 0.5) * step
        CONFIG[key] = val
        fill.Size = UDim2.fromScale((val - min) / (max - min), 1)
        txt.Text = string.format("%s: %.2f", label, val)
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
end

local function addLabel(text)
    local lb = Instance.new("TextLabel")
    lb.Size                    = UDim2.new(1, 0, 0, 18)
    lb.BackgroundTransparency  = 1
    lb.Font                    = Enum.Font.GothamBold
    lb.TextSize                = 10
    lb.TextColor3              = Color3.fromRGB(140, 140, 160)
    lb.TextXAlignment          = Enum.TextXAlignment.Left
    lb.Text                    = string.upper(text)
    lb.Parent                  = body
    return lb
end

-- ==== isi UI ====
addLabel("Farming")
addToggle("Auto Kick Block", "AutoKick")
addToggle("Auto Collect Drop", "AutoCollect")
addToggle("Auto Rebirth", "AutoRebirth")
addToggle("Auto Upgrade", "AutoUpgrade")

addLabel("Setting")
addToggle("Teleport Mode", "UseTeleport")
addToggle("Anti AFK", "AntiAFK")
addSlider("Kick Delay", "KickDelay", 0.05, 1.0, 0.05)
addSlider("Scan Radius", "ScanRadius", 0, 1000, 50)

addLabel("Tools")
local spyBtn
spyBtn = addButton("Remote Spy : OFF", function()
    if not Spy.enabled then
        if not initSpy() then return end
        Spy.seen = {}
        Spy.enabled = true
        spyBtn.Text = "Remote Spy : ON"
        notify("Spy ON — kick 1 block manual, cek console (F9)")
    else
        Spy.enabled = false
        spyBtn.Text = "Remote Spy : OFF"
        notify("Spy OFF")
    end
end)

addButton("List Semua Remote", function()
    local all = indexRemotes()
    log("=== " .. #all .. " remote ditemukan ===")
    for _, r in ipairs(all) do log(" •", r.ClassName, r:GetFullName()) end
    notify(#all .. " remote di-print ke console")
end)

addButton("List Target Terdeteksi", function()
    local b, d = scanTargets()
    log("=== blocks:", #b, "| drops:", #d, "===")
    local seenB, seenD = {}, {}
    for _, o in ipairs(b) do seenB[o.Name] = (seenB[o.Name] or 0) + 1 end
    for _, o in ipairs(d) do seenD[o.Name] = (seenD[o.Name] or 0) + 1 end
    for n, c in pairs(seenB) do log("  block:", n, "x" .. c) end
    for n, c in pairs(seenD) do log("  drop :", n, "x" .. c) end
    notify(("%d block / %d drop"):format(#b, #d))
end)

addButton("Kick Sekali (test)", function()
    local block = nearest(blockCache)
    if not block then
        local ok, bb = pcall(scanTargets)
        if ok then blockCache = bb end
        block = nearest(blockCache)
    end
    if block then
        notify("test kick: " .. block.Name)
        kickBlock(block)
    else
        notify("tidak ada block terdeteksi")
    end
end)

addButton("Balik ke Posisi Awal", function()
    restorePos()
    notify("posisi direstore")
end)

-- status footer
local status = Instance.new("TextLabel")
status.Size                   = UDim2.new(1, 0, 0, 16)
status.BackgroundTransparency = 1
status.Font                   = Enum.Font.Code
status.TextSize               = 10
status.TextColor3             = Color3.fromRGB(120, 200, 140)
status.TextXAlignment         = Enum.TextXAlignment.Left
status.Text                   = "idle"
status.Parent                 = body

task.spawn(function()
    while gui.Parent do
        local _, dist = nearest(blockCache)
        status.Text = string.format("blk:%d drp:%d near:%s",
            #blockCache, #dropCache,
            dist and string.format("%.0f", dist) or "-")
        task.wait(1)
    end
end)

-- minimize
local expanded, fullSize = true, main.Size
minBtn.MouseButton1Click:Connect(function()
    expanded = not expanded
    body.Visible = expanded
    main.Size = expanded and fullSize or UDim2.fromOffset(fullSize.X.Offset, 34)
    minBtn.Text = expanded and "–" or "+"
end)

-- drag
do
    local dragging, dragStart, startPos = false, nil, nil
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, i.Position, main.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

--================================================================
-- 12. CLEANUP
--================================================================
local function cleanup()
    CONFIG.AutoKick, CONFIG.AutoCollect = false, false
    CONFIG.AutoRebirth, CONFIG.AutoUpgrade = false, false
    Spy.enabled = false
    pcall(restorePos)
    pcall(function() afkConn:Disconnect() end)
    pcall(function() gui:Destroy() end)
    if getgenv then getgenv().KALB_LOADED = false end
end

if getgenv then getgenv().KALB_CLEANUP = cleanup end
closeBtn.MouseButton1Click:Connect(cleanup)

-- toggle UI dengan RightShift
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    end
end)

notify("Loaded. RightShift = show/hide UI", 5)
log("siap. kalau Auto Kick tidak jalan: pakai Remote Spy dulu.")
