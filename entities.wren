import "math" for Vec
import "./core/entity" for Entity
import "./events" for CollisionEvent, MoveEvent

class Player is Entity {
  construct new() {
    super()
  }

  handleCollision(ctx, pos) {
    var solid = ctx.map[pos]["solid"]
    var occupying = ctx.getEntitiesAtTile(pos.x, pos.y).where {|entity| !(entity is Player) }
    var solidEntity = false
    for (entity in occupying) {
      var event = entity.notify(ctx, CollisionEvent.new(this, entity, pos))
      System.print(event)
      if (!event.cancelled) {
        ctx.events.add(event)
        solidEntity = true
      }
    }
    return solid || solidEntity
  }

  update(ctx) {
    var old = pos * 1
    move()

    if (pos != old && handleCollision(ctx, pos)) {
      pos = old
    }

    if (pos != old) {
      ctx.events.add(MoveEvent.new(this))
    }

    if (vel.length > 0) {
      vel = Vec.new()
    }
  }
}

