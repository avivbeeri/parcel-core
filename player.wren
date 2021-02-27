import "core/dataobject" for DataObject

class PlayerData is DataObject {
  construct new() {
    super()
    this["hunger"] = 5
    this["energy"] = 5
    this["temperature"] = 1
  }
}
