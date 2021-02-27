import "graphics" for ImageData, Color, Canvas
import "input" for Keyboard
import "math" for Vec, M

import "./display" for Display
import "./tilesheet" for Tilesheet
import "./keys" for InputGroup, Actions

import "./core/director" for RealTimeStrategy, TurnBasedStrategy, EnergyStrategy
import "./core/world" for World, Zone
import "./core/scene" for Scene
import "./core/map" for TileMap, Tile

import "./menu" for Menu
import "./events" for CollisionEvent, MoveEvent
import "./player" for PlayerData
import "./actions" for MoveAction, SleepAction
import "./entities" for Player, Dummy

import "./sprites" for StandardSpriteSet, InvertedSpriteSet
import "./effects" for CameraLerp

// Timer variables
var T = 0
var F = 0

// Is the view static?
var STATIC = false


class WorldScene is Scene {
  construct new(args) {
    _camera = Vec.new()
    _moving = false
    _tried = false
    _ui = []
    _world = World.new(EnergyStrategy.new())


    var zone = Zone.new()
    var player = zone.addEntity("player", Player.new())
    player["#speed"] = 2
    _playerData = PlayerData.new()
    player["data"] = _playerData
    var dummy = zone.addEntity(Dummy.new())
    dummy.pos = Vec.new(-1, 0)

    zone.map = TileMap.init()
    zone.map[0, 0] = Tile.new({ "floor": "grass" })
    zone.map[0, 1] = Tile.new({ "floor": "solid", "solid": true })

    _zones = []
    _zoneIndex = 0

    _world.pushZone(zone)
    _camera.x = player.pos.x * 8
    _camera.y = player.pos.y * 8
  }

  update() {
    _zone = _world.active
    var player = _zone.getEntityByTag("player")

    T = T + (1/60)
    F = (T * 2).floor % 2

    if (_ui.count > 0) {
      _ui[0].update()
      if (_ui[0].finished) {
        _ui.removeAt(0)
      }
      return
    }
    _moving = false
    var pressed = false


    // Overzone interaction
    if (Actions.interact.justPressed) {
      _ui.add(Menu.new(_zone, [
        "Cook", "relax",
        "Sleep", SleepAction.new(),
        "Cancel", "cancel"
      ]))
      return
    }


    if (!player.action && !_tried) {
      var move = Vec.new()
      if (Actions.left.firing) {
        move.x = -1
      } else if (Actions.right.firing) {
        move.x = 1
      } else if (Actions.up.firing) {
        move.y = -1
      } else if (Actions.down.firing) {
        move.y = 1
      }
      if (move.length > 0) {
        player.action = MoveAction.new(move)
      }
    }
    pressed = Actions.directions.any {|key| key.down }

    _world.update()
    for (event in _zone.events) {
      if (event is MoveEvent) {
        if (event.target is Player) {
          _moving = true
          _ui.add(CameraLerp.new(this, event.target.pos * 8))
        }
      } else if (event is CollisionEvent) {
        _tried = true
        _moving = false
      }
    }
    if (!pressed) {
      _tried = false
    }
  }

  draw() {
    _zone = _world.active
    var player = _zone.getEntityByTag("player")
    var X_OFFSET = 4
    var sprites = StandardSpriteSet
    Canvas.cls()

    var cx = (Canvas.width - X_OFFSET - 20) / 2
    var cy = Canvas.height / 2 - 4
    if (!STATIC) {
      Canvas.offset((cx-_camera.x -X_OFFSET).floor, (cy-_camera.y).floor)
    }
    var x = Canvas.width - 20

    for (dy in -5...5) {
      for (dx in -7...7) {
        var x = player.pos.x + dx
        var y = player.pos.y + dy
        var sx = x * 8 + X_OFFSET
        var sy = y * 8
        var tile = _zone.map[x, y]
        if (tile["floor"] == "blank") {
          // Intentionally do nothing
        } else if (tile["floor"] == "grass") {
          var list = sprites[tile["floor"]]
          list[0].draw(sx, sy)
        } else if (tile["floor"] == "solid") {
          Canvas.rectfill(sx, sy, 8, 8, Display.fg)
        } else if (tile["floor"] == "door") {
          var list = sprites[tile["floor"]]
          list[0].draw(sx, sy)
        } else if (_zone["floor"] == "void") {
          var list = sprites["void"]
          list[0].draw(sx, sy)
        }
      }
    }

    for (entity in _zone.entities) {
      var sx = entity.pos.x * 8 + X_OFFSET
      var sy = entity.pos.y * 8
      if (STATIC && entity is Player) {
        // We draw this
        if (_moving) {
          sprites["playerWalk"][F].draw(sx, sy)
        } else {
          sprites["playerStand"][F].draw(sx, sy)
        }
      } else if (entity is Dummy) {
        Canvas.print("D", sx, sy, Display.fg)
      }
    }
    // Put a background on the player for readability
    if (!STATIC) {
      Canvas.offset()
      var tile = _zone.map[player.pos]
      if (tile["floor"] || _zone["floor"]) {
        Canvas.rectfill(cx, cy, 8, 8, _invert ? Display.fg : Display.bg)
      }
      // Draw player in screen center
      if (_moving) {
        sprites["playerWalk"][F].draw(cx, cy)
      } else {
        sprites["playerStand"][F].draw(cx, cy)
      }
    }


    for (ui in _ui) {
      var block = ui.draw()
      if (block) {
        break
      }
    }

    // Draw UI overlay
    Canvas.rectfill(x, 0, 20, Canvas.height, Display.fg)
    Canvas.line(x+1, 0, x+1, Canvas.height, Display.bg)
  }

  world { _world }
  camera { _camera }
  camera=(v) { _camera = v }
}
