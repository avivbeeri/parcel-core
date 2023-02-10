import "math" for Vec

import "core/dataobject" for DataObject
import "core/elegant" for Elegant

class Room is Vec {
  construct new(x, y, w, h) {
    super(x, y, w, h)
    _neighbours = []
    _doors = []
    _id = __id || 0
    __id = _id + 1
  }

  id { _id }
  kind { _kind }
  kind=(v) { _kind = v }

  neighbours { _neighbours }
  doors { _doors }
  toString { "Room [%(super.toString)]"}

  width { z }
  height { w }

  contains(pos) {
    return (pos.x > this.x &&
          pos.x < this.x + this.width &&
          pos.y > this.y &&
          pos.y < this.y + this.height)
  }
}

class Tile is DataObject {
  static new() {
    return Tile.new({})
  }
  construct new(data) {
    super(data)
  }

  toString { "Tile: %(texture), %(data)" }
}

var VOID_TILE = Tile.new({ "solid": true })
var EMPTY_TILE = Tile.new()

class TileMap {
  construct init() {
    _tiles = {}
    _default = {}
  }

  default { _default }
  default=(v) { _default = v }


  clearAll() { _tiles = {} }
  clear(vec) { clear(vec.x, vec.y) }
  clear(x, y) {
    this[x, y] = Tile.new()
  }

  report() {
    for (key in _tiles.keys) {
      System.print(Elegant.unpair(key))
    }
  }

  [vec] {
    return this[vec.x, vec.y]
  }

  [vec]=(tile) {
    this[vec.x.floor, vec.y.floor] = tile
  }

  [x, y] {
    var pair = Elegant.pair(x.floor, y.floor)
    if (!_tiles[pair]) {
      return Tile.new(_default)
    }
    return _tiles[pair]
  }

  [x, y]=(tile) {
    var pair = Elegant.pair(x.floor, y.floor)
    _tiles[pair] = tile
  }

  tiles { _tiles }
}

