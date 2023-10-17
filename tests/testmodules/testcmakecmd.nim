import hidecmakelinkerpkg/libconf

initLibParams(blC,
              {cmplC},
              [],
              [initCMakeCmd("add_compile_definitions(SOME_DEFINE=\"some define string\")", depend = "std.project"),
               initCMakeCmdWithTarget("target_compile_definitions(#target PUBLIC TARGET_DEFINE=98765)")]).config

let
  someDefine* {.importc: "SOME_DEFINE", nodecl.}: cstring
  targetDefine* {.importc: "TARGET_DEFINE", nodecl.}: int
