import "./core/entity" for Entity

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

