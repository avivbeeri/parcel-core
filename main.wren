import "dome" for Platform
var VISION = true
var MODE = 0
import "graphics" for Canvas, Color
import "math" for Vec
import "fov" for Vision, Vision2
import "input" for Keyboard, Mouse, InputGroup
import "parcel" for
  DIR_EIGHT,
  MAX_TURN_SIZE,
  ParcelMain,
  TextUtils,
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
var Target = Vec.new(16, 11)

class SimpleMoveAction is Action {
  construct new(dir) {
    super()
    _dir = dir
  }
  evaluate() {
    if (ctx.zone.map.isSolid(src.pos + _dir)) {
      return ActionResult.invalid
    }
    return ActionResult.valid
  }

  perform() {
    src.pos = src.pos + _dir
    return ActionResult.success
  }
  cost() { MAX_TURN_SIZE }
}
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
    if (hasActions()) {
      return super.getAction()
    }
    return null
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

    _inputs = [
      InputGroup.new([ Keyboard["up"], Keyboard["k"], Keyboard["keypad 8"], Keyboard["8"]]),
      InputGroup.new([ Keyboard["right"], Keyboard["l"], Keyboard["keypad 6"], Keyboard["6"] ]),
      InputGroup.new([ Keyboard["down"], Keyboard["j"], Keyboard["keypad 2"], Keyboard["2"] ]),
      InputGroup.new([ Keyboard["left"], Keyboard["h"], Keyboard["keypad 4"] , Keyboard["4"]]),
      InputGroup.new([ Keyboard["y"], Keyboard["keypad 7"], Keyboard["7"] ]),
      InputGroup.new([ Keyboard["u"], Keyboard["keypad 9"], Keyboard["9"] ]),
      InputGroup.new([ Keyboard["n"], Keyboard["keypad 3"], Keyboard["3"] ]),
      InputGroup.new([ Keyboard["b"], Keyboard["keypad 1"], Keyboard["1"] ])
    ]
    var map = _map = TileMap8.new()
    addElement(Button.new(Vec.new(20,20), Vec.new(70, 32), "Click goes the weasel", null))
    addElement(Box.new(Vec.new(10, 15), Vec.new(16,16), Color.blue))

    for (y in 0...32) {
      for (x in 0...32) {
        map[x,y] = Tile.new({
          "solid": false
        })
      }
    }
    map[12, 16]["solid"] = true
    map[13, 17]["solid"] = true
    for (point in Line.walk(Vec.new(4,19), Vec.new(17,19))) {
        map[point]["solid"] = true
    }
    for (point in Line.walk(Vec.new(4,21), Vec.new(17,21))) {
        map[point]["solid"] = true
    }

    var world = _world = World.new()
    world.addZone(Zone.new(map))
    world.addZone(Zone.new(map))
    var turn = world.addEntity("turn", Turn.new())
    world.addEntity(Entity.new())
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
    var player = _world.getEntityByTag("player")
    var changed = false
    var i = 0
    for (input in _inputs) {
      if (input.firing) {
        changed = true
        player.pushAction(SimpleMoveAction.new(DIR_EIGHT[i]))
      }
      i = i + 1
    }

    if (Keyboard["space"].justPressed) {
      MODE = (MODE + 1) % 4
      search()
    }
    _world.advance()

    if (changed) {
      for (y in _map.yRange) {
        for (x in _map.xRange) {
          _map[x, y]["seen"] = false
          _map[x, y]["cost"] = null
          if (_map[x, y]["visible"]) {
            _map[x, y]["visible"] = "maybe"
          } else {
            _map[x, y]["visible"] = false
          }
        }
      }
      _origin = player.pos
      search()

      /*
      */
      Vision2.new(_map, _origin).compute()
    }
  }

  search() {
    if (!_origin) {
      return
    }
    for (y in _map.yRange) {
      for (x in _map.xRange) {
        _map[x, y]["seen"] = false
          _map[x, y]["cost"] = null
      }
    }
    if (MODE == 0) {
    } else if (MODE == 1) {
      Dijkstra.search(_map, _origin, Target)
    } else if (MODE == 2) {
      AStar.search(_map, _origin, Target)
    } else if (MODE == 3) {
      var search = AStar.fastSearch(_map, _origin, Target)
      AStar.buildFastPath(_map, _origin, Target, search)
    }
  }
  draw() {
    Canvas.cls()
    var map = _world.zone.map

    for (y in map.yRange) {
      for (x in map.xRange) {
        if (!VISION && (!map[x, y]["visible"] || map[x, y]["visible"] == "maybe")) {
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
          Canvas.print("#", x * 16 + 4, y * 16 + 4, Color.lightgray)
        } else if (map[x, y]["cost"]) {
          Canvas.rectfill(x * 16, y*16, 16, 16, Color.darkgray)
          Canvas.print(map[x, y]["cost"], x * 16 + 4, y * 16 + 4, color)

        } else {
          Canvas.print(".", x * 16 + 4, y * 16 + 4, color)
        }
      }
    }
    super.draw()
    if (_origin) {
      Canvas.print("@", _origin.x * 16 + 4, _origin.y * 16 + 4, Color.white)
    }
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
  construct new(pos, size, text, color) {
    super(pos, size, color)
    _text = text
  }

  text { _text }

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

  draw() {
    var offset = (size.y / 2) - 4
    var location = pos + Vec.new(0, offset)
    location = pos
    TextUtils.print(text, {
      "position": location,
      "size": size,
      "color": color,
      //"align": "center"
      "align":"left"
    })
    super.draw()
  }
}

var Game = ParcelMain.new(TestScene)

