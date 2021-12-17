class Event {
  construct new() {
    _cancelled = false

    // lower is better
    _priority = 1
  }
  priority=(v) { _priority = v }
  priority { _priority }

  cancel() {
    _cancelled = true
  }
  cancelled { _cancelled }
}

class EntityChangeEvent is Event {
  construct new(id) {
    super()
    _id = id
  }

  id { _id }
}

class EntityRemovedEvent is EntityChangeEvent {
  construct new(id) {
    super(id)
  }
}

class EntityAddedEvent is EntityChangeEvent {
  construct new(id) {
    super(id)
  }
}
