A complete solution to create custom doors.

Requires [DataManager](https://github.com/tes3mp-scripts/DataManager)!

Simply use `/dfw` (configurable) to receive instructions on how to use this script.

You can find the configuration file in `server/data/custom/__config_DoorFramework.json`.
* `cmdStaffRank` rank necessary to use the command. `1` by default (moderator).
* `collision` whether doors should have collision. `true` by default.
* `cmd` command name to be used. `"dfw"` by default.
* `sound` sound to be used if none was specified for `/dfw sound`. `"fx/doorw1.wav"` by default.

You can also use this as an API to make doors in your own scripts.  
* `DoorFramework.createRecord(`  
  `recordId,` id used in other functions  
  `name,` text displayed on the door  
  `model,` path to the mesh for the door's appearance  
  `cellDescription,` cell to which the door leads  
  `location,` location to which the door leads. Must have `posX`, `posY`, `posZ`, `rotX`, `rotZ`  
  `sound` sound to be played when the door is activated  
  `)`
* `DoorFramework.getRecord(recordId)`  
  returns `{`  
        `refId,` `refId` generated for the door record in miscellaneous record store  
        `location,` location given in `createRecord`  
        `cellDescription,` cell given in `createRecord`  
        `sound` sound given in `createRecord`  
    `}`
* `DoorFramework.removeRecord(recordId)`  
  removes the record. Doesn't despawn all the door instances or remove the generated custom record!
* `DoorFramework.spawnDoor(`  
  `recordId,`  
  `cellDescription,` cell in which to spawn the door (should be loaded)  
  `location` location at which to spawn the door  
  `)`
* `DoorFramework.isDoor(refId)`  
  returns whether a given `refId` is used by the DoorFramework
* `DoorFramework.getDoor(refId)`  
  returns the `recordId` of the door with `refId`
* `DoorFramework.useDoor(pid, recordId)`  
  makes the player with `pid` use the door with `recordId`. Normally is automatically called when a player activates the door.