import "math" for M, Vec
import "./core/action" for Action, ActionResult
import "./events" for CollisionEvent,
  CommuneEvent,
  MoveEvent,
  AttackEvent,
  PickupEvent,
  ModifierEvent,
  LogEvent

import "./system/combat" for Attack, AttackResult

class CommuneAction is Action {
  construct new() {
    super()
  }

  perform() {
    /*
    if (source.has("stats") &&
        source["stats"].has("mana")) {

      if (source["stats"].get("mana") < source["stats"].get("manaMax")) {
        // TODO: Assert?!
        ctx.events.add(CommuneEvent.new(source, false))
        return ActionResult.failure
      }
      source["stats"].set("mana", -1)
    }
    */
    var discard = source["discard"]
    var deck = source["deck"]
    var success = (deck.count == 0 && source["hand"].count == 0)
    if (success) {

      deck.addToBottom(discard)
      deck.shuffle()
      source["discard"] = []

      source["hand"] = deck.drawCards(3)
    }
    ctx.events.add(CommuneEvent.new(source, success))

    return ActionResult.success
  }
}

class RestAction is Action {
  construct new() {
    super()
  }
}

class MoveAction is Action {
  construct new(dir, alwaysSucceed, alt) {
    super()
    _dir = dir
    _succeed = alwaysSucceed
    _alt = alt
  }
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

  getOccupying(pos) {
    return ctx.getEntitiesAtTile(pos.x, pos.y).where {|entity| entity != source }
  }

  perform() {
    var old = source.pos * 1
    source.vel = _dir
    source.pos.x = source.pos.x + source.vel.x
    source.pos.y = source.pos.y + source.vel.y

    var result

    if (source.pos != old) {
      var solid = ctx.isSolidAt(source.pos)
      var target = false
      var collectible = false
      if (!solid) {
        var occupying = getOccupying(source.pos)
        if (occupying.count > 0) {
          solid = solid || occupying.any {|entity| entity.has("solid") }
          target = occupying.any {|entity| entity.has("stats") }
          collectible = occupying.any {|entity| entity is Collectible }
        }
      }
      if (solid || target || collectible) {
        source.pos = old
        if (_alt) {
          result = ActionResult.alternate(_alt)
        }
      }
      if (!_alt && target) {
        if (source.has("stats") && source["stats"].base("atk") > 0) {
          result = ActionResult.alternate(AttackAction.new(source.pos + _dir, Attack.melee(source)))
        }
      } else if (!_alt && collectible) {
        result = ActionResult.alternate(PickupAction.new(_dir))
      }
    }

    if (!result) {
      if (source.pos != old) {
        ctx.events.add(MoveEvent.new(source))
        result = ActionResult.success
      } else if (_succeed) {
        result = ActionResult.alternate(Action.none)
      } else {
        result = ActionResult.failure
      }
    }

    if (source.vel.length > 0) {
      source.vel = Vec.new()
    }
    return result
  }
}

class AttackAction is Action {
  construct new(location, attack) {
    super()
    _location = location
    _attack = attack
  }

  location { _location }

  perform() {
    /*
    ----- MANA DISABLE --------
    if (_attack.needsMana &&
      source.has("stats") &&
      source["stats"].has("mana")) {

      if (source["stats"].get("mana") <= 0) {
        // TODO: Assert?!
        return ActionResult.failure
      }
      source["stats"].decrease("mana", 1)
    }
    */


    var location = _location
    var occupying = ctx.getEntitiesAtTile(location.x, location.y).where {|entity| entity.has("stats") }

    if (occupying.count == 0) {
      return ActionResult.failure
    }
    occupying.each {|target|
      var currentHP = target["stats"].base("hp")
      var defence = target["stats"].get("def")
      var damage = M.max(0, _attack.damage - defence)

      var attackResult = AttackResult.success
      if (_attack.damage <= 0) {
        attackResult = AttackResult.inert
      } else if (damage == 0) {
        attackResult = AttackResult.blocked
      }

      var attackEvent = AttackEvent.new(source, target, _attack, attackResult)
      attackEvent = target.notify(attackEvent)

      if (!attackEvent.cancelled) {
        ctx.events.add(LogEvent.new("%(source) attacked %(target)"))
        ctx.events.add(attackEvent)
        target["stats"].decrease("hp", damage)
        ctx.events.add(LogEvent.new("%(source) did %(damage) damage."))
        if (target["stats"].get("hp") <= 0) {
          ctx.events.add(LogEvent.new("%(target) was defeated."))
        }
      }
    }
    return ActionResult.success
  }

}

class PickupAction is Action {
  construct new(dir) {
    super()
    _dir = dir
  }
  perform() {
    var target = source.pos + _dir
    var occupying = ctx.getEntitiesAtTile(target.x, target.y).where {|entity| entity != source }
    var collectibles = occupying
    .where{|entity| entity is Collectible }


    collectibles.each {|entity|
      var item = entity.item.split(":")
      var kind = item[0]
      var id = item[1]

      var event = source.notify(PickupEvent.new(source, Card[id]))
      ctx.events.add(event)

      if (kind == "card") {
        if (source.has("deck")) {
          source["deck"].addToBottom(Card[id])
        }
      } else if (source.has("inventory")) {
        source["inventory"].add(entity.item)
      }
      ctx.removeEntity(entity)
    }

    return ActionResult.success
  }

}

class PlayCardAction is Action {
  construct new(handIndex) {
    super()
    _handIndex = handIndex
    _target = null
  }

  construct new(handIndex, target) {
    super()
    _handIndex = handIndex
    _target = target
  }

  perform() {
    /*
    if (!source.has("hand") || source.has("stats") && source["stats"].get("mana") <= 0) {
      // TODO: Assert?!
      return ActionResult.failure
    }
    */

    var hand = source["hand"]
    var selectedCard = hand.removeAt(_handIndex)
    var result = ActionResult.failure
    if (selectedCard) {
      if (!_target) {
        // Auto-select target
        // based on card data
        if (selectedCard.target == "self") {
          _target = source
        }
      }

      var cardAction = (CardActionFactory.prepare(selectedCard, source, _target))
      result = cardAction.bind(source).perform()
      // result = ActionResult.alternate(CardActionFactory.prepare(selectedCard, _target))
      if (result.succeeded) {
        ctx.events.add(LogEvent.new("%(source) played the '%(selectedCard.name)' card"))
        var discard = source["discard"]
        discard.add(selectedCard)
        source["stats"].decrease("mana", 2)
      }
    }

    if (!result.succeeded) {
      hand.insert(_handIndex, selectedCard)
    }

    return result
  }
}

class ApplyModifierAction is Action {
  construct new(modifier) {
    super()
    _modifier = modifier
    _target = source
    _responsible = true
  }

  construct new(modifier, target, responsible) {
    super()
    _modifier = modifier
    _target = target
    _responsible = responsible
  }

  perform() {
    if (_target.has("stats")) {
      ctx.events.add(ModifierEvent.new(_target, _modifier.positive))
      if (_modifier.positive) {
        ctx.events.add(LogEvent.new("%(_target) gained %(_modifier.id)!"))
      } else {
        ctx.events.add(LogEvent.new("%(source) inflicted %(_modifier.id) on %(_target)"))
      }

      if (_target["stats"].hasModifier(_modifier.id)) {
        var currentMod = _target["stats"].getModifier(_modifier.id)
        if (_modifier.duration) {
          currentMod.extend(_modifier.duration)
        }
      } else {

        _target["stats"].addModifier(_modifier)
        var host = _responsible ? source : _target
        host["activeEffects"].add([ _modifier, _target.id ])
        if (host == source) {
          _modifier.extend(1)
        }
      }
      return ActionResult.success
    }
    return ActionResult.failure
  }
}

class DespawnAction is Action {
  construct new() {
    super()
    _targetId = null
  }

  perform() {
    var target = _targetId ? ctx.getEntityById(_targetId) : source
    ctx.removeEntity(target)
    return ActionResult.success
  }
}

class SpawnAction is Action {
  construct new(entity, position) {
    super()
    _entity = entity
    _position = position
  }

  getOccupying(pos) {
    return ctx.getEntitiesAtTile(pos.x, pos.y).where {|entity| entity != source }
  }

  perform() {
    var solid = ctx.isSolidAt(source.pos)
    var target = false
    if (solid) {
      return ActionResult.failure
    }
    var hitLocation = getOccupying(_position).count > 0
    if (hitLocation) {
      // There's an entity in our spawn tile.
      // We might want to do something about that.
    }

    var entity = ctx.addEntity(_entity)
    entity.pos = _position

    return ActionResult.success
  }
}

// -------- UNTESTED PROTOTYPE ------
// Assumes that partial failures are acceptible.

class MultiAction is Action {
  construct new(actionList, force) {
    super()
    _actionList = actionList
    _force = force
  }

  perform() {
    var result = ActionResult.success
    var failed = false
    for (step in _actionList) {
      while (step) {
        step.bind(source)
        var stepResult = step.perform()
        if (!_force && !stepResult.succeeded) {
          result = ActionResult.failure
          failed = true
          break
        }
        if (!stepResult.alternate) {
          break
        }
        step = result.alternate
      }
      if (failed) {
        break
      }
    }
    return result
  }
}


import "./entity/collectible" for Collectible
import "./factory" for CardActionFactory
import "./deck" for Card
