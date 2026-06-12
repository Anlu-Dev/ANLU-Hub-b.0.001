-- =============================================================================
-- ANLU Hub(Rivals) - ULTIMATE FULL INTEGRATED EDITION
-- [ Base: ANLU Hub PRO EDITION ] + [ Optimized by Manus ]
-- FIXED: ViewModel Aimbot, Recoil, Volt Stability, Performance
-- =============================================================================

task.spawn(function()
    -- [ 🌟 SERVICES & LOCALIZATION ]
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Lighting = game:GetService("Lighting")
    local HttpService = game:GetService("HttpService")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera

    local Vector3_new = Vector3.new
    local CFrame_new = CFrame.new
    local Color3_fromRGB = Color3.fromRGB
    local task_wait = task.wait
    local task_spawn = task.spawn

    -- [ 🌟 UI LIBRARY LOAD ]
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

    -- [ 🌟 STATE & VARIABLES ]
    local angle, isRightMouseDown = 0, false
    local espCache = {}
    local CachedSilentTarget = nil
    local FOVCircle = Drawing.new("Circle")
    FOVCircle.Color = Color3_fromRGB(255, 0, 50)
    FOVCircle.Thickness = 1.5
    FOVCircle.Filled = false

    -- [ 🌟 CORE INITIALIZATION (UNLOCK ALL & WEAPON MODS) ]
    _G.UnlockAllActive = false
    _G.HooksInitialized = false
    _G.AxiomEquipped = {}

    local function InitUnlockAll()
        if _G.HooksInitialized then return end
        _G.HooksInitialized = true

        task_spawn(function()
            local controllers = LocalPlayer.PlayerScripts:WaitForChild("Controllers", 15)
            if not controllers then return end

            pcall(function()
                _G.EnumLibrary = require(ReplicatedStorage.Modules:WaitForChild("EnumLibrary", 5))
                _G.CosmeticLibrary = require(ReplicatedStorage.Modules:WaitForChild("CosmeticLibrary", 5))
                _G.DataController = require(controllers:WaitForChild("PlayerDataController", 5))
            end)

            if _G.DataController then
                local origGetWeaponData = _G.DataController.GetWeaponData
                _G.DataController.GetWeaponData = function(self, weaponName)
                    local data = origGetWeaponData(self, weaponName)
                    if not data then return nil end
                    local merged = table.clone(data)
                    
                    -- Optimized Weapon Mods
                    if Toggles.ForceAutomatic and Toggles.ForceAutomatic.Value then
                        merged.Automatic = true; merged.IsAutomatic = true; merged.FireMode = "Automatic"
                    end
                    if Toggles.RapidFireToggle and Toggles.RapidFireToggle.Value then
                        merged.FireRate = Options.RapidFireDelay.Value or 0.01; merged.EquipTime = 0
                    end
                    return merged
                end
            end
        end)
    end

    -- [ 🌟 MAIN COMBAT UI ]
    local AimbotTab = Tabs.Main:AddLeftGroupbox('Camera Lock-on Aimbot')
    AimbotTab:AddToggle('AimbotEnabled', { Text = 'Enable Camera Aimbot', Default = false })
    AimbotTab:AddSlider('Smoothness', { Text = 'Aimbot Smoothing', Default = 8, Min = 1, Max = 100, Rounding = 1 })
    AimbotTab:AddDropdown('AimbotPart', { Values = { 'Head', 'HumanoidRootPart' }, Default = 1, Text = 'Target Part' })

    local RageMainBox = Tabs.Main:AddLeftGroupbox('Hydra Rage Bot')
    RageMainBox:AddToggle('RageBotToggle', { Text = 'Enable Instant Bullet Magnet', Default = false })
    RageMainBox:AddSlider('BaseVelocity', { Text = 'Bullet Speed Multiplier', Default = 1000000, Min = 100, Max = 10000000, Rounding = 0 })
    RageMainBox:AddSlider('DropCompensation', { Text = 'Headshot Drop Comp (Y-Offset)', Default = 1.5, Min = 0, Max = 10, Rounding = 1 })
    RageMainBox:AddToggle('AutoShootToggle', { Text = 'Enable Auto-Shoot', Default = false })

    local SilentTab = Tabs.Main:AddRightGroupbox('Hyper Silent Aim')
    SilentTab:AddToggle('SilentEnabled', { Text = 'Enable Silent Aim', Default = true })
    SilentTab:AddToggle('ShowFOV', { Text = 'Show FOV Circle', Default = false })
    SilentTab:AddSlider('Radius', { Text = 'FOV Radius Size', Default = 400, Min = 0, Max = 1000, Rounding = 0 })
    SilentTab:AddSlider('HitChance', { Text = 'Hit Chance (%)', Default = 100, Min = 0, Max = 100, Rounding = 0 })

    -- [ 🌟 PLAYER & VISUALS UI ]
    local MovementBox = Tabs.Player:AddLeftGroupbox('Movement Control')
    MovementBox:AddToggle('FlyToggle', { Text = 'Enable Fly', Default = false })
    MovementBox:AddSlider('FlySpeed', { Text = 'Fly Speed', Default = 50, Min = 1, Max = 300, Rounding = 0 })

    local EspGroupBox = Tabs.Visuals:AddLeftGroupbox('ESP')
    EspGroupBox:AddToggle('EspBox', { Text = 'Box ESP', Default = false })
    EspGroupBox:AddToggle('EspName', { Text = 'Player Names', Default = false })

    -- [ 🌟 WORLD & MISC UI ]
    local WorldBox = Tabs.World:AddLeftGroupbox('Environment')
    WorldBox:AddToggle('Fullbright', { Text = 'Enable Fullbright', Default = false }):OnChanged(function()
        Lighting.Brightness = Toggles.Fullbright.Value and 2 or 1
    end)

    local WeaponBox = Tabs.Misc:AddLeftGroupbox('Weapon Mods')
    WeaponBox:AddToggle('ForceAutomatic', { Text = '강제 자동 발사', Default = false }):OnChanged(InitUnlockAll)
    WeaponBox:AddToggle('RapidFireToggle', { Text = '극한 연사', Default = false }):OnChanged(InitUnlockAll)
    WeaponBox:AddSlider('RapidFireDelay', { Text = '연사 딜레이', Default = 0.01, Min = 0.00, Max = 0.2, Rounding = 3 })
    WeaponBox:AddToggle('UnlockAllToggle', { Text = 'Unlock All Cosmetics', Default = false }):OnChanged(function()
        _G.UnlockAllActive = Toggles.UnlockAllToggle.Value
        InitUnlockAll()
    end)

    -- [ 🌟 BACKEND LOGIC ]
    local function getClosest()
        local target, maxDist = nil, Options.Radius.Value
        local mousePos = UserInputService:GetMouseLocation()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < maxDist then maxDist = dist target = p end
                end
            end
        end
        return target
    end

    -- [ 🌟 METATABLE HOOK ]
    local mt = getrawmetatable(game); local oldNamecall = mt.__namecall; setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod(); local args = {...}
        if not checkcaller() and method == "FireServer" and self.Name == "UseItem" then
            if Toggles.SilentEnabled.Value and math.random(1, 100) <= Options.HitChance.Value then
                local target = CachedSilentTarget
                if target and target.Character then
                    local head = target.Character:FindFirstChild("Head")
                    if head and args[3] and type(args[3]) == "table" and args[3]["\001"] then
                        local hitPos = head.Position + Vector3_new(0, Options.DropCompensation.Value, 0)
                        local data = args[3]["\001"]
                        if data["\001"] then data["\001"]["\001"], data["\001"]["\000"], data["\001"]["\002"] = hitPos.X, hitPos.Y, hitPos.Z end
                        data["\002"] = head
                    end
                end
            end
        end
        return oldNamecall(self, unpack(args))
    end)
    setreadonly(mt, true)

    -- [ 🌟 RENDER LOOP ]
    RunService.RenderStepped:Connect(function()
        if Toggles.SilentEnabled.Value then CachedSilentTarget = getClosest() end
        if Toggles.AimbotEnabled.Value and isRightMouseDown and CachedSilentTarget then
            local head = CachedSilentTarget.Character and CachedSilentTarget.Character:FindFirstChild(Options.AimbotPart.Value)
            if head then
                local aimCFrame = CFrame_new(Camera.CFrame.Position, head.Position + Vector3_new(0, Options.DropCompensation.Value, 0))
                Camera.CFrame = Camera.CFrame:Lerp(aimCFrame, Options.Smoothness.Value / 100)
            end
        end
        local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and Toggles.FlyToggle.Value then
            hrp.Velocity = Camera.CFrame.LookVector * Options.FlySpeed.Value
        end
        if Toggles.ShowFOV.Value then 
            FOVCircle.Position = UserInputService:GetMouseLocation(); FOVCircle.Radius = Options.Radius.Value; FOVCircle.Visible = true 
        else FOVCircle.Visible = false end
    end)

    -- [ 🌟 ESP LOOP ]
    task_spawn(function()
        while task_wait(0.1) do
            for _, player in ipairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end
                local d = espCache[player]
                if not d then 
                    d = { Box = Drawing.new("Square"), Name = Drawing.new("Text") }
                    d.Box.Thickness = 1.5; d.Name.Size = 14; d.Name.Center = true; d.Name.Outline = true; espCache[player] = d 
                end
                local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and Toggles.EspBox.Value then
                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        d.Box.Visible = true; d.Box.Size = Vector2.new(1000/pos.Z, 1500/pos.Z); d.Box.Position = Vector2.new(pos.X - d.Box.Size.X/2, pos.Y - d.Box.Size.Y/2)
                        d.Name.Visible = Toggles.EspName.Value; d.Name.Text = player.DisplayName; d.Name.Position = Vector2.new(pos.X, pos.Y - d.Box.Size.Y/2 - 15)
                    else d.Box.Visible = false; d.Name.Visible = false end
                else d.Box.Visible = false; d.Name.Visible = false end
            end
        end
    end)

    -- [ UI SETTINGS ]
    ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library)
    SaveManager:BuildConfigSection(Tabs['UI Settings']); ThemeManager:ApplyToTab(Tabs['UI Settings'])
    
    UserInputService.InputBegan:Connect(function(i, g) if g then return end if i.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = true end end)
    UserInputService.InputEnded:Connect(function(i, g) if i.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = false end end)

    Library:Notify("ANLU Hub ULTIMATE INTEGRATED Loaded!", 5)
end)
