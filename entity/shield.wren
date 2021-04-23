import "./entity/stackcreature" for StackCreature
import "./entity/behaviour" for SeekBehaviour, WaitBehaviour

class Shield is StackCreature {
  construct new(config) {
    super(config)
    push(WaitBehaviour.new(this))
    push(SeekBehaviour.new(this))
  }
}

