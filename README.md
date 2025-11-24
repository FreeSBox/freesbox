# Free SBox

A mono addon for the FreeSBox GMod server.

Included in this addon are:
- Petition system.
- F2 menu for settings and most of the commands inside it.
- Weapon dropping (`+drop`).
- A file to require a custom binary module.
- Spawn protection.
- Basic localization system.
- Server rules and commandments.
- Lag/crash detector/preventer.
- Custom ULX commands.
- Custom player names and tags.
- Detect known exploit netmessages and run GCC exploit on them.

## Dependencies

| Dependency | Requered | Reason |
|------------------------------------------|----------|--------------------------|
| [Wire](https://github.com/wiremod/wire/) | No       | Adds new functions to E2 |
| [StarfallEx](https://github.com/thegrb93/StarfallEx) | No       | Adds new functions to Starfall |
| [ULX](https://github.com/TeamUlysses/ulx) | No       | Adds new functions to ULX |
| [EasyChat](https://github.com/Earu/EasyChat) | Yes       | Used to parse names in tab and nametags |
| [NadmodPP](https://github.com/Nebual/NadmodPP) | Yes       | Used to count entities owned by a player (CPPI doesn't have an API for this) |
| [gmsv_remove_restrictions](https://github.com/FreeSBox/gmsv_remove_restrictions) | Yes       | Allow running all console commands on the server, allow players using a steam emulator. |

*Requered* means this addon will couse lua errors without this dependency.

### Random notes

#### Updating html.lua files
To update the html.lua files you need to run `build_scripts/html_to_lua.lua` in the addons root directory.
It will only work on Unix like systems. Windows users will have to do things by hand, or use WSL.

