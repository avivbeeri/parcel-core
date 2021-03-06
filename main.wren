import "graphics" for Canvas, Font
import "dome" for Window
import "./scene" for WorldScene
import "./display" for Display


class Game {
  static init() {
    var scale = 3
    Window.title = "Untitled Game"
    Window.lockstep = true
    Window.resize(Canvas.width * scale, Canvas.height * scale)
    Display.setup()

    push(WorldScene)
  }

  static update() {
    __scene.update()
  }
  static draw(dt) {
    __scene.draw()
  }

  static push(scene) { push(scene, null) }
  static push(scene, args) {
    __scene = scene.new(args)
    __scene.game = Game
  }
}
