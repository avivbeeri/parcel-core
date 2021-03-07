import "graphics" for ImageData, Color, Canvas
class Display {
  static setup() {
    Canvas.resize(240, 160)
    __fg = Color.white
    __bg = Color.black
  }

  static fg { __fg }
  static fg=(v) { __fg = v }
  static bg { __bg }
  static bg=(v) { __bg = v }
}

