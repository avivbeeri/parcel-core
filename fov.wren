import "math" for Vec
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
    _depth = null
    _origin = origin
  }
  construct new(map, origin, maxDepth) {
    _map = map
    _maxDepth = maxDepth
    _origin = origin
  }

  compute() {
    reveal(_origin)
    for (i in 0...8) {
      scan(1, 0, 1, Transforms[i])
    }
  }

  scan(y, start, end, transform) {
    if ((_maxDepth && y > _maxDepth) || start >= end) {
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

class Quadrant {
  construct new(cardinal, origin) {
    _cardinal = cardinal
    _origin = origin
  }

  origin { _origin }
  cardinal { _cardinal }

  static north { 0 }
  static south { 1 }
  static east { 2 }
  static west { 3 }

  transform(tile) {
    if (cardinal == Quadrant.north) {
      return Vec.new(origin.x + tile.x, origin.y - tile.y)
    } else if (cardinal == Quadrant.south) {
      return Vec.new(origin.x + tile.x, origin.y + tile.y)
    } else if (cardinal == Quadrant.east) {
      return Vec.new(origin.x + tile.y, origin.y + tile.x)
    } else if (cardinal == Quadrant.west) {
      return Vec.new(origin.x - tile.y, origin.y + tile.x)
    }
  }
}

class Row {
  construct new(depth, startSlope, endSlope) {
    _depth = depth
    _start = startSlope
    _end = endSlope
  }

  start { _start }
  start=(v) { _start = v }
  end { _end }
  end=(v) { _end = v }
  depth { _depth }

  tiles {
    var minCol  = Row.roundTiesUp((start * depth).value)
    var maxCol  = Row.roundTiesDown((end * depth).value)
    var tiles = []
    for (col in minCol...(maxCol + 1)) {
      tiles.add(Vec.new(col, depth))
    }
    return tiles
  }

  next {
    return Row.new(depth + 1, start, end)
  }

  static roundTiesUp(n) { (n+0.5).floor }
  static roundTiesDown(n) { (n - 0.5).ceil }

}

class Vision2 {
  construct new(map, origin) {
    _map = map
    _maxDepth = null
    _origin = origin
  }
  construct new(map, origin, maxDepth) {
    _map = map
    _maxDepth = maxDepth
    _origin = origin
  }


  compute() {
    makeVisible(_origin)
    for (i in 0...4) {
      var quadrant = Quadrant.new(i, _origin)
      var row = Row.new(1, F.new(-1, 1), F.new(1, 1))
      scan(quadrant, row)
    }
  }


  isWall(quadrant, tile) {
    if (tile == null) {
      return false
    }
    var pos =  quadrant.transform(tile)
    return _map.isSolid(pos)
  }
  isFloor(quadrant, tile) {
    if (tile == null) {
      return false
    }
    var pos =  quadrant.transform(tile)
    return _map.isFloor(pos)
  }
  reveal(quadrant, tile) {
    if (tile == null) {
      return
    }
    var pos = quadrant.transform(tile)
    makeVisible(pos)
  }

  scan(quadrant, row) {
    if (_maxDepth && row.depth > _maxDepth) {
      return
    }
    var prev = null
    var tiles = row.tiles
    for (tile in tiles) {
      if (isWall(quadrant, tile) || Vision2.isSymmetric(row, tile)) {
        reveal(quadrant, tile)
      }
      if (isWall(quadrant, prev) && isFloor(quadrant, tile)) {
        row.start = Vision2.slope(tile)
      }
      if (isFloor(quadrant, prev) && isWall(quadrant, tile)) {
        var nextRow = row.next
        nextRow.end = Vision2.slope(tile)
        scan(quadrant, nextRow)
      }
      prev = tile
    }
    if (isFloor(quadrant, prev)) {
      scan(quadrant, row.next)
    }
  }

  static slope(tile) {
    return F.new(2 * tile.x - 1, 2 * tile.y)
  }

  static isSymmetric(row, tile) {
    return (tile.x >=  (row.start * row.depth).value) && (tile.x <= (row.end * row.depth).value)
  }
  makeVisible(pos) { makeVisible(pos.x, pos.y) }
  makeVisible(x, y) {
    if (!_map.inBounds(x, y)) {
      return
    }
    _map[x.floor, y.floor]["visible"] = true
  }
}

class F {
  construct new(n, d) {
    _n = n
    _d = d
  }
  value { _n / _d }

  * (other) {
    return F.new(_n * other, _d)
  }
}
