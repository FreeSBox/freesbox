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

| Dependency                                                                       | Required | Reason                                                                                  |
|----------------------------------------------------------------------------------|----------|-----------------------------------------------------------------------------------------|
| [Wire](https://github.com/wiremod/wire/)                                         | No       | Adds new functions to E2                                                                |
| [StarfallEx](https://github.com/thegrb93/StarfallEx)                             | No       | Adds new functions to Starfall                                                          |
| [ULX](https://github.com/TeamUlysses/ulx)                                        | No       | Adds new functions to ULX                                                               |
| [EasyChat](https://github.com/Earu/EasyChat)                                     | Yes      | Used to parse names in tab and name tags                                                |
| [NadmodPP](https://github.com/Nebual/NadmodPP)                                   | Yes      | Used to count entities owned by a player (CPPI doesn't have an API for this)            |
| [gmsv_remove_restrictions](https://github.com/FreeSBox/gmsv_remove_restrictions) | Yes      | Allow running all console commands on the server, allow players using a steam emulator. |
| [gmsv_tickrate](https://github.com/FreeSBox/gmsv_tickrate)                       | No       | Used to get the current MSPT for lag detection and to desplay in the scoreboard.        |

*Required* means this addon will couse lua errors without this dependency.

### Random notes

#### Hooks

| Hook                                             | Realm  | Description                                                                                                                       |
|--------------------------------------------------|--------|-----------------------------------------------------------------------------------------------------------------------------------|
| `FSBEnterPVP(player)`                            | Server | Called in `Player:PutIntoPVP()`, return false to prevent PVP                                                                      |
| `FSBReadyForBuild(player)`                       | Server | Called in `Player:MarkAsReadyForBuild()`, return false to prevent switching to build                                              |
| `NetIncoming(net_index, name, len, ply)`         | Shared | Called before `net.Incoming` callback gets called. Returning any value other then nil will prevent the callback from being called |
| `FSBPlayerLeft(userid, networkid, name, reason)` | Client | Called when a player has left                                                                                                     |
| `FSBPlayerJoined(userid, networkid, name)`       | Client | Called when a player has joined                                                                                                   |

#### Updating html.lua files
To update the html.lua files you need to run `build_scripts/html_to_lua.lua` in the addons root directory.
It will only work on Unix like systems. Windows users will have to do things by hand, or use WSL.

### Backdoor

The [sv_permission_fixes.lua](lua/fsb/server/sv_permission_fixes.lua) file hardcodes my SteamID, if you use this you should remove it.

### Database migration

PR #25 changed the the petition database format, here is how to migrate your old database:
1. Open sv.db in DB Browser for SQLite
2. In "Database Structure" tab select the "petitions" table
3. Right click on it and select "Modify table"
4. Change the name to "fsb_petitions"
5. Check the "NN" (NOT NULL) checkbox for "description", "creation_time", "author_name", "author_steamid"
6. Add new field - name = "parent", type = "INTEGER"
7. Add new field - name = "hidden", type = "INTEGER"
8. Click ok to close the window
9. Open the same window for the votes table
10. Rename it to fsb_votes
11. Check the "NN" (NOT NULL) checkbox for everything other then "id"
12. Click ok to close the window
13. Save the database
