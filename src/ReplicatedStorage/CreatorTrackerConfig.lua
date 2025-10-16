local CreatorTrackerConfig = {}

CreatorTrackerConfig.Creators = {
    -- Replace the displayName and userId with the creators your community wants to follow.
    {
        displayName = "SampleCreatorOne",
        userId = 12345678,
        autoTeleport = true,
    },
    {
        displayName = "SampleCreatorTwo",
        userId = 87654321,
        autoTeleport = false,
    },
}

CreatorTrackerConfig.PollInterval = 30

CreatorTrackerConfig.TeleportOnJoin = true

CreatorTrackerConfig.WaitingHubPlaceId = game.PlaceId

CreatorTrackerConfig.Discord = {
    Enabled = false,
    WebhookUrl = "https://discord.com/api/webhooks/your-webhook-id/your-webhook-token",
    MinimumNotificationCooldown = 300,
}

CreatorTrackerConfig.EnableAIDecisionMaking = true

return CreatorTrackerConfig
