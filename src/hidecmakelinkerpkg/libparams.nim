import std/[sets, strutils, tables]

type
  BackendLang* = enum
    ## Which Backend language Nim compiler generates.
    ## If both `blC` and `blCpp` was specified,
    ## it must be compiled with `nim cpp`.
    blC   = "c"
    blCpp = "cpp"

  CMakeProgLang* = enum
    ## Selects which programming languages are needed to build the project.
    ## They are added to `project` command as LANGUAGES option in generated CMakeLists.txt.
    ##
    ## See:
    ## https://cmake.org/cmake/help/latest/command/project.html
    cmplC = "C"
    cmplCXX = "CXX"
    cmplASM = "ASM"

  CMakeStmtKind* = enum
    cmstInclude
    cmstCommand
    cmstCommandWithTarget

  CMakeStmt* = object
    stmtKind*: CMakeStmtKind
    name*: string
    depend*: string

  LibParams* = object
    backendLang*: BackendLang
    cmakeProgLangs*: set[CMakeProgLang]
    linkLibraries*: HashSet[string]
    cmakeStmts*: Table[string, CMakeStmt]

  ProjParams* = object
    projectName*: string
    nimStdlibPath*: string
    nimCacheDir*: string
    libParams*: LibParams

const
  ProjParamFileName* = "hideCMakeLinkerProjParam.json"
  ProjParamPathParam* = "--hidecmakelinkerProjParamPath:"

proc cmakeStrArg*(x: string): string =
  "[==[" & x & "]==]"

proc initCMakeStmt(stmtKind: CMakeStmtKind; name: string; depend: string): CMakeStmt =
  if name.startsWith("std."):
    raise newException(Defect, "`" & name & "` is an invalid name as names start with `std.` is reserved by hidecmakelinker")

  CMakeStmt(stmtKind: stmtKind, name: name, depend: depend)

proc initCMakeInclude*(path: string; name = "", depend = ""): (string, CMakeStmt) =
  (path, initCMakeStmt(cmstInclude, name, depend))

proc initCMakeCmd*(cmd: string; name = "", depend = ""): (string, CMakeStmt) =
  (cmd, initCMakeStmt(cmstCommand, name, depend))

proc initCMakeCmdWithTarget*(cmd: string; name = "", depend = ""): (string, CMakeStmt) =
  (cmd, initCMakeStmt(cmstCommandWithTarget, name, depend))

proc initLibParams*(backendLang: BackendLang = blC;
                    cmakeProgLangs: set[CMakeProgLang] = {cmplC, cmplCXX};
                    linkLibraries: openArray[string] = [];
                    cmakeStmts: openArray[(string, CMakeStmt)] = []): LibParams =
  LibParams(backendLang: backendLang,
            cmakeProgLangs: cmakeProgLangs,
            linkLibraries: linkLibraries.toHashSet,
            cmakeStmts: cmakeStmts.toTable)
