import "core/dataobject" for DataObject
import "core/elegant" for Elegant

var SECTION_SIZE = 16
var SECTION_SHIFT = SECTION_SIZE.log2
var SECTION_MASK = SECTION_SIZE - 1

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
  }

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
    var sectionX = x >> SECTION_SHIFT
    var sectionY = y >> SECTION_SHIFT
    var pair = Elegant.pair(sectionX, sectionY)
    var section = _tiles[pair]
    if (section == null) {
      section = _tiles[pair] = (0...(SECTION_SIZE * SECTION_SIZE)).map {|i| Tile.new() }.toList
    }
    var subX = x & SECTION_MASK
    var subY = y & SECTION_MASK
    return section[SECTION_SIZE * subY + subX]
  }

  [x, y]=(tile) {
    var sectionX = x >> SECTION_SHIFT
    var sectionY = y >> SECTION_SHIFT
    var pair = Elegant.pair(sectionX, sectionY)
    var section = _tiles[pair]
    if (!section) {
      section = _tiles[pair] = (0...(SECTION_SIZE * SECTION_SIZE)).map {|i| Tile.new() }.toList
    }
    var subX = x & SECTION_MASK
    var subY = y & SECTION_MASK
    section[SECTION_SIZE * subY + subX] = tile
  }
}

