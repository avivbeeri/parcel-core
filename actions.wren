import "./core/action" for Action, ActionResult
import "math" for M, Vec
import "./events" for CollisionEvent, MoveEvent

class LogAction is Action {
  construct new() {
    super()
  }

  perform() {
    System.print("You make journal notes")
    return ActionResult.success
  }

}
class SleepAction is Action {
  cost { 2 }
  construct new() {
    super()
  }

  perform() {
    System.print("You sleep, and awaken refreshed.")
    return ActionResult.alternate(LogAction.new())
  }
}

class MoveAction is Action {
  construct new(dir, alwaysSucceed) {
    super()
    _dir = dir
    _succeed = alwaysSucceed
  }

  construct new(dir) {
    super()
    _dir = dir
    _succeed = false
  }

  handleCollision(pos) {
    var occupying = ctx.getEntitiesAtTile(pos.x, pos.y).where {|entity| entity != source }
    var solidEntity = false
    for (entity in occupying) {
      var event = entity.notify(ctx, CollisionEvent.new(this, entity, pos))
      if (!event.cancelled) {
        ctx.events.add(event)
        solidEntity = true
      }
    }
    return solidEntity
  }

  perform() {
    var old = source.pos * 1
    source.vel = _dir
    source.pos.x = source.pos.x + source.vel.x
    source.pos.y = source.pos.y + source.vel.y

    var result = ActionResult.failure

    if (source.pos != old) {
      var solid = ctx.isSolidAt(source.pos)
      var occupied = false
      occupied = !solid && handleCollision(source.pos)
      if (solid || occupied) {
        source.pos = old
      }
      if (occupied) {
        result = ActionResult.alternate(AttackAction.new(_dir))
      }
    }

    if (source.pos != old) {
      ctx.events.add(MoveEvent.new(source))
      result = ActionResult.success
    } else if (_succeed) {
      result = ActionResult.alternate(Action.none)
    }

    if (source.vel.length > 0) {
      source.vel = Vec.new()
    }
    return result
  }
}

class AttackAction is Action {
  construct new(dir) {
    super()
    _dir = dir
    _succeed = false
  }
  perform() {
    var target = source.pos + _dir
    var occupying = ctx.getEntitiesAtTile(target.x, target.y).where {|entity| entity != source }
    occupying.each {|entity| ctx.removeEntity(entity) }
    return ActionResult.success
  }

}
