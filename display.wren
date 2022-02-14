import "graphics" for ImageData, Color, Canvas, Font
import "dome" for Window
import "math" for Vec

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

  static print(text, settings) {
    text = text is String ? text : text.toString
    var color = settings["color"] || Color.black
    var align = settings["align"] || "left"
    var position = settings["position"] || Vec.new()
    // TODO vertical size?
    var size = settings["size"] || Vec.new(Canvas.width, Canvas.height)
    var font = settings["font"] || Font.default
    var overflow = settings["overflow"] || false

    var lines = []
    var words = text.split(" ")
    var maxWidth = size.x
    var nextLine
    var lineDims = []
    var currentLine

    while (true) {
      currentLine = words.join(" ")
      var area = Font[font].getArea(currentLine)
      nextLine = []
      while (area.x > maxWidth && words.count > 1) {
        // remove the last word, add it to the start of the nextLine
        nextLine.insert(0, words.removeAt(-1))
        currentLine = words.join(" ")
        // compute the current line's area now
        area = Font[font].getArea(currentLine)
        // and recheck
      }

      lineDims.add(area)
      lines.add(currentLine)
      if (nextLine.count == 0) {
        break
      }
      words = nextLine
    }

    if (!overflow) {
      Canvas.clip(position.x, position.y, size.x, size.y)
    }

    var x
    var y = position.y
    for (lineNumber in 0...lines.count) {
      if (align == "left") {
        x = position.x
      } else if (align == "center") {
        x = ((size.x + position.x) - lineDims[lineNumber].x) / 2
      } else if (align == "right") {
        x = position.x + size.x - lineDims[lineNumber].x
      } else {
        Fiber.abort("invalid text alignment: %(align)")
      }
      Canvas.print(lines[lineNumber], x, y, color, font)
      y = y + lineDims[lineNumber].y
    }

    if (!overflow) {
      Canvas.clip()
    }
    return Vec.new(size.x, y - position.y)
  }

  static printCentered(text, y, color, font) {
    if (font == Font.default) {
      return printCentered(text, y, color)
    }
    return Display.print(text, {
      "color": color,
      "font": font,
      "align": "center",
      "position": Vec.new(0, y),
      "size": Vec.new(Canvas.width, Canvas.height),
      "overflow": true
    })
  }
  static printCentered(text, y, color) {
    var x = (Canvas.width - (text.count * 8)) / 2
    Canvas.print(text, x, y, color)
  }

  static init_() {
    var scale = 2
    Window.resize(Canvas.width * scale, Canvas.height * scale)
  }

  static fg { __fg }
  static fg=(v) { __fg = v }
  static bg { __bg }
  static bg=(v) { __bg = v }
}

