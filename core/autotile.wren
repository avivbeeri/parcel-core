import "json" for Json
import "math" for Vec
import "input" for Keyboard
import "./core/dir" for Directions

var RuleFile = Json.load("tileRules.json")

class AutoTile {
  static pick(map, x, y) {
    var pos = Vec.new(x, y)

    var tile = map[pos]
    var config = RuleFile[tile["floor"]]
    if (!config) {
      return -1
    }

    var neighbours = {}
    for (dir in Directions.keys) {
      neighbours[dir] = map[pos + Directions[dir]]["floor"]
    }

    var result = config["defaultTileIndex"]
    for (rule in config["rules"]) {
      var index = rule["tileIndex"]
      var ruleMap = rule["map"]
      var match = true
      for (dir in ruleMap.keys) {
        var expected = ruleMap[dir]
        var negate = expected.startsWith("!")
        expected = expected.replace("!", "")

        if ((!negate && neighbours[dir] != expected) ||
             (negate && neighbours[dir] == expected)) {
          match = false
          break
        }
      }
      if (match) {
        result = index
        break
      }
    }

    return result
  }
}
