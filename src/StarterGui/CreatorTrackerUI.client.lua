local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage:WaitForChild("CreatorTrackerConfig"))

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "CreatorTrackerUI"
gui.ResetOnSpawn = false

gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Container"
frame.Parent = gui
frame.AnchorPoint = Vector2.new(1, 0)
frame.Position = UDim2.new(1, -20, 0, 20)
frame.Size = UDim2.new(0, 280, 0, 220)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "Creator Tracker"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 22

title.TextXAlignment = Enum.TextXAlignment.Left

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = frame
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 50)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Waiting for creator data..."
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

local creatorList = Instance.new("ScrollingFrame")
creatorList.Parent = frame
creatorList.Position = UDim2.new(0, 10, 0, 80)
creatorList.Size = UDim2.new(1, -20, 1, -140)
creatorList.CanvasSize = UDim2.new(0, 0, 0, 0)
creatorList.ScrollBarThickness = 6
creatorList.BackgroundTransparency = 1

local uiList = Instance.new("UIListLayout")
uiList.Parent = creatorList
uiList.Padding = UDim.new(0, 6)
uiList.SortOrder = Enum.SortOrder.LayoutOrder

local afkButton = Instance.new("TextButton")
afkButton.Parent = frame
afkButton.Size = UDim2.new(0.5, -15, 0, 28)
afkButton.Position = UDim2.new(0, 10, 1, -33)
afkButton.Text = "Toggle AFK"
afkButton.Font = Enum.Font.GothamSemibold
afkButton.TextSize = 16
afkButton.BackgroundColor3 = Color3.fromRGB(45, 120, 255)
afkButton.TextColor3 = Color3.new(1, 1, 1)
afkButton.BorderSizePixel = 0

local refreshButton = afkButton:Clone()
refreshButton.Parent = frame
refreshButton.Position = UDim2.new(0.5, 5, 1, -33)
refreshButton.Text = "Refresh"
refreshButton.BackgroundColor3 = Color3.fromRGB(60, 180, 75)

local function setStatus(text)
    statusLabel.Text = text
end

local function createCreatorButton(creator)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -4, 0, 36)
    button.Text = creator.displayName or ("User %d"):format(creator.userId)
    button.Font = Enum.Font.Gotham
    button.TextSize = 18
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.BorderSizePixel = 0

    local statusText = Instance.new("TextLabel")
    statusText.Parent = button
    statusText.BackgroundTransparency = 1
    statusText.AnchorPoint = Vector2.new(1, 0.5)
    statusText.Position = UDim2.new(1, -10, 0.5, 0)
    statusText.Size = UDim2.new(0.4, 0, 1, 0)
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 14
    statusText.TextColor3 = Color3.fromRGB(180, 180, 180)
    statusText.TextXAlignment = Enum.TextXAlignment.Right
    statusText.Text = creator.isLive and "LIVE" or "Offline"

    button.MouseButton1Click:Connect(function()
        player:SetAttribute("FavoriteCreator", creator.userId)
        setStatus(string.format("Following %s", creator.displayName))
    end)

    return button
end

local function rebuildCreatorList()
    creatorList:ClearAllChildren()
    uiList.Parent = creatorList
    for _, creator in ipairs(Config.Creators) do
        local info = {
            displayName = creator.displayName,
            userId = creator.userId,
            isLive = false,
        }
        local button = createCreatorButton(info)
        button.Parent = creatorList
    end
    creatorList.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y)
end

rebuildCreatorList()

afkButton.MouseButton1Click:Connect(function()
    player:SetAttribute("IsAFK", not player:GetAttribute("IsAFK"))
    setStatus(player:GetAttribute("IsAFK") and "AFK Enabled" or "AFK Disabled")
end)

refreshButton.MouseButton1Click:Connect(function()
    setStatus("Requesting latest status...")
    task.delay(1, function()
        setStatus("Status refreshed")
    end)
end)

gui:GetPropertyChangedSignal("Parent"):Connect(function()
    if gui.Parent then
        gui.Parent = player:WaitForChild("PlayerGui")
    end
end)
