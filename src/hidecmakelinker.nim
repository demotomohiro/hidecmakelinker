import std/[json, jsonutils, os, osproc, strformat, strutils, sets, tables]
import hidecmakelinkerpkg/libparams

proc execProcessWithParentStream(command: string; args: openArray[string]) =
  let
    p = startProcess(command, args = args, options = {poUsePath, poParentStreams})
    exitCode = waitForExit(p)
  close(p)
  doAssert exitCode == 0

proc renderCmakeStmts(result: var string; stmts: var Table[string, CMakeStmt]; doneNames: var HashSet[string]; cmakeTarget: string) =
  while true:
    var newStmts = initTable[string, CMakeStmt](stmts.len)

    for k, v in stmts:
      if block:
        if v.stmtKind == cmstCommandWithTarget and cmakeTarget == "":
          false
        elif v.depend != "" and v.depend notin doneNames:
          false
        else:
          case v.stmtKind
          of cmstInclude:
            result.add &"include({k.cmakeStrArg})\n"
          of cmstCommand:
            result.add k & "\n"
          of cmstCommandWithTarget:
            result.add replace(k, "#target", cmakeTarget) & "\n"
          true
      :
        if v.name != "":
          doneNames.incl v.name
      else:
        newStmts[k] = v

    if stmts.len == newStmts.len:
      result.add '\n'
      break

    stmts = newStmts

proc main =
  #echo commandLineParams()
  let (cmakeContent, nimCacheDir) = block:
    var
      result = "cmake_minimum_required(VERSION 3.13)\n\n"
      args: seq[string]
      projParamPath, outFilePath: string

    block:
      var
        clparams = commandLineParams()
        pos = 0

      while pos < clparams.len:
        template param: string = clparams[pos]
        if param.len == 0:
          continue

        if param[0] == '-':
          if param[1] == '-':
            if param.startsWith(ProjParamPathParam):
              let paramSepPos = param.find(':')
              doAssert paramSepPos != -1
              let argPos = paramSepPos + 1
              doAssert argPos < param.len
              projParamPath = param[argPos .. ^1]
          if param[1] == 'o':
            inc pos
            doAssert pos < clparams.len
            outFilePath = clparams[pos]
        else:
          args.add param

        inc pos

    doAssert projParamPath.len > 0, "Failed to get the path to ProjParamFile"
    let
      projParams = projParamPath.parseFile.jsonTo(ProjParams)
      projectName = projParams.projectName

    var
      cmakeStmts = projParams.libParams.cmakeStmts
      doneNames: HashSet[string]

    renderCmakeStmts(result, cmakeStmts, doneNames, "")

    result.add &"project({projectName} LANGUAGES"
    for l in projParams.libParams.cmakeProgLangs:
      result.add (" " & $l)
    result.add ")\n\n"

    doneNames.incl "std.project"
    renderCmakeStmts(result, cmakeStmts, doneNames, "")

    result.add &"add_executable({projectName}\n"

    for i in args:
      let extPos = i.searchExtPos
      if extPos != -1 and i[(extPos + 1) .. ^1] in ["o", "obj"]:
        result.add ("  " & i[0 .. (extPos - 1)].cmakeStrArg & "\n")
      else:
        raise newException(CatchableError, "Got an unsupported kind of file: " & i)
    result.add ")\n\n"

    block:
      let outputDir = outFilePath.parentDir.cmakeStrArg
      result.add &"""set_target_properties({projectName}
                                           PROPERTIES
                                           ARCHIVE_OUTPUT_DIRECTORY {outputDir}
                                           RUNTIME_OUTPUT_DIRECTORY {outputDir})
                 """
      result.add '\n'

    result.add &"target_compile_options({projectName} PRIVATE {cmakeStrArg(\"-w\")})\n\n"
    result.add &"target_include_directories({projectName} PRIVATE {projParams.nimStdlibPath.cmakeStrArg})\n\n"

    result.add &"target_link_libraries({projectName}\n"
    for l in projParams.libparams.linkLibraries:
      result.add &"  {l}\n"
    result.add ")\n\n"

    renderCmakeStmts(result, cmakeStmts, doneNames, projectName)

    if cmakeStmts.len != 0:
      var msg: string
      for k, v in cmakeStmts:
        msg.add &"{k} depends {v.depend} that doesn't exist\n"
      raise newException(Defect, msg)

    (result, projParams.nimCacheDir)

  writeFile nimCacheDir / "CMakeLists.txt", cmakeContent

  let cmakeBuildDir = nimCacheDir / "cmakeBuildDir"
  execProcessWithParentStream("cmake", args = ["-S", nimCacheDir, "-B", cmakeBuildDir])
  execProcessWithParentStream("cmake", args = ["--build", cmakeBuildDir])

main()
