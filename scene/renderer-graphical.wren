import "input" for Keyboard, Mouse
import "graphics" for ImageData, Canvas, Color, Font
import "math" for Vec, M
import "core/scene" for Ui
import "./palette" for EDG32, EDG32A
import "./sprites" for StandardSpriteSet as Sprites
import "./scene/autotile" for AutoTile

var DEBUG = false
// Timer variables
var T = 0
var F = 0

var SCALE = 1
var TILE_SIZE = 16 * SCALE
var X_OFFSET = 0

class EntityView is Ui {
  construct new(ctx, view, entityId) {
    _ctx = ctx
    _view = view
    _alive = true

    _id = entityId
    var entity = ctx.getEntityById(entityId)
    _spriteType = entity["sprite"]
    _position = entity.pos * TILE_SIZE
    _goal = _position
    _moving = false

    _handlers = {}
  }

  id { _id }

  pos { _position }
  goal { _goal }

  alive { _alive }
  alive=(v) { _alive = v }
  removable { !_alive && !_moving }

  update() {
    _lastEntity = _entity || _lastEntity
    _entity = _ctx.getEntityById(_id)
    _goal = (_entity || _lastEntity).pos * TILE_SIZE
    if (_entity) {
      // _position.x = _entity.pos.x * TILE_SIZE
      // _position.y = _entity.pos.y * TILE_SIZE
      _moving = _position.x != _entity.pos.x * TILE_SIZE || _position.y != _entity.pos.y * TILE_SIZE
    }
  }

  draw() {
    if (!_entity) {
      _entity = _lastEntity
    }

    if (!_entity || !_view.isOnScreen(_entity.pos)) {
      return
    }

    var sx = _position.x + X_OFFSET
    var sy = _position.y
    if (DEBUG && Keyboard["left ctrl"].down) {
      var r = TILE_SIZE / 2
      Canvas.circlefill(sx + r, sy +r, r, EDG32A[10])
    }

    if (_entity is Player) {
      // We draw this
      if (_moving) {
        var s = (T * 5).floor % 2
        Sprites["playerWalk"][s].draw(sx, sy)
      } else {
        Sprites["playerStand"][F].draw(sx, sy)
      }
    } else if (_entity is Collectible) {
      Sprites["card"][0].draw(sx, sy - F * 2)
    } else if (_entity is Creature && _spriteType) {
      Sprites[_spriteType][F].draw(sx, sy)
    } else {
      Canvas.print(_entity.type.name[0], sx, sy, Color.red)
    }
  }
}

import "./entity/all" for Player, Collectible, Creature
