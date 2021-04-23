import "./core/entity" for Entity
import "./actions" for Action
import "./events" for CollisionEvent

class Collectible is Entity {
  construct new() {
    super()
  }

  construct new(item) {
    super()
    _item = item
  }

  item { _item }
}

