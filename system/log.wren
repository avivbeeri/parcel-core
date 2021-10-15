import "graphics" for Canvas
import "math" for M
import "./palette" for EDG32
class Log {
  construct new() {
    _log = []
    _hidden = true
  }

  print(text) {
    System.print(text.toString)
    _log.add(text.toString)
  }

  toggle() { _hidden = !_hidden }
  hidden { _hidden }

  log { _log }

  draw(x, y) {
    if (_hidden) {
      return
    }
    Canvas.rectfill(0, y, Canvas.width, Canvas.height - y, EDG32[27])

    var lines = _log.skip(M.max(0, _log.count - 3)).toList
    var text = lines.join("\n")
    Canvas.print(text, x, y, EDG32[25], "m5x7")
  }
}
