import "math" for M, Vec
import "graphics" for Canvas
import "input" for Mouse
import "./core/display" for Display
import "./core/scene" for Ui
import "./core/action" for Action
import "./keys" for InputActions
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
