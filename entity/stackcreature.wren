import "math" for Vec
import "./entity/creature" for Creature

class StackCreature is Creature {
  construct new(config) {
    super(config)
    _behaviours = []
  }

  push(behaviour) {
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

import "./core/action" for Action
