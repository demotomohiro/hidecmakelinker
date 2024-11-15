import pathX
import hidecmakelinkerpkg/libconf

type
  BuildOSAbsoFile = PathX[fdFile, arAbso, BuildOS, true]

initLibParams(backendLang = blC,
              linkLibraries = ["testc"],
              cmakeStmts = [initCMakeInclude($(currentSourcePath().BuildOSAbsoFile.parentDir.parentDir.joinDire"clib".joinFile"libtestc.cmake"), depend = "std.topStmts"),
                            initCMakeCmd("set(LIBTESTC_TOPSTMTS_VAR test)"),
                            initCMakeCmd("libtestc_init()", depend = "std.project")]
             ).config()

proc libtestc*(): cint {.header: "libtestc.h".}
