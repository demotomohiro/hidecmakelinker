import pathX
import hidecmakelinkerpkg/libconf

type
  BuildOSAbsoFile = PathX[fdFile, arAbso, BuildOS, true]

initLibParams(blCpp,
              {cmplCXX},
              ["testcpp"],
              [initCMakeInclude($(currentSourcePath().BuildOSAbsoFile.parentDir.parentDir.joinDire"cpplib".joinFile"libtestcpp.cmake"), "libtestcpp.cmake", "std.project"),
              initCMakeCmd("libtestcpp_init()", depend = "libtestcpp.cmake")]
              ).config

const LibTestCppHeader = "libtestcpp.hpp"
type
  Testcpp* {.header: LibTestCppHeader, importcpp: "libtestcpp::testcpp".} = object

proc initTestcpp*(x: cint): Testcpp {.header: LibTestCppHeader, importcpp: "libtestcpp::testcpp(@)", constructor.}
proc getX*(x: TestCpp): cint {.header: LibTestCppHeader, importcpp: "#.getX()".}
