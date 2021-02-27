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
