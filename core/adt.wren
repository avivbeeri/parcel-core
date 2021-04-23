// This implements the interface for some common data types

class Stack {
  construct new() {
    _list = []
  }
  isEmpty { _list.isEmpty }
  count { _list.count }

  push(v) {
    _list.add(v)
  }
  peek() { _list[-1] }

  pop() {
    return _list.removeAt(-1)
  }
}


// A FIFO queue
class Queue {
  construct new() {
    _list = []
  }
  enqueue(item) { _list.add(item) }
  dequeue() { _list.removeAt(0) }
  peek() { _list[0] }

  isEmpty { _list.isEmpty }
  count { _list.count }
}


class Heap {
  construct new() {
    _comparator = Fn.new {|a, b| a < b }
    _list = []
    _size = 0
  }
  construct new(comparator) {
    _comparator = comparator
    _list = []
    _size = 0
  }

  swap(i1, i2) {
    var temp = _list[i1]
    _list[i1] = _list[i2]
    _list[i2] = temp
  }

  isEmpty { _list.isEmpty }

  compare(a, b) {
    return _comparator.call(a, b)
  }

  percolateUp(pos) {
    while (pos > 1) {
      var parent = (pos/2).floor
      if (compare(_list[pos], _list[parent]) >= 0) {
        break
      }
      swap(parent, pos)
      pos = parent
    }
  }

  insert(element) {
    _list.insert(0, element)
    percolateDown(0)
    // percolateUp(_list.count - 1)
  }

  del() {
    if (_list.count == 0) {
      return null
    }
    if (_list.count == 1) {
      return _list.removeAt(0)
    }
    var top = _list[0]
    var last = _list.count - 1
    swap(0, last)
    _list.removeAt(last)
    percolateUp(0)
    percolateDown(0)
    // percolate root down
    return top
  }

  peek() {
    if (_list.count == 0) {
      return null
    }
    return _list[0]
  }

  percolateDown(pos) {
    var last = _list.count - 1
    while (true) {
      var min = pos
      var child = 2 * pos
      for (c in child .. child + 1) {
        if (c <= last && compare(_list[c], _list[min])) {
          min = c
        }
      }

      if (min == pos) {
        break
      }

      swap(pos, min)
      pos = min
    }
  }

  count { _size }
}

class Hashable {
  hash() { this.toString }
}

class Set {
  construct new() {
    _map = {}
  }

  isEmpty { _map.isEmpty }

  has(value) {
    var hash = value
    if (value is Hashable) {
      hash = value.hash()
    }
    return _map.containsKey(hash)
  }

  remove(value) {
    var hash = value
    if (value is Hashable) {
      hash = value.hash()
    }
    return _map.remove(hash)
  }

  get(value) {
    var hash = value
    if (value is Hashable) {
      hash = value.hash()
    }
    return _map[hash]
  }

  set(value) {
    var hash = value
    if (value is Hashable) {
      hash = value.hash()
    }
    _map[hash] = value
  }

  count { _map.count }

  iterate(iter) { _map.values.iterate(iter) }
  iteratorValue(iter) { _map.values.iteratorValue(iter) }
}

