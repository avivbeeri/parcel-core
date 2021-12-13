/*
  InputGroup Library v0.3
  Allows for grouping DigitalInput together into a single action,
  with allowances for repetition.
*/

import "input" for DigitalInput
import "math" for M

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
    _initialFreq = 40
    _freq = 10
    if (!_inputs.all {|input| input is DigitalInput }) {
      Fiber.abort("Inputs must be DigitalInput")
    }
  }

  repeating { _repeating }
  repeating=(v) { _repeating = v }

  initialFrequency { _initialFreq }
  initialFrequency=(v) { _initialFreq = v }
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
        if (input.down) {
          if (input.repeats == 0) {
            return true
          } else if (input.repeats < _initialFreq) {
            return false
          } else if (input.repeats == _initialFreq) {
            return true
          } else if (M.max(0, (input.repeats - _initialFreq)) % _freq == 0) {
            return true
          }
        }
        return false
        // return input.down && (input.repeats == _initialFreq || (input.repeats - _initialFreq) % _freq == 0)
      } else {
        return input.justPressed
      }
    }
  }

  action { _action }
}

