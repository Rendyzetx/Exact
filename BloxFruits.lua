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
    farmDistance = 15,
    autoFarmMastery = false,
    bringRadius = 300,
    
    -- Combat
    autoClick = false,
    autoSkill = false,
    fastAttack = false,
    
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

-- Anti-AFK
if config.antiAFK then
    localPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

-- ESP Functions
local espObjects = {}

local function createESP(object, text, color)
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
    table.insert(espObjects, billboardGui)
    return billboardGui
end

local function clearESP()
    for _, esp in ipairs(espObjects) do
        if esp then esp:Destroy() end
    end
    espObjects = {}
end

local function updateMobESP()
    clearESP()
    if not config.mobESP then return end
    
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        for _, mob in pairs(enemies:GetChildren()) do
            if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
                local humanoid = mob.Humanoid
                if humanoid.Health > 0 then
                    local distance = (humanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude
                    local text = string.format("%s\n[%d HP] [%.0fm]", mob.Name, humanoid.Health, distance)
                    createESP(mob.HumanoidRootPart, text, Color3.fromRGB(255, 0, 0))
                end
            end
        end
    end
end

local function updateFruitESP()
    if not config.fruitESP then return end
    
    for _, fruit in pairs(Workspace:GetChildren()) do
        if fruit:IsA("Tool") or (fruit:IsA("Model") and fruit:FindFirstChild("Handle")) then
            local handle = fruit:FindFirstChild("Handle")
            if handle and not handle:FindFirstChild("ESP") then
                createESP(handle, fruit.Name, Color3.fromRGB(255, 165, 0))
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
    
    local bringPosition = humanoidRootPart.CFrame * CFrame.new(0, config.farmDistance, 0)
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return end
    
    for _, mob in pairs(enemies:GetChildren()) do
        if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
            local mobHumanoid = mob.Humanoid
            local mobRoot = mob.HumanoidRootPart
            
            if mobHumanoid.Health > 0 then
                local distance = (humanoidRootPart.Position - mobRoot.Position).Magnitude
                
                if distance <= config.bringRadius then
                    -- Disable mob collision
                    for _, part in pairs(mob:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                    
                    -- Bring mob to player (di depan player)
                    mobRoot.CFrame = bringPosition
                    mobRoot.Velocity = Vector3.new(0, 0, 0)
                    mobRoot.RotVelocity = Vector3.new(0, 0, 0)
                    
                    -- Disable mob movement
                    if mobHumanoid then
                        mobHumanoid.WalkSpeed = 0
                        mobHumanoid.JumpPower = 0
                    end
                    
                    -- Anchor mob (freeze in place)
                    pcall(function()
                        mobRoot.Anchored = true
                    end)
                end
            end
        end
    end
end

local function attackMob(mob)
    if not mob or not mob:FindFirstChild("HumanoidRootPart") then return end
    
    -- Stay in place if bring mob is enabled (sudah otomatis dengan auto farm)
    
    -- Click untuk attack
    if config.autoClick then
        -- Method 1: Tool activation
        local tool = character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Handle") then
            tool:Activate()
        end
        
        -- Method 2: Mouse click simulation
        local VirtualInputManager = game:GetService("VirtualInputManager")
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
    
    -- Method 3: Combat remote (jika ada)
    pcall(function()
        local combat = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Remote")
        if combat then
            local combatEvent = combat:FindFirstChild("CommF_") or combat:FindFirstChild("Combat")
            if combatEvent then
                combatEvent:InvokeServer("Attack")
            end
        end
    end)
end

-- Auto Quest Functions
local function getQuest()
    local questGivers = Workspace:FindFirstChild("NPCs")
    if not questGivers then return end
    
    for _, npc in pairs(questGivers:GetChildren()) do
        if npc.Name:match("Quest") and npc:FindFirstChild("HumanoidRootPart") then
            local args = {npc.Name}
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("CommF_") then
                remotes.CommF_:InvokeServer("StartQuest", unpack(args))
            end
            break
        end
    end
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
local attackTick = 0
RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Update Character References
        if not character or not character.Parent then
            character = localPlayer.Character
            if character then
                humanoid = character:WaitForChild("Humanoid")
                humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            end
        end
        
        -- No Clip
        if config.noClip and character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
        
        -- Walk Speed & Jump Power
        if humanoid then
            humanoid.WalkSpeed = config.walkSpeed
            humanoid.JumpPower = config.jumpPower
        end
        
        -- Auto Farm + Bring Mob (1 paket)
        if config.autoFarm and humanoidRootPart then
            -- Bring all mobs to player
            bringAllMobs()
            
            -- Attack closest mob
            local mob = getClosestMob()
            if mob then
                -- Attack every frame when fast attack enabled
                if config.fastAttack then
                    attackMob(mob)
                else
                    -- Attack every 0.1 second
                    attackTick = attackTick + 1
                    if attackTick >= 6 then
                        attackMob(mob)
                        attackTick = 0
                    end
                end
            end
        end
    end)
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
                Content = "✅ Enabled (Bring Mob aktif otomatis)",
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

FarmTab:CreateLabel("Info: Musuh akan dihisap otomatis ke depan Anda")

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
    Range = {5, 30},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 15,
    Flag = "FarmDistanceSlider",
    Callback = function(value)
        config.farmDistance = value
    end,
})

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
                    wait(0.1)
                    -- Simulate key presses for skills
                    local skills = {"Z", "X", "C", "V"}
                    for _, key in ipairs(skills) do
                        local args = {key}
                        -- This would need proper remote detection
                    end
                end
            end)
        end
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
                if tool:IsA("Tool") and tool.ToolTip:match("Fruit") then
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
        -- Alternatif: buka settings menu
        game:GetService("GuiService"):ToggleGuiIsVisibleForCaptures(false)
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
        game:Shutdown()
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
