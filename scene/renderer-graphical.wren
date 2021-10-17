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

class Renderer {}
class GraphicalRenderer is Renderer {
  construct new(scene, player) {
    _scene = scene
    _camera = Vec.new()
    _camera.x = player.pos.x * TILE_SIZE
    _camera.y = player.pos.y * TILE_SIZE
    _diageticUi = []
    _entityViews = {}
    _isAnimationPlaying = false
  }

  animationPlaying { !_diageticUi.isEmpty }

  update() {
    T = T + (1/60)
    F = (T * 2).floor % 2
    _zone = _world.active

    // Update views
    for (view in _entityViews.values) {
      view.update()
    }

    // Set camera
    var player = _zone.getEntityByTag("player")
    if (player) {
      _lastPosition = player.pos
      _allowInput = (_world.strategy.currentActor is Player) && _world.strategy.currentActor.priority >= 12
      var playerView = _entityViews[player.id]
      _camera.x = playerView.pos.x
      _camera.y = playerView.pos.y
    }

    // Process UI Effects
    if (!_diageticUi.isEmpty) {
      _diageticUi[0].update()
      if (_diageticUi[0].finished) {
        _diageticUi.removeAt(0)
      }
      return
    }
  }

  addEffect(ui) {
    _diageticUi.add(ui)
  }

  processEvents(events) {
  }

  draw() {
    var player = _zone.getEntityByTag("player")
    var cx = center.x
    var cy = center.y

    Canvas.offset((cx-_camera.x -X_OFFSET).floor, (cy-_camera.y).floor)

    var xRange = M.max((cx / TILE_SIZE), (Canvas.width - cx) / TILE_SIZE).ceil + 1
    var yRange = M.max((cy / TILE_SIZE), (Canvas.height - cy) / TILE_SIZE).ceil + 1
    for (dy in -yRange..yRange) {
      for (dx in -xRange..xRange) {
        var x = _lastPosition.x + dx
        var y = _lastPosition.y + dy
        var sx = x * TILE_SIZE + X_OFFSET
        var sy = y * TILE_SIZE
        var tile = _zone.map[x, y]

        var index = tile["index"] = (tile["dirty"] != false) ? AutoTile.pick(_zone.map, x, y) : tile["index"]
        tile["dirty"] = false
        if (index >= 0) {

          var list = Sprites["wall"]
          list[index].draw(sx, sy)

          if (DEBUG && Keyboard["left ctrl"].down) {
            // TODO: disable before release
            if (tile["solid"]) {
              Canvas.rectfill(sx, sy, TILE_SIZE, TILE_SIZE, EDG32A[25])
            } else {
              Canvas.rectfill(sx, sy, TILE_SIZE, TILE_SIZE, EDG32A[12])
            }
            Canvas.print(index, sx, sy, EDG32[24])
          }
        }
      }
    }

    for (view in _entityViews.values) {
      view.draw()
    }


    for (ui in _diageticUi) {
      var block = ui.drawDiagetic()
      if (block) {
        break
      }
    }

    Canvas.offset()

    for (ui in _diageticUi) {
      var block = ui.draw()
      if (block) {
        break
      }
    }

  }

}

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
