import "math" for Vec, M
import "core/elegant" for Elegant

import "core/world" for World, Zone
import "core/map" for TileMap, Tile
import "core/director" for
  ActionStrategy,
  TurnBasedStrategy,
  EnergyStrategy

import "logic" for RemoveDefeated, GameEndCheck

import "./core/config" for Config
import "./rng" for RNG

var SPAWN_DIST = [ 0, 0, 1, 1, 1, 1, 1, 1, 2, 2]
var SPAWNABLES = Config["entities"].where {|config| config["types"].contains("spawnable") }.toList
System.print(SPAWNABLES)
var ROOM_COUNT = 4

class Room is Vec {
  construct new(x, y, w, h) {
    super(x, y, w, h)
    _neighbours = []
    _doors = []
  }

  kind { _kind }
  kind=(v) { _kind = v }

  neighbours { _neighbours }
  doors { _doors }
  toString { "Room [%(super.toString)]"}

  width { z }
  height { w }
}

class WorldGenerator {
  static generate() {
    // return TestGenerator.generate()
    return GrowthGenerator.init().generate()
  }

}

class GrowthGenerator {
  static generate() {
    return GrowthGenerator.init().generate()
  }

  construct init() {}
  generate() {

    // 1. Generate map
    // 2. Populate with enemies
    // 3. Select starting deck (based on steps 1 and 2)

    var world = World.new(EnergyStrategy.new())
    var zone = world.pushZone(Zone.new(TileMap.init()))
    zone.map.default = { "solid": true, "floor": "void", "index": -1, "dirty": false }

    // Order is important!!
    // Put postUpdate here
    zone.postUpdate.add(RemoveDefeated)
    zone.postUpdate.add(GameEndCheck)
    // -------------------


    // Level dimensions in tiles
    // 1-2) General constraints
    var maxRoomSize = 12
    var minRoomSize = 5

    var doors = []

    // 3) A single room in the world (Library)
    var rooms = [ Room.new(0, 0, 7, 7) ]
    var door = null

    while(rooms.count < ROOM_COUNT) {

      // 4) Pass begins: Pick a base for this pass at random from existing rooms.
      var base = RNG.sample(rooms)
      // 5) Select a wall to grow from
      var dir = RNG.int(0, 4) // 0->4, left->up->right->down
      // 6)Make a new room
      var newRoom = Room.new(
        0, 0,
        RNG.int(minRoomSize, maxRoomSize),
        RNG.int(minRoomSize, maxRoomSize)
      )
      // 7) Place the room on the wall of the base
      if (dir == 0) {
        // left
        var offset = RNG.int(3 - newRoom.w, base.w - 3)
        newRoom.x = base.x - newRoom.z + 1
        newRoom.y = base.y + offset
        // 8-9) Check room for valid space compared to other rooms.
        if (!isSafeToPlace(rooms, base, newRoom)) {
          continue
        }


        // 10) Place a door in the overlapping range
        var doorTop = M.max(newRoom.y, base.y)
        var doorBottom = M.min(newRoom.y + newRoom.w, base.y + base.w)
        var doorRange = RNG.int(doorTop + 1, doorBottom - 1)
        door = Vec.new(base.x, doorRange)
      } else if (dir == 1) {
        // up
        var offset = RNG.int(3 - newRoom.z, base.z - 3)
        newRoom.x = base.x + offset
        newRoom.y = base.y - newRoom.w + 1
        // 8-9) Check room for valid space compared to other rooms.
        if (!isSafeToPlace(rooms, base, newRoom)) {
          continue
        }

        // 10) Place a door in the overlapping range
        var doorLeft = M.max(newRoom.x, base.x)
        var doorRight = M.min(newRoom.x + newRoom.z, base.x + base.z)
        var doorRange = RNG.int(doorLeft + 1, doorRight - 1)
        door = Vec.new(doorRange, base.y)
      } else if (dir == 2) {
        // right
        var offset = RNG.int(3 - newRoom.w, base.w - 3)
        newRoom.x = base.x + base.z - 1
        newRoom.y = base.y + offset
        // 8-9) Check room for valid space compared to other rooms.
        if (!isSafeToPlace(rooms, base, newRoom)) {
          continue
        }

        // 10) Place a door in the overlapping range
        var doorTop = M.max(newRoom.y, base.y)
        var doorBottom = M.min(newRoom.y + newRoom.w, base.y + base.w)
        var doorRange = RNG.int(doorTop + 1, doorBottom - 1)
        door = Vec.new(newRoom.x, doorRange)
      } else if (dir == 3){
        // up
        var offset = RNG.int(3 - newRoom.z, base.z - 3)
        newRoom.x = base.x + offset
        newRoom.y = base.y + base.w - 1
        // 8-9) Check room for valid space compared to other rooms.
        if (!isSafeToPlace(rooms, base, newRoom)) {
          continue
        }

        // 10) Place a door in the overlapping range
        var doorLeft = M.max(newRoom.x, base.x)
        var doorRight = M.min(newRoom.x + newRoom.z, base.x + base.z)
        var doorRange = RNG.int(doorLeft + 1, doorRight - 1)
        door = Vec.new(doorRange, newRoom.y)
      } else {
        // Safety assert
        Fiber.abort("Tried to grow from bad direction")
      }
      rooms.add(newRoom)
      base.neighbours.add(newRoom)

      doors.add(door)
      newRoom.doors.add(door)
      base.doors.add(door)
    }

    var start = rooms[0]
    var player = zone.addEntity("player", Player.new())
    player.pos = Vec.new(start.x + 1, start.y + 1)

    var enemyCount = 0
    for (room in rooms) {
      var wx = room.x
      var wy = room.y
      var width = wx + room.z
      var height = wy + room.w
      for (y in wy...height) {
        for (x in wx...width) {
          if (x == wx || x == width - 1 || y == wy || y == height - 1) {
            zone.map[x, y] = Tile.new({ "floor": "wall", "solid": true, "room": room })
          } else {
            zone.map[x, y] = Tile.new({ "floor": "tile", "room": room })
          }
        }
      }

      var spawnTotal = RNG.sample(SPAWN_DIST)

      for (i in 0..spawnTotal) {
        var entity = EntityFactory.prepare(SPAWNABLES[RNG.int(SPAWNABLES.count)])
        spawnIn(zone, room, entity)
        enemyCount = enemyCount + 1
      }
    }
    if (enemyCount == 0) {
      var room = rooms[-1]
      var entity = EntityFactory.prepare(SPAWNABLES[RNG.int(SPAWNABLES.count)])
      spawnIn(zone, room, entity)
    }
    for (door in doors) {
      zone.map[door.x, door.y] = Tile.new({ "floor": "tile" })
    }

    return world
  }

  overlap(r1, r2) {
    return r1.x < r2.x + r2.z &&
           r1.x + r1.z > r2.x &&
           r1.y < r2.y + r2.w &&
           r1.y + r1.w > r2.y
  }

  isSafeToPlace(rooms, base, newRoom) {
    for (room in rooms) {
      if (room == base) {
        // Colliding with the base is intentional. ignore this hit.
        continue
      }
      if (overlap(newRoom, room)) {
        return false
      }
    }
    return true
  }

  spawnIn(zone, room, entity) {
    var wx = room.x
    var wy = room.y
    var width = wx + room.z
    var height = wy + room.w
    zone.addEntity(entity)
    var spawn = Vec.new(RNG.int(wx + 1, width - 1), RNG.int(wy + 1, height - 1))
    // TODO: Can land on player?
    while (zone.getEntitiesAtTile(spawn).count >= 1 || (zone.isSolidAt(spawn))) {
      spawn = Vec.new(RNG.int(wx + 1, width - 1), RNG.int(wy + 1, height - 1))
    }
    entity.pos = spawn
    entity.priority = RNG.int(13)
  }
}


class TestGenerator {
  static generate() {
    // World generation code

    var world = World.new(EnergyStrategy.new())
    var zone = world.pushZone(Zone.new(TileMap.init()))
    // Order is important!!
    // -------------------

    zone.map.default = { "solid": false, "floor": "void" }
    var width = 7
    var height = 7
    for (y in 0..height) {
      for (x in 0..width) {
        if (x == 0 || x == width || y == 0 || y == width) {
          zone.map[x, y] = Tile.new({ "floor": "wall", "solid": true })
        } else {
          zone.map[x, y] = Tile.new({ "floor": "tile" })
        }
      }
    }

    var player = zone.addEntity("player", Player.new())
    player.pos = Vec.new(4, 4)

    return world
  }
}

import "./entity/player" for Player
import "factory" for EntityFactory
