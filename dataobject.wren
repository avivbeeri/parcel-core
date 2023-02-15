import "json" for JSON
class DataObject {
  construct new() {
    _data = {}
  }
  construct new(data) {
    _data = {}
    for (key in data.keys) {
      _data[key] = data[key]
    }
  }

  static copyValue(value) {
    if (value is Map) {
      var copy = {}
      for (key in value.keys) {
        copy[key] = copyValue(value[key])
      }
      return copy
    }
    if (value is List) {
      return value.map {|entry| copyValue(entry) }.toList
    }
    return value
  }

  data { _data }
  [key] { _data[key] }
  [key]=(v) { _data[key] = v }
  has(prop) { _data.containsKey(prop) && _data[prop] != null }
}

class Reducer {
  reduce(state, action) {}
}


/**
 * Redux-style data store for UI?
 */
class Store {
  construct create(reducer) {
    _listeners = []
    _state = {}
    _reducer = reducer
  }
  construct create(data, reducer) {
    _state = data
    _listeners = []
    _reducer = reducer
    _allowDispatch = true
  }

  notify_() {
    _listeners.each {|listener| listener.call() }
  }


  copy_(state) {
    return DataObject.copyValue(state)
  }

  state { _state }
  reducer=(v) { _reducer = v }

  subscribe(listener) {
    if (!(listener is Fn)) {
      Fiber.abort("Attempting to add non-callable listener to store")
    }
    _listeners.add(listener)
    return Fn.new {
      _listeners.remove(listener)
    }
  }

  dispatch(action) {
    if (!_allowDispatch) {
      Fiber.abort("Not allowed to dispatch at this time")
    }
    _allowDispatch = false
    if (_reducer is Reducer) {
      _state = _reducer.reduce(copy_(state), action)
    } else {
      _state = _reducer.call(copy_(state), action)
    }
    _allowDispatch = true
    notify_()
  }

  static combineReducers(reducers) {
    return Fn.new {|state, action|
      return reducers.keys.reduce({}) {|nextState, key|
        nextState[key] = reducers[key].call(state[key], action)
        return nextState
      }
    }
  }
}

