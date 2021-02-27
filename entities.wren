import "math" for Vec
import "./core/entity" for Entity
import "./events" for CollisionEvent, MoveEvent
import "./actions" for MoveAction

class Dummy is Entity {
  construct new() {
    super()
  }

  update() {
    return MoveAction.new(Vec.new(1, 0), true)
  }
}

class Player is Entity {
  construct new() {
    super()
    _action = null
  }

  action { _action }
  action=(v) {
    _action = v
  }

  update() {
    var action = _action
    _action = null
    return action
  }
}

