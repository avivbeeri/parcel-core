import "graphics" for ImageData, Canvas, Color
import "input" for Keyboard
import "math" for Vec, M

import "./core/display" for Display
import "./keys" for InputGroup, InputActions

import "./core/scene" for Scene
import "./core/event" for EntityRemovedEvent, EntityAddedEvent

import "./menu" for Menu
import "./events" for CollisionEvent, MoveEvent
import "./actions" for MoveAction, SleepAction
import "./entities" for Player, Dummy

import "./sprites" for StandardSpriteSet
import "./effects" for CameraLerp

// Timer variables
var T = 0
var F = 0

// Is the view static?
var STATIC = false


class WorldScene is Scene {
  construct new(args) {
    // Args are currently unused.

    _camera = Vec.new()
    _moving = false
    _tried = false
    _ui = []

    _world = args[0]
    var player = _world.active.getEntityByTag("player")

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
    if (InputActions.interact.justPressed) {
      _ui.add(Menu.new(_zone, [
        "Cook", null,
        "Sleep", SleepAction.new(),
        "Cancel", "cancel"
      ]))
      return
    }


    if (!player.action && !_tried) {
      var move = Vec.new()
      if (InputActions.left.firing) {
        move.x = -1
      } else if (InputActions.right.firing) {
        move.x = 1
      } else if (InputActions.up.firing) {
        move.y = -1
      } else if (InputActions.down.firing) {
        move.y = 1
      }
      if (move.length > 0) {
        player.action = MoveAction.new(move)
      }
    }
    pressed = InputActions.directions.any {|key| key.down }

    _world.update()
    if (InputActions.inventory.justPressed) {
      var dummy = _zone.addEntity(Dummy.new())
      dummy.pos = Vec.new(0, 0)
    }
    for (event in _zone.events) {
      if (event is EntityAddedEvent) {
        System.print("Entity %(event.id) was added")
      } else if (event is EntityRemovedEvent) {
        System.print("Entity %(event.id) was removed")
      } else if (event is MoveEvent) {
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
    Canvas.cls(Display.bg)

    var cx = (Canvas.width - X_OFFSET - 20) / 2
    var cy = Canvas.height / 2 - 4
    if (!STATIC) {
      Canvas.offset((cx-_camera.x -X_OFFSET).floor, (cy-_camera.y).floor)
    }
    var x = Canvas.width - 20

    var xRange = 14
    var yRange = 10

    for (dy in -yRange...yRange) {
      for (dx in -xRange...xRange) {
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
      if (entity is Player) {
        if (!STATIC) {
          continue
        }
        // We draw this
        if (_moving) {
          sprites["playerWalk"][F].draw(sx, sy)
        } else {
          sprites["playerStand"][F].draw(sx, sy)
        }
      } else {
        Canvas.print(entity.type.name[0], sx, sy, Color.red)
      }
    }
    // Put a background on the player for readability
    if (!STATIC) {
      Canvas.offset()
      var tile = _zone.map[player.pos]
      if (tile["floor"] || _zone["floor"]) {
        Canvas.rectfill(cx, cy, 8, 8, Display.bg)
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
  }

  world { _world }
  camera { _camera }
  camera=(v) { _camera = v }
}
