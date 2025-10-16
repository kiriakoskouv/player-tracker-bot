local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("CreatorTrackerConfig"))
local AIDecisionEngine = require(script.Parent:WaitForChild("AIDecisionEngine"))

local CreatorTracker = {}
CreatorTracker.__index = CreatorTracker

local PRESENCE_ENDPOINT = "https://presence.roblox.com/v1/presence/users"

local function log(message, ...)
    local formatted = string.format("[CreatorTracker] %s", message)
    print(formatted:format(...))
end

function CreatorTracker.new()
    local self = setmetatable({}, CreatorTracker)
    self.ai = AIDecisionEngine.new(Config)
    self.lastPresence = {}
    self.lastDiscordNotify = {}
    self._maid = {}
    return self
end

function CreatorTracker:getPresence(userIds)
    local payload = HttpService:JSONEncode({
        userIds = userIds,
    })

    local response, status, err = HttpService:PostAsync(PRESENCE_ENDPOINT, payload, Enum.HttpContentType.ApplicationJson, false, {
        Url = PRESENCE_ENDPOINT,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
        },
        Body = payload,
    })

    if not response then
        warn("CreatorTracker failed to fetch presence:", status or err)
        return nil
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not ok then
        warn("CreatorTracker failed to decode presence:", decoded)
        return nil
    end

    return decoded.userPresences or {}
end

function CreatorTracker:augmentPresence(raw)
    local presence = {
        userId = raw.userId,
        userPresenceType = raw.userPresenceType,
        placeId = raw.placeId,
        rootPlaceId = raw.rootPlaceId,
        universeId = raw.universeId,
        lastLocation = raw.lastLocation,
        displayName = raw.lastLocation or "",
    }

    presence.isLive = raw.userPresenceType == 2 or raw.userPresenceType == 3
    presence.activity = presence.isLive and "Game" or "Offline"
    presence.gamePlaceId = raw.placeId
    return presence
end

function CreatorTracker:updateCreator(creatorEntry, presence)
    local info = {
        userId = creatorEntry.userId,
        displayName = creatorEntry.displayName,
        autoTeleport = creatorEntry.autoTeleport,
        isLive = presence and presence.isLive or false,
        activity = presence and presence.activity or "Offline",
        gamePlaceId = presence and presence.gamePlaceId or nil,
        gameInstanceId = presence and presence.lastLocation or nil,
    }

    self.lastPresence[info.userId] = info
    return info
end

function CreatorTracker:shouldTeleport(player, creatorInfo)
    if not Config.TeleportOnJoin then
        return false
    end

    if not Config.EnableAIDecisionMaking then
        return creatorInfo.autoTeleport and creatorInfo.isLive
    end

    return self.ai:shouldTeleport(player, creatorInfo)
end

function CreatorTracker:notifyDiscord(creatorInfo)
    if not Config.Discord.Enabled then
        return
    end

    local last = self.lastDiscordNotify[creatorInfo.userId]
    if last and os.clock() - last < (Config.Discord.MinimumNotificationCooldown or 0) then
        return
    end

    self.lastDiscordNotify[creatorInfo.userId] = os.clock()

    task.spawn(function()
        local webhook = Config.Discord.WebhookUrl
        if not webhook or webhook == "" then
            warn("CreatorTracker Discord webhook not configured")
            return
        end

        local body = HttpService:JSONEncode({
            username = "Creator Tracker",
            embeds = {
                {
                    title = string.format("%s just started playing!", creatorInfo.displayName or creatorInfo.userId),
                    description = string.format("Place ID: %s", tostring(creatorInfo.gamePlaceId or "Unknown")),
                    color = 65280,
                    fields = {
                        {
                            name = "Auto Teleport",
                            value = creatorInfo.autoTeleport and "Enabled" or "Disabled",
                            inline = true,
                        },
                    },
                },
            },
        })

        local ok, err = pcall(function()
            HttpService:PostAsync(webhook, body, Enum.HttpContentType.ApplicationJson)
        end)

        if not ok then
            warn("CreatorTracker failed to notify Discord:", err)
        end
    end)
end

function CreatorTracker:pollCreators()
    local userIds = {}
    for _, creator in ipairs(Config.Creators) do
        table.insert(userIds, creator.userId)
    end

    if #userIds == 0 then
        return
    end

    local presences = self:getPresence(userIds)
    if not presences then
        return
    end

    for _, creator in ipairs(Config.Creators) do
        local presence
        for _, raw in ipairs(presences) do
            if raw.userId == creator.userId then
                presence = self:augmentPresence(raw)
                break
            end
        end

        local info = self:updateCreator(creator, presence)
        if info.isLive then
            self:notifyDiscord(info)
        end
    end
end

function CreatorTracker:teleportPlayerToCreator(player, creatorInfo)
    if not creatorInfo.gamePlaceId or not creatorInfo.gameInstanceId then
        log("Creator %s is missing place information", tostring(creatorInfo.displayName))
        return
    end

    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(creatorInfo.gamePlaceId, creatorInfo.gameInstanceId, player)
    end)

    if not ok then
        warn("CreatorTracker failed to teleport player:", err)
    end
end

function CreatorTracker:teleportInterestedPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        local favoriteCreator = player:GetAttribute("FavoriteCreator")
        if favoriteCreator then
            local info = self.lastPresence[favoriteCreator]
            if info and info.isLive and self:shouldTeleport(player, info) then
                self:teleportPlayerToCreator(player, info)
            end
        end
    end
end

function CreatorTracker:onPlayerAdded(player)
    player:SetAttribute("FavoriteCreator", nil)
    player:SetAttribute("LastCreatorCheck", os.clock())
end

function CreatorTracker:onPlayerRemoving(player)
    player:SetAttribute("FavoriteCreator", nil)
end

function CreatorTracker:assignFavoriteCreator(player, creatorUserId)
    if not creatorUserId then
        player:SetAttribute("FavoriteCreator", nil)
        return
    end

    for _, creator in ipairs(Config.Creators) do
        if creator.userId == creatorUserId then
            player:SetAttribute("FavoriteCreator", creatorUserId)
            player:SetAttribute("LastCreatorCheck", os.clock())
            log("%s is now following creator %s", player.Name, creator.displayName)
            return true
        end
    end

    warn("CreatorTracker: Invalid creator userId", creatorUserId)
    return false
end

function CreatorTracker:start()
    Players.PlayerAdded:Connect(function(player)
        self:onPlayerAdded(player)
    end)
    Players.PlayerRemoving:Connect(function(player)
        self:onPlayerRemoving(player)
    end)

    self:pollCreators()

    task.spawn(function()
        while true do
            self:pollCreators()
            task.wait(Config.PollInterval or 30)
        end
    end)

    task.spawn(function()
        while true do
            self:teleportInterestedPlayers()
            task.wait(5)
        end
    end)
end

local tracker = CreatorTracker.new()
tracker:start()

return tracker
