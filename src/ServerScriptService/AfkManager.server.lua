local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("CreatorTrackerConfig"))

local AfkManager = {}
AfkManager.__index = AfkManager

function AfkManager.new()
    local self = setmetatable({}, AfkManager)
    self.afkPlayers = {}
    return self
end

function AfkManager:setAfk(player, isAfk)
    player:SetAttribute("IsAFK", isAfk)
    self.afkPlayers[player.UserId] = isAfk or nil
    local toggleBindable = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("ToggleAFKMode")
    if toggleBindable then
        toggleBindable:Fire(isAfk)
    end
end

function AfkManager:toggleAfk(player)
    local current = self.afkPlayers[player.UserId]
    self:setAfk(player, not current)
end

function AfkManager:onPlayerAdded(player)
    self:setAfk(player, false)
    player.Chatted:Connect(function(message)
        if message:lower() == "/afk" or message:lower() == "!afk" then
            self:toggleAfk(player)
        end
    end)
end

function AfkManager:start()
    Players.PlayerAdded:Connect(function(player)
        self:onPlayerAdded(player)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        self:onPlayerAdded(player)
    end
end

local manager = AfkManager.new()
manager:start()

return manager
