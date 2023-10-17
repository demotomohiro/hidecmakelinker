import std/[compilesettings, json, jsonutils, macrocache, macros, sets, tables]
import pathX, pathX/lowlevel
import libparams

export libparams.LibParams, libparams.BackendLang, libparams.CMakeProgLang, libparams.cmakeStrArg, libparams.initLibParams, libparams.initCMakeInclude, libparams.initCMakeCmd, libparams.initCMakeCmdWithTarget

type
  BuildOSPath[FoD: static[FileOrDire]; AoR: static[AbsoOrRela]] = PathX[FoD, AoR, BuildOS, true]

const
  backendLang = CacheSeq"hidecmakelinker/libconf.nim backendLang"
  cmakeProgLangs = CacheSeq"hidecmakelinker/libconf.nim cmakeProgLangs"
  linkLibraries = CacheSeq"hidecmakelinker/libconf.nim linkLibraries"
  cmakeStmts = CacheTable"hidecmakelinker/libconf.nim cmakeStmts"
  cmakeStmtNames = CacheTable"hidecmakelinker/libconf.nim cmakeStmtNames"

proc configImpl(params: LibParams) {.compileTime.} =
  backendLang.incl ($params.backendLang).newLit

  for l in params.cmakeProgLangs:
    cmakeProgLangs.incl newLit l.int

  for v in params.linkLibraries:
    linkLibraries.incl v.newLit

  for k, v in params.cmakeStmts:
    if k in cmakeStmts:
      raise newException(Defect, k & " was added multiple times")
    if v.name.len != 0:
      if v.name in cmakeStmtNames:
        raise newException(Defect, v.name & " was defined multiple times")
      cmakeStmtNames[v.name] = nil
    cmakeStmts[k] = newTree(nnkTupleConstr, newLit v.stmtKind.int, newLit v.name, newLit v.depend)

template config*(params: LibParams) =
  static:
    configImpl(params)

proc toEnumSet[T: enum](cset: CacheSeq; E: typedesc[T]): set[T] =
  for v in cset:
    result.incl v.intVal.T

when false:
  # Use this proc when
  # https://github.com/nim-lang/Nim/issues/22285
  # is solved.
  proc toStringHashSet(cset: CacheSeq): HashSet[string] {.compileTime.} =
    for val in cset:
      result.incl val.strVal
else:
  template toStringHashSet(cset: CacheSeq): HashSet[string] =
    block:
      var result: HashSet[string]
      for val in cset:
        result.incl val.strVal
      result

when false:
  proc toStringSeq(cseq: CacheSeq): seq[string] =
    for val in cseq:
      result.add val.strVal

proc contains(cset: CacheSeq, value: string): bool =
  for val in cset:
    if val.strVal == value:
      return true

proc toCMakeStmts(ctab: CacheTable): Table[string, CMakeStmt] =
  for key, val in ctab:
    result[key] = CMakeStmt(stmtKind: val[0].intVal.CMakeStmtKind, name: val[1].strVal, depend: val[2].strVal)

proc writeHideCMakeToFileImpl(): string {.compileTime.} =
  var projParams = ProjParams(projectName: querySetting(SingleValueSetting.projectName),
                              nimStdlibPath: querySetting(SingleValueSetting.libPath),
                              nimCacheDir: querySetting(SingleValueSetting.nimcacheDir),
                              libParams: LibParams(backendLang: if ($BackendLang.blCpp) in backendLang: blCpp else: blC,
                                                   cmakeProgLangs: cmakeProgLangs.toEnumSet(CMakeProgLang),
                                                   linkLibraries: linkLibraries.toStringHashSet,
                                                   cmakeStmts: cmakeStmts.toCMakeStmts))

  block:
    let nimBackend = querySetting(SingleValueSetting.backend)
    if projParams.libParams.backendLang == blCpp and nimBackend != "cpp":
      raise newException(Defect, "nim must run as \"nim cpp ...\" because this project imports a module requires cpp backend")
    elif projParams.libParams.backendLang == blC and nimBackend notin ["c", "cpp"]:
      raise newException(Defect, "nim must run as \"nim c ...\" or \"nim cpp ...\" because this project imports a module requires c backend")

  var jsonStr: string
  toUgly(jsonStr, projParams.toJson)

  let path = querySetting(SingleValueSetting.nimcacheDir).BuildOSPath[:fdDire, arAbso] / ProjParamFileName.BuildOSPath[:fdFile, arRela]
  write path, jsonStr
  $path
 
template writeHideCMakeToFile* =
  static:
    const path = writeHideCMakeToFileImpl()
    {.passL: ProjParamPathParam & path.}
