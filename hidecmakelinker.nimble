# Package

version       = "0.1.1"
author        = "demotomohiro"
description   = "Help using C/C++ libraries that depends on CMake"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["hidecmakelinker, void"]


# Dependencies

requires "nim >= 2.2.0"
requires "https://github.com/demotomohiro/pathX"

task test, "Runs the tests":
  exec "nim c --outdir:. src/hidecmakelinker"
  exec "nim c --outdir:. src/void"
  exec "nim c -r tests/testprojc.nim"
  exec "nim cpp -r tests/testprojcpp.nim"
