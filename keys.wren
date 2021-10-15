import "core/inputGroup" for InputGroup

import "input" for Keyboard, Mouse

var UP_KEY = InputGroup.new([
  Keyboard["up"], Keyboard["w"]
])
var DOWN_KEY = InputGroup.new([
  Keyboard["down"], Keyboard["s"]
])
var LEFT_KEY = InputGroup.new([
  Keyboard["left"], Keyboard["a"]
])
var RIGHT_KEY = InputGroup.new([
  Keyboard["right"], Keyboard["d"]
])

var REST_KEY = InputGroup.new([
  Keyboard["backspace"], Keyboard["escape"]
])
var CANCEL_KEY = InputGroup.new([
  Keyboard["backspace"], Keyboard["escape"]
])

var CONFIRM_KEY = InputGroup.new([
  Keyboard["z"], Keyboard["x"], Keyboard["e"], Keyboard["return"], Keyboard["space"]
])

var INTERACT_KEY = InputGroup.new([
  Keyboard["e"], Keyboard["space"]
])

var INVENTORY_KEY = InputGroup.new([
  Keyboard["i"]
])
var TARGET_KEY = InputGroup.new([
  Keyboard["tab"]
])


var DIR_KEYS = [ UP_KEY, DOWN_KEY, LEFT_KEY, RIGHT_KEY ]
// Set frequency for smoother tile movement
DIR_KEYS.each {|key| key.frequency = 1 }

class InputActions {
  static directions { DIR_KEYS }

  static up { UP_KEY }
  static down { DOWN_KEY }
  static left { LEFT_KEY }
  static right { RIGHT_KEY }
  static inventory { INVENTORY_KEY }
  static interact { INTERACT_KEY }
  static confirm { CONFIRM_KEY }
  static cancel { CANCEL_KEY }
  static nextTarget { TARGET_KEY }
  static rest { TARGET_KEY }


}
