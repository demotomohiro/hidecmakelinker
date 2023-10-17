import os

let rootDir = currentSourcePath.parentDir.parentDir
switch("path",  rootDir / "src")
switch("path", rootDir / "tests" / "testmodules")
switch("gcc.linkerexe", rootDir / "hidecmakelinker")
switch("gcc.cpp.linkerexe", rootDir / "hidecmakelinker")
switch("gcc.exe", rootDir / "void")
switch("gcc.cpp.exe", rootDir / "void")
# libconf need to write a file in nimcacheDir at compile time but it is not created at that time.
nimcacheDir().mkDir()
