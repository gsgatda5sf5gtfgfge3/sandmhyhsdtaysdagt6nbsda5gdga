--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--// CONFIG
getgenv().Config = {
    SilentPrediction = {
        Enabled = true,
        Prediction = 0.135,
        TargetPart = "HumanoidRootPart",
        LockedTarget = nil,
        FOVRadius = 250,
        ShowFOV = false,
        FOVColor = Color3.fromRGB(255, 0, 0),
        FOVTransparency = 0.5,
        FOVThickness = 1
    },
    TriggerBot = {
        Enabled = true,
        Hotkey = Enum.KeyCode.T,
        HotkeyToggle = true,
        DelayTime = 0.0000000000001,
        LastActionTime = 0
    },
    WalkSpeed = {
        Enabled = false,
        Speed = 450
    },
    WallCheck = {
        Enabled = true
    },
    InfiniteJump = {
        Enabled = false
    },
    SpreadMod = {
        BulletSpread = {
            Enabled = true,
            Amount = 38
        }
    }
}

local SilentPrediction = getgenv().Config.SilentPrediction
local TriggerBot = getgenv().Config.TriggerBot
local WalkSpeed = getgenv().Config.WalkSpeed
local WallCheck = getgenv().Config.WallCheck
local InfiniteJump = getgenv().Config.InfiniteJump
local SpreadMod = getgenv().Config.SpreadMod

-- Modify math.random to incorporate BulletSpread
local old_random; old_random = hookfunction(math.random, function(...)
    local args = {...}
    if checkcaller() then
        return old_random(...)
    end
    if (#args == 0) or (args[1] == -0.05 and args[2] == 0.05) or (args[1] == -0.1) or (args[1] == -0.05) then
        if SpreadMod.BulletSpread.Enabled then
            local spread = SpreadMod.BulletSpread.Amount
            return old_random(...) * (spread / 100)
        else
            return old_random(...)
        end
    end
    return old_random(...)
end)

-- TriggerBot Hotkey Handling
local TriggerBotToggle = TriggerBot.Enabled
local TriggerBotHeld = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TriggerBot.Hotkey then
        if TriggerBot.HotkeyToggle then
            TriggerBotToggle = not TriggerBotToggle
        else
            TriggerBotHeld = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == TriggerBot.Hotkey and not TriggerBot.HotkeyToggle then
        TriggerBotHeld = false
    end
end)

-- Anti-hook and Interceptor Code START
local exe_name, exe_version = identifyexecutor()
local function home999() end
local function home888() end

if exe_name ~= "Wave Windows" then
    hookfunction(home888, home999)
    if not isfunctionhooked(home888) then
        LocalPlayer:Destroy()
        return LPH_CRASH()
    end
end

local function check_env(env)
    for _, func in pairs(env) do
        if type(func) ~= "function" then continue end
        if isfunctionhooked(func) then
            LocalPlayer:Destroy()
            return LPH_CRASH()
        end
    end
end

check_env(getgenv())
check_env(getrenv())

local Lua_Fetch_Connections = getconnections
local Lua_Fetch_Upvalues = getupvalues
local Lua_Hook = hookfunction
local Lua_Hook_Method = hookmetamethod
local Lua_Unhook = restorefunction
local Lua_Replace_Function = replaceclosure
local Lua_Set_Upvalue = setupvalue
local Lua_Clone_Function = clonefunction

local Game_RunService = RunService
local Game_LogService = game:GetService("LogService")
local Game_LogService_MessageOut = Game_LogService.MessageOut

local String_Lower = string.lower
local Table_Find = table.find

local Current_Connections = {}
local Hooked_Connections = {}

local function auth_heart()
    return true, true
end

local function XVNP_L(CONNECTION)
    pcall(function()
        local upvals = Lua_Fetch_Upvalues(CONNECTION.Function)
        local func = upvals[9][1]
        Lua_Set_Upvalue(func, 14, function(...) return function(...) end end)
        Lua_Set_Upvalue(func, 1, function(...) task.wait(200) end)
        Lua_Hook(func, function(...) return {} end)
    end)
end

local lastUpdate, updateGap = 0, 5
local ConnMonitor = RunService.RenderStepped:Connect(function()
    if #Lua_Fetch_Connections(Game_LogService_MessageOut) >= 2 then ConnMonitor:Disconnect() end
    if tick() - lastUpdate >= updateGap then
        lastUpdate = tick()
        for _, conn in ipairs(Lua_Fetch_Connections(Game_LogService_MessageOut)) do
            if not Table_Find(Current_Connections, conn) then
                table.insert(Current_Connections, conn)
                table.insert(Hooked_Connections, conn)
                XVNP_L(conn)
            end
        end
    end
end)

local validateCount, lastPulse = 0, 0
RunService.RenderStepped:Connect(function()
    if tick() > lastPulse + 1 then
        lastPulse = tick()
        local check1, check2 = auth_heart()
        if not check1 or not check2 then
            if validateCount <= 0 then
                LocalPlayer:Destroy()
                return LPH_CRASH()
            else
                validateCount -= 1
            end
        else
            validateCount += 1
        end
    end
end)

-- FOV CIRCLE
local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false
FOVCircle.Visible = SilentPrediction.ShowFOV
FOVCircle.Color = SilentPrediction.FOVColor
FOVCircle.Radius = SilentPrediction.FOVRadius
FOVCircle.Thickness = SilentPrediction.FOVThickness
FOVCircle.Transparency = SilentPrediction.FOVTransparency

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
    FOVCircle.Visible = SilentPrediction.ShowFOV
end)

-- Wall Check
local function IsVisible(part)
    if not WallCheck.Enabled then return true end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character or workspace:FindFirstChild(LocalPlayer.Name)}

    local result = workspace:Raycast(origin, direction, raycastParams)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

-- Closest Player Logic
function SilentPrediction:GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = self.FOVRadius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(self.TargetPart) then
            local part = player.Character[self.TargetPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen and IsVisible(part) then
                local distance = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                if distance <= self.FOVRadius and distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- Predict
local function PredictHit(part, prediction)
    local velocity = part.Velocity
    return part.Position + (velocity * prediction)
end

-- Lock Target
RunService.RenderStepped:Connect(function()
    if SilentPrediction.Enabled then
        SilentPrediction.LockedTarget = SilentPrediction:GetClosestPlayer()
    else
        SilentPrediction.LockedTarget = nil
    end
end)

-- Hook Mouse.Hit
local OriginalIndex
OriginalIndex = hookmetamethod(game, "__index", newcclosure(function(object, key, ...)
    if SilentPrediction.Enabled and object:IsA("Mouse") and key == "Hit" then
        local target = SilentPrediction.LockedTarget
        if target and target.Character then
            local hitPart = target.Character:FindFirstChild(SilentPrediction.TargetPart)
            if hitPart and IsVisible(hitPart) then
                local predictedPosition = PredictHit(hitPart, SilentPrediction.Prediction)
                return CFrame.new(predictedPosition)
            end
        end
    end
    return OriginalIndex(object, key, ...)
end))

-- TriggerBot Execution
RunService.RenderStepped:Connect(function()
    local active = TriggerBot.HotkeyToggle and TriggerBotToggle or TriggerBotHeld
    if TriggerBot.Enabled and active then
        if SilentPrediction.LockedTarget then
            local target = SilentPrediction.LockedTarget
            if target and target.Character then
                local hitPart = target.Character:FindFirstChild(SilentPrediction.TargetPart)
                if hitPart and IsVisible(hitPart) then
                    if tick() - TriggerBot.LastActionTime >= TriggerBot.DelayTime then
                        mouse1click()
                        TriggerBot.LastActionTime = tick()
                    end
                end
            end
        end
    end
end)

-- WalkSpeed Enforcement
if WalkSpeed.Enabled then
    local function applySpeed()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                hum.WalkSpeed = WalkSpeed.Speed
            end)
            hum.WalkSpeed = WalkSpeed.Speed
        end
    end

    applySpeed()
    LocalPlayer.CharacterAdded:Connect(function()
        repeat task.wait() until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        applySpeed()
    end)
end

-- Infinite Jump System
if InfiniteJump and InfiniteJump.Enabled then
    local rawmetatable = getrawmetatable(game)
    setreadonly(rawmetatable, false)

    local oldNewIndex
    oldNewIndex = hookmetamethod(game, "__newindex", function(self, Index, Value)
        if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") and Index == "JumpPower" then
            return
        end
        return oldNewIndex(self, Index, Value)
    end)

    UserInputService.JumpRequest:Connect(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum:GetState() ~= Enum.HumanoidStateType.Seated then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

-- Anti-Kick
for _, obj in pairs(getgc(true)) do
    if type(obj) == "table" then
        setreadonly(obj, false)
        local indexInstance = rawget(obj, "indexInstance")
        if type(indexInstance) == "table" and indexInstance[1] == "kick" then
            setreadonly(indexInstance, false)
            rawset(obj, "Table", {"kick", function() coroutine.yield() end})
            break
        end
    end
end