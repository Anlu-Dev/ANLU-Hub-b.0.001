-- =============================================================================
-- ANLU Hub(Rivals) - VOLT EXECUTOR EDITION
-- Optimized for Mobile/Lite Executors
-- =============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [ 🌟 SIMPLE UI SYSTEM (No External Library for Volt Stability) ]
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 280)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.Text = " ANLU Hub - VOLT"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

-- [ Toggle Function Helper ]
local function CreateToggle(name, pos, default, callback)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, pos)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    btn.Text = name .. (default and ": ON" or ": OFF")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = name .. (state and ": ON" or ": OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        callback(state)
    end)
end

-- [ 🌟 STATE ]
local AimbotEnabled = false
local SilentEnabled = false
local FlyEnabled = false
local EspEnabled = false
local isRightMouseDown = false
local CachedTarget = nil

-- [ 🌟 FEATURES ]
CreateToggle("Aimbot", 40, false, function(v) AimbotEnabled = v end)
CreateToggle("Silent Aim", 85, false, function(v) SilentEnabled = v end)
CreateToggle("Fly", 130, false, function(v) FlyEnabled = v end)
CreateToggle("Box ESP", 175, false, function(v) EspEnabled = v end)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0.9, 0, 0, 30)
CloseBtn.Position = UDim2.new(0.05, 0, 0, 230)
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CloseBtn.Text = "UNLOAD"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- [ 🌟 LOGIC ]
local function getClosest()
    local target, maxDist = nil, 400
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

-- [ 🌟 VOLT STABLE LOOP ]
RunService.RenderStepped:Connect(function()
    if SilentEnabled or AimbotEnabled then CachedTarget = getClosest() end
    
    if AimbotEnabled and isRightMouseDown and CachedTarget then
        local head = CachedTarget.Character:FindFirstChild("Head")
        if head then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, head.Position), 0.1)
        end
    end
    
    local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and FlyEnabled then
        hrp.Velocity = Camera.CFrame.LookVector * 50
    end
end)

-- [ 🌟 METATABLE (VOLT COMPATIBLE) ]
local mt = getrawmetatable(game)
if mt then
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and method == "FireServer" and self.Name == "UseItem" and SilentEnabled and CachedTarget then
            local args = {...}
            if args[3] and type(args[3]) == "table" and args[3]["\001"] then
                local head = CachedTarget.Character:FindFirstChild("Head")
                if head then
                    args[3]["\001"]["\001"] = {["\001"] = head.Position.X, ["\000"] = head.Position.Y, ["\002"] = head.Position.Z}
                    args[3]["\001"]["\002"] = head
                end
            end
            return old(self, unpack(args))
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end

UserInputService.InputBegan:Connect(function(i, g) if not g and i.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = true end end)
UserInputService.InputEnded:Connect(function(i, g) if i.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = false end end)

print("ANLU Hub Volt Loaded!")
