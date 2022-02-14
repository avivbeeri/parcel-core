import "graphics" for ImageData, Color
import "./core/display" for Display

class Tilesheet {
  construct new(path) {
    setup(path, 8, 1)
  }

  construct new(path, tileSize) {
    setup(path, tileSize, 1)
  }

  construct new(path, tileSize, scale) {
    setup(path, tileSize, scale)
  }

  setup(path, tileSize, scale) {
    _image = ImageData.loadFromFile(path)
    _tSize = tileSize
    if (_image.width % _tSize != 0) {
      Fiber.abort("Image is not an integer number of tiles wide")
    }
    _width = _image.width / _tSize
    _scale = scale
    _cache = {}
  }

  draw(s, x, y) { draw(s, x, y, null, null) }
  draw(s, x, y, fg, bg) { getTile(s, fg, bg).draw(x, y) }
  draw(s, x, y, fg, bg, cache) { getTile(s, fg, bg, cache).draw(x, y) }

  getTile(s) { getTile(s, null, null) }
  getTile(s, fg, bg) { getTile(s, fg, bg, true) }
  getTile(s, fg, bg, useCache) {
    if (!_cache[s] || !useCache) {
      var sy = (s / _width).floor * _tSize
      var sx = (s % _width).floor * _tSize

      var transform = _image.transform({
        "srcX": sx, "srcY": sy,
        "srcW": _tSize, "srcH": _tSize,
        "mode": fg ? "MONO" : "RGBA",
        "scaleX": _scale,
        "scaleY": _scale,
        "foreground": fg,
        "background": bg
      })
      _cache[s] = transform
    }

    return _cache[s]
  }
}
