import "./entity/stackcreature" for StackCreature

class Thunder is StackCreature {
  construct new(config) {
    super(config)
    push(WaitBehaviour.new(this))
    push(RangedBehaviour.new(this, 3))
    push(SeekBehaviour.new(this))
  }

  notify(event) {
    event = super.notify(event)
    if (event is AttackEvent && event.attack.attackType == AttackType.lightning) {
      event.fail()
    }
    return event
  }
}

import "./system/combat" for AttackType
import "./events" for AttackEvent
import "./entity/behaviour" for RangedBehaviour, SeekBehaviour, WaitBehaviour
