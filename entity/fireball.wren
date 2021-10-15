import "./entity/stackcreature" for StackCreature

class Fireball is StackCreature {
  construct new(config) {
    super(config)
    push(ProjectileBehaviour.new(this))
    _new = true
  }

  update() {
    if (_new) {
      // one-time setup
      var source = this["source"]
      var dir = this["direction"] = (pos - this["source"]).unit
      System.print("direction: %(pos) - %(source) = %(dir)")
      _new = false
    }
    return super.update()
  }

  notify(event) {
    event = super.notify(event)
    if (event is AttackEvent) {
      event.cancel()
    }
    return event
  }
}

import "./system/combat" for AttackType
import "./events" for AttackEvent
import "./entity/behaviour" for ProjectileBehaviour
