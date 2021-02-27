import "./core/action" for Action, ActionResult
import "math" for M, Vec
import "./events" for CollisionEvent, MoveEvent

class MoveAction is Action {
  construct new(dir, speed) {
    super()
    _dir = dir
    _speed = speed
  }

  handleCollision(pos) {
    var solid = ctx.map[pos]["solid"]
    var occupying = ctx.getEntitiesAtTile(pos.x, pos.y).where {|entity| entity != source }
    var solidEntity = false
    for (entity in occupying) {
      var event = entity.notify(ctx, CollisionEvent.new(this, entity, pos))
      if (!event.cancelled) {
        ctx.events.add(event)
        solidEntity = true
      }
    }
    return solid || solidEntity
  }

  perform() {
    var old = source.pos * 1
    source.pos.x = source.pos.x + source.vel.x
    source.pos.y = source.pos.y + source.vel.y

    if (source.pos != old && handleCollision(source.pos)) {
      source.pos = old
    }

    if (source.pos != old) {
      ctx.events.add(MoveEvent.new(source))
    }

    if (source.vel.length > 0) {
      source.vel = Vec.new()
    }
    return ActionResult.success
  }
}
