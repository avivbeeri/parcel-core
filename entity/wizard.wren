import "./entity/stackcreature" for StackCreature
import "./entity/behaviour" for SpawnBehaviour, SeekBehaviour, WaitBehaviour

class Wizard is StackCreature {
  construct new(config) {
    super(config)
    push(WaitBehaviour.new(this))
    push(SpawnBehaviour.new(this, 6, "fireball"))
    push(SeekBehaviour.new(this))
  }
}

