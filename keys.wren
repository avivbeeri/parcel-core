/*
  InputGroup Library v0.3
  Allows for grouping DigitalInput together into a single action,
  with allowances for repetition.
*/
import "input" for Keyboard, Mouse, DigitalInput

class InputGroup {
  construct new(inputs) { init(inputs, null) }
  construct new(inputs, action) { init(inputs, action) }

  init(inputs, action) {
    if (inputs is Sequence) {
      _inputs = inputs
    } else if (inputs is DigitalInput) {
      _inputs = [ inputs ]
    }

    _action = action
    _repeating = true
    _freq = 30
    if (!_inputs.all {|input| input is DigitalInput }) {
      Fiber.abort("Inputs must be DigitalInput")
    }
  }

  repeating { _repeating }
  repeating=(v) { _repeating = v }

  frequency { _freq }
  frequency=(v) { _freq = v }

  reset() {
    _inputs.each {|input| input.reset() }
  }

  justPressed {
    return _inputs.count > 0 && _inputs.any {|input| input.justPressed }
  }
  down {
    return _inputs.count > 0 && _inputs.any {|input| input.down }
  }

  firing {
    return _inputs.count > 0 && _inputs.any {|input|
      if (_repeating) {
        return input.down && input.repeats % _freq == 0
      } else {
        return input.justPressed
      }
    }
  }

  action { _action }
}

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

var CANCEL_KEY = InputGroup.new([
  Keyboard["backspace"], Keyboard["escape"]
])

var CONFIRM_KEY = InputGroup.new([
  Keyboard["z"], Keyboard["x"], Keyboard["e"], Keyboard["return"], Keyboard["space"]
])

var INTERACT_KEY = InputGroup.new([
  Keyboard["e"], Keyboard["space"]
])

var DIR_KEYS = [ UP_KEY, DOWN_KEY, LEFT_KEY, RIGHT_KEY ]
// Set frequency for smoother tile movement
DIR_KEYS.each {|key| key.frequency = 1 }

class Actions {
  static directions { DIR_KEYS }

  static up { UP_KEY }
  static down { DOWN_KEY }
  static left { LEFT_KEY }
  static right { RIGHT_KEY }
  static interact { INTERACT_KEY }
  static confirm { CONFIRM_KEY }
  static cancel { CANCEL_KEY }
}
