import "math" for Vector
import "./core/elegant" for Elegant
import "./core/adt" for Queue, Heap
import "./core/dir" for Directions, NSEW

class Location {}

class Graph {
  neighbours(id) { [] }
}

class SimpleGraph is Graph {
  construct new() {
    _edges = {}
  }

  construct new(edges) {
    _edges = edges
  }

  neighbours(id) { _edges[id] }
}

class SquareGrid is Graph {
  construct new(map) {
    _map = map
  }

  neighbours(location) {
    if (location is Num) {
      location = Elegant.unpair(location)
    }
    var result = []
    for (dir in NSEW.values) {
      if (dir.x != 0 && dir.y != 0) {
        continue
      }

      var target = (location + dir)
      if (!_map[target]["solid"]) {
        result.add(Elegant.pair(target))
      }
    }
    return result
  }

  cost(a, b) { 1 }
}

class WeightedZone is SquareGrid {
  construct new(zone) {
    super(zone.map)
    _zone = zone
  }

  cost(a, b) {
    var pos = Elegant.unpair(b)
    var ok = _zone.getEntitiesAtTile(pos).count == 0
    return ok ? 1 : 10
  }
}


// Expects tuple [ priority, item ]
class PriorityQueue {

  construct new() {
    _comparator = Fn.new {|a, b| b[0] > a[0] }
    _list = []
  }
  isEmpty { _list.isEmpty }

  get() {
    return _list.removeAt(0)[1]
  }

  put(item, priority) {
    _list.add([priority, item])
    _list.sort(_comparator)
  }

}


class BFS {
  static search(graph, start) { search(graph, start, null) }
  static search(graph, start, goal) {
    var frontier = Queue.new()
    var cameFrom = {}
    if (start is Vector) {
      start = Elegant.pair(VecFloor.do(start))
    }
    frontier.enqueue(start)
    cameFrom[start] = null

    while (!frontier.isEmpty) {
      var current = frontier.dequeue()
      if (goal && current == goal) {
        break
      }
      for (next in graph.neighbours(current)) {
        if (!cameFrom[next]) {
          frontier.enqueue(next)
          cameFrom[next] = current
        }
      }
    }
    return [ cameFrom ]
  }
  static reconstruct(cameFrom, start, goal) {
    if (start is Vector) {
      start = Elegant.pair(VecFloor.do(start))
    }
    if (goal is Vector) {
      goal = Elegant.pair(VecFloor.do(goal))
    }
    var current = goal
    var path = []
    while (current != start) {
      path.insert(0, Elegant.unpair(current))
      current = cameFrom[current]
      if (current == null) {
        // Path is unreachable
        return null
      }
    }
    path.insert(0, Elegant.unpair(start))
    return path
  }
}

class VecFloor {
  static do(vec) {
    return Vector.new(vec.x.round, vec.y.round)
  }
}


class DijkstraSearch {

  static search(graph, start) {
    return search(graph, start, null)
  }
  static search(graph, start, goal) {
    if (start is Vector) {
      start = Elegant.pair(VecFloor.do(start))
    }
    var frontier = PriorityQueue.new()
    frontier.put(start, 0)
    var cameFrom = {}
    var costSoFar = {}
    cameFrom[start] = null
    costSoFar[start] = 0

    while (!frontier.isEmpty) {
      var current = frontier.get()
      if (goal && current == goal) {
        break
      }
      for (next in graph.neighbours(current)) {
        var newCost = costSoFar[current] + graph.cost(current, next)
        if (costSoFar[next] == null) {
          costSoFar[next] = newCost
          frontier.put(next, newCost)
          cameFrom[next] = current
        }
        if (newCost < costSoFar[next]) {
          costSoFar[next] = newCost
          cameFrom[next] = current
          frontier.put(next, newCost)
        }
      }
    }
    return [cameFrom, costSoFar]
  }

  static reconstruct(cameFrom, start, goal) {
    if (start is Vector) {
      start = Elegant.pair(VecFloor.do(start))
    }
    if (goal is Vector) {
      goal = Elegant.pair(VecFloor.do(goal))
    }
    var current = goal
    var path = []
    while (current != start) {
      path.insert(0, Elegant.unpair(current))
      current = cameFrom[current]
      if (current == null) {
        // Path is unreachable
        return null
      }
    }
    path.insert(0, Elegant.unpair(start))
    return path
  }
}

class AStar {
  static heuristic(a, b) {
    var v1 = a
    var v2 = b
    if (a is Num) {
      v1 = Elegant.unpair(a)
    }
    if (b is Num) {
      v2 = Elegant.unpair(b)
    }
    return (v1 - v2).manhattan
  }

  static search(graph, start, goal) {
    if (start is Vector) {
      start = Elegant.pair(VecFloor.do(start))
    }
    var frontier = PriorityQueue.new()
    frontier.put(start, 0)
    var cameFrom = {}
    var costSoFar = {}
    cameFrom[start] = null
    costSoFar[start] = 0

    while (!frontier.isEmpty) {
      var current = frontier.get()
      if (goal && current == goal) {
        break
      }
      for (next in graph.neighbours(current)) {
        var newCost = costSoFar[current] + graph.cost(current, next)
        if (!costSoFar[next] || newCost < costSoFar[next]) {
          costSoFar[next] = newCost
          frontier.put(next, newCost + heuristic(next, goal))
          cameFrom[next] = current
        }
      }
    }
    return [cameFrom, costSoFar]
  }

  static reconstruct(cameFrom, start, goal) {
    if (start is Vector) {
      start = Elegant.pair(VecFloor.do(start))
    }
    if (goal is Vector) {
      goal = Elegant.pair(VecFloor.do(goal))
    }
    var current = goal
    var path = []
    while (current != start) {
      path.insert(0, Elegant.unpair(current))
      current = cameFrom[current] // || start
      if (current == null) {
        // Path is unreachable
        return null
      }
    }
    path.insert(0, Elegant.unpair(start))
    return path
  }
}

class DijkstraMap {
  static search(graph, start) {
    if (start is Vector) {
      start = Elegant.pair(VecFloor.do(start))
    }
    var frontier = PriorityQueue.new()
    frontier.put(start, 0)
    var cameFrom = {}
    var costSoFar = {}
    cameFrom[start] = null
    costSoFar[start] = 0

    while (!frontier.isEmpty) {
      var current = frontier.get()
      for (next in graph.neighbours(current)) {
        var newCost = costSoFar[current] + graph.cost(current, next)
        if (!costSoFar[next] || newCost < costSoFar[next]) {
          costSoFar[next] = newCost
          frontier.put(next, newCost + heuristic(next, start))
          cameFrom[next] = current
        }
      }
    }
    return [cameFrom, costSoFar]
  }

  static reconstruct(cameFrom, start, goal) {
    if (start is Vector) {
      start = Elegant.pair(VecFloor.do(start))
    }
    if (goal is Vector) {
      goal = Elegant.pair(VecFloor.do(goal))
    }
    var current = goal
    var path = []
    while (current != start) {
      path.add(Elegant.unpair(current))
      current = cameFrom[current]
      if (current == null) {
        // Path is unreachable
        break
      }
    }
    path.add(Elegant.unpair(start))
    return path
  }

  static heuristic(a, b) {
    var v1 = a
    var v2 = b
    if (a is Num) {
      v1 = Elegant.unpair(a)
    }
    if (b is Num) {
      v2 = Elegant.unpair(b)
    }
    return (v1 - v2).manhattan
  }
}
class BFSNeutral {
  static search(graph, start) { search(graph, start, null) }
  static search(graph, start, goal) {
    var frontier = Queue.new()
    var cameFrom = {}
    frontier.enqueue(start)
    cameFrom[start] = null

    while (!frontier.isEmpty) {
      var current = frontier.dequeue()
      if (goal && current == goal) {
        break
      }
      for (next in graph.neighbours(current)) {
        if (!cameFrom[next]) {
          frontier.enqueue(next)
          cameFrom[next] = current
        }
      }
    }
    return [ cameFrom ]
  }
  static reconstruct(cameFrom, start, goal) {
    var current = goal
    var path = []
    while (current != start) {
      path.insert(0, current)
      current = cameFrom[current]
      if (current == null) {
        // Path is unreachable
        return null
      }
    }
    path.insert(0, start)
    return path
  }
}
