import "core/dataobject" for DataObject
import "core/elegant" for Elegant

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
    this[vec.x, vec.y] = tile
  }

  [x, y] {
    var pair = Elegant.pair(x, y)
    if (!_tiles[pair]) {
      return Tile.new(_default)
    }
    return _tiles[pair]
  }

  [x, y]=(tile) {
    var pair = Elegant.pair(x, y)
    _tiles[pair] = tile
  }
}

