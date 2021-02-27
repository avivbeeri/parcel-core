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

  data { _data }
  [key] { _data[key] }
  [key]=(v) { _data[key] = v }
}


