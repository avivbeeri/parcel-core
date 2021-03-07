import "core/dataobject" for DataObject
import "core/event" for EntityAddedEvent, EntityRemovedEvent

class World is DataObject {
  construct new(strategy) {
    super()
    _worlds = []
    _strategy = strategy
  }

  pushZone(world) {
    world.parent = this
    _worlds.insert(0, world)
    return world
  }
  popZone() {
    return _worlds.removeAt(0)
  }

  active { _worlds[0] }
  strategy { _strategy }

  update() {
    _strategy.bind(active).update()
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
    _parent = null
    _nextId = 0
    _freeIds = []
  }

  entities { _entities }
  events { _events }

  map { _map }
  map=(v) { _map = v }
  postUpdate { _postUpdate }

  parent { _parent }
  parent=(v) { _parent = v }

  addEntity(tag, entity) {
    _tagged[tag] = entity
    return addEntity(entity)
  }

  addEntity(entity) {
    entity.ctx = this
    _entities.add(entity)
    parent.strategy.onEntityAdd(entity)

    if (_freeIds.count > 0) {
      entity.id = _freeIds.removeAt(-1)
    } else {
      entity.id = _nextId
      _nextId = _nextId + 1
    }
    _events.add(EntityAddedEvent.new(entity.id))

    return entity
  }

  removeEntity(entity) {
    var pos = entities.indexOf(entity)
    if (pos == -1) {
      return
    }
    _freeIds.add(entity.id)
    parent.strategy.onEntityRemove(pos)
    entities.removeAt(pos)
    _events.add(EntityRemovedEvent.new(entity.id))
  }

  getEntityByTag(tag) { _tagged[tag] }
  getEntityById(id) {
    var ent = _entities.where {|entity| entity.id == id }
    if (ent.count == 1) {
      return ent.toList.removeAt(0)
    } else if (ent.count > 1) {
      Fiber.abort("Assert failure: Entities cannot share IDs")
    }
    return null
  }

  getEntitiesAtTile(vec) { getEntitiesAtTile(vec.x, vec.y) }
  getEntitiesAtTile(x, y) {
    return _entities.where {|entity| entity.occupies(x, y) }
  }

  isSolidAt(pos) { isSolidAt(pos.x, pos.y) }
  isSolidAt(x, y) {
    return map[x, y]["solid"]
  }
}
