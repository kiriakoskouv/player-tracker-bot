local HttpService = game:GetService("HttpService")

local AIDecisionEngine = {}
AIDecisionEngine.__index = AIDecisionEngine

function AIDecisionEngine.new(config)
    local self = setmetatable({}, AIDecisionEngine)
    self.config = config
    self.lastDecisions = {}
    return self
end

function AIDecisionEngine:getDecisionKey(decisionType, context)
    local key = decisionType
    if context then
        key ..= ":" .. HttpService:JSONEncode(context)
    end
    return key
end

function AIDecisionEngine:shouldTeleport(player, creatorInfo)
    local key = self:getDecisionKey("Teleport", {
        player = player.UserId,
        creator = creatorInfo.userId,
    })

    local autoTeleport = creatorInfo.autoTeleport
    if self.lastDecisions[key] == autoTeleport then
        return autoTeleport
    end

    local weight = 0
    if autoTeleport then
        weight += 1
    end
    if creatorInfo.isLive then
        weight += 1
    end
    if creatorInfo.activity == "Game" then
        weight += 1
    end

    if creatorInfo.gamePlaceId and creatorInfo.gamePlaceId == game.PlaceId then
        weight -= 0.5
    end

    local decision = weight >= 1
    self.lastDecisions[key] = decision
    return decision
end

function AIDecisionEngine:shouldNotifyDiscord(creatorInfo)
    local key = self:getDecisionKey("DiscordNotify", {
        creator = creatorInfo.userId,
    })

    local decision = creatorInfo.isLive and creatorInfo.activity == "Game"
    self.lastDecisions[key] = decision
    return decision
end

return AIDecisionEngine
