import "./core/action" for Action
import "math" for M

class Director {
  construct new() {}
  bind(world) {
    _world = world
    return this
  }
  world { _world }

  update() {
    world.events.clear()

    if (world.parent.gameover) {
      return
    }

    // process entities
    processEntities()
    runPostUpdate()
  }

  runPostUpdate() {
    world.postUpdate.each {|hook| hook.update(world) }
    cleanupEntities()
  }

  cleanupEntities() {
    world.entities
    .where {|entity| !entity.alive }
    .each {|entity|
      System.print("removing %(entity)")
      world.removeEntity(entity)
    }
  }

  processEntities() {}
  onEntityAdd(entity) {}
  onEntityRemove(entity) {}
}

class ActionStrategy is Director {
  construct new() { super() }
  processEntities() {
    var actions = world.entities.map {|entity|
      var action = entity.update()
      if (action) {
        action.bind(entity)
      }
      return action
    }.toList
    actions.where {|action| action != null }.each {|action|
      var result
      var source = action.source
      while (true) {
        result = action.perform()
        action = result.alternate
        if (action == null) {
          break
        }
      }
      source.endTurn()
    }
  }
  onEntityAdd(entity) {
    if (!world) {
      Fiber.abort("no world!?!")
    }
    world.entities.sort {|a, b| a.priority < b.priority}
  }
}

class EnergyStrategy is Director {
  construct new() {
    super()
    _turn = 0
  }
  turn { _turn }
  advance() {
    _turn = (_turn + 1) % world.entities.count
  }

  currentActor {
    return world ? world.entities[_turn] : null
  }

  gainEnergy(actor) {
    actor.priority = actor.priority + (actor.speed || 1)
    actor.priority = M.min(actor.priority, threshold)
  }

  threshold { 12 }

  gameLoop() {
    var actor = world.entities[turn]
    gainEnergy(actor)
    if (actor.priority < threshold) {
      advance()
      return true
    }

    var action = actor.getAction()

    if (!action) {
      // No action given, retry and hope we got input
      return false
    }


    while (true) {
      // System.print("Trying: %(actor): %(action)")
      var result = action.bind(actor).perform()
      if (!result.succeeded) {
        // Action wasn't successful, allow retry
        return false
      }
      // System.print(result)
      if (!result.alternate) {
        break
      }
      action = result.alternate
    }
    actor.priority = 0
    actor.endTurn()
    runPostUpdate()
    advance()
    return true
  }

  processEntities() {
    var advance = true
    while (advance && !world.parent.gameover) {
      advance = gameLoop()
    }
  }

  onEntityRemove(pos) {
    if (pos > _turn) {
      _turn = _turn - 1
    }
    // It hasn't been deleted yet but it is about to be.
    if (_turn >= world.entities.count - 1) {
      _turn = 0
    }
  }
}

class TurnBasedStrategy is Director  {
  construct new() {
    super()
    _turn = 0

  }

  turn { _turn }
  advance() {
    _turn = (_turn + 1) % world.entities.count
  }

  processEntities() {
    var actor = world.entities[turn]
    var action = actor.getAction()

    if (!action) {
      // No action given, retry and hope we got input
      return
    }

    while (true) {

      var result = action.bind(actor).perform()
      if (!result.succeeded) {
        // Action wasn't successful, allow retry
        return
      }
      // System.print("%(actor): %(action)")

      if (!result.alternate) {
        break
      }
      action = result.alternate
    }
    actor.endTurn()
    advance()
  }

  onEntityRemove(pos) {
    if (pos > _turn) {
      _turn = _turn - 1
    }
    // It hasn't been deleted yet but it is about to be.
    if (_turn >= world.entities.count - 1) {
      _turn = 0
    }
  }
}
