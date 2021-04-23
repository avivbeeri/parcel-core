import "core/entity" for Entity
import "core/dataobject" for DataObject
import "core/graph" for WeightedZone, BFS, AStar, DijkstraMap
import "./stats" for StatGroup
import "./deck" for Deck, Card
import "./entity/creature" for Creature
import "./rng" for RNG

class Player is Creature {
  construct new() {
    super()
    _action = null
    priority = 12
    this["stats"].set("hpMax", 2)
    this["stats"].set("hp", 2)
    this["stats"].set("spi", 1)
    this["stats"].set("mana", 1)
    this["stats"].set("manaMax", 5)

    this["discard"] = []
    this["deck"] = Deck.new(RNG.sample(Card.all, 3)).shuffle()
    this["hand"] = this["deck"].drawCards(3)
  }

  action { _action }
  action=(v) {
    _action = v
  }

  update() {
    var action = _action
    _action = null
    return action
  }

  endTurn() {
    super.endTurn()
    this["stats"].increase("mana", 1, "manaMax")
    var graph = WeightedZone.new(ctx)
    this["dijkstra"] = DijkstraMap.search(graph, pos)
  }
}

import "./events" for LogEvent
