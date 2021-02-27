import "graphics" for ImageData, Color, Canvas
class Display {
  static setup() {
    Canvas.resize(240, 160)
  }

  static fg { Color.white }
  static bg { Color.black }
}

