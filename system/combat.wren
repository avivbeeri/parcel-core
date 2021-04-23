class AttackResult {
  static success { "success" }
  static blocked { "blocked" }
  static inert { "inert" }
}


class AttackType {
  static melee { "basic" }
  static lightning { "lightning" }
  static fire { "fire" }

  static verify(text) {
    if (text == "basic" ||
      text == "lightning" ||
      text == "fire") {
      return text
    }
    Fiber.abort("unknown AttackType: %(text)")
  }
}

class Attack {
  construct new(damage, attackType, needsMana) {
    _damage = damage
    _attackType = AttackType.verify(attackType)
    _needsMana = needsMana
  }

  damage { _damage }
  attackType { _attackType }
  needsMana { _needsMana }

  static melee(entity) {
    return Attack.new(entity["stats"].get("atk"), AttackType.melee, true)
  }
}
