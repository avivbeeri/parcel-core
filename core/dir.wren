import "math" for Vec

var Directions = {
  "w": Vec.new(-1, 0),
  "nw": Vec.new(-1, -1),
  "n": Vec.new(0, -1),
  "ne": Vec.new(1, -1),
  "e": Vec.new(1, 0),
  "se": Vec.new(1, 1),
  "s": Vec.new(0, 1),
  "sw": Vec.new(-1, 1)
}

var NSEW = {
  "w": Vec.new(-1, 0),
  "n": Vec.new(0, -1),
  "e": Vec.new(1, 0),
  "s": Vec.new(0, 1)
}
