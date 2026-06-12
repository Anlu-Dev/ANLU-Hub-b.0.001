-- =============================================================================
-- ANLU Hub(Rivals) - UNIVERSAL COMPATIBILITY EDITION
-- Fixed: Execution Issues / Freezing
-- =============================================================================

print("[ANLU] Initializing...")

-- [ 🌟 UI LIBRARY LOAD WITH RETRY ]
local function LoadLibrary()
    local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
    local success, result = pcall(function()
        return loadstring(game:HttpGet(repo .. 'Library.lua'))()
    end)
    if success and result then return result end
    warn("[ANLU] Failed to load UI Library from GitHub.")
    return nil
end

local Library = LoadLibrary()
if not Library then
    print("[ANLU] FATAL: UI Library could not be loaded.")
    return
end

local Window = Library:CreateWindow({
    Title = 'ANLU Hub - UNIVERSAL',
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Main = Window:AddTab('Main'),
    Player = Window:AddTab('Player'),
    Visuals = Window:AddTab('Visuals'),
    Misc = Window:AddTab('Misc'),
}

-- [ Services ]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [ State ]
local isRightMouseDown = false
local CachedSilentTarget = nil
local keyStates = {W = false, A = false, S = false, D = false}

-- [ 🌟 MAIN FEATURES ]
local AimbotTab = Tabs.Main:AddLeftGroupbox('Aimbot')
AimbotTab:AddToggle('AimbotEnabled', { Text = 'Enable Aimbot', Default = false })
AimbotTab:AddSlider('Smoothness', { Text = 'Smoothing', Default = 10, Min = 1, Max = 100, Rounding = 1 })

local SilentTab = Tabs.Main:AddRightGroupbox('Silent Aim')
SilentTab:AddToggle('SilentEnabled', { Text = 'Enable Silent Aim', Default = false })
SilentTab:AddSlider('Radius', { Text = 'FOV Radius', Default = 300, Min = 0, Max = 1000, Rounding = 0 })

local MovementBox = Tabs.Player:AddLeftGroupbox('Movement')
MovementBox:AddToggle('FlyToggle', { Text = 'Enable Fly', Default = false })
MovementBox:AddSlider('FlySpeed', { Text = 'Fly Speed', Default = 50, Min = 1, Max = 300, Rounding = 0 })

local EspBox = Tabs.Visuals:AddLeftGroupbox('ESP')
EspBox:AddToggle('EspBox', { Text = 'Box ESP', Default = false })

-- [ 🌟 FUNCTIONS ]
local function getClosestPlayer()
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

-- [ 🌟 METATABLE HOOK (SAFE) ]
local function HookNamecall()
    local mt = getrawmetatable(game)
    if not mt then warn("[ANLU] getrawmetatable not supported.") return end
    
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if not checkcaller() and method == "FireServer" and self.Name == "UseItem" then
            if Toggles.SilentEnabled.Value and CachedSilentTarget then
                local head = CachedSilentTarget.Character:FindFirstChild("Head")
                if head and args[3] and type(args[3]) == "table" and args[3]["\001"] then
                    local data = args[3]["\001"]
                    if data["\001"] then 
                        data["\001"]["\001"], data["\001"]["\000"], data["\001"]["\002"] = head.Position.X, head.Position.Y, head.Position.Z 
                    end
                    data["\002"] = head
                end
            end
        end
        return oldNamecall(self, unpack(args))
    end)
    setreadonly(mt, true)
    print("[ANLU] Metatable hooked.")
end

pcall(HookNamecall)

-- [ 🌟 MAIN LOOP ]
RunService.RenderStepped:Connect(function()
    if Toggles.SilentEnabled.Value then CachedSilentTarget = getClosestPlayer() end
    if Toggles.AimbotEnabled.Value and isRightMouseDown and CachedSilentTarget then
        local head = CachedSilentTarget.Character and CachedSilentTarget.Character:FindFirstChild("Head")
        if head then
            local aimCFrame = CFrame.new(Camera.CFrame.Position, head.Position)
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
    end
end)

-- [ INPUT ]
UserInputService.InputBegan:Connect(function(i, g) if g then return end if i.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = true end local code = i.KeyCode.Name; if keyStates[code] ~= nil then keyStates[code] = true end end)
UserInputService.InputEnded:Connect(function(i, g) if i.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = false end local code = i.KeyCode.Name; if keyStates[code] ~= nil then keyStates[code] = false end end)

print("[ANLU] Script fully loaded.")
Library:Notify("ANLU Hub Loaded!", 5)
