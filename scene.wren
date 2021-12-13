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
  }
  construct new (parent) {
    _parent = parent
    _children = []
  }

  addViewChild(child) {
    if (!(child is View)) {
      Fiber.abort("Attempted to add non-View object to the scene: %(child)")
    }
    _children.add(child)
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
  }
  draw() {
    _children.each {|view| view.draw() }
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

