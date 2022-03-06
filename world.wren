import "core/dataobject" for DataObject
import "core/event" for EntityAddedEvent, EntityRemovedEvent

class World is DataObject {
  construct new(strategy) {
    super()
    _worlds = []
    _strategy = strategy
    _gameover = false
  }

  gameover { _gameover }
  gameover=(v) { _gameover = v }

  pushZone(world) {
    world.parent = this
    _worlds.insert(0, world)
    _strategy.bind(active)
    return world
  }
  popZone() {
    return _worlds.removeAt(0)
  }

  active { _worlds[0] }
  strategy { _strategy }

  update() {
    _ghosts = []
    _strategy.bind(active).update()
  }
}

class Zone is DataObject {
  construct new() {
    super()
    init()
  }

  construct new(map) {
    super()
    init()
    _map = map
  }

  init() {
    _entities = []
    _ghosts = []
    _events = []
    _tagged = {}
    _postUpdate = []
    _map = _map || null
    _parent = _parent || null
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
    addEntity(entity)
    _tagged[tag] = entity.id
    return entity
  }

  addEntity(entity) {
    entity.ctx = this
    _entities.add(entity)
    parent.strategy.onEntityAdd(entity)

    /*
    if (_freeIds.count > 0) {
      entity.id = _freeIds.removeAt(-1)
    } else {
      */
      entity.id = _nextId
      _nextId = _nextId + 1
    // }
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
    _ghosts.add(entity)
    entity.alive = false
    _events.add(EntityRemovedEvent.new(entity.id))
  }

  getEntityByTag(tag, includeGhost) { getEntityById(_tagged[tag], includeGhost) }
  getEntityByTag(tag) { getEntityById(_tagged[tag], false) }
  getEntityById(id) { getEntityById(id, true) }
  getEntityById(id, includeGhosts) {
    var ent = _entities.where {|entity| entity.id == id }
    if (ent.count == 0 && includeGhosts) {
      ent = _ghosts.where {|entity| entity.id == id }
      return ent.toList.removeAt(0)
    }

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
