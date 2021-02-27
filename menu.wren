import "math" for M
import "graphics" for Canvas
import "./display" for Display
import "./core/scene" for Ui
import "./core/action" for Action
import "./keys" for Actions

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
      _width = M.max(_width, _actions[i * 2].count)
    }
  }

  update() {
    if (Actions.cancel.justPressed) {
      _done = true
      return
    }
    if (Actions.confirm.justPressed) {
      var action = _actions[_cursor * 2 + 1]
      if (action == "cancel") {
        _done = true
      } else if (action is Action) {
        var player = ctx.getEntityByTag("player")
        player.action = action
        _done = true
      }
    } else if (Actions.up.justPressed) {
      _cursor = _cursor - 1
    } else if (Actions.down.justPressed) {
      _cursor = _cursor + 1
    }
    _cursor = M.mid(0, _cursor, _size - 1)
  }

  draw() {
    Canvas.rectfill(0, 0, 10 + _width * 6, _size * 8 + 6, Display.bg)
    var y = 4
    var i = 0
    for (i in 0..._size) {
      if (i == _cursor) {
        Canvas.print(">", 3, y, Display.fg)
      }
      Canvas.print(_actions[i * 2], 10, y, Display.fg)
      y = y + 8
    }
    Canvas.rect(1, 1, 10 + _width * 6 - 2, _size * 8 + 6, Display.fg)
  }

  finished { _done }
}
