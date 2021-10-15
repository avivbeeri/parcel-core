import "./entity/stackcreature" for StackCreature

class Shadow is StackCreature {
  construct new(config) {
    super(config)
    push(WaitBehaviour.new(this))
    push(RangedBehaviour.new(this, 5) {|target|

      var id = config["effect"]["id"]
      var add = config["effect"]["add"]
      var mult = config["effect"]["mult"]
      var responsible = config["effect"]["responsible"]
      var duration = config["effect"]["duration"]
      var positive = config["effect"]["positive"]
      var modifier = Modifier.new(id, add, mult, duration, positive)
      return ApplyModifierAction.new(modifier, target, !config["effect"]["responsible"] || false)
    })
    push(SeekBehaviour.new(this))
  }
}

import "./system/combat" for AttackType
import "./system/stats" for Modifier
import "./actions" for ApplyModifierAction
import "./entity/behaviour" for RangedBehaviour, SeekBehaviour, WaitBehaviour
