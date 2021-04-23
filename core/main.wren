import "./core/display" for Display
import "./core/config" for Config

class ParcelMain {
  construct new(scene) {
    _initial = scene
    _args = []
  }
  construct new(scene, args) {
    _initial = scene
    _args = args
  }

  init() {
    Display.setup(Config["display"])
    push(_initial, _args)
  }

  update() {
    _scene.update()
  }
  draw(dt) {
    _scene.draw()
  }

  push(scene) { push(scene, []) }
  push(scene, args) {
    _scene = scene.new(args)
    _scene.game = this
  }
}

