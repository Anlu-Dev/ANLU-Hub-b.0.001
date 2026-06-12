-- =============================================================================
-- ANLU Hub(Rivals) - ULTRA STABLE INTEGRATED EDITION
-- FIXED: Script Timeout / Freezing
-- =============================================================================

-- [ 🌟 ASYNC INITIALIZATION ]
task_spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [ Performance Localization ]
local Vector3_new = Vector3.new
local Vector2_new = Vector2.new
local CFrame_new = CFrame.new
local Color3_fromRGB = Color3.fromRGB
local math_abs = math.abs
local math_random = math.random
local task_spawn = task.spawn
local task_wait = task.wait

-- [ UI Library ]
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'ANLU Hub(Rivals) - ULTRA STABLE',
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
local angle = 0
local isRightMouseDown = false
local espCache = {}
local CachedSilentTarget = nil
local keyStates = { W = false, A = false, S = false, D = false }

local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3_fromRGB(255, 0, 50)
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false

-- [ 🌟 CORE: ASYNC HOOKS (PREVENTS TIMEOUT) ]
_G.UnlockAllActive = false
_G.HooksInitialized = false

local function SafeInit()
    if _G.HooksInitialized then return end
    
    task_spawn(function()
        local controllers = LocalPlayer.PlayerScripts:WaitForChild("Controllers", 15)
        if not controllers then return end
        
        -- 단계별 로딩 (프리징 방지)
        pcall(function()
            _G.EnumLibrary = require(ReplicatedStorage.Modules:WaitForChild("EnumLibrary", 5))
            task_wait(0.1)
            _G.CosmeticLibrary = require(ReplicatedStorage.Modules:WaitForChild("CosmeticLibrary", 5))
            task_wait(0.1)
            _G.DataController = require(controllers:WaitForChild("PlayerDataController", 5))
        end)
        
        if _G.DataController then
            local origGetWeaponData = _G.DataController.GetWeaponData
            _G.DataController.GetWeaponData = function(self, weaponName)
                local data = origGetWeaponData(self, weaponName)
                if not data then return nil end
                local merged = table.clone(data)
                if Toggles.ForceAutomatic and Toggles.ForceAutomatic.Value then
                    merged.Automatic = true; merged.IsAutomatic = true; merged.FireMode = "Automatic"
                end
                if Toggles.RapidFireToggle and Toggles.RapidFireToggle.Value then
                    merged.FireRate = Options.RapidFireDelay.Value or 0.01; merged.EquipTime = 0
                end
                return merged
            end
        end
        _G.HooksInitialized = true
    end)
end

-- [ UI SECTIONS ]
local AimbotTab = Tabs.Main:AddLeftGroupbox('Aimbot')
AimbotTab:AddToggle('AimbotEnabled', { Text = 'Enable Aimbot', Default = false })
AimbotTab:AddSlider('Smoothness', { Text = 'Smoothing', Default = 10, Min = 1, Max = 100, Rounding = 1 })

local SilentTab = Tabs.Main:AddRightGroupbox('Silent Aim')
SilentTab:AddToggle('SilentEnabled', { Text = 'Enable Silent Aim', Default = false })
SilentTab:AddSlider('Radius', { Text = 'FOV Radius', Default = 400, Min = 0, Max = 1000, Rounding = 0 })
SilentTab:AddSlider('HitChance', { Text = 'Hit Chance (%)', Default = 100, Min = 0, Max = 100, Rounding = 0 })

local MovementBox = Tabs.Player:AddLeftGroupbox('Movement')
MovementBox:AddToggle('FlyToggle', { Text = 'Enable Fly', Default = false })
MovementBox:AddSlider('FlySpeed', { Text = 'Fly Speed', Default = 50, Min = 1, Max = 300, Rounding = 0 })

local EspGroupBox = Tabs.Visuals:AddLeftGroupbox('ESP')
EspGroupBox:AddToggle('EspBox', { Text = 'Box ESP', Default = false })
EspGroupBox:AddToggle('EspName', { Text = 'Names', Default = false })

local WorldBox = Tabs.World:AddLeftGroupbox('World')
WorldBox:AddToggle('Fullbright', { Text = 'Fullbright', Default = false }):OnChanged(function()
    Lighting.Brightness = Toggles.Fullbright.Value and 2 or 1
end)

local WeaponBox = Tabs.Misc:AddLeftGroupbox('Weapon Mods')
WeaponBox:AddToggle('ForceAutomatic', { Text = '강제 자동 발사', Default = false }):OnChanged(SafeInit)
WeaponBox:AddToggle('RapidFireToggle', { Text = '극한 연사', Default = false }):OnChanged(SafeInit)
WeaponBox:AddSlider('RapidFireDelay', { Text = '연사 딜레이', Default = 0.01, Min = 0.00, Max = 0.2, Rounding = 3 })

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu Bind'):AddKeyPicker('MenuKeybind', { Default = 'RightShift', NoUI = true, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library)
SaveManager:BuildConfigSection(Tabs['UI Settings']); ThemeManager:ApplyToTab(Tabs['UI Settings'])

-- [ 🌟 BACKEND CORE ENGINE ]

local function getClosestPlayer()
    if not Options.Radius then return nil end
    local target, maxDist = nil, Options.Radius.Value
    local mousePos = UserInputService:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local dist = (Vector2_new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < maxDist then maxDist = dist target = p end
            end
        end
    end
    return target
end

-- ESP 업데이트 (주기적 실행으로 부하 감소)
task_spawn(function()
    while task_wait(0.1) do
        if not Library then break end
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local d = espCache[player]
            if not d then 
                d = { Box = Drawing.new("Square"), TopGui = Instance.new("BillboardGui"), TopLabel = Instance.new("TextLabel") }
                d.Box.Thickness = 1.5; d.TopGui.AlwaysOnTop = true; d.TopGui.Size = UDim2.new(0, 200, 0, 50)
                d.TopLabel.Size = UDim2.new(1,0,1,0); d.TopLabel.BackgroundTransparency = 1; d.TopLabel.Font = Enum.Font.SourceSansBold; d.TopLabel.TextSize = 14; d.TopLabel.Parent = d.TopGui
                d.TopGui.Parent = CoreGui; espCache[player] = d 
            end
            local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local head = char and char:FindFirstChild("Head"); local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and head and hum and hum.Health > 0 then
                local _, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local top, topOn = Camera:WorldToViewportPoint(head.Position + Vector3_new(0, 1.8, 0)); local bot, botOn = Camera:WorldToViewportPoint(hrp.Position - Vector3_new(0, 3.2, 0))
                    if topOn and botOn then
                        local sizeY = math_abs(top.Y - bot.Y); local sizeX = sizeY * 0.65; local boxPos = Vector2_new(top.X - (sizeX / 2), top.Y)
                        d.Box.Visible = Toggles.EspBox.Value; if d.Box.Visible then d.Box.Size = Vector2_new(sizeX, sizeY); d.Box.Position = boxPos; d.Box.Color = Color3_fromRGB(255,255,255) end
                        if Toggles.EspName.Value then d.TopGui.Adornee = head; d.TopLabel.Text = player.DisplayName; d.TopGui.Enabled = true else d.TopGui.Enabled = false end
                    else d.Box.Visible=false; d.TopGui.Enabled=false end
                else d.Box.Visible=false; d.TopGui.Enabled=false end
            else d.Box.Visible=false; d.TopGui.Enabled=false end
        end
    end
end)

-- [ 🌟 METATABLE ]
local mt = getrawmetatable(game); local oldNamecall = mt.__namecall; setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod(); local args = {...}
    if not checkcaller() and method == "FireServer" and self.Name == "UseItem" then
        if Toggles.SilentEnabled.Value and math_random(1, 100) <= Options.HitChance.Value then
            local target = CachedSilentTarget
            if target and target.Character then
                local head = target.Character:FindFirstChild("Head")
                if head and args[3] and type(args[3]) == "table" and args[3]["\001"] then
                    local hitPos = head.Position
                    local data = args[3]["\001"]; if data["\001"] then data["\001"]["\001"], data["\001"]["\000"], data["\001"]["\002"] = hitPos.X, hitPos.Y, hitPos.Z end
                    data["\002"] = head
                end
            end
        end
    end
    return oldNamecall(self, unpack(args))
end)
setreadonly(mt, true)

-- [ 🌟 MAIN RENDER LOOP ]
RunService.RenderStepped:Connect(function()
    if Toggles.SilentEnabled.Value then CachedSilentTarget = getClosestPlayer() end
    if Toggles.AimbotEnabled.Value and isRightMouseDown and CachedSilentTarget then
        local head = CachedSilentTarget.Character and CachedSilentTarget.Character:FindFirstChild("Head")
        if head then
            local aimCFrame = CFrame_new(Camera.CFrame.Position, head.Position)
            Camera.CFrame = Camera.CFrame:Lerp(aimCFrame, math.clamp(Options.Smoothness.Value / 100, 0.01, 1))
        end
    end
    local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and Toggles.FlyToggle.Value then
        local moveDir = Vector3_new(0,0,0)
        if keyStates.W then moveDir = moveDir + Camera.CFrame.LookVector end
        if keyStates.S then moveDir = moveDir - Camera.CFrame.LookVector end
        if keyStates.A then moveDir = moveDir - Camera.CFrame.RightVector end
        if keyStates.D then moveDir = moveDir + Camera.CFrame.RightVector end
        hrp.Velocity = moveDir.Unit * Options.FlySpeed.Value
    end
    if Toggles.ShowFOV.Value then FOVCircle.Position = UserInputService:GetMouseLocation(); FOVCircle.Radius = Options.Radius.Value; FOVCircle.Visible = true else FOVCircle.Visible = false end
end)

-- [ INPUT ]
UserInputService.InputBegan:Connect(function(i, g) if g then return end if i.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = true end local code = i.KeyCode.Name; if keyStates[code] ~= nil then keyStates[code] = true end end)
UserInputService.InputEnded:Connect(function(i, g) if i.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = false end local code = i.KeyCode.Name; if keyStates[code] ~= nil then keyStates[code] = false end end)

Library:Notify("ANLU Hub ULTRA STABLE Loaded!", 5)
