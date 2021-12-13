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
  toString { "ActionResult [%(succeeded), %(alternate)]"}
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


// Partial failure results in total failure, but doesn't rollback.
class MultiAction is Action {
  construct new(actionList, force) {
    super()
    _actionList = actionList
    _force = force
  }

  perform() {
    var result = ActionResult.success
    var failed = false
    for (step in _actionList) {
      while (step) {
        step.bind(source)
        var stepResult = step.perform()
        if (!_force && !stepResult.succeeded) {
          result = ActionResult.failure
          failed = true
          break
        }
        if (!stepResult.alternate) {
          break
        }
        step = result.alternate
      }
      if (failed) {
        break
      }
    }
    return result
  }
}
