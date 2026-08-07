-- BloxFruits.lua
-- Script Hub untuk Blox Fruits | by Tezydner
-- Fitur: Auto Farm, ESP, Teleport, Combat, dan lebih banyak lagi

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputService = game:GetService("VirtualInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- State Configuration
local config = {
    -- Auto Farm
    autoFarm = false,
    farmMethod = "Level",
    farmDistance = 20,
    farmMode = "TP to Mob", -- "TP to Mob" (aman) / "Fly + Bring" (legacy)
    autoFarmMastery = false,
    bringRadius = 300,
    
    -- Combat
    autoClick = false,
    autoSkill = false,
    fastAttack = false,
    skillRange = 150,
    skillKeys = {"Z", "X", "C", "V"},
    
    -- Player
    walkSpeed = 16,
    jumpPower = 50,
    noClip = false,
    infiniteEnergy = false,
    antiAFK = true,
    
    -- ESP
    mobESP = false,
    playerESP = false,
    fruitESP = false,
    chestESP = false,
    
    -- Teleport
    selectedIsland = "Middle Town",
    selectedNPC = "Quest Giver",
    
    -- Misc
    autoQuest = false,
    autoBuyMelee = false,
}

-- Anti-AFK (FIX: bisa dimatikan, koneksinya disimpan)
local antiAfkConnection = nil

local function setAntiAFK(enabled)
    if enabled then
        if antiAfkConnection then return end
        antiAfkConnection = localPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    elseif antiAfkConnection then
        antiAfkConnection:Disconnect()
        antiAfkConnection = nil
    end
end

setAntiAFK(config.antiAFK)

-- Highlight (Outline) Character untuk indikator auto farm aktif
local characterHighlight = nil

local function createCharacterHighlight()
    if characterHighlight and characterHighlight.Parent then return end
    characterHighlight = nil
    if not character then return end
    
    pcall(function()
        characterHighlight = Instance.new("Highlight")
        characterHighlight.Name = "AutoFarmIndicator"
        characterHighlight.FillColor = Color3.fromRGB(0, 255, 0) -- Hijau
        characterHighlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- Putih
        characterHighlight.FillTransparency = 0.5
        characterHighlight.OutlineTransparency = 0
        characterHighlight.Enabled = false
        characterHighlight.Parent = character
    end)
end

local function updateCharacterHighlight()
    pcall(function()
        if config.autoFarm then
            if not characterHighlight or not characterHighlight.Parent then
                createCharacterHighlight()
            end
            if characterHighlight then
                characterHighlight.Enabled = true
            end
        else
            if characterHighlight then
                characterHighlight.Enabled = false
            end
        end
    end)
end

-- Create highlight saat script load
if character then
    createCharacterHighlight()
end

-- Update highlight saat character respawn
localPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    -- FIX: wajib reset referensi lama, kalau tidak guard di
    -- createCharacterHighlight() bikin indikator hilang permanen
    characterHighlight = nil
    task.wait(0.5)
    createCharacterHighlight()
end)

-- ESP Functions
local mobESPObjects = {}
local fruitESPObjects = {}

local function createESP(object, text, color, store)
    if not object or not object:IsA("BasePart") then return end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP"
    billboardGui.Adornee = object
    billboardGui.Size = UDim2.new(0, 100, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.AlwaysOnTop = true
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = color
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextScaled = true
    textLabel.Parent = billboardGui
    
    billboardGui.Parent = object
    table.insert(store or mobESPObjects, billboardGui)
    return billboardGui
end

local function clearESPList(list)
    for _, esp in ipairs(list) do
        if esp then esp:Destroy() end
    end
    table.clear(list)
end

local function clearESP()
    clearESPList(mobESPObjects)
    clearESPList(fruitESPObjects)
end

local function updateMobESP()
    -- FIX: dulu clearESP() ikut menghapus ESP fruit tiap detik
    clearESPList(mobESPObjects)
    if not config.mobESP then return end
    if not humanoidRootPart then return end

    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return end

    for _, mob in pairs(enemies:GetChildren()) do
        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
        local mobHumanoid = mob:FindFirstChild("Humanoid")
        if mobRoot and mobHumanoid and mobHumanoid.Health > 0 then
            local distance = (humanoidRootPart.Position - mobRoot.Position).Magnitude
            local text = string.format("%s\n[%d HP] [%.0fm]", mob.Name, mobHumanoid.Health, distance)
            createESP(mobRoot, text, Color3.fromRGB(255, 0, 0), mobESPObjects)
        end
    end
end

local function updateFruitESP()
    if not config.fruitESP then
        clearESPList(fruitESPObjects)
        return
    end

    for _, fruit in pairs(Workspace:GetChildren()) do
        if fruit:IsA("Tool") or (fruit:IsA("Model") and fruit:FindFirstChild("Handle")) then
            local handle = fruit:FindFirstChild("Handle")
            if handle and not handle:FindFirstChild("ESP") then
                createESP(handle, fruit.Name, Color3.fromRGB(255, 165, 0), fruitESPObjects)
            end
        end
    end
end

-- Movement Functions
local function tweenTo(position, speed)
    if not humanoidRootPart then return end
    speed = speed or 300
    
    local distance = (humanoidRootPart.Position - position).Magnitude
    local duration = distance / speed
    
    local tween = TweenService:Create(
        humanoidRootPart,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(position)}
    )
    
    tween:Play()
    return tween
end

-- Auto Farm Functions
local function getClosestMob()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    
    local closestMob, shortestDistance = nil, math.huge
    
    for _, mob in pairs(enemies:GetChildren()) do
        if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
            local mobHumanoid = mob.Humanoid
            if mobHumanoid.Health > 0 then
                local distance = (humanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestMob = mob
                end
            end
        end
    end
    
    return closestMob
end

local function getAllMobs()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return {} end
    
    local mobList = {}
    for _, mob in pairs(enemies:GetChildren()) do
        if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
            local mobHumanoid = mob.Humanoid
            if mobHumanoid.Health > 0 then
                table.insert(mobList, mob)
            end
        end
    end
    return mobList
end

local function bringAllMobs()
    if not config.autoFarm or not humanoidRootPart then return end
    
    -- Player position (tetap di atas)
    local playerPos = humanoidRootPart.Position
    
    -- Posisi bring: DI BAWAH player (player terbang di atas)
    local bringPosition = CFrame.new(playerPos.X, playerPos.Y - config.farmDistance, playerPos.Z)
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return end
    
    for _, mob in pairs(enemies:GetChildren()) do
        if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
            local mobHumanoid = mob.Humanoid
            local mobRoot = mob.HumanoidRootPart
            
            if mobHumanoid.Health > 0 then
                local distance = (playerPos - mobRoot.Position).Magnitude
                
                if distance <= config.bringRadius then
                    -- Disable mob collision
                    for _, part in pairs(mob:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                            part.Massless = true
                        end
                    end
                    
                    -- Bring mob ke BAWAH player yang terbang
                    mobRoot.CFrame = bringPosition
                    mobRoot.Velocity = Vector3.new(0, 0, 0)
                    mobRoot.RotVelocity = Vector3.new(0, 0, 0)
                    
                    -- Freeze mob
                    if mobHumanoid then
                        mobHumanoid.WalkSpeed = 0
                        mobHumanoid.JumpPower = 0
                        mobHumanoid.PlatformStand = true
                    end
                    
                    -- Size adjustment untuk stack better
                    pcall(function()
                        if mobRoot:IsA("BasePart") then
                            mobRoot.Size = Vector3.new(2, 2, 2)
                        end
                    end)
                end
            end
        end
    end
end

-- FIX: CommF_:InvokeServer("Attack") bukan endpoint valid dan errornya
-- ketelan pcall. Jalur hit yang benar = tool:Activate() + CombatFramework.
local combatFramework = nil
task.spawn(function()
    local ok, mod = pcall(function()
        local scripts = localPlayer:WaitForChild("PlayerScripts", 10)
        return require(scripts:WaitForChild("CombatFramework", 10))
    end)
    if ok then combatFramework = mod end
end)

local MAX_ATTACK_RANGE = 60 -- server menolak hit di luar jangkauan wajar

local function attackMob(mob)
    local mobRoot = mob and mob:FindFirstChild("HumanoidRootPart")
    if not mobRoot or not humanoidRootPart or not character then return end

    -- percuma spam kalau target di luar jangkauan: pasti ditolak server
    if (humanoidRootPart.Position - mobRoot.Position).Magnitude > MAX_ATTACK_RANGE then
        return
    end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool or not tool.Parent then return end

    pcall(function()
        tool:Activate()
    end)

    if combatFramework then
        pcall(function()
            local controller = combatFramework.activeController
            if controller and controller.attack then
                controller:attack()
            end
        end)
    end
end

-- Auto Skill Functions
-- FIX: Blox Fruits tidak punya remote skill publik yang stabil; skill di-handle
-- client lewat input listener. Jalur paling reliable = kirim key event asli via
-- VirtualInputService (masuk ke UserInputService game), sambil arahkan kamera
-- ke mob terdekat supaya skill berbasis raycast/aim kena target.
local skillSupportWarned = false

local function pressSkillKey(keyName)
    local keyCode = Enum.KeyCode[keyName]
    if not keyCode then return false end

    local ok = pcall(function()
        VirtualInputService:SendKeyEvent(keyCode, true, nil, game)
        task.wait(0.05)
        VirtualInputService:SendKeyEvent(keyCode, false, nil, game)
    end)
    return ok
end

local function aimCameraAt(position)
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam then
            cam.CFrame = CFrame.new(cam.CFrame.Position, position)
        end
    end)
end

local function castSkills()
    if not config.autoSkill or not character or not humanoidRootPart then return end
    if humanoid and humanoid.Health <= 0 then return end

    local mob = getClosestMob()
    local mobRoot = mob and mob:FindFirstChild("HumanoidRootPart")
    if not mobRoot then return end

    -- jangan buang skill kalau target di luar jangkauan
    if (humanoidRootPart.Position - mobRoot.Position).Magnitude > config.skillRange then
        return
    end

    aimCameraAt(mobRoot.Position)

    for _, key in ipairs(config.skillKeys) do
        if not config.autoSkill then break end -- hormati toggle off di tengah cast
        local ok = pressSkillKey(key)
        if not ok and not skillSupportWarned then
            skillSupportWarned = true
            config.autoSkill = false
            Rayfield:Notify({
                Title = "Auto Skill",
                Content = "❌ Executor tidak support VirtualInputService. Auto Skill dimatikan.",
                Duration = 5,
            })
            return
        end
        task.wait(0.3) -- jeda antar skill, sesuai cooldown umum Blox Fruits
    end
end

-- Auto Quest Functions
-- FIX: CommF_ "StartQuest" butuh NAMA QUEST + tier, bukan nama NPC.
-- Tabel First Sea; sesuaikan kalau ada update game.
local questTable = {
    { min = 1,   max = 9,   name = "BanditQuest1", tier = 1, spot = CFrame.new(1059, 17, 1550) },
    { min = 10,  max = 14,  name = "BanditQuest1", tier = 2, spot = CFrame.new(1059, 17, 1550) },
    { min = 15,  max = 29,  name = "JungleQuest",  tier = 1, spot = CFrame.new(-1598, 37, 153) },
    { min = 30,  max = 39,  name = "JungleQuest",  tier = 2, spot = CFrame.new(-1598, 37, 153) },
    { min = 40,  max = 59,  name = "BuggyQuest1",  tier = 1, spot = CFrame.new(-1140, 4, 3831) },
    { min = 60,  max = 74,  name = "BuggyQuest1",  tier = 2, spot = CFrame.new(-1140, 4, 3831) },
    { min = 75,  max = 89,  name = "DesertQuest",  tier = 1, spot = CFrame.new(896, 6, 4390) },
    { min = 90,  max = 99,  name = "DesertQuest",  tier = 2, spot = CFrame.new(896, 6, 4390) },
    { min = 100, max = 119, name = "SnowQuest",    tier = 1, spot = CFrame.new(1386, 87, -1298) },
    { min = 120, max = 149, name = "SnowQuest",    tier = 2, spot = CFrame.new(1386, 87, -1298) },
    { min = 150, max = 174, name = "MarineQuest2", tier = 1, spot = CFrame.new(-2450, 73, -3210) },
    { min = 175, max = 189, name = "MarineQuest2", tier = 2, spot = CFrame.new(-2450, 73, -3210) },
    { min = 190, max = 209, name = "SkyQuest",     tier = 1, spot = CFrame.new(-4721, 845, -1953) },
    { min = 210, max = 249, name = "SkyQuest",     tier = 2, spot = CFrame.new(-4721, 845, -1953) },
}

local function getPlayerLevel()
    local ok, lvl = pcall(function()
        return localPlayer.Data.Level.Value
    end)
    if ok and type(lvl) == "number" then return lvl end
    return 1
end

local function getQuestForLevel(level)
    for _, q in ipairs(questTable) do
        if level >= q.min and level <= q.max then
            return q
        end
    end
    return nil
end

local function hasActiveQuest()
    local active = false
    pcall(function()
        local main = localPlayer:FindFirstChild("PlayerGui")
        main = main and main:FindFirstChild("Main")
        local questFrame = main and main:FindFirstChild("Quest")
        active = questFrame ~= nil and questFrame.Visible == true
    end)
    return active
end

local lastQuestTry = 0

local function getQuest()
    if tick() - lastQuestTry < 3 then return end
    if hasActiveQuest() then return end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    if not commF then return end

    local q = getQuestForLevel(getPlayerLevel())
    if not q or not humanoidRootPart then return end

    -- server hanya menerima StartQuest kalau kita dekat quest giver
    if (humanoidRootPart.Position - q.spot.Position).Magnitude > 25 then
        humanoidRootPart.CFrame = q.spot
        task.wait(0.4)
    end

    lastQuestTry = tick()
    pcall(function()
        commF:InvokeServer("StartQuest", q.name, q.tier)
    end)
end

-- Island Teleport Data
local islands = {
    -- First Sea
    ["Starter Island"] = CFrame.new(1071, 16, 1426),
    ["Jungle"] = CFrame.new(-1249, 12, 341),
    ["Pirate Village"] = CFrame.new(-1112, 5, 3881),
    ["Desert"] = CFrame.new(1094, 6, 4192),
    ["Frozen Village"] = CFrame.new(1198, 9, -1297),
    ["Middle Town"] = CFrame.new(-690, 15, 1582),
    ["Marine Fortress"] = CFrame.new(-2892, 73, -3195),
    ["Skylands"] = CFrame.new(-4813, 718, -2625),
    ["Prison"] = CFrame.new(4854, 6, 734),
    ["Colosseum"] = CFrame.new(-1503, 7, -3014),
    ["Magma Village"] = CFrame.new(-5234, 9, -4640),
    ["Underwater City"] = CFrame.new(61123, 5, 1819),
    ["Upper Skylands"] = CFrame.new(-7894, 5545, -380),
    
    -- Second Sea
    ["Kingdom of Rose"] = CFrame.new(-303, 8, 5589),
    ["Cafe"] = CFrame.new(-379, 73, 297),
    ["Mansion"] = CFrame.new(-12471, 374, -7551),
    ["Graveyard"] = CFrame.new(-8652, 143, 6170),
    ["Snow Mountain"] = CFrame.new(753, 409, -5274),
    
    -- Third Sea
    ["Port Town"] = CFrame.new(-290, 7, 5343),
    ["Hydra Island"] = CFrame.new(5749, 611, -282),
    ["Great Tree"] = CFrame.new(2681, 1682, -7190),
    ["Castle on the Sea"] = CFrame.new(-5057, 314, -2991),
}

-- Main Loops
local fastAttackSpeed = 0.1 -- FIX: dulu global, sekarang local

-- Cache BasePart supaya tidak GetDescendants() tiap frame (hemat FPS)
local collisionPartsCache = {}
local collisionCacheOwner = nil

local function refreshCollisionCache()
    collisionPartsCache = {}
    collisionCacheOwner = character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(collisionPartsCache, part)
        end
    end
end

local function setCharacterCollision(state)
    if collisionCacheOwner ~= character or #collisionPartsCache == 0 then
        refreshCollisionCache()
    end
    for _, part in ipairs(collisionPartsCache) do
        if part.Parent then
            part.CanCollide = state
        end
    end
end

-- Daftar yang TIDAK boleh dihitung sebagai "tanah" saat fly
local function getFlyIgnoreList()
    local list = {}
    if character then table.insert(list, character) end
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then table.insert(list, enemies) end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character then
            table.insert(list, plr.Character)
        end
    end
    return list
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Update Character References
        if not character or not character.Parent then
            character = localPlayer.Character
            if character then
                humanoid = character:WaitForChild("Humanoid")
                humanoidRootPart = character:WaitForChild("HumanoidRootPart")
                createCharacterHighlight()
            end
        end
        
        -- Update Highlight Indicator
        updateCharacterHighlight()
        
        -- No Clip
        if config.noClip and character then
            setCharacterCollision(false)
        end

        -- Walk Speed & Jump Power
        if humanoid then
            humanoid.WalkSpeed = config.walkSpeed
            humanoid.UseJumpPower = true
            humanoid.JumpPower = config.jumpPower
        end

        -- Auto Farm
        if config.autoFarm and humanoidRootPart and character then
            if config.farmMode == "TP to Mob" then
                -- Mode aman: kita yang mendekati mob.
                -- Perpindahan player itu server-authoritative, jadi hit-nya kebaca.
                local mob = getClosestMob()
                local mobRoot = mob and mob:FindFirstChild("HumanoidRootPart")
                if mobRoot then
                    humanoidRootPart.CFrame = mobRoot.CFrame * CFrame.new(0, config.farmDistance, 0)
                    humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            else
                -- Mode legacy: terbang di atas tanah + tarik mob ke bawah
                local currentPos = humanoidRootPart.Position
                local targetHeight = config.farmDistance + 5

                -- FIX: raycast ke bawah harus mengabaikan mob & player lain.
                -- Kalau tidak, ray nabrak mob yang baru ditarik ke bawah dan
                -- player naik terus tiap frame (terbang tak terkendali).
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = getFlyIgnoreList()
                params.IgnoreWater = true

                local result = Workspace:Raycast(currentPos, Vector3.new(0, -1000, 0), params)
                if result then
                    local targetY = result.Position.Y + targetHeight
                    -- clamp: maksimal 8 stud per frame, biar tidak melesat
                    local deltaY = math.clamp(targetY - currentPos.Y, -8, 8)
                    humanoidRootPart.CFrame = CFrame.new(currentPos.X, currentPos.Y + deltaY, currentPos.Z)
                    humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end

                setCharacterCollision(false)
                bringAllMobs()
            end
        end
    end)
end)

-- Separate attack loop untuk avoid freeze
task.spawn(function()
    while true do
        task.wait(config.fastAttack and fastAttackSpeed or 0.2)
        
        pcall(function()
            if config.autoFarm and humanoidRootPart then
                local mob = getClosestMob()
                if mob then
                    attackMob(mob)
                end
            end
        end)
    end
end)

-- ESP Update Loop
task.spawn(function()
    while true do
        wait(1)
        pcall(function()
            if config.mobESP then
                updateMobESP()
            end
            if config.fruitESP then
                updateFruitESP()
            end
        end)
    end
end)

-- ============================================================
-- RAYFIELD UI
-- ============================================================

local Window = Rayfield:CreateWindow({
    Name = "🍇 Blox Fruits Hub | by Tezydner",
    Icon = 0,
    LoadingTitle = "Blox Fruits Script",
    LoadingSubtitle = "Loading...",
    Theme = "Ocean",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
})

-- Tab: Auto Farm
local FarmTab = Window:CreateTab("🌾 Auto Farm", 4483362458)

FarmTab:CreateSection("Main Farm Settings")

FarmTab:CreateToggle({
    Name = "Auto Farm Level (+ Bring Mob)",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(value)
        config.autoFarm = value
        if value then
            config.autoClick = true
            config.fastAttack = true
            Rayfield:Notify({
                Title = "Auto Farm",
                Content = "✅ Enabled | Anda akan terbang otomatis",
                Duration = 3,
            })
        else
            Rayfield:Notify({
                Title = "Auto Farm",
                Content = "❌ Disabled",
                Duration = 2,
            })
        end
    end,
})

FarmTab:CreateDropdown({
    Name = "Farm Mode",
    Options = {"TP to Mob", "Fly + Bring"},
    CurrentOption = {"TP to Mob"},
    Flag = "FarmModeDropdown",
    Callback = function(option)
        config.farmMode = option[1] or option
    end,
})

FarmTab:CreateLabel("TP to Mob = aman (server terima). Fly + Bring = legacy")

FarmTab:CreateSlider({
    Name = "Bring Radius (Jarak Hisap)",
    Range = {100, 500},
    Increment = 10,
    Suffix = "studs",
    CurrentValue = 300,
    Flag = "BringRadiusSlider",
    Callback = function(value)
        config.bringRadius = value
    end,
})

FarmTab:CreateSlider({
    Name = "Farm Height (Ketinggian Terbang)",
    Range = {10, 40},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 20,
    Flag = "FarmDistanceSlider",
    Callback = function(value)
        config.farmDistance = value
    end,
})

FarmTab:CreateLabel("Semakin tinggi = semakin aman dari musuh")

FarmTab:CreateSection("Quest Settings")

FarmTab:CreateToggle({
    Name = "Auto Quest",
    CurrentValue = false,
    Flag = "AutoQuestToggle",
    Callback = function(value)
        config.autoQuest = value
        if value then
            task.spawn(function()
                while config.autoQuest do
                    wait(0.5)
                    getQuest()
                end
            end)
        end
    end,
})

FarmTab:CreateSection("Attack Settings")

FarmTab:CreateToggle({
    Name = "Fast Attack",
    CurrentValue = false,
    Flag = "FastAttackToggle",
    Callback = function(value)
        config.fastAttack = value
    end,
})

FarmTab:CreateSlider({
    Name = "Attack Speed",
    Range = {0.05, 0.5},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.1,
    Flag = "AttackSpeedSlider",
    Callback = function(value)
        fastAttackSpeed = value
    end,
})

FarmTab:CreateLabel("Semakin kecil = semakin cepat attack")

-- Tab: Combat
local CombatTab = Window:CreateTab("⚔️ Combat", 4483362458)

CombatTab:CreateToggle({
    Name = "Auto Skill (Z, X, C, V)",
    CurrentValue = false,
    Flag = "AutoSkillToggle",
    Callback = function(value)
        config.autoSkill = value
        if value then
            task.spawn(function()
                while config.autoSkill do
                    task.wait(0.3)
                    pcall(castSkills)
                end
            end)
        end
    end,
})

CombatTab:CreateSlider({
    Name = "Skill Range (Jarak Cast)",
    Range = {50, 500},
    Increment = 10,
    Suffix = "studs",
    CurrentValue = 150,
    Flag = "SkillRangeSlider",
    Callback = function(value)
        config.skillRange = value
    end,
})

CombatTab:CreateButton({
    Name = "Equip Melee",
    Callback = function()
        local backpack = localPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and tool.ToolTip == "Melee" then
                    humanoid:EquipTool(tool)
                    break
                end
            end
        end
    end,
})

CombatTab:CreateButton({
    Name = "Equip Fruit",
    Callback = function()
        local backpack = localPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and (tool.ToolTip or ""):match("Fruit") then
                    humanoid:EquipTool(tool)
                    break
                end
            end
        end
    end,
})

-- Tab: Player
local PlayerTab = Window:CreateTab("👤 Player", 4483362458)

PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    Suffix = "speed",
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(value)
        config.walkSpeed = value
    end,
})

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 10,
    Suffix = "power",
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(value)
        config.jumpPower = value
    end,
})

PlayerTab:CreateToggle({
    Name = "No Clip",
    CurrentValue = false,
    Flag = "NoClipToggle",
    Callback = function(value)
        config.noClip = value
    end,
})

PlayerTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFKToggle",
    Callback = function(value)
        config.antiAFK = value
        setAntiAFK(value)
    end,
})

PlayerTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        if humanoid then
            humanoid.Health = 0
        end
    end,
})

-- Tab: ESP & Visuals
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)

ESPTab:CreateSection("Character Indicator")

ESPTab:CreateLabel("Outline Character = Auto Farm Aktif")

ESPTab:CreateColorPicker({
    Name = "Outline Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "OutlineColor",
    Callback = function(value)
        if characterHighlight then
            characterHighlight.OutlineColor = value
        end
    end,
})

ESPTab:CreateColorPicker({
    Name = "Fill Color",
    Color = Color3.fromRGB(0, 255, 0),
    Flag = "FillColor",
    Callback = function(value)
        if characterHighlight then
            characterHighlight.FillColor = value
        end
    end,
})

ESPTab:CreateSlider({
    Name = "Fill Transparency",
    Range = {0, 1},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 0.5,
    Flag = "FillTransparency",
    Callback = function(value)
        if characterHighlight then
            characterHighlight.FillTransparency = value
        end
    end,
})

ESPTab:CreateSection("ESP Settings")

ESPTab:CreateToggle({
    Name = "Mob ESP",
    CurrentValue = false,
    Flag = "MobESPToggle",
    Callback = function(value)
        config.mobESP = value
        if not value then
            clearESP()
        end
    end,
})

ESPTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "PlayerESPToggle",
    Callback = function(value)
        config.playerESP = value
    end,
})

ESPTab:CreateToggle({
    Name = "Fruit ESP",
    CurrentValue = false,
    Flag = "FruitESPToggle",
    Callback = function(value)
        config.fruitESP = value
    end,
})

ESPTab:CreateToggle({
    Name = "Chest ESP",
    CurrentValue = false,
    Flag = "ChestESPToggle",
    Callback = function(value)
        config.chestESP = value
    end,
})

-- Tab: Teleport
local TeleportTab = Window:CreateTab("🌍 Teleport", 4483362458)

TeleportTab:CreateSection("Islands")

local islandList = {}
for island, _ in pairs(islands) do
    table.insert(islandList, island)
end
table.sort(islandList)

TeleportTab:CreateDropdown({
    Name = "Select Island",
    Options = islandList,
    CurrentOption = {"Middle Town"},
    Flag = "IslandDropdown",
    Callback = function(option)
        config.selectedIsland = option[1]
    end,
})

TeleportTab:CreateButton({
    Name = "Teleport to Island",
    Callback = function()
        local targetCFrame = islands[config.selectedIsland]
        if targetCFrame and humanoidRootPart then
            humanoidRootPart.CFrame = targetCFrame
            Rayfield:Notify({
                Title = "Teleport",
                Content = "Teleported to " .. config.selectedIsland,
                Duration = 2,
            })
        end
    end,
})

TeleportTab:CreateSection("Quick Teleports")

TeleportTab:CreateButton({
    Name = "TP to Closest Mob",
    Callback = function()
        local mob = getClosestMob()
        if mob and mob:FindFirstChild("HumanoidRootPart") then
            humanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 10, 0)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "TP to Spawn Point",
    Callback = function()
        local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
        if spawnLocation then
            humanoidRootPart.CFrame = spawnLocation.CFrame * CFrame.new(0, 5, 0)
        end
    end,
})

-- Tab: Misc
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

MiscTab:CreateSection("Auto Buy")

MiscTab:CreateToggle({
    Name = "Auto Buy Melee",
    CurrentValue = false,
    Flag = "AutoBuyMeleeToggle",
    Callback = function(value)
        config.autoBuyMelee = value
    end,
})

MiscTab:CreateSection("Server Management")

MiscTab:CreateButton({
    Name = "🔄 Rejoin Server (Same)",
    Callback = function()
        Rayfield:Notify({
            Title = "Rejoining...",
            Content = "Rejoining server saat ini",
            Duration = 2,
        })
        wait(1)
        game:GetService("TeleportService"):Teleport(game.PlaceId, localPlayer)
    end,
})

MiscTab:CreateButton({
    Name = "🔍 Server Hop (Player Paling Dikit)",
    Callback = function()
        Rayfield:Notify({
            Title = "Server Hop",
            Content = "Mencari server dengan player paling sedikit...",
            Duration = 3,
        })
        
        task.spawn(function()
            local HttpService = game:GetService("HttpService")
            local TeleportService = game:GetService("TeleportService")
            
            local success, result = pcall(function()
                local servers = HttpService:JSONDecode(game:HttpGet(
                    "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                ))
                
                local lowestPlayerServer = nil
                local lowestPlayerCount = math.huge
                
                for _, server in pairs(servers.data) do
                    if server.id ~= game.JobId and server.playing < lowestPlayerCount and server.playing < server.maxPlayers then
                        lowestPlayerCount = server.playing
                        lowestPlayerServer = server
                    end
                end
                
                if lowestPlayerServer then
                    Rayfield:Notify({
                        Title = "Server Ditemukan!",
                        Content = string.format("Pindah ke server dengan %d/%d players", lowestPlayerServer.playing, lowestPlayerServer.maxPlayers),
                        Duration = 3,
                    })
                    wait(1)
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, lowestPlayerServer.id, localPlayer)
                else
                    Rayfield:Notify({
                        Title = "Error",
                        Content = "Tidak dapat menemukan server yang lebih sepi",
                        Duration = 3,
                    })
                end
            end)
            
            if not success then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Gagal server hop: " .. tostring(result),
                    Duration = 3,
                })
            end
        end)
    end,
})

MiscTab:CreateButton({
    Name = "🌍 Server Hop (Random)",
    Callback = function()
        Rayfield:Notify({
            Title = "Server Hop",
            Content = "Pindah ke server random...",
            Duration = 2,
        })
        
        task.spawn(function()
            local HttpService = game:GetService("HttpService")
            local TeleportService = game:GetService("TeleportService")
            
            local success, result = pcall(function()
                local servers = HttpService:JSONDecode(game:HttpGet(
                    "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                ))
                
                local availableServers = {}
                for _, server in pairs(servers.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        table.insert(availableServers, server)
                    end
                end
                
                if #availableServers > 0 then
                    local randomServer = availableServers[math.random(1, #availableServers)]
                    wait(1)
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer.id, localPlayer)
                end
            end)
            
            if not success then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Gagal server hop",
                    Duration = 3,
                })
            end
        end)
    end,
})

MiscTab:CreateSection("Game Info")

MiscTab:CreateLabel("Server ID: " .. game.JobId:sub(1, 12))
MiscTab:CreateLabel("Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)

local pingLabel = MiscTab:CreateLabel("Ping: Calculating...")

-- Update ping setiap 2 detik
task.spawn(function()
    while true do
        wait(2)
        pcall(function()
            local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
            pingLabel:Set("Ping: " .. ping .. "ms")
        end)
    end
end)

MiscTab:CreateButton({
    Name = "📋 Copy Server ID",
    Callback = function()
        setclipboard(game.JobId)
        Rayfield:Notify({
            Title = "Copied!",
            Content = "Server ID copied to clipboard",
            Duration = 2,
        })
    end,
})

MiscTab:CreateSection("Game Settings")

MiscTab:CreateButton({
    Name = "⚙️ Buka Pengaturan Roblox",
    Callback = function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Pengaturan",
            Text = "Tekan ESC untuk buka menu Roblox",
            Duration = 3,
        })
        -- catatan: GuiService tidak punya API untuk membuka menu Roblox dari script
    end,
})

MiscTab:CreateButton({
    Name = "🚪 Keluar ke Lobby",
    Callback = function()
        Rayfield:Notify({
            Title = "Keluar",
            Content = "Kembali ke menu utama...",
            Duration = 2,
        })
        wait(1)
        game:GetService("TeleportService"):Teleport(2753915549, localPlayer) -- Blox Fruits lobby
    end,
})

MiscTab:CreateButton({
    Name = "🔴 Disconnect (Quit Game)",
    Callback = function()
        Rayfield:Notify({
            Title = "Disconnecting",
            Content = "Keluar dari game...",
            Duration = 2,
        })
        wait(1)
        localPlayer:Kick("Keluar dari game via script")
    end,
})

-- Tab: Credits
local CreditsTab = Window:CreateTab("ℹ️ Info", 4483362458)

CreditsTab:CreateSection("Script Info")

CreditsTab:CreateLabel("Blox Fruits Hub v1.0")
CreditsTab:CreateLabel("Created by: Tezydner")
CreditsTab:CreateLabel("Last Updated: 2026")

CreditsTab:CreateSection("Keybinds")

CreditsTab:CreateLabel("Toggle UI: RightShift")
CreditsTab:CreateLabel("Toggle Farm: F")

CreditsTab:CreateKeybind({
    Name = "Toggle Auto Farm",
    CurrentKeybind = "F",
    HoldToInteract = false,
    Flag = "FarmKeybind",
    Callback = function()
        config.autoFarm = not config.autoFarm
        Rayfield:Notify({
            Title = "Auto Farm",
            Content = config.autoFarm and "✅ Enabled" or "❌ Disabled",
            Duration = 2,
        })
    end,
})

CreditsTab:CreateSection("Disclaimer")

CreditsTab:CreateLabel("Use at your own risk!")
CreditsTab:CreateLabel("This script may be detected")
CreditsTab:CreateLabel("by anti-cheat systems")

-- Final Notification
Rayfield:Notify({
    Title = "Blox Fruits Hub Loaded!",
    Content = "Script berhasil dijalankan. Selamat bermain!",
    Duration = 5,
    Image = 4483362458,
})

print("[Blox Fruits Hub] Script loaded successfully!")
print("[Blox Fruits Hub] Press RightShift to toggle UI")
