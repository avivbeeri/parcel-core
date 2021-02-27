import "./core/action" for Action

class RealTimeStrategy {
  construct new() {}
  update(world) {
    world.events.clear()
    world.entities.each {|entity| entity.update() }
    world.postUpdate.each {|hook| hook.update() }
    world.events.sort {|a, b| a.priority < b.priority}
  }
}

class TurnBasedStrategy  {
  construct new() {
    _turn = 0
  }

  update(world) {
    var actor = world.entities[_turn]
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
    _turn = (_turn + 1) % world.entities.count
  }
}
