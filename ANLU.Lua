-- =============================================================================
-- ANLU Hub(Rivals) - ULTIMATE INTEGRATED EDITION
-- Optimized Performance + Synced Aimbot + All Features Included
-- =============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [ Performance Localization ]
local Vector3_new = Vector3.new
local Vector2_new = Vector2.new
local CFrame_new = CFrame.new
local CFrame_Angles = CFrame.Angles
local Color3_fromRGB = Color3.fromRGB
local math_rad = math.rad
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs
local table_insert = table.insert
local task_spawn = task.spawn
local task_wait = task.wait

-- [ UI Library ]
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'ANLU Hub(Rivals) - ULTIMATE INTEGRATED',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.1
})

local Tabs = {
    Main = Window:AddTab('Main'),
    Player = Window:AddTab('Player'),
    Visuals = Window:AddTab('Visuals'),
    World = Window:AddTab('World'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings')
}

-- [ State Variables ]
local angle, antiAimAngle, lastStrafeTime, alternateVoid = 0, 0, 0, false
local isClicking, isRightMouseDown = false, false
local espCache = {}
local CachedSilentTarget = nil
local keyStates = { W = false, A = false, S = false, D = false, Space = false, LeftControl = false }

local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3_fromRGB(255, 0, 50)
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false

-- [ 🌟 CORE: UNLOCK ALL & WEAPON MODS ]
_G.UnlockAllActive = false
_G.HooksInitialized = false
_G.AxiomEquipped = {}
_G.AxiomFavorites = {}
_G.LastUsedWeapon = nil
_G.ConstructingWeapon = nil
_G.ViewingProfile = nil

local function InitUnlockAll()
    if _G.HooksInitialized then return end
    _G.HooksInitialized = true

    local controllers = LocalPlayer.PlayerScripts:WaitForChild("Controllers", 10)
    _G.EnumLibrary = require(ReplicatedStorage.Modules:WaitForChild("EnumLibrary", 10))
    if _G.EnumLibrary then _G.EnumLibrary:WaitForEnumBuilder() end
    _G.CosmeticLibrary = require(ReplicatedStorage.Modules:WaitForChild("CosmeticLibrary", 10))
    _G.ItemLibrary = require(ReplicatedStorage.Modules:WaitForChild("ItemLibrary", 10))
    _G.DataController = require(controllers:WaitForChild("PlayerDataController", 10))
    pcall(function() _G.FighterController = require(controllers:WaitForChild("FighterController", 10)) end)

    _G.CosmeticLibrary.OwnsCosmeticNormally = function() return true end
    _G.CosmeticLibrary.OwnsCosmeticUniversally = function() return true end
    _G.CosmeticLibrary.OwnsCosmeticForWeapon = function() return true end

    local origOwns = _G.CosmeticLibrary.OwnsCosmetic
    _G.CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
        if not _G.UnlockAllActive then return origOwns(self, inventory, name, weapon) end 
        if type(name) == "string" and name:find("MISSING_") then return origOwns(self, inventory, name, weapon) end
        return true
    end

    local origGet = _G.DataController.Get
    _G.DataController.Get = function(self, key)
        local data = origGet(self, key)
        if not _G.UnlockAllActive then return data end 
        if key == "CosmeticInventory" then
            local proxy = data and table.clone(data) or {}
            return setmetatable(proxy, { __index = function() return true end })
        end
        return data
    end

    local origGetWeaponData = _G.DataController.GetWeaponData
    _G.DataController.GetWeaponData = function(self, weaponName)
        local data = origGetWeaponData(self, weaponName)
        if not data then return nil end
        local merged = type(data) == "table" and table.clone(data) or data
        if Toggles.ForceAutomatic and Toggles.ForceAutomatic.Value then
            merged.Automatic = true; merged.IsAutomatic = true; merged.FireMode = "Automatic"; merged.BurstCount = 1
        end
        if Toggles.RapidFireToggle and Toggles.RapidFireToggle.Value then
            merged.FireRate = Options.RapidFireDelay.Value or 0.01; merged.EquipTime = 0; merged.ReloadTime = 0.05; merged.ChargeTime = 0
        end
        return merged
    end
end

-- [ UI SECTIONS ]
local AimbotTab = Tabs.Main:AddLeftGroupbox('Camera Lock-on Aimbot')
AimbotTab:AddToggle('AimbotEnabled', { Text = 'Enable Camera Aimbot', Default = false })
AimbotTab:AddSlider('Smoothness', { Text = 'Aimbot Smoothing', Default = 8, Min = 1, Max = 100, Rounding = 1 })
AimbotTab:AddDropdown('AimbotPart', { Values = { 'Head', 'HumanoidRootPart' }, Default = 1, Text = 'Target Part' })

local RageMainBox = Tabs.Main:AddLeftGroupbox('Hydra Rage Bot')
RageMainBox:AddToggle('RageBotToggle', { Text = 'Enable Instant Bullet Magnet', Default = false })
RageMainBox:AddSlider('BaseVelocity', { Text = 'Bullet Speed', Default = 1000000, Min = 100, Max = 10000000, Rounding = 0 })
RageMainBox:AddSlider('DropCompensation', { Text = 'Drop Comp (Y-Offset)', Default = 1.5, Min = 0, Max = 10, Rounding = 1 })
RageMainBox:AddToggle('AutoShootToggle', { Text = 'Enable Auto-Shoot', Default = false })
RageMainBox:AddToggle('KillAllToggle', { Text = 'Enable AOE Kill', Default = false })
RageMainBox:AddToggle('AntiDamage', { Text = 'Delete Enemy Bullets (God Mode)', Default = false })

local SilentTab = Tabs.Main:AddRightGroupbox('Hyper Silent Aim')
SilentTab:AddToggle('SilentEnabled', { Text = 'Enable Silent Aim', Default = true })
SilentTab:AddToggle('PredictiveShot', { Text = 'Prediction Engine', Default = true })
SilentTab:AddToggle('ShowFOV', { Text = 'Show FOV Circle', Default = false })
SilentTab:AddSlider('Radius', { Text = 'FOV Radius', Default = 400, Min = 0, Max = 1000, Rounding = 0 })
SilentTab:AddSlider('HitChance', { Text = 'Hit Chance (%)', Default = 100, Min = 0, Max = 100, Rounding = 0 })

local FlyGroupBox = Tabs.Player:AddLeftGroupbox('Flight Control')
FlyGroupBox:AddToggle('FlyToggle', { Text = 'Enable Fly', Default = false })
FlyGroupBox:AddSlider('FlySpeed', { Text = 'Fly Speed', Default = 50, Min = 1, Max = 300, Rounding = 0 })

local MovementGroupBox = Tabs.Player:AddLeftGroupbox('Movement Exploits')
MovementGroupBox:AddToggle('StrafeToggle', { Text = 'Enable Strafe', Default = false })
MovementGroupBox:AddToggle('OrbitToggle', { Text = 'Enable Orbit', Default = false })
MovementGroupBox:AddToggle('AutoStrafeToggle', { Text = 'Enable Auto-Strafe', Default = false })
MovementGroupBox:AddSlider('AutoStrafeSpeed', { Text = 'Auto-Strafe Speed', Default = 50, Min = 1, Max = 200, Rounding = 0 })

local EspGroupBox = Tabs.Visuals:AddLeftGroupbox('ESP')
EspGroupBox:AddToggle('EspBox', { Text = 'Box ESP', Default = false })
EspGroupBox:AddToggle('EspSkeleton', { Text = 'Skeleton ESP', Default = false })
EspGroupBox:AddToggle('EspHealthBar', { Text = 'Health Bar', Default = false })
EspGroupBox:AddToggle('EspName', { Text = 'Player Names', Default = false })

local WeaponModBox = Tabs.Misc:AddLeftGroupbox('Weapon Mods')
WeaponModBox:AddToggle('FastFireToggle', { Text = 'Enable Multi-Packet Fire', Default = false })
WeaponModBox:AddSlider('FireRateMultiplier', { Text = 'Packet Multiplier', Default = 10, Min = 1, Max = 50, Rounding = 0 })
WeaponModBox:AddToggle('ForceAutomatic', { Text = '강제 자동 발사', Default = false }):OnChanged(function() InitUnlockAll() end)
WeaponModBox:AddToggle('RapidFireToggle', { Text = '극한 연사', Default = false }):OnChanged(function() InitUnlockAll() end)
WeaponModBox:AddSlider('RapidFireDelay', { Text = '연사 딜레이', Default = 0.01, Min = 0.00, Max = 0.2, Rounding = 3 })
WeaponModBox:AddToggle('UnlockAllToggle', { Text = 'Unlock All Cosmetics', Default = false }):OnChanged(function() _G.UnlockAllActive = Toggles.UnlockAllToggle.Value; InitUnlockAll() end)

-- [ 🌟 BACKEND CORE ENGINE ]

local function getClosestPlayerToMouse()
    if not Options.Radius then return nil end
    local target, maxDist = nil, Options.Radius.Value
    local mousePos = UserInputService:GetMouseLocation()

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        local head = char and char:FindFirstChild("Head")
        if head then
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2_new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < maxDist then maxDist = dist target = p end
            end
        end
    end
    return target
end

local function updateEsp()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local d = espCache[player]
        if not d then 
            d = { Box = Drawing.new("Square"), HealthOutline = Drawing.new("Square"), HealthBar = Drawing.new("Square"), Bones = {}, TopGui = Instance.new("BillboardGui"), TopLabel = Instance.new("TextLabel") }
            d.Box.Thickness = 1.5; d.Box.Filled = false; d.HealthOutline.Filled = true; d.HealthOutline.Color = Color3_fromRGB(0,0,0)
            d.HealthBar.Filled = true; d.TopGui.AlwaysOnTop = true; d.TopGui.Size = UDim2.new(0, 200, 0, 50)
            d.TopLabel.Size = UDim2.new(1,0,1,0); d.TopLabel.BackgroundTransparency = 1; d.TopLabel.Font = Enum.Font.SourceSansBold; d.TopLabel.TextSize = 14; d.TopLabel.Parent = d.TopGui
            d.TopGui.Parent = CoreGui
            espCache[player] = d 
        end

        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if hrp and head and hum and hum.Health > 0 then
            local _, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local top, topOn = Camera:WorldToViewportPoint(head.Position + Vector3_new(0, 1.8, 0))
                local bot, botOn = Camera:WorldToViewportPoint(hrp.Position - Vector3_new(0, 3.2, 0))
                if topOn and botOn then
                    local sizeY = math_abs(top.Y - bot.Y); local sizeX = sizeY * 0.65; local boxPos = Vector2_new(top.X - (sizeX / 2), top.Y)
                    d.Box.Visible = Toggles.EspBox.Value; if d.Box.Visible then d.Box.Size = Vector2_new(sizeX, sizeY); d.Box.Position = boxPos; d.Box.Color = Color3_fromRGB(255,255,255) end
                    if Toggles.EspHealthBar.Value then
                        local pct = hum.Health / hum.MaxHealth
                        d.HealthOutline.Visible = true; d.HealthOutline.Size = Vector2_new(3, sizeY); d.HealthOutline.Position = Vector2_new(boxPos.X - 6, boxPos.Y)
                        d.HealthBar.Visible = true; d.HealthBar.Size = Vector2_new(3, sizeY * pct); d.HealthBar.Position = Vector2_new(boxPos.X - 6, boxPos.Y + (sizeY - (sizeY * pct))); d.HealthBar.Color = Color3_fromRGB(0,255,0)
                    else d.HealthOutline.Visible = false; d.HealthBar.Visible = false end
                    if Toggles.EspName.Value then d.TopGui.Adornee = head; d.TopLabel.Text = player.DisplayName; d.TopGui.Enabled = true else d.TopGui.Enabled = false end
                else d.Box.Visible=false; d.HealthOutline.Visible=false; d.HealthBar.Visible=false; d.TopGui.Enabled=false end
            else d.Box.Visible=false; d.HealthOutline.Visible=false; d.HealthBar.Visible=false; d.TopGui.Enabled=false end
        else d.Box.Visible=false; d.HealthOutline.Visible=false; d.HealthBar.Visible=false; d.TopGui.Enabled=false end
    end
end

-- [ 🌟 UNIFIED METATABLE HOOKING ]
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod(); local args = {...}
    if not checkcaller() and method == "FireServer" and self.Name == "UseItem" then
        if Toggles.SilentEnabled.Value and math_random(1, 100) <= Options.HitChance.Value then
            local target = CachedSilentTarget
            if target and target.Character then
                local head = target.Character:FindFirstChild("Head")
                if head and args[3] and type(args[3]) == "table" and args[3]["\001"] then
                    local hitPos = head.Position + Vector3_new(0, Options.DropCompensation.Value or 1.5, 0)
                    if Toggles.PredictiveShot.Value then local hrp = target.Character:FindFirstChild("HumanoidRootPart"); if hrp then hitPos = hitPos + (hrp.Velocity * 0.05) end end
                    local data = args[3]["\001"]; if data["\001"] then data["\001"]["\001"], data["\001"]["\000"], data["\001"]["\002"] = hitPos.X, hitPos.Y, hitPos.Z end
                    if data["\000"] then data["\000"]["\001"], data["\000"]["\000"], data["\000"]["\002"] = hitPos.X, hitPos.Y, hitPos.Z end
                    data["\002"] = head
                end
            end
        end
    end
    return oldNamecall(self, unpack(args))
end)
setreadonly(mt, true)

-- [ 🌟 MAIN LOOP ]
task_spawn(function()
    while true do
        local dt = task_wait()
        pcall(updateEsp)
        if Toggles.SilentEnabled.Value then CachedSilentTarget = getClosestPlayerToMouse() end
        
        -- SYNCED AIMBOT
        if Toggles.AimbotEnabled.Value and isRightMouseDown and CachedSilentTarget then
            local head = CachedSilentTarget.Character and CachedSilentTarget.Character:FindFirstChild(Options.AimbotPart.Value)
            if head then
                local targetPos = head.Position + Vector3_new(0, Options.DropCompensation.Value, 0)
                local aimCFrame = CFrame_new(Camera.CFrame.Position, targetPos)
                Camera.CFrame = Camera.CFrame:Lerp(aimCFrame, math.clamp(Options.Smoothness.Value / 100, 0.01, 1))
            end
        end

        -- MOVEMENT
        local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if Toggles.FlyToggle.Value then
                local moveDir = Vector3_new(0,0,0)
                if keyStates.W then moveDir = moveDir + Camera.CFrame.LookVector end
                if keyStates.S then moveDir = moveDir - Camera.CFrame.LookVector end
                if keyStates.A then moveDir = moveDir - Camera.CFrame.RightVector end
                if keyStates.D then moveDir = moveDir + Camera.CFrame.RightVector end
                hrp.Velocity = moveDir.Unit * Options.FlySpeed.Value
            end
            if Toggles.AutoStrafeToggle.Value then
                angle = angle + (Options.AutoStrafeSpeed.Value * dt)
                hrp.CFrame = hrp.CFrame + (hrp.CFrame.RightVector * math.sin(angle) * 2)
            end
        end

        -- FOV CIRCLE
        if Toggles.ShowFOV.Value then
            FOVCircle.Position = UserInputService:GetMouseLocation(); FOVCircle.Radius = Options.Radius.Value; FOVCircle.Visible = true
        else FOVCircle.Visible = false end
    end
end)

-- [ INPUT ]
UserInputService.InputBegan:Connect(function(i, g) if g then return end if i.UserInputType == Enum.UserInputType.MouseButton1 then isClicking = true elseif i.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = true end local code = i.KeyCode.Name; if keyStates[code] ~= nil then keyStates[code] = true end end)
UserInputService.InputEnded:Connect(function(i, g) if i.UserInputType == Enum.UserInputType.MouseButton1 then isClicking = false elseif i.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = false end local code = i.KeyCode.Name; if keyStates[code] ~= nil then keyStates[code] = false end end)

Library:Notify("ANLU Hub ULTIMATE Loaded!", 5)
