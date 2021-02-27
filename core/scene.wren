class GameElement {
  update() {}
  draw() {}
}

class Scene is GameElement {
  game=(v) { _game = v }
  game { _game }
}


class Ui is GameElement {
  construct new(ctx) {
    _ctx = ctx
  }

  ctx { _ctx }
  finished { true }
}

