import "random" for Squirrel5 as Random
import "core/config" for Config
import "dome" for Platform
var Seed = Config["seed"] || Platform.time
System.print(Seed)
var RNG = Random.new(Seed)

