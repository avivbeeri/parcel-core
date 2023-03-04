import "dome" for Platform
var MODE = 2
import "combat"
import "meta" for Meta
import "graphics" for Canvas, Color
import "math" for Vec
import "fov" for Vision, Vision2
import "input" for Keyboard, Mouse, InputGroup
import "parcel" for
  TextInputReader,
  DIR_EIGHT,
  MAX_TURN_SIZE,
  ParcelMain,
  GameSystem,
  TextUtils,
  TurnEvent,
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
  Palette,
  JPS,
  AStar

var Search = BreadthFirst
var Target = Vec.new(16, 11)
var Pal = Palette.new()
Pal.addColor("white", Color.new(255, 255, 255))
Pal.addColor("gray", Color.darkgray)
Pal.addColor("black", Color.new(0, 0, 0))
Pal.addColor("red", Color.new(255, 0, 0))
Pal.addColor("green", Color.new(0, 255, 0))
Pal.addColor("blue", Color.new(0, 255, 255))

Pal.setPurpose("floor", "gray")
Pal.setPurpose("wall", "white")

class SimpleMoveAction is Action {
  construct new(dir) {
    super()
    _dir = dir
  }
  evaluate() {
    if (ctx.zone.map.neighbours(src.pos).contains(src.pos + _dir)) {
      return ActionResult.valid
    }
    return ActionResult.invalid
  }

  perform() {
    src.pos = src.pos + _dir
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

class TestScene is Scene {
  construct new(args) {
    super(args)
    _t = 0
    _kb = TextInputReader.new()

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
    _world.systems.add(VisionSystem.new())
    world.addZone(Zone.new(map))
    world.addZone(Zone.new(map))
    world.addEntity("player", Player.new())
    world.addEntity(Entity.new())
    _name = ""

    world.start()
  }

  update() {
    super.update()
    if (_kb.enabled) {
      _t = _t + 1
      _kb.update()
      _text = _kb.text || ""
      if (Keyboard["return"].justPressed) {
        _kb.disable()
        _name = _kb.text
        var error = Fiber.new {
          var world = _world
          Meta.eval(_kb.text)
        }.try()
        if (error) {
          Log.e(error)
        }
      }
      if (Keyboard["escape"].justPressed) {
        _kb.disable()
      }
      return
    }
    var player = _world.getEntityByTag("player")
    var i = 0
    for (input in _inputs) {
      if (input.firing) {
        player.pushAction(SimpleMoveAction.new(DIR_EIGHT[i]))
      }
      i = i + 1
    }

    if (Keyboard["space"].justPressed) {
      MODE = (MODE + 1) % 4
    }
    if (Keyboard["return"].justPressed) {
      _kb.clear()
      _kb.enable()
    }

    _world.advance()
    for (event in _world.events) {
      if (event is TurnEvent) {
        var t = event["turn"]
        Log.i("Next turn %(t)")
      }
    }
  }

  draw() {
    Canvas.cls()
    var player = _world.getEntityByTag("player")
    var map = _world.zone.map

    for (y in map.yRange) {
      for (x in map.xRange) {
        if (!map[x, y]["visible"]) {
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
          Canvas.print("#", x * 16 + 4, y * 16 + 4, color)
        } else if (map[x, y]["cost"]) {
          Canvas.rectfill(x * 16, y*16, 16, 16, Color.darkgray)
          Canvas.print(map[x, y]["cost"], x * 16 + 4, y * 16 + 4, color)

        } else {
          Canvas.print(".", x * 16 + 4, y * 16 + 4, color)
        }
      }
    }
    super.draw()
    if (player) {
      Canvas.print("@", player.pos.x * 16 + 4, player.pos.y * 16 + 4, Color.white)
    }

    Canvas.print(_name, 0, Canvas.height - 17, Color.white)
    if (_kb.enabled) {
      var x = _kb.pos * 8
      var y = Canvas.height - 10
      if ((_t / 30).floor % 2 == 0) {
        Canvas.rectfill(x, y, 8, 10, Color.white)
      }
      Canvas.print(_kb.text, 0, Canvas.height - 9, Color.white)
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
      "align":"left"
    })
    super.draw()
  }
}


class VisionSystem is GameSystem {
  construct new() { super() }
  postUpdate(ctx, actor) {
    var player = ctx.getEntityByTag("player")
    if (!player) {
      return
    }
    var map = ctx.zone.map
    for (y in map.yRange) {
      for (x in map.xRange) {
        map[x, y]["seen"] = false
        map[x, y]["cost"] = null
        if (map[x, y]["visible"]) {
          map[x, y]["visible"] = "maybe"
        } else {
          map[x, y]["visible"] = false
        }
      }
    }
    Vision2.new(map, player.pos).compute()
    search(map, player.pos)
  }

  search(map, origin) {
    if (!origin) {
      return
    }
    for (y in map.yRange) {
      for (x in map.xRange) {
        map[x, y]["seen"] = false
        map[x, y]["cost"] = null
      }
    }
    if (MODE == 0) {
    } else if (MODE == 1) {
      Dijkstra.search(map, origin, Target)
    } else if (MODE == 2) {
      AStar.search(map, origin, Target)
    } else if (MODE == 3) {
      var search = JPS.fastSearch(map, origin, Target)
      JPS.buildFastPath(map, origin, Target, search)
    }
  }
}

var Game = ParcelMain.new(TestScene)

