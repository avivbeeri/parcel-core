import "graphics" for ImageData, Color, Canvas
import "dome" for Window

class Display {
  static setup() {
    var scale = 3
    Canvas.resize(240, 160)
    Window.title = "Untitled Game"
    Window.lockstep = true
    Window.resize(Canvas.width * scale, Canvas.height * scale)

    __fg = Color.white
    __bg = Color.hex("#262b44")
  }

  static fg { __fg }
  static fg=(v) { __fg = v }
  static bg { __bg }
  static bg=(v) { __bg = v }
}

