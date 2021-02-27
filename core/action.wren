class ActionResult {
  static success { ActionResult.new(true) }
  static failure { ActionResult.new(false) }

  construct new(success) {
    _success = success
    _alt = null
  }

  alternate { _alt }
  alternate=(v) { _alt = v }

  succeeded { _success }
}


class Action {
  construct new() {}
  bind(entity) {
    _source = entity
    return this
  }

  perform() {
    return null
  }

  ctx { _source.ctx }
  source { _source }
}
