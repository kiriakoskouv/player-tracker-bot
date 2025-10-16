# Roblox Creator Tracker Game Scripts

This repository contains a full set of Roblox Lua scripts that power a waiting hub where players can follow their favourite creators, automatically join them when they start playing, and stay AFK without being kicked. The system optionally integrates with Discord webhooks for community notifications and uses a light-weight AI decision engine to customise teleport behaviour.

## Features

- **Creator presence polling** powered by the Roblox Presence API with safe fallbacks.
- **AI-assisted decisions** on when to teleport followers or ping Discord using `AIDecisionEngine`.
- **Player-configurable favourites** via a responsive UI panel in `StarterGui`.
- **AFK protection** that keeps players safe from idle kicks and lets them broadcast AFK state with `/afk`.
- **Discord notifications** (optional) when a tracked creator goes live in-game.

## Folder layout

```
src/
  ReplicatedStorage/
    CreatorTrackerConfig.lua
  ServerScriptService/
    AIDecisionEngine.lua
    CreatorTracker.server.lua
    AfkManager.server.lua
  StarterPlayer/
    StarterPlayerScripts/
      AfkGuard.client.lua
  StarterGui/
    CreatorTrackerUI.client.lua
```

## Configuration

1. Update `CreatorTrackerConfig.lua` with the display names and user IDs of the creators you want to follow. Toggle per-creator `autoTeleport` and global options like `TeleportOnJoin` or `EnableAIDecisionMaking` as needed.
2. If you want Discord notifications, set `Discord.Enabled = true` and paste the webhook URL. The script already batches notifications using a cooldown.
3. Publish the `src` hierarchy to your Roblox experience (e.g. using Roblox Studio and the command bar or Rojo).

## Teleport and HTTP prerequisites

- Enable **HTTP requests** in your Roblox experience (Game Settings → Security).
- Make sure the experience allows **Third Party Teleports** if you expect to jump between universes.
- The hub server must remain running; use Reserved Servers or private servers if you need dedicated uptime.

## Gameplay flow

1. Players spawn into the waiting hub and open the Creator Tracker UI (automatically attached on spawn).
2. They pick a creator to follow; the selection is stored as a player attribute for the server scripts to consume.
3. The server polls the Roblox Presence API on a schedule. When a creator starts a live game session, the AI engine evaluates whether to teleport waiting followers immediately.
4. Followers that pass the AI check are teleported into the creator's active server using `TeleportToPlaceInstance`.
5. Players can toggle AFK mode with the on-screen button or `/afk` command. An in-world billboard shows AFK status and the client injects virtual input to avoid idle kicks.

## Discord integration

`CreatorTracker.server.lua` pushes Discord webhooks with details about the creator and destination place when they go live. This keeps your community in sync even if they're not in-game.

## Extending the system

- Add more creator metadata (e.g. custom thumbnails or voice chat requirements) to `CreatorTrackerConfig.lua` and surface it inside the UI.
- Replace the simple AI heuristics with more advanced logic (e.g. prioritise friends or high ping) by editing `AIDecisionEngine.lua`.
- Integrate a datastore to persist player preferences across sessions.

Happy building!
