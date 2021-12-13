// Abstract
class Behaviour {
  construct new(self) {
    _self = self
  }
  self { _self }
  ctx { _self.ctx }

  notify(event) {}
  evaluate() {}
}

