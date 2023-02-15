import "math" for M
class State {
  onEnter() {}
  update() { this }
  tickWorld { true }
  onExit() {}
}

class GameElement {
  update() {}
  draw() {}
}

class View is GameElement {
  construct new () {
    _children = []
    _newChildren = []
    _z = 0
  }
  construct new (parent) {
    _parent = parent
    _children = []
    _newChildren = []
    _z = 0
  }

  z { _z }
  z=(v) { _z = v }

  addViewChild(child) {
    if (!(child is View)) {
      Fiber.abort("Attempted to add non-View object to the scene: %(child)")
    }
    _newChildren.add(child)
    child.parent = this
  }
  removeViewChild(child) {
    _children.remove(child)
  }

  process(event) {
    _children.each {|view| view.process(event) }
  }

  parent { _parent }
  parent=(v) { _parent = v }
  children { _children }

  top {
    var current = this
    while (current.parent) {
      current = current.parent
    }
    return current
  }

  update() {
    _children.each {|view| view.update() }
    _children.addAll(_newChildren)
    _newChildren.clear()
    _children.sort {|a, b|
      if (a.z == b.z) {
        var a = a.type.name.codePoints
        var b = b.type.name.codePoints
        var count = M.min(a.count, b.count)
        for (i in 0...count) {
          if (a[i] != b[i]) {
            return a[i] < b[i]
          }
        }
        return a.count > b.count
      }
      return a.z < b.z
    }
  }
  draw() {
    var copy = [].addAll(_children)
    copy.each {|view|
      if (_children.contains(view)) {
        view.draw()
      }
    }
  }
  busy { _children.count > 0 && _children.any {|view| view.busy } }
}

class Scene is View {
  construct new() {
    super(null)
    _store = null
  }

  store { _store }
  store=(v) { _store = v }
  game { _game }
  game=(v) { _game = v }
}


class UiView is View {
  construct new(parent, ctx) {
    super(parent)
    _ctx = ctx
  }

  ctx { _ctx }
  finished { true }
}

class Effect is GameElement {
  construct new(ctx) {
    _ctx = ctx
  }

  ctx { _ctx }
  finished { true }
}

