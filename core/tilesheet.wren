import "graphics" for ImageData, Color
import "./display" for Display

class Tilesheet {
  construct new(path, tileSize) {
    _image = ImageData.loadFromFile(path)
    _tSize = tileSize
    if (_image.width % _tSize != 0) {
      Fiber.abort("Image is not an integer number of tiles wide")
    }
    _width = _image.width / _tSize
  }

  draw(s, x, y) { draw(s, x, y, Display.fg, Display.bg) }
  draw(s, x, y, fg, bg) { getTile(s, fg, bg).draw(x, y) }

  getTile(s) { getTile(s, Display.fg, Display.bg) }
  getTile(s, fg, bg) {
    var sy = (s / _width).floor * _tSize
    var sx = (s % _width).floor * _tSize

    return _image.transform({
      "srcX": sx, "srcY": sy,
      "srcW": _tSize, "srcH": _tSize,
      "mode": "MONO",
      "foreground": fg,
      "background": bg
    })
  }
}
