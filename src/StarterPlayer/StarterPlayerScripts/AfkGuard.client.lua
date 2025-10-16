local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local idleDebounce = false
local lastFakeInput = 0
local fakeInputInterval = 55

local function sendFakeInput()
    if os.clock() - lastFakeInput < fakeInputInterval then
        return
    end
    lastFakeInput = os.clock()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame)
end

localPlayer.Idled:Connect(function(timeIdle)
    if idleDebounce then
        return
    end
    idleDebounce = true
    sendFakeInput()
    task.delay(2, function()
        idleDebounce = false
    end)
end)

RunService.Stepped:Connect(function()
    if os.clock() - lastFakeInput >= fakeInputInterval then
        sendFakeInput()
    end
end)

local notificationBillboard = Instance.new("BillboardGui")
notificationBillboard.Name = "AFKNotification"
notificationBillboard.Size = UDim2.new(0, 200, 0, 50)
notificationBillboard.StudsOffset = Vector3.new(0, 3, 0)
notificationBillboard.AlwaysOnTop = true
notificationBillboard.Enabled = false

local textLabel = Instance.new("TextLabel")
textLabel.Parent = notificationBillboard
textLabel.BackgroundTransparency = 1
textLabel.Size = UDim2.new(1, 0, 1, 0)
textLabel.TextScaled = true
textLabel.Font = Enum.Font.GothamSemibold
textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
textLabel.Text = "AFK MODE" 

local function attachBillboard(character)
    if notificationBillboard.Parent ~= character then
        notificationBillboard.Parent = character:WaitForChild("Head", 5) or character
    end
end

local function onCharacterAdded(character)
    attachBillboard(character)
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)
if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end

local toggleBindable = Instance.new("BindableEvent")
toggleBindable.Name = "ToggleAFKMode"
toggleBindable.Parent = localPlayer:WaitForChild("PlayerGui")

toggleBindable.Event:Connect(function(isEnabled)
    notificationBillboard.Enabled = isEnabled
    if isEnabled then
        sendFakeInput()
    end
end)
