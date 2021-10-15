import "graphics" for Canvas
import "input" for Mouse
import "./core/scene" for Ui, GameElement
import "./palette" for EDG32, EDG32A

class Widget is GameElement {}
class Button is Widget {
  construct new(text, pos, size) {
    _text = text
    _pos = pos
    _size = size
    _corner = pos + size
    _clicked = false
    _hover = false
  }

  hover { _hover }
  clicked { _clicked }

  update() {
    var mouse = Mouse.pos
    _hover = mouse.x >= _pos.x && mouse.x < _corner.x && mouse.y >= _pos.y && mouse.y < _corner.y
    _clicked = _hover && Mouse["left"].justPressed
    return this
  }

  draw() {
    var c = EDG32[20]
    if (hover) {
      c = EDG32[21]
    }
    if (clicked) {
      c = EDG32[22]
    }
    Canvas.rectfill(_pos.x, _pos.y, _size.x, _size.y, c)
    var x = _pos.x + (_size.x - (_text.count * 8)) / 2
    Canvas.print(_text, _pos.x+4, _pos.y+4, EDG32[19])
  }
}
