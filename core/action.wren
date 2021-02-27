class ActionResult {
  static success { ActionResult.new(true) }
  static failure { ActionResult.new(false) }

  construct new(success) {
    _success = success
    _alt = null
  }

  construct alternate(action) {
    _success = true
    _alt = action
  }

  alternate { _alt }
  succeeded { _success }
}


class Action {
  static none { Action.new() }
  construct new() {}
  cost { 1 }
  bind(entity) {
    _source = entity
    return this
  }

  perform() {
    return ActionResult.success
  }

  ctx { _source.ctx }
  source { _source }
  toString { this.type.name }
}
