import "parcel" for Action, ActionResult, Event
import "math" for M

class AttackEvent is Event {
  construct new() { super() }
}

class Damage {
  static calculate(atk, def) {
    var o1 = atk * 2 - def
    var o2 = (atk * atk) / def
    if (atk > def) {
      return o1.floor
    }
    if (!o2.isNan) {
      return o2.floor
    }
    return 0
  }
}

class AttackResult {
  static success { "success" }
  static blocked { "blocked" }
  static inert { "inert" }
}

class AttackType {
  static melee { "basic" }

  static verify(text) {
    if (text == "basic") {
      return text
    }
    Fiber.abort("unknown AttackType: %(text)")
  }
}

class Attack {
  construct new(damage, attackType) {
    _damage = damage
    _attackType = AttackType.verify(attackType)
  }

  damage { _damage }
  attackType { _attackType }

  static melee(entity) {
    return Attack.new(entity["stats"].get("atk"), AttackType.melee)
  }
}

class StatGroup {
  construct new(statMap) {
    _base = statMap
    _mods = {}
  }

  modifiers { _mods }

  addModifier(mod) {
    _mods[mod.id] = mod
  }
  hasModifier(id) {
    return _mods.containsKey(id)
  }
  getModifier(id) {
    return _mods[id]
  }
  removeModifier(id) {
    _mods.remove(id)
  }

  base(stat) { _base[stat] }
  set(stat, value) { _base[stat] = value }
  decrease(stat, by) { _base[stat] = _base[stat] - by }
  increase(stat, by) { _base[stat] = _base[stat] + by }
  increase(stat, by, maxStat) { _base[stat] = M.mid(0, _base[stat] + by, _base[maxStat]) }

  has(stat) { _base[stat] }
  [stat] { get(stat) }
  get(stat) {
    var value = _base[stat]
    if (value == null) {
      Fiber.abort("Stat %(stat) does not exist")
    }
    var multiplier = 0
    var total = value || 0
    for (mod in _mods.values) {
      total = total + (mod.add[stat] || 0)
      multiplier = multiplier + (mod.mult[stat] || 0)
    }
    return M.max(0, total + total * multiplier)
  }

  print(stat) {
    return "%(stat)>%(base(stat)):%(get(stat))"
  }

  tick() {
    for (modifier in _mods.values) {
      if (modifier.done) {
        removeModifier(modifier.id)
      }
    }
  }
}

/**
  Represent arbitrary modifiers to multiple stats at once
  Modifiers can be additive or multiplicative.
  Multipliers are a "percentage change", so +0.5 adds 50% of base to the value.
*/
class Modifier {
  construct new(id, add, mult, duration, positive) {
    _id = id
    _add = add || {}
    _mult = mult || {}
    _duration = duration || null
    _positive = positive || false
  }

  id { _id }
  add { _add }
  mult { _mult }
  duration { _duration }
  positive { _positive }

  tick() {
    _duration = _duration ? _duration - 1 : null
  }
  done { _duration && _duration <= 0 }

  extend(n) {
    if (_duration != null) {
      _duration = (_duration  || 0) + n
    }
  }
}

class AttackAction is Action {
  construct new(attack, locations) {
    super()
    if (!(locations is Sequence)) {
      locations = [ locations ]
    }
    data["locations"] = locations
    data["attack"] = attack
  }

  locations { data["locations"] }
  attack { data["attack"] }

  evaluate() {
    // TODO: We should evaluate validity based on the attack being made
    return ActionResult.valid
  }

  perform() {
    var location = _location
    var targets = ctx.getEntitiesAtTile(location.x, location.y).where {|entity| entity.has("stats") }

    targets.each {|target|
      var currentHP = target["stats"].base("hp")
      var defence = target["stats"].get("def")
      var damage = Damage.calculate(_attack.strength - defence)

      var attackResult = AttackResult.success
      if (_attack.damage <= 0) {
        attackResult = AttackResult.inert
      } else if (damage == 0) {
        attackResult = AttackResult.blocked
      }

      var attackEvent = AttackEvent.new(source, target, _attack, attackResult)
      attackEvent = target.notify(attackEvent)

      if (!attackEvent.cancelled) {
        //ctx.events.add(LogEvent.new("%(source) attacked %(target)"))
        ctx.events.add(attackEvent)
        target["stats"].decrease("hp", damage)
        //ctx.events.add(LogEvent.new("%(source) did %(damage) damage."))
        if (target["stats"].get("hp") <= 0) {
          //ctx.events.add(LogEvent.new("%(target) was defeated."))
        }
      }
    }
    return ActionResult.success
  }
}
