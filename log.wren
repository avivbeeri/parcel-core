// ==================================
var LogLevels = {
  0: "DEBUG",
  1: "INFO",
  2: "WARN",
  3: "ERROR",
  4: "FATAL",
}

var LogColors = {
  0: "\e[36m", // Cyan
  1: "\e[32m", // Green
  2: "\e[33m", // Yellow
  3: "\e[31m", // Red
  4: "\e[31m", // Red
}

class Log {
  static level=(v) { __level = v }
  static print(level, text) {
    if (level >= (__level || 1)) {
      System.print("%(LogColors[level])[%(LogLevels[level])]\e[0m: %(text)")
    }
  }
  static d(text) {
    print(0, text)
  }
  static i(text) {
    print(1, text)
  }
  static w(text) {
    print(2, text)
  }
  static e(text) {
    print(3, text)
  }
  static f(text) {
    print(4, text)
  }
}
