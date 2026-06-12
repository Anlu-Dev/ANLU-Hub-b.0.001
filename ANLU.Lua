-- =============================================================================
-- ANLU Hub(Rivals) - ULTIMATE FINAL EDITION
-- Optimized for Volt & All High-End Executors
-- =============================================================================

-- [ 🌟 FORCED ASYNC LOAD TO PREVENT TIMEOUT ]
task_spawn(function()
    local function SafeLoad(url)
        local success, result = pcall(function() return game:HttpGet(url) end)
        if success then return loadstring(result)() end
        return nil
    end

    local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
    local Library = SafeLoad(repo .. 'Library.lua')
    local ThemeManager = SafeLoad(repo .. 'addons/ThemeManager.lua')
    local SaveManager = SafeLoad(repo .. 'addons/SaveManager.lua')

    if not Library then return end

    local Window = Library:CreateWindow({
        Title = 'ANLU Hub(Rivals) - ULTIMATE FINAL',
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

    -- [ Services ]
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Lighting = game:GetService("Lighting")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera

    -- [ State ]
    local isRightMouseDown = false
    local CachedSilentTarget = nil
    local espCache = {}
    local keyStates = {W = false, A = false, S = false, D = false}
    local rainPE, snowPE = nil, nil

    -- [ 🌟 FEATURES: MAIN ]
    local AimbotTab = Tabs.Main:AddLeftGroupbox('Camera Lock-on Aimbot')
    AimbotTab:AddToggle('AimbotEnabled', { Text = 'Enable Camera Aimbot', Default = false })
    AimbotTab:AddSlider('Smoothness', { Text = 'Aimbot Smoothing', Default = 10, Min = 1, Max = 100, Rounding = 1 })
    AimbotTab:AddDropdown('AimbotPart', { Values = { 'Head', 'HumanoidRootPart' }, Default = 1, Text = 'Target Part' })

    local SilentTab = Tabs.Main:AddRightGroupbox('Hyper Silent Aim')
    SilentTab:AddToggle('SilentEnabled', { Text = 'Enable Silent Aim', Default = true })
    SilentTab:AddSlider('Radius', { Text = 'FOV Radius', Default = 400, Min = 0, Max = 1000, Rounding = 0 })
    SilentTab:AddSlider('HitChance', { Text = 'Hit Chance (%)', Default = 100, Min = 0, Max = 100, Rounding = 0 })
    SilentTab:AddSlider('DropCompensation', { Text = 'Drop Comp (Y-Offset)', Default = 1.5, Min = 0, Max = 10, Rounding = 1 })

    -- [ 🌟 FEATURES: PLAYER ]
    local MovementBox = Tabs.Player:AddLeftGroupbox('Movement Control')
    MovementBox:AddToggle('FlyToggle', { Text = 'Enable Fly', Default = false })
    MovementBox:AddSlider('FlySpeed', { Text = 'Fly Speed', Default = 50, Min = 1, Max = 300, Rounding = 0 })

    -- [ 🌟 FEATURES: VISUALS ]
    local EspBox = Tabs.Visuals:AddLeftGroupbox('ESP')
    EspBox:AddToggle('EspBox', { Text = 'Box ESP', Default = false })
    EspBox:AddToggle('EspName', { Text = 'Player Names', Default = false })

    -- [ 🌟 FEATURES: WORLD ]
    local WorldBox = Tabs.World:AddLeftGroupbox('Environment')
    WorldBox:AddToggle('Fullbright', { Text = 'Enable Fullbright', Default = false }):OnChanged(function()
        Lighting.Brightness = Toggles.Fullbright.Value and 2 or 1
    end)

    local weatherAnchor = Instance.new("Part", workspace)
    weatherAnchor.Anchored = true; weatherAnchor.CanCollide = false; weatherAnchor.Transparency = 1; weatherAnchor.Size = Vector3.new(1,1,1)

    Tabs.World:AddRightGroupbox('Weather'):AddToggle('RainEffect', { Text = 'Enable Rain', Default = false }):OnChanged(function()
        if Toggles.RainEffect.Value then
            rainPE = Instance.new("ParticleEmitter", weatherAnchor)
            rainPE.Texture = "rbxassetid://363276166"; rainPE.Rate = 500; rainPE.Speed = NumberRange.new(90, 130)
        else if rainPE then rainPE:Destroy(); rainPE = nil end end
    end)

    -- [ 🌟 FEATURES: MISC ]
    local WeaponBox = Tabs.Misc:AddLeftGroupbox('Weapon Mods')
    WeaponBox:AddToggle('ForceAutomatic', { Text = '강제 자동 발사', Default = false })
    WeaponBox:AddToggle('RapidFireToggle', { Text = '극한 연사', Default = false })
    WeaponBox:AddSlider('RapidFireDelay', { Text = '연사 딜레이', Default = 0.01, Min = 0.00, Max = 0.2, Rounding = 3 })

    -- [ 🌟 CORE LOGIC ]
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

    -- [ 🌟 METATABLE ]
    local mt = getrawmetatable(game)
    if mt then
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and method == "FireServer" and self.Name == "UseItem" and Toggles.SilentEnabled.Value and CachedSilentTarget then
                local args = {...}
                if args[3] and type(args[3]) == "table" and args[3]["\001"] then
                    local head = CachedSilentTarget.Character:FindFirstChild("Head")
                    if head then
                        local hitPos = head.Position + Vector3.new(0, Options.DropCompensation.Value, 0)
                        args[3]["\001"]["\001"] = {["\001"] = hitPos.X, ["\000"] = hitPos.Y, ["\002"] = hitPos.Z}
                        args[3]["\001"]["\002"] = head
                    end
                end
                return old(self, unpack(args))
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end

    -- [ 🌟 RENDER LOOP ]
    RunService.RenderStepped:Connect(function()
        if Toggles.SilentEnabled.Value then CachedSilentTarget = getClosest() end
        if Toggles.AimbotEnabled.Value and isRightMouseDown and CachedSilentTarget then
            local head = CachedSilentTarget.Character:FindFirstChild(Options.AimbotPart.Value)
            if head then
                local aimCFrame = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, Options.DropCompensation.Value, 0))
                Camera.CFrame = Camera.CFrame:Lerp(aimCFrame, Options.Smoothness.Value / 100)
            end
        end
        local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and Toggles.FlyToggle.Value then
            local moveDir = Vector3.new(0,0,0)
            if keyStates.W then moveDir = moveDir + Camera.CFrame.LookVector end
            if keyStates.S then moveDir = moveDir - Camera.CFrame.LookVector end
            if keyStates.A then moveDir = moveDir - Camera.CFrame.RightVector end
            if keyStates.D then moveDir = moveDir + Camera.CFrame.RightVector end
            hrp.Velocity = moveDir.Unit * Options.FlySpeed.Value
            if weatherAnchor then weatherAnchor.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 25, 0)) end
        end
    end)

    -- [ UI SETTINGS ]
    ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library)
    SaveManager:BuildConfigSection(Tabs['UI Settings']); ThemeManager:ApplyToTab(Tabs['UI Settings'])

    UserInputService.InputBegan:Connect(function(i, g) if g then return end if i.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = true end local code = i.KeyCode.Name; if keyStates[code] ~= nil then keyStates[code] = true end end)
    UserInputService.InputEnded:Connect(function(i, g) if i.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = false end local code = i.KeyCode.Name; if keyStates[code] ~= nil then keyStates[code] = false end end)

    Library:Notify("ANLU Hub ULTIMATE FINAL Loaded!", 5)
end)
