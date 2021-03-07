import "math" for Vec, M

import "./core/main" for ParcelMain
import "./core/world" for World, Zone
import "./core/map" for TileMap, Tile
import "./core/director" for
  RealTimeStrategy,
  TurnBasedStrategy,
  EnergyStrategy


import "./player" for PlayerData
import "./entities" for Player, Dummy
import "./scene" for WorldScene

// World generation code
var world = World.new(EnergyStrategy.new())

var zone = world.pushZone(Zone.new(TileMap.init()))
zone.map[0, 0] = Tile.new({ "floor": "grass" })
zone.map[0, 1] = Tile.new({ "floor": "solid", "solid": true })
zone.map[10, 0] = Tile.new({ "floor": "solid", "solid": true })

var player = zone.addEntity("player", Player.new())
player["data"] = PlayerData.new()

var dummy = zone.addEntity(Dummy.new())
dummy.pos = Vec.new(-1, 0)

dummy = zone.addEntity(Dummy.new())
dummy.pos = Vec.new(-1, 4)

var Game = ParcelMain.new(WorldScene, [ world ])
