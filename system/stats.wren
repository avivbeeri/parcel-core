import "math" for M

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

