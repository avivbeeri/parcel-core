import "./core/action" for Action
import "./actions" for ApplyModifierAction, AttackAction, SpawnAction
import "./system/stats" for Modifier
import "./core/config" for Config


import "./system/combat" for Attack, AttackType

class CardActionFactory {
  static prepare(card, source, target) {
    var actionClass
    if (!card.action) {
      return Action.none
    }

    if (card.action == "applyModifier") {
      var id = card.params["id"]
      var add = card.params["add"]
      var mult = card.params["mult"]
      var responsible = card.params["responsible"]
      var duration = card.params["duration"]
      var positive = card.params["positive"]
      var modifier = Modifier.new(id, add, mult, duration, positive)
      return ApplyModifierAction.new(modifier, target, !responsible || responsible == "source")
    } else if (card.action == "attack") {
      var kind = card.params["kind"] || AttackType.melee
      var base = card.params["base"] || source["stats"].get("spi") || 1
      var mana = card.params["needsMana"] || false
      return AttackAction.new(target.pos, Attack.new(base, kind, mana))
    } else if (card.action == "spawn") {
      var id = card.params["id"]
      var entityConfig
      for (config in Config["entities"]) {
        if (config["id"] == id) {
          entityConfig = config
          break
        }
      }
      var fireball = EntityFactory.prepare(entityConfig)
      fireball["source"] = source.pos * 1
      for (id in card.params["stats"].keys) {
        System.print(id)
        fireball["stats"].set(id, card.params["stats"][id])
      }
      return SpawnAction.new(fireball, target.pos * 1)
    } else {
      Fiber.abort("Could not prepare unknown action %(card.action)")
    }
  }

}

class EntityFactory {
  static prepare(config) {
    var classType = config["classType"]
    if (classType == "sword") {
      return Sword.new(config)
    }
    if (classType == "shield") {
      return Shield.new(config)
    }
    if (classType == "thunder") {
      return Thunder.new(config)
    }
    if (classType == "wizard") {
      return Wizard.new(config)
    }
    if (classType == "fireball") {
      return Fireball.new(config)
    }
    if (classType == "shadow") {
      return Shadow.new(config)
    }
    if (classType == "creature") {
      return Creature.new(config)
    }
    if (classType == "seeker") {
      return Seeker.new(config)
    }
    Fiber.abort("Unknown entity type %(classType)")
  }
}

import "./entity/all" for Sword,
  Shield,
  Creature,
  Thunder,
  Fireball,
  Wizard,
  Seeker,
  Shadow
