import "graphics" for ImageData, Canvas, Color, Font
import "input" for Keyboard, Mouse
import "math" for Vec, M

import "./palette" for EDG32, EDG32A

import "./core/display" for Display
import "./core/scene" for Scene, Ui
import "./core/event" for EntityRemovedEvent, EntityAddedEvent

import "./keys" for InputGroup, InputActions
import "./menu" for Menu, CardTargetSelector, CombatTargetSelector
import "./combat" for AttackResult
import "./events" for CollisionEvent, MoveEvent, GameEndEvent, AttackEvent, LogEvent, CommuneEvent, ModifierEvent, PickupEvent
import "./actions" for MoveAction, RestAction, PlayCardAction, CommuneAction
import "./entity/all" for Player, Dummy, Collectible, Creature

import "./sprites" for StandardSpriteSet as Sprites
import "./log" for Log

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

    _reshuffleButton = Button.new("Commune", Vec.new(416, CARD_UI_TOP + 4), Vec.new(7 * 8 + 4, 16))
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
      if (InputActions.commune.justPressed || _reshuffleButton.update().clicked) {
        player.action = CommuneAction.new()
      }

      if (InputActions.nextTarget.justPressed) {
        _diageticUi.add(CombatTargetSelector.new(_zone, this))
        return
      }


      var mouse = Mouse.pos
      if (mouse.y < CARD_UI_TOP) {
        var mouseEntities = _zone.getEntitiesAtTile(screenToWorld(mouse))
        if (mouseEntities.count > 0) {
          _selectedEntityId = mouseEntities.toList[0].id
        } else {
          _selectedEntityId = null
        }
      }

      // Play a card
      var hand = player["hand"]
      var handLeft = 5 + 59
      var maxHandWidth = 416 - (handLeft)
      var slots = getHandSlots(hand, handLeft, CARD_UI_TOP + 12, maxHandWidth)
      var index = 0
      var hover = null
      for (slot in slots) {
        var card = slot[0]
        var pos = slot[1]
        if (mouse.y >= pos.y && mouse.x >= pos.x && mouse.x < pos.z) {
          hover = slot
          var shift = InputActions.shift.down

          if (Mouse["left"].justPressed && !shift) {
            playCard(slots, index)
          } else if (Mouse["right"].justPressed || (Mouse["left"].justPressed && shift)) {
            displayCardDescription(card.id)
          }
        }

        if ((index+1) < InputActions.options.count && InputActions.options[index+1].justPressed) {
          if (InputActions.shift.down) {
            displayCardDescription(card.id)
          } else {
            hover = playCard(slots, index)
          }
        }
        index = index + 1
      }
      _selected = _allowInput && _log.hidden ? hover : null


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
        } else if (event is CommuneEvent) {
          if (event.success) {
            System.print("You communed with the cards and their magic is restored.")
            _diageticUi.add(Animation.new(this, event.source.pos * TILE_SIZE, Sprites["commune"], 5))
          } else {
            System.print("You cannot commune right now.")
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

      // Draw the card shelf
      Canvas.rectfill(0, CARD_UI_TOP, Canvas.width, Canvas.height - CARD_UI_TOP, EDG32[28])
      Canvas.line(0, CARD_UI_TOP, Canvas.width, CARD_UI_TOP, EDG32[29], 2)

      var deck = player["deck"]
      var left = 5
      var top = CARD_UI_TOP + 4
      drawPile(deck, 5, top, false)
      drawPile(player["discard"], 416, top, true)

      var hand = player["hand"]
      var handLeft = 5 + 59
      var maxHandWidth = 416 - (handLeft)
      var slots = getHandSlots(hand, handLeft, top + 8, maxHandWidth)
      for (slot in slots) {
        var card = slot[0]
        var pos = slot[1]
        if (_selected && Object.same(_selected[0], card)) {
        } else {
         card.draw(pos.x, pos.y)
        }
      }

      if (deck.isEmpty && hand.isEmpty) {
        _reshuffleButton.draw()
      }

      if (_selected) {
        var card = _selected[0]
        var pos =  _selected[1]
        card.draw(pos.x, pos.y - 32)
        if (!_allowInput) {
          Canvas.rectfill(pos.x, pos.y - 32, 96, CARD_UI_TOP - (pos.y - 32), EDG32A[27])
        }
      }
      if (!_allowInput) {
        Canvas.rectfill(0, CARD_UI_TOP, Canvas.width, Canvas.height - CARD_UI_TOP, EDG32A[27])
      }
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

  drawPile(pile, left, top, shade) {
    var mouse = Mouse.pos
    var hover = null
    var width = 59
    var height = 89
    var border = 3
    Canvas.rect(left, top, width, height, EDG32[27])
    if (!pile.isEmpty) {
      var total = M.min(4, (pile.count / 3).ceil)
      for (offset in 1..total) {
        if (offset < total) {
        Sprites["cardback"]
        .transform({ "mode": "MONO", "foreground": EDG32[3 + total - offset], "background": Color.none })
        .draw(left + 7 - offset, top + 6 - offset)
        } else {
          Sprites["cardback"].draw(left + 7 - offset, top + 6 - offset)
        }
      }
    }
    if (shade) {
      Canvas.rectfill(left+1, top+1, width-2, height-2, EDG32A[27])
    }
    if (mouse.x >= left && mouse.x < left + width && mouse.y >= top && mouse.y < top + height) {
      var font = Font["m5x7"]
      var area = font.getArea(pile.count.toString)

      var textLeft = left + ((width - area.x) / 2)
      var textTop = top + ((height - area.y) / 2)
      Canvas.rectfill(textLeft - border, textTop - border, area.x + border * 2, area.y + border * 2, EDG32[21])
      font.print(pile.count.toString, textLeft + 1, textTop - 2, EDG32[23])
    }
  }

  getHandSlots(hand, handLeft, top, maxHandWidth) {
      var cardWidth = 96
      var spacingCount = M.max(0, hand.count - 1)
      var spacing = 6
      var handWidth = (hand.count * cardWidth) + spacingCount * spacing
      var handStep
      var adjust
      if (handWidth < maxHandWidth) {
        handStep = (handWidth / hand.count).floor
        adjust = (maxHandWidth - handWidth) / 2
      } else {
        maxHandWidth = maxHandWidth - cardWidth
        handStep = ((maxHandWidth) / (hand.count)).ceil
        spacing = 0
        adjust = handStep / 2
      }

      return (0...hand.count).map {|i|
        var x = handLeft + adjust + handStep * i + spacing / 2
        return [ hand[i], Vec.new(x, top, i < hand.count - 1 ? x + handStep : x + cardWidth, 160) ]
      }
  }


  displayCardDescription(cardId) {
    _ui.add(CardDialog.new(this, cardId))
  }

  playCard(slots, index) {
    var player = _world.active.getEntityByTag("player")
    slots = slots.toList
    var card = slots[index][0]
    if (!card.requiresInput) {
      player.action = PlayCardAction.new(index)
    } else {
      // get inputs
      _diageticUi.add(CardTargetSelector.new(_zone, this, card, index))
      return slots[index]
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
  SuccessMessage,
  FailureMessage,
  Animation,
  CardDialog,
  Pause
