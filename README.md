# TtB Discord Bot

A fun Discord bot that responds to various triggers with humorous quotes and random phrases.

## Setup

1. Clone this repository.
2. Install [Luvit](https://luvit.io/) if not already installed.
3. Create a `config.lua` file in the root directory with your bot token:

```lua
return {
    token = 'YOUR_BOT_TOKEN_HERE',
    admins = {
        "ADMIN_USER_ID_1",
        "ADMIN_USER_ID_2"
    }
}
```

Replace `YOUR_BOT_TOKEN_HERE` with your actual Discord bot token (without the 'Bot ' prefix).

4. Run the bot with `luvit robot.lua` or use `start.bat`.

## Features

- `!ooc`: Sends a random out-of-character quote.
- Reply "delete this" to an ooc message: Bans that specific response for the server (admins only? No, public for curation).
- Messages with `^` characters: Responds with "That's the beauty of [random phrase]".
- Messages ending with `...`: Randomly says "*sucks*" or "*doesn't suck*".
- `!reload <module>`: Reloads a module (ooc, adjective, noun, logic) or all modules at once (use 'all' as the module name) to apply changes without restarting the bot. (Admin only - configured in config.lua)

## Project Structure

- `robot.lua` - Main entry point
- `util/commands.lua` - Command dispatcher
- `commands/` - Individual command modules
  - `ooc.lua` - OOC quote handler
  - `ttb.lua` - TtB trigger handler
  - `suck.lua` - Suck response handler
- `util/reload.lua` - Module reloading utilities
- `responses/` - Response data and modules
  - `ooc.lua` - OOC quote data
  - `wordbank/` - Word data modules
- `config.lua` - Configuration (token, admins)