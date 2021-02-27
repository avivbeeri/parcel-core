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

    // process entities
    processEntities()

    world.postUpdate.each {|hook| hook.update() }
    world.events.sort {|a, b| a.priority < b.priority}
  }

  processEntities() {}
}

class RealTimeStrategy is Director {
  construct new() { super() }
  processEntities() {
    var actions = world.entities.map {|entity|
      var action = entity.update()
      if (action) {
        action.bind(entity)
      }
      return action
    }.toList
    actions.where {|action| action != null }.each {|action| action.perform() }
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

  gainEnergy(actor) {
    actor.priority = actor.priority + (actor["#speed"] || 1)
    actor.priority = M.min(actor.priority, threshold)
  }

  threshold { 12 }

  processEntities() {
    var actor = world.entities[turn]
    gainEnergy(actor)
    if (actor.priority < threshold) {
      advance()
      return
    }

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

      if (!result.alternate) {
        break
      }
      action = result.alternate
    }
    actor.priority = 0
    advance()
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

      if (!result.alternate) {
        break
      }
      action = result.alternate
    }
    advance()
  }
}
