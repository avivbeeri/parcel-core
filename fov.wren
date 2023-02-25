var Transforms = [
  [ 1, 0, 0, 1],
  [ 1, 0, 0, -1],
  [ -1, 0, 0, 1],
  [ -1, 0, 0, -1],
  [ 0, 1, 1, 0],
  [ 0, 1, -1, 0],
  [ 0, -1, 1, 0],
  [ 0, -1, -1, 0]
]

class Vision {
  construct new(map, origin) {
    _map = map
    _origin = origin
  }

  compute() {
    reveal(_origin)
    for (i in 0...8) {
      scan(1, 0, 1, Transforms[i])
    }
  }

  scan(y, start, end, transform) {
    if (start >= end) {
      return
    }
    var xmin = ((y - 0.5) * start).round
    var xmax = ((y + 0.5) * end - 0.5).ceil

    for (x in xmin..xmax) {
      var realx = _origin.x + transform[0] * x + transform[1] * y
      var realy = _origin.y + transform[2] * x + transform[3] * y
      if (!_map.isSolid(realx, realy)) {
        if (x >= y * start && x <= y * end) {
          reveal(realx, realy)
        }
      } else {
        if (x >= (y - 0.5) * start && x - 0.5 <= y * end) {
          reveal(realx, realy)
        }
        scan(y + 1, start, (x - 0.5) / y, transform)
        start = (x + 0.5) / y
        if (start >= end) {
          return
        }
      }
    }
    scan(y + 1, start, end, transform)
  }

  reveal(pos) { reveal(pos.x, pos.y) }
  reveal(x, y) {
    if (!_map.inBounds(x, y)) {
      return
    }
    _map[x.floor, y.floor]["visible"] = true
  }
}
