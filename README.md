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


### Random notes

#### Updating html.lua files
To update the html.lua files you need to run `build_scripts/html_to_lua.lua` in the addons root directory.
It will only work on Unix like systems. Windows users will have to do things by hand, or use WSL.

