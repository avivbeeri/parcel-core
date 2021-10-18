class GameElement {
  update() {}
  draw() {}
}

class View is GameElement {
  construct new (parent, args) {
    _parent = parent
  }
  parent { _parent }
  busy { false }
  processEvent(event) {}
}

class Scene is GameElement {
  game=(v) { _game = v }
  game { _game }

  addView(view) {
    if (!(view is View)) {
      Fiber.abort("Attempted to add non-View object to the scene: %(view)")
    }
    _views.add(view)
  }

  construct new(args) {
    _views = []
  }
  update() {
    _views.each {|view| view.update() }
  }
  draw() {
    _views.each {|view| view.draw() }
  }

  viewIsBusy { _views.count > 0 && _views.any {|view| view.busy } }

  processEvent(event) {
    _views.each {|view| view.processEvent(event) }
  }
}


class Ui is GameElement {
  construct new(ctx) {
    _ctx = ctx
  }

  ctx { _ctx }
  finished { true }
  drawDiagetic() {}
}

