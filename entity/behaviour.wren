import "math" for Vec

import "./core/action" for Action
import "./core/config" for Config
import "./core/dir" for NSEW

import "./combat" for Attack, AttackType
import "./actions" for MoveAction, AttackAction, DespawnAction, MultiAction, SpawnAction
import "./rng" for RNG

class Behaviour {
  construct new(self) {
    _self = self
  }
  self { _self }
  ctx { _self.ctx }

  notify(event) {}
  evaluate() {}
}

class ProjectileBehaviour is Behaviour {
  construct new(self) {
    super(self)
  }

  evaluate() {
    var map = ctx.map
    var dir = self["direction"]
    var despawn = DespawnAction.new()
    var dest = self.pos + dir
    if (ctx.isSolidAt(dest)) {
      return despawn
    }
    if (ctx.getEntitiesAtTile(dest).count > 0) {
      return MultiAction.new([
        AttackAction.new(dest, Attack.new(self["stats"].get("atk"), AttackType.fire, false)),
        despawn
      ], true)
    }
    System.print(dest)
    return MoveAction.new(dir, true, despawn)
  }
}
class WaitBehaviour is Behaviour {
  construct new(self) {
    super(self)
    self["seenPlayer"] = false
  }

  evaluate() {
    var map = ctx.map
    var player = ctx.getEntityByTag("player")
    var room = map[self.pos]["room"]
    if (self["seenPlayer"]) {
      return null
    }
    if (room) {
      if (player.pos.x > room.x &&
          player.pos.x < room.x + room.width &&
          player.pos.y > room.y &&
          player.pos.y < room.y + room.height) {
        self["seenPlayer"] = true
        return null
      } else {
        var search = player["dijkstra"]
        var path = DijkstraMap.reconstruct(search[0], player.pos, self.pos)
        if (path && path.count < 2 + 2) {
          System.print("CLOSE")
          self["seenPlayer"] = true
          return null
        }
      }
    }
    var dir = RNG.sample(NSEW.values.toList)
    if (dir) {
      return MoveAction.new(dir, true, Action.none )
    } else {
      return Action.none
    }
  }
}


class SeekBehaviour is Behaviour {
  construct new(self) {
    super(self)
  }

  evaluate() {
    var map = ctx.map
    var player = ctx.getEntityByTag("player")
    if (player) {
      var search = player["dijkstra"]
      var path = DijkstraMap.reconstruct(search[0], player.pos, self.pos)
      if (path == null) {
        return Action.none
      }
      return MoveAction.new(path[1] - self.pos, true)
    }
    return Action.none
  }
}
class RangedBehaviour is Behaviour {
  construct new(self, range) {
    super(self)
    _maxRange = range
  }
  construct new(self, range, factory) {
    super(self)
    _maxRange = range
    _factory = factory
  }

  evaluate() {
    var map = ctx.map
    var player = ctx.getEntityByTag("player")
    if (player) {
      if (player.pos.x == self.pos.x || player.pos.y == self.pos.y) {
        // Same x or y coordinate
        var range = (player.pos - self.pos)
        if (range.manhattan < _maxRange) {
          // In range
          // check LOS
          var solid = false
          var unit = range.unit
          for (step in 0..range.manhattan) {
            var tile = self.pos + unit * step
            if (ctx.isSolidAt(tile)) {
              solid = true
              break
            }
          }
          if (!solid) {
            // attack is good
            if (!_factory) {
              return AttackAction.new(player.pos, Attack.new(self["stats"].get("spi"), AttackType.lightning, false))
            } else {
              return _factory.call(player)
            }
          }
        }
      }
    }
  }
}

class SpawnBehaviour is RangedBehaviour {
  construct new(self, range, id) {
    super(self, range)
    _cast = false
    var entityConfig
    for (config in Config["entities"]) {
      if (config["id"] == id) {
        _entityConfig = config
        break
      }
    }
  }

  evaluate() {
    var action = super.evaluate()
    if (action is AttackAction ) {
      var dir = (action.location - self.pos).unit
      if (ctx.getEntitiesAtTile(self.pos + dir).count > 0) {
        action = null
      } else {
        var entity = EntityFactory.prepare(_entityConfig)
        entity["source"] = self.pos * 1
        action = SpawnAction.new(entity, self.pos + dir)
      }
    }
    return action
  }
}
import "./factory" for EntityFactory
import "./core/graph" for WeightedZone, BFS, AStar, DijkstraMap
