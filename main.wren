import "graphics" for Canvas, Color
import "math" for Vec
import "fov" for Vision
import "input" for Keyboard, Mouse
import "parcel" for
  MAX_TURN_SIZE,
  ParcelMain,
  Scene,
  Element,
  World,
  Entity,
  FastAction,
  FakeAction,
  Log,
  TileMap8,
  TileMap4,
  Tile,
  Zone,
  Action,
  ActionResult,
  BreadthFirst,
  Dijkstra,
  Line,
  AStar

var Search = BreadthFirst

class DeclareTurnAction is Action {
  construct new(turn) {
    super()
    _turn = turn
  }
  perform() {
    Log.i("=====  TURN %(_turn) =====")
    return ActionResult.success
  }
  cost() { MAX_TURN_SIZE }
}
class Player is Entity {
  construct new() {
    super()
  }
  name { "Player" }
  getAction() {
    return FastAction.new()
  }
}

class Turn is Entity {
  construct new() {
    super()
    pos = null
    _turn = 1
  }
  name { "Turn Marker" }
  getAction() {
    return DeclareTurnAction.new(_turn)
  }
  endTurn() {
    _turn = _turn + 1
  }
}

class TestScene is Scene {
  construct new(args) {
    super(args)
    var map = _map = TileMap8.new()
    addElement(Button.new(Vec.new(0,0), Vec.new(5,5), null))
    addElement(Box.new(Vec.new(10, 10), Vec.new(16,16), null))
    for (y in 0...32) {
      for (x in 0...32) {
        map[x,y] = Tile.new({
          "solid": false
        })
      }
    }
    _origin = Vec.new(16, 18)
    map[12, 16]["solid"] = true
    map[13, 17]["solid"] = true
    for (point in Line.walk(Vec.new(4,19), Vec.new(17,19))) {
        map[point]["solid"] = true
    }
    for (point in Line.walk(Vec.new(4,21), Vec.new(17,21))) {
        map[point]["solid"] = true
    }
    Vision.new(map, _origin).compute()

    // System.print(AStar.search(map, Vec.new(0,0), Vec.new(5,6)))
    var world = _world = World.new()
    world.addZone(Zone.new(map))
    world.addZone(Zone.new(map))
    var turn = world.addEntity("turn", Turn.new())
    world.addEntity(Entity.new())
    //player.pushAction(FakeAction.new())
    world.start()
    for (i in 0...5) {
      world.advance()
    }
    var player = world.addEntity("player", Player.new())
    Log.i("Adding Player")
    for (i in 0...12) {
      world.advance()
    }
  }

  update() {
    super.update()
    var changed = false
    if (Keyboard["left"].justPressed) {
      _origin.x = _origin.x - 1
      changed = true

    }
    if (Keyboard["up"].justPressed) {
      _origin.y = _origin.y - 1
      changed = true

    }
    if (Keyboard["right"].justPressed) {
      _origin.x = _origin.x + 1
      changed = true

    }
    if (Keyboard["down"].justPressed) {
      _origin.y = _origin.y + 1
      changed = true
    }
    if (changed) {
      for (y in _map.yRange) {
        for (x in _map.xRange) {
          if (_map[x, y]["visible"]) {
            _map[x, y]["visible"] = "maybe"
          } else {
            _map[x, y]["visible"] = false
          }
        }
      }
      Vision.new(_map, _origin).compute()
    }
  }

  draw() {
    Canvas.cls()
    var map = _world.zone.map

    for (y in map.yRange) {
      for (x in map.xRange) {
        if (!map[x, y]["visible"] || map[x, y]["visible"] == "maybe") {
          continue
        }
        var color = Color.white
        if (map[x, y]["visible"] == "maybe") {
          color = Color.darkgray
        }
        if (map[x, y]["seen"]) {
          color = Color.red
        }
        if (map[x, y]["void"]) {
        } else if (map[x, y]["solid"]) {
          Canvas.print("#", x * 16 + 8, y * 16 + 8, Color.lightgray)
        } else if (map[x, y]["cost"]) {
          Canvas.print(map[x, y]["cost"], x * 16, y * 16, color)
        } else {
          Canvas.print(".", x * 16 + 8, y * 16 + 8, color)
        }
      }
    }
    super.draw()
    Canvas.print("@", _origin.x * 16 + 8, _origin.y * 16 + 8, Color.white)
  }
}

class Box is Element {
  construct new(pos, size, color) {
    super()
    _pos = pos
    _size = size
    _color = color || Color.red
  }
  pos { _pos }
  size { _size }
  color { _color }
  draw() {
    Canvas.rect(pos.x, pos.y, size.x, size.y, color)
  }
}
class Button is Box {
  construct new(pos, size, color) {
    super(pos, size, color)
  }

  update() {
    if (Mouse["left"].justPressed) {
      System.print("click")
      System.print(Mouse.pos)
      if (Mouse.x >= pos.x &&
          Mouse.y >= pos.y &&
          Mouse.x < pos.x + size.x &&
          Mouse.y < pos.y + size.y) {
        System.print("close")
        removeSelf()
        return
      }
    }
    super.update()
  }
}

var Game = ParcelMain.new(TestScene)

