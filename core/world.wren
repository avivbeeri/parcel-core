import "core/dataobject" for DataObject

class World is DataObject {
  construct new(strategy) {
    super()
    _worlds = []
    _strategy = strategy
  }

  pushZone(world) {
    _worlds.insert(0, world)
  }
  popZone() {
    return _worlds.removeAt(0)
  }

  active { _worlds[0] }

  update() {
    _strategy.update(active)
  }
}

class Zone is DataObject {
  construct new() {
    super()
    _entities = []
    _events = []
    _tagged = {}
    _postUpdate = []
    _map = null
  }

  entities { _entities }
  events { _events }

  map { _map }
  map=(v) { _map = v }
  postUpdate { _postUpdate }

  getEntityByTag(tag) { _tagged[tag] }

  addEntity(tag, entity) {
    _tagged[tag] = entity
    return addEntity(entity)
  }

  addEntity(entity) {
    entity.ctx = this
    _entities.add(entity)
    _entities.sort {|a, b| a.priority < b.priority}
    return entity
  }

  update() {
    _events.clear()
    _entities.each {|entity| entity.update(this) }
    _postUpdate.each {|hook| hook.update(this) }
    _events.sort {|a, b| a.priority < b.priority}
  }

  draw() {
    _entities.each {|entity| entity.draw(this) }
  }

  getEntitiesAtTile(x, y) {
    return _entities.where {|entity| entity.occupies(x, y) }
  }

  checkCollision(vec) { checkCollision(vec.x, vec.y) }
  checkCollision(x, y) {
    var solid = map[x, y]["solid"]
    var occupies = false
    if (!solid) {
      for (entity in _entities) {
        // Todo: There's no way to check the player
        if (entity["solid"] && entity.occupies(x, y)) {
          occupies = true
          break
        }
      }
    }
    return solid || occupies
  }
}
