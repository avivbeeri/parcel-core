import "graphics" for ImageData, Color, Canvas
import "dome" for Window

class Display {
  static setup() {
    Canvas.resize(240, 160)
    Window.title = "Untitled Game"
    __fg = Color.white
    __bg = Color.hex("#262b44")
    init_()
  }

  static setup(config) {
    Canvas.resize(config["width"], config["height"])
    Window.title = config["title"]
    __fg = Color.hex(config["foreground"])
    __bg = Color.hex(config["background"])
    init_()
  }

  static init_() {
    var scale = 3
    Window.lockstep = true
    Window.resize(Canvas.width * scale, Canvas.height * scale)
  }

  static fg { __fg }
  static fg=(v) { __fg = v }
  static bg { __bg }
  static bg=(v) { __bg = v }
}

