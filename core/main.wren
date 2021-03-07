import "./core/display" for Display

class ParcelMain {
  construct new() {}
  construct new(scene) {
    push(scene)
  }
  construct new(scene, args) {
    push(scene, args)
  }

  init() {
    Display.setup()
  }

  update() {
    _scene.update()
  }
  draw(dt) {
    _scene.draw()
  }

  push(scene) { push(scene, null) }
  push(scene, args) {
    _scene = scene.new(args)
    _scene.game = this
  }
}

