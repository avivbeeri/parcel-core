import "math" for Vec, M

// Converts two integers into a single integer, good for hashing
// Supports negative numbers too
class Elegant {
  static pair(vec) { pair(vec.x, vec.y) }
  static pair(x, y) {
    var xx = x >= 0 ? x * 2 : x * -2 - 1
    var yy = y >= 0 ? y * 2 : y * -2 - 1
    return (xx >= yy) ? (xx * xx + xx + yy) : (yy * yy + xx)
  }

  static unpair(z) {
    var sqrtz = M.floor(z.sqrt)
    var sqz = sqrtz * sqrtz
    var result1 = ((z - sqz) >= sqrtz) ? [ sqrtz, z - sqz - sqrtz] : [z - sqz, sqrtz]

    var xx = result1[0] % 2 == 0 ? result1[0] / 2 : (result1[0] + 1) / -2
    var yy = result1[1] % 2 == 0 ? result1[1] / 2 : (result1[1] + 1) / -2
    return Vec.new(xx, yy)
  }

}
