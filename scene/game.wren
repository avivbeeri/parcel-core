import "graphics" for ImageData, Canvas, Color, Font
import "input" for Keyboard, Mouse
import "math" for Vec, M

import "./palette" for EDG32, EDG32A

import "./core/display" for Display
import "./core/scene" for Scene, Ui
import "./core/event" for EntityRemovedEvent, EntityAddedEvent

import "./keys" for InputGroup, InputActions
import "./system/combat" for AttackResult
import "./events" for CollisionEvent, MoveEvent, GameEndEvent, AttackEvent, LogEvent, ModifierEvent, PickupEvent
import "./actions" for MoveAction, RestAction
import "./entity/all" for Player, Dummy, Collectible, Creature

import "./sprites" for StandardSpriteSet as Sprites
import "./system/log" for Log

import "./widgets" for Button
import "./scene/autotile" for AutoTile

// Timer variables
var T = 0
var F = 0

var DEBUG = false


var SCALE = 1
var TILE_SIZE = 16 * SCALE
var CARD_UI_TOP = 224
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

class WorldScene is Scene {
  construct new(args) {
    // Args are currently unused.
    _log = Log.new()

    _camera = Vec.new()
    _moving = false
    _tried = false
    _ui = []
    _diageticUi = []

    _world = args[0]
    var player = _world.active.getEntityByTag("player")

    _camera.x = player.pos.x * TILE_SIZE
    _camera.y = player.pos.y * TILE_SIZE
    _lastPosition = player.pos
    _selected = null

    _selectedEntityId = null

    _allowInput = true

    _entityViews = {}
    _world.active.entities.each {|entity| _entityViews[entity.id] = EntityView.new(_world.active, this, entity.id) }
  }


  world { _world }
  camera { _camera }
  camera=(v) { _camera = v }
  update() {
    if (Keyboard["l"].justPressed) {
      _log.toggle()
    }
    _zone = _world.active
    T = T + (1/60)
    F = (T * 2).floor % 2

    for (view in _entityViews.values) {
      view.update()
    }


    var player = _zone.getEntityByTag("player")
    if (player) {
      _lastPosition = player.pos
      _allowInput = (_world.strategy.currentActor is Player) && _world.strategy.currentActor.priority >= 12
      var playerView = _entityViews[player.id]
      _camera.x = playerView.pos.x
      _camera.y = playerView.pos.y
    }

    _selected = _allowInput && _log.hidden ? _selected : null

    if (updateAllUi()) {
      _allowInput = false
      return
    }

    _moving = false

    var pressed = false

    if (player && _allowInput) {
      if (InputActions.nextTarget.justPressed) {
        _diageticUi.add(CombatTargetSelector.new(_zone, this))
        return
      }


      var mouse = Mouse.pos
      var mouseEntities = _zone.getEntitiesAtTile(screenToWorld(mouse))
      if (mouseEntities.count > 0) {
        _selectedEntityId = mouseEntities.toList[0].id
      } else {
        _selectedEntityId = null
      }

      // Allow movement
      if (!player.action && !_tried) {
        if (InputActions.rest.firing) {
          player.action = RestAction.new()
        } else {
          var move = Vec.new()
          if (InputActions.left.firing) {
            move.x = -1
          } else if (InputActions.right.firing) {
            move.x = 1
          } else if (InputActions.up.firing) {
            move.y = -1
          } else if (InputActions.down.firing) {
            move.y = 1
          }
          if (move.length > 0) {
            player.action = MoveAction.new(move)
          }
        }
      }
    }
    pressed = InputActions.directions.any {|key| key.down }

    _world.update()
    var lastEntityLerp = null
    for (event in _zone.events) {
      if (event is MoveEvent) {
        if (event.target is Player) {
          _moving = true
          _lastPosition = player.pos
        }
        if (isOnScreen(event.target.pos)) {
          if (!lastEntityLerp) {
            lastEntityLerp = EntityBulkLerp.new(this, [])
            _diageticUi.add(lastEntityLerp)
          }
          lastEntityLerp.add(_entityViews[event.target.id])
        } else {
          _entityViews[event.target.id].pos.x = event.target.pos.x * TILE_SIZE
          _entityViews[event.target.id].pos.y = event.target.pos.y * TILE_SIZE
        }
      } else {
        lastEntityLerp = null
        if (event is EntityAddedEvent) {
          _diageticUi.add(EntityAdd.new(this, event.id))
        } else if (event is EntityRemovedEvent) {
          _diageticUi.add(EntityRemove.new(this, event.id))
          System.print("Entity %(event.id) was removed")
          if (event.id == player.id) {
            _diageticUi.add(Pause.new(this, 60))
          }
        } else if (event is GameEndEvent) {
          var result = event.won ? "won" : "lost"
          System.print("The game has ended. You have %(result).")
          if (event.won) {
            _ui.add(SuccessMessage.new(this))
          } else {
            // TOOD: Add more context about cause of failure
            _ui.add(FailureMessage.new(this))
          }
        } else if (event is ModifierEvent) {
          if (isOnScreen(event.target.pos)) {
            _diageticUi.add(Animation.new(this, event.target.pos * TILE_SIZE, event.positive ? Sprites["buff"] : Sprites["debuff"], 5))
          }

        } else if (event is PickupEvent) {
          if (event.source is Player) {
            _tried = true
            _moving = false
          }
        } else if (event is AttackEvent) {
          var playerIsTarget = event.target is Player
          if (isOnScreen(event.target.pos)) {
            var animation = "%(event.attack.attackType)Attack"
            var animate = event.target
            var linger = 0
            if (event.result == AttackResult.blocked) {
              animation = "blocked"
              linger = playerIsTarget ? 30 : linger
            } else if (event.result == AttackResult.inert) {
              animation = "inert"
              animate = event.source
              linger = playerIsTarget ? 30 : linger
            }
            _diageticUi.add(Animation.new(this, animate.pos * TILE_SIZE, Sprites[animation] || Sprites["basicAttack"], 5, linger))
            if (playerIsTarget) {
              // _diageticUi.add(Pause.new(this, 15))
            }
            if (event.source is Player) {
              _tried = true
              _moving = false
            }
          }
        } else if (event is LogEvent) {
          _log.print(event.text)
        } else if (event is CollisionEvent) {
          if (isOnScreen(event.source.pos)) {
            if (event.source is Player) {
              _tried = true
              _moving = false
            }
          }
        }
      }
    }
    if (!pressed) {
      _tried = false
    }
  }

  updateAllUi() {
    var uiList
    if (!_diageticUi.isEmpty) {
      uiList = _diageticUi
    } else if (!_ui.isEmpty) {
      uiList = _ui
    }
    if (uiList) {
      uiList[0].update()
      if (uiList[0].finished) {
        uiList.removeAt(0)
      }
      return true
    }
    return false
  }

  addEntityView(id) {
    System.print("Entity %(id) was added")
    _entityViews[id] = EntityView.new(_zone, this, id)
  }

  removeEntityView(id) {
    _entityViews.remove(id)
    System.print("removing %(id) from view")
  }

  draw() {
    _zone = _world.active
    var player = _zone.getEntityByTag("player")
    Canvas.cls(Display.bg)


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

    if (player) {
      // Draw the top bar (player stats, menu button, tabs?)
      Canvas.rectfill(0, 0, Canvas.width, 20, EDG32[28])
      var hp = player["stats"].get("hp")
      var hpMax = player["stats"].get("hpMax")
      Canvas.line(0, 20, Canvas.width, 20, EDG32[29], 2)
      var atk = player["stats"].get("atk")
      var def = player["stats"].get("def")
      var spi = player["stats"].get("spi")
      var text = "HP: %(hp)/%(hpMax)   ATK: %(atk)   DEF: %(def)   SPI: %(spi)"
      Canvas.print(text, 8, 2, EDG32[19], "m5x7")

      drawEntityMods(player, Vec.new(Canvas.width - 8 - TILE_SIZE, 2), Vec.new(Canvas.width - 8 - 3 * TILE_SIZE, 2), true)
    }

    if (_selectedEntityId) {
      var selectedEntity = _zone.getEntityById(_selectedEntityId)
      if (selectedEntity && selectedEntity.has("stats")) {
        drawEntityStats(selectedEntity)
      }
    }


    for (ui in _diageticUi) {
      var block = ui.draw()
      if (block) {
        break
      }
    }

    // TODO: Enforce priority for UI effects better
    _log.draw(4, CARD_UI_TOP + 2)

    if (_diageticUi.isEmpty) {
      for (ui in _ui) {
        var block = ui.draw()
        if (block) {
          break
        }
      }
    }
  }

  center {
    var cx = (Canvas.width - X_OFFSET - 20) / 2
    var cy = (Canvas.height - CARD_UI_TOP) / 2 + TILE_SIZE * 4
    return Vec.new(cx, cy)
  }

  screenToWorld(pos) {
    var tile =  (pos - (center - _camera)) / TILE_SIZE
    tile.x = tile.x.floor
    tile.y = tile.y.floor
    return tile
  }

  worldToScreen(pos) {
    return (pos * TILE_SIZE) + (center - _camera)
  }

  isOnScreen(worldPos) {
    var screenPos = worldToScreen(worldPos)
    return (screenPos.x >= 0 && screenPos.x < Canvas.width && screenPos.y >= 21 && screenPos.y < CARD_UI_TOP)
  }

  drawEntityMods(entity, iconPos, descriptionPos, rightAlign) {
    var mouse = Mouse.pos
    var x = iconPos.x
    var y = iconPos.y
    var iconX = rightAlign ? Canvas.width - 8 - TILE_SIZE : x
    var mod
    for (id in entity["stats"].modifiers.keys) {
      if (id == "shadow") {
        Sprites["icons"][2].draw(iconX, y)
      } else if (id == "sword") {
        Sprites["icons"][0].draw(iconX, y)
      } else if (id == "shield") {
        Sprites["icons"][1].draw(iconX, y)
      }
      var hover = mouse.x >= iconX && mouse.x < iconX + TILE_SIZE && mouse.y >= y && mouse.y < y + TILE_SIZE
      mod = hover ? id : mod
      iconX =  iconX + (rightAlign ? -1 : 1) * TILE_SIZE
    }
    if (mod) {
      var condition = entity["stats"].getModifier(mod)
      var text = "%(condition.id) (%(condition.duration) turns)"
      var conditionArea = Font["m5x7"].getArea(text)
      Canvas.print(text, rightAlign ? descriptionPos.x - conditionArea.x : descriptionPos.x, descriptionPos.y, EDG32[19], "m5x7")
    }
  }

  drawEntityStats(selectedEntity) {
    var text = "%(selectedEntity.name)"
    if (selectedEntity.has("stats")) {
      var stats = selectedEntity["stats"]
      var hp = stats.get("hp")
      var hpMax = stats.get("hpMax")
      var atk = stats.get("atk")
      var def = stats.get("def")
      text = "%(selectedEntity.name)\nHP: %(hp)/%(hpMax)\nATK: %(atk)\nDEF: %(def)"
      if (stats.base("spi") > 0) {
        var spi = stats.get("spi")
        text = "%(text)\nSPI: %(spi)"
      }
    }
    var area = Font["m5x7"].getArea(text)

    var width = M.max(area.x, TILE_SIZE * 3)
    var left = 8
    var top = 21

    Canvas.rectfill(left, top, width + 8, area.y + 8 + TILE_SIZE, EDG32[21])
    Canvas.print(text, left + 4, top + 4, EDG32[27], "m5x7")
    drawEntityMods(selectedEntity, Vec.new(left + 4, top + area.y + 8), Vec.new(left + 4, top + area.y + 8 + TILE_SIZE), false)
  }
}

// These need to be down here for safety
// from circular dependancies
import "./effects" for
  CameraLerp,
  EntityBulkLerp,
  EntityRemove,
  EntityAdd,
  Animation
import "./menu" for CombatTargetSelector,
  SuccessMessage,
  FailureMessage,
  Pause
