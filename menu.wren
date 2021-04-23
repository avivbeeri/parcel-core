import "math" for M, Vec
import "graphics" for Canvas
import "input" for Mouse
import "./core/display" for Display
import "./core/scene" for Ui
import "./core/action" for Action
import "./keys" for InputActions
import "./actions" for PlayCardAction
import "./palette" for EDG32, EDG32A

import "./widgets" for Button

var scale = 1
var TILE_SIZE = 16 * scale

class Space {
  construct wrap(vec) {
    _pos = vec
  }
  pos { _pos }
  size { Vec.new(1, 1) }
}

class CombatTargetSelector is Ui {
  construct new(ctx, view) {
    super(ctx)
    _view = view
    _player = ctx.getEntityByTag("player")
    _targets = ctx.entities.where {|entity|
      return entity.has("types") && view.isOnScreen(entity.pos)
    }.toList
    _current = (_targets.count > 1 && _targets[0].id == _player.id) ? 1 : 0
    _closeButton = Button.new("X", Vec.new(460, 22), Vec.new(15, 15))
  }

  finished { _done }

  update() {
    if (_closeButton.update().clicked || InputActions.cancel.justPressed) {
      _done = true
      return
    }
    if (InputActions.nextTarget.justPressed) {
      _current = _current + 1
    }
    _mouseTile = _view.screenToWorld(Mouse.pos)
    for (i in 0..._targets.count) {
      var target = _targets[i]
      if (target.pos == _mouseTile) {
        _current = i
        break
      }
    }
    _current = _current % _targets.count
  }

  drawDiagetic() {
    var loc = Vec.new()

    // Draw targeting recticle
    if (_targets.count > 0) {
      var target = _targets[_current]
      var left = (target.pos.x) * TILE_SIZE - 5
      var top = (target.pos.y) * TILE_SIZE - 5
      var right = (target.pos.x + target.size.x) * TILE_SIZE + 4
      var bottom = (target.pos.y + target.size.y) * TILE_SIZE + 4
      var vThird = ((bottom - top) / 3).round
      var hThird = ((bottom - top) / 3).round
      // top left
      Canvas.line(left, top, left + hThird, top, EDG32[7], 3)
      Canvas.line(left, top, left, top + vThird, EDG32[7], 3)


      // bottom left
      Canvas.line(left, bottom, left + hThird, bottom, EDG32[7], 3)
      Canvas.line(left, bottom, left, bottom - vThird, EDG32[7], 3)

      // top right
      Canvas.line(right, top, right - hThird, top, EDG32[7], 3)
      Canvas.line(right, top, right, top + vThird, EDG32[7], 3)

      // bottom right
      Canvas.line(right, bottom, right - hThird, bottom, EDG32[7], 3)
      Canvas.line(right, bottom, right, bottom - vThird, EDG32[7], 3)
    }
  }

  draw() {
    _closeButton.draw()
    _view.drawEntityStats(_targets[_current])
  }
}

class CardTargetSelector is Ui {
  construct new(ctx, view, card, handIndex) {
    super(ctx)
    _done = false
    _index = handIndex
    _player = ctx.getEntityByTag("player")
    _pos = _player.pos
    _view = view
    _range = card.params["range"]
    if (card.target == "space") {
      _targets = []
      for (y in -_range .. _range) {
        for (x in -_range .. _range) {
          var loc =  (Vec.new(x, y) + _player.pos)
          if (!(x == 0 && y == 0) && (loc - _player.pos).manhattan <= _range) {
            // TODO: should we wrap location for compatibility?
            _targets.add(Space.wrap(loc))
          }
        }
      }
      _current = 0
    } else {
      _targets = ctx.entities.where {|entity|
        return entity.has("types") &&
          entity["types"].contains(card.target) &&
          (entity.pos - _player.pos).manhattan <= _range
      }.toList
      _current = (_targets.count > 1 && _targets[0].id == _player.id) ? 1 : 0
    }
    if (_targets.count > 0) {
      _current = _current % _targets.count
    }
    _mouseTile = null
    _closeButton = Button.new("X", Vec.new(460, 22), Vec.new(15, 15))
  }

  finished { _done }

  update() {
    var mouse = Mouse.pos
    if (_closeButton.update().clicked || InputActions.cancel.justPressed) {
      _done = true
      return
    }
    if (InputActions.nextTarget.justPressed) {
      _current = _current + 1
    }

    var center = _view.center
    var xRange = (center.x / TILE_SIZE).ceil + 1
    var yRange = (center.y / TILE_SIZE).ceil + 1

    _mouseTile = _view.screenToWorld(mouse)

    var hover = false
    if (ctx.map[_mouseTile]["floor"] != "void" && (_mouseTile.x - _player.pos.x).abs < xRange && (_mouseTile.y - _player.pos.y).abs < yRange) {
      for (i in 0..._targets.count) {
        var target = _targets[i]
        if (target.pos == _mouseTile) {
          _current = i
          hover = true
          break
        }
      }
    } else {
      _mouseTile = null
    }

    var downOptions = InputActions.options.where {|input| input.justPressed }.toList
    if (downOptions.count > 0) {
      if (downOptions[0].action < _targets.count) {
        _current = downOptions[0].action
        _done = true
        _player.action = PlayCardAction.new(_index, _targets[_current])
        return
      }
    }

    if (InputActions.confirm.justPressed || (Mouse["left"].justPressed && hover)) {
      _done = true
      _player.action = PlayCardAction.new(_index, _targets[_current])
      return
    }

    _current = _current % _targets.count
  }

  drawDiagetic() {
    var loc = Vec.new()
    for (y in -_range.._range) {
      for (x in -_range.._range) {
        loc.x = x
        loc.y = y
        if (loc.manhattan <= _range) {
          var tile = loc + _player.pos
          Canvas.rectfill(tile.x * TILE_SIZE, tile.y * TILE_SIZE, TILE_SIZE, TILE_SIZE, EDG32A[29])
        }
      }
    }
    // Draw targeting recticle
    if (_targets.count > 0) {
      var target = _targets[_current]
      var left = (target.pos.x) * TILE_SIZE - 5
      var top = (target.pos.y) * TILE_SIZE - 5
      var right = (target.pos.x + target.size.x) * TILE_SIZE + 4
      var bottom = (target.pos.y + target.size.y) * TILE_SIZE + 4
      var vThird = ((bottom - top) / 3).round
      var hThird = ((bottom - top) / 3).round
      // top left
      Canvas.line(left, top, left + hThird, top, EDG32[7], 3)
      Canvas.line(left, top, left, top + vThird, EDG32[7], 3)


      // bottom left
      Canvas.line(left, bottom, left + hThird, bottom, EDG32[7], 3)
      Canvas.line(left, bottom, left, bottom - vThird, EDG32[7], 3)

      // top right
      Canvas.line(right, top, right - hThird, top, EDG32[7], 3)
      Canvas.line(right, top, right, top + vThird, EDG32[7], 3)

      // bottom right
      Canvas.line(right, bottom, right - hThird, bottom, EDG32[7], 3)
      Canvas.line(right, bottom, right, bottom - vThird, EDG32[7], 3)

      if (_mouseTile) {
        // Mouse selector
        Canvas.rectfill(_mouseTile.x * TILE_SIZE, _mouseTile.y * TILE_SIZE, TILE_SIZE, TILE_SIZE, EDG32A[17])
      }

      var n = 0
      for (target in _targets) {
        var tile = target.pos
        Canvas.print(n, tile.x * TILE_SIZE, tile.y * TILE_SIZE, EDG32A[19])
        n = n + 1
      }
    }
  }

  draw() {
    _closeButton.draw()
  }

}

class Menu is Ui {
  construct new(ctx, actions) {
    super(ctx)
    if (actions.count % 2 != 0) {
      Fiber.abort("Items list must be multiples of 2")
    }
    _done = false
    _actions = actions
    _size = _actions.count / 2
    _cursor = 0
    _width = 0
    for (i in 0..._size) {
      _width = M.max(_width, Canvas.getPrintArea(_actions[i * 2]).x)
    }
  }

  update() {
    if (InputActions.cancel.justPressed) {
      _done = true
      return
    }
    if (InputActions.confirm.justPressed) {
      var action = _actions[_cursor * 2 + 1]
      if (!action || action == "cancel") {
        _done = true
      } else if (action is Action) {
        var player = ctx.getEntityByTag("player")
        player.action = action
        _done = true
      }
    } else if (InputActions.up.justPressed) {
      _cursor = _cursor - 1
    } else if (InputActions.down.justPressed) {
      _cursor = _cursor + 1
    }
    _cursor = M.mid(0, _cursor, _size - 1)
  }

  draw() {
    Canvas.rectfill(0, 0, 10 + _width, _size * 8 + 6, Display.bg)
    var y = 4
    var i = 0
    for (i in 0..._size) {
      if (i == _cursor) {
        Canvas.print(">", 3, y, Display.fg)
      }
      Canvas.print(_actions[i * 2], 10, y, Display.fg)
      y = y + 8
    }
    Canvas.rect(1, 1, 10 + _width, _size * 8 + 6, Display.fg)
  }

  finished { _done }
}
