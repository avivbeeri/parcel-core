import "math" for Vec
import "./core/world" for DataObject
import "./core/action" for Action

class Entity is DataObject {
  construct new() {
    super()
    init()
  }
  construct new(config) {
    super(config)
    init()
  }

  init() {
    _pos = Vec.new()
    _size = Vec.new(1, 1)
    _vel = Vec.new()
    _name = null

    // Lower is better
    _priority = 0
    _alive = true
  }

  id { _id }
  id=(v) { _id = v }

  ctx { _ctx }
  ctx=(v) { _ctx = v }

  pos { _pos }
  pos=(v) { _pos = v }

  size { _size }
  size=(v) { _size = v }

  vel { _vel }
  vel=(v) { _vel = v }

  priority=(v) { _priority = v }
  priority { _priority }

  alive=(v) { _alive = v }
  alive { _alive }

  // May not always be used, can be override
  speed { 1 }

  move() {
    // pos = pos + vel
    pos.x = pos.x + vel.x
    pos.y = pos.y + vel.y
  }

  occupies(x, y) {
    return pos.x <= x &&
           x <= pos.x + size.x - 1 &&
           pos.y <= y &&
           y <= pos.y + size.y - 1
  }

  notify(event) { notify(ctx, event) }
  notify(ctx, event) { event }
  getAction() { update() }
  endTurn() {}
  name { _name || this.type.name }
  name=(v) { _name = v }

  update() { Action.none }
  draw() {}

  toString { "%(name) (id: %(_id))" }
}

class StackEntity is Entity {
  construct new() {
    super()
    _behaviours = []
  }
  construct new(config) {
    super(config)
    _behaviours = []
  }

  push(behaviour) {
    if (behaviour is Class) {
      behaviour = behaviour.new(this)
    }
    _behaviours.add(behaviour)
  }

  update() {
    var action
    for (behaviour in _behaviours) {
      action = behaviour.evaluate()
      if (action) {
        break
      }
    }
    return action || Action.none
  }
}

class EntityFactory {
  static map {
    if (!__map) {
      __map = {}
    }
    return __map
  }

  static register(name, entityClass) {
    map[name] = entityClass
  }

  static prepare(config) {
    var classType = config["classType"]
    if (map.contains(classType)) {
      Fiber.abort("Unknown entity type %(classType)")
    }
    return map[classType].new(config)
  }
}
