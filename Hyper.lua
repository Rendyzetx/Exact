-- Hyper.lua
-- Aimbot with Rayfield UI | by Tezydner

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- State
local config = {
    aimbotEnabled = false,
    fovVisible = true,
    noSpread = false,
    targetBone = "Head",
    fovRadius = 300,
}

-- Modules (adjust paths sesuai game)
local globalStuff = require(game:GetService("ReplicatedStorage").Modules.GlobalStuff)
local gameUIMod = require(localPlayer.PlayerGui.GameUI.GameUIMod)
local gunModule = require(localPlayer.PlayerGui.ControllerGUI.NewMainLocal.Tools.Tool.Gun)

-- FOV Circle Drawing
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = config.fovVisible
fovCircle.Radius = config.fovRadius
fovCircle.Thickness = 1.5
fovCircle.Color = Color3.fromRGB(255, 255, 0)
fovCircle.Transparency = 0.7
fovCircle.Filled = false
fovCircle.NumSides = 64

-- Get Closest Target
local function getClosestTarget()
    if not config.aimbotEnabled then return nil end
    local closestTarget, shortestDist = nil, config.fovRadius
    local mousePos = UserInputService:GetMouseLocation()
    for _, mob in Workspace.Mobs:GetChildren() do
        if globalStuff:SameTeam(localPlayer, mob) then continue end
        local humanoid = mob:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        local part = mob:FindFirstChild(config.targetBone) or mob:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        local screenPos, onScreen = camera:WorldToScreenPoint(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if dist < shortestDist then
            shortestDist = dist
            closestTarget = mob
        end
    end
    return closestTarget
end

-- Hook: GetMousePos
local originalGetMousePos = gameUIMod.GetMousePos
gameUIMod.GetMousePos = function(self, ...)
    if config.aimbotEnabled then
        local target = getClosestTarget()
        if target then
            local part = target:FindFirstChild(config.targetBone)
            if part then
                local screenPos, onScreen = camera:WorldToScreenPoint(part.Position)
                if onScreen then
                    return Vector2.new(screenPos.X, screenPos.Y)
                end
            end
        end
    end
    return originalGetMousePos(self, ...)
end

-- Hook: ConeOfFire
local originalConeOfFire = gunModule.ConeOfFire
gunModule.ConeOfFire = function(self, origin, mousePos, spread)
    if config.aimbotEnabled then
        local target = getClosestTarget()
        if target then
            local part = target:FindFirstChild(config.targetBone)
            if part then
                return part.Position
            end
        end
    end
    return originalConeOfFire(self, origin, mousePos, spread)
end

-- Hook: GetTotalSpread
local originalGetTotalSpread = gunModule.GetTotalSpread
gunModule.GetTotalSpread = function(self)
    if config.noSpread and getClosestTarget() then
        return 0
    end
    return originalGetTotalSpread(self)
end

-- RenderStepped: Update FOV Circle
RunService.RenderStepped:Connect(function()
    fovCircle.Visible = config.fovVisible
    fovCircle.Radius = config.fovRadius
    fovCircle.Position = UserInputService:GetMouseLocation()
end)

-- ============================================================
-- RAYFIELD UI
-- ============================================================

local Window = Rayfield:CreateWindow({
    Name = "🔫 Hyper | Aimbot",
    Icon = 0,
    LoadingTitle = "Hyper Script",
    LoadingSubtitle = "by Tezydner",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
})

-- Tab: Aimbot
local AimbotTab = Window:CreateTab("🎯 Aimbot", 4483362458)

AimbotTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(value)
        config.aimbotEnabled = value
    end,
})

AimbotTab:CreateToggle({
    Name = "No Spread",
    CurrentValue = false,
    Flag = "NoSpreadToggle",
    Callback = function(value)
        config.noSpread = value
    end,
})

AimbotTab:CreateDropdown({
    Name = "Target Bone",
    Options = {"Head", "HumanoidRootPart", "UpperTorso"},
    CurrentOption = {"Head"},
    Flag = "BoneDropdown",
    Callback = function(option)
        config.targetBone = option[1]
    end,
})

AimbotTab:CreateSlider({
    Name = "FOV Radius",
    Range = {50, 600},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 300,
    Flag = "FovSlider",
    Callback = function(value)
        config.fovRadius = value
    end,
})

-- Tab: Visual
local VisualTab = Window:CreateTab("👁️ Visual", 4483362458)

VisualTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Flag = "FovVisibleToggle",
    Callback = function(value)
        config.fovVisible = value
    end,
})

VisualTab:CreateColorPicker({
    Name = "FOV Color",
    Color = Color3.fromRGB(255, 255, 0),
    Flag = "FovColor",
    Callback = function(value)
        fovCircle.Color = value
    end,
})

VisualTab:CreateSlider({
    Name = "FOV Thickness",
    Range = {1, 5},
    Increment = 0.5,
    Suffix = "px",
    CurrentValue = 1.5,
    Flag = "FovThickness",
    Callback = function(value)
        fovCircle.Thickness = value
    end,
})

VisualTab:CreateSlider({
    Name = "FOV Transparency",
    Range = {0, 1},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 0.7,
    Flag = "FovTransparency",
    Callback = function(value)
        fovCircle.Transparency = value
    end,
})

-- Tab: Info
local InfoTab = Window:CreateTab("ℹ️ Info", 4483362458)

InfoTab:CreateSection("Script Info")

InfoTab:CreateLabel("Hyper Aimbot v1.0")
InfoTab:CreateLabel("by Tezydner")
InfoTab:CreateLabel("Toggle UI: RightShift")

InfoTab:CreateSection("Keybind")

InfoTab:CreateKeybind({
    Name = "Toggle Aimbot",
    CurrentKeybind = "E",
    HoldToInteract = false,
    Flag = "AimbotKeybind",
    Callback = function()
        config.aimbotEnabled = not config.aimbotEnabled
        Rayfield:Notify({
            Title = "Aimbot",
            Content = config.aimbotEnabled and "✅ Enabled" or "❌ Disabled",
            Duration = 2,
        })
    end,
})

Rayfield:Notify({
    Title = "Hyper Loaded",
    Content = "Script berhasil dijalankan!",
    Duration = 3,
    Image = 4483362458,
})
